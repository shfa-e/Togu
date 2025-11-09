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
    
    @StateObject private var badgeNotificationManager = BadgeNotificationManager()
    @State private var airtableService: AirtableService? = {
        guard let config = AirtableConfig() else { return nil }
        let service = AirtableService(config: config)
        return service
    }()
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
                    .environmentObject(auth)
                    .environmentObject(router)
                    .environmentObject(badgeNotificationManager)
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
                        .environmentObject(badgeNotificationManager)
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
        .onAppear {
            // Set badge notification manager on AirtableService
            if let service = airtableService {
                service.badgeNotificationManager = badgeNotificationManager
            }
        }
        .badgeToast(badgeName: $badgeNotificationManager.earnedBadgeName)
    }
}

