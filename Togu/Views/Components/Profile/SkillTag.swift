//
//  SkillTag.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct SkillTag: View {
    let skill: Skill
    
    var body: some View {
        HStack(spacing: 6) {
            Text(skill.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(skill.isHighlighted ? .toguPrimary : .toguTextPrimary)
            Text("•")
                .foregroundColor(.toguTextSecondary)
            Text("Level \(skill.level)")
                .font(.system(size: 14))
                .foregroundColor(.toguTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
        )
    }
}

