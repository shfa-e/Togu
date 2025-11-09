//
//  AnswerCardView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct AnswerCardView: View {
    let answer: Answer
    let hasVoted: Bool
    let upvoteCount: Int
    let onUpvote: () -> Void
    let isVoting: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                // Profile Picture (placeholder for now)
                Circle()
                    .fill(Color.toguPrimary.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(answer.author.first ?? "U"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.toguPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(answer.author)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.toguTextPrimary)
                        Text("• Level 1")
                            .font(.system(size: 12))
                            .foregroundColor(.toguTextSecondary)
                    }
                    Text(FormattingHelpers.timeAgoShort(from: answer.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.toguTextSecondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        onUpvote()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: hasVoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                            Text("\(upvoteCount)")
                        }
                        .foregroundColor(hasVoted ? .toguPrimary : .toguTextSecondary)
                    }
                    .disabled(hasVoted || isVoting)
                    
                    Button { } label: {
                        Image(systemName: "bookmark")
                            .foregroundColor(.toguTextSecondary)
                    }
                }
                .font(.system(size: 13, weight: .medium))
            }
            
            Text(answer.text)
                .font(.system(size: 14))
                .foregroundColor(.toguTextPrimary)
            
            HStack(spacing: 20) {
                Button("Reply") { }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.toguPrimary)
                Button("Share") { }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.toguTextSecondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(uiColor: .systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.toguBorder, lineWidth: 1)
                )
        )
    }
}

