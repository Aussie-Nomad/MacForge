//
//  PayloadConfigurationSheet.swift
//  MacForge
//
//  Dynamic configuration sheet for individual MDM payloads.
//  Provides form-based configuration with validation and real-time preview.
//

import SwiftUI

// MARK: - Payload Configuration Sheet
struct PayloadConfigurationSheet: View {
    let payload: Payload
    @ObservedObject var model: BuilderModel
    @Binding var isPresented: Bool
    
    @State private var configuration: [String: CodableValue] = [:]
    @State private var showingPreview = false
    @State private var validationErrors: [String] = []
    
    var body: some View {
        NavigationView {
            mainContent
        }
        .sheet(isPresented: $showingPreview) {
            PayloadPreviewSheet(payload: payload, configuration: configuration)
        }
        .onAppear {
            loadConfiguration()
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            
            configurationForm
            
            actionButtonsSection
        }
        .background(LCARSTheme.background)
        .navigationTitle("Configure \(payload.name)")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Preview") {
                    showingPreview = true
                }
            }
        }
    }
    
    // MARK: - Configuration Form
    private var configurationForm: some View {
        ScrollView {
            VStack(spacing: 20) {
                basicSettingsSection
                
                dynamicConfigurationSection
                
                if !validationErrors.isEmpty {
                    validationSection
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(payload.icon)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    Text(payload.description)
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                }
                
                Spacer()
            }
            
            // Platform Badges
            HStack {
                ForEach(payload.platforms, id: \.self) { platform in
                    PlatformBadge(platform: platform, color: LCARSTheme.accent)
                }
                
                Spacer()
                
                Text(payload.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LCARSTheme.primary.opacity(0.2))
                    .foregroundStyle(LCARSTheme.primary)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(LCARSTheme.surface)
    }
    
    // MARK: - Basic Settings Section
    private var basicSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Settings")
                .font(.headline)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            VStack(spacing: 12) {
                // Display Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Display Name")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    TextField("Enter display name", text: Binding(
                        get: { configuration["DisplayName"]?.value as? String ?? "" },
                        set: { configuration["DisplayName"] = CodableValue($0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    TextField("Enter description", text: Binding(
                        get: { configuration["Description"]?.value as? String ?? "" },
                        set: { configuration["Description"] = CodableValue($0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
                
                // Enabled Toggle
                HStack {
                    Text("Enabled")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { configuration["Enabled"]?.value as? Bool ?? true },
                        set: { configuration["Enabled"] = CodableValue($0) }
                    ))
                    .toggleStyle(.switch)
                }
            }
        }
        .padding(16)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
    }
    
    // MARK: - Dynamic Configuration Section
    private var dynamicConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration Options")
                .font(.headline)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            // Generate dynamic fields based on payload type
            ForEach(dynamicFields, id: \.key) { field in
                DynamicConfigurationField(
                    field: field,
                    value: Binding(
                        get: { configuration[field.key] ?? CodableValue("") },
                        set: { configuration[field.key] = $0 }
                    )
                )
            }
        }
        .padding(16)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
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
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                isPresented = false
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            Button("Save Configuration") {
                saveConfiguration()
            }
            .buttonStyle(LcarsButtonStyle())
            .frame(maxWidth: .infinity)
            .disabled(validationErrors.count > 0)
        }
        .padding(20)
        .background(LCARSTheme.surface)
    }
    
    // MARK: - Helper Methods
    private var dynamicFields: [DynamicField] {
        switch payload.id {
        case "wifi":
            return [
                DynamicField(key: "SSID_STR", label: "Network Name (SSID)", type: .string, required: true),
                DynamicField(key: "HIDDEN_NETWORK", label: "Hidden Network", type: .boolean, required: false),
                DynamicField(key: "EncryptionType", label: "Security Type", type: .enum, required: true, options: ["WPA", "WPA2", "WPA3", "None"]),
                DynamicField(key: "Password", label: "Password", type: .password, required: false)
            ]
        case "vpn":
            return [
                DynamicField(key: "VPNType", label: "VPN Type", type: .enum, required: true, options: ["IKEv2", "L2TP", "PPTP"]),
                DynamicField(key: "RemoteAddress", label: "Server Address", type: .string, required: true),
                DynamicField(key: "Username", label: "Username", type: .string, required: false),
                DynamicField(key: "Password", label: "Password", type: .password, required: false)
            ]
        case "filevault2":
            return [
                DynamicField(key: "Enable", label: "Enable FileVault", type: .boolean, required: true),
                DynamicField(key: "ShowRecoveryKey", label: "Show Recovery Key", type: .boolean, required: false),
                DynamicField(key: "Defer", label: "Defer Enablement", type: .boolean, required: false)
            ]
        case "pppc":
            return [
                DynamicField(key: "BundleIdentifier", label: "Bundle Identifier", type: .string, required: true),
                DynamicField(key: "CodeRequirement", label: "Code Requirement", type: .string, required: false),
                DynamicField(key: "Services", label: "Services", type: .array, required: true)
            ]
        default:
            return [
                DynamicField(key: "CustomSetting", label: "Custom Setting", type: .string, required: false)
            ]
        }
    }
    
    private func loadConfiguration() {
        configuration = payload.settings
        if configuration.isEmpty {
            // Set default values
            configuration["DisplayName"] = CodableValue(payload.name)
            configuration["Description"] = CodableValue(payload.description)
            configuration["Enabled"] = CodableValue(true)
        }
        validateConfiguration()
    }
    
    private func saveConfiguration() {
        // Update the payload in the model
        if let index = model.dropped.firstIndex(where: { $0.id == payload.id }) {
            model.dropped[index].settings = configuration
        }
        isPresented = false
    }
    
    private func validateConfiguration() {
        validationErrors.removeAll()
        
        for field in dynamicFields where field.required {
            if let value = configuration[field.key]?.value as? String, value.isEmpty {
                validationErrors.append("\(field.label) is required")
            }
        }
        
        // Payload-specific validation
        switch payload.id {
        case "wifi":
            if let ssid = configuration["SSID_STR"]?.value as? String, ssid.isEmpty {
                validationErrors.append("Wi-Fi network name is required")
            }
        case "vpn":
            if let address = configuration["RemoteAddress"]?.value as? String, address.isEmpty {
                validationErrors.append("VPN server address is required")
            }
        case "pppc":
            if let bundleID = configuration["BundleIdentifier"]?.value as? String, bundleID.isEmpty {
                validationErrors.append("Bundle identifier is required for PPPC")
            }
        default:
            break
        }
    }
}

// MARK: - Dynamic Field Model
struct DynamicField {
    let key: String
    let label: String
    let type: FieldType
    let required: Bool
    let options: [String]?
    
    init(key: String, label: String, type: FieldType, required: Bool = false, options: [String]? = nil) {
        self.key = key
        self.label = label
        self.type = type
        self.required = required
        self.options = options
    }
}

enum FieldType {
    case string, boolean, integer, password, `enum`, array
}

// MARK: - Dynamic Configuration Field
struct DynamicConfigurationField: View {
    let field: DynamicField
    @Binding var value: CodableValue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(field.label)
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
                
                if field.required {
                    Text("*")
                        .foregroundStyle(.red)
                }
                
                Spacer()
            }
            
            switch field.type {
            case .string, .password:
                SecureField(field.type == .password ? "Enter \(field.label.lowercased())" : "Enter \(field.label.lowercased())", text: Binding(
                    get: { value.value as? String ?? "" },
                    set: { value = CodableValue($0) }
                ))
                .textFieldStyle(.roundedBorder)
                
            case .boolean:
                Toggle("", isOn: Binding(
                    get: { value.value as? Bool ?? false },
                    set: { value = CodableValue($0) }
                ))
                .toggleStyle(.switch)
                
            case .integer:
                TextField("Enter number", value: Binding(
                    get: { value.value as? Int ?? 0 },
                    set: { value = CodableValue($0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                
            case .enum:
                if let options = field.options {
                    Picker("Select \(field.label.lowercased())", selection: Binding(
                        get: { value.value as? String ?? options.first ?? "" },
                        set: { value = CodableValue($0) }
                    )) {
                        ForEach(options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
            case .array:
                Text("Array configuration - use advanced editor")
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textMuted)
            }
        }
    }
}

// MARK: - Payload Preview Sheet
struct PayloadPreviewSheet: View {
    let payload: Payload
    let configuration: [String: CodableValue]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Configuration Preview")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                configurationList
            }
            .navigationTitle("Preview")
        }
    }
    
    private var configurationList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(configuration.keys.sorted()), id: \.self) { key in
                    configurationRow(key: key)
                }
            }
            .padding(20)
        }
    }
    
    private func configurationRow(key: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.headline)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            Text(configurationValueString(for: key))
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
                .padding(8)
                .background(LCARSTheme.panel)
                .cornerRadius(8)
        }
    }
    
    private func configurationValueString(for key: String) -> String {
        guard let codableValue = configuration[key] else {
            return "No value"
        }
        
        switch codableValue.value {
        case let string as String:
            return string.isEmpty ? "Empty" : string
        case let bool as Bool:
            return bool ? "Yes" : "No"
        case let int as Int:
            return String(int)
        case let double as Double:
            return String(double)
        case let array as [String]:
            return array.isEmpty ? "Empty array" : array.joined(separator: ", ")
        default:
            return String(describing: codableValue.value)
        }
    }
}

// MARK: - Preview
#Preview {
    PayloadConfigurationSheet(
        payload: Payload(
            id: "wifi",
            name: "Wi-Fi",
            description: "Configure Wi-Fi network settings",
            platforms: ["iOS", "macOS"],
            icon: "📶",
            category: "Network"
        ),
        model: BuilderModel(),
        isPresented: .constant(true)
    )
}
