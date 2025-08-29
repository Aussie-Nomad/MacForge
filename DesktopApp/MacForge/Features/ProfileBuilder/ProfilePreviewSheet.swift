//
//  ProfilePreviewSheet.swift
//  MacForge
//
//  Profile preview sheet showing the complete configuration profile
//  with XML/plist structure and validation results.
//

import SwiftUI

// MARK: - Profile Preview Sheet
struct ProfilePreviewSheet: View {
    @ObservedObject var model: BuilderModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingXML = false
    @State private var xmlContent = ""
    @State private var validationErrors: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if showingXML {
                    xmlPreviewSection
                } else {
                    profileSummarySection
                }
                
                // Action Buttons
                actionButtonsSection
            }
            .background(LCARSTheme.background)
            .navigationTitle("Profile Preview")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(showingXML ? "Summary" : "XML") {
                        showingXML.toggle()
                        if showingXML {
                            generateXML()
                        }
                    }
                }
            }
        }
        .onAppear {
            validateProfile()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configuration Profile Preview")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    Text("Review your profile before export")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                }
                
                Spacer()
                
                // Profile Status
                HStack(spacing: 8) {
                    Image(systemName: validationErrors.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(validationErrors.isEmpty ? .green : .orange)
                    
                    Text(validationErrors.isEmpty ? "Valid" : "Issues Found")
                        .font(.caption)
                        .foregroundStyle(validationErrors.isEmpty ? .green : .orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((validationErrors.isEmpty ? Color.green : Color.orange).opacity(0.2))
                .cornerRadius(8)
            }
            
            // Profile Info
            HStack(spacing: 20) {
                ProfileInfoItem(
                    label: "Name",
                    value: model.settings.name
                )
                
                ProfileInfoItem(
                    label: "Identifier",
                    value: model.settings.identifier
                )
                
                ProfileInfoItem(
                    label: "Organization",
                    value: model.settings.organization
                )
                
                ProfileInfoItem(
                    label: "Payloads",
                    value: "\(model.dropped.count)"
                )
            }
        }
        .padding(20)
        .background(LCARSTheme.surface)
    }
    
    // MARK: - Profile Summary Section
    private var profileSummarySection: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Validation Results
                if !validationErrors.isEmpty {
                    validationSection
                }
                
                // Payload Summary
                payloadSummarySection
                
                // Export Options
                exportOptionsSection
            }
            .padding(20)
        }
    }
    
    // MARK: - XML Preview Section
    private var xmlPreviewSection: some View {
        VStack(spacing: 0) {
            // XML Header
            HStack {
                Text("XML Structure")
                    .font(.headline)
                    .foregroundStyle(LCARSTheme.textPrimary)
                
                Spacer()
                
                Button("Copy XML") {
                    copyXMLToClipboard()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(16)
            .background(LCARSTheme.panel)
            
            // XML Content
            ScrollView {
                Text(xmlContent)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(LCARSTheme.textPrimary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LCARSTheme.background)
            }
        }
    }
    
    // MARK: - Validation Section
    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                
                Text("Validation Issues")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
            
            ForEach(validationErrors, id: \.self) { error in
                Text("• \(error)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Payload Summary Section
    private var payloadSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configured Payloads")
                .font(.headline)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            LazyVStack(spacing: 12) {
                ForEach(model.dropped) { payload in
                    PayloadSummaryRow(payload: payload)
                }
            }
        }
        .padding(16)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
    }
    
    // MARK: - Export Options Section
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Options")
                .font(.headline)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            VStack(spacing: 12) {
                ExportOptionRow(
                    title: "Download to Downloads Folder",
                    description: "Save as .mobileconfig file",
                    icon: "arrow.down.circle",
                    action: { exportToDownloads() }
                )
                
                ExportOptionRow(
                    title: "Copy to Clipboard",
                    description: "Copy XML content to clipboard",
                    icon: "doc.on.clipboard",
                    action: { copyXMLToClipboard() }
                )
                
                if model.isAuthenticated {
                    ExportOptionRow(
                        title: "Upload to JAMF Pro",
                        description: "Direct deployment to MDM",
                        icon: "network",
                        action: { uploadToJAMF() }
                    )
                }
            }
        }
        .padding(16)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            Button("Export Profile") {
                exportToDownloads()
            }
            .buttonStyle(LcarsButtonStyle())
            .frame(maxWidth: .infinity)
            .disabled(validationErrors.count > 0)
        }
        .padding(20)
        .background(LCARSTheme.surface)
    }
    
    // MARK: - Helper Methods
    private func validateProfile() {
        validationErrors.removeAll()
        
        // Basic validation
        if model.settings.name.isEmpty {
            validationErrors.append("Profile name is required")
        }
        
        if model.settings.identifier.isEmpty {
            validationErrors.append("Profile identifier is required")
        }
        
        if model.dropped.isEmpty {
            validationErrors.append("At least one payload is required")
        }
        
        // Payload-specific validation
        for payload in model.dropped {
            if payload.settings.isEmpty {
                validationErrors.append("\(payload.name) has no configuration")
            }
        }
    }
    
    private func generateXML() {
        // Generate XML representation of the profile
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>PayloadContent</key>
            <array>
        """
        
        for payload in model.dropped {
            xml += """
            
                <dict>
                    <key>PayloadType</key>
                    <string>\(payload.id)</string>
                    <key>PayloadVersion</key>
                    <integer>1</integer>
                    <key>PayloadIdentifier</key>
                    <string>\(model.settings.identifier).\(payload.id)</string>
                    <key>PayloadUUID</key>
                    <string>\(payload.uuid)</string>
                    <key>PayloadDisplayName</key>
                    <string>\(payload.name)</string>
                    <key>PayloadDescription</key>
                    <string>\(payload.description)</string>
                    <key>PayloadEnabled</key>
                    <\(payload.enabled ? "true" : "false")/>
            """
            
            // Add payload-specific settings
            for (key, value) in payload.settings {
                xml += """
                
                    <key>\(key)</key>
                    <\(valueType(for: value.value))>\(String(describing: value.value))</\(valueType(for: value.value))>
                """
            }
            
            xml += """
            
                </dict>
            """
        }
        
        xml += """
        
            </array>
            <key>PayloadRemovalDisallowed</key>
            <false/>
            <key>PayloadScope</key>
            <string>\(model.settings.scope)</string>
            <key>PayloadType</key>
            <string>Configuration</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
            <key>PayloadIdentifier</key>
            <string>\(model.settings.identifier)</string>
            <key>PayloadUUID</key>
            <string>\(UUID().uuidString)</string>
            <key>PayloadDisplayName</key>
            <string>\(model.settings.name)</string>
            <key>PayloadDescription</key>
            <string>\(model.settings.description)</string>
            <key>PayloadOrganization</key>
            <string>\(model.settings.organization)</string>
        </dict>
        </plist>
        """
        
        xmlContent = xml
    }
    
    private func valueType(for value: AnyHashable) -> String {
        switch value {
        case is Bool: return "true"
        case is Int: return "integer"
        case is Double: return "real"
        case is String: return "string"
        case is [String]: return "array"
        default: return "string"
        }
    }
    
    private func exportToDownloads() {
        do {
            let url = try model.saveProfileToDownloads()
            print("Profile exported to: \(url)")
            dismiss()
        } catch {
            print("Export failed: \(error)")
        }
    }
    
    private func copyXMLToClipboard() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(xmlContent, forType: .string)
        #endif
    }
    
    private func uploadToJAMF() {
        Task {
            do {
                try await model.submitProfileToJAMF()
                print("Profile uploaded to JAMF successfully")
                dismiss()
            } catch {
                print("Upload failed: \(error)")
            }
        }
    }
}

// MARK: - Profile Info Item
struct ProfileInfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(LCARSTheme.textSecondary)
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(LCARSTheme.textPrimary)
        }
    }
}

// MARK: - Payload Summary Row
struct PayloadSummaryRow: View {
    let payload: Payload
    
    var body: some View {
        HStack(spacing: 12) {
            Text(payload.icon)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(payload.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(LCARSTheme.textPrimary)
                
                Text("\(payload.settings.count) settings configured")
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
            }
            
            Spacer()
            
            if payload.enabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(LCARSTheme.surface)
        .cornerRadius(8)
    }
}

// MARK: - Export Option Row
struct ExportOptionRow: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(LCARSTheme.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textMuted)
            }
            .padding(12)
            .background(LCARSTheme.background)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ProfilePreviewSheet(model: BuilderModel())
}
