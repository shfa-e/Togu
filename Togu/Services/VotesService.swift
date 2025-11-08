//
//  VotesService.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

final class VotesService {
    private let config: AirtableConfig
    private let urlSession: URLSession
    private let questionsService: QuestionsService
    private let answersService: AnswersService
    
    init(config: AirtableConfig, urlSession: URLSession = .shared, questionsService: QuestionsService, answersService: AnswersService) {
        self.config = config
        self.urlSession = urlSession
        self.questionsService = questionsService
        self.answersService = answersService
    }
    
    // MARK: - Voting
    
    func hasUserVoted(userId: String, targetType: String, targetId: String) async throws -> Bool {
        guard !userId.isEmpty, !targetId.isEmpty else { return false }

        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "api.airtable.com"
        comps.path = "/v0/\(config.baseId)/Votes"

        let formula = targetType == "Question"
            ? "AND({User}='\(userId)', {TargetType}='\(targetType)', {Target Question}='\(targetId)')"
            : "AND({User}='\(userId)', {TargetType}='\(targetType)', {Target Answer}='\(targetId)')"

        comps.queryItems = [URLQueryItem(name: "filterByFormula", value: formula)]
        guard let url = comps.url else { throw AirtableService.ServiceError.url }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AirtableService.ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<VoteFields>.self, from: data)
        return !decoded.records.isEmpty
    }

    func createVote(userId: String, targetType: String, targetId: String) async throws {
        guard !userId.isEmpty, !targetId.isEmpty else { throw AirtableService.ServiceError.missingAuthorId }

        if try await hasUserVoted(userId: userId, targetType: targetType, targetId: targetId) { return }

        guard let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Votes") else {
            throw AirtableService.ServiceError.url
        }

        var fields: [String:Any] = [
            "User": [userId],
            "TargetType": targetType
        ]

        if targetType == "Question" {
            fields["Target Question"] = [targetId]
        } else {
            fields["Target Answer"] = [targetId]
        }

        let body = ["fields": fields]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (_, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AirtableService.ServiceError.http
        }

        try await updateUpvoteCount(targetType: targetType, targetId: targetId)
    }
    
    // MARK: - Upvote Count Management
    
    private func updateUpvoteCount(targetType: String, targetId: String) async throws {
        let tableName = targetType == "Question" ? config.questionsTable : "Answers"

        guard let fetchURL = URL(string: "https://api.airtable.com/v0/\(config.baseId)/\(tableName)/\(targetId)") else {
            throw AirtableService.ServiceError.url
        }

        var fetchRequest = URLRequest(url: fetchURL)
        fetchRequest.httpMethod = "GET"
        fetchRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        fetchRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        let (fetchData, fetchResponse) = try await urlSession.data(for: fetchRequest)
        guard let http = fetchResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AirtableService.ServiceError.http
        }

        let currentUpvotes: Int
        if targetType == "Question" {
            let record = try JSONDecoder().decode(AirtableRecord<QuestionFields>.self, from: fetchData)
            currentUpvotes = record.fields.upvotes ?? 0
        } else {
            let record = try JSONDecoder().decode(AirtableRecord<AnswerFields>.self, from: fetchData)
            currentUpvotes = record.fields.Upvotes ?? 0
        }

        guard let updateURL = URL(string: "https://api.airtable.com/v0/\(config.baseId)/\(tableName)/\(targetId)") else {
            throw AirtableService.ServiceError.url
        }

        var updateRequest = URLRequest(url: updateURL)
        updateRequest.httpMethod = "PATCH"
        updateRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let updateBody: [String: Any] = [
            "fields": [
                "Upvotes": currentUpvotes + 1
            ]
        ]

        updateRequest.httpBody = try JSONSerialization.data(withJSONObject: updateBody, options: [])
        let (_, updateResponse) = try await urlSession.data(for: updateRequest)
        guard let http = updateResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AirtableService.ServiceError.http
        }
    }
    
    /// Award points to the author when their content receives an upvote
    func awardPointsForUpvote(targetType: String, targetId: String, fetchData: Data, usersService: UsersService) async {
        do {
            // Get author ID from the record data we already fetched
            let authorId: String?
            if targetType == "Question" {
                let record = try JSONDecoder().decode(AirtableRecord<QuestionFields>.self, from: fetchData)
                authorId = record.fields.author?.first
            } else {
                let record = try JSONDecoder().decode(AirtableRecord<AnswerFields>.self, from: fetchData)
                authorId = record.fields.Author?.first
            }
            
            if let authorId = authorId, !authorId.isEmpty {
                await usersService.addPoints(userRecordId: authorId, points: 1, reason: "Received an upvote")
            }
        } catch {
            print("⚠️ Failed to award points for upvote: \(error)")
        }
    }
}

