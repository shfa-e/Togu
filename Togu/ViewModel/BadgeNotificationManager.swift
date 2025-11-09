//
//  BadgeNotificationManager.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation
import Combine

@MainActor
final class BadgeNotificationManager: ObservableObject {
    @Published var earnedBadgeName: String?
    
    func showBadgeNotification(_ badgeName: String) {
        earnedBadgeName = badgeName
        
        // Auto-dismiss after 4 seconds
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if earnedBadgeName == badgeName {
                earnedBadgeName = nil
            }
        }
    }
    
    func dismiss() {
        earnedBadgeName = nil
    }
}

