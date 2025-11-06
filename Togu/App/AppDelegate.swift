//
//  AppDelegate.swift
//  Togu
//
//  Created by Whyyy on 05/11/2025.
//

import UIKit
import OLOidc

class AppDelegate: UIResponder, UIApplicationDelegate {
    var olOidc: OLOidc?

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Resume OneLogin redirect flow
        return olOidc?.currentAuthorizationFlow?.resumeExternalUserAgentFlow(with: url) ?? false
    }
}
