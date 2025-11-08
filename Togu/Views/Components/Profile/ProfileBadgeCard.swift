//
//  ProfileBadgeCard.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct ProfileBadgeCard: View {
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

