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

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "smiley")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.yellow)

            VStack(spacing: 8) {
                Text("Share. Learn. Build Together.")
                    .font(.title2).bold()
                    .multilineTextAlignment(.center)

                Text("Welcome to Togu, the best place for students to connect & create.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                auth.signIn() // Router will auto-progress via RootRouter onChange
            } label: {
                Text("Sign in with IDServe")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(authIsBusy ? Color.gray : Color.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .padding(.horizontal)
            .disabled(authIsBusy)

            if case .error(let errorMsg) = auth.state {
                Text(errorMsg)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
    }

    private var authIsBusy: Bool {
        if case .signingIn = auth.state { return true }
        return false
    }
}
