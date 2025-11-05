//
//  HomeView.swift
//  Togu
//
//  Created by Whyyy on 05/11/2025.
//


import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var router: Router

    @State private var isSigningOut = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)

                    Text("You're signed in")
                        .font(.title)
                        .fontWeight(.semibold)

                    if let info = extractUserInfo() {
                        VStack(spacing: 4) {
                            if let name = info["name"] as? String ?? info["given_name"] as? String {
                                Text(name)
                                    .font(.headline)
                            }
                            if let email = info["email"] as? String {
                                Text(email)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    }

                    Spacer()

                    Button(role: .destructive) {
                        signOut()
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .fontDesign(.rounded)
                .padding()

                if isSigningOut {
                    VStack {
                        ProgressView("Signing out…")
                            .progressViewStyle(.circular)
                            .padding(24)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
                    .ignoresSafeArea()
                    .transition(.opacity)
                }
            }
            .navigationTitle("Home")
        }
    }

    // MARK: - Helpers

    private func signOut() {
        withAnimation { isSigningOut = true }
        auth.signOut()

        // Observe AuthViewModel state change
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isSigningOut = false }
            if case .signedOut = auth.state {
                router.go(.onboarding)
            }
        }
    }

    private func extractUserInfo() -> [String: Any]? {
        switch auth.state {
        case .signedIn(let userInfo):
            return userInfo
        default:
            return nil
        }
    }
}
