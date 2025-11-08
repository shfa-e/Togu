//
//  QuestionMetaRow.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct QuestionMetaRow: View {
    var body: some View {
        HStack(spacing: 18) {
            metaButton(icon: "bookmark", label: "Save")
            metaButton(icon: "square.and.arrow.up", label: "Share")
            metaButton(icon: "flag", label: "Report")
            Spacer()
        }
    }
    
    private func metaButton(icon: String, label: String) -> some View {
        Button { } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.toguTextSecondary)
        }
    }
}

