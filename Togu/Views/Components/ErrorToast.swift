//
//  ErrorToast.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct ErrorToast: ViewModifier {
    @Binding var error: String?
    let onDismiss: (() -> Void)?
    
    init(error: Binding<String?>, onDismiss: (() -> Void)? = nil) {
        self._error = error
        self.onDismiss = onDismiss
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let error = error {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Text(error)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button {
                            self.error = nil
                            onDismiss?()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.toguError)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: error)
    }
}

extension View {
    func errorToast(error: Binding<String?>, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(ErrorToast(error: error, onDismiss: onDismiss))
    }
}

