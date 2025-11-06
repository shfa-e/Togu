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

}

