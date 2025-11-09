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
    @EnvironmentObject var badgeNotificationManager: BadgeNotificationManager
    
    let airtable: AirtableService
    
    init(airtable: AirtableService, auth: AuthViewModel) {
        self.airtable = airtable
        _viewModel = StateObject(wrappedValue: ProfileViewModel(airtable: airtable, auth: auth))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Header
                profileHeaderSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Statistics
                statisticsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                
                // Level & XP Card
                levelXPCard
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                
                // Badges & Achievements
                badgesSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                
                // Top Skills
                if !viewModel.skills.isEmpty {
                    skillsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }
                
                // Recent Activity
                if !viewModel.recentActivities.isEmpty {
                    recentActivitySection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }
                
                // My Questions
                if !viewModel.userQuestions.isEmpty {
                    questionsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }
                
                // My Answers
                if !viewModel.userAnswers.isEmpty {
                    answersSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .background(Color(hex: "#F5F5F5").ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .errorToast(error: Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .onAppear {
            // Set badge notification manager on service
            airtable.badgeNotificationManager = badgeNotificationManager
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    auth.signOut()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
        .refreshable {
            viewModel.loadProfile()
        }
        .onAppear {
            if viewModel.shouldLoadProfile {
                viewModel.loadProfile()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Profile Picture
                ZStack {
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
                        .frame(width: 80, height: 80)
                    
                    if let imageURL = viewModel.profilePictureURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.toguPrimary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.toguPrimary)
                    }
                }
                
                // Name, Email, Bio
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.userName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.toguTextPrimary)
                    
                    Text(viewModel.userEmail)
                        .font(.system(size: 14))
                        .foregroundColor(.toguTextSecondary)
                    
                    Text("\(viewModel.points) points • Level \(viewModel.levelInfo.level) Developer")
                        .font(.system(size: 13))
                        .foregroundColor(.toguTextSecondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Statistics
    private var statisticsSection: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(viewModel.userQuestions.count)", label: "Questions")
            StatCard(value: "\(viewModel.userAnswers.count)", label: "Answers")
            StatCard(value: FormattingHelpers.formatNumber(viewModel.totalUpvotes), label: "Upvotes")
        }
    }
    
    // MARK: - Level & XP Card
    private var levelXPCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Lightning Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(viewModel.levelInfo.level) Developer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.levelInfo.currentXP) / \(viewModel.levelInfo.nextLevelXP) XP")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.levelInfo.totalXP)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Total XP")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * min(viewModel.levelInfo.progress, 1.0), height: 8)
                }
            }
            .frame(height: 8)
            
            // Progress Info
            HStack {
                Text("\(viewModel.levelInfo.xpNeeded) XP to next level")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                let percentage = Int(viewModel.levelInfo.progress * 100)
                Text("\(percentage)%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.toguPrimary,
                    Color.toguPrimary.opacity(0.7)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Badges Section
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Badges & Achievements")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                
                Spacer()
            }
            
            if viewModel.badges.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "medal")
                        .font(.system(size: 40))
                        .foregroundColor(.toguTextSecondary)
                    Text("No badges yet")
                        .font(.system(size: 14))
                        .foregroundColor(.toguTextSecondary)
                    Text("Post questions and answers to earn badges!")
                        .font(.system(size: 12))
                        .foregroundColor(.toguTextSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.badges, id: \.id) { badge in
                            ProfileBadgeCard(badge: badge)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Skills Section
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Skills")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.skills, id: \.name) { skill in
                        SkillTag(skill: skill)
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(viewModel.recentActivities.enumerated()), id: \.offset) { index, activity in
                    ActivityCard(activity: activity)
                }
            }
        }
    }
    
    // MARK: - Questions Section
    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Questions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.userQuestions.prefix(5)) { question in
                    NavigationLink {
                        QuestionDetailView(question: question, airtable: airtable)
                            .environmentObject(auth)
                            .environmentObject(badgeNotificationManager)
                    } label: {
                        ProfileQuestionCard(question: question)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Answers Section
    private var answersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Answers")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.userAnswers.prefix(5)) { answer in
                    ProfileAnswerCard(answer: answer)
                }
            }
        }
    }
}
