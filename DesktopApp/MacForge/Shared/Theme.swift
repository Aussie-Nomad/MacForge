//
//  Theme.swift
//  MacForge
//
//  Consolidated theme system for MacForge application.
//  Provides consistent visual styling across all UI components.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Default Theme Colors
struct DefaultTheme {
    static let bg = Color(red: 0.03, green: 0.03, blue: 0.03)
    static let amber = Color(red: 1.0, green: 0.53, blue: 0.0)
    static let orange = Color(red: 0.925, green: 0.48, blue: 0.13)
    static let panel = Color(red: 0.10, green: 0.10, blue: 0.10)
    
    enum Sidebar {
        static let width: CGFloat = 220
        static let sectionGap: CGFloat = 16
        static let outerPadding: CGFloat = 12
        static let cardCorner: CGFloat = 18
        static let tileCorner: CGFloat = 12
        static let tileStroke: CGFloat = 2
    }
    
    enum Header {
        static let ringCorner: CGFloat = 18
        static let ringStroke: CGFloat = 2
        static let titleSize: CGFloat = 22
    }
    
    enum Welcome {
        static let maxTextWidth: CGFloat = 720
        static let pillCorner: CGFloat = 14
    }
    
    enum Layout {
        static let designBase = CGSize(width: 1440, height: 900)
    }
}

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
}

// MARK: - Legacy Support (for existing code)
typealias LcarsTheme = DefaultTheme

// MARK: - Theme-Aware Extensions
extension View {
    func lcarsPanel(tint: Color = DefaultTheme.orange) -> some View {
        modifier(LcarsPanel(tint: tint))
    }
    
    func lcarsPill() -> some View { 
        modifier(LcarsPillModifier()) 
    }
}

// MARK: - Panel Modifier
struct LcarsPanel: ViewModifier {
    var tint: Color = DefaultTheme.orange
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18).fill(DefaultTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(tint, lineWidth: 3))
    }
}

// MARK: - Pill Modifier
private struct LcarsPillModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(DefaultTheme.amber, lineWidth: 2)
            )
    }
}

// MARK: - Header Component
struct LcarsHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 22, weight: .black, design: .rounded)).kerning(1.2)
            .foregroundStyle(DefaultTheme.amber)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 20).fill(DefaultTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(DefaultTheme.orange, lineWidth: 3))
            .padding(.bottom, 6)
    }
}

// MARK: - Button Style
struct LcarsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.black))
            .padding(.vertical, 12).padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(DefaultTheme.amber.opacity(configuration.isPressed ? 0.85 : 1)))
            .foregroundStyle(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

// MARK: - Constants
let kDesignBase = CGSize(width: 1440, height: 900)
let kAppMarkAsset = "MACFORGE"

// MARK: - App Mark Component
@ViewBuilder
func JamforgeMark(_ size: CGFloat) -> some View {
#if os(macOS)
    if NSImage(named: kAppMarkAsset) != nil {
        Image(kAppMarkAsset).resizable().scaledToFit().frame(width: size, height: size)
    } else {
        Image(systemName: "hammer.circle.fill").resizable().scaledToFit().frame(width: size, height: size).foregroundStyle(.orange)
    }
#else
    if UIImage(named: kAppMarkAsset) != nil {
        Image(kAppMarkAsset).resizable().scaledToFit().frame(width: size, height: size)
    } else {
        Image(systemName: "hammer.circle.fill").resizable().scaledToFit().frame(width: size, height: size).foregroundStyle(.orange)
    }
#endif
}
