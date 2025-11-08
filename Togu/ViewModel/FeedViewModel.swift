//
//  FeedViewModel.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
	@Published var isLoading: Bool = false
	@Published var errorMessage: String? = nil
    @Published var questions: [Question] = []

    private lazy var airtableServiceInternal: AirtableService? = {
        guard let config = AirtableConfig() else {
            return nil
        }
        return AirtableService(config: config)
    }()

    var airtableService: AirtableService? { airtableServiceInternal }

	func loadQuestions() {
		isLoading = true
		errorMessage = nil

        Task {
            guard let airtable = self.airtableServiceInternal else {
				self.errorMessage = "Airtable not configured. Check Info.plist keys."
				self.isLoading = false
				return
			}
			do {
				let items = try await airtable.fetchQuestions()
				self.questions = items
				self.isLoading = false
			} catch {
				self.errorMessage = "Failed to load questions."
				self.isLoading = false
			}
		}
	}

    func prepend(_ question: Question) {
        if let existingIndex = questions.firstIndex(where: { $0.id == question.id }) {
            questions.remove(at: existingIndex)
        }
        questions.insert(question, at: 0)
    }
        
        // Refresh the feed from Airtable after posting (keeps order/metadata authoritative).
    func reload(using service: AirtableService) async {
        do {
            let latest = try await service.fetchQuestions()
            self.questions = latest
        } catch {
            // Optional: surface/log non-blocking error
            // print("Reload failed: \(error)")
        }
    }
    
}

