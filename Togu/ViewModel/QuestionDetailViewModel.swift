//
//  QuestionDetailViewModel.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation
import Combine

@MainActor
final class QuestionDetailViewModel: ObservableObject {
    @Published var answers: [Answer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var updatedQuestionvotes: Int? = nil
    @Published var updatedAnswerVotes: [String: Int] = [:]
    @Published var isSubmittingAnswer = false
    @Published var submitAnswerError: String?
    @Published var hasVotedOnQuestion = false
    @Published var hasVotedOnAnswers: [String: Bool] = [:]
    @Published var isVoting = false
    
    private let airtable: AirtableService
    private let question: Question

    init(question: Question, airtable: AirtableService) {
        self.question = question
        self.airtable = airtable
    }

    func loadAnswers(for question: Question, auth: AuthViewModel? = nil) {
        Task { 
            await fetchAnswers(for: question)
            if let auth = auth {
                await checkVoteStatus(auth: auth)
            }
        }
    }
    
    func checkVoteStatus(auth: AuthViewModel?) async {
        guard let auth = auth else { return }
        
        // Resolve user ID
        guard let userId = auth.airtableUserId, !userId.isEmpty else {
            // Try to resolve it
            do {
                let id = try await resolveAuthorId(from: auth)
                await checkVoteStatusForUser(userId: id)
            } catch {
                print("⚠️ Could not resolve user ID for vote check: \(error)")
            }
            return
        }
        
        await checkVoteStatusForUser(userId: userId)
    }
    
    private func checkVoteStatusForUser(userId: String) async {
        // Check question vote
        do {
            let voted = try await airtable.hasUserVoted(
                userId: userId,
                targetType: "Question",
                targetId: question.id
            )
            await MainActor.run {
                hasVotedOnQuestion = voted
            }
        } catch {
            print("⚠️ Error checking question vote: \(error)")
        }
        
        // Check answer votes (use current answers array)
        let currentAnswers = await MainActor.run { answers }
        for answer in currentAnswers {
            do {
                let voted = try await airtable.hasUserVoted(
                    userId: userId,
                    targetType: "Answer",
                    targetId: answer.id
                )
                await MainActor.run {
                    hasVotedOnAnswers[answer.id] = voted
                }
            } catch {
                print("⚠️ Error checking answer vote for \(answer.id): \(error)")
            }
        }
    }

    private func fetchAnswers(for question: Question) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard !question.id.isEmpty else {
            print("❌ Missing Airtable record ID for question")
            errorMessage = "Missing record ID."
            return
        }
        
        
        do {
            // ✅ Use your AirtableService method directly
            let fetchedAnswers = try await airtable.fetchAnswers(for: question)
            
            // ✅ Assign explicitly to self.answers
            self.answers = fetchedAnswers
            
            
        } catch {
            print("❌ Error loading answers:", error)
            self.errorMessage = "Failed to load answers."
        }
    }
    
    private func resolveAuthorId(from auth: AuthViewModel) async throws -> String { 
        if let id = auth.airtableUserId, !id.isEmpty { return id }

        // Read email/name from the same source used in HomeView (AuthViewModel.state)
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

        let displayName = name ?? "Unknown"
        let recId = try await airtable.createUserIfMissing(name: displayName, email: userEmail)
        await MainActor.run { auth.airtableUserId = recId }
        return recId
    }

    // NEW: use AuthViewModel, not a raw authorId string
    func submitAnswer(text: String, auth: AuthViewModel) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run { self.submitAnswerError = "Answer text cannot be empty." }
            return
        }

        await MainActor.run {
            self.isSubmittingAnswer = true
            self.submitAnswerError = nil
        }

        do {
            let authorId = try await resolveAuthorId(from: auth)
            try await airtable.createAnswer(for: question, text: trimmed, authorId: authorId)
            await fetchAnswers(for: question)
            await MainActor.run { self.isSubmittingAnswer = false }
        } catch {
            await MainActor.run {
                self.isSubmittingAnswer = false
                self.submitAnswerError = error.localizedDescription
            }
        }
    }
    
    func upvoteQuestion(question: Question, auth: AuthViewModel) async {
        // Check if already voted
        if hasVotedOnQuestion {
            print("⚠️ User has already voted on this question")
            return
        }
        
        await MainActor.run {
            isVoting = true
        }
        
        do {
            // Resolve user ID
            let userId = try await resolveAuthorId(from: auth)
            
            // Create vote in Airtable (this also updates the upvote count)
            try await airtable.createVote(
                userId: userId,
                targetType: "Question",
                targetId: question.id
            )
            
            // Update local state
            let newCount = (updatedQuestionvotes ?? question.upvotes) + 1
            await MainActor.run {
                self.updatedQuestionvotes = newCount
                self.hasVotedOnQuestion = true
                self.isVoting = false
            }
            
            // Reload question to get updated count from server
            // (In a real app, you might want to refresh the question from the feed)
        } catch {
            print("❌ Error upvoting question: \(error)")
            await MainActor.run {
                self.isVoting = false
            }
        }
    }
    
    func upvoteAnswer(_ answer: Answer, auth: AuthViewModel) async {
        // Check if already voted
        if hasVotedOnAnswers[answer.id] == true {
            print("⚠️ User has already voted on this answer")
            return
        }
        
        await MainActor.run {
            isVoting = true
        }
        
        do {
            // Resolve user ID
            let userId = try await resolveAuthorId(from: auth)
            
            // Create vote in Airtable (this also updates the upvote count)
            try await airtable.createVote(
                userId: userId,
                targetType: "Answer",
                targetId: answer.id
            )
            
            // Update local state
            let current = updatedAnswerVotes[answer.id] ?? answer.upvotes
            let newCount = current + 1
            await MainActor.run {
                self.updatedAnswerVotes[answer.id] = newCount
                self.hasVotedOnAnswers[answer.id] = true
                self.isVoting = false
            }
            
            // Reload answers to get updated counts
            await fetchAnswers(for: question)
        } catch {
            print("❌ Error upvoting answer: \(error)")
            await MainActor.run {
                self.isVoting = false
            }
        }
    }

}

