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

    @State private var isSigningOut = false
    @State private var showAskQuestion = false
    @State private var showConfigAlert = false
    @State private var airtableService: AirtableService? = {
        guard let config = AirtableConfig() else { return nil }
        return AirtableService(config: config)
    }()

    // Available tags for filtering (same as in AskQuestionViewModel)
    private let availableTags = [
        "iOS", "Swift", "UI", "Database", "Backend",
        "Frontend", "API", "Airtable", "Learning", "General"
    ]
    
    var body: some View {
        NavigationStack {
            List {
                // Search and Filter Section
                Section {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search questions...", text: $feed.searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit {
                                if case .signedIn = auth.state {
                                    feed.loadQuestions(auth: auth)
                                }
                            }
                            .onChange(of: feed.searchText) { oldValue, newValue in
                                // Debounce search - reload after user stops typing
                                Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                    // Only reload if the search text hasn't changed during the delay
                                    if feed.searchText == newValue && !newValue.isEmpty {
                                        if case .signedIn = auth.state {
                                            feed.loadQuestions(auth: auth)
                                        }
                                    } else if feed.searchText.isEmpty && oldValue != newValue {
                                        // Reload immediately when search is cleared
                                        if case .signedIn = auth.state {
                                            feed.loadQuestions(auth: auth)
                                        }
                                    }
                                }
                            }
                        
                        if !feed.searchText.isEmpty {
                            Button {
                                feed.searchText = ""
                                if case .signedIn = auth.state {
                                    feed.loadQuestions(auth: auth)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Tag Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // "All" button to clear filter
                            Button {
                                feed.selectedTag = nil
                                if case .signedIn = auth.state {
                                    feed.loadQuestions(auth: auth)
                                }
                            } label: {
                                Text("All")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        feed.selectedTag == nil
                                            ? Color.accentColor
                                            : Color.secondary.opacity(0.15)
                                    )
                                    .foregroundColor(
                                        feed.selectedTag == nil
                                            ? .white
                                            : .primary
                                    )
                                    .clipShape(Capsule())
                            }
                            
                            // Tag filter buttons
                            ForEach(availableTags, id: \.self) { tag in
                                Button {
                                    feed.selectedTag = (feed.selectedTag == tag) ? nil : tag
                                    if case .signedIn = auth.state {
                                        feed.loadQuestions(auth: auth)
                                    }
                                } label: {
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            feed.selectedTag == tag
                                                ? Color.accentColor
                                                : Color.secondary.opacity(0.15)
                                        )
                                        .foregroundColor(
                                            feed.selectedTag == tag
                                                ? .white
                                                : .primary
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                } header: {
                    Text("Search & Filter")
                }
                
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
                                Button("Retry") {
                                    if case .signedIn = auth.state {
                                        feed.loadQuestions(auth: auth)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .listRowInsets(.none)
                    } else if feed.questions.isEmpty {
                        ZStack {
                            Color.clear
                            ContentUnavailableView(
                                feed.searchText.isEmpty && feed.selectedTag == nil
                                    ? "No questions yet"
                                    : "No questions found",
                                systemImage: "text.bubble",
                                description: Text(
                                    feed.searchText.isEmpty && feed.selectedTag == nil
                                        ? "Be the first to ask a question!"
                                        : feed.selectedTag != nil
                                            ? "Try a different tag or search term"
                                            : "Try a different search term"
                                )
                            )
                        }
                        .listRowInsets(.none)
                    } else if let service = airtableService {
                        ForEach(feed.questions) { question in
                            NavigationLink {
                                QuestionDetailView(question: question, airtable: service)
                                    .environmentObject(auth)
                            } label: {
                                QuestionRow(question: question, feed: feed)
                                    .environmentObject(auth)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text("Airtable configuration is missing. Add your keys to Info.plist to load questions.")
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 32)
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                if case .signedIn = auth.state {
                    feed.loadQuestions(auth: auth)
                }
            }
            .navigationTitle("Home")
            .onAppear {
                if case .signedIn = auth.state {
                    feed.loadQuestions(auth: auth)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if airtableService == nil {
                            showConfigAlert = true
                        } else {
                            showAskQuestion = true
                        }
                    } label: {
                        Label("Ask", systemImage: "plus")
                    }
                    .accessibilityIdentifier("home.askQuestion")
                    .disabled(airtableService == nil)
                }
                signOutToolbar()
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
    private func signOutToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if let info = extractUserInfo(),
                   let email = info["email"] as? String {
                    Label(email, systemImage: "envelope")
                }
                
                Divider()
                
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
    @ObservedObject var feed: FeedViewModel
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(question.title)
                    .font(.headline)
                Spacer()

                Button {
                    Task { await feed.upvoteQuestion(question, auth: auth) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: question.userHasVoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                            .font(.subheadline)
                        Text("\(feed.updatedQuestionVotes[question.id] ?? question.upvotes)")
                            .font(.subheadline)
                    }
                }
                .buttonStyle(.borderless)
                .foregroundColor(question.userHasVoted ? .blue : .secondary)
                .disabled(question.userHasVoted || feed.isVoting)
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
