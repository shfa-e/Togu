//
//  QuestionHeaderCard.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct QuestionHeaderCard: View {
    let question: Question
    let hasVoted: Bool
    let upvoteCount: Int
    let answerCount: Int
    let onUpvote: () -> Void
    let isVoting: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                // Profile Picture
                Group {
                    if let imageURL = question.authorProfilePictureURL {
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
                .frame(width: 46, height: 46)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.author)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.toguTextPrimary)
                    
                    HStack(spacing: 6) {
                        Text("Posted \(FormattingHelpers.timeAgoShort(from: question.createdAt))")
                            .foregroundColor(.toguTextSecondary)
                        Circle()
                            .fill(Color.toguTextSecondary.opacity(0.5))
                            .frame(width: 4, height: 4)
                        if let level = question.authorLevel {
                            Text("Level \(level)")
                                .foregroundColor(.toguPrimary)
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                
                Spacer()
                
                Button { } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.toguTextSecondary)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(question.title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.toguTextPrimary)
                
                Text(MarkdownHelpers.removeCodeBlocks(from: question.text))
                    .font(.system(size: 15))
                    .foregroundColor(.toguTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            HStack(spacing: 14) {
                Button {
                    onUpvote()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: hasVoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                        Text("\(upvoteCount)")
                    }
                    .foregroundColor(hasVoted ? .toguPrimary : .toguTextSecondary)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.toguCard)
                    )
                }
                .disabled(hasVoted || isVoting)
                
                actionPill(symbol: "bubble.right", text: "\(answerCount)")
                Spacer()
                Button { } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.toguTextSecondary)
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(uiColor: .systemBackground))
                .stroke(Color.toguBorder, lineWidth: 1)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
    
    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.toguCard)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.toguTextSecondary)
            )
    }
    
    private func actionPill(symbol: String, text: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                Text(text)
            }
            .foregroundColor(.toguTextSecondary)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.toguCard)
            )
        }
    }
}

