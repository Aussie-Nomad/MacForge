//
//  ProfileTopToolbar.swift
//  MacForge
//
//  Top toolbar component for the profile builder interface.
//  Provides quick access to common actions and profile management tools.

import SwiftUI

struct ProfileTopToolbar: View {
    var onHome: () -> Void
    var onExport: () -> Void
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("Back") { onHome() }
                .buttonStyle(.bordered)
                .contentShape(Rectangle())

            Spacer()

            Button("Download .mobileconfig") { onExport() }
                .buttonStyle(.bordered)
                .contentShape(Rectangle())

            Button("Submit to MDM") { onSubmit() }
                .buttonStyle(.borderedProminent)
                .contentShape(Rectangle())
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
