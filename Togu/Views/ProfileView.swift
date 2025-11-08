//
//  ProfileView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    
    let airtable: AirtableService
    
    init(airtable: AirtableService, auth: AuthViewModel) {
        self.airtable = airtable
        _viewModel = StateObject(wrappedValue: ProfileViewModel(airtable: airtable, auth: auth))
    }
    
    var body: some View {
        List {
            // Profile Header Section
            Section {
                VStack(spacing: 16) {
                    // Profile Picture
                    if let imageURL = viewModel.profilePictureURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 2))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Name and Email
                    VStack(spacing: 4) {
                        Text(viewModel.userName)
                            .font(.title2)
                            .bold()
                        
                        Text(viewModel.userEmail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Points
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("\(viewModel.points) points")
                            .font(.headline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            
            // Badges Section
            Section {
                if viewModel.badges.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "medal")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No badges yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Post questions and answers to earn badges!")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.badges, id: \.id) { badge in
                                BadgeCard(badge: badge)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            } header: {
                HStack {
                    Text("Badges")
                    Spacer()
                    Text("\(viewModel.badges.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Statistics Section
            Section("Statistics") {
                HStack {
                    StatItem(
                        title: "Questions",
                        value: "\(viewModel.userQuestions.count)",
                        icon: "questionmark.circle.fill",
                        color: .blue
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    StatItem(
                        title: "Answers",
                        value: "\(viewModel.userAnswers.count)",
                        icon: "text.bubble.fill",
                        color: .green
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    StatItem(
                        title: "Points",
                        value: "\(viewModel.points)",
                        icon: "star.fill",
                        color: .yellow
                    )
                }
                .padding(.vertical, 8)
            }
            
            // Questions Section
            if !viewModel.userQuestions.isEmpty {
                Section("My Questions") {
                    ForEach(viewModel.userQuestions) { question in
                        NavigationLink {
                            QuestionDetailView(question: question, airtable: airtable)
                                .environmentObject(auth)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(question.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                
                                HStack(spacing: 8) {
                                    Label("\(question.upvotes)", systemImage: "arrow.up.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(question.formattedDate)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            // Answers Section
            if !viewModel.userAnswers.isEmpty {
                Section("My Answers") {
                    ForEach(viewModel.userAnswers) { answer in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(answer.text)
                                .font(.body)
                                .lineLimit(3)
                            
                            HStack(spacing: 8) {
                                Label("\(answer.upvotes)", systemImage: "arrow.up.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(answer.formattedDate)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.loadProfile()
        }
        .onAppear {
            if viewModel.userName.isEmpty {
                viewModel.loadProfile()
            }
        }
    }
}

// MARK: - Helper Views

private struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BadgeCard: View {
    let badge: (id: String, name: String, description: String?, iconURL: URL?, dateEarned: Date?)
    
    var body: some View {
        VStack(spacing: 10) {
            // Badge Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                if let iconURL = badge.iconURL {
                    AsyncImage(url: iconURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        case .failure:
                            Image(systemName: "medal.fill")
                                .font(.system(size: 35))
                                .foregroundStyle(.yellow)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 35))
                        .foregroundStyle(.yellow)
                }
            }
            
            // Badge Name
            Text(badge.name)
                .font(.caption)
                .bold()
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 90)
            
            // Date Earned
            if let date = badge.dateEarned {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .frame(width: 110)
    }
}

