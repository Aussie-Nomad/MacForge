//
//  MacForge
//
//  Simplified LCARS theme for MacForge application.
//  Essential colors and styling without over-engineering.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - LCARS Theme Colors
struct LCARSTheme {
    // Core Colors - Improved contrast ratios
    static let background = Color(red: 0.03, green: 0.03, blue: 0.08)      // Darker for better contrast
    static let surface = Color(red: 0.08, green: 0.08, blue: 0.12)         // Better contrast with background
    static let panel = Color(red: 0.12, green: 0.12, blue: 0.18)           // Improved panel contrast
    
    // Accent Colors - Enhanced visibility
    static let primary = Color(red: 0.85, green: 0.45, blue: 0.0)          // Brighter orange
    static let secondary = Color(red: 0.65, green: 0.35, blue: 0.85)       // Enhanced purple
    static let accent = Color(red: 1.0, green: 0.6, blue: 0.0)             // Brighter amber
    
    // Text Colors - Improved readability
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.85, green: 0.85, blue: 0.9)    // Better contrast
    static let textMuted = Color(red: 0.7, green: 0.7, blue: 0.75)         // Improved muted text
    
    // Status Colors - Enhanced visibility
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)            // Bright green
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.0)            // Bright yellow
    static let error = Color(red: 1.0, green: 0.4, blue: 0.4)              // Bright red
    static let info = Color(red: 0.4, green: 0.7, blue: 1.0)               // Bright blue
    
    // Legacy Support - now using LCARS theme values
    static let bg = background
    static let amber = accent
    static let orange = primary
    
    // MARK: - Layout Constants
    struct Sidebar {
        static let width: CGFloat = 280
        static let minWidth: CGFloat = 200
        static let maxWidth: CGFloat = 400
        
        // Spacing and padding
        static let sectionGap: CGFloat = 16
        static let outerPadding: CGFloat = 16
        
        // Tile styling
        static let tileCorner: CGFloat = 12
        static let tileStroke: CGFloat = 2
    }
    
    // MARK: - Accessibility
    static let highContrastMode = false // Can be toggled for accessibility
    
    // High contrast color variants
    static var highContrastBackground: Color {
        return highContrastMode ? Color(red: 0.0, green: 0.0, blue: 0.0) : background
    }
    
    static var highContrastSurface: Color {
        return highContrastMode ? Color(red: 0.1, green: 0.1, blue: 0.15) : surface
    }
    
    static var highContrastPanel: Color {
        return highContrastMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : panel
    }
}

// MARK: - Legacy Support (for existing code)
typealias LcarsTheme = LCARSTheme
typealias DefaultTheme = LCARSTheme

// MARK: - Essential UI Components
extension View {
    func lcarsPanel(tint: Color = LCARSTheme.primary) -> some View {
        modifier(LcarsPanel(tint: tint))
    }
}

// MARK: - Panel Modifier
struct LcarsPanel: ViewModifier {
    var tint: Color = LCARSTheme.primary
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16).fill(LCARSTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(tint, lineWidth: 2))
    }
}

// MARK: - Pill Modifier
struct LcarsPillModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LCARSTheme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(LCARSTheme.accent, lineWidth: 2)
            )
    }
}

extension Text {
    func lcarsPill() -> some View {
        self.modifier(LcarsPillModifier())
    }
}

// MARK: - Header Component
struct LcarsHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 20, weight: .black, design: .rounded)).kerning(1.2)
            .foregroundStyle(LCARSTheme.accent)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 18).fill(LCARSTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(LCARSTheme.primary, lineWidth: 2))
            .padding(.bottom, 6)
    }
}

// MARK: - Button Style
struct LcarsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded)).fontWeight(.semibold)
            .padding(.vertical, 10).padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(LCARSTheme.accent.opacity(configuration.isPressed ? 0.85 : 1)))
            .foregroundStyle(.black)
            .lineLimit(1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Constants
let kAppMarkAsset = "MACFORGE"

// MARK: - App Mark Component
@ViewBuilder
func JamforgeMark(_ size: CGFloat) -> some View {
    Image(kAppMarkAsset)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: size, height: size)
        .foregroundStyle(LCARSTheme.accent)
}
