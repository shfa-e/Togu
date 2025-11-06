//
//  HomeView.swift
//  Togu
//
//  Created by Whyyy on 05/11/2025.
//


import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var router: Router

	@State private var isSigningOut = false
	@StateObject private var feed = FeedViewModel()

    var body: some View {

		NavigationStack {
			List {
				Section {
					if feed.isLoading {
						ZStack {
							Color.clear
							VStack(spacing: 12) {
								ProgressView()
								Text("Loading questions…")
									.foregroundStyle(.secondary)
							}
							.frame(maxWidth: .infinity, maxHeight: .infinity)
						}
						.listRowInsets(.none)
					} else if let error = feed.errorMessage {
						ZStack {
							Color.clear
							VStack(spacing: 12) {
								Image(systemName: "exclamationmark.triangle")
									.font(.largeTitle)
									.foregroundStyle(.orange)
								Text(error)
									.multilineTextAlignment(.center)
								Button("Retry") { feed.loadQuestions() }
							}
							.padding()
							.frame(maxWidth: .infinity, maxHeight: .infinity)
						}
						.listRowInsets(.none)
					} else if feed.questions.isEmpty {
						ZStack {
							Color.clear
							ContentUnavailableView(
								"No questions yet",
								systemImage: "text.bubble", description: Text("Be the first to ask a question!")
							)
						}
						.listRowInsets(.none)
					} else {
						ForEach(feed.questions) { question in
							NavigationLink(
								destination: QuestionDetailView(
									question: question,
                                    airtable: AirtableService(config: AirtableConfig()!)
								)
							) {
								QuestionRow(question: question)
							}
						}
					}
				}
			}
			.listStyle(.plain)
			.refreshable { feed.loadQuestions() }
			.navigationTitle("Home")
			.onAppear { feed.loadQuestions() }
			.toolbar { signOutToolbar }
		}
    }

	// MARK: - Helpers

    private func signOut() {
        withAnimation { isSigningOut = true }
        auth.signOut()

        // Observe AuthViewModel state change
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isSigningOut = false }
            if case .signedOut = auth.state {
                router.go(.onboarding)
            }
        }
    }

    private func extractUserInfo() -> [String: Any]? {
        switch auth.state {
        case .signedIn(let userInfo):
            return userInfo
        default:
            return nil
        }
    }

	@ToolbarContentBuilder
	private var signOutToolbar: some ToolbarContent {
		ToolbarItem(placement: .topBarTrailing) {
			Menu {
				if let info = extractUserInfo() {
					if let email = info["email"] as? String {
						Label(email, systemImage: "envelope")
					}
				}
				Button(role: .destructive) { signOut() } label: {
					Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
				}
			} label: {
				Image(systemName: "ellipsis.circle")
			}
		}
	}
}

// MARK: - UI Components

private struct QuestionRow: View {
	let question: Question

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(alignment: .firstTextBaseline) {
				Text(question.title)
					.font(.headline)
				Spacer()
				Label("\(question.upvotes)", systemImage: "arrow.up.circle.fill")
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}

			Text(question.text)
				.font(.subheadline)
				.foregroundStyle(.secondary)
				.lineLimit(3)

			if !question.tags.isEmpty {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 8) {
						ForEach(question.tags, id: \.self) { tag in
							Text(tag)
								.font(.caption)
								.padding(.horizontal, 8)
								.padding(.vertical, 4)
								.background(Color.secondary.opacity(0.15))
								.clipShape(Capsule())
						}
					}
				}
			}
		}
		.padding(.vertical, 8)
	}
}
