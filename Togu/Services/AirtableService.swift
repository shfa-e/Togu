//
//  AirtableService.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
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
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<QuestionFields>.self, from: data)

        let questions: [Question] = decoded.records.map { record in
            record.fields.toQuestion(
                fallbackId: record.id ?? "",
                createdTime: record.createdTime!
            )
        }.sorted { $0.createdAt > $1.createdAt }

        // Sort newest first using createdAt
        return questions.sorted(by: { $0.createdAt > $1.createdAt })
    }

    // MARK: - Fetch Answers
    func fetchAnswers(for question: Question) async throws -> [Answer] {
        let baseURL = try makeListURL(tableName: "Answers")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)

        // ✅ Correct filter formula — no manual encoding
        let filter = "FIND('\(question.id)', {Question})"
        components?.queryItems = [
            URLQueryItem(name: "filterByFormula", value: filter)
        ]

        guard let finalURL = components?.url else { throw ServiceError.url }
        print("🔍 Requesting Answers URL:", finalURL)

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.http }
        if !(200..<300).contains(http.statusCode) {
            print("❌ HTTP Error Status Code:", http.statusCode)
            throw ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<AnswerFields>.self, from: data)
        print("✅ Loaded \(decoded.records.count) answers from Airtable")

        let dateFormatter = ISO8601DateFormatter()

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
        // NEW: Validate the IDs we’re about to send to Airtable
        guard !authorId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ createAnswer aborted: empty authorId") // NEW
            throw ServiceError.missingAuthorId              // NEW
        }
        guard question.id.hasPrefix("rec") else {           // NEW (Airtable record IDs start with 'rec')
            print("❌ createAnswer aborted: invalid question.id \(question.id)") // NEW
            throw ServiceError.invalidQuestionId            // NEW
        }

        guard let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Answers") else {
            throw ServiceError.url
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // ✅ Do NOT set "Created Date" if it's a Created time field in Airtable
        let body: [String: Any] = [
            "fields": [
                "Answer Text": text,
                "Author": [authorId],
                "Question": [question.id],
                "Upvotes": 0
            ]
        ]

        // NEW: Log the body you’re sending (helps when debugging 422s)
        if let dbg = try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted]),
           let dbgStr = String(data: dbg, encoding: .utf8) {
            print("📤 POST /Answers body:\n\(dbgStr)") // NEW
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            print("❌ Failed to create answer. Status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print(String(data: data, encoding: .utf8) ?? "No response")
            throw ServiceError.http
        }

        print("✅ Successfully created answer")
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

        if !tags.isEmpty {
            fields["Tags"] = tags
        }

        if let image {
            let base64 = image.data.base64EncodedString()
            fields["Image"] = [[
                "data": base64,
                "filename": image.filename,
                "type": image.mimeType
            ]]
        }

        let payload: [String: Any] = ["fields": fields]

        if let dbg = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let dump = String(data: dbg, encoding: .utf8) {
            print("📤 POST /Questions body:\n\(dump)")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, resp) = try await URLSession.shared.data(for: request)
        if let http = resp as? HTTPURLResponse {
            print("📡 Airtable createQuestion status:", http.statusCode)
            if let body = String(data: data, encoding: .utf8) {
                print("🧩 Airtable response body:\n\(body)")
            }
            guard (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
        }

        let record = try JSONDecoder().decode(AirtableRecord<QuestionFields>.self, from: data)
        let fallbackId = record.id ?? UUID().uuidString
        let createdTime = record.createdTime ?? ISO8601DateFormatter().string(from: Date())
        return record.fields.toQuestion(fallbackId: fallbackId, createdTime: createdTime)
    }
    
    
    // MARK: - Helper: Parse Airtable date safely
    private func parseAirtableDate(_ str: String?) -> Date {
        guard let str = str else { return Date() }

        // 1. Try ISO8601 (Airtable API format)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: str) {
            return date
        }

        // 2. Try simple date (like "11/5/2025")
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"
        df.locale = Locale(identifier: "en_US_POSIX")
        if let date = df.date(from: str) {
            return date
        }

        // 3. Try "yyyy-MM-dd" fallback (some Airtable fields use this)
        df.dateFormat = "yyyy-MM-dd"
        if let date = df.date(from: str) {
            return date
        }

        // Fallback: return current date
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

    // Return the Airtable Users recordId for a given email, or nil if not found.
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
            print("❌ Failed to fetch user by email: \(email)")
            return nil
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<UserFields>.self, from: data)
        return decoded.records.first?.id
    }

    // Create a Users record if the email isn't found, then return its recordId.
    func createUserIfMissing(name: String, email: String) async throws -> String {
        if let existing = try await fetchUserRecordId(byEmail: email) {
            print("✅ Found existing Airtable user for \(email)")
            return existing
        }

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
            print("❌ Failed to create new user for \(email)")
            throw ServiceError.http
        }

        let created = try JSONDecoder().decode(AirtableCreateResponse<UserFields>.self, from: data)
        let id = created.id ?? ""
        print("✅ Created new Airtable user record for \(email) → \(id)")
        return id
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
            print("❌ hasUserVoted error:", String(data: data, encoding: .utf8) ?? "")
            throw ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<VoteFields>.self, from: data)
        return !decoded.records.isEmpty
    }
    
    // Create a vote record and update the upvote count
    func createVote(userId: String, targetType: String, targetId: String) async throws {
        guard !userId.isEmpty, !targetId.isEmpty else { throw ServiceError.missingAuthorId }

        if try await hasUserVoted(userId: userId, targetType: targetType, targetId: targetId) {
            print("⚠️ already voted")
            return
        }

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

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            print("❌ Failed vote:", String(data: data, encoding: .utf8) ?? "")
            throw ServiceError.http
        }

        print("✅ vote created")
        try await updateUpvoteCount(targetType: targetType, targetId: targetId)
    }
    
    /// Update the upvote count on a Question or Answer
    private func updateUpvoteCount(targetType: String, targetId: String) async throws {
        let tableName = targetType == "Question" ? config.questionsTable : "Answers"
        let upvoteFieldName = targetType == "Question" ? "Upvotes" : "Upvotes"
        
        // First, fetch the current record to get the current upvote count
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
        
        // Parse current upvote count
        let currentUpvotes: Int
        if targetType == "Question" {
            let record = try JSONDecoder().decode(AirtableRecord<QuestionFields>.self, from: fetchData)
            currentUpvotes = record.fields.upvotes ?? 0
        } else {
            let record = try JSONDecoder().decode(AirtableRecord<AnswerFields>.self, from: fetchData)
            currentUpvotes = record.fields.Upvotes ?? 0
        }
        
        // Update with incremented count
        guard let updateURL = URL(string: "https://api.airtable.com/v0/\(config.baseId)/\(tableName)/\(targetId)") else {
            throw ServiceError.url
        }
        
        var updateRequest = URLRequest(url: updateURL)
        updateRequest.httpMethod = "PATCH"
        updateRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let updateBody: [String: Any] = [
            "fields": [
                upvoteFieldName: currentUpvotes + 1
            ]
        ]
        
        updateRequest.httpBody = try JSONSerialization.data(withJSONObject: updateBody, options: [])
        
        let (_, updateResponse) = try await urlSession.data(for: updateRequest)
        guard let http = updateResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.http
        }
        
        print("✅ Updated \(targetType) \(targetId) upvotes to \(currentUpvotes + 1)")
    }
    
}

