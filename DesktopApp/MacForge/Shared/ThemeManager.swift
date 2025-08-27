//
//  MacForge
//
//  Simplified theme manager that provides LCARS theme colors.
//  No theme switching - just consistent LCARS styling.
//

import SwiftUI

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    // MARK: - Theme-Aware Colors
    var backgroundColor: Color { LCARSTheme.background }
    var surfaceColor: Color { LCARSTheme.surface }
    var primaryColor: Color { LCARSTheme.primary }
    var secondaryColor: Color { LCARSTheme.secondary }
    var accentColor: Color { LCARSTheme.accent }
    var panelColor: Color { LCARSTheme.panel }
    var textPrimaryColor: Color { LCARSTheme.textPrimary }
    var textSecondaryColor: Color { LCARSTheme.textSecondary }
    var textMutedColor: Color { LCARSTheme.textMuted }
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
