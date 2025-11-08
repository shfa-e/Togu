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
    @State private var selectedImageData: Data?
    @State private var selectedImageName: String?

    @FocusState private var focusedField: Field?
    enum Field { case title, details, tags }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Title
                Section("Title") {
                    TextField("Enter a short, clear question title", text: $viewModel.title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                }

                // MARK: Details
                Section("Details") {
                    TextEditor(text: $viewModel.body)
                        .frame(minHeight: 150)
                        .focused($focusedField, equals: .details)
                }

                // MARK: Tag Selection
                Section("Tags (select up to 3)") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.availableTags, id: \.self) { tag in
                                Button {
                                    viewModel.toggleTag(tag)
                                } label: {
                                    Text(tag)
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 14)
                                        .background(
                                            viewModel.tags.contains(tag)
                                            ? Color.accentColor.opacity(0.25)
                                            : Color.gray.opacity(0.15)
                                        )
                                        .foregroundColor(
                                            viewModel.tags.contains(tag)
                                            ? .accentColor
                                            : .primary
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                    }
                }

                // MARK: Image
                Section("Image (optional)") {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text(selectedImageName ?? "Pick an image")
                        }
                    }
                    .onChange(of: pickerItem) { newItem in
                        Task { await loadPickedImage(newItem) }
                    }

                    if let data = selectedImageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Ask a Question")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task {await submitQuestion()}
                    }
                    .disabled(!viewModel.canSubmit)
                }
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

    // MARK: - Submit Question
    private func submitQuestion() async {
        // Assign text fields
        viewModel.title = viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.body  = viewModel.body.trimmingCharacters(in: .whitespacesAndNewlines)

        // Attach optional image
        viewModel.setImage(data: selectedImageData, filename: selectedImageName)

        // Directly submit — tags are already selected in the ViewModel
        let ok = await viewModel.submit(auth: auth)

        if ok && viewModel.errorMessage == nil {
            dismiss()
        }
    }

    // MARK: - Load Picked Image
    private func loadPickedImage(_ item: PhotosPickerItem?) async {
        guard let item else {
            await MainActor.run {
                selectedImageData = nil
                selectedImageName = nil
            }
            return
        }

        do {
            let data = try await item.loadTransferable(type: Data.self)
            let name = try await item.loadTransferable(type: String.self) ?? "photo.jpg"
            await MainActor.run {
                selectedImageData = data
                selectedImageName = name
            }
        } catch {
            await MainActor.run {
                selectedImageData = nil
                selectedImageName = nil
            }
            print("❌ Failed to load picked image:", error)
        }
    }
}

#Preview {
    AskQuestionView(viewModel: AskQuestionViewModel(airtable: AirtableService(config: AirtableConfig()!)))
        .environmentObject(AuthViewModel())
        .environmentObject(FeedViewModel())
}
