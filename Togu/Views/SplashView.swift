//
//  SplashView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var meshAnimation = false

    var body: some View {
        ZStack {
            // Mesh Gradient Background (match LoginView)
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0], [1.0, 0.0],
                        [0.0, 0.5], [meshAnimation ? 0.1 : 0.9, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        Color.toguPrimary, Color.toguPrimary.opacity(0.6), Color.toguPrimary.opacity(0.9),
                        Color.toguPrimary.opacity(0.4), Color.toguBackground, Color.toguPrimary.opacity(0.35),
                        Color.toguPrimary.opacity(0.3), Color.toguPrimary.opacity(0.7), Color.toguPrimary.opacity(0.89)
                    ],
                    smoothsColors: true,
                    colorSpace: .perceptual
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                        meshAnimation.toggle()
                    }
                }
            } else {
                // Fallback: gentle linear gradient similar in tone
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.toguPrimary.opacity(0.15),
                        Color.toguBackground
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 24) {
                // Logo text
                Text("togu.")
                    .font(.system(size: 86, weight: .bold, design: .rounded))
                    .kerning(-1.2)
                    .foregroundColor(.clear)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.6), value: isAnimating)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.toguPrimary.opacity(0.5),
                                Color.toguPrimary.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask(
                            Text("togu.")
                                .font(.system(size: 86, weight: .bold, design: .rounded))
                                .kerning(-1.2)
                        )
                    )

                // Progress indicator under logo
                ProgressView()
                    .tint(.toguPrimary)
                    .scaleEffect(1.2)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
