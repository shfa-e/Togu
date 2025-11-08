//
//  LoginViewModel.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var isAnimating = false
    @Published var meshAnimation = false
    
    private var auth: AuthViewModel
    
    init(auth: AuthViewModel) {
        self.auth = auth
    }
    
    func updateAuth(_ auth: AuthViewModel) {
        self.auth = auth
    }
    
    var authIsBusy: Bool {
        if case .signingIn = auth.state { return true }
        return false
    }
    
    var hasError: Bool {
        if case .error = auth.state { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = auth.state {
            return message
        }
        return nil
    }
    
    func signIn() {
        auth.signIn()
    }
    
    func startAnimations() {
        isAnimating = true
        meshAnimation = true
    }
}

