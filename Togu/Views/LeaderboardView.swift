//
//  LeaderboardView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.toguPrimary)
                
                Text("Leaderboard")
                    .font(.title)
                    .bold()
                
                Text("See who's leading the community with the most points and contributions!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 100)
        }
        .background(Color(hex: "#F5F5F5").ignoresSafeArea())
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

