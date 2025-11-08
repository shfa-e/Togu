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

    func fetchQuestions(searchText: String? = nil, selectedTag: String? = nil) async throws -> [Question] {
        let baseURL = try makeListURL(tableName: config.questionsTable)
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        
        // Build filter formula if we have search text or selected tag
        var filterParts: [String] = []
        
        if let tag = selectedTag, !tag.isEmpty {
            // Filter by tag: check if Tags array contains the selected tag
            // For Airtable multi-select fields, use FIND to check if value exists in array
            filterParts.append("FIND('\(tag)', {Tags})")
        }
        
        if let search = searchText, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)
            // Search in both Title and Body fields
            // Use OR to search in either field, and use FIND for case-insensitive matching
            let titleSearch = "FIND(LOWER('\(trimmedSearch.lowercased())'), LOWER({Title}))"
            let bodySearch = "FIND(LOWER('\(trimmedSearch.lowercased())'), LOWER({Body}))"
            filterParts.append("OR(\(titleSearch), \(bodySearch))")
        }
        
        // Combine filters with AND if we have both tag and search
        let formula: String?
        if filterParts.count == 1 {
            formula = filterParts.first
        } else if filterParts.count > 1 {
            formula = "AND(\(filterParts.joined(separator: ", ")))"
        } else {
            formula = nil
        }
        
        if let formula = formula {
            components?.queryItems = [
                URLQueryItem(name: "filterByFormula", value: formula)
            ]
        }
        
        guard let finalURL = components?.url else {
            throw ServiceError.url
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<QuestionFields>.self, from: data)
        let questions: [Question] = decoded.records.map { record in
            record.fields.toQuestion(
                fallbackId: record.id ?? "",
                createdTime: record.createdTime ?? ""
            )
        }
        return questions.sorted(by: { $0.createdAt > $1.createdAt })
    }

    // MARK: - Fetch Answers

    func fetchAnswers(for question: Question) async throws -> [Answer] {
        let baseURL = try makeListURL(tableName: "Answers")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let filter = "FIND('\(question.id)', {Question})"
        components?.queryItems = [ URLQueryItem(name: "filterByFormula", value: filter) ]

        guard let finalURL = components?.url else { throw ServiceError.url }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<AnswerFields>.self, from: data)

        let answers: [Answer] = decoded.records.compactMap { record in
            let fields = record.fields
            return Answer(
                id: record.id ?? UUID().uuidString,
                text: fields.AnswerText ?? "(No answer text)",
                author: fields.AuthorName?.first ?? "Anonymous",
                upvotes: fields.Upvotes ?? 0,
                createdAt: parseAirtableDate(fields.CreatedDate),
                questionId: question.id
            )
        }

        return answers.sorted(by: { $0.createdAt < $1.createdAt })
    }
    
    // MARK: - Create Answer

    func createAnswer(for question: Question, text: String, authorId: String) async throws {
        guard !authorId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ServiceError.missingAuthorId
        }
        guard question.id.hasPrefix("rec") else {
            throw ServiceError.invalidQuestionId
        }

        guard let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Answers") else {
            throw ServiceError.url
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "fields": [
                "Answer Text": text,
                "Author": [authorId],
                "Question": [question.id],
                "Upvotes": 0
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }

        // decode or ignore response as necessary; here we simply succeed on 2xx
        _ = data
        
        // Award points for posting an answer (fire and forget)
        Task {
            await addPoints(userRecordId: authorId, points: 5, reason: "Posted an answer")
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
        guard !authorId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ServiceError.missingAuthorId
        }

        guard let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/\(config.questionsTable)") else {
            throw ServiceError.url
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var fields: [String: Any] = [
            "Title": title,
            "Body": body,
            "Author": [authorId],
            "Upvotes": 0
        ]

        if !tags.isEmpty { fields["Tags"] = tags }

        if let image {
            let base64 = image.data.base64EncodedString()
            fields["Image"] = [[
                "data": base64,
                "filename": image.filename,
                "type": image.mimeType
            ]]
        }

        let payload: [String: Any] = ["fields": fields]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, resp) = try await urlSession.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }

        let record = try JSONDecoder().decode(AirtableRecord<QuestionFields>.self, from: data)
        let fallbackId = record.id ?? UUID().uuidString
        let createdTime = record.createdTime ?? ISO8601DateFormatter().string(from: Date())
        
        // Award points for posting a question (fire and forget)
        Task {
            await addPoints(userRecordId: authorId, points: 10, reason: "Posted a question")
        }
        
        // Check and award milestone badges (fire and forget)
        Task {
            // small initial delay so Airtable has time to index the new record
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
            await checkQuestionMilestones(userRecordId: authorId)
        }
        
        return record.fields.toQuestion(fallbackId: fallbackId, createdTime: createdTime)
    }
    
    // MARK: - Helper: Parse Airtable date safely

    private func parseAirtableDate(_ str: String?) -> Date {
        guard let str = str else { return Date() }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: str) { return date }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "MM/dd/yyyy"
        if let date = df.date(from: str) { return date }

        df.dateFormat = "yyyy-MM-dd"
        if let date = df.date(from: str) { return date }

        return Date()
    }
    
    // MARK: - Helpers

    private func makeListURL(tableName: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/\(config.baseId)/\(tableName)"
        components.queryItems = [URLQueryItem(name: "pageSize", value: "50")]

        guard let url = components.url else { throw ServiceError.url }
        return url
    }

    func fetchUserRecordId(byEmail email: String) async throws -> String? {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "api.airtable.com"
        comps.path = "/v0/\(config.baseId)/Users"
        let formula = "LOWER({Email})='\(email.lowercased())'"
        comps.queryItems = [ URLQueryItem(name: "filterByFormula", value: formula) ]

        guard let url = comps.url else { throw ServiceError.url }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return nil
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<UserFields>.self, from: data)
        return decoded.records.first?.id
    }

    func createUserIfMissing(name: String, email: String) async throws -> String {
        if let existing = try await fetchUserRecordId(byEmail: email) { return existing }

        guard let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Users") else {
            throw ServiceError.url
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "fields": [
                "Name": name,
                "Email": email,
                "Points": 0  // Initialize points to 0
            ]
        ]

        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }

        let created = try JSONDecoder().decode(AirtableCreateResponse<UserFields>.self, from: data)
        return created.id ?? ""
    }

    // MARK: - Voting System

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
        guard let url = comps.url else { throw ServiceError.url }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<VoteFields>.self, from: data)
        return !decoded.records.isEmpty
    }

    func createVote(userId: String, targetType: String, targetId: String) async throws {
        guard !userId.isEmpty, !targetId.isEmpty else { throw ServiceError.missingAuthorId }

        if try await hasUserVoted(userId: userId, targetType: targetType, targetId: targetId) { return }

        guard let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Votes") else {
            throw ServiceError.url
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
            throw ServiceError.http
        }

        try await updateUpvoteCount(targetType: targetType, targetId: targetId)
    }

    private func updateUpvoteCount(targetType: String, targetId: String) async throws {
        let tableName = targetType == "Question" ? config.questionsTable : "Answers"

        guard let fetchURL = URL(string: "https://api.airtable.com/v0/\(config.baseId)/\(tableName)/\(targetId)") else {
            throw ServiceError.url
        }

        var fetchRequest = URLRequest(url: fetchURL)
        fetchRequest.httpMethod = "GET"
        fetchRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        fetchRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        let (fetchData, fetchResponse) = try await urlSession.data(for: fetchRequest)
        guard let http = fetchResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
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
            throw ServiceError.url
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
            throw ServiceError.http
        }
        
        // Award points to the author when their content gets upvoted
        Task {
            await awardPointsForUpvote(targetType: targetType, targetId: targetId, fetchData: fetchData)
        }
    }
    
    /// Award points to the author when their content receives an upvote
    private func awardPointsForUpvote(targetType: String, targetId: String, fetchData: Data) async {
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
                await addPoints(userRecordId: authorId, points: 1, reason: "Received an upvote")
            }
        } catch {
            print("⚠️ Failed to award points for upvote: \(error)")
        }
    }
    
    /// Add points to a user's total
    func addPoints(userRecordId: String, points: Int, reason: String = "") async {
        guard !userRecordId.isEmpty, points > 0 else { return }
        
        do {
            // Fetch current user record to get current points
            let (_, userFields) = try await fetchUser(recordId: userRecordId)
            let currentPoints = userFields.Points ?? 0
            let newPoints = currentPoints + points
            
            // Update user's points
            guard let updateURL = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Users/\(userRecordId)") else {
                print("❌ Failed to create update URL for points")
                return
            }
            
            var updateRequest = URLRequest(url: updateURL)
            updateRequest.httpMethod = "PATCH"
            updateRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let updateBody: [String: Any] = [
                "fields": [
                    "Points": newPoints
                ]
            ]
            
            updateRequest.httpBody = try JSONSerialization.data(withJSONObject: updateBody, options: [])
            
            let (_, updateResponse) = try await urlSession.data(for: updateRequest)
            guard let http = updateResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                print("❌ Failed to update points: HTTP \((updateResponse as? HTTPURLResponse)?.statusCode ?? -1)")
                return
            }
            
            print("✅ Added \(points) points to user \(userRecordId) (now \(newPoints) total)\(reason.isEmpty ? "" : " - \(reason)")")
            
            // Check for points milestone badges (e.g., 100 points)
            if newPoints >= 100 {
                do {
                    try await awardBadge(userRecordId: userRecordId, badgeName: "Centurion")
                } catch {
                    print("⚠️ Failed to award Centurion badge: \(error)")
                }
            }
        } catch {
            print("⚠️ Failed to add points to user: \(error)")
        }
    }

    // MARK: - Profile/User Data

    func fetchUser(recordId: String) async throws -> (id: String, fields: UserFields) {
        guard let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Users/\(recordId)") else {
            throw ServiceError.url
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }

        do {
            let record = try JSONDecoder().decode(AirtableRecord<UserFields>.self, from: data)
            return (id: record.id ?? recordId, fields: record.fields)
        } catch {
            throw ServiceError.decoding
        }
    }

    func fetchUserQuestions(userRecordId: String) async throws -> [Question] {
        let baseURL = try makeListURL(tableName: config.questionsTable)
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let filter = "FIND('\(userRecordId)', {Author})"
        components?.queryItems = [ URLQueryItem(name: "filterByFormula", value: filter) ]
        guard let finalURL = components?.url else { throw ServiceError.url }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<QuestionFields>.self, from: data)
        let questions: [Question] = decoded.records.map { record in
            record.fields.toQuestion(
                fallbackId: record.id ?? "",
                createdTime: record.createdTime ?? ""
            )
        }
        return questions.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func fetchUserAnswers(userRecordId: String) async throws -> [Answer] {
        let baseURL = try makeListURL(tableName: "Answers")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let filter = "FIND('\(userRecordId)', {Author})"
        components?.queryItems = [ URLQueryItem(name: "filterByFormula", value: filter) ]
        guard let finalURL = components?.url else { throw ServiceError.url }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<AnswerFields>.self, from: data)
        let answers: [Answer] = decoded.records.compactMap { record in
            let fields = record.fields
            let questionId = fields.Question?.first ?? ""
            return Answer(
                id: record.id ?? UUID().uuidString,
                text: fields.AnswerText ?? "",
                author: fields.AuthorName?.first ?? "Unknown",
                upvotes: fields.Upvotes ?? 0,
                createdAt: parseAirtableDate(fields.CreatedDate) ?? Date(),
                questionId: questionId
            )
        }
        return answers.sorted(by: { $0.createdAt > $1.createdAt })
    }

    // MARK: - Badges

    func fetchUserBadges(userRecordId: String) async throws
    -> [(id: String, name: String, description: String?, iconURL: URL?, dateEarned: Date?)] {

        func requestBadges(withFormula formula: String?) async throws -> (Data, URLResponse) {
            let baseURL = try makeListURL(tableName: "Badges")
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            if let formula { components?.queryItems = [URLQueryItem(name: "filterByFormula", value: formula)] }
            guard let url = components?.url else { throw ServiceError.url }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            return try await urlSession.data(for: request)
        }

        let formula = "FIND('\(userRecordId)', {EarnedBy})"

        // Attempt server-side filter
        do {
            let (data, response) = try await requestBadges(withFormula: formula)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                let decoded = try JSONDecoder().decode(AirtableListResponse<BadgeFields>.self, from: data)
                return decoded.records.compactMap { record in
                    let name = record.fields.badgeName ?? extractBadgeNameWeakly(from: record.fields)
                    guard let badgeName = name else { return nil }
                    let iconURL = record.fields.icon?.first?.url.flatMap(URL.init)
                    let date = parseAirtableDate(record.fields.dateEarned)
                    return (record.id ?? UUID().uuidString, badgeName, record.fields.description, iconURL, date)
                }
            }
        } catch {
            // fallback below
        }

        // Fallback: fetch all badges and filter locally
        let (allData, allResponse) = try await requestBadges(withFormula: nil)
        guard let http = allResponse as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ServiceError.http
        }

        let decodedAll = try JSONDecoder().decode(AirtableListResponse<BadgeFields>.self, from: allData)
        let filtered = decodedAll.records.compactMap { record -> (id: String, name: String, description: String?, iconURL: URL?, dateEarned: Date?)? in
            if let earned = record.fields.earnedBy, earned.contains(userRecordId) {
                let name = record.fields.badgeName ?? extractBadgeNameWeakly(from: record.fields)
                guard let badgeName = name else { return nil }
                let icon = record.fields.icon?.first?.url.flatMap(URL.init)
                let dateEarned = parseAirtableDate(record.fields.dateEarned)
                return (record.id ?? UUID().uuidString, badgeName, record.fields.description, icon, dateEarned)
            }
            // try weak inspection (encoded JSON) for linked IDs
            if let encoded = try? JSONEncoder().encode(record.fields),
               let jsonObj = try? JSONSerialization.jsonObject(with: encoded, options: []) as? [String: Any] {
                for value in jsonObj.values {
                    if let arr = value as? [String], arr.contains(userRecordId) {
                        let name = record.fields.badgeName ?? extractBadgeNameWeakly(from: record.fields)
                        guard let badgeName = name else { return nil }
                        let icon = record.fields.icon?.first?.url.flatMap(URL.init)
                        let dateEarned = parseAirtableDate(record.fields.dateEarned)
                        return (record.id ?? UUID().uuidString, badgeName, record.fields.description, icon, dateEarned)
                    }
                    if let arrDict = value as? [[String: Any]] {
                        for dict in arrDict {
                            if let idVal = dict["id"] as? String, idVal == userRecordId {
                                let name = record.fields.badgeName ?? extractBadgeNameWeakly(from: record.fields)
                                guard let badgeName = name else { return nil }
                                let icon = record.fields.icon?.first?.url.flatMap(URL.init)
                                let dateEarned = parseAirtableDate(record.fields.dateEarned)
                                return (record.id ?? UUID().uuidString, badgeName, record.fields.description, icon, dateEarned)
                            }
                        }
                    }
                }
            }
            return nil
        }

        return filtered
    }

    private func extractBadgeNameWeakly(from fields: BadgeFields) -> String? {
        if let s = fields.badgeName, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s
        }
        if let encoded = try? JSONEncoder().encode(fields),
           let jsonObj = try? JSONSerialization.jsonObject(with: encoded, options: []) as? [String: Any] {
            for key in ["Badge Name", "BadgeName", "Name", "badgeName", "title"] {
                if let val = jsonObj[key] as? String, !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return val
                }
            }
            for (k, v) in jsonObj where k.lowercased().contains("badge") || k.lowercased().contains("name") {
                if let s = v as? String, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return s
                }
            }
        }
        return nil
    }
    
    // MARK: - Badge Earning Logic
    
    /// Check if a user has already earned a specific badge by name
    func hasUserEarnedBadge(userRecordId: String, badgeName: String) async throws -> Bool {
        let baseURL = try makeListURL(tableName: "Badges")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        
        // Filter: Badge Name matches AND EarnedBy contains userRecordId
        let formula = "AND({Badge Name}='\(badgeName)', FIND('\(userRecordId)', {EarnedBy}) > 0)"
        components?.queryItems = [
            URLQueryItem(name: "filterByFormula", value: formula)
        ]
        
        guard let finalURL = components?.url else { throw ServiceError.url }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }
        
        let decoded = try JSONDecoder().decode(AirtableListResponse<BadgeFields>.self, from: data)
        return !decoded.records.isEmpty
    }
    
    /// Award a badge to a user by badge name
    func awardBadge(userRecordId: String, badgeName: String) async throws {
        print("🏆 Attempting to award badge '\(badgeName)' to user \(userRecordId)")
        
        // First, check if user already has this badge
        do {
            let alreadyHas = try await hasUserEarnedBadge(userRecordId: userRecordId, badgeName: badgeName)
            if alreadyHas {
                print("⚠️ User \(userRecordId) already has badge: \(badgeName)")
                return
            }
        } catch {
            print("⚠️ Error checking if user has badge: \(error)")
            // Continue anyway - might be a transient error
        }
        
        // Find the badge record by name
        let baseURL = try makeListURL(tableName: "Badges")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let formula = "{Badge Name}='\(badgeName)'"
        components?.queryItems = [
            URLQueryItem(name: "filterByFormula", value: formula)
        ]
        
        guard let searchURL = components?.url else {
            print("❌ Failed to create search URL for badge: \(badgeName)")
            throw ServiceError.url
        }
        
        print("🔍 Searching for badge with formula: \(formula)")
        
        var searchRequest = URLRequest(url: searchURL)
        searchRequest.httpMethod = "GET"
        searchRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        searchRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (searchData, searchResponse) = try await urlSession.data(for: searchRequest)
        
        guard let http = searchResponse as? HTTPURLResponse else {
            print("❌ Invalid response when searching for badge")
            throw ServiceError.http
        }
        
        if !(200..<300).contains(http.statusCode) {
            let errorBody = String(data: searchData, encoding: .utf8) ?? "Unknown error"
            print("❌ HTTP \(http.statusCode) when searching for badge '\(badgeName)': \(errorBody)")
            throw ServiceError.http
        }
        
        let decoded = try JSONDecoder().decode(AirtableListResponse<BadgeFields>.self, from: searchData)
        
        guard let badgeRecord = decoded.records.first else {
            print("⚠️ Badge '\(badgeName)' not found in Airtable. Available badges: \(decoded.records.map { $0.fields.badgeName ?? "Unknown" })")
            // Try to list all badges for debugging
            await listAllBadges()
            return
        }
        
        guard let badgeRecordId = badgeRecord.id else {
            print("❌ Badge record found but has no ID")
            return
        }
        
        print("✅ Found badge record: \(badgeRecordId)")
        
        // Get current EarnedBy array and add the user
        var currentEarnedBy = badgeRecord.fields.earnedBy ?? []
        if currentEarnedBy.contains(userRecordId) {
            print("⚠️ User already in EarnedBy array")
            return
        }
        
        currentEarnedBy.append(userRecordId)
        print("📝 Updating badge with \(currentEarnedBy.count) users in EarnedBy")
        
        // Update the badge record with the new user
        guard let updateURL = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Badges/\(badgeRecordId)") else {
            print("❌ Failed to create update URL")
            throw ServiceError.url
        }
        
        var updateRequest = URLRequest(url: updateURL)
        updateRequest.httpMethod = "PATCH"
        updateRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let updateBody: [String: Any] = [
            "fields": [
                "EarnedBy": currentEarnedBy
            ]
        ]
        
        updateRequest.httpBody = try JSONSerialization.data(withJSONObject: updateBody, options: [])
        
        let (updateData, updateResponse) = try await urlSession.data(for: updateRequest)
        
        guard let updateHttp = updateResponse as? HTTPURLResponse else {
            print("❌ Invalid response when updating badge")
            throw ServiceError.http
        }
        
        if !(200..<300).contains(updateHttp.statusCode) {
            let errorBody = String(data: updateData, encoding: .utf8) ?? "Unknown error"
            print("❌ HTTP \(updateHttp.statusCode) when updating badge: \(errorBody)")
            throw ServiceError.http
        }
        
        print("✅ Successfully awarded badge '\(badgeName)' to user \(userRecordId)")
    }
    
    /// Helper method to list all badges for debugging
    private func listAllBadges() async {
        do {
            let baseURL = try makeListURL(tableName: "Badges")
            var request = URLRequest(url: baseURL)
            request.httpMethod = "GET"
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return
            }
            
            let decoded = try JSONDecoder().decode(AirtableListResponse<BadgeFields>.self, from: data)
            let badgeNames = decoded.records.compactMap { $0.fields.badgeName }
            print("📋 Available badges in Airtable: \(badgeNames)")
        } catch {
            print("⚠️ Failed to list badges: \(error)")
        }
    }
    
    /// Check and award milestone badges after a user action
    func checkAndAwardMilestoneBadges(userRecordId: String, action: BadgeMilestone) async {
        do {
            switch action {
            case .firstQuestion:
                try await awardBadge(userRecordId: userRecordId, badgeName: "First Question")
            case .firstAnswer:
                try await awardBadge(userRecordId: userRecordId, badgeName: "First Answer")
            case .fiveQuestions:
                try await awardBadge(userRecordId: userRecordId, badgeName: "Question Master")
            case .tenAnswers:
                try await awardBadge(userRecordId: userRecordId, badgeName: "Answer Expert")
            case .hundredPoints:
                try await awardBadge(userRecordId: userRecordId, badgeName: "Centurion")
            }
        } catch {
            // Silently fail - badge awarding shouldn't break the main flow
            print("⚠️ Failed to award badge for \(action): \(error)")
        }
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
                            try await awardBadge(userRecordId: userRecordId, badgeName: "First Question")
                        } catch {
                            print("❌ Failed to award 'First Question' badge: \(error)")
                        }
                    }
                    if count == 5 {
                        print("🎯 User has exactly 5 questions - awarding 'Question Master' badge")
                        do {
                            try await awardBadge(userRecordId: userRecordId, badgeName: "Question Master")
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
                    try await awardBadge(userRecordId: userRecordId, badgeName: "First Answer")
                } catch {
                    print("❌ Failed to award 'First Answer' badge: \(error)")
                }
            } else if count == 10 {
                print("🎯 User has exactly 10 answers - awarding 'Answer Expert' badge")
                do {
                    try await awardBadge(userRecordId: userRecordId, badgeName: "Answer Expert")
                } catch {
                    print("❌ Failed to award 'Answer Expert' badge: \(error)")
                }
            }
        } catch {
            print("❌ Failed to check answer milestones: \(error)")
        }
    }
}

// MARK: - Badge Milestone Types

enum BadgeMilestone {
    case firstQuestion
    case firstAnswer
    case fiveQuestions
    case tenAnswers
    case hundredPoints
}
