//
//  ExploreView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "safari")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.toguPrimary)
                
                Text("Explore")
                    .font(.title)
                    .bold()
                
                Text("Discover trending questions, popular topics, and more!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 100)
        }
        .background(Color(hex: "#F5F5F5").ignoresSafeArea())
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
    }
}

