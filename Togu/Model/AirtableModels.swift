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
    var QuestionID: Int?
    var Title: String?
    var Body: String?
    var Tags: [String]?
    var Image: [ATAttachment]?
    var Author: [String]?
    var Upvotes: Int?
    var Answers: [String]?
    var CreatedDate: String?
}

// 3. Answers
struct AnswerFields: Codable {
    var AnswerID: Int?
    var AnswerText: String?
    var Question: [String]?
    var Author: [String]?
    var Upvotes: Int?
    var CreatedDate: String?
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
