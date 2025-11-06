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

	private lazy var airtable = AirtableService()

	func loadQuestions() {
		isLoading = true
		errorMessage = nil

		Task {
			guard let airtable else {
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
}


