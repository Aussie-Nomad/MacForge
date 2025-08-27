//
//  ThemeSwitcher.swift
//  MacForge
//
//  Theme switching component for the LCARS interface.
//

import SwiftUI

struct ThemeSwitcher: View {
    @Environment(\.themeManager) var themeManager
    @State private var showingThemePicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Theme Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LCARS Theme")
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    Text("Star Trek-Inspired futuristic interface")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingThemePicker.toggle()
                    }
                }) {
                    Image(systemName: "paintbrush")
                        .font(.title3)
                        .foregroundStyle(LCARSTheme.accent)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LCARSTheme.panel)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LCARSTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(LCARSTheme.primary.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Theme Info
            if showingThemePicker {
                VStack(spacing: 8) {
                    Text("LCARS Theme Active")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    Text("The LCARS (Library Computer Access/Retrieval System) theme provides a futuristic, Star Trek-inspired interface with optimized colors and typography for professional MDM management.")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LCARSTheme.panel.opacity(0.5))
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ThemeSwitcher()
            .padding()
            .background(LCARSTheme.background)
    }
    .environment(\.themeManager, ThemeManager())
}
