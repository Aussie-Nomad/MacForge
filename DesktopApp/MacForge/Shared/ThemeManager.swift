//
//  ThemeManager.swift
//  MacForge
//
//  Manages theme switching and provides theme-aware colors and constants.
//

import SwiftUI

// MARK: - Theme Types
enum ThemeType: String, CaseIterable {
    case lcars = "LCARS"
    
    var displayName: String {
        switch self {
        case .lcars:
            return "Star Trek-Inspired futuristic interface"
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: ThemeType = .lcars
    
    // MARK: - Theme-Aware Colors
    var backgroundColor: Color {
        switch currentTheme {
        case .lcars:
            return LCARSTheme.background
        }
    }
    
    var surfaceColor: Color {
        switch currentTheme {
        case .lcars:
            return LCARSTheme.surface
        }
    }
    
    var primaryColor: Color {
        switch currentTheme {
        case .lcars:
            return LCARSTheme.primary
        }
    }
    
    var secondaryColor: Color {
        switch currentTheme {
        case .lcars:
            return LCARSTheme.secondary
        }
    }
    
    var accentColor: Color {
        switch currentTheme {
        case .lcars:
            return LCARSTheme.accent
        }
    }
    
    var panelColor: Color {
        switch currentTheme {
        case .lcars:
            return LCARSTheme.panel
        }
    }
}

// MARK: - Environment Key
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeManager = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    func themeAwareBackground() -> some View {
        self.background(ThemeManager().backgroundColor)
    }
}
