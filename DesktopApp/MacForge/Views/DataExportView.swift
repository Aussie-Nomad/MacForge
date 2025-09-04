//
//  DataExportView.swift
//  MacForge
//
//  GDPR Article 20 - Right to Data Portability
//  Allows users to export all their data in a machine-readable format.
//

import SwiftUI
import Foundation

struct DataExportView: View {
    @ObservedObject var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var exportStatus = "Ready to export"
    @State private var exportError: String? = nil
    @State private var exportURL: URL? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .imageAccessibility(label: "Data Export icon", hint: "Export your data")
                    
                    Text("Export Your Data")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .accessibilityLabel("Export Your Data")
                    
                    Text("Download a complete copy of all your MacForge data in machine-readable format.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Download a complete copy of all your MacForge data in machine-readable format")
                }
                .padding(.top)
                
                // Export Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("What will be exported:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ExportDataRow(
                            title: "MDM Account Information",
                            description: "Server URLs, account names, and preferences",
                            isIncluded: !userSettings.mdmAccounts.isEmpty
                        )
                        
                        ExportDataRow(
                            title: "Profile Configurations",
                            description: "PPPC settings, payload configurations, and templates",
                            isIncluded: true
                        )
                        
                        ExportDataRow(
                            title: "Application Preferences",
                            description: "Theme settings, default values, and UI preferences",
                            isIncluded: true
                        )
                        
                        ExportDataRow(
                            title: "Export Metadata",
                            description: "Export date, version, and data structure information",
                            isIncluded: true
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.05))
                    )
                }
                
                // Progress Section
                if isExporting {
                    VStack(spacing: 12) {
                        ProgressView(value: exportProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .accessibilityLabel("Export progress: \(Int(exportProgress * 100)) percent complete")
                        
                        Text(exportStatus)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Export status: \(exportStatus)")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                
                // Status Messages
                if let error = exportError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                        .accessibilityLabel("Export error: \(error)")
                }
                
                if let url = exportURL {
                    VStack(spacing: 8) {
                        Text("Export completed successfully!")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                        
                        Text("File saved to: \(url.lastPathComponent)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                    )
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .buttonAccessibility(
                        label: "Cancel",
                        hint: "Close the data export dialog"
                    )
                    
                    Button(action: exportData) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(isExporting ? "Exporting..." : "Export Data")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isExporting)
                    .buttonAccessibility(
                        label: isExporting ? "Exporting Data" : "Export Data",
                        hint: isExporting ? "Please wait while your data is being exported" : "Start the data export process",
                        isEnabled: !isExporting
                    )
                }
            }
            .padding()
            .navigationTitle("Data Export")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonAccessibility(label: "Close", hint: "Close the data export view")
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        exportProgress = 0.0
        exportStatus = "Preparing export..."
        exportError = nil
        exportURL = nil
        
        Task {
            do {
                // Step 1: Prepare data structure
                await MainActor.run {
                    exportProgress = 0.2
                    exportStatus = "Collecting account information..."
                }
                
                let mdmAccounts = try await collectMDMAccounts()
                
                await MainActor.run {
                    exportProgress = 0.4
                    exportStatus = "Collecting profile configurations..."
                }
                
                let profileDefaults = userSettings.profileDefaults
                
                await MainActor.run {
                    exportProgress = 0.6
                    exportStatus = "Collecting application preferences..."
                }
                
                let appPreferences = collectAppPreferences()
                
                await MainActor.run {
                    exportProgress = 0.8
                    exportStatus = "Generating export file..."
                }
                
                // Step 2: Create export data structure
                let exportData = UserDataExport(
                    exportDate: Date(),
                    exportVersion: "2.0.0",
                    mdmAccounts: mdmAccounts,
                    aiAccounts: userSettings.aiAccounts,
                    profileDefaults: profileDefaults,
                    appPreferences: appPreferences,
                    metadata: ExportMetadata(
                        totalAccounts: mdmAccounts.count,
                        totalProfiles: 1, // ProfileDefaults is a single object
                        exportFormat: "JSON",
                        dataStructure: "v2.0"
                    )
                )
                
                // Step 3: Generate JSON file
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                
                let jsonData = try encoder.encode(exportData)
                
                await MainActor.run {
                    exportProgress = 0.9
                    exportStatus = "Saving export file..."
                }
                
                // Step 4: Save to file
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = "MacForge_Data_Export_\(DateFormatter.fileNameFormatter.string(from: Date())).json"
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                try jsonData.write(to: fileURL)
                
                await MainActor.run {
                    exportProgress = 1.0
                    exportStatus = "Export completed!"
                    exportURL = fileURL
                    isExporting = false
                }
                
                // Open file in Finder
                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                
            } catch {
                await MainActor.run {
                    exportError = "Export failed: \(error.localizedDescription)"
                    isExporting = false
                }
            }
        }
    }
    
    private func collectMDMAccounts() async throws -> [MDMAccount] {
        // In a real implementation, this would collect from Keychain
        // For now, return the accounts from UserSettings
        return userSettings.mdmAccounts
    }
    
    private func collectAppPreferences() -> [String: String] {
        return [
            "isLCARSActive": String(userSettings.themePreferences.isLCARSActive),
            "panelOpacity": String(userSettings.themePreferences.panelOpacity),
            "animationSpeed": userSettings.themePreferences.animationSpeed.rawValue,
            "accentColor": userSettings.themePreferences.accentColor.rawValue,
            "defaultIdentifierPrefix": userSettings.profileDefaults.defaultIdentifierPrefix,
            "defaultProfileName": userSettings.profileDefaults.defaultProfileName,
            "defaultExportLocation": userSettings.profileDefaults.defaultExportLocation,
            "autoSaveInterval": String(userSettings.profileDefaults.autoSaveInterval),
            "includeMetadata": String(userSettings.profileDefaults.includeMetadata),
            "exportFormat": "JSON"
        ]
    }
}

// MARK: - Export Data Row
struct ExportDataRow: View {
    let title: String
    let description: String
    let isIncluded: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isIncluded ? "checkmark.circle.fill" : "minus.circle.fill")
                .foregroundColor(isIncluded ? .green : .gray)
                .imageAccessibility(
                    label: isIncluded ? "Data will be exported" : "No data to export",
                    hint: "Indicates whether this type of data will be included in the export"
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description). \(isIncluded ? "Data will be exported" : "No data to export")")
    }
}

// MARK: - Supporting Extensions
extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

#Preview {
    DataExportView(userSettings: UserSettings())
}
