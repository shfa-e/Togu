//
//  Answer.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

struct Answer: Identifiable, Codable {
    let id: String
    let text: String
    let author: String
    let upvotes: Int
    let createdAt: Date
    let questionId: String?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}


