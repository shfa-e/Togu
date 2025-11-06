//
//  Router.swift
//  Togu
//
//  Created by Whyyy on 05/11/2025.
//


import SwiftUI
import Combine

final class Router: ObservableObject {
    enum Route: Equatable {
        case onboarding
        case signingIn
        case home
    }

    @Published var route: Route = .onboarding

    func go(_ route: Route) {
        withAnimation(.easeInOut) { self.route = route }
    }
}

struct RootRouter: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        ZStack {
            switch router.route {
            case .onboarding:
                LoginView()
                    .transition(.opacity.combined(with: .scale))
            case .signingIn:
                ProgressView("Signing in…")
                    .font(.headline)
                    .transition(.opacity)
            case .home:
                HomeView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        // Keep router and auth in sync
        .onAppear { syncRouteWithAuth() }
        .onChange(of: auth.state) { _ in syncRouteWithAuth() }
    }

    private func syncRouteWithAuth() {
        switch auth.state {
        case .signedOut, .error:
            router.go(.onboarding)
        case .signingIn:
            router.go(.signingIn)
        case .signedIn:
            router.go(.home)
        }
    }
}
