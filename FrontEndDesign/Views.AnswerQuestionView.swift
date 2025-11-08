//
//  Views.AnswerQuestionView.swift
//  Togu
//
//  Created by HY on 05/11/2025.
//

import SwiftUI


struct AnswerQuestionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var answerText: String = ""
    @State private var codeSnippets: [String] = []
    
    // Sample question data - in real app, this would be passed as a parameter
    let question: Post = Post(
        community: "SwiftUI",
        author: "Alex Chen",
        authorLevel: 15,
        title: "How to implement custom transitions in SwiftUI?",
        contentPreview: "I'm trying to create a custom slide transition for my views but can't get the animation timing right. Has anyone worked with matchedGeometryEffect for",
        upvotes: 12,
        downvotes: 0,
        commentCount: 5,
        tags: ["SwiftUI", "Animation"],
        codeSnippet: nil
    )
    
    // Custom date for display (2 hours ago)
    private let questionDate = Date().addingTimeInterval(-7200)
    
    
    private let maxCharacters = 5000
    
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
            .background(Color.toguBackground.ignoresSafeArea())
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
        }
    }
    
    // MARK: - Question Details
    private var questionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Profile Picture
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.toguTextSecondary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.author)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.toguTextPrimary)
                    
                    Text(timeAgoString(from: questionDate))
                        .font(.system(size: 13))
                        .foregroundColor(.toguTextSecondary)
                }
                
                Spacer()
            }
            
            Text(question.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.toguTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(question.contentPreview + "...")
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
    
    // MARK: - Your Answer Section
    private var yourAnswerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Answer")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            
            ZStack(alignment: .topLeading) {
                // Text Editor
                TextEditor(text: $answerText)
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
                if answerText.isEmpty {
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
                toolbarIcon(icon: "chevron.left.forwardslash.chevron.right", action: {})
                toolbarIcon(icon: "photo", action: {})
                toolbarIcon(icon: "link", action: {})
                toolbarIcon(icon: "list.bullet", action: {})
                
                Spacer()
                
                // Character Counter
                Text("\(answerText.count) / \(maxCharacters)")
                    .font(.system(size: 12))
                    .foregroundColor(answerText.count > maxCharacters ? .red : .toguTextSecondary)
            }
            .padding(.top, 8)
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
        HStack {
            Text("Add Code Snippet")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            
            Spacer()
            
            Button {
                // Add code snippet action
                codeSnippets.append("")
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
                Text("Earn +25 XP For posting a helpful answer")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.toguTextPrimary)
                
                Text("Possible bonus +50 XP")
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
                // Post answer action
                dismiss()
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
                        .fill(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.toguPrimary)
                )
            }
            .disabled(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.toguBackground)
        }
    }
    
    // MARK: - Helper Functions
    private func timeAgoString(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "Posted \(hours) hour\(hours > 1 ? "s" : "") ago"
        } else if minutes > 0 {
            return "Posted \(minutes) minute\(minutes > 1 ? "s" : "") ago"
        } else {
            return "Posted just now"
        }
    }
}

#Preview {
    AnswerQuestionView()
}
