//
//  ThemeSwitcher.swift
//  MacForge
//
//  Theme switcher component that allows users to toggle between
//  the default theme and LCARS theme.
//

import SwiftUI

struct ThemeSwitcher: View {
    @Environment(\.themeManager) var themeManager
    @State private var showingThemePicker = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Current Theme Display
            HStack(spacing: 12) {
                Image(systemName: themeManager.currentTheme.icon)
                    .font(.title2)
                    .foregroundColor(themeManager.primaryColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(themeManager.currentTheme.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(themeManager.currentTheme.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingThemePicker.toggle()
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showingThemePicker ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: showingThemePicker)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Theme Picker
            if showingThemePicker {
                VStack(spacing: 8) {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeOptionRow(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    themeManager.switchTheme(to: theme)
                                    showingThemePicker = false
                                }
                            }
                        )
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
    }
}

// MARK: - Theme Option Row
struct ThemeOptionRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: theme.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? 
                          (theme == .lcars ? LCARSTheme.primary : LcarsTheme.amber) : 
                          Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.clear : 
                        (theme == .lcars ? LCARSTheme.primary.opacity(0.3) : LcarsTheme.amber.opacity(0.3)),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ThemeSwitcher()
            .padding()
            .background(LcarsTheme.bg)
        
        ThemeSwitcher()
            .padding()
            .background(LCARSTheme.background)
    }
    .environment(\.themeManager, ThemeManager.shared)
}
