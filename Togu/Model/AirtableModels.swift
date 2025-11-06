//
//  AirtableModels.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//


import Foundation

// Airtable Wrappers
struct ATListResponse<F: Codable>: Codable {
    let records: [ATRecord<F>]
    let offset: String?
}

struct ATRecord<F: Codable>: Codable {
    let id: String?
    let createdTime: String?
    let fields: F
}

struct ATAttachment: Codable {
    var id: String?
    var url: String?
    var filename: String?
    var type: String?
    var size: Int?
}

// 1. Users
struct UserFields: Codable {
    var UserID: Int?
    var Name: String?
    var Email: String?
    var ProfilePicture: [ATAttachment]?
    var Badges: [String]?
    var QuestionsPosted: [String]?
    var AnswersPosted: [String]?
    var Points: Int?
}

// 2. Questions
struct QuestionFields: Codable {
    let questionID: String?
    let title: String?
    let body: String?
    let tags: [String]?
    let image: [ATAttachment]?
    let author: [String]?
    let authorName: [String]?
    let upvotes: Int?
    let createdDate: String?

    enum CodingKeys: String, CodingKey {
        case questionID = "Question ID"
        case title = "Title"
        case body = "Body"
        case tags = "Tags"
        case image = "Image"
        case author = "Author"
        case authorName = "Author Name"
        case upvotes = "Upvotes"
        case createdDate = "Created Date"
    }
}

// 3. Answers
struct AnswerFields: Codable {
    let AnswerID: String?
    let AnswerText: String?
    let Question: [String]?
    let Author: [String]?
    let AuthorName: [String]?
    let Upvotes: Int?
    let CreatedDate: String?

    enum CodingKeys: String, CodingKey {
        case AnswerID = "Answer ID"
        case AnswerText = "Answer Text"
        case Question
        case Author
        case AuthorName = "Author Name"
        case Upvotes
        case CreatedDate = "Created Date"
    }
}

// 4. Votes
struct VoteFields: Codable {
    var VoteID: Int?
    var User: [String]?
    var TargetType: String?
    var TargetID: [String]?
    var CreatedDate: String?
}

// 5. Badges
struct BadgeFields: Codable {
    var BadgeID: Int?
    var BadgeName: String?
    var Description: String?
    var Icon: [ATAttachment]?
    var EarnedBy: [String]?
    var DateEarned: String?
}

struct AirtableAttachment: Codable {
    var url: String?
}


// MARK: - Field Mappers
extension QuestionFields {
    func toQuestion(fallbackId: String, createdTime: String) -> Question {
            let created = parseAirtableDate(createdDate) ?? parseAirtableDate(createdTime) ?? Date()

            let imageURLString = image?.first?.url
            let url = imageURLString.flatMap { URL(string: $0) }

            // Prefer Author Name lookup field
            let authorDisplay = (authorName?.first).flatMap { !$0.isEmpty ? $0 : nil } ??
                                (author?.first).flatMap { !$0.isEmpty ? $0 : nil } ??
                                "Unknown"

        return Question(
            id: fallbackId,
            title: title ?? "(No title)",
            text: body ?? "",
            tags: tags ?? [],
            imageURL: url,
            author: authorDisplay,
            upvotes: upvotes ?? 0,
            createdAt: created
        )
    }

    private static func parseDate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}


extension AnswerFields {
    // Converts raw Airtable fields into an app Answer model.
    func toAnswer(recordId: String, questionRecordId: String, createdTime: String) -> Answer {
        let createdDate = Self.parseDate(CreatedDate) ?? Self.parseDate(createdTime) ?? Date()
        let authorName = (AuthorName?.first) ?? (Author?.first) ?? "Unknown"
        let linkedQuestionId = Question?.first ?? questionRecordId

        return Answer(
            id: recordId,
            text: AnswerText ?? "",
            author: authorName,
            upvotes: Upvotes ?? 0,
            createdAt: createdDate,
            questionId: questionRecordId
        )
    }

    private static func parseDate(_ str: String?) -> Date? {
        guard let str = str else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}


func parseAirtableDate(_ str: String?) -> Date? {
    guard let s = str, !s.isEmpty else { return nil }

    // Try ISO8601 (Airtable API & “Created time”)
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = iso.date(from: s) { return d }
    if let d = ISO8601DateFormatter().date(from: s) { return d }

    // Fallbacks if your column is a plain Date (not Created time)
    let df = DateFormatter()
    df.locale = .init(identifier: "en_US_POSIX")

    df.dateFormat = "yyyy-MM-dd"
    if let d = df.date(from: s) { return d }
    df.dateFormat = "MM/dd/yyyy"
    if let d = df.date(from: s) { return d }

    return nil
}
