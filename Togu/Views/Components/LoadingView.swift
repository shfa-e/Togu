//
//  LoadingView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading…") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.toguPrimary)
                .scaleEffect(1.2)
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.toguTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    LoadingView("Loading questions…")
}

