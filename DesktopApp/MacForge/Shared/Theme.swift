//
//  Theme.swift
//  MacForge
//
//  LCARS-inspired color theme and design constants for the MacForge application.
//  Provides consistent visual styling across all UI components.


import SwiftUI
#if os(macOS)
import AppKit
#endif

enum LcarsTheme {
    static let bg     = Color(red: 0.03, green: 0.03, blue: 0.03)
    static let amber    = Color(red: 1.0, green: 0.53, blue: 0.0)
    static let orange = Color(red: 0.925, green: 0.48, blue: 0.13)
    static let panel  = Color(red: 0.10, green: 0.10, blue: 0.10)
    
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
        static let titleSize: CGFloat  = 22
    }
    
    enum Welcome {
        static let maxTextWidth: CGFloat = 720
        static let pillCorner: CGFloat = 14
    }
    
    enum Layout {
        // Some call-sites expect LcarsTheme.Layout.designBase
        static let designBase = CGSize(width: 1440, height: 900)
    }
    
    // Optional builder version of "panel" used by some legacy call-sites:
    static func panel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18).fill(LcarsTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(LcarsTheme.orange, lineWidth: 3))
    }
}

struct LcarsPanel: ViewModifier {
    var tint: Color = LcarsTheme.orange
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18).fill(LcarsTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(tint, lineWidth: 3))
    }
}

extension View {
    func lcarsPanel(tint: Color = LcarsTheme.orange) -> some View {
        modifier(LcarsPanel(tint: tint))
    }
}

private struct LcarsPillModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(LcarsTheme.amber, lineWidth: 2)
            )
    }
}

extension View {
    /// Small rounded "pill" stroke used for captions/tags
    func lcarsPill() -> some View { modifier(LcarsPillModifier()) }
}

struct LcarsHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 22, weight: .black, design: .rounded)).kerning(1.2)
            .foregroundStyle(LcarsTheme.amber)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 20).fill(LcarsTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(LcarsTheme.orange, lineWidth: 3))
            .padding(.bottom, 6)
    }
}

struct LcarsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.black))
            .padding(.vertical, 12).padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(LcarsTheme.amber.opacity(configuration.isPressed ? 0.85 : 1)))
            .foregroundStyle(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

let kDesignBase = CGSize(width: 1440, height: 900)
let kAppMarkAsset = "MACFORGE"

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
