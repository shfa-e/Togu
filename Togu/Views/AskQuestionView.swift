//
//  AskQuestionView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI
import PhotosUI
import UIKit

struct AskQuestionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var feed: FeedViewModel

    @ObservedObject var viewModel: AskQuestionViewModel

    // Image picker
    @State private var pickerItem: PhotosPickerItem?
    @State private var showingCodeEditor = false

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
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.toguError)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.toguError.opacity(0.1))
                            )
                    }
                    
                    // Bottom Spacing
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(hex: "#F5F5F5").ignoresSafeArea())
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
            }
            .safeAreaInset(edge: .bottom) {
                bottomActionButtons
            }
            .sheet(isPresented: $showingCodeEditor) {
                codeEditorSheet
            }
            .overlay {
                if viewModel.isSubmitting {
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
    
    // MARK: - Question Title Section
    private var questionTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Question Title")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            
            TextField("e.g., How to implement custom transitions in SwiftUI?", text: $viewModel.title)
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
                TextEditor(text: $viewModel.body)
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
                
                if viewModel.body.isEmpty {
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
            
            if let code = viewModel.codeSnippet, !code.isEmpty {
                HStack {
                    Text(code)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.toguTextSecondary)
                        .lineLimit(3)
                    Spacer()
                    
                    Button {
                        viewModel.codeSnippet = nil
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
            
            // Selected Tags
            if !viewModel.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            HStack(spacing: 6) {
                                Text(tag)
                                    .font(.system(size: 13))
                                Button {
                                    viewModel.removeTag(tag)
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
                                    .stroke(Color.toguBorder, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            // Available Tags
            VStack(alignment: .leading, spacing: 10) {
                
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.availableTags, id: \.self) { tag in
                        Button {
                            if viewModel.tags.contains(tag) {
                                viewModel.removeTag(tag)
                            } else if viewModel.tags.count < 5 {
                                viewModel.addTag(tag)
                            }
                        } label: {
                            Text(tag)
                                .font(.system(size: 13))
                                .foregroundColor(viewModel.tags.contains(tag) ? .white : .toguTextSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(viewModel.tags.contains(tag) ? Color.toguPrimary : Color(hex: "#F5F5F5"))
                                )
                        }
                        .disabled(viewModel.tags.count >= 5 && !viewModel.tags.contains(tag))
                    }
                }
                
                
                Text("Select up to 5 tags to help categorize your question")
                    .font(.system(size: 13))
                    .foregroundColor(.toguTextSecondary)
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
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    attachmentButtonContent(icon: "photo", label: "Image")
                }
                .onChange(of: pickerItem) { newItem in
                    Task { await loadPickedImage(newItem) }
                }
                
                attachmentButton(icon: "doc", label: "File", action: {
                    // File attachment - can be implemented later
                })
                attachmentButton(icon: "link", label: "Link", action: {
                    // Link attachment - can be implemented later
                })
            }
            
            if let data = viewModel.imageData,
               let uiImage = UIImage(data: data) {
                HStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                    
                    Button {
                        viewModel.clearImage()
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
    
    private func attachmentButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            attachmentButtonContent(icon: icon, label: label)
        }
    }
    
    private func attachmentButtonContent(icon: String, label: String) -> some View {
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
                    Task { await submitQuestion() }
                } label: {
                    Text("Post Question")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.canSubmit ? Color.toguPrimary : Color.gray)
                        )
                }
                .disabled(!viewModel.canSubmit)
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
                    get: { viewModel.codeSnippet ?? "" },
                    set: { viewModel.codeSnippet = $0.isEmpty ? nil : $0 }
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
    
    // MARK: - Submit Question
    private func submitQuestion() async {
        let ok = await viewModel.submit(auth: auth)

        if ok && viewModel.errorMessage == nil {
            dismiss()
        }
    }
    
    // MARK: - Load Picked Image
    private func loadPickedImage(_ item: PhotosPickerItem?) async {
        guard let item else {
            viewModel.setPickedImage(data: nil, filename: nil)
            return
        }

        do {
            let data = try await item.loadTransferable(type: Data.self)
            let name = try await item.loadTransferable(type: String.self) ?? "photo.jpg"
            viewModel.setPickedImage(data: data, filename: name)
        } catch {
            viewModel.setPickedImage(data: nil, filename: nil)
            print("❌ Failed to load picked image:", error)
        }
    }
}

#Preview {
    AskQuestionView(viewModel: AskQuestionViewModel(airtable: AirtableService(config: AirtableConfig()!)))
        .environmentObject(AuthViewModel())
        .environmentObject(FeedViewModel())
}
