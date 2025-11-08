//
//  AskQuestionViewModel.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation
import Combine

@MainActor
final class AskQuestionViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var body: String = ""
    @Published private(set) var tags: [String] = []
    @Published var imageData: Data?
    @Published var imageFilename: String?
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var availableTags: [String] = [
           "iOS", "Swift", "UI", "Database", "Backend",
           "Frontend", "API", "Airtable", "Learning", "General"]

    private let maxTags = 3
    private let airtable: AirtableService
    var onCreated: ((Question) -> Void)?

    init(airtable: AirtableService) {
        self.airtable = airtable
    }

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSubmitting
    }

    var canAddMoreTags: Bool { tags.count < maxTags }

    func toggleTag(_ tag: String) {
        if let index = tags.firstIndex(of: tag) {
            tags.remove(at: index)
        } else {
            guard canAddMoreTags else {
                errorMessage = "You can select up to \(maxTags) tags."
                return
            }
            tags.append(tag)
            errorMessage = nil
        }
    }

    func setImage(data: Data?, filename: String?) {
        imageData = data
        imageFilename = filename
    }

    func clearImage() {
        imageData = nil
        imageFilename = nil
    }

    func submit(auth: AuthViewModel) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Title cannot be empty."
            return false
        }

        guard !trimmedBody.isEmpty else {
            errorMessage = "Description cannot be empty."
            return false
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let authorId = try await resolveAuthorId(from: auth)
            let attachment = makeImageAttachment()
            let question = try await airtable.createQuestion(
                title: trimmedTitle,
                body: trimmedBody,
                tags: tags,
                authorId: authorId,
                image: attachment
            )

            onCreated?(question)
            resetForm()
            isSubmitting = false
            return true
        } catch {
            isSubmitting = false
            if let svcError = error as? AirtableService.ServiceError {
                switch svcError {
                case .missingAuthorId:
                    errorMessage = "We couldn't identify your profile. Please sign out and sign in again."
                case .invalidQuestionId:
                    errorMessage = "Invalid question id returned from Airtable."
                case .http:
                    errorMessage = "Airtable returned an error. Please try again."
                default:
                    errorMessage = "Failed to submit question."
                }
            } else {
                errorMessage = error.localizedDescription
            }
            return false
        }
    }

    private func resetForm() {
        title = ""
        body = ""
        availableTags = []
        tags = []
        imageData = nil
        imageFilename = nil
    }

    private func resolveAuthorId(from auth: AuthViewModel) async throws -> String {
        if let id = auth.airtableUserId, !id.isEmpty { return id }

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

    private func makeImageAttachment() -> AirtableService.NewQuestionImage? {
        guard let data = imageData else { return nil }
        let filename = imageFilename ?? "photo.jpg"
        let mime = detectMimeType(for: data)
        return AirtableService.NewQuestionImage(data: data, filename: filename, mimeType: mime)
    }

    private func detectMimeType(for data: Data) -> String {
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        return "application/octet-stream"
    }
}


