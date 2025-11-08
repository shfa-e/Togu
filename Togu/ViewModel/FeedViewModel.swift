//
//  FeedViewModel.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation
import Combine
//
@MainActor
final class FeedViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String? = nil
    @Published var questions: [Question] = []
    @Published var updatedQuestionVotes: [String: Int] = [:]
    @Published var hasVotedOnQuestions: [String: Bool] = [:]
    @Published var isVoting = false
    
    // Pagination state
    private var nextOffset: String? = nil
    @Published var hasMorePages: Bool = true
    
    // Search and filter state
    @Published var searchText: String = "" {
        didSet {
            // Debounce search
            searchDebounceTask?.cancel()
            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                guard !Task.isCancelled else { return }
                await performSearch()
            }
        }
    }
    @Published var selectedTag: String? = nil
    
    private var searchDebounceTask: Task<Void, Never>?
    private var authForSearch: AuthViewModel?

    private lazy var airtableServiceInternal: AirtableService? = {
        guard let config = AirtableConfig() else { return nil }
        return AirtableService(config: config)
    }()

    var airtableService: AirtableService? { airtableServiceInternal }

    // Load with auth so we can hydrate vote state per question
    func loadQuestions(auth: AuthViewModel, reset: Bool = true) {
        authForSearch = auth
        if reset {
            isLoading = true
            nextOffset = nil
            hasMorePages = true
            questions = []
        } else {
            isLoadingMore = true
        }
        errorMessage = nil

        Task {
            await loadQuestionsWithRetry(auth: auth, reset: reset)
        }
    }
    
    func performSearch() async {
        guard let auth = authForSearch else { return }
        // Only perform search if user is signed in
        guard case .signedIn = auth.state else { return }
        await loadQuestionsWithRetry(auth: auth, reset: true)
    }
    
    func selectTag(_ tag: String, auth: AuthViewModel) {
        if tag == "All" {
            selectedTag = nil
        } else {
            selectedTag = (selectedTag == tag) ? nil : tag
        }
        loadQuestions(auth: auth)
    }
    
    var isEmptyState: Bool {
        questions.isEmpty
    }
    
    var emptyStateTitle: String {
        searchText.isEmpty && selectedTag == nil
            ? "No questions yet"
            : "No questions found"
    }
    
    var emptyStateMessage: String {
        searchText.isEmpty && selectedTag == nil
            ? "Be the first to ask a question!"
            : "Try a different search term or filter"
    }
    
    var shouldShowEmptyStateAction: Bool {
        searchText.isEmpty && selectedTag == nil
    }
    
    private func loadQuestionsWithRetry(auth: AuthViewModel, reset: Bool, retryCount: Int = 0) async {
        guard let airtable = self.airtableServiceInternal else {
            self.errorMessage = "Airtable not configured. Check Info.plist keys."
            self.isLoading = false
            self.isLoadingMore = false
            return
        }
        
        do {
            // Use search and tag filters with pagination
            let result = try await airtable.fetchQuestions(
                searchText: searchText.isEmpty ? nil : searchText,
                selectedTag: selectedTag,
                offset: reset ? nil : nextOffset
            )
            
            var items = result.questions
            
            // Enrich questions with author details (answer counts loaded separately in QuestionCardView)
            // Use TaskGroup for parallel fetching
            await withTaskGroup(of: (Int, URL?, Int?).self) { group in
                for i in 0..<items.count {
                    let question = items[i]
                    group.addTask {
                        if let authorId = question.authorId {
                            do {
                                let (profileURL, level) = try await airtable.getAuthorDetails(authorId: authorId)
                                return (i, profileURL, level)
                            } catch {
                                print("⚠️ Failed to get author details for \(authorId): \(error)")
                                return (i, nil, nil)
                            }
                        }
                        return (i, nil, nil)
                    }
                }
                
                for await (index, profileURL, level) in group {
                    items[index].authorProfilePictureURL = profileURL
                    items[index].authorLevel = level
                }
            }
            
            if reset {
                self.questions = items
            } else {
                self.questions.append(contentsOf: items)
            }
            
            // Update pagination state
            self.nextOffset = result.nextOffset
            self.hasMorePages = result.nextOffset != nil

            // Hydrate per-question vote state for this user
            if let userId = try? await resolveAuthorId(from: auth) {
                let startIndex = reset ? 0 : self.questions.count - items.count
                for i in startIndex..<self.questions.count {
                    let q = self.questions[i]
                    let voted = try await airtable.hasUserVoted(
                        userId: userId,
                        targetType: "Question",
                        targetId: q.id
                    )
                    self.questions[i].userHasVoted = voted
                    self.hasVotedOnQuestions[q.id] = voted
                }
            }

            self.isLoading = false
            self.isLoadingMore = false
        } catch {
            // Retry logic with exponential backoff
            if retryCount < 3 {
                let delay = pow(2.0, Double(retryCount)) // 1s, 2s, 4s
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await loadQuestionsWithRetry(auth: auth, reset: reset, retryCount: retryCount + 1)
            } else {
                self.errorMessage = "Failed to load questions. Please check your connection."
                self.isLoading = false
                self.isLoadingMore = false
            }
        }
    }
    
    func loadMoreQuestions(auth: AuthViewModel) {
        guard hasMorePages && !isLoadingMore && !isLoading else { return }
        loadQuestions(auth: auth, reset: false)
    }

    func prepend(_ question: Question) {
        if let existingIndex = questions.firstIndex(where: { $0.id == question.id }) {
            questions.remove(at: existingIndex)
        }
        questions.insert(question, at: 0)
    }

    // Refresh from Airtable and (optionally) re-hydrate votes
    func reload(using service: AirtableService, auth: AuthViewModel? = nil) async {
        do {
            let result = try await service.fetchQuestions(
                searchText: searchText.isEmpty ? nil : searchText,
                selectedTag: selectedTag
            )
            var latest = result.questions

            if let auth = auth, let userId = try? await resolveAuthorId(from: auth) {
                for i in 0..<latest.count {
                    let q = latest[i]
                    let voted = try await service.hasUserVoted(
                        userId: userId,
                        targetType: "Question",
                        targetId: q.id
                    )
                    latest[i].userHasVoted = voted
                    hasVotedOnQuestions[q.id] = voted
                }
            }

            self.questions = latest
            self.nextOffset = result.nextOffset
            self.hasMorePages = result.nextOffset != nil
        } catch {
            // Optional: log non-blocking error
            print("⚠️ Failed to reload questions: \(error)")
        }
    }

    // MARK: - Voting

    /// Resolve user ID from AuthViewModel
    private func resolveAuthorId(from auth: AuthViewModel) async throws -> String {
        if let id = auth.airtableUserId, !id.isEmpty { return id }

        var email: String?
        var name: String?
        if case .signedIn(let claims) = auth.state {
            email = (claims["email"] as? String)
                ?? (claims["upn"] as? String)
                ?? (claims["preferred_username"] as? String)
            name  = (claims["name"] as? String)
                ?? (claims["given_name"] as? String)
                ?? email
        }

        guard let userEmail = email, !userEmail.isEmpty else {
            throw NSError(domain: "AuthorId", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Missing author identity. Please sign out and sign in again."
            ])
        }

        guard let airtable = airtableServiceInternal else {
            throw NSError(domain: "AirtableService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Airtable service not available."
            ])
        }

        let displayName = name ?? "Unknown"
        let recId = try await airtable.createUserIfMissing(name: displayName, email: userEmail)
        await MainActor.run { auth.airtableUserId = recId }
        return recId
    }

    /// Upvote a question from the feed
    func upvoteQuestion(_ question: Question, auth: AuthViewModel) async {
        // Check if already voted (UI guard)
        if hasVotedOnQuestions[question.id] == true || question.userHasVoted {
            return
        }

        await MainActor.run { isVoting = true }

        do {
            guard let airtable = airtableServiceInternal else {
                throw NSError(domain: "AirtableService", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Airtable service not available."
                ])
            }

            // Resolve user ID
            let userId = try await resolveAuthorId(from: auth)

            // Create vote in Airtable (also updates upvote count there)
            try await airtable.createVote(
                userId: userId,
                targetType: "Question",
                targetId: question.id
            )

            // Update local state (maps)
            let newCount = (updatedQuestionVotes[question.id] ?? question.upvotes) + 1
            self.updatedQuestionVotes[question.id] = newCount
            self.hasVotedOnQuestions[question.id] = true

            // Update the Question item’s userHasVoted flag so button is blue immediately
            if let idx = self.questions.firstIndex(where: { $0.id == question.id }) {
                self.questions[idx].userHasVoted = true
            }

            self.isVoting = false

            // Reload to get authoritative counts and keep vote state in sync
            await reload(using: airtable, auth: auth)
        } catch {
            await MainActor.run { self.isVoting = false }
        }
    }
}
