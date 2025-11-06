//
//  ToguApp.swift
//  Togu
//
//  Created by Whyyy on 05/11/2025.
//

import SwiftUI

@main
struct ToguApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var router = Router()
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootRouter()
                .environmentObject(router)
                .environmentObject(auth)
        }
    }
}
