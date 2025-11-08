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
    @Published var errorMessage: String? = nil
    @Published var questions: [Question] = []
    @Published var updatedQuestionVotes: [String: Int] = [:]
    @Published var hasVotedOnQuestions: [String: Bool] = [:]
    @Published var isVoting = false
    
    // Search and filter state
    @Published var searchText: String = ""
    @Published var selectedTag: String? = nil

    private lazy var airtableServiceInternal: AirtableService? = {
        guard let config = AirtableConfig() else { return nil }
        return AirtableService(config: config)
    }()

    var airtableService: AirtableService? { airtableServiceInternal }

    // Load with auth so we can hydrate vote state per question
    func loadQuestions(auth: AuthViewModel) {
        isLoading = true
        errorMessage = nil

        Task {
            guard let airtable = self.airtableServiceInternal else {
                self.errorMessage = "Airtable not configured. Check Info.plist keys."
                self.isLoading = false
                return
            }
            do {
                // Use search and tag filters
                var items = try await airtable.fetchQuestions(
                    searchText: searchText.isEmpty ? nil : searchText,
                    selectedTag: selectedTag
                )
                
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
                
                self.questions = items

                // Hydrate per-question vote state for this user
                if let userId = try? await resolveAuthorId(from: auth) {
                    for i in 0..<self.questions.count {
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
            } catch {
                self.errorMessage = "Failed to load questions."
                self.isLoading = false
            }
        }
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
            var latest = try await service.fetchQuestions(
                searchText: searchText.isEmpty ? nil : searchText,
                selectedTag: selectedTag
            )

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
        } catch {
            // Optional: log non-blocking error
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
