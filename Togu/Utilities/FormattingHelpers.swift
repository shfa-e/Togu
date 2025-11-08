//
//  FormattingHelpers.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

enum FormattingHelpers {
    static func formatXP(_ xp: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: xp)) ?? "\(xp)"
    }
    
    static func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        }
        return "\(number)"
    }
    
    static func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    static func timeAgoShort(from date: Date) -> String {
        let delta = Date().timeIntervalSince(date)
        if delta > 3600 {
            let hours = Int(delta / 3600)
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        }
        let mins = max(Int(delta / 60), 1)
        return "\(mins) minute\(mins > 1 ? "s" : "") ago"
    }
}

