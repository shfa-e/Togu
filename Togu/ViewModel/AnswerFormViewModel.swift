//
//  AnswerFormViewModel.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation
import Combine

@MainActor
final class AnswerFormViewModel: ObservableObject {
    @Published var answerText: String = ""
    @Published var codeSnippets: [String] = []
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    
    private let maxCharacters = 5000
    private let question: Question
    private let questionDetailViewModel: QuestionDetailViewModel
    
    init(question: Question, questionDetailViewModel: QuestionDetailViewModel) {
        self.question = question
        self.questionDetailViewModel = questionDetailViewModel
    }
    
    // MARK: - Computed Properties for Display
    
    var questionTextWithoutCode: String {
        MarkdownHelpers.removeCodeBlocks(from: question.text)
    }
    
    var questionPreviewText: String {
        let text = questionTextWithoutCode
        return text + (text.count > 100 ? "..." : "")
    }
    
    var isValid: Bool {
        !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        answerText.count <= maxCharacters
    }
    
    var characterCount: Int {
        answerText.count
    }
    
    var remainingCharacters: Int {
        maxCharacters - answerText.count
    }
    
    func addCodeSnippet(_ code: String) {
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        codeSnippets.append(code)
    }
    
    func removeCodeSnippet(at index: Int) {
        guard index >= 0 && index < codeSnippets.count else { return }
        codeSnippets.remove(at: index)
    }
    
    func updateCodeSnippet(at index: Int, with code: String) {
        guard index >= 0 && index < codeSnippets.count else { return }
        codeSnippets[index] = code
    }
    
    func buildFinalAnswerText() -> String {
        var finalAnswer = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Append code snippets if they exist
        if !codeSnippets.isEmpty {
            let codeBlocks = codeSnippets.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if !codeBlocks.isEmpty {
                finalAnswer += "\n\n" + codeBlocks.map { "```\n\($0)\n```" }.joined(separator: "\n\n")
            }
        }
        
        return finalAnswer
    }
    
    func submitAnswer(auth: AuthViewModel) async -> Bool {
        guard isValid else {
            errorMessage = "Answer cannot be empty and must be under \(maxCharacters) characters."
            return false
        }
        
        isSubmitting = true
        errorMessage = nil
        
        let finalText = buildFinalAnswerText()
        
        await questionDetailViewModel.submitAnswer(text: finalText, auth: auth)
        
        if let error = questionDetailViewModel.submitAnswerError {
            errorMessage = error
            isSubmitting = false
            return false
        }
        
        isSubmitting = false
        return true
    }
    
    func reset() {
        answerText = ""
        codeSnippets = []
        errorMessage = nil
    }
}

