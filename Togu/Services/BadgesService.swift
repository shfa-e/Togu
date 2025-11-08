//
//  BadgesService.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

final class BadgesService {
    private let config: AirtableConfig
    private let urlSession: URLSession
    
    init(config: AirtableConfig, urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }
    
    // MARK: - Badge Fetching
    
    func fetchUserBadges(userRecordId: String) async throws
    -> [(id: String, name: String, description: String?, iconURL: URL?, dateEarned: Date?)] {

        func requestBadges(withFormula formula: String?) async throws -> (Data, URLResponse) {
            let baseURL = try makeListURL(tableName: "Badges")
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            if let formula { components?.queryItems = [URLQueryItem(name: "filterByFormula", value: formula)] }
            guard let url = components?.url else { throw AirtableService.ServiceError.url }

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
            throw AirtableService.ServiceError.http
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
        
        guard let finalURL = components?.url else { throw AirtableService.ServiceError.url }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AirtableService.ServiceError.http
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
            throw AirtableService.ServiceError.url
        }
        
        print("🔍 Searching for badge with formula: \(formula)")
        
        var searchRequest = URLRequest(url: searchURL)
        searchRequest.httpMethod = "GET"
        searchRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        searchRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (searchData, searchResponse) = try await urlSession.data(for: searchRequest)
        
        guard let http = searchResponse as? HTTPURLResponse else {
            print("❌ Invalid response when searching for badge")
            throw AirtableService.ServiceError.http
        }
        
        if !(200..<300).contains(http.statusCode) {
            let errorBody = String(data: searchData, encoding: .utf8) ?? "Unknown error"
            print("❌ HTTP \(http.statusCode) when searching for badge '\(badgeName)': \(errorBody)")
            throw AirtableService.ServiceError.http
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
            throw AirtableService.ServiceError.url
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
            throw AirtableService.ServiceError.http
        }
        
        if !(200..<300).contains(updateHttp.statusCode) {
            let errorBody = String(data: updateData, encoding: .utf8) ?? "Unknown error"
            print("❌ HTTP \(updateHttp.statusCode) when updating badge: \(errorBody)")
            throw AirtableService.ServiceError.http
        }
        
        print("✅ Successfully awarded badge '\(badgeName)' to user \(userRecordId)")
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
    
    // MARK: - Helper Methods
    
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

