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

    enum ServiceError: Error { case url, http }
    
}

