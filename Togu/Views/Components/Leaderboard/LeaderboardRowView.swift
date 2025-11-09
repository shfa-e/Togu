//
//  LeaderboardRowView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Number
            ZStack {
                Circle()
                    .fill(Color.toguLightBackground)
                    .frame(width: 36, height: 36)
                Text("\(entry.rank)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.toguTextSecondary)
            }
            
            // Profile Picture
            if let imageURL = entry.profilePictureURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    case .failure:
                        profilePlaceholder
                    @unknown default:
                        profilePlaceholder
                    }
                }
            } else {
                profilePlaceholder
            }
            
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
                Text(FormattingHelpers.formatXP(entry.xp))
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
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.15))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.toguTextSecondary.opacity(0.6))
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
}

