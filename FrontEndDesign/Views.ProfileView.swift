
//
//  Views.ProfileView.swift
//  Togu
//
//  Created by HY on 05/11/2025.
//

import SwiftUI

struct ProfileView: View {
    @State private var profile = UserProfile.sample
    
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
                skillsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                
                // Recent Activity
                recentActivitySection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
            }
        }
        .background(Color(hex: "#F5F5F5").ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.toguPrimary)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("T")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                    Text("Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.toguTextPrimary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Settings action
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.toguTextPrimary)
                        .font(.system(size: 20))
                }
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
                    
                    Image(systemName: profile.profileImage)
                        .font(.system(size: 40))
                        .foregroundColor(.toguPrimary)
                }
                
                // Name, Username, Bio
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.toguTextPrimary)
                    
                    Text(profile.username)
                        .font(.system(size: 14))
                        .foregroundColor(.toguTextSecondary)
                    
                    Text(profile.bio)
                        .font(.system(size: 13))
                        .foregroundColor(.toguTextSecondary)
                        .lineLimit(3)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
            
            // Edit Profile Button
            HStack(spacing: 12) {
                Button {
                    // Edit profile action
                } label: {
                    Text("Edit Profile")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.toguPrimary)
                        .cornerRadius(10)
                }
                
                Button {
                    // Share action
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.toguTextSecondary)
                        .frame(width: 44, height: 44)
                        .background(Color.toguCard)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Statistics
    private var statisticsSection: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(profile.questions)", label: "Questions")
            StatCard(value: "\(profile.answers)", label: "Answers")
            StatCard(value: formatNumber(profile.upvotes), label: "Upvotes")
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
                    Text("Level \(profile.level) Developer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(profile.currentXP) / \(profile.nextLevelXP) XP")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(profile.totalXP)")
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
                    let progress = Double(profile.currentXP) / Double(profile.nextLevelXP)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                }
            }
            .frame(height: 8)
            
            // Progress Info
            HStack {
                let xpNeeded = profile.nextLevelXP - profile.currentXP
                Text("\(xpNeeded) XP to next level")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                let percentage = Int((Double(profile.currentXP) / Double(profile.nextLevelXP)) * 100)
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
                
                Button {
                    // View all badges
                } label: {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.toguPrimary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(profile.badges) { badge in
                        BadgeCard(badge: badge)
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
                    ForEach(profile.skills) { skill in
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
                
                Button {
                    // View all activity
                } label: {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.toguPrimary)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(profile.recentActivities) { activity in
                    ActivityCard(activity: activity)
                }
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

// MARK: - Stat Card
struct StatCard: View {
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

// MARK: - Badge Card
struct BadgeCard: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(backgroundColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: badge.icon)
                    .font(.system(size: 28))
                    .foregroundColor(foregroundColor)
            }
            Text(badge.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.toguTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
    }
    
    private var backgroundColor: Color {
        switch badge.color {
        case .gold: return .yellow
        case .purple: return .purple
        case .blue: return .blue
        case .green: return .green
        }
    }
    
    private var foregroundColor: Color {
        switch badge.color {
        case .gold: return .yellow
        case .purple: return Color.toguPrimary
        case .blue: return .blue
        case .green: return .green
        }
    }
}

// MARK: - Skill Tag
struct SkillTag: View {
    let skill: Skill
    
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

// MARK: - Activity Card
struct ActivityCard: View {
    let activity: Activity
    
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
                    Text("+\(activity.xpGained) XP")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.toguPrimary)
                    Text("•")
                        .foregroundColor(.toguTextSecondary)
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

#Preview {
    NavigationStack {
        ProfileView()
    }
}
