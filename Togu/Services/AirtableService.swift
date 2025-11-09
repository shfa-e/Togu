//
//  AirtableService.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//  Clean, production-ready version.
//

import Foundation

final class AirtableService {
    private let config: AirtableConfig
    private let urlSession: URLSession
    
    // Domain-specific services
    private lazy var questionsService = QuestionsService(config: config, urlSession: urlSession)
    private lazy var answersService = AnswersService(config: config, urlSession: urlSession)
    private lazy var usersService = UsersService(config: config, urlSession: urlSession)
    private lazy var votesService = VotesService(config: config, urlSession: urlSession, questionsService: questionsService, answersService: answersService)
    private lazy var badgesService = BadgesService(config: config, urlSession: urlSession)
    private lazy var leaderboardService = LeaderboardService(config: config, urlSession: urlSession)
    
    // Badge notification manager (optional, set by views)
    weak var badgeNotificationManager: BadgeNotificationManager?

    init(config: AirtableConfig, urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }
    
    struct NewQuestionImage {
        let data: Data
        let filename: String
        let mimeType: String
    }

    enum ServiceError: Error {
        case url
        case http
        case decoding
        case server
        case missingAuthorId
        case invalidQuestionId
        case missingImageData
    }
    
    // MARK: - Fetch Questions
    
    struct QuestionsResult {
        let questions: [Question]
        let nextOffset: String?
    }

    func fetchQuestions(
        searchText: String? = nil,
        selectedTag: String? = nil,
        offset: String? = nil,
        pageSize: Int = 20
    ) async throws -> QuestionsResult {
        return try await questionsService.fetchQuestions(
            searchText: searchText,
            selectedTag: selectedTag,
            offset: offset,
            pageSize: pageSize
        )
    }

    // MARK: - Fetch Answers

    func fetchAnswers(for question: Question) async throws -> [Answer] {
        return try await answersService.fetchAnswers(for: question)
    }
    
    // MARK: - Create Answer

    func createAnswer(for question: Question, text: String, authorId: String) async throws {
        try await answersService.createAnswer(for: question, text: text, authorId: authorId)
        
        // Award points for posting an answer (fire and forget)
        Task {
            await usersService.addPoints(userRecordId: authorId, points: 5, reason: "Posted an answer")
        }
        
        // Check and award milestone badges (fire and forget)
        Task {
            await checkAnswerMilestones(userRecordId: authorId)
        }
    }

    // MARK: - Create Question

    func createQuestion(title: String,
                        body: String,
                        tags: [String],
                        authorId: String,
                        image: NewQuestionImage?) async throws -> Question {
        let question = try await questionsService.createQuestion(
            title: title,
            body: body,
            tags: tags,
            authorId: authorId,
            image: image
        )
        
        // Award points for posting a question (fire and forget)
        Task {
            await usersService.addPoints(userRecordId: authorId, points: 10, reason: "Posted a question")
        }
        
        // Check and award milestone badges (fire and forget)
        Task {
            // small initial delay so Airtable has time to index the new record
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
            await checkQuestionMilestones(userRecordId: authorId)
        }
        
        return question
    }
    
    // MARK: - Voting System

    func hasUserVoted(userId: String, targetType: String, targetId: String) async throws -> Bool {
        return try await votesService.hasUserVoted(userId: userId, targetType: targetType, targetId: targetId)
    }

    func createVote(userId: String, targetType: String, targetId: String) async throws {
        try await votesService.createVote(userId: userId, targetType: targetType, targetId: targetId)
        
        // Award points to the author when their content gets upvoted (fire and forget)
        Task {
            // Fetch the record to get author ID
            let tableName = targetType == "Question" ? config.questionsTable : "Answers"
            guard let fetchURL = URL(string: "https://api.airtable.com/v0/\(config.baseId)/\(tableName)/\(targetId)") else { return }
            
            var fetchRequest = URLRequest(url: fetchURL)
            fetchRequest.httpMethod = "GET"
            fetchRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            fetchRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            
            do {
                let (fetchData, fetchResponse) = try await urlSession.data(for: fetchRequest)
                guard let http = fetchResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
                await votesService.awardPointsForUpvote(targetType: targetType, targetId: targetId, fetchData: fetchData, usersService: usersService)
            } catch {
                print("⚠️ Failed to fetch record for upvote points: \(error)")
            }
        }
    }
    
    /// Add points to a user's total
    func addPoints(userRecordId: String, points: Int, reason: String = "") async {
        await usersService.addPoints(userRecordId: userRecordId, points: points, reason: reason)
        
        // Check for points milestone badges (e.g., 100 points) - fire and forget
        Task {
            do {
                let (_, userFields) = try await usersService.fetchUser(recordId: userRecordId)
                let currentPoints = userFields.Points ?? 0
                if currentPoints >= 100 {
                    try await badgesService.awardBadge(userRecordId: userRecordId, badgeName: "Centurion")
                }
            } catch {
                print("⚠️ Failed to check points milestone: \(error)")
            }
        }
    }

    // MARK: - Helper Methods
    
    /// Get answer count for a question
    func getAnswerCount(for questionId: String) async throws -> Int {
        return try await answersService.getAnswerCount(for: questionId)
    }
    
    /// Get author details (profile picture, level) for a question
    func getAuthorDetails(authorId: String) async throws -> (profilePictureURL: URL?, level: Int) {
        return try await usersService.getAuthorDetails(authorId: authorId)
    }
    
    // MARK: - Leaderboard
    
    func fetchLeaderboard() async throws -> [(id: String, name: String, points: Int, profilePictureURL: URL?)] {
        return try await leaderboardService.fetchLeaderboard()
    }

    // MARK: - Profile/User Data

    func fetchUser(recordId: String) async throws -> (id: String, fields: UserFields) {
        return try await usersService.fetchUser(recordId: recordId)
    }
    
    func fetchUserRecordId(byEmail email: String) async throws -> String? {
        return try await usersService.fetchUserRecordId(byEmail: email)
    }
    
    func createUserIfMissing(name: String, email: String) async throws -> String {
        return try await usersService.createUserIfMissing(name: name, email: email)
    }

    func fetchUserQuestions(userRecordId: String) async throws -> [Question] {
        return try await questionsService.fetchUserQuestions(userRecordId: userRecordId)
    }

    func fetchUserAnswers(userRecordId: String) async throws -> [Answer] {
        return try await answersService.fetchUserAnswers(userRecordId: userRecordId)
    }

    // MARK: - Badges

    func fetchUserBadges(userRecordId: String) async throws
    -> [(id: String, name: String, description: String?, iconURL: URL?, dateEarned: Date?)] {
        return try await badgesService.fetchUserBadges(userRecordId: userRecordId)
    }
    
    func hasUserEarnedBadge(userRecordId: String, badgeName: String) async throws -> Bool {
        return try await badgesService.hasUserEarnedBadge(userRecordId: userRecordId, badgeName: badgeName)
    }
    
    func awardBadge(userRecordId: String, badgeName: String) async throws -> String? {
        let badgeName = try await badgesService.awardBadge(userRecordId: userRecordId, badgeName: badgeName)
        if let badgeName = badgeName {
            await MainActor.run {
                badgeNotificationManager?.showBadgeNotification(badgeName)
            }
        }
        return badgeName
    }
    
    func checkAndAwardMilestoneBadges(userRecordId: String, action: BadgeMilestone) async -> String? {
        let badgeName = await badgesService.checkAndAwardMilestoneBadges(userRecordId: userRecordId, action: action)
        if let badgeName = badgeName {
            Task { @MainActor in
                badgeNotificationManager?.showBadgeNotification(badgeName)
            }
        }
        return badgeName
    }
    
    // Check user's question count and award milestone badges
    func checkQuestionMilestones(userRecordId: String) async {
        print("🔍 Checking question milestones for user: \(userRecordId)")
        do {
            var attempts = 0
            var questions: [Question] = []
            while attempts < 4 { // attempt 0..3 => 4 tries (first immediate)
                questions = try await fetchUserQuestions(userRecordId: userRecordId)
                let count = questions.count
                print("📊 User has \(count) question(s) (attempt \(attempts + 1))")
                
                if count >= 1 {
                    // award corresponding badges if thresholds hit
                    if count == 1 {
                        print("🎯 User has exactly 1 question - awarding 'First Question' badge")
                        do {
                            if let badgeName = try await badgesService.awardBadge(userRecordId: userRecordId, badgeName: "First Question") {
                                await MainActor.run {
                                    badgeNotificationManager?.showBadgeNotification(badgeName)
                                }
                            }
                        } catch {
                            print("❌ Failed to award 'First Question' badge: \(error)")
                        }
                    }
                    if count == 5 {
                        print("🎯 User has exactly 5 questions - awarding 'Question Master' badge")
                        do {
                            if let badgeName = try await badgesService.awardBadge(userRecordId: userRecordId, badgeName: "Question Master") {
                                await MainActor.run {
                                    badgeNotificationManager?.showBadgeNotification(badgeName)
                                }
                            }
                        } catch {
                            print("❌ Failed to award 'Question Master' badge: \(error)")
                        }
                    }
                    return
                }
                // If we haven't seen the new question yet, wait and retry
                attempts += 1
                if attempts < 4 {
                    let delaySeconds = UInt64(pow(2.0, Double(attempts - 1))) // 1, 2, 4
                    print("⏳ Waiting \(delaySeconds) seconds before retry...")
                    try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                }
            }
            print("⚠️ After \(attempts) attempts, user still has 0 questions - no badge awarded")
        } catch {
            print("❌ Failed to check question milestones: \(error)")
        }
    }

    
    /// Check user's answer count and award milestone badges
    func checkAnswerMilestones(userRecordId: String) async {
        print("🔍 Checking answer milestones for user: \(userRecordId)")
        do {
            let answers = try await fetchUserAnswers(userRecordId: userRecordId)
            let count = answers.count
            print("📊 User has \(count) answer(s)")
            
            if count == 1 {
                print("🎯 User has exactly 1 answer - awarding 'First Answer' badge")
                do {
                    if let badgeName = try await badgesService.awardBadge(userRecordId: userRecordId, badgeName: "First Answer") {
                        await MainActor.run {
                            badgeNotificationManager?.showBadgeNotification(badgeName)
                        }
                    }
                } catch {
                    print("❌ Failed to award 'First Answer' badge: \(error)")
                }
            } else if count == 10 {
                print("🎯 User has exactly 10 answers - awarding 'Answer Expert' badge")
                do {
                    if let badgeName = try await badgesService.awardBadge(userRecordId: userRecordId, badgeName: "Answer Expert") {
                        await MainActor.run {
                            badgeNotificationManager?.showBadgeNotification(badgeName)
                        }
                    }
                } catch {
                    print("❌ Failed to award 'Answer Expert' badge: \(error)")
                }
            }
        } catch {
            print("❌ Failed to check answer milestones: \(error)")
        }
    }
}



