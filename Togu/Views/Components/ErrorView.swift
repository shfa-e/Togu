//
//  ErrorView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct ErrorView: View {
    let error: String
    let retryAction: (() -> Void)?
    
    init(error: String, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.toguError)
            
            Text("Something went wrong")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.toguTextPrimary)
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.toguTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
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
    ErrorView(error: "Failed to load questions. Please check your connection.", retryAction: {})
}

