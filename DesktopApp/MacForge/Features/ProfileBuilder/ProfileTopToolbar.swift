//
//  ProfileTopToolbar.swift
//  MacForge
//
//  Top toolbar component for the PPPC profile creator interface.
//  Provides quick access to common actions and profile management tools.

import SwiftUI
import UniformTypeIdentifiers

struct ProfileTopToolbar: View {
    var onHome: () -> Void
    var onExport: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("Home") { onHome() }
                .buttonStyle(.bordered)
                .contentShape(Rectangle())

            Spacer()

            Button("Download .mobileconfig") { 
                onExport()
            }
            .buttonStyle(.bordered)
            .contentShape(Rectangle())
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}


