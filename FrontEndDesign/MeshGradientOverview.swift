//
//  MeshGradientOverview.swift
//  Togu
//
//  Created by Whyyy on 08/11/2025.
//


import SwiftUI

struct MeshGradientOverview: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            MeshGradient(width: 3, height: 3, points: [
                [0.0, 0.0], [0.5, 0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.1 : 0.9, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ], colors: [
                .blue, .purple, .indigo,
                .indigo, isAnimating ? .white : .white, .blue,
                .indigo, .purple, .purple
            ],
                         
                smoothsColors: true,
                colorSpace: .perceptual
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    isAnimating.toggle()
                }
            }
            
            
        }.ignoresSafeArea()
        
    }
}

#Preview {
    MeshGradientOverview()
}
