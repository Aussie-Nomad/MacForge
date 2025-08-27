//
//  SettingsHeader.swift
//  MacForge
//
//  Reusable settings header component for configuration screens.
//  Provides consistent styling and layout for settings and preferences sections.

import SwiftUI

struct SettingsHeader: View {
    @Binding var settings: ProfileSettings
    @State private var showingIdentifierInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROFILE SETTINGS")
                .font(.headline)
                .foregroundStyle(LCARSTheme.accent)
            
            VStack(spacing: 8) {
                TextField("Profile Name", text: $settings.name)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Description", text: $settings.description)
                    .textFieldStyle(.roundedBorder)
                
                HStack(spacing: 8) {
                    TextField("Identifier", text: $settings.identifier)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        showingIdentifierInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(LCARSTheme.accent)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Profile Identifier Information")
                }
                
                TextField("Organization", text: $settings.organization)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .popover(isPresented: $showingIdentifierInfo) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Profile Identifier")
                    .font(.headline)
                    .foregroundStyle(LCARSTheme.accent)
                
                Text("The profile identifier is a unique reverse-DNS string that identifies your configuration profile. It should follow the format:")
                    .font(.body)
                
                Text("com.yourcompany.profilename")
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(LCARSTheme.panel)
                    .cornerRadius(6)
                
                Text("• Must be unique across all profiles on the device\n• Cannot contain spaces or special characters\n• Should match your organization's domain structure\n• Used by the system to track profile installations")
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
                
                Spacer()
                
                Button("Copy Current Identifier") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(settings.identifier, forType: .string)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .frame(width: 400, height: 300)
        }
    }
}
