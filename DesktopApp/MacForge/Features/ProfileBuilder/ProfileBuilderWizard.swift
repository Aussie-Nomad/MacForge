//
//  ProfileBuilderWizard.swift
//  MacForge
//
//  Comprehensive Profile Builder Wizard with 4-step process.
//  Includes app upload, template management, payload selection, configuration, and deployment.
//

import SwiftUI
import UniformTypeIdentifiers

struct ProfileBuilderWizard: View {
    let selectedMDM: MDMVendor?
    let model: BuilderModel
    let onHome: () -> Void
    
    @State private var currentStep: WizardStep = .setup
    @State private var profileSettings = ProfileSettings()
    @State private var selectedTemplate: TemplateProfile?
    @State private var showingTemplateCreator = false
    @State private var showingAppUpload = false
    @State private var uploadedApps: [AppInfo] = []
    @State private var selectedPayloads: [Payload] = []
    @State private var payloadConfigurations: [String: [String: CodableValue]] = [:]
    
    enum WizardStep: Int, CaseIterable {
        case setup = 0
        case choosePayload = 1
        case configureSettings = 2
        case exportDeploy = 3
        
        var title: String {
            switch self {
            case .setup: return "Setup"
            case .choosePayload: return "Choose Payloads"
            case .configureSettings: return "Configure Settings"
            case .exportDeploy: return "Export & Deploy"
            }
        }
        
        var description: String {
            switch self {
            case .setup: return "Upload apps, choose templates, or create new ones"
            case .choosePayload: return "Select the configuration payloads you need"
            case .configureSettings: return "Configure values and options for each payload"
            case .exportDeploy: return "Export profile and deploy to your MDM"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Wizard Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Builder Wizard")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(LCARSTheme.accent)
                        
                        Text("Create Apple Configuration Profiles with guided assistance")
                            .font(.title3)
                            .foregroundStyle(LCARSTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button("Back to Tools") {
                        onHome()
                    }
                    .buttonStyle(.bordered)
                }
                
                // Step Indicator
                HStack(spacing: 0) {
                    ForEach(WizardStep.allCases, id: \.self) { step in
                        StepIndicator(
                            step: step,
                            isActive: currentStep == step,
                            isCompleted: currentStep.rawValue > step.rawValue,
                            isFirst: step == .setup,
                            isLast: step == .exportDeploy
                        )
                    }
                }
            }
            .padding(24)
            .background(LCARSTheme.panel)
            .cornerRadius(16)
            
            // Step Content
            VStack(spacing: 0) {
                switch currentStep {
                case .setup:
                    SetupStepView(
                        profileSettings: $profileSettings,
                        selectedTemplate: $selectedTemplate,
                        uploadedApps: $uploadedApps,
                        showingTemplateCreator: $showingTemplateCreator,
                        showingAppUpload: $showingAppUpload,
                        onNext: { currentStep = .choosePayload }
                    )
                    
                case .choosePayload:
                    ChoosePayloadStepView(
                        selectedPayloads: $selectedPayloads,
                        onBack: { currentStep = .setup },
                        onNext: { currentStep = .configureSettings }
                    )
                    
                case .configureSettings:
                    ConfigureSettingsStepView(
                        selectedPayloads: selectedPayloads,
                        payloadConfigurations: $payloadConfigurations,
                        onBack: { currentStep = .choosePayload },
                        onNext: { currentStep = .exportDeploy }
                    )
                    
                case .exportDeploy:
                    ExportDeployStepView(
                        profileSettings: profileSettings,
                        selectedPayloads: selectedPayloads,
                        payloadConfigurations: payloadConfigurations,
                        onBack: { currentStep = .configureSettings },
                        onComplete: { onHome() }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(LCARSTheme.background)
        .sheet(isPresented: $showingTemplateCreator) {
            TemplateCreatorView()
        }
        .sheet(isPresented: $showingAppUpload) {
            AppUploadView(uploadedApps: $uploadedApps)
        }
    }
}

// MARK: - Step Indicator
struct StepIndicator: View {
    let step: ProfileBuilderWizard.WizardStep
    let isActive: Bool
    let isCompleted: Bool
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Connector Line (before)
            if !isFirst {
                Rectangle()
                    .fill(isCompleted ? LCARSTheme.accent : LCARSTheme.textMuted)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            }
            
            // Step Circle
            ZStack {
                Circle()
                    .fill(stepColor)
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                } else {
                    Text("\(step.rawValue + 1)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(stepTextColor)
                }
            }
            
            // Connector Line (after)
            if !isLast {
                Rectangle()
                    .fill(isCompleted ? LCARSTheme.accent : LCARSTheme.textMuted)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var stepColor: Color {
        if isCompleted { return LCARSTheme.accent }
        if isActive { return LCARSTheme.primary }
        return LCARSTheme.panel
    }
    
    private var stepTextColor: Color {
        if isActive { return .black }
        return LCARSTheme.textSecondary
    }
}

// MARK: - Setup Step
struct SetupStepView: View {
    @Binding var profileSettings: ProfileSettings
    @Binding var selectedTemplate: TemplateProfile?
    @Binding var uploadedApps: [AppInfo]
    @Binding var showingTemplateCreator: Bool
    @Binding var showingAppUpload: Bool
    let onNext: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Profile Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Profile Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsRow(label: "Profile Name", value: $profileSettings.name)
                        SettingsRow(label: "Description", value: $profileSettings.description)
                        SettingsRow(label: "Identifier", value: $profileSettings.identifier)
                        SettingsRow(label: "Organization", value: $profileSettings.organization)
                        SettingsRow(label: "Scope", value: $profileSettings.scope)
                    }
                }
                .padding(20)
                .background(LCARSTheme.panel)
                .cornerRadius(12)
                
                // App Upload
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Application Upload")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        Spacer()
                        
                        Button("Upload Apps") {
                            showingAppUpload = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(LCARSTheme.accent)
                    }
                    
                    if uploadedApps.isEmpty {
                        Text("No applications uploaded yet. Upload apps to configure PPPC and other app-specific settings.")
                            .font(.body)
                            .foregroundStyle(LCARSTheme.textSecondary)
                            .padding(20)
                            .background(LCARSTheme.surface)
                            .cornerRadius(8)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(uploadedApps) { app in
                                AppInfoCard(app: app)
                            }
                        }
                    }
                }
                .padding(20)
                .background(LCARSTheme.panel)
                .cornerRadius(12)
                
                // Template Management
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Template Management")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        Spacer()
                        
                        Button("Create Template") {
                            showingTemplateCreator = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let template = selectedTemplate {
                        TemplateCard(template: template, isSelected: true) {
                            selectedTemplate = nil
                        }
                    } else {
                        Text("No template selected. Choose an existing template or create a new one to get started quickly.")
                            .font(.body)
                            .foregroundStyle(LCARSTheme.textSecondary)
                            .padding(20)
                            .background(LCARSTheme.surface)
                            .cornerRadius(8)
                    }
                }
                .padding(20)
                .background(LCARSTheme.panel)
                .cornerRadius(12)
                
                // Navigation
                HStack {
                    Spacer()
                    
                    Button("Next: Choose Payloads") {
                        onNext()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(LCARSTheme.accent)
                    .disabled(profileSettings.name.isEmpty || profileSettings.identifier.isEmpty)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Choose Payload Step
struct ChoosePayloadStepView: View {
    @Binding var selectedPayloads: [Payload]
    let onBack: () -> Void
    let onNext: () -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    
    private let availablePayloads = [
        Payload(id: "filevault", name: "FileVault 2 Encryption", description: "Enable and configure FileVault 2 disk encryption for enhanced data security on macOS devices.", platforms: ["macOS"], icon: "lock.shield", category: "Security"),
        Payload(id: "gatekeeper", name: "Gatekeeper Security", description: "Control which applications can run on macOS devices based on their source and code signing status.", platforms: ["macOS"], icon: "shield", category: "Security"),
        Payload(id: "firewall", name: "Firewall Configuration", description: "Configure macOS firewall settings to control network access and protect against unauthorized connections.", platforms: ["macOS"], icon: "network.badge.shield.half.filled", category: "Security"),
        Payload(id: "wifi", name: "Wi-Fi Configuration", description: "Configure Wi-Fi network settings including SSID, security type, and authentication methods.", platforms: ["macOS", "iOS"], icon: "wifi", category: "Network"),
        Payload(id: "vpn", name: "VPN Configuration", description: "Set up VPN connections with various protocols including IKEv2, L2TP, and PPTP.", platforms: ["macOS", "iOS"], icon: "network", category: "Network"),
        Payload(id: "pppc", name: "Privacy Preferences Policy Control", description: "Manage Privacy Preferences Policy Control (PPPC) to control app access to system resources.", platforms: ["macOS", "iOS"], icon: "hand.raised", category: "Privacy"),
        Payload(id: "tcc", name: "Transparency, Consent, and Control", description: "Configure TCC settings for privacy and security controls.", platforms: ["macOS", "iOS"], icon: "eye.slash", category: "Privacy"),
        Payload(id: "apprestrictions", name: "Application Restrictions", description: "Limit which applications can run and control app functionality and features.", platforms: ["macOS", "iOS"], icon: "app.badge", category: "Applications"),
        Payload(id: "loginwindow", name: "Login Window Settings", description: "Configure login window appearance, behavior, and security settings.", platforms: ["macOS"], icon: "person.crop.rectangle", category: "System"),
        Payload(id: "energysaver", name: "Energy Saver Preferences", description: "Manage power management settings and energy-saving preferences for macOS devices.", platforms: ["macOS"], icon: "battery.100", category: "System")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Configuration Payloads")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(LCARSTheme.accent)
                
                Spacer()
                
                Text("\(selectedPayloads.count) selected")
                    .font(.subheadline)
                    .foregroundStyle(LCARSTheme.textSecondary)
            }
            .padding(20)
            .background(LCARSTheme.surface)
            
            // Search and Filter
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    TextField("Search payloads...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["All", "Security", "Network", "Privacy", "Applications", "System", "Restrictions", "Enterprise"], id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(16)
            .background(LCARSTheme.surface)
            
            // Payload List
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(filteredPayloads, id: \.self) { payload in
                        PayloadSelectionCard(
                            payload: payload,
                            isSelected: selectedPayloads.contains(payload),
                            onToggle: { togglePayload(payload) }
                        )
                    }
                }
                .padding(16)
            }
            
            // Navigation
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Next: Configure Settings") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .tint(LCARSTheme.accent)
                .disabled(selectedPayloads.isEmpty)
            }
            .padding(20)
            .background(LCARSTheme.surface)
        }
    }
    
    private var filteredPayloads: [Payload] {
        let categoryFiltered = selectedCategory == "All" ? availablePayloads : availablePayloads.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { payload in
                payload.name.localizedCaseInsensitiveContains(searchText) ||
                payload.description.localizedCaseInsensitiveContains(searchText) ||
                payload.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func togglePayload(_ payload: Payload) {
        if selectedPayloads.contains(payload) {
            selectedPayloads.removeAll { $0.id == payload.id }
        } else {
            selectedPayloads.append(payload)
        }
    }
}

// MARK: - Configure Settings Step
struct ConfigureSettingsStepView: View {
    let selectedPayloads: [Payload]
    @Binding var payloadConfigurations: [String: [String: CodableValue]]
    let onBack: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Configure Payload Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(LCARSTheme.accent)
                
                Spacer()
                
                Text("\(selectedPayloads.count) payloads to configure")
                    .font(.subheadline)
                    .foregroundStyle(LCARSTheme.textSecondary)
            }
            .padding(20)
            .background(LCARSTheme.surface)
            
            // Configuration Content
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(selectedPayloads, id: \.self) { payload in
                        PayloadConfigurationView(
                            payload: payload,
                            configuration: binding(for: payload.id)
                        )
                    }
                }
                .padding(16)
            }
            
            // Navigation
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Next: Export & Deploy") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .tint(LCARSTheme.accent)
            }
            .padding(20)
            .background(LCARSTheme.surface)
        }
    }
    
    private func binding(for payloadId: String) -> Binding<[String: CodableValue]> {
        Binding(
            get: { payloadConfigurations[payloadId] ?? [:] },
            set: { payloadConfigurations[payloadId] = $0 }
        )
    }
}

// MARK: - Export & Deploy Step
struct ExportDeployStepView: View {
    let profileSettings: ProfileSettings
    let selectedPayloads: [Payload]
    let payloadConfigurations: [String: [String: CodableValue]]
    let onBack: () -> Void
    let onComplete: () -> Void
    
    @State private var showingExportPanel = false
    @State private var showingDeployPanel = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Export & Deploy Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(LCARSTheme.accent)
                
                Spacer()
                
                Text("Ready for deployment")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            .padding(20)
            .background(LCARSTheme.surface)
            
            // Profile Summary
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Profile Overview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Profile Overview")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            SummaryRow(label: "Name", value: profileSettings.name)
                            SummaryRow(label: "Description", value: profileSettings.description)
                            SummaryRow(label: "Identifier", value: profileSettings.identifier)
                            SummaryRow(label: "Organization", value: profileSettings.organization)
                            SummaryRow(label: "Scope", value: profileSettings.scope)
                        }
                    }
                    .padding(20)
                    .background(LCARSTheme.panel)
                    .cornerRadius(12)
                    
                    // Payload Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Selected Payloads")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(selectedPayloads, id: \.self) { payload in
                                PayloadSummaryCard(payload: payload)
                            }
                        }
                    }
                    .padding(20)
                    .background(LCARSTheme.panel)
                    .cornerRadius(12)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button("Export .mobileconfig File") {
                            showingExportPanel = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(LCARSTheme.accent)
                        .frame(maxWidth: .infinity)
                        
                        Button("Deploy to MDM") {
                            showingDeployPanel = true
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(16)
            }
            
            // Navigation
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Complete") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .tint(LCARSTheme.accent)
            }
            .padding(20)
            .background(LCARSTheme.surface)
        }
        .fileExporter(
            isPresented: $showingExportPanel,
            document: ProfileDocument(content: generateProfileContent()),
            contentType: UTType(filenameExtension: "mobileconfig") ?? .data,
            defaultFilename: "\(profileSettings.name).mobileconfig"
        ) { _ in }
    }
    
    private func generateProfileContent() -> String {
        // Generate the actual .mobileconfig content
        return "Profile content would be generated here"
    }
}

// MARK: - Supporting Views
struct SettingsRow: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            TextField(label, text: $value)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct AppInfoCard: View {
    let app: AppInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "app.badge")
                    .foregroundStyle(LCARSTheme.accent)
                
                Text(app.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Text(app.bundleID)
                .font(.caption)
                .foregroundStyle(LCARSTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(LCARSTheme.surface)
        .cornerRadius(8)
    }
}

struct TemplateCard: View {
    let template: TemplateProfile
    let isSelected: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(LCARSTheme.textPrimary)
                
                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Remove") {
                onRemove()
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(16)
        .background(LCARSTheme.surface)
        .cornerRadius(8)
    }
}

struct PayloadSelectionCard: View {
    let payload: Payload
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.name)
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    Text(payload.category)
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LCARSTheme.accent.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? LCARSTheme.accent : LCARSTheme.textSecondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            
            Text(payload.description)
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
                .lineLimit(3)
            
            HStack(spacing: 8) {
                ForEach(payload.platforms, id: \.self) { platform in
                    PlatformBadge(platform: platform, color: platformColor(for: platform))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LCARSTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? LCARSTheme.accent : Color.clear, lineWidth: 2)
                )
        )
    }
    
    private func platformColor(for platform: String) -> Color {
        switch platform.lowercased() {
        case "macos": return .blue
        case "ios": return .green
        case "tvos": return .purple
        default: return .gray
        }
    }
}

struct PayloadConfigurationView: View {
    let payload: Payload
    @Binding var configuration: [String: CodableValue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.name)
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    Text(payload.category)
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.accent)
                }
                
                Spacer()
                
                Button("Configure") {
                    // Open detailed configuration interface
                }
                .buttonStyle(.borderedProminent)
                .tint(LCARSTheme.accent)
            }
            
            Text(payload.description)
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
            
            // Basic configuration options would go here
            Text("Configuration options will be available in the detailed view")
                .font(.caption)
                .foregroundStyle(LCARSTheme.textMuted)
                .padding(12)
                .background(LCARSTheme.surface)
                .cornerRadius(8)
        }
        .padding(16)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
    }
}

struct PayloadSummaryCard: View {
    let payload: Payload
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(payload.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(LCARSTheme.textPrimary)
                
                Spacer()
                
                Text(payload.category)
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.accent)
            }
            
            Text(payload.description)
                .font(.caption)
                .foregroundStyle(LCARSTheme.textSecondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(LCARSTheme.surface)
        .cornerRadius(8)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(LCARSTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(LCARSTheme.textPrimary)
        }
    }
}

// MARK: - Placeholder Views
struct TemplateCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Template Creator")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Template creation interface will be implemented here")
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }
}

struct AppUploadView: View {
    @Binding var uploadedApps: [AppInfo]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("App Upload")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("App upload interface will be implemented here")
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }
}

// MARK: - Profile Document
struct ProfileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    
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

#Preview {
    ProfileBuilderWizard(
        selectedMDM: .jamf,
        model: BuilderModel(),
        onHome: {}
    )
}
