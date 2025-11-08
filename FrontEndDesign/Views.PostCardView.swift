//
//  Views.PostCardView.swift
//  Togu
//
//  Created by HY on 05/11/2025.
//

import SwiftUI

struct ViewsPostCardView: View {
    let post: Post
    let upAction: () -> Void
    let downAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("r/\(post.community)")
                    .font(.caption.bold())
                    .foregroundColor(.toguPrimary)
                Spacer()
                Text("u/\(post.author)")
                    .font(.caption)
                    .foregroundColor(.toguTextSecondary)
            }
            
            Text(post.title)
                .font(.headline)
                .foregroundColor(.toguTextPrimary)
            Text(post.contentPreview)
                .font(.subheadline)
                .foregroundColor(.toguTextSecondary)
                .lineLimit(2)
            
            HStack {
                Button(action: upAction) {
                    Image(systemName: "arrow.up")
                }
                Text("\(post.upvotes - post.downvotes)")
                Button(action: downAction) {
                    Image(systemName: "arrow.down")
                }
                Spacer()
                Image(systemName: "bubble.right")
                Text("\(post.commentCount)")
            }
            .font(.subheadline)
            .foregroundColor(.toguTextSecondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.toguCard))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.toguBorder, lineWidth: 1))
        .shadow(color: .toguShadow, radius: 4, x: 0, y: 2)
    }
}
