//
//  QuestionTagsView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct QuestionTagsView: View {
    let tags: [String]
    
    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.toguPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.toguPrimary.opacity(0.15))
                    )
            }
        }
    }
}

