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
    @EnvironmentObject var badgeNotificationManager: BadgeNotificationManager
    
    init(question: Question, airtable: AirtableService) {
        self.question = question
        self.airtable = airtable
        _vm = StateObject(wrappedValue: QuestionDetailViewModel(question: question, airtable: airtable))
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 28) {
                    QuestionHeaderCard(
                        question: question,
                        hasVoted: vm.hasVotedOnQuestion,
                        upvoteCount: vm.updatedQuestionvotes ?? question.upvotes,
                        answerCount: vm.answers.count,
                        onUpvote: {
                            Task {
                                await vm.upvoteQuestion(question: question, auth: auth)
                            }
                        },
                        isVoting: vm.isVoting
                    )
                    QuestionMetaRow()
                    QuestionTagsView(tags: question.tags)
                    if let snippet = MarkdownHelpers.extractCodeSnippet(from: question.text), !snippet.isEmpty {
                        CodeSnippetBlock(code: snippet)
                    }
                    AnswersHeader(answerCount: vm.answers.count)
                    answersList
                    loadMoreButton
                }
                .padding(20)
                .padding(.bottom, 100) // Space for FAB
            }
        .background(Color.toguLightBackground.ignoresSafeArea())
        .navigationTitle("Question")
        .navigationBarTitleDisplayMode(.inline)
        .errorToast(error: Binding(
            get: { vm.errorMessage },
            set: { vm.errorMessage = $0 }
        ))
        .onAppear { 
            // Set badge notification manager on service
            airtable.badgeNotificationManager = badgeNotificationManager
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
    
    // MARK: - Answers
    
    private var answersList: some View {
        Group {
            if vm.isLoading {
                LoadingView("Loading answers…")
                    .padding()
            } else if let err = vm.errorMessage {
                ErrorView(
                    error: err,
                    retryAction: {
                        vm.loadAnswers(for: question, auth: auth)
                    }
                )
                .padding()
            } else if vm.answers.isEmpty {
                EmptyStateView(
                    icon: "bubble.right",
                    title: "No answers yet",
                    message: "Be the first to answer this question!"
                )
                .padding()
            } else {
                VStack(spacing: 16) {
                ForEach(vm.answers) { answer in
                    AnswerCardView(
                        answer: answer,
                        hasVoted: vm.hasVotedOnAnswers[answer.id] == true,
                        upvoteCount: vm.updatedAnswerVotes[answer.id] ?? answer.upvotes,
                        onUpvote: {
                            Task {
                                await vm.upvoteAnswer(answer, auth: auth)
                            }
                        },
                        isVoting: vm.isVoting
                    )
                }
                }
            }
        }
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
    
}
