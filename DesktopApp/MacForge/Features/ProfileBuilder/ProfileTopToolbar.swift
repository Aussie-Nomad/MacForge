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
                // Direct export - no need for file picker since we're saving to Downloads
                onExport()
            }
            .buttonStyle(.borderedProminent)
            .tint(LCARSTheme.accent)
            .contentShape(Rectangle())
            .help("Download the configuration profile to your Downloads folder")
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Profile Document for Export
struct ProfileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [UTType(filenameExtension: "mobileconfig") ?? .data] }
    
    var content: String
    
    init(content: String) {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        content = ""
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(content.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
