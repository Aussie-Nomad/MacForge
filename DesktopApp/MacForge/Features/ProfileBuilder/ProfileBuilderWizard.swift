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
                        Text("PPPC Profile Creator Wizard")
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
                        SettingsRow(
                            label: "Profile Name", 
                            value: $profileSettings.name,
                            helpText: "The display name for your configuration profile. This will be shown to users and administrators."
                        )
                        SettingsRow(
                            label: "Description", 
                            value: $profileSettings.description,
                            helpText: "A detailed description of what this profile does and why it's needed. This helps administrators understand the profile's purpose."
                        )
                        SettingsRow(
                            label: "Identifier", 
                            value: $profileSettings.identifier,
                            helpText: "A unique reverse-DNS identifier for your profile (e.g., com.company.profilename). Must be unique across all profiles on the device and cannot contain spaces or special characters.",
                            isMonospaced: true
                        )
                        SettingsRow(
                            label: "Organization", 
                            value: $profileSettings.organization,
                            helpText: "The name of your organization or company. This will be displayed to users and helps identify the source of the profile."
                        )
                        
                        // Scope Picker
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Scope")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(width: 120, alignment: .leading)
                                
                                Button(action: {}) {
                                    Image(systemName: "info.circle")
                                        .foregroundStyle(LCARSTheme.accent)
                                        .font(.caption)
                                }
                                .help("System scope applies to all users on the device, while User scope applies only to the current user. Choose based on your deployment needs.")
                                .buttonStyle(.plain)
                                
                                Spacer()
                            }
                            
                            Picker("Scope", selection: $profileSettings.scope) {
                                Text("System").tag("System")
                                Text("User").tag("User")
                            }
                            .pickerStyle(.segmented)
                        }
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
                    
                    // Drop Zone
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LCARSTheme.surface.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LCARSTheme.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                        
                        if uploadedApps.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "arrow.down.doc")
                                    .font(.title2)
                                    .foregroundStyle(LCARSTheme.accent)
                                
                                Text("Drop .app files here or click Upload Apps")
                                    .font(.subheadline)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                
                                Text("Upload applications to configure PPPC permissions and other app-specific settings")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textMuted)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(20)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("\(uploadedApps.count) Application(s) Uploaded")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(uploadedApps) { app in
                                        AppInfoCard(app: app)
                                            .contextMenu {
                                                Button("Remove") {
                                                    uploadedApps.removeAll { $0.id == app.id }
                                                }
                                                .foregroundStyle(.red)
                                            }
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                    .frame(minHeight: 120)
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleAppDrop(providers)
                        return true
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
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleAppDrop(providers)
            return true
        }
    }
    
    // MARK: - App Drop Handling
    private func handleAppDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        self.handleSelectedApp(url)
                    }
                }
            }
        }
    }
    
    private func handleSelectedApp(_ url: URL) {
        // Extract app information
        let appName = url.deletingPathExtension().lastPathComponent
        let bundleID = extractBundleID(from: url) ?? "com.unknown.app"
        
        let appInfo = AppInfo(name: appName, bundleID: bundleID, path: url.path)
        
        // Check if app is already uploaded
        if !uploadedApps.contains(where: { $0.bundleID == bundleID }) {
            uploadedApps.append(appInfo)
        }
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

// MARK: - Specific Payload Configuration Views

struct PPPCConfigurationView: View {
    @Binding var configuration: [String: CodableValue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy Preferences Policy Control")
                .font(.headline)
                .foregroundStyle(LCARSTheme.accent)
            
            VStack(alignment: .leading, spacing: 12) {
                // Bundle Identifier
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Bundle Identifier")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button(action: {}) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(LCARSTheme.accent)
                                .font(.caption)
                        }
                        .help("The bundle identifier of the application that will be granted permissions")
                        .buttonStyle(.plain)
                    }
                    
                                            TextField("com.company.app", text: stringBinding(for: "BundleIdentifier"))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
                
                // Code Requirement
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Code Requirement")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button(action: {}) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(LCARSTheme.accent)
                                .font(.caption)
                        }
                        .help("Code signing requirement for the application")
                        .buttonStyle(.plain)
                    }
                    
                                            TextField("designated => ...", text: stringBinding(for: "CodeRequirement"))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
                
                // Services
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Services")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(privacyServices, id: \.id) { service in
                            PrivacyServiceToggle(
                                service: service,
                                isEnabled: isServiceEnabled(service.id),
                                onToggle: { toggleService(service.id) }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func stringBinding(for key: String) -> Binding<String> {
        Binding(
            get: { (configuration[key]?.value as? String) ?? "" },
            set: { configuration[key] = CodableValue($0) }
        )
    }
    
    private func isServiceEnabled(_ serviceId: String) -> Bool {
        let services = configuration["Services"]?.value as? [String] ?? []
        return services.contains(serviceId)
    }
    
    private func toggleService(_ serviceId: String) {
        var services = configuration["Services"]?.value as? [String] ?? []
        if services.contains(serviceId) {
            services.removeAll { $0 == serviceId }
        } else {
            services.append(serviceId)
        }
        configuration["Services"] = CodableValue(services)
    }
    
    private let privacyServices = [
        PrivacyService(id: "camera", name: "Camera", description: "Access to camera"),
        PrivacyService(id: "microphone", name: "Microphone", description: "Access to microphone"),
        PrivacyService(id: "full-disk-access", name: "Full Disk Access", description: "Access to all files"),
        PrivacyService(id: "screen-recording", name: "Screen Recording", description: "Record screen content"),
        PrivacyService(id: "accessibility", name: "Accessibility", description: "Control other applications"),
        PrivacyService(id: "input-monitoring", name: "Input Monitoring", description: "Monitor keyboard and mouse")
    ]
}

struct PrivacyServiceToggle: View {
    let service: PrivacyService
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(service.description)
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Image(systemName: isEnabled ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isEnabled ? LCARSTheme.accent : LCARSTheme.textSecondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(LCARSTheme.surface)
        .cornerRadius(6)
    }
}

struct PrivacyService: Identifiable {
    let id: String
    let name: String
    let description: String
}

struct FileVaultConfigurationView: View {
    @Binding var configuration: [String: CodableValue]
    @State private var showingCertificatePicker = false
    @State private var selectedCertificateURL: URL?
    @State private var showingAdvancedOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("FileVault 2 Encryption")
                .font(.headline)
                .foregroundStyle(LCARSTheme.accent)
            
            VStack(alignment: .leading, spacing: 16) {
                // Enable FileVault
                HStack {
                    Text("Enable FileVault")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                                            Toggle("", isOn: boolBinding(for: "EnableFileVault"))
                        .labelsHidden()
                }
                
                // Recovery Key Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recovery Key Configuration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Recovery Key Type
                        HStack {
                            Text("Recovery Key Type")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            Spacer()
                            
                            Picker("Recovery Key Type", selection: stringBinding(for: "RecoveryKeyType")) {
                                Text("Personal Recovery Key").tag("Personal")
                                Text("Institutional Recovery Key").tag("Institutional")
                                Text("Both").tag("Both")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 200)
                        }
                        
                        // Personal Recovery Key
                        if shouldShowPersonalRecoveryKey {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Personal Recovery Key")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    TextField("Enter personal recovery key", text: stringBinding(for: "PersonalRecoveryKey"))
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                    
                                    Button("Generate") {
                                        generatePersonalRecoveryKey()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                        
                        // Institutional Recovery Key
                        if shouldShowInstitutionalRecoveryKey {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Institutional Recovery Key")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    TextField("Enter institutional recovery key", text: stringBinding(for: "InstitutionalRecoveryKey"))
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                    
                                    Button("Generate") {
                                        generateInstitutionalRecoveryKey()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                }
                
                // Recovery Key Certificate
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recovery Key Certificate")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button("Choose Certificate File") {
                                showingCertificatePicker = true
                            }
                            .buttonStyle(.bordered)
                            
                            if let certificateURL = selectedCertificateURL {
                                Text(certificateURL.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                        
                        if selectedCertificateURL != nil {
                            HStack {
                                Button("Remove Certificate") {
                                    removeCertificate()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Advanced Options
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: { showingAdvancedOptions.toggle() }) {
                        HStack {
                            Text("Advanced Options")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: showingAdvancedOptions ? "chevron.up" : "chevron.down")
                                .foregroundStyle(LCARSTheme.accent)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if showingAdvancedOptions {
                        VStack(alignment: .leading, spacing: 12) {
                            // Defer Enable
                            HStack {
                                Text("Defer Enable Until Logout")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                Spacer()
                                
                                Toggle("", isOn: boolBinding(for: "DeferEnable"))
                                    .labelsHidden()
                            }
                            
                            // Defer Force
                            HStack {
                                Text("Force Enable After Defer")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                Spacer()
                                
                                Toggle("", isOn: boolBinding(for: "DeferForce"))
                                    .labelsHidden()
                            }
                            
                            // Defer Count
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Defer Count")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                TextField("Number of deferrals allowed", text: stringBinding(for: "DeferCount"))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 150)
                            }
                            
                            // Show Recovery Key
                            HStack {
                                Text("Show Recovery Key to User")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                Spacer()
                                
                                Toggle("", isOn: boolBinding(for: "ShowRecoveryKey"))
                                    .labelsHidden()
                            }
                            
                            // Use Keychain
                            HStack {
                                Text("Store Recovery Key in Keychain")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                Spacer()
                                
                                Toggle("", isOn: boolBinding(for: "UseKeychain"))
                                    .labelsHidden()
                            }
                        }
                        .padding(.leading, 16)
                    }
                }
                
                // FileVault Status Monitoring
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status Monitoring")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Monitor Encryption Progress")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            Spacer()
                            
                            Toggle("", isOn: boolBinding(for: "MonitorProgress"))
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Send Status Reports")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            Spacer()
                            
                            Toggle("", isOn: boolBinding(for: "SendReports"))
                                .labelsHidden()
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingCertificatePicker,
            allowedContentTypes: [.x509Certificate, .pkcs12],
            allowsMultipleSelection: false
        ) { result in
            handleCertificateSelection(result)
        }
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowPersonalRecoveryKey: Bool {
        let type = configuration["RecoveryKeyType"]?.value as? String ?? "Personal"
        return type == "Personal" || type == "Both"
    }
    
    private var shouldShowInstitutionalRecoveryKey: Bool {
        let type = configuration["RecoveryKeyType"]?.value as? String ?? "Personal"
        return type == "Institutional" || type == "Both"
    }
    
    // MARK: - Helper Methods
    
    private func generatePersonalRecoveryKey() {
        let newKey = generateSecureRecoveryKey()
        configuration["PersonalRecoveryKey"] = CodableValue(newKey)
    }
    
    private func generateInstitutionalRecoveryKey() {
        let newKey = generateSecureRecoveryKey()
        configuration["InstitutionalRecoveryKey"] = CodableValue(newKey)
    }
    
    private func generateSecureRecoveryKey() -> String {
        // Generate a 24-character recovery key with mixed case and numbers
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<24).map { _ in characters.randomElement()! })
    }
    
    private func handleCertificateSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedCertificateURL = url
                configuration["CertificatePath"] = CodableValue(url.path)
                configuration["CertificateName"] = CodableValue(url.lastPathComponent)
            }
        case .failure(let error):
            print("Certificate selection failed: \(error.localizedDescription)")
        }
    }
    
    private func removeCertificate() {
        selectedCertificateURL = nil
        configuration["CertificatePath"] = CodableValue("")
        configuration["CertificateName"] = CodableValue("")
    }
    
    // MARK: - Binding Helpers
    
    private func stringBinding(for key: String) -> Binding<String> {
        Binding(
            get: { (configuration[key]?.value as? String) ?? "" },
            set: { configuration[key] = CodableValue($0) }
        )
    }
    
    private func boolBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: { (configuration[key]?.value as? Bool) ?? false },
            set: { configuration[key] = CodableValue($0) }
        )
    }
}

struct GatekeeperConfigurationView: View {
    @Binding var configuration: [String: CodableValue]
    @State private var showingAdvancedOptions = false
    @State private var showingCertificatePicker = false
    @State private var selectedCertificateURL: URL?
    @State private var customIdentifiers: [String] = []
    @State private var newIdentifier = ""
    @State private var selectedSource = "App Store"
    
    private let applicationSources = [
        ApplicationSource(id: "App Store", name: "App Store", description: "Only allow apps from the Mac App Store"),
        ApplicationSource(id: "App Store and Identified Developers", name: "App Store and Identified Developers", description: "Allow apps from the Mac App Store and identified developers"),
        ApplicationSource(id: "Anywhere", name: "Anywhere", description: "Allow apps from anywhere (not recommended)")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Gatekeeper Security")
                .font(.headline)
                .foregroundStyle(LCARSTheme.accent)
            
            VStack(alignment: .leading, spacing: 16) {
                // Allowed Sources
                VStack(alignment: .leading, spacing: 12) {
                    Text("Allowed Application Sources")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(applicationSources, id: \.id) { source in
                            HStack {
                                RadioButton(
                                    isSelected: selectedSource == source.id,
                                    action: { selectedSource = source.id }
                                )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(source.name)
                                        .font(.subheadline)
                                    
                                    Text(source.description)
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Developer ID Certificates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Developer ID Certificates")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button("Add Developer ID Certificate") {
                                showingCertificatePicker = true
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                        }
                        
                        if let certificateURL = selectedCertificateURL {
                            HStack {
                                Text(certificateURL.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button("Remove") {
                                    removeCertificate()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        // Custom Identifiers
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom Identifiers")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            HStack {
                                TextField("Enter bundle identifier or path", text: $newIdentifier)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button("Add") {
                                    addCustomIdentifier()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(newIdentifier.isEmpty)
                            }
                            
                            if !customIdentifiers.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(customIdentifiers, id: \.self) { identifier in
                                        HStack {
                                            Text(identifier)
                                                .font(.caption)
                                                .foregroundStyle(LCARSTheme.textSecondary)
                                            
                                            Spacer()
                                            
                                            Button("Remove") {
                                                removeCustomIdentifier(identifier)
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Advanced Options
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: { showingAdvancedOptions.toggle() }) {
                        HStack {
                            Text("Advanced Security Options")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: showingAdvancedOptions ? "chevron.up" : "chevron.down")
                                .foregroundStyle(LCARSTheme.accent)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if showingAdvancedOptions {
                        VStack(alignment: .leading, spacing: 12) {
                            // Notarization Requirements
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notarization Requirements")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Text("Require Notarization")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "RequireNotarization"))
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Check Notarization Status")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "CheckNotarization"))
                                        .labelsHidden()
                                }
                            }
                            
                            // Code Signing Policies
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Code Signing Policies")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Text("Require Valid Code Signature")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "RequireCodeSignature"))
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Allow Ad Hoc Signatures")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "AllowAdHocSignatures"))
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Allow Self-Signed Certificates")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "AllowSelfSigned"))
                                        .labelsHidden()
                                }
                            }
                            
                            // Runtime Protection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Runtime Protection")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Text("Enable Runtime Protection")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "EnableRuntimeProtection"))
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Block Untrusted Extensions")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "BlockUntrustedExtensions"))
                                        .labelsHidden()
                                }
                            }
                            
                            // Quarantine Management
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Quarantine Management")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Text("Remove Quarantine Attributes")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "RemoveQuarantine"))
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Allow Quarantined Apps")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "AllowQuarantined"))
                                        .labelsHidden()
                                }
                            }
                        }
                        .padding(.leading, 16)
                    }
                }
                
                // Monitoring and Reporting
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monitoring & Reporting")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Monitor Gatekeeper Events")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            Spacer()
                            
                            Toggle("", isOn: boolBinding(for: "MonitorEvents"))
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Log Blocked Applications")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                            
                            Spacer()
                            
                            Toggle("", isOn: boolBinding(for: "LogBlockedApps"))
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Send Security Reports")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            Spacer()
                            
                            Toggle("", isOn: boolBinding(for: "SendSecurityReports"))
                                .labelsHidden()
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingCertificatePicker,
            allowedContentTypes: [.x509Certificate, .pkcs12],
            allowsMultipleSelection: false
        ) { result in
            handleCertificateSelection(result)
        }
        .onAppear {
            loadCustomIdentifiers()
        }
    }
    
    // MARK: - Computed Properties
    
    // MARK: - Helper Methods
    
    private func addCustomIdentifier() {
        guard !newIdentifier.isEmpty else { return }
        customIdentifiers.append(newIdentifier)
        configuration["CustomIdentifiers"] = CodableValue(customIdentifiers)
        newIdentifier = ""
        saveCustomIdentifiers()
    }
    
    private func removeCustomIdentifier(_ identifier: String) {
        customIdentifiers.removeAll { $0 == identifier }
        configuration["CustomIdentifiers"] = CodableValue(customIdentifiers)
        saveCustomIdentifiers()
    }
    
    private func loadCustomIdentifiers() {
        if let identifiers = configuration["CustomIdentifiers"]?.value as? [String] {
            customIdentifiers = identifiers
        }
    }
    
    private func saveCustomIdentifiers() {
        configuration["CustomIdentifiers"] = CodableValue(customIdentifiers)
    }
    
    private func handleCertificateSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedCertificateURL = url
                configuration["DeveloperIDCertificatePath"] = CodableValue(url.path)
                configuration["DeveloperIDCertificateName"] = CodableValue(url.lastPathComponent)
            }
        case .failure(let error):
            print("Certificate selection failed: \(error.localizedDescription)")
        }
    }
    
    private func removeCertificate() {
        selectedCertificateURL = nil
        configuration["DeveloperIDCertificatePath"] = CodableValue("")
        configuration["DeveloperIDCertificateName"] = CodableValue("")
    }
    
    // MARK: - Binding Helpers
    
    private func stringBinding(for key: String) -> Binding<String> {
        Binding(
            get: { (configuration[key]?.value as? String) ?? "" },
            set: { configuration[key] = CodableValue($0) }
        )
    }
    
    private func boolBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: { (configuration[key]?.value as? Bool) ?? false },
            set: { configuration[key] = CodableValue($0) }
        )
    }
}

struct ApplicationSource: Identifiable {
    let id: String
    let name: String
    let description: String
}

struct RadioButton: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(isSelected ? LCARSTheme.accent : LCARSTheme.textSecondary)
                .font(.title3)
        }
        .buttonStyle(.plain)
    }
}

struct WiFiConfigurationView: View {
    @Binding var configuration: [String: CodableValue]
    @State private var showingAdvancedOptions = false
    @State private var showingCertificatePicker = false
    @State private var selectedCertificateURL: URL?
    @State private var showingPasswordPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Wi-Fi Configuration")
                .font(.headline)
                .foregroundStyle(LCARSTheme.accent)
            
            VStack(alignment: .leading, spacing: 16) {
                // Basic Network Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Basic Network Configuration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    // SSID
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Network Name (SSID)")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                        
                        TextField("Enter network name", text: stringBinding(for: "SSID"))
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Hidden Network
                    HStack {
                        Text("Hidden Network")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                        
                        Spacer()
                        
                        Toggle("", isOn: boolBinding(for: "HiddenNetwork"))
                            .labelsHidden()
                    }
                    
                    // Auto Join
                    HStack {
                        Text("Auto-Join Network")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                        
                        Spacer()
                        
                        Toggle("", isOn: boolBinding(for: "AutoJoin"))
                            .labelsHidden()
                    }
                }
                
                // Security Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Security Configuration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    // Security Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Security Type")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                        
                        Picker("Security", selection: stringBinding(for: "SecurityType")) {
                            Text("None").tag("None")
                            Text("WEP").tag("WEP")
                            Text("WPA/WPA2 Personal").tag("WPA/WPA2 Personal")
                            Text("WPA/WPA2 Enterprise").tag("WPA/WPA2 Enterprise")
                            Text("WPA3 Personal").tag("WPA3 Personal")
                            Text("WPA3 Enterprise").tag("WPA3 Enterprise")
                        }
                        .pickerStyle(.menu)
                        .onChange(of: configuration["SecurityType"]?.value as? String ?? "") { oldValue, newValue in
                            updateSecurityFields()
                        }
                    }
                    
                    // Password/Passphrase
                    if requiresPassword {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(passwordFieldLabel)
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            HStack {
                                SecureField(passwordFieldPlaceholder, text: stringBinding(for: "Password"))
                                    .textFieldStyle(.roundedBorder)
                                
                                Button("Generate") {
                                    generateSecurePassword()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                
                // Enterprise Authentication
                if isEnterpriseSecurity {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enterprise Authentication")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(LCARSTheme.textPrimary)
                        
                        // Authentication Method
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Authentication Method")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            Picker("Authentication", selection: stringBinding(for: "AuthenticationMethod")) {
                                Text("Username & Password").tag("UsernamePassword")
                                Text("EAP-TLS").tag("EAP-TLS")
                                Text("PEAP").tag("PEAP")
                                Text("TTLS").tag("TTLS")
                                Text("FAST").tag("FAST")
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Username
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Username")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            TextField("Enter username", text: stringBinding(for: "Username"))
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Certificate-based Authentication
                        if requiresCertificate {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Client Certificate")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Button("Choose Certificate File") {
                                        showingCertificatePicker = true
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    if let certificateURL = selectedCertificateURL {
                                        Text(certificateURL.lastPathComponent)
                                            .font(.caption)
                                            .foregroundStyle(LCARSTheme.textSecondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                }
                                
                                if selectedCertificateURL != nil {
                                    HStack {
                                        Button("Remove Certificate") {
                                            removeCertificate()
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        // Domain
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Domain")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            TextField("Enter domain (optional)", text: stringBinding(for: "Domain"))
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                
                // Advanced Options
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: { showingAdvancedOptions.toggle() }) {
                        HStack {
                            Text("Advanced Options")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: showingAdvancedOptions ? "chevron.up" : "chevron.down")
                                .foregroundStyle(LCARSTheme.accent)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if showingAdvancedOptions {
                        VStack(alignment: .leading, spacing: 12) {
                            // Proxy Configuration
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Proxy Configuration")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Text("Use Proxy")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "UseProxy"))
                                        .labelsHidden()
                                }
                                
                                if (configuration["UseProxy"]?.value as? Bool) == true {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Proxy Server")
                                            .font(.caption)
                                            .foregroundStyle(LCARSTheme.textSecondary)
                                        
                                        TextField("proxy.company.com", text: stringBinding(for: "ProxyServer"))
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Proxy Port")
                                            .font(.caption)
                                            .foregroundStyle(LCARSTheme.textSecondary)
                                        
                                        TextField("8080", text: stringBinding(for: "ProxyPort"))
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 100)
                                    }
                                }
                            }
                            
                            // QoS Configuration
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Quality of Service")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Text("Enable QoS")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "EnableQoS"))
                                        .labelsHidden()
                                }
                                
                                if (configuration["EnableQoS"]?.value as? Bool) == true {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("QoS Priority")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                        
                                        Picker("QoS Priority", selection: stringBinding(for: "QoSPriority")) {
                                            Text("Background").tag("Background")
                                            Text("Standard").tag("Standard")
                                            Text("Video").tag("Video")
                                            Text("Voice").tag("Voice")
                                        }
                                        .pickerStyle(.menu)
                                    }
                                }
                            }
                            
                            // Network Profile Validation
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Network Profile Validation")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Text("Validate Network Profile")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "ValidateProfile"))
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Test Connection Before Save")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "TestConnection"))
                                        .labelsHidden()
                                }
                            }
                        }
                        .padding(.leading, 16)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingCertificatePicker,
            allowedContentTypes: [.x509Certificate, .pkcs12],
            allowsMultipleSelection: false
        ) { result in
            handleCertificateSelection(result)
        }
        .onAppear {
            updateSecurityFields()
        }
    }
    
    // MARK: - Computed Properties
    
    private var isEnterpriseSecurity: Bool {
        let securityType = configuration["SecurityType"]?.value as? String ?? ""
        return securityType.contains("Enterprise")
    }
    
    private var requiresPassword: Bool {
        let securityType = configuration["SecurityType"]?.value as? String ?? ""
        return securityType != "None"
    }
    
    private var requiresCertificate: Bool {
        let authMethod = configuration["AuthenticationMethod"]?.value as? String ?? ""
        return authMethod == "EAP-TLS"
    }
    
    private var passwordFieldLabel: String {
        let securityType = configuration["SecurityType"]?.value as? String ?? ""
        if securityType.contains("WEP") {
            return "WEP Key"
        } else {
            return "Password/Passphrase"
        }
    }
    
    private var passwordFieldPlaceholder: String {
        let securityType = configuration["SecurityType"]?.value as? String ?? ""
        if securityType.contains("WEP") {
            return "Enter WEP key"
        } else {
            return "Enter password or passphrase"
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateSecurityFields() {
        // Update UI based on security type selection
        let securityType = configuration["SecurityType"]?.value as? String ?? ""
        
        if securityType.contains("Enterprise") {
            configuration["AuthenticationMethod"] = CodableValue("UsernamePassword")
        }
    }
    
    private func generateSecurePassword() {
        let newPassword = generateSecureWiFiPassword()
        configuration["Password"] = CodableValue(newPassword)
    }
    
    private func generateSecureWiFiPassword() -> String {
        // Generate a 16-character WiFi password with mixed case, numbers, and symbols
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
        return String((0..<16).map { _ in characters.randomElement()! })
    }
    
    private func handleCertificateSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedCertificateURL = url
                configuration["ClientCertificatePath"] = CodableValue(url.path)
                configuration["ClientCertificateName"] = CodableValue(url.lastPathComponent)
            }
        case .failure(let error):
            print("Certificate selection failed: \(error.localizedDescription)")
        }
    }
    
    private func removeCertificate() {
        selectedCertificateURL = nil
        configuration["ClientCertificatePath"] = CodableValue("")
        configuration["ClientCertificateName"] = CodableValue("")
    }
    
    // MARK: - Binding Helpers
    
    private func stringBinding(for key: String) -> Binding<String> {
        Binding(
            get: { (configuration[key]?.value as? String) ?? "" },
            set: { configuration[key] = CodableValue($0) }
        )
    }
    
    private func boolBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: { (configuration[key]?.value as? Bool) ?? false },
            set: { configuration[key] = CodableValue($0) }
        )
    }
}

struct VPNConfigurationView: View {
    @Binding var configuration: [String: CodableValue]
    @State private var showingAdvancedOptions = false
    @State private var showingCertificatePicker = false
    @State private var selectedCertificateURL: URL?
    @State private var showingPasswordPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("VPN Configuration")
                .font(.headline)
                .foregroundStyle(LCARSTheme.accent)
            
            VStack(alignment: .leading, spacing: 16) {
                // Basic VPN Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Basic VPN Configuration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    // VPN Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VPN Type")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                        
                        Picker("VPN Type", selection: stringBinding(for: "VPNType")) {
                            Text("IKEv2").tag("IKEv2")
                            Text("L2TP").tag("L2TP")
                            Text("PPTP").tag("PPTP")
                            Text("Cisco IPsec").tag("Cisco IPsec")
                            Text("OpenVPN").tag("OpenVPN")
                            Text("WireGuard").tag("WireGuard")
                        }
                        .pickerStyle(.menu)
                        .onChange(of: configuration["VPNType"]?.value as? String ?? "") { oldValue, newValue in
                            updateVPNFields()
                        }
                    }
                    
                    // Server Address
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server Address")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                        
                        TextField("vpn.company.com", text: stringBinding(for: "ServerAddress"))
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Server Port
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server Port")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                        
                        TextField("Default port for selected protocol", text: stringBinding(for: "ServerPort"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                    }
                    
                    // Account Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Name")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                        
                        TextField("Enter account name", text: stringBinding(for: "AccountName"))
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Authentication Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Authentication Configuration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    // Authentication Method
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Authentication Method")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                        
                        Picker("Authentication", selection: stringBinding(for: "AuthenticationMethod")) {
                            Text("Username & Password").tag("UsernamePassword")
                            Text("Certificate").tag("Certificate")
                            Text("Shared Secret").tag("SharedSecret")
                            Text("RSA SecurID").tag("RSASecurID")
                        }
                        .pickerStyle(.menu)
                        .onChange(of: configuration["AuthenticationMethod"]?.value as? String ?? "") { oldValue, newValue in
                            updateAuthenticationFields()
                        }
                    }
                    
                    // Username
                    if requiresUsername {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Username")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            TextField("Enter username", text: stringBinding(for: "Username"))
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // Password
                    if requiresPassword {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            HStack {
                                SecureField("Enter password", text: stringBinding(for: "Password"))
                                    .textFieldStyle(.roundedBorder)
                                
                                Button("Generate") {
                                    generateSecurePassword()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    
                    // Certificate-based Authentication
                    if requiresCertificate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Client Certificate")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            HStack {
                                Button("Choose Certificate File") {
                                    showingCertificatePicker = true
                                }
                                .buttonStyle(.bordered)
                                
                                if let certificateURL = selectedCertificateURL {
                                    Text(certificateURL.lastPathComponent)
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            
                            if selectedCertificateURL != nil {
                                HStack {
                                    Button("Remove Certificate") {
                                        removeCertificate()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Shared Secret
                    if requiresSharedSecret {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shared Secret")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            SecureField("Enter shared secret", text: stringBinding(for: "SharedSecret"))
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                
                // Advanced Options
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: { showingAdvancedOptions.toggle() }) {
                        HStack {
                            Text("Advanced Options")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: showingAdvancedOptions ? "chevron.up" : "chevron.down")
                                .foregroundStyle(LCARSTheme.accent)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if showingAdvancedOptions {
                        VStack(alignment: .leading, spacing: 12) {
                            // Connection Settings
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Connection Settings")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Text("Auto-Connect")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "AutoConnect"))
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Send All Traffic")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "SendAllTraffic"))
                                        .labelsHidden()
                                }
                                
                                if (configuration["SendAllTraffic"]?.value as? Bool) == false {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Split Tunnel Networks")
                                            .font(.caption)
                                            .foregroundStyle(LCARSTheme.textSecondary)
                                        
                                        TextField("192.168.1.0/24, 10.0.0.0/8", text: stringBinding(for: "SplitTunnelNetworks"))
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            
                            // Security Settings
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Security Settings")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Text("Use Certificate Revocation")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "UseCertificateRevocation"))
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Validate Server Certificate")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "ValidateServerCertificate"))
                                        .labelsHidden()
                                }
                                
                                if (configuration["ValidateServerCertificate"]?.value as? Bool) == true {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Server Certificate Name")
                                            .font(.caption)
                                            .foregroundStyle(LCARSTheme.textSecondary)
                                        
                                        TextField("vpn.company.com", text: stringBinding(for: "ServerCertificateName"))
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            
                            // Monitoring and Reporting
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Monitoring & Reporting")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                HStack {
                                    Text("Monitor Connection Status")
                                        .font(.caption)
                                        .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "MonitorConnection"))
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Log Connection Events")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "LogConnectionEvents"))
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Send Status Reports")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: boolBinding(for: "SendStatusReports"))
                                        .labelsHidden()
                                }
                            }
                        }
                        .padding(.leading, 16)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingCertificatePicker,
            allowedContentTypes: [.x509Certificate, .pkcs12],
            allowsMultipleSelection: false
        ) { result in
            handleCertificateSelection(result)
        }
        .onAppear {
            updateVPNFields()
            updateAuthenticationFields()
        }
    }
    
    // MARK: - Computed Properties
    
    private var requiresUsername: Bool {
        let authMethod = configuration["AuthenticationMethod"]?.value as? String ?? ""
        return authMethod == "UsernamePassword" || authMethod == "RSASecurID"
    }
    
    private var requiresPassword: Bool {
        let authMethod = configuration["AuthenticationMethod"]?.value as? String ?? ""
        return authMethod == "UsernamePassword"
    }
    
    private var requiresCertificate: Bool {
        let authMethod = configuration["AuthenticationMethod"]?.value as? String ?? ""
        return authMethod == "Certificate"
    }
    
    private var requiresSharedSecret: Bool {
        let authMethod = configuration["AuthenticationMethod"]?.value as? String ?? ""
        return authMethod == "SharedSecret"
    }
    
    // MARK: - Helper Methods
    
    private func updateVPNFields() {
        let vpnType = configuration["VPNType"]?.value as? String ?? ""
        
        // Set default ports based on VPN type
        switch vpnType {
        case "IKEv2":
            configuration["ServerPort"] = CodableValue("500")
        case "L2TP":
            configuration["ServerPort"] = CodableValue("1701")
        case "PPTP":
            configuration["ServerPort"] = CodableValue("1723")
        case "Cisco IPsec":
            configuration["ServerPort"] = CodableValue("500")
        case "OpenVPN":
            configuration["ServerPort"] = CodableValue("1194")
        case "WireGuard":
            configuration["ServerPort"] = CodableValue("51820")
        default:
            configuration["ServerPort"] = CodableValue("")
        }
    }
    
    private func updateAuthenticationFields() {
        let authMethod = configuration["AuthenticationMethod"]?.value as? String ?? ""
        
        // Reset fields based on authentication method
        if authMethod != "UsernamePassword" {
            configuration["Password"] = CodableValue("")
        }
        if authMethod != "Certificate" {
            configuration["ClientCertificatePath"] = CodableValue("")
            configuration["ClientCertificateName"] = CodableValue("")
        }
        if authMethod != "SharedSecret" {
            configuration["SharedSecret"] = CodableValue("")
        }
    }
    
    private func generateSecurePassword() {
        let newPassword = generateSecureVPNPassword()
        configuration["Password"] = CodableValue(newPassword)
    }
    
    private func generateSecureVPNPassword() -> String {
        // Generate a 16-character VPN password with mixed case, numbers, and symbols
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
        return String((0..<16).map { _ in characters.randomElement()! })
    }
    
    private func handleCertificateSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedCertificateURL = url
                configuration["ClientCertificatePath"] = CodableValue(url.path)
                configuration["ClientCertificateName"] = CodableValue(url.lastPathComponent)
            }
        case .failure(let error):
            print("Certificate selection failed: \(error.localizedDescription)")
        }
    }
    
    private func removeCertificate() {
        selectedCertificateURL = nil
        configuration["ClientCertificatePath"] = CodableValue("")
        configuration["ClientCertificateName"] = CodableValue("")
    }
    
    // MARK: - Binding Helpers
    
    private func stringBinding(for key: String) -> Binding<String> {
        Binding(
            get: { (configuration[key]?.value as? String) ?? "" },
            set: { configuration[key] = CodableValue($0) }
        )
    }
    
    private func boolBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: { (configuration[key]?.value as? Bool) ?? false },
            set: { configuration[key] = CodableValue($0) }
        )
    }
}

struct GenericConfigurationView: View {
    let payload: Payload
    @Binding var configuration: [String: CodableValue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration Options")
                .font(.headline)
                .foregroundStyle(LCARSTheme.accent)
            
            Text("Detailed configuration options for \(payload.name) will be implemented in future updates.")
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
            
            // Basic enable/disable toggle
            HStack {
                Text("Enable \(payload.name)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                                        Toggle("", isOn: boolBinding(for: "Enabled"))
                    .labelsHidden()
            }
        }
    }
    
    private func boolBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: { (configuration[key]?.value as? Bool) ?? false },
            set: { configuration[key] = CodableValue($0) }
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
    
    @StateObject private var userSettings = UserSettings()
    @State private var showingExportPanel = false
    @State private var showingDeployPanel = false
    @State private var exportErrorMessage: String?
    @State private var showingExportError = false
    @State private var showingSettings = false
    @State private var selectedMDMAccount: MDMAccount?
    @State private var isDeploying = false
    @State private var deployStatus: String = ""
    
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
                    
                    // MDM Connection Section
                    MDMConnectionSection(
                        userSettings: userSettings,
                        selectedMDMAccount: $selectedMDMAccount,
                        onOpenSettings: {
                            showingSettings = true
                        }
                    )
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button("Export .mobileconfig File") {
                            // Validate profile settings before export
                            if validateProfileSettings() {
                                showingExportPanel = true
                            } else {
                                exportErrorMessage = "Please ensure profile has a name, valid identifier, and at least one payload selected."
                                showingExportError = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(LCARSTheme.accent)
                        .frame(maxWidth: .infinity)
                        
                        Button("Deploy to MDM") {
                            deployToMDM()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(LCARSTheme.accent)
                        .frame(maxWidth: .infinity)
                        .disabled(selectedMDMAccount == nil || isDeploying)
                        
                        if isDeploying {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(deployStatus)
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                            }
                        }
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
        .sheet(isPresented: $showingSettings) {
            SettingsView(userSettings: userSettings)
        }
        .fileExporter(
            isPresented: $showingExportPanel,
            document: ProfileDocument(content: generateProfileContent()),
            contentType: UTType(filenameExtension: "mobileconfig") ?? .data,
            defaultFilename: "\(profileSettings.name).mobileconfig"
        ) { result in
            switch result {
            case .success(let url):
                print("Profile exported successfully to: \(url)")
            case .failure(let error):
                print("Profile export failed: \(error)")
                exportErrorMessage = "Export failed: \(error.localizedDescription)"
                showingExportError = true
            }
        }
        .alert("Export Error", isPresented: $showingExportError) {
            Button("OK") { }
        } message: {
            Text(exportErrorMessage ?? "An unknown error occurred during export.")
        }
    }
    
    private func generateProfileContent() -> String {
        // Generate a safe, basic .mobileconfig content
        let profileName = profileSettings.name.isEmpty ? "MacForge Profile" : profileSettings.name
        let profileDescription = profileSettings.description.isEmpty ? "Generated by MacForge" : profileSettings.description
        let profileIdentifier = profileSettings.identifier.isEmpty ? "com.macforge.profile.\(UUID().uuidString)" : profileSettings.identifier
        let organization = profileSettings.organization.isEmpty ? "MacForge" : profileSettings.organization
        
        // Create a basic but valid .mobileconfig structure
        let profileContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>PayloadContent</key>
            <array>
                <dict>
                    <key>PayloadDescription</key>
                    <string>\(profileDescription)</string>
                    <key>PayloadDisplayName</key>
                    <string>\(profileName)</string>
                    <key>PayloadIdentifier</key>
                    <string>\(profileIdentifier)</string>
                    <key>PayloadType</key>
                    <string>Configuration</string>
                    <key>PayloadUUID</key>
                    <string>\(UUID().uuidString)</string>
                    <key>PayloadVersion</key>
                    <integer>1</integer>
                </dict>
            </array>
            <key>PayloadDescription</key>
            <string>\(profileDescription)</string>
            <key>PayloadDisplayName</key>
            <string>\(profileName)</string>
            <key>PayloadIdentifier</key>
            <string>\(profileIdentifier)</string>
            <key>PayloadOrganization</key>
            <string>\(organization)</string>
            <key>PayloadRemovalDisallowed</key>
            <false/>
            <key>PayloadType</key>
            <string>Configuration</string>
            <key>PayloadUUID</key>
            <string>\(UUID().uuidString)</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
        </plist>
        """
        
        return profileContent
    }
    
    private func validateProfileSettings() -> Bool {
        // Basic validation to prevent crashes
        guard !profileSettings.name.isEmpty,
              !profileSettings.identifier.isEmpty,
              !selectedPayloads.isEmpty else {
            return false
        }
        
        // Ensure identifier is valid format
        guard profileSettings.identifier.contains(".") else {
            return false
        }
        
        return true
    }
    
    private func deployToMDM() {
        guard let selectedAccount = selectedMDMAccount else { return }
        
        isDeploying = true
        deployStatus = "Connecting to \(selectedAccount.displayName)..."
        
        Task {
            do {
                // Check if the selected account has a valid authentication token
                guard let authToken = selectedAccount.authToken else {
                    await MainActor.run {
                        deployStatus = "No authentication token found. Please authenticate in Settings first."
                        isDeploying = false
                    }
                    return
                }
                
                // Check if token is expired
                if let tokenExpiry = selectedAccount.tokenExpiry, tokenExpiry < Date() {
                    await MainActor.run {
                        deployStatus = "Authentication token has expired. Please re-authenticate in Settings."
                        isDeploying = false
                    }
                    return
                }
                
                // Generate the profile content
                let profileContent = generateProfileContent()
                let profileData = Data(profileContent.utf8)
                
                // Create JAMF service instance
                guard let serverURL = URL(string: selectedAccount.serverURL) else {
                    await MainActor.run {
                        deployStatus = "Invalid server URL"
                        isDeploying = false
                    }
                    return
                }
                
                await MainActor.run {
                    deployStatus = "Uploading profile to \(selectedAccount.vendor)..."
                }
                
                // Create JAMF service and deploy the profile
                let jamfService = JAMFService(baseURL: serverURL, token: authToken)
                try await jamfService.uploadOrUpdateProfile(
                    name: profileSettings.name,
                    xmlData: profileData
                )
                
                // Update last used timestamp
                await MainActor.run {
                    userSettings.updateMDMAccountAuth(selectedAccount.id, token: authToken, expiry: selectedAccount.tokenExpiry)
                    deployStatus = "Profile deployed successfully to \(selectedAccount.displayName)!"
                    isDeploying = false
                }
                
            } catch {
                await MainActor.run {
                    deployStatus = "Deployment failed: \(error.localizedDescription)"
                    isDeploying = false
                }
            }
        }
    }
}

// MARK: - MDM Connection Section
struct MDMConnectionSection: View {
    let userSettings: UserSettings
    @Binding var selectedMDMAccount: MDMAccount?
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MDM Deployment")
                .font(.headline)
                .foregroundStyle(LCARSTheme.accent)
            
            if userSettings.mdmAccounts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No MDM accounts configured")
                        .font(.subheadline)
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    Button("Add MDM Account") {
                        onOpenSettings()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                .padding(12)
                .background(LCARSTheme.panel)
                .cornerRadius(8)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select MDM Account")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("MDM Account", selection: $selectedMDMAccount) {
                        Text("Choose an account...").tag(nil as MDMAccount?)
                        ForEach(userSettings.mdmAccounts) { account in
                            Text(account.displayName).tag(account as MDMAccount?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if let selectedAccount = selectedMDMAccount {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Connected to \(selectedAccount.displayName)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Text("Server: \(selectedAccount.serverURL)")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            Text("Vendor: \(selectedAccount.vendor)")
                                .font(.caption)
                                .foregroundStyle(LCARSTheme.textSecondary)
                        }
                        .padding(12)
                        .background(LCARSTheme.panel)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(20)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views
struct SettingsRow: View {
    let label: String
    @Binding var value: String
    let helpText: String?
    let isMonospaced: Bool
    
    init(label: String, value: Binding<String>, helpText: String? = nil, isMonospaced: Bool = false) {
        self.label = label
        self._value = value
        self.helpText = helpText
        self.isMonospaced = isMonospaced
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 120, alignment: .leading)
                
                if let helpText = helpText {
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(LCARSTheme.accent)
                            .font(.caption)
                    }
                    .help(helpText)
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            
            TextField(label, text: $value)
                .textFieldStyle(.roundedBorder)
                .font(isMonospaced ? .system(.body, design: .monospaced) : .body)
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
                    HStack {
                        Text(payload.name)
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.textPrimary)
                        
                        Button(action: {}) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(LCARSTheme.accent)
                                .font(.caption)
                        }
                        .help(payload.description)
                        .buttonStyle(.plain)
                    }
                    
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
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
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
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(LCARSTheme.accent)
                }
                .buttonStyle(.plain)
            }
            
            Text(payload.description)
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
            
            // Configuration Interface
            if isExpanded {
                configurationInterface
            }
        }
        .padding(16)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var configurationInterface: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            
            switch payload.id {
            case "pppc":
                PPPCConfigurationView(configuration: $configuration)
            case "filevault":
                FileVaultConfigurationView(configuration: $configuration)
            case "gatekeeper":
                GatekeeperConfigurationView(configuration: $configuration)
            case "wifi":
                WiFiConfigurationView(configuration: $configuration)
            case "vpn":
                VPNConfigurationView(configuration: $configuration)
            default:
                GenericConfigurationView(payload: payload, configuration: $configuration)
            }
        }
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
    
    @State private var draggedApps: [AppInfo] = []
    @State private var isDragTargeted = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Application Upload")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(LCARSTheme.accent)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(LCARSTheme.accent)
            }
            
            // Instructions
            Text("Drag and drop .app files here to configure PPPC permissions and other app-specific settings. You can also use the file picker below.")
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            // Drop Zone
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDragTargeted ? LCARSTheme.accent.opacity(0.1) : LCARSTheme.panel.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LCARSTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                
                VStack(spacing: 16) {
                    if uploadedApps.isEmpty {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 48))
                            .foregroundStyle(LCARSTheme.accent)
                        
                        Text("Drop Applications Here")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.textPrimary)
                        
                        Text("Drag and drop .app files to configure permissions")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Select Applications") {
                            selectApplications()
                        }
                        .buttonStyle(.bordered)
                        .tint(LCARSTheme.accent)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.green)
                            
                            Text("\(uploadedApps.count) Application(s) Uploaded")
                                .font(.headline)
                                .foregroundStyle(LCARSTheme.textPrimary)
                            
                            Button("Add More Apps") {
                                selectApplications()
                            }
                            .buttonStyle(.bordered)
                            .tint(LCARSTheme.accent)
                        }
                    }
                }
                .padding(32)
            }
            .frame(height: 200)
            .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
                handleAppDrop(providers)
                return true
            }
            
            // Uploaded Apps List
            if !uploadedApps.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Uploaded Applications")
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(uploadedApps) { app in
                                AppInfoCard(app: app)
                                    .contextMenu {
                                        Button("Remove") {
                                            uploadedApps.removeAll { $0.id == app.id }
                                        }
                                        .foregroundStyle(.red)
                                    }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 500, height: 600)
        .background(LCARSTheme.background)
    }
    
    // MARK: - App Selection Helpers
    private func selectApplications() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                handleSelectedApp(url)
            }
        }
    }
    
    private func handleAppDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        self.handleSelectedApp(url)
                    }
                }
            }
        }
    }
    
    private func handleSelectedApp(_ url: URL) {
        // Extract app information
        let appName = url.deletingPathExtension().lastPathComponent
        let bundleID = extractBundleID(from: url) ?? "com.unknown.app"
        
        let appInfo = AppInfo(name: appName, bundleID: bundleID, path: url.path)
        
        // Check if app is already uploaded
        if !uploadedApps.contains(where: { $0.bundleID == bundleID }) {
            uploadedApps.append(appInfo)
        }
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
        // Ensure content is not empty and safely convert to data
        let safeContent = content.isEmpty ? "<?xml version=\"1.0\" encoding=\"UTF-8\"?><plist version=\"1.0\"><dict></dict></plist>" : content
        
        let data = Data(safeContent.utf8)
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
