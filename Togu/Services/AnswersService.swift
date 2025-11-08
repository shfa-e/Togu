//
//  AnswersService.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

final class AnswersService {
    private let config: AirtableConfig
    private let urlSession: URLSession
    
    init(config: AirtableConfig, urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }
    
    func fetchAnswers(for question: Question) async throws -> [Answer] {
        let baseURL = try makeListURL(tableName: "Answers")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let filter = "FIND('\(question.id)', {Question})"
        components?.queryItems = [ URLQueryItem(name: "filterByFormula", value: filter) ]

        guard let finalURL = components?.url else { throw AirtableService.ServiceError.url }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AirtableService.ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<AnswerFields>.self, from: data)

        let answers: [Answer] = decoded.records.compactMap { record in
            let fields = record.fields
            return Answer(
                id: record.id ?? UUID().uuidString,
                text: fields.AnswerText ?? "(No answer text)",
                author: fields.AuthorName?.first ?? "Anonymous",
                upvotes: fields.Upvotes ?? 0,
                createdAt: parseAirtableDate(fields.CreatedDate) ?? Date(),
                questionId: question.id
            )
        }

        return answers.sorted(by: { $0.createdAt < $1.createdAt })
    }
    
    func createAnswer(for question: Question, text: String, authorId: String) async throws {
        guard !authorId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AirtableService.ServiceError.missingAuthorId
        }
        guard question.id.hasPrefix("rec") else {
            throw AirtableService.ServiceError.invalidQuestionId
        }

        guard let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Answers") else {
            throw AirtableService.ServiceError.url
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
            throw AirtableService.ServiceError.http
        }

        _ = data
    }
    
    func fetchUserAnswers(userRecordId: String) async throws -> [Answer] {
        let baseURL = try makeListURL(tableName: "Answers")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let filter = "FIND('\(userRecordId)', {Author})"
        components?.queryItems = [ URLQueryItem(name: "filterByFormula", value: filter) ]
        guard let finalURL = components?.url else { throw AirtableService.ServiceError.url }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AirtableService.ServiceError.http
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
    
    func getAnswerCount(for questionId: String) async throws -> Int {
        let baseURL = try makeListURL(tableName: "Answers")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let filter = "FIND('\(questionId)', {Question})"
        components?.queryItems = [URLQueryItem(name: "filterByFormula", value: filter)]
        
        guard let finalURL = components?.url else { throw AirtableService.ServiceError.url }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AirtableService.ServiceError.http
        }
        
        let decoded = try JSONDecoder().decode(AirtableListResponse<AnswerFields>.self, from: data)
        return decoded.records.count
    }
    
    private func makeListURL(tableName: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/\(config.baseId)/\(tableName)"
        components.queryItems = [URLQueryItem(name: "pageSize", value: "50")]

        guard let url = components.url else { throw AirtableService.ServiceError.url }
        return url
    }
    
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
}

