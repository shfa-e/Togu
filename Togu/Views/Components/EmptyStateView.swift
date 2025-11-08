//
//  EmptyStateView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.toguTextSecondary.opacity(0.6))
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.toguTextPrimary)
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.toguTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.toguPrimary)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "text.bubble",
        title: "No questions yet",
        message: "Be the first to ask a question!",
        actionTitle: "Ask Question",
        action: {}
    )
}

