//
//  Views.LeaderboardView.swift
//  Togu
//
//  Created by HY on 05/11/2025.
//

import SwiftUI

struct LeaderboardView: View {
    @State private var selectedTimeframe: Timeframe = .allTime
    @State private var leaderboardData = LeaderboardEntry.sampleData
    
    enum Timeframe: String, CaseIterable {
        case allTime = "All Time"
        case thisMonth = "This Month"
        case thisWeek = "This Week"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            segmentedControl
                .padding(.top, 12)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Top 3 Users
                    topThreeSection
                        .padding(.top, 24)
                    
                    // Divider
                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    
                    // User's Rank Card
                    userRankCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    
                    // Leaderboard List (Rank 4+)
                    LazyVStack(spacing: 12) {
                        ForEach(leaderboardData.filter { $0.rank > 3 }) { entry in
                            LeaderboardRowView(entry: entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                }
            }
        }
        .background(Color.toguBackground.ignoresSafeArea())
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Segmented Control
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTimeframe = timeframe
                    }
                } label: {
                    Text(timeframe.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .toguTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeframe == timeframe ? Color.toguPrimary : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#F5F5F5"))
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Top 3 Section
    private var topThreeSection: some View {
        HStack(spacing: 12) {
            // Rank 2
            if let second = leaderboardData.first(where: { $0.rank == 2 }) {
                TopThreeUserView(entry: second, position: .second)
            }
            
            // Rank 1 (Center - Larger)
            if let first = leaderboardData.first(where: { $0.rank == 1 }) {
                TopThreeUserView(entry: first, position: .first)
            }
            
            // Rank 3
            if let third = leaderboardData.first(where: { $0.rank == 3 }) {
                TopThreeUserView(entry: third, position: .third)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - User Rank Card
    private var userRankCard: some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 50, height: 50)
                Text("#\(LeaderboardEntry.currentUser.rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Rank")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("\(LeaderboardEntry.currentUser.name) (Level \(LeaderboardEntry.currentUser.level))")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            // XP
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatXP(LeaderboardEntry.currentUser.xp))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("XP")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.toguPrimary,
                    Color.toguPrimary.opacity(0.75)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
    
    private func formatXP(_ xp: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: xp)) ?? "\(xp)"
    }
}

// MARK: - Top Three User View
struct TopThreeUserView: View {
    let entry: LeaderboardEntry
    let position: Position
    
    enum Position {
        case first, second, third
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                // Profile Picture
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: profileSize, height: profileSize)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: iconSize))
                            .foregroundColor(.toguTextSecondary.opacity(0.6))
                    )
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                
                // Rank Badge
                rankBadge
                    .offset(x: 6, y: 6)
            }
            
            Text(entry.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.toguTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("Level \(entry.level)")
                .font(.system(size: 12))
                .foregroundColor(.toguTextSecondary)
            
            Text(formatXP(entry.xp))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(entry.rank == 1 ? Color.toguPrimary : .toguTextPrimary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var profileSize: CGFloat {
        switch position {
        case .first: return 80
        case .second, .third: return 70
        }
    }
    
    private var iconSize: CGFloat {
        switch position {
        case .first: return 35
        case .second, .third: return 30
        }
    }
    
    private var borderColor: Color {
        switch position {
        case .first: return Color.toguPrimary
        case .second, .third: return Color.gray.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        switch position {
        case .first: return 3
        case .second, .third: return 1
        }
    }
    
    @ViewBuilder
    private var rankBadge: some View {
        switch position {
        case .first:
            Image(systemName: "crown.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.toguPrimary)
        case .second:
            Circle()
                .fill(Color.gray)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("2")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
        case .third:
            Circle()
                .fill(Color.orange)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("3")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
    
    private func formatXP(_ xp: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: xp)) ?? "\(xp)"
    }
}

// MARK: - Leaderboard Row View
struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Number
            ZStack {
                Circle()
                    .fill(Color(hex: "#F5F5F5"))
                    .frame(width: 36, height: 36)
                Text("\(entry.rank)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.toguTextSecondary)
            }
            
            // Profile Picture
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.toguTextSecondary.opacity(0.6))
                )
            
            // Name and Level
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                
                HStack(spacing: 6) {
                    Text("Level \(entry.level)")
                        .font(.system(size: 13))
                        .foregroundColor(.toguTextSecondary)
                    
                    // Achievements
                    if !entry.achievements.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(entry.achievements, id: \.self) { achievement in
                                achievementIcon(for: achievement)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // XP
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatXP(entry.xp))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
                Text("XP")
                    .font(.system(size: 11))
                    .foregroundColor(.toguTextSecondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func achievementIcon(for achievement: LeaderboardEntry.Achievement) -> some View {
        switch achievement {
        case .goldTrophy:
            Image(systemName: "trophy.fill")
                .font(.system(size: 10))
                .foregroundColor(.yellow)
        case .silverMedal:
            Image(systemName: "medal.fill")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        case .purpleStar:
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(Color.toguPrimary)
        }
    }
    
    private func formatXP(_ xp: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: xp)) ?? "\(xp)"
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
