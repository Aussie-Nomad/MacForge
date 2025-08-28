//
//  ProfileTopToolbar.swift
//  MacForge
//
//  Top toolbar component for the profile builder interface.
//  Provides quick access to common actions and profile management tools.

import SwiftUI
import UniformTypeIdentifiers

struct ProfileTopToolbar: View {
    var onHome: () -> Void
    var onExport: () -> Void
    @State private var showingExportPanel = false

    var body: some View {
        HStack(spacing: 12) {
            Button("Home") { onHome() }
                .buttonStyle(.bordered)
                .contentShape(Rectangle())

            Spacer()

            Button("Download .mobileconfig") { 
                showingExportPanel = true
            }
            .buttonStyle(.bordered)
            .contentShape(Rectangle())
            .fileExporter(
                isPresented: $showingExportPanel,
                document: ProfileDocument(content: "Profile content will be generated here"),
                contentType: UTType(filenameExtension: "mobileconfig") ?? .data,
                defaultFilename: "profile.mobileconfig"
            ) { result in
                switch result {
                case .success(_):
                    // Trigger the actual export when user chooses location
                    onExport()
                case .failure(let error):
                    print("Export failed: \(error.localizedDescription)")
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}


