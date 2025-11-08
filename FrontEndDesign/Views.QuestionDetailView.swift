//
//  Views.QuestionDetailView.swift.swift
//  Togu
//
//  Created by HY on 05/11/2025.
//

import SwiftUI

struct QuestionDetailView: View {
    let post: Post
    let answers: [Answer]

    @State private var answerDraft = ""

    init(post: Post, answers: [Answer] = Answer.sample) {
        self.post = post
        self.answers = answers
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                questionHeaderCard
                questionMetaRow
                tagsWrap
                codeSnippetBlock
                answersHeader
                answersList
                loadMoreButton
                answerComposer
            }
            .padding(20)
        }
        .background(Color.toguBackground.ignoresSafeArea())
        .navigationTitle("Question")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Question Card

    private var questionHeaderCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.author)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    HStack(spacing: 6) {
                        Text("Posted \(timeAgo(from: post.createdAt))")
                            .foregroundColor(.white.opacity(0.65))
                        Circle()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 4, height: 4)
                        Text("Level \(post.authorLevel)")
                            .foregroundColor(.toguPrimary.opacity(0.9))
                    }
                    .font(.system(size: 12, weight: .medium))
                }

                Spacer()

                Button { } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 18, weight: .semibold))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(post.title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)

                Text(post.contentPreview)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 14) {
                actionPill(symbol: "hand.thumbsup", text: "\(post.interactions)")
                actionPill(symbol: "bubble.right", text: "\(post.commentCount)")
                Spacer()
                Button { } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(hex: "#111827"))
        )
    }

    private func actionPill(symbol: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(text)
        }
        .foregroundColor(.white.opacity(0.75))
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
    }

    // MARK: - Meta row / tags / code

    private var questionMetaRow: some View {
        HStack(spacing: 18) {
            metaButton(icon: "bookmark", label: "Save")
            metaButton(icon: "square.and.arrow.up", label: "Share")
            metaButton(icon: "flag", label: "Report")
            Spacer()
        }
    }

    private func metaButton(icon: String, label: String) -> some View {
        Button { } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.toguTextSecondary)
        }
    }

    private var tagsWrap: some View {
        FlowLayout(spacing: 10) {
            ForEach(post.tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.toguPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.toguPrimary.opacity(0.15))
                    )
            }
        }
    }

    private var codeSnippetBlock: some View {
        Group {
            if let snippet = post.codeSnippet, !snippet.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Code Snippet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.toguTextPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(snippet)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.codeBlue)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Answers

    private var answersHeader: some View {
        HStack {
            Text("\(answers.count) Answers")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.toguTextPrimary)

            Spacer()

            Button { } label: {
                HStack(spacing: 6) {
                    Text("Sort by")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.toguTextSecondary)
            }
        }
    }

    private var answersList: some View {
        VStack(spacing: 16) {
            ForEach(answers) { answer in
                answerCard(for: answer)
            }
        }
    }

    private func answerCard(for answer: Answer) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.toguPrimary.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(answer.author.first ?? "U"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.toguPrimary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(answer.author)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.toguTextPrimary)
                        Text("• Level \(answer.level)")
                            .font(.system(size: 12))
                            .foregroundColor(.toguTextSecondary)
                        if answer.isBest {
                            Text("Best")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(Color(hex: "#22C55E"))
                                )
                        }
                    }
                    Text(answer.ago)
                        .font(.system(size: 12))
                        .foregroundColor(.toguTextSecondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup")
                        Text("\(answer.votes)")
                    }
                    Button { } label: { Image(systemName: "bookmark") }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.toguTextSecondary)
            }

            Text(answer.body)
                .font(.system(size: 14))
                .foregroundColor(.toguTextPrimary)

            FlowLayout(spacing: 8) {
                ForEach(answer.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.toguPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color.toguPrimary.opacity(0.12))
                        )
                }
            }

            HStack(spacing: 20) {
                Button("Reply") { }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.toguPrimary)
                Button("Share") { }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.toguTextSecondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.toguBorder, lineWidth: 1)
                )
        )
    }

    private var loadMoreButton: some View {
        Button { } label: {
            Text("Load more answers")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.toguPrimary)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.toguPrimary.opacity(0.25), lineWidth: 1)
                )
        }
    }

    // MARK: - Composer

    private var answerComposer: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your Answer")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.toguTextPrimary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $answerDraft)
                    .frame(minHeight: 130)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
                    )

                if answerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Share your solution or insights…")
                        .font(.system(size: 14))
                        .foregroundColor(.toguTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }

            HStack(spacing: 12) {
                composerButton(icon: "chevron.left.forwardslash.chevron.right")
                composerButton(icon: "photo")
                composerButton(icon: "paperclip")
                Spacer()
                Button { } label: {
                    Text("Post Answer")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(Color.toguPrimary)
                        )
                }
                .disabled(answerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(answerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    private func composerButton(icon: String) -> some View {
        Button { } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.toguTextSecondary)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.toguCard)
                )
        }
    }

    private func timeAgo(from date: Date) -> String {
        let delta = Date().timeIntervalSince(date)
        if delta > 3600 {
            let hours = Int(delta / 3600)
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        }
        let mins = max(Int(delta / 60), 1)
        return "\(mins) minute\(mins > 1 ? "s" : "") ago"
    }
}

// MARK: - Model + Sample

struct Answer: Identifiable {
    let id = UUID()
    let author: String
    let level: Int
    let isBest: Bool
    let votes: Int
    let ago: String
    let body: String
    let tags: [String]

    static let sample: [Answer] = [
        Answer(author: "Lisa Thompson", level: 25, isBest: true, votes: 45, ago: "Answered 1 hour ago", body: "Wrap the state change in withAnimation and pick the proper curve for smoother transitions.", tags: ["SwiftUI", "Animation"]),
        Answer(author: "Marcus Johnson", level: 18, isBest: false, votes: 18, ago: "Answered 6 hours ago", body: "Custom AnyTransition gives you full control over how the view enters and leaves.", tags: ["SwiftUI"]),
        Answer(author: "Sarah Mitchell", level: 22, isBest: false, votes: 12, ago: "Answered 20 minutes ago", body: "Check WWDC sessions on Advanced SwiftUI Animations to fine‑tune matchedGeometryEffect.", tags: ["SwiftUI"]),
        Answer(author: "David Park", level: 14, isBest: false, votes: 9, ago: "Answered 15 minutes ago", body: "Explicit animation values allow duration control and chaining for complex effects.", tags: ["Animation"]),
        Answer(author: "Emma Rodriguez", level: 20, isBest: false, votes: 8, ago: "Answered just now", body: "GeometryReader helps when you need precise positioning in custom transitions.", tags: ["Geometry"])
    ]
}

#Preview {
    NavigationStack {
        QuestionDetailView(
            post: Post(
                community: "SwiftUI",
                author: "Alex Chen",
                authorLevel: 15,
                title: "How to implement custom transitions in SwiftUI?",
                contentPreview: "I'm trying to create a custom slide transition for my views but can't get the animation timing right.",
                upvotes: 24,
                downvotes: 0,
                commentCount: 8,
                tags: ["SwiftUI", "Animation", "iOS 17"],
                codeSnippet: "struct ContentView: View {\n    // sample code\n}"
            )
        )
    }
}
