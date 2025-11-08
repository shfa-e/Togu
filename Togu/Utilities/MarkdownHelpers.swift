//
//  MarkdownHelpers.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation

enum MarkdownHelpers {
    /// Extracts code snippet from markdown code blocks (```code```)
    static func extractCodeSnippet(from text: String) -> String? {
        let pattern = #"```[\s\S]*?```"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }
        
        let codeBlock = String(text[range])
        return codeBlock
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Removes code blocks from text for display
    static func removeCodeBlocks(from text: String) -> String {
        let pattern = #"```[\s\S]*?```"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        
        let cleaned = regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text),
            withTemplate: ""
        )
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

