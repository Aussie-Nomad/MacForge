//
//  LCARSTheme.swift
//  MacForge
//
//  LCARS (Library Computer Access/Retrieval System) theme inspired by Star Trek.
//  Provides an alternative UI theme that's more futuristic and interactive.
//

import SwiftUI

// MARK: - LCARS Color Palette
struct LCARSTheme {
    // Primary Colors
    static let primary = Color(red: 0.8, green: 0.4, blue: 0.0)      // Orange
    static let secondary = Color(red: 0.6, green: 0.2, blue: 0.8)    // Purple
    static let tertiary = Color(red: 0.2, green: 0.6, blue: 0.8)     // Blue
    static let accent = Color(red: 0.8, green: 0.8, blue: 0.2)       // Yellow
    
    // Background Colors
    static let background = Color(red: 0.05, green: 0.05, blue: 0.1) // Dark Blue-Black
    static let surface = Color(red: 0.1, green: 0.1, blue: 0.15)     // Slightly Lighter
    static let panel = Color(red: 0.15, green: 0.15, blue: 0.2)      // Panel Background
    
    // Status Colors
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)      // Green
    static let warning = Color(red: 0.8, green: 0.6, blue: 0.2)      // Amber
    static let error = Color(red: 0.8, green: 0.2, blue: 0.2)        // Red
    static let info = Color(red: 0.2, green: 0.6, blue: 0.8)         // Info Blue
    
    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.8, green: 0.8, blue: 0.8)
    static let textMuted = Color(red: 0.6, green: 0.6, blue: 0.6)
}

// MARK: - LCARS Button Styles
struct LCARSButtonStyle: ButtonStyle {
    let variant: LCARSButtonVariant
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(variant.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(variant.borderColor, lineWidth: 2)
                    )
            )
            .foregroundColor(variant.textColor)
            .font(.system(.body, design: .monospaced))
            .fontWeight(.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

enum LCARSButtonVariant {
    case primary, secondary, tertiary, accent, success, warning, error
    
    var backgroundColor: Color {
        switch self {
        case .primary: return LCARSTheme.primary
        case .secondary: return LCARSTheme.secondary
        case .tertiary: return LCARSTheme.tertiary
        case .accent: return LCARSTheme.accent
        case .success: return LCARSTheme.success
        case .warning: return LCARSTheme.warning
        case .error: return LCARSTheme.error
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary: return LCARSTheme.primary.opacity(0.8)
        case .secondary: return LCARSTheme.secondary.opacity(0.8)
        case .tertiary: return LCARSTheme.tertiary.opacity(0.8)
        case .accent: return LCARSTheme.accent.opacity(0.8)
        case .success: return LCARSTheme.success.opacity(0.8)
        case .warning: return LCARSTheme.warning.opacity(0.8)
        case .error: return LCARSTheme.error.opacity(0.8)
        }
    }
    
    var textColor: Color {
        switch self {
        case .accent: return LCARSTheme.background
        default: return LCARSTheme.textPrimary
        }
    }
}

// MARK: - LCARS Panel Styles
struct LCARSPanel: ViewModifier {
    let variant: LCARSPanelVariant
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(variant.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(variant.borderColor, lineWidth: 1)
                    )
            )
    }
}

enum LCARSPanelVariant {
    case primary, secondary, surface, info
    
    var backgroundColor: Color {
        switch self {
        case .primary: return LCARSTheme.panel
        case .secondary: return LCARSTheme.surface
        case .surface: return LCARSTheme.background
        case .info: return LCARSTheme.info.opacity(0.1)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary: return LCARSTheme.primary.opacity(0.3)
        case .secondary: return LCARSTheme.secondary.opacity(0.3)
        case .surface: return LCARSTheme.tertiary.opacity(0.2)
        case .info: return LCARSTheme.info.opacity(0.4)
        }
    }
}

// MARK: - LCARS Text Styles
struct LCARSTextStyle: ViewModifier {
    let variant: LCARSTextVariant
    
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .monospaced))
            .foregroundColor(variant.color)
            .fontWeight(variant.weight)
    }
}

enum LCARSTextVariant {
    case heading, subheading, body, caption, status
    
    var color: Color {
        switch self {
        case .heading: return LCARSTheme.textPrimary
        case .subheading: return LCARSTheme.textSecondary
        case .body: return LCARSTheme.textSecondary
        case .caption: return LCARSTheme.textMuted
        case .status: return LCARSTheme.accent
        }
    }
    
    var weight: Font.Weight {
        switch self {
        case .heading: return .bold
        case .subheading: return .semibold
        case .body: return .medium
        case .caption: return .regular
        case .status: return .medium
        }
    }
}

// MARK: - LCARS Interactive Elements
struct LCARSStatusIndicator: View {
    let status: LCARSStatus
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(status.color.opacity(0.5), lineWidth: 1)
                )
            
            Text(text)
                .modifier(LCARSTextStyle(variant: .status))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(status.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

enum LCARSStatus {
    case online, offline, standby, warning, error
    
    var color: Color {
        switch self {
        case .online: return LCARSTheme.success
        case .offline: return LCARSTheme.error
        case .standby: return LCARSTheme.warning
        case .warning: return LCARSTheme.warning
        case .error: return LCARSTheme.error
        }
    }
}

// MARK: - LCARS Extensions
extension View {
    func lcarsButton(_ variant: LCARSButtonVariant = .primary) -> some View {
        self.buttonStyle(LCARSButtonStyle(variant: variant))
    }
    
    func lcarsPanel(_ variant: LCARSPanelVariant = .primary) -> some View {
        self.modifier(LCARSPanel(variant: variant))
    }
    
    func lcarsText(_ variant: LCARSTextVariant = .body) -> some View {
        self.modifier(LCARSTextStyle(variant: variant))
    }
}

// MARK: - LCARS Preview
#Preview {
    VStack(spacing: 20) {
        Text("LCARS Interface")
            .lcarsText(.heading)
            .font(.title)
        
        HStack(spacing: 16) {
            Button("Primary") { }
                .lcarsButton(.primary)
            
            Button("Secondary") { }
                .lcarsButton(.secondary)
            
            Button("Accent") { }
                .lcarsButton(.accent)
        }
        
        VStack(alignment: .leading, spacing: 12) {
            Text("System Status")
                .lcarsText(.subheading)
            
            LCARSStatusIndicator(status: .online, text: "Online")
            LCARSStatusIndicator(status: .standby, text: "Standby")
            LCARSStatusIndicator(status: .warning, text: "Warning")
        }
        .lcarsPanel(.primary)
        
        Text("LCARS Theme Active")
            .lcarsText(.status)
    }
    .padding(20)
    .background(LCARSTheme.background)
}
