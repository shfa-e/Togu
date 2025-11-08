//
//  AnswersHeader.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct AnswersHeader: View {
    let answerCount: Int
    
    var body: some View {
        HStack {
            Text("\(answerCount) Answers")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.toguTextPrimary)
            
            Spacer()
            
            Button { } label: {
                HStack(spacing: 6) {
                    Text("Sort by")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.toguTextSecondary)
            }
        }
    }
}

