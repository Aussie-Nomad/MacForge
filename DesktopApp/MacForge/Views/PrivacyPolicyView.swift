//
//  PrivacyPolicyView.swift
//  MacForge
//
//  Privacy policy and GDPR compliance interface.
//  Provides user consent management and data export/deletion.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @StateObject private var userSettings = UserSettings()
    @State private var showingDataExport = false
    @State private var showingDataDeletion = false
    @State private var hasAcceptedPrivacyPolicy = false
    @State private var dataExportContent: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy & Data Protection")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Your privacy and data protection rights")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Privacy Policy Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy Policy")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("MacForge is committed to protecting your privacy and personal data. This policy explains how we collect, use, and protect your information.")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PrivacyPolicyItem(
                                title: "Data Collection",
                                description: "We collect only the minimum data necessary to provide our services: profile configurations, theme preferences, and MDM connection details."
                            )
                            
                            PrivacyPolicyItem(
                                title: "Data Storage",
                                description: "All sensitive data (passwords, tokens, credentials) is stored securely in macOS Keychain. Non-sensitive preferences are stored locally."
                            )
                            
                            PrivacyPolicyItem(
                                title: "Data Usage",
                                description: "Your data is used solely to provide MacForge functionality. We do not share, sell, or transmit your data to third parties."
                            )
                            
                            PrivacyPolicyItem(
                                title: "Data Retention",
                                description: "Data is retained only as long as necessary. You can delete all data at any time using the controls below."
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.controlBackgroundColor))
                    )
                    
                    // GDPR Rights Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Rights (GDPR)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Under the General Data Protection Regulation, you have the following rights:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            GDPRRightItem(
                                title: "Right to Access",
                                description: "You can request a copy of all personal data we hold about you.",
                                action: "Export Data",
                                actionColor: .blue
                            ) {
                                exportUserData()
                            }
                            
                            GDPRRightItem(
                                title: "Right to Rectification",
                                description: "You can correct or update your personal data at any time.",
                                action: "Update Settings",
                                actionColor: .orange
                            ) {
                                // Navigate to settings
                            }
                            
                            GDPRRightItem(
                                title: "Right to Erasure",
                                description: "You can request deletion of all your personal data.",
                                action: "Delete All Data",
                                actionColor: .red
                            ) {
                                showingDataDeletion = true
                            }
                            
                            GDPRRightItem(
                                title: "Right to Data Portability",
                                description: "You can export your data in a machine-readable format.",
                                action: "Export Data",
                                actionColor: .green
                            ) {
                                exportUserData()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.controlBackgroundColor))
                    )
                    
                    // Consent Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Consent")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("By using MacForge, you consent to the collection and processing of your data as described in this privacy policy.")
                            .font(.body)
                        
                        HStack {
                            Button(action: {
                                hasAcceptedPrivacyPolicy.toggle()
                            }) {
                                HStack {
                                    Image(systemName: hasAcceptedPrivacyPolicy ? "checkmark.square.fill" : "square")
                                        .foregroundColor(hasAcceptedPrivacyPolicy ? .blue : .gray)
                                    Text("I accept the privacy policy")
                                        .font(.body)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.controlBackgroundColor))
                    )
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("If you have any questions about this privacy policy or your data rights, please contact us:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ContactItem(
                                icon: "globe",
                                title: "GitHub Issues",
                                description: "Report privacy concerns or data requests"
                            )
                            
                            ContactItem(
                                icon: "envelope",
                                title: "Email",
                                description: "Privacy questions and data requests"
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.controlBackgroundColor))
                    )
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        // Close view
                    }
                }
            }
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView(content: dataExportContent)
        }
        .alert("Delete All Data", isPresented: $showingDataDeletion) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All Data", role: .destructive) {
                deleteAllUserData()
            }
        } message: {
            Text("This will permanently delete all your data including MDM accounts, preferences, and profiles. This action cannot be undone.")
        }
    }
    
    private func exportUserData() {
        let export = userSettings.exportUserData()
        dataExportContent = export.formattedJSON ?? "Error exporting data"
        showingDataExport = true
    }
    
    private func deleteAllUserData() {
        userSettings.deleteAllUserData()
    }
}

// MARK: - Supporting Views

struct PrivacyPolicyItem: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct GDPRRightItem: View {
    let title: String
    let description: String
    let action: String
    let actionColor: Color
    let actionHandler: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: actionHandler) {
                Text(action)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(actionColor)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

struct ContactItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct DataExportView: View {
    let content: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Your Data Export")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.controlBackgroundColor))
                )
                .padding()
                
                HStack {
                    Button("Copy to Clipboard") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(content, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save to File") {
                        saveToFile()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Data Export")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func saveToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "macforge_data_export_\(Date().timeIntervalSince1970).json"
        
        if panel.runModal() == .OK, let url = panel.url {
            try? content.data(using: .utf8)?.write(to: url)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
