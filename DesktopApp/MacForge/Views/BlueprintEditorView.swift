import SwiftUI

/// Blueprint Editor View for creating and editing DDM Blueprints
struct BlueprintEditorView: View {
    
    // MARK: - Properties
    
    let blueprint: DDMBlueprint?
    let service: DDMBlueprintsService
    
    @Environment(\.dismiss) private var dismiss
    @State private var editedBlueprint: DDMBlueprint
    @State private var showingValidation = false
    @State private var validationResult: BlueprintValidationResult?
    @State private var isSaving = false
    @State private var showingTestResult = false
    @State private var testResult: BlueprintTestResult?
    @State private var selectedTab = 0
    
    // MARK: - Initialization
    
    init(blueprint: DDMBlueprint?, service: DDMBlueprintsService) {
        self.blueprint = blueprint
        self.service = service
        
        if let blueprint = blueprint {
            self._editedBlueprint = State(initialValue: blueprint)
        } else {
            self._editedBlueprint = State(initialValue: DDMBlueprint(
                name: "New Blueprint",
                description: "",
                category: .deviceManagement
            ))
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                blueprintHeaderView
                
                // Tab View
                TabView(selection: $selectedTab) {
                    // Basic Information
                    basicInfoView
                        .tabItem {
                            Label("Basic", systemImage: "info.circle")
                        }
                        .tag(0)
                    
                    // Device Settings
                    deviceSettingsView
                        .tabItem {
                            Label("Device", systemImage: "laptopcomputer")
                        }
                        .tag(1)
                    
                    // Security Policies
                    securityPoliciesView
                        .tabItem {
                            Label("Security", systemImage: "lock.shield")
                        }
                        .tag(2)
                    
                    // Network Configuration
                    networkConfigurationView
                        .tabItem {
                            Label("Network", systemImage: "network")
                        }
                        .tag(3)
                    
                    // Application Settings
                    applicationSettingsView
                        .tabItem {
                            Label("Apps", systemImage: "app.badge")
                        }
                        .tag(4)
                    
                    // User Preferences
                    userPreferencesView
                        .tabItem {
                            Label("User", systemImage: "person.crop.circle")
                        }
                        .tag(5)
                    
                    // Compliance Rules
                    complianceRulesView
                        .tabItem {
                            Label("Compliance", systemImage: "checkmark.shield")
                        }
                        .tag(6)
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle(blueprint == nil ? "New Blueprint" : "Edit Blueprint")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Validate") {
                        validateBlueprint()
                    }
                    
                    Button("Test") {
                        testBlueprint()
                    }
                    
                    Button("Save") {
                        saveBlueprint()
                    }
                    .disabled(isSaving)
                }
            }
        }
        .sheet(isPresented: $showingValidation) {
            if let result = validationResult {
                BlueprintValidationView(result: result)
            }
        }
        .sheet(isPresented: $showingTestResult) {
            if let result = testResult {
                BlueprintTestResultView(result: result)
            }
        }
    }
    
    // MARK: - Blueprint Header View
    
    private var blueprintHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Blueprint Name", text: $editedBlueprint.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    TextField("Description", text: $editedBlueprint.description, axis: .vertical)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2...4)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Picker("Category", selection: $editedBlueprint.category) {
                        ForEach(BlueprintCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Toggle("Template", isOn: $editedBlueprint.isTemplate)
                        .toggleStyle(.switch)
                    
                    Toggle("Public", isOn: $editedBlueprint.isPublic)
                        .toggleStyle(.switch)
                }
            }
            
            // Tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)
                
                TagEditorView(tags: $editedBlueprint.tags)
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Basic Info View
    
    private var basicInfoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Version Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Version Information")
                        .font(.headline)
                    
                    HStack {
                        TextField("Version", text: $editedBlueprint.version)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Author", text: $editedBlueprint.author)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 12) {
                    Text("Metadata")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Complexity", selection: $editedBlueprint.metadata.complexity) {
                            ForEach(BlueprintComplexity.allCases, id: \.self) { complexity in
                                Text(complexity.rawValue).tag(complexity)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        HStack {
                            Text("Estimated Deployment Time:")
                            Spacer()
                            TextField("Minutes", value: $editedBlueprint.metadata.estimatedDeploymentTime, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                }
                
                // Compatibility
                VStack(alignment: .leading, spacing: 12) {
                    Text("Compatibility")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Minimum OS Version", text: $editedBlueprint.metadata.compatibility.minimumOSVersion)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Maximum OS Version", text: Binding(
                                get: { editedBlueprint.metadata.compatibility.maximumOSVersion ?? "" },
                                set: { editedBlueprint.metadata.compatibility.maximumOSVersion = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        
                        Text("Supported Architectures")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                            ForEach(["arm64", "x86_64"], id: \.self) { arch in
                                HStack {
                                    Image(systemName: editedBlueprint.metadata.compatibility.supportedArchitectures.contains(arch) ? "checkmark.square.fill" : "square")
                                        .foregroundStyle(editedBlueprint.metadata.compatibility.supportedArchitectures.contains(arch) ? .green : .secondary)
                                    
                                    Text(arch)
                                        .font(.caption)
                                    
                                    Spacer()
                                }
                                .onTapGesture {
                                    toggleArchitecture(arch)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Device Settings View
    
    private var deviceSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Device Information")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        TextField("Device Name", text: Binding(
                            get: { editedBlueprint.configuration.deviceSettings.deviceName ?? "" },
                            set: { editedBlueprint.configuration.deviceSettings.deviceName = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        TextField("Device Model", text: Binding(
                            get: { editedBlueprint.configuration.deviceSettings.deviceModel ?? "" },
                            set: { editedBlueprint.configuration.deviceSettings.deviceModel = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        TextField("Serial Number", text: Binding(
                            get: { editedBlueprint.configuration.deviceSettings.serialNumber ?? "" },
                            set: { editedBlueprint.configuration.deviceSettings.serialNumber = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        TextField("Asset Tag", text: Binding(
                            get: { editedBlueprint.configuration.deviceSettings.assetTag ?? "" },
                            set: { editedBlueprint.configuration.deviceSettings.assetTag = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location & Organization")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        TextField("Location", text: Binding(
                            get: { editedBlueprint.configuration.deviceSettings.location ?? "" },
                            set: { editedBlueprint.configuration.deviceSettings.location = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        TextField("Department", text: Binding(
                            get: { editedBlueprint.configuration.deviceSettings.department ?? "" },
                            set: { editedBlueprint.configuration.deviceSettings.department = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        TextField("User", text: Binding(
                            get: { editedBlueprint.configuration.deviceSettings.user ?? "" },
                            set: { editedBlueprint.configuration.deviceSettings.user = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Fields")
                        .font(.headline)
                    
                    CustomFieldsView(fields: $editedBlueprint.configuration.deviceSettings.customFields)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Security Policies View
    
    private var securityPoliciesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Passcode Policy
                VStack(alignment: .leading, spacing: 12) {
                    Text("Passcode Policy")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle("Require Passcode", isOn: $editedBlueprint.configuration.securityPolicies.passcodePolicy.requirePasscode)
                        
                        if editedBlueprint.configuration.securityPolicies.passcodePolicy.requirePasscode {
                            HStack {
                                Text("Minimum Length:")
                                Spacer()
                                TextField("Length", value: $editedBlueprint.configuration.securityPolicies.passcodePolicy.minimumLength, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }
                            
                            Toggle("Require Complexity", isOn: $editedBlueprint.configuration.securityPolicies.passcodePolicy.requireComplexity)
                            
                            HStack {
                                Text("Max Failed Attempts:")
                                Spacer()
                                TextField("Attempts", value: $editedBlueprint.configuration.securityPolicies.passcodePolicy.maximumFailedAttempts, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }
                            
                            HStack {
                                Text("Lockout Duration (min):")
                                Spacer()
                                TextField("Minutes", value: $editedBlueprint.configuration.securityPolicies.passcodePolicy.lockoutDuration, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }
                            
                            Toggle("Require Biometric", isOn: $editedBlueprint.configuration.securityPolicies.passcodePolicy.requireBiometric)
                            Toggle("Allow Simple Passcode", isOn: $editedBlueprint.configuration.securityPolicies.passcodePolicy.allowSimplePasscode)
                        }
                    }
                }
                
                // Encryption Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Encryption Settings")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle("Require FileVault", isOn: $editedBlueprint.configuration.securityPolicies.encryptionSettings.requireFileVault)
                        Toggle("Require Data Protection", isOn: $editedBlueprint.configuration.securityPolicies.encryptionSettings.requireDataProtection)
                        
                        Picker("Encryption Level", selection: $editedBlueprint.configuration.securityPolicies.encryptionSettings.encryptionLevel) {
                            ForEach(EncryptionLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Toggle("Key Recovery Enabled", isOn: $editedBlueprint.configuration.securityPolicies.encryptionSettings.keyRecoveryEnabled)
                    }
                }
                
                // Firewall Rules
                VStack(alignment: .leading, spacing: 12) {
                    Text("Firewall Rules")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle("Enable Firewall", isOn: $editedBlueprint.configuration.securityPolicies.firewallRules.enableFirewall)
                        
                        if editedBlueprint.configuration.securityPolicies.firewallRules.enableFirewall {
                            Toggle("Block Incoming Connections", isOn: $editedBlueprint.configuration.securityPolicies.firewallRules.blockIncomingConnections)
                            Toggle("Allow Signed Applications", isOn: $editedBlueprint.configuration.securityPolicies.firewallRules.allowSignedApplications)
                            Toggle("Stealth Mode", isOn: $editedBlueprint.configuration.securityPolicies.firewallRules.stealthMode)
                        }
                    }
                }
                
                // VPN Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Text("VPN Configuration")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle("Enable VPN", isOn: $editedBlueprint.configuration.securityPolicies.vpnConfiguration.enabled)
                        
                        if editedBlueprint.configuration.securityPolicies.vpnConfiguration.enabled {
                            TextField("Connection Name", text: Binding(
                                get: { editedBlueprint.configuration.securityPolicies.vpnConfiguration.connectionName ?? "" },
                                set: { editedBlueprint.configuration.securityPolicies.vpnConfiguration.connectionName = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            TextField("Server Address", text: Binding(
                                get: { editedBlueprint.configuration.securityPolicies.vpnConfiguration.serverAddress ?? "" },
                                set: { editedBlueprint.configuration.securityPolicies.vpnConfiguration.serverAddress = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            Picker("Authentication Method", selection: $editedBlueprint.configuration.securityPolicies.vpnConfiguration.authenticationMethod) {
                                ForEach(VPNAuthenticationMethod.allCases, id: \.self) { method in
                                    Text(method.rawValue).tag(method)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Toggle("On Demand", isOn: $editedBlueprint.configuration.securityPolicies.vpnConfiguration.onDemand)
                            Toggle("Split Tunnel", isOn: $editedBlueprint.configuration.securityPolicies.vpnConfiguration.splitTunnel)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Network Configuration View
    
    private var networkConfigurationView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // WiFi Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("WiFi Settings")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle("Auto Join", isOn: $editedBlueprint.configuration.networkConfigurations.wifiSettings.autoJoin)
                        
                        Text("WiFi Networks")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        WiFiNetworksView(networks: $editedBlueprint.configuration.networkConfigurations.wifiSettings.networks)
                    }
                }
                
                // Ethernet Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ethernet Settings")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle("Auto Configure", isOn: $editedBlueprint.configuration.networkConfigurations.ethernetSettings.autoConfigure)
                        
                        if !editedBlueprint.configuration.networkConfigurations.ethernetSettings.autoConfigure {
                            TextField("IP Address", text: Binding(
                                get: { editedBlueprint.configuration.networkConfigurations.ethernetSettings.ipAddress ?? "" },
                                set: { editedBlueprint.configuration.networkConfigurations.ethernetSettings.ipAddress = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            TextField("Subnet Mask", text: Binding(
                                get: { editedBlueprint.configuration.networkConfigurations.ethernetSettings.subnetMask ?? "" },
                                set: { editedBlueprint.configuration.networkConfigurations.ethernetSettings.subnetMask = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            TextField("Router", text: Binding(
                                get: { editedBlueprint.configuration.networkConfigurations.ethernetSettings.router ?? "" },
                                set: { editedBlueprint.configuration.networkConfigurations.ethernetSettings.router = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                
                // Proxy Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Proxy Settings")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle("Enable Proxy", isOn: $editedBlueprint.configuration.networkConfigurations.proxySettings.enabled)
                        
                        if editedBlueprint.configuration.networkConfigurations.proxySettings.enabled {
                            Picker("Proxy Type", selection: $editedBlueprint.configuration.networkConfigurations.proxySettings.type) {
                                ForEach(ProxyType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            TextField("Server", text: Binding(
                                get: { editedBlueprint.configuration.networkConfigurations.proxySettings.server ?? "" },
                                set: { editedBlueprint.configuration.networkConfigurations.proxySettings.server = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            HStack {
                                TextField("Port", value: Binding(
                                    get: { editedBlueprint.configuration.networkConfigurations.proxySettings.port ?? 8080 },
                                    set: { editedBlueprint.configuration.networkConfigurations.proxySettings.port = $0 }
                                ), format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // DNS Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("DNS Settings")
                        .font(.headline)
                    
                    DNSServersView(servers: $editedBlueprint.configuration.networkConfigurations.dnsSettings.servers)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Application Settings View
    
    private var applicationSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Application Lists
                VStack(alignment: .leading, spacing: 12) {
                    Text("Application Management")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        ApplicationListEditor(
                            title: "Allowed Applications",
                            applications: $editedBlueprint.configuration.applicationSettings.allowedApplications
                        )
                        
                        ApplicationListEditor(
                            title: "Blocked Applications",
                            applications: $editedBlueprint.configuration.applicationSettings.blockedApplications
                        )
                        
                        ApplicationListEditor(
                            title: "Required Applications",
                            applications: $editedBlueprint.configuration.applicationSettings.requiredApplications
                        )
                    }
                }
                
                // App Store Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("App Store Settings")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle("Allow App Store", isOn: $editedBlueprint.configuration.applicationSettings.appStoreSettings.allowAppStore)
                        Toggle("Allow In-App Purchases", isOn: $editedBlueprint.configuration.applicationSettings.appStoreSettings.allowInAppPurchases)
                        Toggle("Require Password", isOn: $editedBlueprint.configuration.applicationSettings.appStoreSettings.requirePassword)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - User Preferences View
    
    private var userPreferencesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Desktop Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Desktop Settings")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        TextField("Wallpaper", text: Binding(
                            get: { editedBlueprint.configuration.userPreferences.desktopSettings.wallpaper ?? "" },
                            set: { editedBlueprint.configuration.userPreferences.desktopSettings.wallpaper = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Text("Screen Saver Timeout (min):")
                            Spacer()
                            TextField("Minutes", value: $editedBlueprint.configuration.userPreferences.desktopSettings.screenSaverTimeout, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        Toggle("Show Desktop Icons", isOn: $editedBlueprint.configuration.userPreferences.desktopSettings.showDesktopIcons)
                        
                        HStack {
                            Text("Icon Size:")
                            Spacer()
                            TextField("Size", value: $editedBlueprint.configuration.userPreferences.desktopSettings.iconSize, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                }
                
                // Dock Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dock Settings")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Picker("Position", selection: $editedBlueprint.configuration.userPreferences.dockSettings.position) {
                            ForEach(DockPosition.allCases, id: \.self) { position in
                                Text(position.rawValue).tag(position)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        HStack {
                            Text("Size:")
                            Spacer()
                            TextField("Size", value: $editedBlueprint.configuration.userPreferences.dockSettings.size, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        Toggle("Magnification", isOn: $editedBlueprint.configuration.userPreferences.dockSettings.magnification)
                        
                        if editedBlueprint.configuration.userPreferences.dockSettings.magnification {
                            HStack {
                                Text("Magnification Size:")
                                Spacer()
                                TextField("Size", value: $editedBlueprint.configuration.userPreferences.dockSettings.magnificationSize, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }
                        }
                        
                        Picker("Minimize Effect", selection: $editedBlueprint.configuration.userPreferences.dockSettings.minimizeEffect) {
                            ForEach(MinimizeEffect.allCases, id: \.self) { effect in
                                Text(effect.rawValue).tag(effect)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Toggle("Show Recent Applications", isOn: $editedBlueprint.configuration.userPreferences.dockSettings.showRecentApplications)
                    }
                }
                
                // System Preferences
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Preferences")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle("Allow System Preferences", isOn: $editedBlueprint.configuration.userPreferences.systemPreferences.allowSystemPreferences)
                        Toggle("Require Password", isOn: $editedBlueprint.configuration.userPreferences.systemPreferences.requirePassword)
                    }
                }
                
                // Accessibility Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Accessibility Settings")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle("VoiceOver", isOn: $editedBlueprint.configuration.userPreferences.accessibilitySettings.voiceOver)
                        Toggle("Zoom", isOn: $editedBlueprint.configuration.userPreferences.accessibilitySettings.zoom)
                        Toggle("High Contrast", isOn: $editedBlueprint.configuration.userPreferences.accessibilitySettings.highContrast)
                        Toggle("Reduce Motion", isOn: $editedBlueprint.configuration.userPreferences.accessibilitySettings.reduceMotion)
                        Toggle("Increase Contrast", isOn: $editedBlueprint.configuration.userPreferences.accessibilitySettings.increaseContrast)
                        Toggle("Reduce Transparency", isOn: $editedBlueprint.configuration.userPreferences.accessibilitySettings.reduceTransparency)
                        Toggle("Large Text", isOn: $editedBlueprint.configuration.userPreferences.accessibilitySettings.largeText)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Compliance Rules View
    
    private var complianceRulesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Compliance Rules")
                    .font(.headline)
                
                Text("Compliance rules help ensure devices meet organizational standards and regulatory requirements.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 16) {
                    ComplianceRulesSectionView(
                        title: "Device Compliance",
                        rules: $editedBlueprint.configuration.complianceRules.deviceCompliance
                    )
                    
                    ComplianceRulesSectionView(
                        title: "Application Compliance",
                        rules: $editedBlueprint.configuration.complianceRules.applicationCompliance
                    )
                    
                    ComplianceRulesSectionView(
                        title: "Network Compliance",
                        rules: $editedBlueprint.configuration.complianceRules.networkCompliance
                    )
                    
                    ComplianceRulesSectionView(
                        title: "Security Compliance",
                        rules: $editedBlueprint.configuration.complianceRules.securityCompliance
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleArchitecture(_ architecture: String) {
        if editedBlueprint.metadata.compatibility.supportedArchitectures.contains(architecture) {
            editedBlueprint.metadata.compatibility.supportedArchitectures.removeAll { $0 == architecture }
        } else {
            editedBlueprint.metadata.compatibility.supportedArchitectures.append(architecture)
        }
    }
    
    private func validateBlueprint() {
        validationResult = service.validateBlueprint(editedBlueprint)
        showingValidation = true
    }
    
    private func testBlueprint() {
        Task {
            do {
                testResult = try await service.testBlueprint(editedBlueprint)
                showingTestResult = true
            } catch {
                // Handle error
            }
        }
    }
    
    private func saveBlueprint() {
        isSaving = true
        
        Task {
            do {
                if blueprint == nil {
                    try await service.createBlueprint(editedBlueprint)
                } else {
                    try await service.updateBlueprint(editedBlueprint)
                }
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    // Handle error
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TagEditorView: View {
    @Binding var tags: [String]
    @State private var newTag = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addTag()
                    }
                
                Button("Add") {
                    addTag()
                }
                .disabled(newTag.isEmpty)
            }
            
            if !tags.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .font(.caption)
                            
                            Button {
                                removeTag(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

struct CustomFieldsView: View {
    @Binding var fields: [String: String]
    @State private var newKey = ""
    @State private var newValue = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Key", text: $newKey)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Value", text: $newValue)
                    .textFieldStyle(.roundedBorder)
                
                Button("Add") {
                    addField()
                }
                .disabled(newKey.isEmpty || newValue.isEmpty)
            }
            
            if !fields.isEmpty {
                ForEach(Array(fields.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(fields[key] ?? "")
                            .font(.caption)
                        
                        Button {
                            removeField(key)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func addField() {
        let trimmedKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedKey.isEmpty && !trimmedValue.isEmpty {
            fields[trimmedKey] = trimmedValue
            newKey = ""
            newValue = ""
        }
    }
    
    private func removeField(_ key: String) {
        fields.removeValue(forKey: key)
    }
}

struct WiFiNetworksView: View {
    @Binding var networks: [WiFiNetwork]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(networks) { network in
                WiFiNetworkRowView(network: network)
            }
            
            Button("Add Network") {
                addNetwork()
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func addNetwork() {
        let newNetwork = WiFiNetwork(ssid: "New Network", securityType: .wpa2)
        networks.append(newNetwork)
    }
}

struct WiFiNetworkRowView: View {
    let network: WiFiNetwork
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(network.ssid)
                    .font(.headline)
                
                Text(network.securityType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Edit") {
                // Edit network
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(8)
    }
}

struct DNSServersView: View {
    @Binding var servers: [String]
    @State private var newServer = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("DNS Server", text: $newServer)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addServer()
                    }
                
                Button("Add") {
                    addServer()
                }
                .disabled(newServer.isEmpty)
            }
            
            if !servers.isEmpty {
                ForEach(servers, id: \.self) { server in
                    HStack {
                        Text(server)
                            .font(.caption)
                        
                        Spacer()
                        
                        Button {
                            removeServer(server)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func addServer() {
        let trimmedServer = newServer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedServer.isEmpty && !servers.contains(trimmedServer) {
            servers.append(trimmedServer)
            newServer = ""
        }
    }
    
    private func removeServer(_ server: String) {
        servers.removeAll { $0 == server }
    }
}

struct ApplicationListEditor: View {
    let title: String
    @Binding var applications: [String]
    @State private var newApplication = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                TextField("Application Name", text: $newApplication)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addApplication()
                    }
                
                Button("Add") {
                    addApplication()
                }
                .disabled(newApplication.isEmpty)
            }
            
            if !applications.isEmpty {
                ForEach(applications, id: \.self) { application in
                    HStack {
                        Text(application)
                            .font(.caption)
                        
                        Spacer()
                        
                        Button {
                            removeApplication(application)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func addApplication() {
        let trimmedApp = newApplication.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedApp.isEmpty && !applications.contains(trimmedApp) {
            applications.append(trimmedApp)
            newApplication = ""
        }
    }
    
    private func removeApplication(_ application: String) {
        applications.removeAll { $0 == application }
    }
}

struct ComplianceRulesSectionView: View {
    let title: String
    @Binding var rules: [ComplianceRule]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(rules.count) rules")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !rules.isEmpty {
                ForEach(rules) { rule in
                    ComplianceRuleRowView(rule: rule)
                }
            }
            
            Button("Add Rule") {
                addRule()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(8)
    }
    
    private func addRule() {
        let newRule = ComplianceRule(
            name: "New Rule",
            description: "",
            category: .device,
            severity: .medium,
            condition: ComplianceCondition(
                type: .deviceProperty,
                parameter: "",
                operator: .equals,
                value: ""
            ),
            action: ComplianceAction(type: .notify)
        )
        rules.append(newRule)
    }
}

struct ComplianceRuleRowView: View {
    let rule: ComplianceRule
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.name)
                    .font(.headline)
                
                Text(rule.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text(rule.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(rule.severity.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Button("Edit") {
                // Edit rule
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    BlueprintEditorView(blueprint: nil, service: DDMBlueprintsService())
}
