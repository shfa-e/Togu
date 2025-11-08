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

    func fetchQuestions() async throws -> [Question] {
        let url = try makeListURL(tableName: config.questionsTable)
        var request = URLRequest(url: url)
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
                "Email": email
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
}
