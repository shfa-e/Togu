//
//  Views.MainTabView.swift
//  Togu
//
//  Created by HY on 05/11/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            
            NavigationStack {
                QAsView()
            }
            .tabItem {
                Image(systemName: "safari.fill")
                Text("Explore")
            }
            
            NavigationStack {
                LeaderboardView()
            }
            .tabItem {
                Image(systemName: "trophy.fill")
                Text("Leaderboard")
            }
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
        }
        .accentColor(.toguPrimary)
    }
}
