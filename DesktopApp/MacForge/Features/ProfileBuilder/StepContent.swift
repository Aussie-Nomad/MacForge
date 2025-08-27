//
//  StepContent.swift
//  MacForge
//
//  Step content components for the profile builder wizard mode.
//  Provides guided step-by-step profile creation with validation and help.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Step 1 Content
struct Step1Content: View {
    @ObservedObject var model: BuilderModel
    @ObservedObject var viewModel: ProfileBuilderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("CREATE PROFILE")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(LcarsTheme.amber)

            Text("Start by naming your profile and uploading an application to configure PPPC permissions.")
                .foregroundStyle(.secondary)

            // Profile Settings Section
            VStack(alignment: .leading, spacing: 20) {
                Text("PROFILE SETTINGS")
                    .font(.headline)
                    .foregroundStyle(LcarsTheme.amber)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Profile Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter profile name", text: $viewModel.profileSettings.name)
                            .textFieldStyle(.roundedBorder)
                            .contentShape(Rectangle())
                    }
                    
                    // Profile Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter profile description", text: $viewModel.profileSettings.description)
                            .textFieldStyle(.roundedBorder)
                            .contentShape(Rectangle())
                    }
                    
                    // Profile Identifier with explanation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Identifier")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Button(action: {
                                // Show tooltip/popover explaining identifier
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(LcarsTheme.amber)
                            }
                            .help("The identifier is a unique string that uniquely identifies this profile. It's typically in reverse domain notation (e.g., com.company.profile.name) and must be unique across all profiles on the device.")
                            .contentShape(Rectangle())
                        }
                        
                        TextField("Enter profile identifier", text: $viewModel.profileSettings.identifier)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .contentShape(Rectangle())
                        
                        Text("Format: com.organization.profile.name (must be unique)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Organization
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Organization")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter organization name", text: $viewModel.profileSettings.organization)
                            .textFieldStyle(.roundedBorder)
                            .contentShape(Rectangle())
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LcarsTheme.panel.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LcarsTheme.amber.opacity(0.5), lineWidth: 1)
                        )
                )
            }

            // Application Drop Zone
            VStack(alignment: .leading, spacing: 20) {
                Text("TARGET APPLICATION")
                    .font(.headline)
                    .foregroundStyle(LcarsTheme.amber)
                
                Text("Drag and drop an application (.app) to configure PPPC permissions for it, or select from the payload library below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // App Drop Zone
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LcarsTheme.panel.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LcarsTheme.amber, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    
                    VStack(spacing: 16) {
                        if let selectedApp = model.selectedApp {
                            // Show selected app info
                            VStack(spacing: 12) {
                                Image(systemName: "app.fill")
                                    .font(.title)
                                    .foregroundStyle(LcarsTheme.amber)
                                
                                Text(selectedApp.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(selectedApp.bundleID)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .font(.system(.caption, design: .monospaced))
                                
                                Button("Remove App") {
                                    model.selectedApp = nil
                                }
                                .buttonStyle(.bordered)
                                .foregroundStyle(.red)
                                .contentShape(Rectangle())
                            }
                        } else {
                            // Show drop zone
                            VStack(spacing: 16) {
                                Image(systemName: "arrow.down.doc")
                                    .font(.title)
                                    .foregroundStyle(LcarsTheme.amber)
                                
                                Text("Drop Application Here")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Drag and drop a .app file to configure PPPC permissions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Select Application") {
                                    selectApplication()
                                }
                                .buttonStyle(.bordered)
                                .contentShape(Rectangle())
                            }
                        }
                    }
                    .padding(24)
                }
                .frame(height: 200)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleAppDrop(providers)
                    return true
                }
            }

            // Available payloads grid - responsive columns
            VStack(alignment: .leading, spacing: 16) {
                Text("AVAILABLE PAYLOADS")
                    .font(.headline)
                    .foregroundStyle(LcarsTheme.amber)
                
                Text("Choose the payloads you want to include in your profile. You can select multiple payloads and configure them in the next steps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(model.library) { payload in
                        PayloadSelectionTile(
                            payload: payload,
                            isSelected: model.dropped.contains { $0.id == payload.id },
                            onToggle: { viewModel.togglePayload(payload) }
                        )
                    }
                }
            }

            // Selected count
            if !model.dropped.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("\(model.dropped.count) payload(s) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - App Selection Helpers
    private func selectApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                handleSelectedApp(url)
            }
        }
    }
    
    private func handleAppDrop(_ providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    self.handleSelectedApp(url)
                }
            }
            }
        }
    
    private func handleSelectedApp(_ url: URL) {
        // Extract app information
        let appName = url.deletingPathExtension().lastPathComponent
        let bundleID = extractBundleID(from: url) ?? "com.unknown.app"
        
        let appInfo = AppInfo(name: appName, bundleID: bundleID, path: url.path)
        model.selectedApp = appInfo
    }
    
    private func extractBundleID(from url: URL) -> String? {
        // Try to extract bundle ID from Info.plist
        let infoPlistPath = url.appendingPathComponent("Contents/Info.plist")
        
        guard let plistData = try? Data(contentsOf: infoPlistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
              let bundleID = plist["CFBundleIdentifier"] as? String else {
            return nil
        }
        
        return bundleID
    }
}

// MARK: - Step 2 Content
struct Step2Content: View {
    @ObservedObject var model: BuilderModel
    @ObservedObject var viewModel: ProfileBuilderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("CONFIGURE PAYLOADS")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(LcarsTheme.amber)

            Text("Configure the settings for your selected payloads. Each payload may have different configuration options.")
                .foregroundStyle(.secondary)

            if model.dropped.isEmpty {
                Text("No payloads selected. Please go back to step 1 and select at least one payload.")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(model.dropped) { payload in
                            if payload.id == "pppc" {
                                PPPCConfigurationView(model: model, viewModel: viewModel)
                            } else {
                                PayloadConfigurationTile(payload: payload)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step 3 Content
struct Step3Content: View {
    @ObservedObject var model: BuilderModel
    @ObservedObject var viewModel: ProfileBuilderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("REVIEW & EXPORT")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(LcarsTheme.amber)

            Text("Review your profile configuration and export it as a .mobileconfig file or submit it directly to your MDM.")
                .foregroundStyle(.secondary)

            // Profile settings
            Group {
                Text("PROFILE SETTINGS")
                    .font(.headline)
                    .foregroundStyle(LcarsTheme.amber)

                VStack(alignment: .leading, spacing: 8) {
                    ProfileSettingRow(title: "Name", value: viewModel.profileSettings.name)
                    ProfileSettingRow(title: "Description", value: viewModel.profileSettings.description)
                    ProfileSettingRow(title: "Identifier", value: viewModel.profileSettings.identifier)
                    ProfileSettingRow(title: "Organization", value: viewModel.profileSettings.organization)
                }
                .padding(.leading, 16)
            }

            // Selected payloads summary
            if !model.dropped.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECTED PAYLOADS")
                        .font(.headline)
                        .foregroundStyle(LcarsTheme.amber)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(model.dropped) { payload in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(payload.name)
                                    .font(.caption)
                                Spacer()
                                Text(payload.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.leading, 16)
                }
            }

            // Configuration status
            VStack(alignment: .leading, spacing: 12) {
                Text("CONFIGURATION STATUS")
                    .font(.headline)
                    .foregroundStyle(LcarsTheme.amber)

                VStack(alignment: .leading, spacing: 8) {
                    ConfigurationStatusRow(
                        title: "PPPCP Payload",
                        status: viewModel.hasPPPCPayload ? .configured : .notConfigured
                    )
                    ConfigurationStatusRow(
                        title: "Permissions",
                        status: viewModel.hasConfiguredPermissions ? .configured : .notConfigured
                    )
                    ConfigurationStatusRow(
                        title: "Profile Settings",
                        status: .configured
                    )
                }
                .padding(.leading, 16)
            }
        }
    }
}

// MARK: - Supporting Views
struct PayloadSelectionTile: View {
    let payload: Payload
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(payload.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                Text(payload.description)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(3)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? LcarsTheme.amber : LcarsTheme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? LcarsTheme.amber : .secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("\(payload.name): \(payload.description)")
        .contentShape(Rectangle())
    }
}

// MARK: - PPPC Configuration View
struct PPPCConfigurationView: View {
    @ObservedObject var model: BuilderModel
    @ObservedObject var viewModel: ProfileBuilderViewModel
    @State private var selectedCategory: PPPCServiceCategory = .system
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Privacy Preferences (PPPC) Configuration")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(LcarsTheme.amber)
                
                Spacer()
                
                Button("Add Service") {
                    addDefaultService()
                }
                .buttonStyle(.bordered)
                .disabled(model.selectedApp == nil)
                .help("Add a new PPPC service configuration for the selected application. This allows you to configure specific permissions like Full Disk Access, Accessibility, or Input Monitoring.")
                .contentShape(Rectangle())
            }
            
            // Target Application Info
            if let selectedApp = model.selectedApp {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Target Application")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundStyle(LcarsTheme.amber)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedApp.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(selectedApp.bundleID)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .font(.system(.caption, design: .monospaced))
                        }
                        
                        Spacer()
                        
                        Button("Change App") {
                            model.selectedApp = nil
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.red)
                        .contentShape(Rectangle())
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LcarsTheme.panel.opacity(0.3))
                    )
                }
            } else {
                Text("No application selected. Please go back to Step 1 and select a target application.")
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(LcarsTheme.amber, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
            }
            
            // Service Categories
            if model.selectedApp != nil {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Service Categories")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    // Category Picker
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(PPPCServiceCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Services in selected category
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(pppcServices.filter { $0.category == selectedCategory }, id: \.id) { service in
                            let isConfigured = model.pppcConfigurations.contains { $0.service.id == service.id }
                            PPPCServiceTile(
                                service: service,
                                isConfigured: isConfigured,
                                onToggle: { toggleService(service) }
                            )
                        }
                    }
                }
                
                // Configured Services
                if !model.pppcConfigurations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Configured Services")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        ForEach(model.pppcConfigurations) { config in
                            PPPCConfigurationTile(config: config) { updatedConfig in
                                updateConfiguration(updatedConfig)
                            } onDelete: {
                                deleteConfiguration(config)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LcarsTheme.panel.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LcarsTheme.amber, lineWidth: 2)
        )
    }
    
    // MARK: - Helper Methods
    private func addDefaultService() {
        guard let selectedApp = model.selectedApp else { return }
        
        // Add common services for the selected app
        let commonServices = ["SystemPolicyAllFiles", "Accessibility", "InputMonitoring"]
        
        for serviceID in commonServices {
            if let service = pppcServices.first(where: { $0.id == serviceID }) {
                let config = PPPCConfiguration(
                    service: service,
                    identifier: selectedApp.bundleID
                )
                model.pppcConfigurations.append(config)
            }
        }
    }
    
    private func toggleService(_ service: PPPCService) {
        guard let selectedApp = model.selectedApp else { return }
        
        if let existingIndex = model.pppcConfigurations.firstIndex(where: { $0.service.id == service.id }) {
            // Remove existing configuration
            model.pppcConfigurations.remove(at: existingIndex)
        } else {
            // Add new configuration
            let config = PPPCConfiguration(
                service: service,
                identifier: selectedApp.bundleID
                )
            model.pppcConfigurations.append(config)
        }
    }
    
    private func updateConfiguration(_ config: PPPCConfiguration) {
        if let index = model.pppcConfigurations.firstIndex(where: { $0.id == config.id }) {
            model.pppcConfigurations[index] = config
        }
    }
    
    private func deleteConfiguration(_ config: PPPCConfiguration) {
        model.pppcConfigurations.removeAll { $0.id == config.id }
    }
}

// MARK: - PPPC Service Tile
struct PPPCServiceTile: View {
    let service: PPPCService
    let isConfigured: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(service.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(isConfigured ? .white : .primary)
                    
                    Spacer()
                    
                    if isConfigured {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                Text(service.description)
                    .font(.caption)
                    .foregroundStyle(isConfigured ? .white.opacity(0.8) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isConfigured ? LcarsTheme.amber : LcarsTheme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isConfigured ? LcarsTheme.amber : .secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - PPPC Configuration Tile
struct PPPCConfigurationTile: View {
    let config: PPPCConfiguration
    let onUpdate: (PPPCConfiguration) -> Void
    let onDelete: () -> Void
    
    @State private var isExpanded = false
    @State private var localConfig: PPPCConfiguration
    
    init(config: PPPCConfiguration, onUpdate: @escaping (PPPCConfiguration) -> Void, onDelete: @escaping () -> Void) {
        self.config = config
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._localConfig = State(initialValue: config)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(config.service.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(LcarsTheme.amber)
                
                Spacer()
                
                Button(isExpanded ? "Collapse" : "Expand") {
                    isExpanded.toggle()
                }
                .buttonStyle(.bordered)
                    .font(.caption)
                    .contentShape(Rectangle())
                
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .contentShape(Rectangle())
            }
            
            // Basic Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Identifier:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(config.identifier)
                        .font(.caption)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                
                HStack {
                    Text("Type:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(config.identifierType.displayName)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
            
            // Expanded Configuration
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    // Allow/Deny Toggle
                    HStack {
                        Text("Access:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("Access", selection: $localConfig.allowed) {
                            Text("Allow").tag(true)
                            Text("Deny").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                    
                    // User Override Toggle
                    HStack {
                        Text("User Override:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Toggle("", isOn: $localConfig.userOverride)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    
                    // Comment Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Comment:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("Optional comment", text: Binding(
                            get: { localConfig.comment ?? "" },
                            set: { localConfig.comment = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    }
                    
                    // Save Button
                    Button("Save Changes") {
                        onUpdate(localConfig)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(localConfig == config)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(LcarsTheme.panel.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(LcarsTheme.amber, lineWidth: 1)
        )
    }
}

struct PayloadConfigurationTile: View {
    let payload: Payload

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(payload.name)
                    .font(.headline)
                    .foregroundStyle(LcarsTheme.amber)
                Spacer()
                Text(payload.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(payload.description)
                .foregroundStyle(.secondary)
            
            // Placeholder for configuration options
            Text("Configuration options will be implemented here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 8).fill(LcarsTheme.panel.opacity(0.3)))
    }
}

struct ProfileSettingRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value.isEmpty ? "Not set" : value)
                .font(.caption)
                .foregroundStyle(value.isEmpty ? .secondary.opacity(0.7) : Color.primary)
        }
    }
}

struct ConfigurationStatusRow: View {
    let title: String
    let status: ConfigurationStatus

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: status.iconName)
                    .font(.caption2)
                Text(status.displayText)
                    .font(.caption2)
            }
            .foregroundStyle(status.color)
        }
    }
}
