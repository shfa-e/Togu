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
    
    
    private let airtable: AirtableService
    private let question: Question

    init(question: Question, airtable: AirtableService) {
        self.question = question
        self.airtable = airtable
    }

    func loadAnswers(for question: Question) {
        Task { await fetchAnswers(for: question) }
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
    
    func upvoteQuestion(question: Question) async {
        // Simple local increment
        let newCount = (updatedQuestionvotes ?? question.upvotes) + 1
        await MainActor.run {
            self.updatedQuestionvotes = newCount
        }

        // 🔧 TODO: Optional Airtable update later
        // try? await airtable.updateUpvotes(for: question.id, to: newCount)
        
//        func updateUpvotes(for recordId: String, to newCount: Int) async throws {
//            let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Questions/\(recordId)")!
//            var request = URLRequest(url: url)
//            request.httpMethod = "PATCH"
//            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//            let body = ["fields": ["Upvotes": newCount]]
//            request.httpBody = try JSONSerialization.data(withJSONObject: body)
//
//            let (_, response) = try await URLSession.shared.data(for: request)
//            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
//                throw URLError(.badServerResponse)
//            }
//        }
    }
    
    func upvoteAnswer(_ answer: Answer) async {
        let current = updatedAnswerVotes[answer.id] ?? answer.upvotes
        let newCount = current + 1
        await MainActor.run {
            self.updatedAnswerVotes[answer.id] = newCount
        }

        // Optional: Uncomment when ready to save to Airtable
        // try? await airtable.updateUpvotes(for: answer.id, to: newCount, in: "Answers")
    }
    
    // MARK: - Submit Answer
    @Published var isSubmittingAnswer = false
    @Published var submitAnswerError: String?
    
    func submitAnswer(text: String, authorId: String) async {
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
            try await airtable.createAnswer(for: question, text: trimmed, authorId: authorId)
            await fetchAnswers(for: question)
            await MainActor.run { self.isSubmittingAnswer = false }
        } catch {
            let friendly: String
            if let svcErr = error as? AirtableService.ServiceError {
                switch svcErr {
                case .missingAuthorId: friendly = "Missing author identity. Please sign out and sign in again."   // NEW
                case .invalidQuestionId: friendly = "Invalid question id. Please refresh and try again."          // NEW
                default: friendly = "Failed to submit answer."
                }
            } else {
                friendly = "Failed to submit answer: \(error.localizedDescription)"
            }
            await MainActor.run {
                self.isSubmittingAnswer = false
                self.submitAnswerError = friendly // NEW
            }
        }
    }

}

