//
//  QuestionCard.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct ProfileQuestionCard: View {
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.toguTextPrimary)
                .lineLimit(2)
            
            HStack(spacing: 8) {
                Label("\(question.upvotes)", systemImage: "arrow.up.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.toguTextSecondary)
                
                Text(question.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.toguTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
        )
    }
}

