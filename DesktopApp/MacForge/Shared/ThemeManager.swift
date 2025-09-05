//
//  MacForge
//
//  Simplified theme manager that provides LCARS theme colors.
//  No theme switching - just consistent LCARS styling.
//

import SwiftUI

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    // MARK: - Theme State
    @Published var isLCARSActive: Bool = true
    @Published var themePreferences: ThemePreferences = ThemePreferences()
    
    // MARK: - Theme-Aware Colors (self-contained to avoid import issues)
    var backgroundColor: Color { Color(red: 0.05, green: 0.05, blue: 0.1) }
    var surfaceColor: Color { Color(red: 0.12, green: 0.12, blue: 0.18) }
    var primaryColor: Color { Color(red: 0.8, green: 0.4, blue: 0.0) }
    var secondaryColor: Color { Color(red: 0.6, green: 0.3, blue: 0.8) }
    var accentColor: Color { themePreferences.accentColor.color }
    var panelColor: Color { Color(red: 0.15, green: 0.15, blue: 0.22) }
    var textPrimaryColor: Color { .white }
    var textSecondaryColor: Color { Color(red: 0.8, green: 0.8, blue: 0.8) }
    var textMutedColor: Color { Color(red: 0.6, green: 0.6, blue: 0.6) }
    
    func updateThemePreferences(_ preferences: ThemePreferences) {
        themePreferences = preferences
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
