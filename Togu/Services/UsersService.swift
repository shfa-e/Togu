//
//  UsersService.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

final class UsersService {
    private let config: AirtableConfig
    private let urlSession: URLSession
    
    init(config: AirtableConfig, urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }
    
    // MARK: - User Management
    
    func fetchUserRecordId(byEmail email: String) async throws -> String? {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "api.airtable.com"
        comps.path = "/v0/\(config.baseId)/Users"
        let formula = "LOWER({Email})='\(email.lowercased())'"
        comps.queryItems = [ URLQueryItem(name: "filterByFormula", value: formula) ]

        guard let url = comps.url else { throw AirtableService.ServiceError.url }

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
            throw AirtableService.ServiceError.url
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
            throw AirtableService.ServiceError.http
        }

        let created = try JSONDecoder().decode(AirtableCreateResponse<UserFields>.self, from: data)
        return created.id ?? ""
    }
    
    func fetchUser(recordId: String) async throws -> (id: String, fields: UserFields) {
        guard let url = URL(string: "https://api.airtable.com/v0/\(config.baseId)/Users/\(recordId)") else {
            throw AirtableService.ServiceError.url
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AirtableService.ServiceError.http
        }

        do {
            let record = try JSONDecoder().decode(AirtableRecord<UserFields>.self, from: data)
            return (id: record.id ?? recordId, fields: record.fields)
        } catch {
            throw AirtableService.ServiceError.decoding
        }
    }
    
    func getAuthorDetails(authorId: String) async throws -> (profilePictureURL: URL?, level: Int) {
        do {
            let (_, userFields) = try await fetchUser(recordId: authorId)
            let points = userFields.Points ?? 0
            let level = max(1, points / 100 + 1)
            let pictureURL = userFields.ProfilePicture?.first?.url.flatMap { URL(string: $0) }
            return (profilePictureURL: pictureURL, level: level)
        } catch {
            return (profilePictureURL: nil, level: 1)
        }
    }
    
    // MARK: - Points Management
    
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
        } catch {
            print("⚠️ Failed to add points to user: \(error)")
        }
    }
}

