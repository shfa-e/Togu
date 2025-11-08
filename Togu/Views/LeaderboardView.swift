//
//  LeaderboardView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel: LeaderboardViewModel
    
    @State private var selectedTimeframe: Timeframe = .allTime
    @State private var airtableService: AirtableService? = {
        guard let config = AirtableConfig() else { return nil }
        return AirtableService(config: config)
    }()
    
    init() {
        // Initialize with service - auth will be injected via environment
        if let config = AirtableConfig() {
            let service = AirtableService(config: config)
            // Create a temporary auth for initialization - will be updated in onAppear
            let tempAuth = AuthViewModel()
            _viewModel = StateObject(wrappedValue: LeaderboardViewModel(airtable: service, auth: tempAuth))
        } else {
            // Fallback - should not happen if config is set
            let tempService = AirtableService(config: AirtableConfig()!)
            let tempAuth = AuthViewModel()
            _viewModel = StateObject(wrappedValue: LeaderboardViewModel(airtable: tempService, auth: tempAuth))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            
            // Segmented Control
            segmentedControl
                .padding(.top, 12)
            
            if viewModel.isLoading {
                Spacer()
                LoadingView("Loading leaderboard…")
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                ErrorView(
                    error: error,
                    retryAction: {
                        viewModel.loadLeaderboard()
                    }
                )
                .padding()
                Spacer()
            } else if viewModel.leaderboardEntries.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "trophy",
                    title: "No leaderboard data",
                    message: "Check back later when users start earning points!"
                )
                .padding()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Top 3 Users
                        topThreeSection
                            .padding(.top, 24)
                        
                        // Divider
                        if !viewModel.leaderboardEntries.isEmpty {
                            Divider()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                        }
                        
                        // User's Rank Card
                        if let currentUser = viewModel.currentUserEntry {
                            userRankCard(entry: currentUser)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        }
                        
                        // Leaderboard List (Rank 4+)
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.leaderboardEntries.filter { $0.rank > 3 }) { entry in
                                LeaderboardRowView(entry: entry)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
        }
        .background(Color.toguBackground.ignoresSafeArea())
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .errorToast(error: Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .onAppear {
            // Update viewModel's auth reference
            viewModel.updateAuth(auth)
            if viewModel.leaderboardEntries.isEmpty {
                if airtableService != nil {
                    viewModel.loadLeaderboard()
                }
            }
        }
        .refreshable {
            viewModel.loadLeaderboard()
        }
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
            if let second = viewModel.leaderboardEntries.first(where: { $0.rank == 2 }) {
                TopThreeUserView(entry: second, position: .second)
            }
            
            // Rank 1 (Center - Larger)
            if let first = viewModel.leaderboardEntries.first(where: { $0.rank == 1 }) {
                TopThreeUserView(entry: first, position: .first)
            }
            
            // Rank 3
            if let third = viewModel.leaderboardEntries.first(where: { $0.rank == 3 }) {
                TopThreeUserView(entry: third, position: .third)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - User Rank Card
    private func userRankCard(entry: LeaderboardEntry) -> some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 50, height: 50)
                Text("#\(entry.rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Rank")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("\(entry.name) (Level \(entry.level))")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            // XP
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatXP(entry.xp))
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
    
    // MARK: - Helpers
    private func formatXP(_ value: Int) -> String {
        let absValue = abs(Double(value))
        let sign = value < 0 ? "-" : ""

        let million = 1_000_000.0
        let thousand = 1_000.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0

        if absValue >= million {
            let formatted = absValue / million
            if let s = formatter.string(from: NSNumber(value: formatted)) {
                return "\(sign)\(s)M"
            }
            return "\(sign)\(String(format: "%.1f", formatted))M"
        } else if absValue >= thousand {
            let formatted = absValue / thousand
            if let s = formatter.string(from: NSNumber(value: formatted)) {
                return "\(sign)\(s)K"
            }
            return "\(sign)\(String(format: "%.1f", formatted))K"
        } else {
            let intFormatter = NumberFormatter()
            intFormatter.numberStyle = .decimal
            intFormatter.maximumFractionDigits = 0
            intFormatter.minimumFractionDigits = 0
            return "\(sign)\(intFormatter.string(from: NSNumber(value: abs(value))) ?? String(value))"
        }
    }
    
}
