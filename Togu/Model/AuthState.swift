//
//  AuthState.swift
//  Togu
//
//  Created by Whyyy on 05/11/2025.
//


import Foundation

enum AuthState: Equatable {
    case signedOut
    case signingIn
    case signedIn(userInfo: [String: Any])
    case error(String)

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.signedOut, .signedOut),
             (.signingIn, .signingIn):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        case (.signedIn, .signedIn):
            return true  // we don't compare userInfo contents
        default:
            return false
        }
    }
}
