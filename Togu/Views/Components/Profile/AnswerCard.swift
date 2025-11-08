//
//  AnswerCard.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct ProfileAnswerCard: View {
    let answer: Answer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(answer.text)
                .font(.system(size: 15))
                .foregroundColor(.toguTextPrimary)
                .lineLimit(3)
            
            HStack(spacing: 8) {
                Label("\(answer.upvotes)", systemImage: "arrow.up.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.toguTextSecondary)
                
                Text(answer.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.toguTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
}

