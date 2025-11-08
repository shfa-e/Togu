//
//  LoginView.swift
//  Togu
//
//  Created by Whyyy on 05/11/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var router: Router
    @StateObject private var viewModel: LoginViewModel

    init() {
        let tempAuth = AuthViewModel()
        _viewModel = StateObject(wrappedValue: LoginViewModel(auth: tempAuth))
    }

    var body: some View {
        ZStack {
            // Mesh Gradient Background
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0], [1.0, 0.0],
                        [0.0, 0.5], [viewModel.meshAnimation ? 0.1 : 0.9, 0.5], [1.0, 0.5],
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
                        viewModel.meshAnimation.toggle()
                    }
                }
            } else {
                // Fallback on earlier versions
            }

            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

                    // Logo Section
                    logoSection
                        .padding(.bottom, 40) // slightly reduced so welcomeSection sits closer

                    // Welcome Text (now includes the yellow "title" circle)
                    welcomeSection
                        .padding(.bottom, 60)

                    // Sign In Button
                    signInButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // Error Message
                    if let errorMsg = viewModel.errorMessage {
                        errorMessage(errorMsg)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .onAppear {
            viewModel.updateAuth(auth)
            withAnimation(.easeOut(duration: 0.6)) {
                viewModel.startAnimations()
            }
        }
    }

    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 20) {
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            
            Text("togu.")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .kerning(-1.2)
                .foregroundColor(.clear)
                .opacity(viewModel.isAnimating ? 1.0 : 0.0)
                .offset(y: viewModel.isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: viewModel.isAnimating)
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
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .kerning(-1.2)
                    )
                )

        }
    }

    // MARK: - Welcome Section (includes yellow circle with "title")
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            
            Text("Share. Learn. Build Together.")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.toguTextPrimary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 40)
            
            // Subtext
            Text("Welcome to togu, the best place for students to connect & create.")
                .font(.system(size: 16))
                .foregroundColor(.toguTextSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(viewModel.isAnimating ? 1.0 : 0.0)
        .offset(y: viewModel.isAnimating ? 0 : 20)
        .animation(.easeOut(duration: 0.6), value: viewModel.isAnimating)
    }

    // MARK: - Sign In Button
    private var signInButton: some View {
        Button {
            viewModel.signIn()
        } label: {
            HStack(spacing: 12) {
                if viewModel.authIsBusy {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.1)
                } else {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(viewModel.authIsBusy ? "Signing in..." : "Sign in with IDServe")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if viewModel.authIsBusy {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.toguDisabled,
                                Color.toguDisabled.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.toguPrimary,
                                Color.toguPrimary.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(16)
            .shadow(
                color: viewModel.authIsBusy ? Color.clear : Color.toguPrimary.opacity(0.3),
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .disabled(viewModel.authIsBusy)
        .scaleEffect(viewModel.isAnimating ? 1.0 : 0.95)
        .opacity(viewModel.isAnimating ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5), value: viewModel.isAnimating)
    }

    // MARK: - Error Message
    private func errorMessage(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.toguError)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.toguError)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.toguError.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.toguError.opacity(0.3), lineWidth: 1)
                )
        )
    }

}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
        .environmentObject(Router())
}
