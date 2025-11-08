//
//  AirtableListResponse.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//


import Foundation

// MARK: - Airtable List Response
struct AirtableListResponse<T: Codable>: Codable {
    let records: [AirtableRecord<T>]
    let offset: String?
}

// MARK: - Record Wrapper
struct AirtableRecord<T: Codable>: Codable {
    let id: String?
    let createdTime: String?
    let fields: T
}
