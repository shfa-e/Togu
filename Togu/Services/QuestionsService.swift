//
//  QuestionsService.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

final class QuestionsService {
    private let config: AirtableConfig
    private let urlSession: URLSession
    
    init(config: AirtableConfig, urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }
    
    func fetchQuestions(
        searchText: String? = nil,
        selectedTag: String? = nil,
        offset: String? = nil,
        pageSize: Int = 20
    ) async throws -> AirtableService.QuestionsResult {
        let baseURL = try makeListURL(tableName: config.questionsTable)
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        
        var queryItems: [URLQueryItem] = []
        
        // Build filter formula if we have search text or selected tag
        var filterParts: [String] = []
        
        if let tag = selectedTag, !tag.isEmpty {
            filterParts.append("FIND('\(tag)', {Tags})")
        }
        
        if let search = searchText, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)
            let titleSearch = "FIND(LOWER('\(trimmedSearch.lowercased())'), LOWER({Title}))"
            let bodySearch = "FIND(LOWER('\(trimmedSearch.lowercased())'), LOWER({Body}))"
            filterParts.append("OR(\(titleSearch), \(bodySearch))")
        }
        
        let formula: String?
        if filterParts.count == 1 {
            formula = filterParts.first
        } else if filterParts.count > 1 {
            formula = "AND(\(filterParts.joined(separator: ", ")))"
        } else {
            formula = nil
        }
        
        if let formula = formula {
            queryItems.append(URLQueryItem(name: "filterByFormula", value: formula))
        }
        
        queryItems.append(URLQueryItem(name: "pageSize", value: String(pageSize)))
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: offset))
        }
        
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let finalURL = components?.url else {
            throw AirtableService.ServiceError.url
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AirtableService.ServiceError.http
        }

        let decoded = try JSONDecoder().decode(AirtableListResponse<QuestionFields>.self, from: data)
        let questions: [Question] = decoded.records.map { record in
            record.fields.toQuestion(
                fallbackId: record.id ?? "",
                createdTime: record.createdTime ?? ""
            )
        }
        let sortedQuestions = questions.sorted(by: { $0.createdAt > $1.createdAt })
        return AirtableService.QuestionsResult(questions: sortedQuestions, nextOffset: decoded.offset)
    }
    
    func createQuestion(
        title: String,
        body: String,
        tags: [String],
        authorId: String,
        image: AirtableService.NewQuestionImage?
    ) async throws -> Question {
        guard !authorId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AirtableService.ServiceError.missingAuthorId
        }

        guard let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/\(config.questionsTable)") else {
            throw AirtableService.ServiceError.url
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
            throw AirtableService.ServiceError.http
        }

        let record = try JSONDecoder().decode(AirtableRecord<QuestionFields>.self, from: data)
        let fallbackId = record.id ?? UUID().uuidString
        let createdTime = record.createdTime ?? ISO8601DateFormatter().string(from: Date())
        
        return record.fields.toQuestion(fallbackId: fallbackId, createdTime: createdTime)
    }
    
    func fetchUserQuestions(userRecordId: String) async throws -> [Question] {
        let baseURL = try makeListURL(tableName: config.questionsTable)
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

        let decoded = try JSONDecoder().decode(AirtableListResponse<QuestionFields>.self, from: data)
        let questions: [Question] = decoded.records.map { record in
            record.fields.toQuestion(
                fallbackId: record.id ?? "",
                createdTime: record.createdTime ?? ""
            )
        }
        return questions.sorted(by: { $0.createdAt > $1.createdAt })
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
}

