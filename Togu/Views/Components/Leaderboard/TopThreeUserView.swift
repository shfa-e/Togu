//
//  TopThreeUserView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

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
                if let imageURL = entry.profilePictureURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: profileSize, height: profileSize)
                                .overlay(
                                    ProgressView()
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: profileSize, height: profileSize)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(borderColor, lineWidth: borderWidth)
                                )
                        case .failure:
                            profilePlaceholder
                        @unknown default:
                            profilePlaceholder
                        }
                    }
                } else {
                    profilePlaceholder
                }
                
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
            
            Text(FormattingHelpers.formatXP(entry.xp))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(entry.rank == 1 ? Color.toguPrimary : .toguTextPrimary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var profilePlaceholder: some View {
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
}

