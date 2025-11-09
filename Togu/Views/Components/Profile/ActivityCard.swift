//
//  ActivityCard.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

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
                .fill(Color(uiColor: .systemBackground))
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

