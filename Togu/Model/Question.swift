//
//  Question.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

struct Question: Identifiable, Hashable {
	let id: String
	let title: String
	let text: String
	let imageURL: URL?
	let author: String
	let upvotes: Int
	let createdAt: Date
    let tags: [String]

	init(
		id: String,
		title: String,
		text: String,
		tags: [String] = [],
		imageURL: URL? = nil,
		author: String,
		upvotes: Int = 0,
		createdAt: Date = Date()
	) {
		self.id = id
		self.title = title
		self.text = text
		self.tags = tags
		self.imageURL = imageURL
		self.author = author
		self.upvotes = upvotes
		self.createdAt = createdAt
	}
}

extension Question {
    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: createdAt)
    }
}

