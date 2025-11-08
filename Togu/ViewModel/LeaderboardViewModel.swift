//
//  LeaderboardViewModel.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation
import Combine

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var currentUserEntry: LeaderboardEntry?
    
    private let airtable: AirtableService
    private var auth: AuthViewModel
    
    init(airtable: AirtableService, auth: AuthViewModel) {
        self.airtable = airtable
        self.auth = auth
    }
    
    func updateAuth(_ auth: AuthViewModel) {
        self.auth = auth
    }
    
    func loadLeaderboard() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Fetch leaderboard data
                let users = try await airtable.fetchLeaderboard()
                
                // Convert to LeaderboardEntry with ranks
                var entries: [LeaderboardEntry] = []
                for (index, user) in users.enumerated() {
                    let rank = index + 1
                    let level = LeaderboardEntry.calculateLevel(from: user.points)
                    
                    // Simple achievements based on rank and points
                    var achievements: [LeaderboardEntry.Achievement] = []
                    if rank == 1 {
                        achievements.append(.goldTrophy)
                    } else if rank <= 3 {
                        achievements.append(.silverMedal)
                    }
                    if user.points >= 500 {
                        achievements.append(.purpleStar)
                    }
                    
                    entries.append(LeaderboardEntry(
                        id: user.id,
                        name: user.name,
                        xp: user.points,
                        level: level,
                        rank: rank,
                        profilePictureURL: user.profilePictureURL,
                        achievements: achievements
                    ))
                }
                
                self.leaderboardEntries = entries
                
                // Find current user's entry
                if let userId = try? await resolveAuthorId() {
                    self.currentUserEntry = entries.first { $0.id == userId }
                }
                
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load leaderboard: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Error loading leaderboard:", error)
            }
        }
    }
    
    private func resolveAuthorId() async throws -> String {
        if let id = auth.airtableUserId, !id.isEmpty, id.hasPrefix("rec") {
            return id
        }
        
        var email: String?
        if case .signedIn(let claims) = auth.state {
            email = (claims["email"] as? String)
                ?? (claims["upn"] as? String)
                ?? (claims["preferred_username"] as? String)
        }
        
        guard let userEmail = email, !userEmail.isEmpty else {
            throw NSError(domain: "AuthorId", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Missing author identity."
            ])
        }
        
        let name = (auth.state.userInfo?["name"] as? String) ?? email ?? "Unknown"
        let recId = try await airtable.createUserIfMissing(name: name, email: userEmail)
        await MainActor.run { auth.airtableUserId = recId }
        return recId
    }
}

extension AuthState {
    var userInfo: [String: Any]? {
        if case .signedIn(let info) = self {
            return info
        }
        return nil
    }
}

