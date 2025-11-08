//
//  PostCardView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct PostCardView: View {
    let question: Question
    let upAction: () -> Void
    let answerCount: Int
    let upvoteCount: Int
    let hasVoted: Bool
    
    init(
        question: Question,
        upAction: @escaping () -> Void,
        answerCount: Int,
        upvoteCount: Int,
        hasVoted: Bool
    ) {
        self.question = question
        self.upAction = upAction
        self.answerCount = answerCount
        self.upvoteCount = upvoteCount
        self.hasVoted = hasVoted
    }
    
    private var authorProfilePictureURL: URL? {
        question.authorProfilePictureURL
    }
    
    private var authorLevel: Int {
        question.authorLevel ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Section
            HStack(spacing: 12) {
                // Profile Picture
                Group {
                    if let imageURL = authorProfilePictureURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                profilePlaceholder
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                profilePlaceholder
                            @unknown default:
                                profilePlaceholder
                            }
                        }
                    } else {
                        profilePlaceholder
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                // Name and Timestamp
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.author)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.toguTextPrimary)
                    
                    Text(relativeTimeString(from: question.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.toguTextSecondary)
                }
                
                Spacer()
                
                // Level Badge
                Text("Level \(authorLevel)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.toguPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.toguPrimary.opacity(0.15))
                    )
            }
            
            // Title
            Text(question.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.toguTextPrimary)
                .lineLimit(2)
            
            // Body/Description (without code snippet)
            Text(questionTextWithoutCode)
                .font(.system(size: 15))
                .foregroundColor(.toguTextPrimary)
                .lineLimit(3)
            
            // Code Snippet (if present)
            if let codeSnippet = extractedCodeSnippet, !codeSnippet.isEmpty {
                Text(codeSnippet)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.codeBlue)
                    )
            }
            
            // Tags
            if !question.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(question.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12))
                                .foregroundColor(.toguPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule().fill(Color.toguPrimary.opacity(0.15))
                                )
                        }
                    }
                }
            }
            
            // Footer Actions
            HStack(spacing: 20) {
                // Upvotes (clickable)
                Button(action: upAction) {
                    HStack(spacing: 6) {
                        Image(systemName: hasVoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                            .font(.system(size: 16))
                            .foregroundColor(hasVoted ? .toguPrimary : .toguTextSecondary)
                        Text("\(upvoteCount)")
                            .font(.system(size: 14))
                            .foregroundColor(.toguTextSecondary)
                    }
                }
                .disabled(hasVoted)
                
                // Comments
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 16))
                        .foregroundColor(.toguTextSecondary)
                    Text("\(answerCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.toguTextSecondary)
                }
                
                Spacer()
                
                // Bookmark
                Button {
                    // Bookmark action
                } label: {
                    Image(systemName: "bookmark")
                        .font(.system(size: 16))
                        .foregroundColor(.toguTextSecondary)
                }
                
                // Share
                Button {
                    // Share action
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.toguTextSecondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.toguCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.toguBorder, lineWidth: 1)
        )
        .shadow(color: .toguShadow, radius: 4, x: 0, y: 2)
    }
    
    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.15))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.toguTextSecondary.opacity(0.6))
            )
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let relativeString = formatter.localizedString(for: date, relativeTo: Date())
        return "Posted \(relativeString)"
    }
    
    // MARK: - Code Snippet Extraction
    
    private var extractedCodeSnippet: String? {
        // Extract code from markdown code blocks (```code```)
        let text = question.text
        let pattern = #"```[\s\S]*?```"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            let codeBlock = String(text[range])
            // Remove the ``` markers and get first line for preview
            let cleaned = codeBlock
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            // Get first line only for card preview
            return cleaned.components(separatedBy: .newlines).first
        }
        return nil
    }
    
    private var questionTextWithoutCode: String {
        // Remove code blocks from text for display
        let text = question.text
        let pattern = #"```[\s\S]*?```"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let cleaned = regex.stringByReplacingMatches(
                in: text,
                options: [],
                range: NSRange(text.startIndex..., in: text),
                withTemplate: ""
            )
            return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
}
