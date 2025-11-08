//
//  Views.NewQuestionView.swift
//  Togu
//
//  Created by HY on 05/11/2025.
//

import SwiftUI

struct NewQuestionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var tags: [String] = []
    @State private var tagInput: String = ""
    @State private var codeSnippet: String? = nil
    @State private var showingCodeEditor = false
    
    var onPost: (String, String, [String], String?) -> Void
    
    let popularTags = ["SwiftUI", "UIKit", "Xcode", "Core Data", "Combine", "AI/ML", "Animation", "Swift"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Question Title
                    questionTitleSection
                    
                    // Description
                    descriptionSection
                    
                    // Code Snippet
                    codeSnippetSection
                    
                    // Tags
                    tagsSection
                    
                    // Attachments
                    attachmentsSection
                    
                    // Writing Tips
                    writingTipsCard
                    
                    // Bottom Spacing
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.toguBackground.ignoresSafeArea())
            .navigationTitle("Ask a Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.toguTextPrimary)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Preview") {
                        // Preview action
                    }
                    .foregroundColor(.toguPrimary)
                    .font(.system(size: 15, weight: .medium))
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomActionButtons
            }
            .sheet(isPresented: $showingCodeEditor) {
                codeEditorSheet
            }
        }
    }
    
    // MARK: - Question Title Section
    private var questionTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Question Title")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            
            TextField("e.g., How to implement custom transitions in SwiftUI?", text: $title)
                .font(.system(size: 15))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "#E5E5E5"), lineWidth: 1)
                        )
                )
            
            Text("Be specific and concise. This helps others find your question.")
                .font(.system(size: 13))
                .foregroundColor(.toguTextSecondary)
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $description)
                    .frame(minHeight: 150)
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
                
                if description.isEmpty {
                    Text("Describe your question in detail. Include what you've tried and what you're trying to achieve...")
                        .font(.system(size: 15))
                        .foregroundColor(.toguTextSecondary.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            
            Text("Provide context and details to help others understand your problem.")
                .font(.system(size: 13))
                .foregroundColor(.toguTextSecondary)
        }
    }
    
    // MARK: - Code Snippet Section
    private var codeSnippetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Code Snippet (Optional)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                
                Spacer()
                
                Button {
                    showingCodeEditor = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 14))
                        Text("Add Code")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.toguPrimary)
                }
            }
            
            if let code = codeSnippet {
                HStack {
                    Text(code)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.toguTextSecondary)
                    Spacer()
                    
                    Button {
                        codeSnippet = nil
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
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            
            HStack(spacing: 12) {
                Image(systemName: "tag")
                    .foregroundColor(.toguTextSecondary)
                    .font(.system(size: 16))
                
                TextField("Add tags (e.g., SwiftUI, UIKit, Xcode)", text: $tagInput)
                    .font(.system(size: 15))
                    .onSubmit {
                        addTag()
                    }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#E5E5E5"), lineWidth: 1)
                    )
            )
            
            Text("Add up to 5 tags to help categorize your question")
                .font(.system(size: 13))
                .foregroundColor(.toguTextSecondary)
            
            // Selected Tags
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 6) {
                                Text(tag)
                                    .font(.system(size: 13))
                                Button {
                                    tags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.toguPrimary)
                            )
                        }
                    }
                }
            }
            
            // Popular Tags
            VStack(alignment: .leading, spacing: 10) {
                Text("Popular Tags")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.toguTextPrimary)
                
                FlowLayout(spacing: 8) {
                    ForEach(popularTags, id: \.self) { tag in
                        if !tags.contains(tag) && tags.count < 5 {
                            Button {
                                if tags.count < 5 {
                                    tags.append(tag)
                                }
                            } label: {
                                Text(tag)
                                    .font(.system(size: 13))
                                    .foregroundColor(.toguTextSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "#F5F5F5"))
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Attachments Section
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attachments (Optional)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            
            HStack(spacing: 12) {
                attachmentButton(icon: "photo", label: "Image", action: {})
                attachmentButton(icon: "doc", label: "File", action: {})
                attachmentButton(icon: "link", label: "Link", action: {})
            }
        }
    }
    
    private func attachmentButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.toguPrimary)
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.toguTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#E5E5E5"), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Writing Tips Card
    private var writingTipsCard: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 24))
                .foregroundColor(.toguPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Writing Tips")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                
                VStack(alignment: .leading, spacing: 10) {
                    tipRow(text: "Be clear and specific in your title")
                    tipRow(text: "Include relevant code snippets")
                    tipRow(text: "Explain what you've already tried")
                    tipRow(text: "Use appropriate tags for visibility")
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
    
    // MARK: - Bottom Action Buttons
    private var bottomActionButtons: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                Button {
                    // Save draft action
                    dismiss()
                } label: {
                    Text("Save Draft")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.toguTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#F5F5F5"))
                        )
                }
                
                Button {
                    // Post question action
                    postQuestion()
                } label: {
                    Text("Post Question")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isValid ? Color.toguPrimary : Color.gray)
                        )
                }
                .disabled(!isValid)
            }
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
                    get: { codeSnippet ?? "" },
                    set: { codeSnippet = $0.isEmpty ? nil : $0 }
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
    
    // MARK: - Computed Properties
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Helper Functions
    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && tags.count < 5 && !tags.contains(trimmed) {
            tags.append(trimmed)
            tagInput = ""
        }
    }
    
    private func postQuestion() {
        onPost(title, description, tags, codeSnippet)
        dismiss()
    }
}

#Preview {
    NewQuestionView(onPost: { _, _, _, _ in })
}
