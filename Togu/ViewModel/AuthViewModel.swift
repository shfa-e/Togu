//
//  AuthViewModel.swift
//  Togu
//
//  Created by Whyyy on 05/11/2025.
//

import Foundation
import OLOidc
import Combine
import UIKit
import WebKit
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var state: AuthState = .signedOut
    @Published var message: String = ""
    @Published var airtableUserId: String? = nil

    private var olOidc: OLOidc?

    init() {
        setupOidc()
        checkExistingSession()
    }

    // MARK: - Setup OIDC using OL-Oidc.plist
    private func setupOidc() {
        do {
            // Loads OL-Oidc.plist automatically if configuration is nil
            olOidc = try OLOidc(configuration: nil)
            (UIApplication.shared.delegate as? AppDelegate)?.olOidc = olOidc
        } catch {
            state = .error("Failed to initialize OIDC: \(error.localizedDescription)")
        }
    }

    // MARK: - Restore session if still valid
    private func checkExistingSession() {
        guard let olOidc else { return }

        if let accessToken = olOidc.olAuthState.accessToken, !accessToken.isEmpty {
            olOidc.introspect { [weak self] isValid, _ in
                guard let self else { return }
                if isValid {
                    self.state = .signedIn(userInfo: [:])
                    self.message = "Session restored ✅"
                } else {
                    self.state = .signedOut
                }
            }
        }
    }

    // MARK: - Sign In
    func signIn() {
        guard let olOidc else {
            state = .error("OIDC not configured.")
            return
        }

        state = .signingIn

        guard let presenter = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            state = .error("Unable to find a root view controller for sign-in presentation.")
            return
        }

        olOidc.signIn(presenter: presenter) { [weak self] error in
            guard let self else { return }

            if let error = error {
                self.state = .error("Sign-in failed: \(error.localizedDescription)")
                return
            }

            if let claims = olOidc.olAuthState.idTokenParsed?.claims as? [String: Any] {
                self.state = .signedIn(userInfo: claims)
                self.message = "✅ Signed in successfully!"
            } else {
                self.state = .signedIn(userInfo: [:])
                self.message = "✅ Signed in (no claims returned)."
            }
        }
        
        // After setting `self.state = .signedIn(userInfo: claims)`:
        Task { // NEW
            guard let cfg = AirtableConfig() else { return }        // NEW
            let airtable = AirtableService(config: cfg)             // NEW
            if case .signedIn(let claims) = self.state {            // NEW
                let name = (claims["name"] as? String)
                        ?? (claims["given_name"] as? String)
                        ?? "Unknown"
                let email = (claims["email"] as? String) ?? ""      // NEW
                if !email.isEmpty {
                    let id = try? await airtable.createUserIfMissing(name: name, email: email) // NEW
                    await MainActor.run { self.airtableUserId = id }                            // NEW
                    print("✅ Airtable user id linked: \(self.airtableUserId ?? "nil")")        // NEW
                } else {
                    print("⚠️ Missing email in OneLogin claims — cannot sync Airtable user.")   // NEW
                }
            }
        }
    }

    // MARK: - Fetch User Info
    func showUserInfo() {
        guard let olOidc else { return }

        olOidc.getUserInfo { [weak self] userInfo, error in
            guard let self else { return }

            if let error = error {
                self.message = "❌ Failed to fetch user info: \(error.localizedDescription)"
                return
            }

            guard let userInfo = userInfo as? [String: Any] else {
                self.message = "No user info returned."
                return
            }

            self.state = .signedIn(userInfo: userInfo)
            self.message = userInfo.map { "\($0): \($1)" }.joined(separator: "\n")
        }
    }

    // MARK: - Check Token Validity
    func checkTokenValidity() {
        guard let olOidc else { return }

        olOidc.introspect { [weak self] valid, error in
            guard let self else { return }

            if let error = error {
                self.message = "❌ Token introspection failed: \(error.localizedDescription)"
                return
            }

            self.message = valid ? "✅ Token is valid" : "⚠️ Token is invalid"
        }
    }

    // MARK: - Proper Sign Out (Revoke + Delete + Clear session)
    func signOut() {
        guard let olOidc else { return }

        message = "Signing out..."

        // 1. Revoke tokens on the server
        olOidc.revokeToken(tokenType: .AccessToken) { [weak self] _ in
            olOidc.revokeToken(tokenType: .RefreshToken) { [weak self] _ in
                guard let self else { return }

                // 2. Delete locally saved tokens
                olOidc.deleteTokens()

                // 3. Clear OneLogin web session cookies (WKWebView cache)
                self.clearOneLoginSessionCookies()

                // 4. Perform true OneLogin logout in ASWebAuthenticationSession
                Task { @MainActor in
                    self.performServerLogout()  // 👈 NEW
                    self.state = .signedOut
                    self.message = "✅ Signed out successfully."
                }
            }
        }
    }

    // MARK: - Call OneLogin end-session endpoint to clear SSO cookies
    private func performServerLogout() {
        // Replace with your actual subdomain
        guard let logoutURL = URL(string: "https://testinggg.onelogin.com/oidc/2/logout") else { return }

        let session = ASWebAuthenticationSession(
            url: logoutURL,
            callbackURLScheme: "com.shfa.Togu.oidc", // Must match your redirect URI scheme
            completionHandler: { _, _ in
                print("🔒 OneLogin SSO session cleared via logout endpoint.")
            }
        )

        // Make sure the logout runs in an isolated browser context
        session.prefersEphemeralWebBrowserSession = true
        session.start()
    }

    // MARK: - Clear cached OneLogin cookies from WKWebView
    private func clearOneLoginSessionCookies() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            let oneLoginRecords = records.filter { record in
                record.displayName.contains("onelogin") || record.displayName.contains("oidc")
            }

            WKWebsiteDataStore.default()
                .removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                            for: oneLoginRecords) {
                    print("🧹 OneLogin WKWebView cookies cleared.")
                }
        }
    }

    // MARK: - Lightweight Int tag for animation
    var animationPhase: Int {
        switch state {
        case .signedOut: return 0
        case .signingIn: return 1
        case .signedIn: return 2
        case .error: return 3
        }
    }
    
    // MARK: - Convenience accessors for OneLogin claims
    var userEmail: String? {
        if case .signedIn(let claims) = state {
            return (claims["email"] as? String)
                ?? (claims["upn"] as? String)
                ?? (claims["preferred_username"] as? String)
        }
        return nil
    }

    var userDisplayName: String? {
        if case .signedIn(let claims) = state {
            return (claims["name"] as? String)
                ?? (claims["given_name"] as? String)
                ?? (claims["preferred_username"] as? String)
                ?? userEmail
        }
        return nil
    }                                                  
    
    
}
