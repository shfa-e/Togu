//
//  HomeViewModel.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var userPoints: Int = 0
    @Published var isLoadingUserData: Bool = false
    @Published var errorMessage: String?
    
    private let airtable: AirtableService
    private var auth: AuthViewModel
    
    init(airtable: AirtableService, auth: AuthViewModel) {
        self.airtable = airtable
        self.auth = auth
    }
    
    func updateAuth(_ auth: AuthViewModel) {
        self.auth = auth
    }
    
    var levelInfo: LevelInfo {
        LevelInfo.calculate(from: userPoints)
    }
    
    func loadUserProgress() {
        guard !isLoadingUserData else { return }
        isLoadingUserData = true
        errorMessage = nil
        
        Task {
            do {
                // Resolve user ID
                var userId: String?
                if let id = auth.airtableUserId, !id.isEmpty, id.hasPrefix("rec") {
                    userId = id
                } else {
                    var email: String?
                    if case .signedIn(let claims) = auth.state {
                        email = (claims["email"] as? String)
                            ?? (claims["upn"] as? String)
                            ?? (claims["preferred_username"] as? String)
                    }
                    
                    if let userEmail = email, !userEmail.isEmpty {
                        let name = (auth.state.userInfo?["name"] as? String) ?? userEmail
                        userId = try await airtable.createUserIfMissing(name: name, email: userEmail)
                        await MainActor.run { auth.airtableUserId = userId }
                    }
                }
                
                if let userId = userId {
                    let (_, userFields) = try await airtable.fetchUser(recordId: userId)
                    await MainActor.run {
                        userPoints = userFields.Points ?? 0
                        isLoadingUserData = false
                    }
                } else {
                    await MainActor.run {
                        isLoadingUserData = false
                    }
                }
            } catch {
                print("⚠️ Failed to load user progress: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to load user progress"
                    isLoadingUserData = false
                }
            }
        }
    }
}

