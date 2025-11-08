////


import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var showingCompose = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    filterBar
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    userProgressCard
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    LazyVStack(spacing: 16) {
                        ForEach(vm.filtered) { post in
                            NavigationLink {
                                QuestionDetailView(post: post)
                            } label: {
                                PostCardView(
                                    post: post,
                                    upAction: { vm.upvote(post) },
                                    downAction: { vm.downvote(post) }
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(hex: "#F5F5F5").ignoresSafeArea())
            
            floatingActionButton
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCompose) {
            NewQuestionView { title, description, tags, snippet in
                vm.addPost(title: title, description: description, tags: tags, codeSnippet: snippet)
                showingCompose = false
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.toguPrimary)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("T")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Text("TOGU")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.toguTextPrimary)
            }
            
            Spacer()
            
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.toguPrimary.opacity(0.3),
                            Color.toguPrimary.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.toguPrimary)
                )
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.toguTextSecondary)
                .font(.system(size: 16))
            
            TextField("Search questions, topics...", text: $vm.searchText)
                .font(.system(size: 15))
                .foregroundColor(.toguTextPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TopicFilter.allCases, id: \.self) { filter in
                    Button {
                        vm.filter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(vm.filter == filter ? .white : .toguTextPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(vm.filter == filter ? Color.toguPrimary : Color(hex: "#F5F5F5"))
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - User Progress Card
    private var userProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level 12 Developer")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("2,450 XP")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 6)
                    
                    let progress = 2450.0 / 3000.0
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            
            Text("550 XP to Level 13")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.toguPrimary,
                    Color.toguPrimary.opacity(0.8)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        Button {
            showingCompose.toggle()
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

#Preview {
    NavigationStack {
        HomeView()
    }
}
