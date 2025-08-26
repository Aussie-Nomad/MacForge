//
//  SettingsHeader.swift
//  MacForge
//
//  Reusable settings header component for configuration screens.
//  Provides consistent styling and layout for settings and preferences sections.

import SwiftUI

struct SettingsHeader: View {
    @Binding var settings: ProfileSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROFILE SETTINGS")
                .font(.headline)
                .foregroundStyle(LcarsTheme.amber)
            
            VStack(spacing: 8) {
                TextField("Profile Name", text: $settings.name)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Description", text: $settings.description)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Identifier", text: $settings.identifier)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Organization", text: $settings.organization)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}
