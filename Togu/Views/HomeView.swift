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
    @EnvironmentObject var badgeNotificationManager: BadgeNotificationManager
    
    @StateObject var feed = FeedViewModel()
    @StateObject private var homeViewModel: HomeViewModel

    @State private var showAskQuestion = false
    @State private var showConfigAlert = false
    @State private var airtableService: AirtableService? = {
        guard let config = AirtableConfig() else { return nil }
        return AirtableService(config: config)
    }()
    
    init() {
        guard let config = AirtableConfig() else {
            fatalError("Airtable config not found")
        }
        let service = AirtableService(config: config)
        let tempAuth = AuthViewModel()
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(airtable: service, auth: tempAuth))
    }
    
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
                        LoadingView("Loading questions…")
                            .padding(.top, 40)
                            .padding(.bottom, 100)
					} else if let error = feed.errorMessage {
                        ErrorView(
                            error: error,
                            retryAction: {
                                if case .signedIn = auth.state {
                                    feed.loadQuestions(auth: auth)
                                }
                            }
                        )
                        .padding(.top, 40)
                        .padding(.bottom, 100)
					} else if feed.isEmptyState {
                        EmptyStateView(
                            icon: "text.bubble",
                            title: feed.emptyStateTitle,
                            message: feed.emptyStateMessage,
                            actionTitle: feed.shouldShowEmptyStateAction ? "Ask Question" : nil,
                            action: feed.shouldShowEmptyStateAction ? {
                                showAskQuestion = true
                            } : nil
                        )
                        .padding(.top, 40)
                        .padding(.bottom, 100)
					} else if let service = airtableService {
                        LazyVStack(spacing: 16) {
						ForEach(feed.questions) { question in
							NavigationLink {
								QuestionDetailView(question: question, airtable: service)
									.environmentObject(auth)
									.environmentObject(badgeNotificationManager)
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
                            
                            // Load More Button
                            if feed.hasMorePages {
                                Button {
                                    feed.loadMoreQuestions(auth: auth)
                                } label: {
                                    HStack {
                                        if feed.isLoadingMore {
                                            ProgressView()
                                                .tint(.toguPrimary)
                                        } else {
                                            Text("Load More")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.toguPrimary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.toguPrimary.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .disabled(feed.isLoadingMore)
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.toguLightBackground.ignoresSafeArea())
            .refreshable {
                if case .signedIn = auth.state {
                    feed.loadQuestions(auth: auth)
                    homeViewModel.loadUserProgress()
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
                // Update HomeViewModel's auth reference
                homeViewModel.updateAuth(auth)
                if let service = airtableService {
                    // Update service if needed (though it should already be set)
                    homeViewModel.updateAuth(auth)
                    // Set badge notification manager on service
                    service.badgeNotificationManager = badgeNotificationManager
                }
                homeViewModel.loadUserProgress()
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
        )
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(availableTags, id: \.self) { tag in
                    Button {
                        if case .signedIn = auth.state {
                            feed.selectTag(tag, auth: auth)
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
                                            : Color.toguLightBackground
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
                    Text("Level \(homeViewModel.levelInfo.level) Developer")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(FormattingHelpers.formatXP(homeViewModel.userPoints)) XP")
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
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * min(homeViewModel.levelInfo.progress, 1.0), height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(homeViewModel.levelInfo.xpNeeded) XP to Level \(homeViewModel.levelInfo.level + 1)")
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
    
}
