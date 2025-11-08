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
	let authorId: String?
	let upvotes: Int
	let createdAt: Date
    let tags: [String]
    var userHasVoted: Bool = false
    var authorProfilePictureURL: URL?
    var authorLevel: Int?

	init(
		id: String,
		title: String,
		text: String,
		tags: [String] = [],
		imageURL: URL? = nil,
		author: String,
		authorId: String? = nil,
		upvotes: Int = 0,
		createdAt: Date = Date(),
		authorProfilePictureURL: URL? = nil,
		authorLevel: Int? = nil
	) {
		self.id = id
		self.title = title
		self.text = text
		self.tags = tags
		self.imageURL = imageURL
		self.author = author
		self.authorId = authorId
		self.upvotes = upvotes
		self.createdAt = createdAt
		self.authorProfilePictureURL = authorProfilePictureURL
		self.authorLevel = authorLevel
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

