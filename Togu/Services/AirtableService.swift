//
//  AirtableService.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

struct AirtableConfig {
	let apiKey: String
	let baseId: String
	let questionsTable: String

	init?() {
		let info = Bundle.main.infoDictionary ?? [:]
		guard let apiKey = info["AIRTABLE_KEY"] as? String, !apiKey.isEmpty,
				let baseId = info["AIRTABLE_BASE_ID"] as? String, !baseId.isEmpty else {
			return nil
		}
		self.apiKey = apiKey
		self.baseId = baseId
		self.questionsTable = (info["AIRTABLE_TABLE_QUESTIONS"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (info["AIRTABLE_TABLE_QUESTIONS"] as! String) : "Questions"
	}
}

final class AirtableService {
	private let config: AirtableConfig
	private let urlSession: URLSession

	init?(urlSession: URLSession = .shared) {
		guard let config = AirtableConfig() else { return nil }
		self.config = config
		self.urlSession = urlSession
	}

	// MARK: - Public API
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
		let questions: [Question] = decoded.records.compactMap { record in
			guard let fields = record.fields else { return nil }
			return fields.toQuestion(fallbackId: record.id, createdTime: record.createdTime)
		}
		// Sort newest first using createdAt
		return questions.sorted(by: { $0.createdAt > $1.createdAt })
	}

	// MARK: - Helpers
	private func makeListURL(tableName: String) throws -> URL {
		var components = URLComponents()
		components.scheme = "https"
		components.host = "api.airtable.com"
		components.path = "/v0/\(config.baseId)/\(tableName)"
		components.queryItems = [
			URLQueryItem(name: "pageSize", value: "50")
		]
		guard let url = components.url else { throw ServiceError.url }
		return url
	}

	enum ServiceError: Error { case url, http }
}

// MARK: - Airtable DTOs

struct AirtableListResponse<F: Decodable>: Decodable {
	let records: [AirtableRecord<F>]
}

struct AirtableRecord<F: Decodable>: Decodable {
	let id: String
	let createdTime: String
	let fields: F?
}

extension QuestionFields {
    func toQuestion(fallbackId: String, createdTime: String) -> Question {
        // Map Airtable schema fields to app model
        let createdDate = Self.parseDate(CreatedDate) ?? Self.parseDate(createdTime) ?? Date()
        let imageURLString = Image?.first?.url
        let url = imageURLString.flatMap { URL(string: $0) }
        let authorName = (Author?.first).map { $0 } ?? "Unknown"
        return Question(
            id: UUID(uuidString: String(QuestionID ?? 0)) ?? UUID(),
            title: Title ?? "(No title)",
            text: Body ?? "",
            imageURL: url,
            author: authorName,
            upvotes: Upvotes ?? 0,
            createdAt: createdDate
        )
    }

    private static func parseDate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
