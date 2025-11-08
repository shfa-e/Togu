//
//  LevelInfo.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

struct LevelInfo {
    let level: Int
    let currentXP: Int
    let nextLevelXP: Int
    let totalXP: Int
    let xpNeeded: Int
    let progress: Double
    
    static func calculate(from points: Int, xpPerLevel: Int = 100) -> LevelInfo {
        let level = max(1, points / xpPerLevel + 1)
        let currentXP = points % xpPerLevel
        let nextLevelXP = xpPerLevel
        let totalXP = points
        let xpNeeded = nextLevelXP - currentXP
        let progress = Double(currentXP) / Double(nextLevelXP)
        
        return LevelInfo(
            level: level,
            currentXP: currentXP,
            nextLevelXP: nextLevelXP,
            totalXP: totalXP,
            xpNeeded: xpNeeded,
            progress: progress
        )
    }
}

