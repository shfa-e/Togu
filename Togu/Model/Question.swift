//
//  Question.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

struct Question: Identifiable, Hashable {
	let id: UUID
	let title: String
	let text: String
	let tags: [String]
	let imageURL: URL?
	let author: String
	let upvotes: Int
	let createdAt: Date

	init(
		id: UUID = UUID(),
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


