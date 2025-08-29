//
//  CommonUI.swift
//  MacForge
//
//  Common reusable UI components and utilities.
//  Provides shared UI elements used across multiple views in the application.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Sidebar Brand Header
struct SidebarBrandHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "hammer.circle.fill")
                    .font(.title2)
                    .foregroundStyle(LcarsTheme.amber)
                Text("MACFORGE")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(LcarsTheme.amber)
            }
            
            Text("PPPC Profile Creator")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Disabled Tile Component
struct LcarsDisabledTile: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.7))
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(LcarsTheme.panel.opacity(0.3)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Themed Field Component
struct ThemedField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var secure: Bool = false
    var monospaced: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.heavy)
                .foregroundStyle(LcarsTheme.amber.opacity(0.9))
            
            if secure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(monospaced ? .system(.body, design: .monospaced) : .body)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(monospaced ? .system(.body, design: .monospaced) : .body)
            }
        }
    }
}
