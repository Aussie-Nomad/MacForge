//
//  ProfileBuilderComponents.swift
//  MacForge
//
//  UI Components for the PPPC Profile Creator Wizard
//

import SwiftUI

// MARK: - Platform Badge
struct PlatformBadge: View {
    let platform: String
    let color: Color
    
    var body: some View {
        Text(platform)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? LCARSTheme.accent : LCARSTheme.panel)
                )
                .foregroundStyle(isSelected ? .black : LCARSTheme.textPrimary)
        }
        .buttonStyle(.plain)
    }
}
