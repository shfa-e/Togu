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
        case restoring
        case onboarding
        case signingIn
        case home
    }
    @Published var route: Route = .restoring

    func go(_ route: Route) {
        withAnimation(.easeInOut) { self.route = route }
    }
}

struct RootRouter: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var feed: FeedViewModel

    var body: some View {
        ZStack {
            switch router.route {
            case .restoring:
                // Neutral splash so the login view never flashes during restore
                ProgressView().transition(.opacity)
            case .onboarding:
                LoginView().transition(.opacity.combined(with: .scale))
            case .signingIn:
                ProgressView("Signing in…")
                    .font(.headline)
                    .transition(.opacity)
            case .home:
                MainTabView()
                    .environmentObject(auth)
                    .environmentObject(feed)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        // Start in a splash state and keep the route in sync with auth.state
        .task { syncRouteWithAuth() }                       // runs on first appearance
        .onChange(of: auth.state) { _ in syncRouteWithAuth() }   // reacts to all auth changes
    }

    private func syncRouteWithAuth() {
        switch auth.state {
        case .restoring:
            router.go(.restoring)
        case .signedOut, .error:
            router.go(.onboarding)
        case .signingIn:
            router.go(.signingIn)
        case .signedIn:
            router.go(.home)
        }
    }
}
