//
//  StatCard.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.toguTextPrimary)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.toguTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
        )
    }
}

