//
//  AnswerFormView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct AnswerFormView: View {
    let question: Question
    @ObservedObject var vm: QuestionDetailViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var answerText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(question.title)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Question")
                }
                
                Section {
                    TextEditor(text: $answerText)
                        .frame(minHeight: 150)
                        .focused($isTextFieldFocused)
                } header: {
                    Text("Your Answer")
                } footer: {
                    if let error = vm.submitAnswerError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Answer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            await vm.submitAnswer(text: answerText, auth: auth)
                            if vm.submitAnswerError == nil { dismiss() }
                        }
                    }
                    .disabled(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSubmittingAnswer)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    private func submitAnswer() {
        let authorName = extractAuthorName()
        Task {
            await vm.submitAnswer(text: answerText, authorId: auth.airtableUserId ?? "")
            if vm.submitAnswerError == nil {
                dismiss()
            }
        }
    }
    
    private func extractAuthorName() -> String {
        switch auth.state {
        case .signedIn(let userInfo):
            if let name = userInfo["name"] as? String {
                return name
            }
            if let givenName = userInfo["given_name"] as? String {
                return givenName
            }
            if let email = userInfo["email"] as? String {
                return email
            }
            return "Anonymous"
        default:
            return "Anonymous"
        }
    }
}

