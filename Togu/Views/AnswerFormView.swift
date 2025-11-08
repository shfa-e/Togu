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
    
    @StateObject private var answerViewModel: AnswerFormViewModel
    @State private var showingCodeEditor = false
    @State private var currentCodeSnippetIndex: Int?
    
    init(question: Question, vm: QuestionDetailViewModel) {
        self.question = question
        self.vm = vm
        _answerViewModel = StateObject(wrappedValue: AnswerFormViewModel(question: question, questionDetailViewModel: vm))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Question Details Section
                    questionDetailsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Your Answer Section
                    yourAnswerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    
                    // Add Code Snippet Section
                    codeSnippetSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    
                    // Tips Card
                    tipsCard
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    
                    // Earn XP Card
                    earnXPCard
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Bottom Spacing
                    Spacer()
                        .frame(height: 100)
                }
            }
            .background(Color(hex: "#F5F5F5").ignoresSafeArea())
            .navigationTitle("Post Answer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.toguTextPrimary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                postAnswerButton
            }
            .sheet(isPresented: $showingCodeEditor) {
                codeEditorSheet
            }
            .overlay {
                if answerViewModel.isSubmitting {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        ProgressView("Posting…")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Question Details Section
    private var questionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Profile Picture
                Group {
                    if let imageURL = question.authorProfilePictureURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                profilePlaceholder
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                profilePlaceholder
                            @unknown default:
                                profilePlaceholder
                            }
                        }
                    } else {
                        profilePlaceholder
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.author)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.toguTextPrimary)
                    
                    Text(timeAgoString(from: question.createdAt))
                        .font(.system(size: 13))
                        .foregroundColor(.toguTextSecondary)
                }
                
                Spacer()
            }
            
            Text(question.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.toguTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(answerViewModel.questionPreviewText)
                .font(.system(size: 14))
                .foregroundColor(.toguTextSecondary)
                .lineLimit(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.toguTextSecondary)
            )
    }
    
    // MARK: - Your Answer Section
    private var yourAnswerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Answer")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            
            ZStack(alignment: .topLeading) {
                // Text Editor
                TextEditor(text: $answerViewModel.answerText)
                    .frame(minHeight: 200)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#E5E5E5"), lineWidth: 1)
                            )
                    )
                
                // Placeholder
                if answerViewModel.answerText.isEmpty {
                    Text("Share your knowledge and help the community...")
                        .font(.system(size: 15))
                        .foregroundColor(.toguTextSecondary.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            
            // Toolbar
            HStack {
                // Toolbar Icons
                toolbarIcon(icon: "chevron.left.forwardslash.chevron.right") {
                    showingCodeEditor = true
                    currentCodeSnippetIndex = nil
                }
                toolbarIcon(icon: "photo", action: {
                    // Photo action - can be implemented later
                })
                toolbarIcon(icon: "link", action: {
                    // Link action - can be implemented later
                })
                toolbarIcon(icon: "list.bullet", action: {
                    // List action - can be implemented later
                })
                
                Spacer()
                
                // Character Counter
                Text("\(answerViewModel.characterCount) / 5000")
                    .font(.system(size: 12))
                    .foregroundColor(answerViewModel.characterCount > 5000 ? .toguError : .toguTextSecondary)
            }
            .padding(.top, 8)
            
            // Error Message
            if let error = vm.submitAnswerError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.toguError)
                    .padding(.top, 4)
            }
        }
    }
    
    private func toolbarIcon(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.toguTextSecondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.toguCard)
                )
        }
    }
    
    // MARK: - Code Snippet Section
    private var codeSnippetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Add Code Snippet")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                
                Spacer()
                
                Button {
                    showingCodeEditor = true
                    currentCodeSnippetIndex = nil
                } label: {
                    Text("+ Add Code")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.toguPrimary)
                        .cornerRadius(8)
                }
            }
            
            // Display code snippets
            if !answerViewModel.codeSnippets.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(answerViewModel.codeSnippets.enumerated()), id: \.offset) { index, code in
                        if !code.isEmpty {
                            HStack {
                                Text(code)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.toguTextSecondary)
                                    .lineLimit(3)
                                Spacer()
                                
                                Button {
                                    answerViewModel.removeCodeSnippet(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.toguTextSecondary)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#F5F5F5"))
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Tips Card
    private var tipsCard: some View {
        HStack(alignment: .top, spacing: 16) {
            // Lightbulb Icon
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 24))
                .foregroundColor(.toguPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Tips for great answers")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                
                VStack(alignment: .leading, spacing: 10) {
                    tipRow(text: "Be clear and provide working code examples")
                    tipRow(text: "Explain why your solution works")
                    tipRow(text: "Add relevant links or documentation")
                    tipRow(text: "Be respectful and constructive")
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.toguPrimary.opacity(0.1))
        )
    }
    
    private func tipRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.toguPrimary)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.toguTextSecondary)
        }
    }
    
    // MARK: - Earn XP Card
    private var earnXPCard: some View {
        HStack(spacing: 16) {
            // Trophy Icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 24))
                .foregroundColor(.toguPrimary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Earn +5 XP For posting a helpful answer")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.toguTextPrimary)
                
                Text("Possible bonus +1 XP per upvote")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.toguPrimary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.toguPrimary.opacity(0.1))
        )
    }
    
    // MARK: - Post Answer Button
    private var postAnswerButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                Task {
                    let success = await answerViewModel.submitAnswer(auth: auth)
                    if success {
                        answerViewModel.reset()
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    Text("Post Your Answer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(answerViewModel.isValid ? Color.toguPrimary : Color.gray)
                )
            }
            .disabled(!answerViewModel.isValid || answerViewModel.isSubmitting)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.toguBackground)
        }
    }
    
    // MARK: - Code Editor Sheet
    private var codeEditorSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: Binding(
                    get: {
                        if let index = currentCodeSnippetIndex, index < answerViewModel.codeSnippets.count {
                            return answerViewModel.codeSnippets[index]
                        }
                        return ""
                    },
                    set: { newValue in
                        if let index = currentCodeSnippetIndex, index < answerViewModel.codeSnippets.count {
                            answerViewModel.updateCodeSnippet(at: index, with: newValue)
                        } else {
                            // Add new code snippet
                            if !newValue.isEmpty {
                                answerViewModel.addCodeSnippet(newValue)
                            }
                        }
                    }
                ))
                .font(.system(size: 14, design: .monospaced))
                .padding()
                .background(Color(hex: "#F5F5F5"))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Code Snippet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCodeEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingCodeEditor = false
                    }
                    .foregroundColor(.toguPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Helper Functions
    private func timeAgoString(from date: Date) -> String {
        FormattingHelpers.timeAgo(from: date)
    }
}
