//
//  ProfileViewModel.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // User data
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var profilePictureURL: URL?
    @Published var points: Int = 0
    
    // User content
    @Published var userQuestions: [Question] = []
    @Published var userAnswers: [Answer] = []
    
    // Badges
    @Published var badges: [(id: String, name: String, description: String?, iconURL: URL?, dateEarned: Date?)] = []
    
    private let airtable: AirtableService
    private let auth: AuthViewModel
    
    init(airtable: AirtableService, auth: AuthViewModel) {
        self.airtable = airtable
        self.auth = auth
    }
    
    // MARK: - Computed Properties
    
    var levelInfo: LevelInfo {
        LevelInfo.calculate(from: points)
    }
    
    var skills: [Skill] {
        var tagCounts: [String: Int] = [:]
        
        // Count tags from questions
        for question in userQuestions {
            for tag in question.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        // Sort by count and take top 5
        let sortedTags = tagCounts.sorted { $0.value > $1.value }.prefix(5)
        
        return sortedTags.enumerated().map { index, pair in
            let level = min(5, pair.value) // Cap level at 5
            return Skill(
                name: pair.key,
                level: level,
                isHighlighted: index < 2
            )
        }
    }
    
    var recentActivities: [Activity] {
        var activities: [Activity] = []
        
        // Add questions
        for question in userQuestions.prefix(3) {
            activities.append(Activity(
                title: "Asked a question",
                description: question.title,
                xpGained: 10,
                timeAgo: FormattingHelpers.timeAgo(from: question.createdAt),
                date: question.createdAt,
                type: .questionAsked
            ))
        }
        
        // Add answers
        for answer in userAnswers.prefix(3) {
            activities.append(Activity(
                title: "Answered a question",
                description: String(answer.text.prefix(50)) + (answer.text.count > 50 ? "..." : ""),
                xpGained: 5,
                timeAgo: FormattingHelpers.timeAgo(from: answer.createdAt),
                date: answer.createdAt,
                type: .answerAccepted
            ))
        }
        
        // Add badges
        for badge in badges.prefix(2) {
            if let date = badge.dateEarned {
                activities.append(Activity(
                    title: "Earned a badge",
                    description: badge.name,
                    xpGained: 0,
                    timeAgo: FormattingHelpers.timeAgo(from: date),
                    date: date,
                    type: .badgeEarned
                ))
            }
        }
        
        // Sort by date (most recent first) and take top 5
        return activities.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }
    
    var totalUpvotes: Int {
        let questionUpvotes = userQuestions.reduce(0) { $0 + $1.upvotes }
        let answerUpvotes = userAnswers.reduce(0) { $0 + $1.upvotes }
        return questionUpvotes + answerUpvotes
    }
    
    var shouldLoadProfile: Bool {
        userName.isEmpty
    }
    
    func loadProfile() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Resolve user ID
                let userId = try await resolveAuthorId()

                print("🔵 loadProfile about to fetch user record:", userId)

                // Fetch user data
                let (_, userFields) = try await airtable.fetchUser(recordId: userId)

                // Update user info on main actor
                await MainActor.run {
                    userName = userFields.Name ?? "Unknown"
                    userEmail = userFields.Email ?? ""
                    points = userFields.Points ?? 0

                    if let pictureURLString = userFields.ProfilePicture?.first?.url {
                        profilePictureURL = URL(string: pictureURLString)
                    } else {
                        profilePictureURL = nil
                    }
                }

                // Fetch user's questions, answers, and badges — do NOT let one failure cancel the others.
                async let questionsTask = airtable.fetchUserQuestions(userRecordId: userId)
                async let answersTask = airtable.fetchUserAnswers(userRecordId: userId)
                async let badgesTask = airtable.fetchUserBadges(userRecordId: userId)

                var fetchedQuestions: [Question] = []
                var fetchedAnswers: [Answer] = []
                var fetchedBadges: [(id: String, name: String, description: String?, iconURL: URL?, dateEarned: Date?)] = []

                // Await each in its own do/catch so we can log exactly which one failed
                do {
                    fetchedQuestions = try await questionsTask
                    print("✅ Fetched \(fetchedQuestions.count) user questions")
                } catch {
                    print("❌ fetchUserQuestions failed:", error)
                    // Optionally set a non-fatal error message:
                    await MainActor.run { errorMessage = "Some profile data couldn't be loaded (questions)." }
                }

                do {
                    fetchedAnswers = try await answersTask
                    print("✅ Fetched \(fetchedAnswers.count) user answers")
                } catch {
                    print("❌ fetchUserAnswers failed:", error)
                    await MainActor.run {
                        if errorMessage == nil {
                            errorMessage = "Some profile data couldn't be loaded (answers)."
                        } else {
                            errorMessage = "Some profile data couldn't be loaded."
                        }
                    }
                }

                do {
                    fetchedBadges = try await badgesTask
                    print("✅ Fetched \(fetchedBadges.count) badges")
                } catch {
                    print("❌ fetchUserBadges failed:", error)
                    await MainActor.run {
                        if errorMessage == nil {
                            errorMessage = "Some profile data couldn't be loaded (badges)."
                        } else {
                            errorMessage = "Some profile data couldn't be loaded."
                        }
                    }
                }

                // Apply results to published properties on main actor
                await MainActor.run {
                    userQuestions = fetchedQuestions
                    userAnswers = fetchedAnswers
                    badges = fetchedBadges
                    isLoading = false
                }
            } catch {
                // This catch handles fatal errors (resolveAuthorId, fetchUser(recordId:) decoding, etc.)
                await MainActor.run {
                    errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    isLoading = false
                }
                print("❌ Error loading profile:", error)
            }
        }
    }

    
    private func resolveAuthorId() async throws -> String {
        print("🟡 resolveAuthorId — stored:", auth.airtableUserId ?? "nil")
        
        if let id = auth.airtableUserId, !id.isEmpty {
            if id.hasPrefix("rec") { return id }
        }
        
        // Extract email from auth state
        var email: String?
        var name: String?
        if case .signedIn(let claims) = auth.state {
            email = (claims["email"] as? String)
                ?? (claims["upn"] as? String)
                ?? (claims["preferred_username"] as? String)
            name = (claims["name"] as? String)
                ?? (claims["given_name"] as? String)
                ?? email
        }
        
        guard let userEmail = email, !userEmail.isEmpty else {
            throw NSError(domain: "AuthorId", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Missing author identity. Please sign out and sign in again."
            ])
        }
        
        let displayName = name ?? "Unknown"
        let recId = try await airtable.createUserIfMissing(name: displayName, email: userEmail)
        print("🟢 resolveAuthorId — newly created returned:", recId)
        await MainActor.run { auth.airtableUserId = recId }
        return recId
    }
}

