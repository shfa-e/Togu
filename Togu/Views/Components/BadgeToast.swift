//
//  BadgeToast.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct BadgeToast: ViewModifier {
    @Binding var badgeName: String?
    let onDismiss: (() -> Void)?
    
    init(badgeName: Binding<String?>, onDismiss: (() -> Void)? = nil) {
        self._badgeName = badgeName
        self.onDismiss = onDismiss
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let badgeName = badgeName {
                VStack {
                    HStack(spacing: 16) {
                        // Trophy/Badge Icon
                        ZStack {
                            Circle()
                                .fill(Color.toguPrimary.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.toguPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Badge Earned!")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.toguTextSecondary)
                            
                            Text(badgeName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.toguTextPrimary)
                        }
                        
                        Spacer()
                        
                        Button {
                            self.badgeName = nil
                            onDismiss?()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.toguTextSecondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: badgeName)
    }
}

extension View {
    func badgeToast(badgeName: Binding<String?>, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(BadgeToast(badgeName: badgeName, onDismiss: onDismiss))
    }
}

