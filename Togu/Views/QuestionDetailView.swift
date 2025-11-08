//
//  QuestionDetailView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI
import Combine

struct QuestionDetailView: View {
    let question: Question
    let airtable: AirtableService
    @StateObject private var vm: QuestionDetailViewModel
    @State private var answerDraft = ""
    @State private var showingCodeEditor = false
    @State private var showAnswerForm = false
    @EnvironmentObject var auth: AuthViewModel
    
    init(question: Question, airtable: AirtableService) {
        self.question = question
        self.airtable = airtable
        _vm = StateObject(wrappedValue: QuestionDetailViewModel(question: question, airtable: airtable))
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 28) {
                    questionHeaderCard
                    questionMetaRow
                    tagsWrap
                    codeSnippetBlock
                    answersHeader
                    answersList
                    loadMoreButton
                }
                .padding(20)
                .padding(.bottom, 100) // Space for FAB
            }
            .background(Color(hex: "#F5F5F5").ignoresSafeArea())
        .navigationTitle("Question")
        .navigationBarTitleDisplayMode(.inline)
            .onAppear { 
                vm.loadAnswers(for: question, auth: auth)
                Task {
                    await vm.checkVoteStatus(auth: auth)
                }
            }
            .refreshable { 
                vm.loadAnswers(for: question, auth: auth)
                Task {
                    await vm.checkVoteStatus(auth: auth)
                }
            }
            .overlay {
                if vm.isSubmittingAnswer {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        ProgressView("Posting…")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                }
            }
            
            // Floating Action Button
            floatingActionButton
        }
        .sheet(isPresented: $showAnswerForm) {
            AnswerFormView(question: question, vm: vm)
                .environmentObject(auth)
        }
    }
    
    // MARK: - Question Header Card
    
    private var questionHeaderCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                // Profile Picture
                Group {
                    if let imageURL = question.authorProfilePictureURL {
                        AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                                profilePlaceholder
                        case .success(let image):
                            image
                                .resizable()
                                    .scaledToFill()
                        case .failure:
                                profilePlaceholder
                        @unknown default:
                                profilePlaceholder
                            }
                        }
                    } else {
                        profilePlaceholder
                    }
                }
                .frame(width: 46, height: 46)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.author)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.toguTextPrimary)
                    
                    HStack(spacing: 6) {
                        Text("Posted \(timeAgo(from: question.createdAt))")
                            .foregroundColor(.toguTextSecondary)
                        Circle()
                            .fill(Color.toguTextSecondary.opacity(0.5))
                            .frame(width: 4, height: 4)
                        if let level = question.authorLevel {
                            Text("Level \(level)")
                                .foregroundColor(.toguPrimary)
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                    
                    Spacer()
                    
                Button { } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.toguTextSecondary)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(question.title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.toguTextPrimary)
                
                Text(questionTextWithoutCode)
                    .font(.system(size: 15))
                    .foregroundColor(.toguTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            HStack(spacing: 14) {
                    Button {
                        Task {
                        await vm.upvoteQuestion(question: question, auth: auth)
                        }
                    } label: {
                    HStack(spacing: 6) {
                        Image(systemName: vm.hasVotedOnQuestion ? "arrow.up.circle.fill" : "arrow.up.circle")
                            Text("\(vm.updatedQuestionvotes ?? question.upvotes)")
                    }
                    .foregroundColor(vm.hasVotedOnQuestion ? .toguPrimary : .toguTextSecondary)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.toguCard)
                    )
                }
                .disabled(vm.hasVotedOnQuestion || vm.isVoting)
                
                actionPill(symbol: "bubble.right", text: "\(vm.answers.count)")
                Spacer()
                Button { } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.toguTextSecondary)
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.white)
                .stroke(Color.toguBorder, lineWidth: 1)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
    
    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.toguCard)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.toguTextSecondary)
            )
    }
    
    private func actionPill(symbol: String, text: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                Text(text)
            }
            .foregroundColor(.toguTextSecondary)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.toguCard)
            )
        }
    }
    
    // MARK: - Meta Row / Tags / Code
    
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
                            ForEach(question.tags, id: \.self) { tag in
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
            if let snippet = extractedCodeSnippet, !snippet.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Code Snippet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.toguTextPrimary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.codeBlue)

                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(snippet)
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
    }
    
    
    private var extractedCodeSnippet: String? {
        // Extract code from markdown code blocks (```code```)
        let text = question.text
        let pattern = #"```[\s\S]*?```"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            let codeBlock = String(text[range])
            // Remove the ``` markers
            return codeBlock
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    
    private var questionTextWithoutCode: String {
        // Remove code blocks from text for display
        let text = question.text
        let pattern = #"```[\s\S]*?```"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let cleaned = regex.stringByReplacingMatches(
                in: text,
                options: [],
                range: NSRange(text.startIndex..., in: text),
                withTemplate: ""
            )
            return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
    
    // MARK: - Answers
    
    private var answersHeader: some View {
        HStack {
            Text("\(vm.answers.count) Answers")
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
        Group {
            if vm.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading…")
                        .foregroundColor(.toguTextSecondary)
                }
                .padding()
            } else if let err = vm.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(err)
                        .foregroundColor(.toguError)
                    Button("Retry") {
                        vm.loadAnswers(for: question, auth: auth)
                    }
                    .foregroundColor(.toguPrimary)
                }
                .padding()
            } else if vm.answers.isEmpty {
                Text("No answers yet")
                    .foregroundColor(.toguTextSecondary)
                    .padding()
            } else {
                VStack(spacing: 16) {
                ForEach(vm.answers) { answer in
                        answerCard(for: answer)
                    }
                }
            }
        }
    }
    
    private func answerCard(for answer: Answer) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                // Profile Picture (placeholder for now)
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
                        // Note: Answer model doesn't have level yet, could be enhanced
                        Text("• Level 1")
                            .font(.system(size: 12))
                            .foregroundColor(.toguTextSecondary)
                        // Best answer badge could be added later
                    }
                    Text(timeAgo(from: answer.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.toguTextSecondary)
                            }

                            Spacer()

                HStack(spacing: 12) {
                            Button {
                                Task {
                            await vm.upvoteAnswer(answer, auth: auth)
                                }
                            } label: {
                                HStack(spacing: 4) {
                            Image(systemName: (vm.hasVotedOnAnswers[answer.id] == true) ? "arrow.up.circle.fill" : "arrow.up.circle")
                                    Text("\(vm.updatedAnswerVotes[answer.id] ?? answer.upvotes)")
                        }
                        .foregroundColor((vm.hasVotedOnAnswers[answer.id] == true) ? .toguPrimary : .toguTextSecondary)
                    }
                    .disabled((vm.hasVotedOnAnswers[answer.id] == true) || vm.isVoting)
                    
                    Button { } label: {
                        Image(systemName: "bookmark")
                            .foregroundColor(.toguTextSecondary)
                    }
                }
                .font(.system(size: 13, weight: .medium))
            }
            
            Text(answer.text)
                .font(.system(size: 14))
                .foregroundColor(.toguTextPrimary)
            
            // Extract tags from answer text if present (could be enhanced)
            // For now, we'll skip tags in answers as they're not in the model
            
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
        Button { 
            // Load more answers - could be implemented later
        } label: {
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
        .opacity(vm.answers.count < 10 ? 0 : 1) // Only show if there might be more
    }
    
    // MARK: - Floating Action Button
    
    private var floatingActionButton: some View {
        Button {
            showAnswerForm = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.toguPrimary)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
        }
        .padding(.trailing, 17)
        .padding(.bottom, 68)
    }
    
    // MARK: - Composer (Deprecated - kept for reference, but not used)
    
    private var answerComposer: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your Answer")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.toguTextPrimary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $answerDraft)
                    .frame(minHeight: 130)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
                            )
                    )
                
                if answerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Share your solution or insights…")
                        .font(.system(size: 14))
                        .foregroundColor(.toguTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            
            // Error message
            if let error = vm.submitAnswerError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.toguError)
            }
            
            HStack(spacing: 12) {
                composerButton(icon: "chevron.left.forwardslash.chevron.right") {
                    showingCodeEditor = true
                }
                composerButton(icon: "photo") {
                    // Photo action - can be implemented later
                }
                composerButton(icon: "paperclip") {
                    // File attachment - can be implemented later
                }
                Spacer()
                Button {
                    Task {
                        await vm.submitAnswer(text: answerDraft, auth: auth)
                        if vm.submitAnswerError == nil {
                            answerDraft = ""
                        }
                    }
                } label: {
                    Text("Post Answer")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(isValid ? Color.toguPrimary : Color.gray)
                        )
                }
                .disabled(!isValid || vm.isSubmittingAnswer)
                .opacity(isValid ? 1 : 0.4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .sheet(isPresented: $showingCodeEditor) {
            codeEditorSheet
        }
    }
    
    private func composerButton(icon: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
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
    
    private var codeEditorSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $answerDraft)
                    .font(.system(size: 14, design: .monospaced))
                    .padding()
                    .background(Color(hex: "#F5F5F5"))
                    .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Code Snippet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCodeEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingCodeEditor = false
                    }
                    .foregroundColor(.toguPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !answerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Helper Functions
    
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
