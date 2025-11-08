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
    @State private var showAnswerForm = false
    @EnvironmentObject var auth: AuthViewModel
    
    init(question: Question, airtable: AirtableService) {
        self.question = question
        self.airtable = airtable
        _vm = StateObject(wrappedValue: QuestionDetailViewModel(question: question, airtable: airtable))
    }
    
    var body: some View {
        List {
            sectionHeader
            sectionAnswers
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Question")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAnswerForm = true
                } label: {
                    Label("Answer", systemImage: "text.bubble")
                }
            }
        }
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
        .sheet(isPresented: $showAnswerForm) {
            AnswerFormView(question: question, vm: vm)
                .environmentObject(auth)
        }
    }
    
    private var sectionHeader: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(question.title)
                    .font(.title3).bold()
                
                Text(question.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                if let url = question.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // MARK: - Author, Date, and Upvote
                HStack(spacing: 8) {
                    Label(question.author, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Text(question.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // 🟢 Upvote Button
                    Button {
                        Task {
                            await vm.upvoteQuestion(question: question, auth: auth)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: vm.hasVotedOnQuestion ? "arrow.up.circle.fill" : "arrow.up.circle")
                                .font(.caption)
                            Text("\(vm.updatedQuestionvotes ?? question.upvotes)")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(vm.hasVotedOnQuestion ? .blue : .secondary)
                    .disabled(vm.hasVotedOnQuestion || vm.isVoting)
                }
                
                if !question.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(question.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var sectionAnswers: some View {
        Section("Answers") {
            if vm.isLoading {
                HStack { ProgressView(); Text("Loading…") }
            } else if let err = vm.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(err).foregroundStyle(.red)
                    Button("Retry") { vm.loadAnswers(for: question) }
                }
            } else if vm.answers.isEmpty {
                Text("No answers yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.answers) { answer in
                    VStack(alignment: .leading, spacing: 6) {
                        // The answer text
                        Text(answer.text)
                            .font(.body)
                            .padding(.bottom, 2)

                        // Author, date, and upvote button
                        HStack(spacing: 8) {
                            Label(answer.author, systemImage: "person.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if !answer.formattedDate.isEmpty {
                                Text("•").font(.caption).foregroundStyle(.tertiary)
                                Text(answer.formattedDate)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // 🟢 Upvote button for answers
                            Button {
                                Task {
                                    await vm.upvoteAnswer(answer, auth: auth)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: (vm.hasVotedOnAnswers[answer.id] == true) ? "arrow.up.circle.fill" : "arrow.up.circle")
                                        .font(.caption)
                                    Text("\(vm.updatedAnswerVotes[answer.id] ?? answer.upvotes)")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor((vm.hasVotedOnAnswers[answer.id] == true) ? .blue : .secondary)
                            .disabled((vm.hasVotedOnAnswers[answer.id] == true) || vm.isVoting)
                        }
                    }
                }
            }
        }
    }
}
