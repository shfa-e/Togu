//
//  CodeSnippetBlock.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct CodeSnippetBlock: View {
    let code: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Code Snippet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.toguTextPrimary)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.codeBlue)

                ScrollView(.horizontal, showsIndicators: false) {
                    Text(code)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

