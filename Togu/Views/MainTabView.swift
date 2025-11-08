//
//  MainTabView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var router: Router
    
    @State private var airtableService: AirtableService? = {
        guard let config = AirtableConfig() else { return nil }
        return AirtableService(config: config)
    }()
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
                    .environmentObject(auth)
                    .environmentObject(router)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            
            NavigationStack {
                ExploreView()
                    .environmentObject(auth)
            }
            .tabItem {
                Image(systemName: "safari.fill")
                Text("Explore")
            }
            
            NavigationStack {
                LeaderboardView()
                    .environmentObject(auth)
            }
            .tabItem {
                Image(systemName: "trophy.fill")
                Text("Leaderboard")
            }
            
            NavigationStack {
                if let service = airtableService {
                    ProfileView(airtable: service, auth: auth)
                        .environmentObject(auth)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("Airtable configuration is missing")
                            .font(.headline)
                        Text("Add your keys to Info.plist to view profile.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
        }
        .tint(.toguPrimary)
    }
}

