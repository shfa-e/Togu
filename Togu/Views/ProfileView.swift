//
//  ProfileView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

enum ActivityType {
    case answerAccepted
    case badgeEarned
    case questionUpvoted
    case answerUpvoted
    case questionAsked
}

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    
    let airtable: AirtableService
    
    init(airtable: AirtableService, auth: AuthViewModel) {
        self.airtable = airtable
        _viewModel = StateObject(wrappedValue: ProfileViewModel(airtable: airtable, auth: auth))
    }
    
    // Calculate level from points (100 points per level)
    private var level: Int {
        max(1, viewModel.points / 100 + 1)
    }
    
    private var currentXP: Int {
        viewModel.points % 100
    }
    
    private var nextLevelXP: Int {
        100
    }
    
    private var totalXP: Int {
        viewModel.points
    }
    
    // Extract skills from question tags
    private var skills: [(name: String, level: Int, isHighlighted: Bool)] {
        var tagCounts: [String: Int] = [:]
        
        // Count tags from questions
        for question in viewModel.userQuestions {
            for tag in question.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        // Sort by count and take top 5
        let sortedTags = tagCounts.sorted { $0.value > $1.value }.prefix(5)
        
        return sortedTags.enumerated().map { index, pair in
            let level = min(5, pair.value) // Cap level at 5
            return (name: pair.key, level: level, isHighlighted: index < 2)
        }
    }
    
    // Create recent activity from questions and answers
    private var recentActivities: [(title: String, description: String, xpGained: Int, timeAgo: String, date: Date, type: ActivityType)] {
        var activities: [(title: String, description: String, xpGained: Int, timeAgo: String, date: Date, type: ActivityType)] = []
        
        // Add questions
        for question in viewModel.userQuestions.prefix(3) {
            activities.append((
                title: "Asked a question",
                description: question.title,
                xpGained: 10,
                timeAgo: formatTimeAgo(from: question.createdAt),
                date: question.createdAt,
                type: .questionAsked
            ))
        }
        
        // Add answers
        for answer in viewModel.userAnswers.prefix(3) {
            activities.append((
                title: "Answered a question",
                description: String(answer.text.prefix(50)) + (answer.text.count > 50 ? "..." : ""),
                xpGained: 5,
                timeAgo: formatTimeAgo(from: answer.createdAt),
                date: answer.createdAt,
                type: .answerAccepted
            ))
        }
        
        // Add badges
        for badge in viewModel.badges.prefix(2) {
            if let date = badge.dateEarned {
                activities.append((
                    title: "Earned a badge",
                    description: badge.name,
                    xpGained: 0,
                    timeAgo: formatTimeAgo(from: date),
                    date: date,
                    type: .badgeEarned
                ))
            }
        }
        
        // Sort by date (most recent first) and take top 5
        return activities.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }
    
    private func formatTimeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        }
        return "\(number)"
    }
    
    // Calculate total upvotes
    private var totalUpvotes: Int {
        let questionUpvotes = viewModel.userQuestions.reduce(0) { $0 + $1.upvotes }
        let answerUpvotes = viewModel.userAnswers.reduce(0) { $0 + $1.upvotes }
        return questionUpvotes + answerUpvotes
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
                if !skills.isEmpty {
                    skillsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }
                
                // Recent Activity
                if !recentActivities.isEmpty {
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
            if viewModel.userName.isEmpty {
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
                    
                    Text("\(viewModel.points) points • Level \(level) Developer")
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
            StatCard(value: formatNumber(totalUpvotes), label: "Upvotes")
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
                    Text("Level \(level) Developer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(currentXP) / \(nextLevelXP) XP")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(totalXP)")
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
                    let progress = Double(currentXP) / Double(nextLevelXP)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                }
            }
            .frame(height: 8)
            
            // Progress Info
            HStack {
                let xpNeeded = nextLevelXP - currentXP
                Text("\(xpNeeded) XP to next level")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                let percentage = Int((Double(currentXP) / Double(nextLevelXP)) * 100)
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
                    ForEach(skills, id: \.name) { skill in
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
                ForEach(Array(recentActivities.enumerated()), id: \.offset) { index, activity in
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
                    } label: {
                        QuestionCard(question: question)
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
                    AnswerCard(answer: answer)
                }
            }
        }
    }
}

// MARK: - Helper Views

private struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.toguTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
}

private struct ProfileBadgeCard: View {
    let badge: (id: String, name: String, description: String?, iconURL: URL?, dateEarned: Date?)
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.toguPrimary.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                if let iconURL = badge.iconURL {
                    AsyncImage(url: iconURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        case .failure:
                            Image(systemName: "medal.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.toguPrimary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.toguPrimary)
                }
            }
            Text(badge.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.toguTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
    }
}

private struct SkillTag: View {
    let skill: (name: String, level: Int, isHighlighted: Bool)
    
    var body: some View {
        HStack(spacing: 6) {
            Text(skill.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(skill.isHighlighted ? .toguPrimary : .toguTextPrimary)
            Text("•")
                .foregroundColor(.toguTextSecondary)
            Text("Level \(skill.level)")
                .font(.system(size: 14))
                .foregroundColor(.toguTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
        )
    }
}

private struct ActivityCard: View {
    let activity: (title: String, description: String, xpGained: Int, timeAgo: String, date: Date, type: ActivityType)
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                
                Text(activity.description)
                    .font(.system(size: 13))
                    .foregroundColor(.toguTextSecondary)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    if activity.xpGained > 0 {
                        Text("+\(activity.xpGained) XP")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.toguPrimary)
                        Text("•")
                            .foregroundColor(.toguTextSecondary)
                    }
                    Text(activity.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.toguTextSecondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
    
    private var iconName: String {
        switch activity.type {
        case .answerAccepted: return "checkmark.circle.fill"
        case .badgeEarned: return "rosette"
        case .questionUpvoted, .answerUpvoted: return "arrow.up.circle.fill"
        case .questionAsked: return "questionmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch activity.type {
        case .answerAccepted: return .green
        case .badgeEarned: return Color.toguPrimary
        case .questionUpvoted, .answerUpvoted: return .blue
        case .questionAsked: return .orange
        }
    }
}

private struct QuestionCard: View {
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.toguTextPrimary)
                .lineLimit(2)
            
            HStack(spacing: 8) {
                Label("\(question.upvotes)", systemImage: "arrow.up.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.toguTextSecondary)
                
                Text(question.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.toguTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
}

private struct AnswerCard: View {
    let answer: Answer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(answer.text)
                .font(.system(size: 15))
                .foregroundColor(.toguTextPrimary)
                .lineLimit(3)
            
            HStack(spacing: 8) {
                Label("\(answer.upvotes)", systemImage: "arrow.up.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.toguTextSecondary)
                
                Text(answer.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.toguTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
}
