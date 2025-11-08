//
//  Theme.swift
//  Togu
//
//  Created by HY on 05/11/2025.
//
import SwiftUI

// MARK: - Togu Design System (with backward-compatible aliases)

enum ToguFont {
    static func title(size: CGFloat) -> Font { Font.custom("PlusJakartaSans-Bold", size: size) }
    static func regular(size: CGFloat) -> Font { Font.custom("PlusJakartaSans-Regular", size: size) }
    static func medium(size: CGFloat) -> Font { Font.custom("PlusJakartaSans-Medium", size: size) }
}

extension Color {
    // MARK: Core Brand Colors (new canonical names)
    static let toguPrimary = Color(hex: "#6155F5")     // Main Purple
    static let toguBackground = Color(hex: "#FFFFFF")  // Background (white)
    static let toguTextPrimary = Color(hex: "#000000") // Main text (black)
    static let toguTextSecondary = Color(hex: "#4B5563").opacity(0.85) // gray-ish
    static let toguCard = Color(hex: "#F9F9FB")         // light gray for cards
    static let toguBorder = Color(hex: "#E5E5EE")

    // MARK: States
    static let toguPressed = Color(hex: "#4C44C7")      // darker violet
    static let toguHover = Color(hex: "#7368FF")        // lighter violet
    static let toguDisabled = Color(hex: "#C9C8F0")     // desaturated
    static let toguSuccess = Color(hex: "#22C55E")      // green for positive
    static let toguError = Color(hex: "#EF4444")        // red for alerts
    static let toguWarning = Color(hex: "#FACC15")      // yellow for caution

    // MARK: Utilities
    static let toguShadow = Color.black.opacity(0.08)
    
    // MARK: Backward-compatible aliases
    // If older views refer to these names, they will still compile.
    static let warmOrange: Color = toguPrimary /* alias - maps old 'warmOrange' to brand purple */
    static let deepSpace: Color = Color(hex: "#0B0B0D") /* dark background alias (approx) */
    static let mutedTeal: Color = Color(hex: "#4ecdc4") /* original teal used in mocks */
    static let softCoral: Color = Color(hex: "#ff8a80")
    static let glassCard: Color = Color.white.opacity(0.04)
    static let lightGray: Color = Color(hex: "#e9ecef")
    static let softWhite: Color = Color(hex: "#f8f9fa")
    static let codeBlue: Color = Color(hex: "#2d3748")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
