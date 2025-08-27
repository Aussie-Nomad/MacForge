//
//  Theme.swift
//  MacForge
//
//  LCARS-inspired color theme and design constants for the MacForge application.
//  Provides consistent visual styling across all UI components.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - LCARS Theme Colors
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
    
    // Legacy Support - now using LCARS theme values
    static let bg = background
    static let amber = accent
    static let orange = primary
    
    enum Sidebar {
        static let width: CGFloat = 240  // Increased from 220
        static let sectionGap: CGFloat = 18  // Increased from 16
        static let outerPadding: CGFloat = 13  // Increased from 12
        static let cardCorner: CGFloat = 20  // Increased from 18
        static let tileCorner: CGFloat = 13  // Increased from 12
        static let tileStroke: CGFloat = 2
    }
    
    enum Header {
        static let ringCorner: CGFloat = 20  // Increased from 18
        static let ringStroke: CGFloat = 2
        static let titleSize: CGFloat = 24  // Increased from 22
    }
    
    enum Welcome {
        static let maxTextWidth: CGFloat = 792  // Increased from 720
        static let pillCorner: CGFloat = 15  // Increased from 14
    }
    
    enum Layout {
        static let designBase = CGSize(width: 1440, height: 900)
    }
}

// MARK: - Legacy Support (for existing code)
typealias LcarsTheme = LCARSTheme
typealias DefaultTheme = LCARSTheme

// MARK: - Theme-Aware Extensions
extension View {
    func lcarsPanel(tint: Color = LCARSTheme.primary) -> some View {
        modifier(LcarsPanel(tint: tint))
    }
    
    func lcarsPill() -> some View { 
        modifier(LcarsPillModifier()) 
    }
}

// MARK: - Panel Modifier
struct LcarsPanel: ViewModifier {
    var tint: Color = LCARSTheme.primary
    func body(content: Content) -> some View {
        content
            .padding(13)  // Increased from 12
            .background(RoundedRectangle(cornerRadius: 20).fill(LCARSTheme.panel))  // Increased from 18
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(tint, lineWidth: 3))  // Increased from 18
    }
}

// MARK: - Pill Modifier
private struct LcarsPillModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 11)  // Increased from 10
            .padding(.vertical, 6)  // Increased from 5
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)  // Increased from 10
                    .fill(LCARSTheme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)  // Increased from 10
                    .stroke(LCARSTheme.accent, lineWidth: 2)
            )
    }
}

// MARK: - Header Component
struct LcarsHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 24, weight: .black, design: .rounded)).kerning(1.3)  // Increased from 22 and 1.2
            .foregroundStyle(LCARSTheme.accent)
            .padding(.vertical, 9)  // Increased from 8
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 22).fill(LCARSTheme.panel))  // Increased from 20
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(LCARSTheme.primary, lineWidth: 3))  // Increased from 20
            .padding(.bottom, 7)  // Increased from 6
    }
}

// MARK: - Button Style
struct LcarsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))  // Increased from default
            .padding(.vertical, 13).padding(.horizontal, 18)  // Increased from 12 and 16
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 18).fill(LCARSTheme.accent.opacity(configuration.isPressed ? 0.85 : 1)))  // Increased from 16
            .foregroundStyle(.black)
            .lineLimit(1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Constants
let kDesignBase = CGSize(width: 1440, height: 900)
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
