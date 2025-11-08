//
//  QuestionCardView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct QuestionCardView: View {
    let question: Question
    let airtable: AirtableService
    let upAction: () -> Void
    let upvoteCount: Int
    let hasVoted: Bool
    
    @State private var answerCount: Int = 0
    @State private var isLoadingAnswerCount = false
    
    var body: some View {
        PostCardView(
            question: question,
            upAction: upAction,
            answerCount: answerCount,
            upvoteCount: upvoteCount,
            hasVoted: hasVoted
        )
        .task {
            await loadAnswerCount()
        }
    }
    
    private func loadAnswerCount() async {
        guard !isLoadingAnswerCount else { return }
        isLoadingAnswerCount = true
        
        do {
            let count = try await airtable.getAnswerCount(for: question.id)
            await MainActor.run {
                answerCount = count
                isLoadingAnswerCount = false
            }
        } catch {
            print("⚠️ Failed to load answer count: \(error)")
            await MainActor.run {
                isLoadingAnswerCount = false
            }
        }
    }
}

