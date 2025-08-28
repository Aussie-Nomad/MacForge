//
//  ThemeSwitcher.swift
//  MacForge
//
//  Theme switching component for MacForge application.
//  Provides a simple interface to switch between available themes.
//

import SwiftUI

struct ThemeSwitcher: View {
    @State private var showingThemeOptions = false
    @State private var isLCARSActive = true
    
    var body: some View {
        VStack(spacing: 12) {
            Text("THEME SELECTION")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
                .textCase(.uppercase)
                .kerning(1.2)
            
            Button(action: {
                showingThemeOptions.toggle()
            }) {
                HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundStyle(.orange)
                    
                    Text("Switch Theme")
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.orange, lineWidth: 2)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if showingThemeOptions {
                VStack(spacing: 8) {
                    ThemeOptionButton(
                        title: "LCARS Theme",
                        description: "Star Trek inspired interface",
                        isActive: isLCARSActive,
                        action: {
                            isLCARSActive = true
                            showingThemeOptions = false
                        }
                    )
                    
                    ThemeOptionButton(
                        title: "System Theme",
                        description: "Follows macOS appearance",
                        isActive: !isLCARSActive,
                        action: {
                            isLCARSActive = false
                            showingThemeOptions = false
                        }
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.orange, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: showingThemeOptions)
    }
}

// MARK: - Theme Option Button
struct ThemeOptionButton: View {
    let title: String
    let description: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isActive ? .orange : .white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? Color.gray.opacity(0.8) : Color.gray.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isActive ? .orange : .gray, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ThemeSwitcher()
        .padding()
        .background(Color.black)
}
