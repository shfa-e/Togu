//
//  LeaderboardService.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

final class LeaderboardService {
    private let config: AirtableConfig
    private let urlSession: URLSession
    
    init(config: AirtableConfig, urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }
    
    func fetchLeaderboard() async throws -> [(id: String, name: String, points: Int, profilePictureURL: URL?)] {
        let baseURL = try makeListURL(tableName: "Users")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        
        // Sort by Points descending, limit to top 100
        components?.queryItems = [
            URLQueryItem(name: "sort[0][field]", value: "Points"),
            URLQueryItem(name: "sort[0][direction]", value: "desc"),
            URLQueryItem(name: "maxRecords", value: "100")
        ]
        
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
        
        let decoded = try JSONDecoder().decode(AirtableListResponse<UserFields>.self, from: data)
        
        return decoded.records.enumerated().map { index, record in
            let fields = record.fields
            let pictureURL = fields.ProfilePicture?.first?.url.flatMap { URL(string: $0) }
            return (
                id: record.id ?? "",
                name: fields.Name ?? "Unknown",
                points: fields.Points ?? 0,
                profilePictureURL: pictureURL
            )
        }
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

