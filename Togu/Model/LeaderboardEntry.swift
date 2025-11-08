//
//  LeaderboardEntry.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

struct LeaderboardEntry: Identifiable, Hashable {
    let id: String
    let name: String
    let xp: Int
    let level: Int
    let rank: Int
    let profilePictureURL: URL?
    let achievements: [Achievement]
    
    enum Achievement: String, Hashable {
        case goldTrophy = "goldTrophy"
        case silverMedal = "silverMedal"
        case purpleStar = "purpleStar"
    }
    
    // Calculate level from XP (100 points per level)
    static func calculateLevel(from xp: Int) -> Int {
        max(1, xp / 100 + 1)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LeaderboardEntry, rhs: LeaderboardEntry) -> Bool {
        lhs.id == rhs.id
    }
}

