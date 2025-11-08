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
    
    @StateObject var feed = FeedViewModel()

    @State private var showAskQuestion = false
    @State private var showConfigAlert = false
    @State private var airtableService: AirtableService? = {
        guard let config = AirtableConfig() else { return nil }
        return AirtableService(config: config)
    }()
    
    // User progress data
    @State private var userPoints: Int = 0
    @State private var isLoadingUserData = false
    
    // Available tags for filtering (must match Airtable database tags)
    private let availableTags = [
        "All", "iOS", "Frontend", "Backend", "Swift", "UX",
        "UI", "Database", "General", "API", "Learning"
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    // Search Bar
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Filter Bar
                    filterBar
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // User Progress Card
                    userProgressCard
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Questions List
					if feed.isLoading {
                        VStack(spacing: 16) {
								ProgressView()
								Text("Loading questions…")
                                .font(.subheadline)
                                .foregroundColor(.toguTextSecondary)
							}
                        .padding(.top, 40)
                        .padding(.bottom, 100)
					} else if let error = feed.errorMessage {
                        VStack(spacing: 16) {
								Image(systemName: "exclamationmark.triangle")
									.font(.largeTitle)
                                .foregroundColor(.orange)
								Text(error)
									.multilineTextAlignment(.center)
                            Button("Retry") {
                                if case .signedIn = auth.state {
                                    feed.loadQuestions(auth: auth)
                                }
							}
						}
                        .padding(.top, 40)
                        .padding(.bottom, 100)
					} else if feed.questions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 60))
                                .foregroundColor(.toguTextSecondary)
                            Text(feed.searchText.isEmpty && feed.selectedTag == nil
                                 ? "No questions yet"
                                 : "No questions found")
                                .font(.headline)
                                .foregroundColor(.toguTextPrimary)
                            Text(feed.searchText.isEmpty && feed.selectedTag == nil
                                 ? "Be the first to ask a question!"
                                 : "Try a different search term or filter")
                                .font(.subheadline)
                                .foregroundColor(.toguTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 100)
					} else if let service = airtableService {
                        LazyVStack(spacing: 16) {
						ForEach(feed.questions) { question in
							NavigationLink {
								QuestionDetailView(question: question, airtable: service)
									.environmentObject(auth)
							} label: {
                                    QuestionCardView(
                                        question: question,
                                        airtable: service,
                                        upAction: {
                                            Task {
                                                await feed.upvoteQuestion(question, auth: auth)
                                            }
                                        },
                                        upvoteCount: feed.updatedQuestionVotes[question.id] ?? question.upvotes,
                                        hasVoted: question.userHasVoted
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color(hex: "#F5F5F5").ignoresSafeArea())
            .refreshable {
                if case .signedIn = auth.state {
                    feed.loadQuestions(auth: auth)
                    loadUserProgress()
                }
            }
            Spacer()
            
            // Floating Action Button
            floatingActionButton
        }
        .navigationBarHidden(true)
        .onAppear {
            if case .signedIn = auth.state {
                feed.loadQuestions(auth: auth)
                loadUserProgress()
			}
		}
        .sheet(isPresented: $showAskQuestion) {
            if let service = airtableService {
                AskQuestionView(
                    viewModel: {
                        let vm = AskQuestionViewModel(airtable: service)
                        vm.onCreated = { question in
                            feed.prepend(question)
                            if let service = airtableService {
                                Task {
                                    await feed.reload(using: service, auth: auth)
                                }
                            }
                        }
                        return vm
                    }()
                )
                .environmentObject(auth)
                .environmentObject(feed)
            } else {
                Text("Airtable not configured")
                    .padding()
            }
        }
        .alert("Airtable Not Configured", isPresented: $showConfigAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Add AIRTABLE_KEY and AIRTABLE_BASE_ID to Info.plist before posting questions.")
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Text("Togu")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
            }
            
            Spacer()
            
            // Profile icon - navigate to profile
            NavigationLink {
                if let service = airtableService {
                    ProfileView(airtable: service, auth: auth)
                        .environmentObject(auth)
                }
            } label: {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.toguPrimary.opacity(0.3),
                                Color.toguPrimary.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.toguPrimary)
                    )
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.toguTextSecondary)
                .font(.system(size: 16))
            
            TextField("Search questions, topics...", text: $feed.searchText)
                .font(.system(size: 15))
                .foregroundColor(.toguTextPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    if case .signedIn = auth.state {
                        feed.loadQuestions(auth: auth)
                    }
                }
                .onChange(of: feed.searchText) { oldValue, newValue in
                    // Debounce search
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        if feed.searchText == newValue && !newValue.isEmpty {
                            if case .signedIn = auth.state {
                                feed.loadQuestions(auth: auth)
                            }
                        } else if feed.searchText.isEmpty && oldValue != newValue {
                            if case .signedIn = auth.state {
                                feed.loadQuestions(auth: auth)
                            }
                        }
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(availableTags, id: \.self) { tag in
                    Button {
                        if tag == "All" {
                            feed.selectedTag = nil
                        } else {
                            feed.selectedTag = (feed.selectedTag == tag) ? nil : tag
                        }
                        if case .signedIn = auth.state {
                            feed.loadQuestions(auth: auth)
				}
			} label: {
                        Text(tag)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(
                                (tag == "All" && feed.selectedTag == nil) || feed.selectedTag == tag
                                    ? .white
                                    : .toguTextPrimary
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        (tag == "All" && feed.selectedTag == nil) || feed.selectedTag == tag
                                            ? Color.toguPrimary
                                            : Color(hex: "#F5F5F5")
                                    )
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - User Progress Card
    private var userProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(calculateLevel(from: userPoints)) Developer")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(formatXP(userPoints)) XP")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
				Spacer()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 6)
                    
                    let currentLevelXP = userPoints % 100
                    let nextLevelXP = 100
                    let progress = Double(currentLevelXP) / Double(nextLevelXP)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 6)
                }
            }
            .frame(height: 6)
            
            let currentLevelXP = userPoints % 100
            let nextLevelXP = 100
            let xpNeeded = nextLevelXP - currentLevelXP
            Text("\(xpNeeded) XP to Level \(calculateLevel(from: userPoints) + 1)")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.toguPrimary,
                    Color.toguPrimary.opacity(0.8)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        Button {
            if airtableService == nil {
                showConfigAlert = true
            } else {
                showAskQuestion = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.toguPrimary)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
        }
        .padding(.trailing, 17)
        .padding(.bottom, 68)
    }
    
    // MARK: - Helpers
    
    private func loadUserProgress() {
        guard let service = airtableService, !isLoadingUserData else { return }
        isLoadingUserData = true
        
        Task {
            do {
                // Resolve user ID
                var userId: String?
                if let id = auth.airtableUserId, !id.isEmpty, id.hasPrefix("rec") {
                    userId = id
                } else {
                    var email: String?
                    if case .signedIn(let claims) = auth.state {
                        email = (claims["email"] as? String)
                            ?? (claims["upn"] as? String)
                            ?? (claims["preferred_username"] as? String)
                    }
                    
                    if let userEmail = email, !userEmail.isEmpty {
                        let name = (auth.state.userInfo?["name"] as? String) ?? userEmail
                        userId = try await service.createUserIfMissing(name: name, email: userEmail)
                        await MainActor.run { auth.airtableUserId = userId }
                    }
                }
                
                if let userId = userId {
                    let (_, userFields) = try await service.fetchUser(recordId: userId)
                    await MainActor.run {
                        userPoints = userFields.Points ?? 0
                        isLoadingUserData = false
                    }
                } else {
                    await MainActor.run {
                        isLoadingUserData = false
                    }
                }
            } catch {
                print("⚠️ Failed to load user progress: \(error)")
                await MainActor.run {
                    isLoadingUserData = false
                }
            }
        }
    }
    
    private func calculateLevel(from xp: Int) -> Int {
        max(1, xp / 100 + 1)
    }
    
    private func formatXP(_ xp: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: xp)) ?? "\(xp)"
    }
}
