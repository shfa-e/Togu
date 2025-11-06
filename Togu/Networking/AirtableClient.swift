//
//  AirtableClient.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//


import Foundation

enum ATTable: String {
    case users = "Users"
    case questions = "Questions"
    case answers = "Answers"
    case votes = "Votes"
    case badges = "Badges"
}

final class AirtableClient {
    private let baseId: String
    private let apiKey: String
    private let session: URLSession = .shared

    init(baseId: String, apiKey: String) {
        self.baseId = baseId
        self.apiKey = apiKey
    }

    // MARK: - Helpers
    private func makeURL(table: ATTable, queryItems: [URLQueryItem] = []) -> URL {
        var comps = URLComponents(string: "https://api.airtable.com/v0/\(baseId)/\(table.rawValue)")!
        comps.queryItems = queryItems.isEmpty ? nil : queryItems
        return comps.url!
    }

    private func request(_ url: URL, method: String = "GET", body: Data? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if body != nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }
        return req
    }

    // MARK: - Fetch Records
    func list<F: Codable>(
        table: ATTable,
        view: String? = nil,
        filterByFormula: String? = nil,
        sort: [(field: String, direction: String)] = [],
        pageSize: Int? = nil,
        offset: String? = nil
    ) async throws -> ATListResponse<F> {
        var items: [URLQueryItem] = []
        if let view { items.append(.init(name: "view", value: view)) }
        if let filterByFormula { items.append(.init(name: "filterByFormula", value: filterByFormula)) }
        for (i, s) in sort.enumerated() {
            items.append(.init(name: "sort[\(i)][field]", value: s.field))
            items.append(.init(name: "sort[\(i)][direction]", value: s.direction))
        }
        if let pageSize { items.append(.init(name: "pageSize", value: String(pageSize))) }
        if let offset { items.append(.init(name: "offset", value: offset)) }

        let url = makeURL(table: table, queryItems: items)
        let (data, _) = try await session.data(for: request(url))
        return try JSONDecoder().decode(ATListResponse<F>.self, from: data)
    }

    // MARK: - Create Record
    func create<F: Codable>(table: ATTable, fields: F) async throws -> ATRecord<F> {
        let body = try JSONEncoder().encode(["fields": fields])
        let url = makeURL(table: table)
        let (data, _) = try await session.data(for: request(url, method: "POST", body: body))
        return try JSONDecoder().decode(ATRecord<F>.self, from: data)
    }

    // MARK: - Update Record
    func update<F: Codable>(table: ATTable, id: String, fields: F) async throws -> ATRecord<F> {
        let body = try JSONEncoder().encode(["fields": fields])
        let url = makeURL(table: table).appendingPathComponent(id)
        let (data, _) = try await session.data(for: request(url, method: "PATCH", body: body))
        return try JSONDecoder().decode(ATRecord<F>.self, from: data)
    }

    // MARK: - Delete Record
    func delete(table: ATTable, id: String) async throws {
        let url = makeURL(table: table).appendingPathComponent(id)
        _ = try await session.data(for: request(url, method: "DELETE"))
    }
}
