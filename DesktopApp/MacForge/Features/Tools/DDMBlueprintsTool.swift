import SwiftUI

// MARK: - System Config Button Component
struct SystemConfigButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

/// DDM Blueprints Tool - Device Data Management Blueprint Editor
struct DDMBlueprintsView: View {
    
    // MARK: - State Properties
    
    @StateObject private var blueprintsService = DDMBlueprintsService()
    @State private var selectedBlueprint: DDMBlueprint?
    @State private var showingBlueprintEditor = false
    @State private var showingTemplateLibrary = false
    @State private var showingSearchFilters = false
    @State private var searchText = ""
    @State private var selectedCategory: BlueprintCategory?
    @State private var selectedComplexity: BlueprintComplexity?
    @State private var showingCreateBlueprint = false
    @State private var showingImportBlueprint = false
    @State private var showingExportBlueprint = false
    @State private var showingBlueprintTest = false
    @State private var testResult: BlueprintTestResult?
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            sidebarView
        } detail: {
            // Main Content
            if let blueprint = selectedBlueprint {
                blueprintDetailView(blueprint)
            } else {
                welcomeView
            }
        }
        .navigationTitle("DDM Blueprints")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("New Blueprint") {
                    showingCreateBlueprint = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("Import") {
                    showingImportBlueprint = true
                }
                
                Button("Templates") {
                    showingTemplateLibrary = true
                }
                
                Button("Search") {
                    showingSearchFilters.toggle()
                }
            }
        }
        .sheet(isPresented: $showingCreateBlueprint) {
            BlueprintEditorView(blueprint: nil, service: blueprintsService)
        }
        .sheet(isPresented: $showingTemplateLibrary) {
            TemplateLibraryView(service: blueprintsService)
        }
        .sheet(isPresented: $showingImportBlueprint) {
            BlueprintImportView(service: blueprintsService)
        }
        .sheet(isPresented: $showingBlueprintTest) {
            if let result = testResult {
                BlueprintTestResultView(result: result)
            }
        }
        .searchable(text: $searchText, prompt: "Search blueprints...")
        .onChange(of: searchText) { _, newValue in
            performSearch()
        }
    }
    
    // MARK: - Sidebar View
    
    private var sidebarView: some View {
        List(selection: $selectedBlueprint) {
            // Quick Access Section
            Section("Quick Access") {
                Button("All Blueprints") {
                    selectedBlueprint = nil
                }
                Button("My Blueprints") {
                    selectedBlueprint = nil
                }
                Button("Templates") {
                    selectedBlueprint = nil
                }
                Button("Recent") {
                    selectedBlueprint = nil
                }
            }
            
            // Categories Section
            Section("Categories") {
                ForEach(BlueprintCategory.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        Label(category.rawValue, systemImage: category.icon)
                    }
                }
            }
            
            // Blueprints List
            Section("Blueprints") {
                ForEach(blueprintsService.blueprints) { blueprint in
                    NavigationLink(value: blueprint) {
                        BlueprintRowView(blueprint: blueprint)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Blueprints")
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("DDM Blueprints")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Device Configuration & System Management")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // System Configuration Tools
            VStack(spacing: 16) {
                Text("System Configuration Tools")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    SystemConfigButton(
                        title: "Device Management",
                        description: "Configure device settings and policies",
                        icon: "laptopcomputer",
                        color: .blue
                    ) {
                        // TODO: Implement device management
                    }
                    
                    SystemConfigButton(
                        title: "Security Policies",
                        description: "Set up security and compliance rules",
                        icon: "shield.fill",
                        color: .red
                    ) {
                        // TODO: Implement security policies
                    }
                    
                    SystemConfigButton(
                        title: "Network Configuration",
                        description: "Wi-Fi, VPN, and network settings",
                        icon: "wifi",
                        color: .green
                    ) {
                        // TODO: Implement network configuration
                    }
                    
                    SystemConfigButton(
                        title: "Application Management",
                        description: "App deployment and restrictions",
                        icon: "app.fill",
                        color: .orange
                    ) {
                        // TODO: Implement application management
                    }
                    
                    SystemConfigButton(
                        title: "User Experience",
                        description: "Customize user interface and settings",
                        icon: "person.fill",
                        color: .purple
                    ) {
                        // TODO: Implement user experience
                    }
                    
                    SystemConfigButton(
                        title: "Compliance Rules",
                        description: "Set up compliance and monitoring",
                        icon: "checkmark.shield.fill",
                        color: .teal
                    ) {
                        // TODO: Implement compliance rules
                    }
                }
            }
            .padding(.horizontal)
            
            // Quick Actions
            VStack(spacing: 12) {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    Button("Create Blueprint") {
                        showingCreateBlueprint = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Browse Templates") {
                        showingTemplateLibrary = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Import Blueprint") {
                        showingImportBlueprint = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LCARSTheme.background)
    }
    
    // MARK: - Blueprint Detail View
    
    private func blueprintDetailView(_ blueprint: DDMBlueprint) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                blueprintHeaderView(blueprint)
                
                // Configuration Sections
                LazyVStack(spacing: 16) {
                    ConfigurationSectionView(
                        title: "Device Settings",
                        icon: "laptopcomputer",
                        color: .blue
                    ) {
                        DeviceSettingsView(settings: blueprint.configuration.deviceSettings)
                    }
                    
                    ConfigurationSectionView(
                        title: "Security Policies",
                        icon: "lock.shield",
                        color: .red
                    ) {
                        SecurityPoliciesView(policies: blueprint.configuration.securityPolicies)
                    }
                    
                    ConfigurationSectionView(
                        title: "Network Configuration",
                        icon: "network",
                        color: .green
                    ) {
                        NetworkConfigurationView(config: blueprint.configuration.networkConfigurations)
                    }
                    
                    ConfigurationSectionView(
                        title: "Application Settings",
                        icon: "app.badge",
                        color: .purple
                    ) {
                        ApplicationSettingsView(settings: blueprint.configuration.applicationSettings)
                    }
                    
                    ConfigurationSectionView(
                        title: "User Preferences",
                        icon: "person.crop.circle",
                        color: .orange
                    ) {
                        UserPreferencesView(preferences: blueprint.configuration.userPreferences)
                    }
                    
                    ConfigurationSectionView(
                        title: "Compliance Rules",
                        icon: "checkmark.shield",
                        color: .indigo
                    ) {
                        ComplianceRulesView(rules: blueprint.configuration.complianceRules)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(blueprint.name)

        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Edit") {
                    showingCreateBlueprint = true
                }
                
                Button("Test") {
                    Task {
                        do {
                            testResult = try await blueprintsService.testBlueprint(blueprint)
                            showingBlueprintTest = true
                        } catch {
                            // Handle error
                        }
                    }
                }
                
                Button("Export") {
                    showingExportBlueprint = true
                }
                
                Menu {
                    Button("Duplicate") {
                        // Duplicate blueprint
                    }
                    
                    Button("Clone Template") {
                        // Clone as template
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        // Delete blueprint
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: - Blueprint Header View
    
    private func blueprintHeaderView(_ blueprint: DDMBlueprint) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(blueprint.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(blueprint.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Label(blueprint.category.rawValue, systemImage: blueprint.category.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("v\(blueprint.version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Tags
            if !blueprint.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(blueprint.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.quaternary)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // Metadata
            HStack(spacing: 20) {
                Label("\(blueprint.metadata.complexity.rawValue)", systemImage: "chart.bar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(blueprint.metadata.estimatedDeploymentTime) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if blueprint.metadata.ratings.totalRatings > 0 {
                    Label("\(String(format: "%.1f", blueprint.metadata.ratings.averageRating)) ⭐", systemImage: "star")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("By \(blueprint.author)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func performSearch() {
        var criteria = BlueprintSearchCriteria()
        criteria.query = searchText
        
        if let category = selectedCategory {
            criteria.categories = [category]
        }
        
        if let complexity = selectedComplexity {
            criteria.complexity = [complexity]
        }
        
        blueprintsService.searchBlueprints(criteria)
    }
}

// MARK: - Blueprint Row View

struct BlueprintRowView: View {
    let blueprint: DDMBlueprint
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(blueprint.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(blueprint.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(blueprint.category.rawValue, systemImage: blueprint.category.icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if blueprint.metadata.ratings.totalRatings > 0 {
                        Text("\(String(format: "%.1f", blueprint.metadata.ratings.averageRating)) ⭐")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                if blueprint.isTemplate {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.blue)
                }
                
                if blueprint.isPublic {
                    Image(systemName: "globe")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Configuration Section View

struct ConfigurationSectionView<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content()
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Device Settings View

struct DeviceSettingsView: View {
    let settings: DeviceSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let deviceName = settings.deviceName {
                BlueprintInfoRow(label: "Device Name", value: deviceName)
            }
            
            if let location = settings.location {
                BlueprintInfoRow(label: "Location", value: location)
            }
            
            if let department = settings.department {
                BlueprintInfoRow(label: "Department", value: department)
            }
            
            if let user = settings.user {
                BlueprintInfoRow(label: "User", value: user)
            }
            
            if !settings.customFields.isEmpty {
                Text("Custom Fields")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(Array(settings.customFields.keys.sorted()), id: \.self) { key in
                    BlueprintInfoRow(label: key, value: settings.customFields[key] ?? "")
                }
            }
        }
    }
}

// MARK: - Security Policies View

struct SecurityPoliciesView: View {
    let policies: SecurityPolicies
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BlueprintInfoRow(label: "Passcode Required", value: policies.passcodePolicy.requirePasscode ? "Yes" : "No")
            BlueprintInfoRow(label: "Minimum Length", value: "\(policies.passcodePolicy.minimumLength) characters")
            BlueprintInfoRow(label: "Complexity Required", value: policies.passcodePolicy.requireComplexity ? "Yes" : "No")
            BlueprintInfoRow(label: "FileVault Required", value: policies.encryptionSettings.requireFileVault ? "Yes" : "No")
            BlueprintInfoRow(label: "Firewall Enabled", value: policies.firewallRules.enableFirewall ? "Yes" : "No")
            BlueprintInfoRow(label: "VPN Enabled", value: policies.vpnConfiguration.enabled ? "Yes" : "No")
        }
    }
}

// MARK: - Network Configuration View

struct NetworkConfigurationView: View {
    let config: NetworkConfigurations
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BlueprintInfoRow(label: "Auto Join WiFi", value: config.wifiSettings.autoJoin ? "Yes" : "No")
            BlueprintInfoRow(label: "WiFi Networks", value: "\(config.wifiSettings.networks.count) configured")
            BlueprintInfoRow(label: "Proxy Enabled", value: config.proxySettings.enabled ? "Yes" : "No")
            BlueprintInfoRow(label: "DNS Servers", value: "\(config.dnsSettings.servers.count) configured")
        }
    }
}

// MARK: - Application Settings View

struct ApplicationSettingsView: View {
    let settings: ApplicationSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BlueprintInfoRow(label: "Allowed Apps", value: "\(settings.allowedApplications.count)")
            BlueprintInfoRow(label: "Blocked Apps", value: "\(settings.blockedApplications.count)")
            BlueprintInfoRow(label: "Required Apps", value: "\(settings.requiredApplications.count)")
            BlueprintInfoRow(label: "App Store Allowed", value: settings.appStoreSettings.allowAppStore ? "Yes" : "No")
        }
    }
}

// MARK: - User Preferences View

struct UserPreferencesView: View {
    let preferences: UserPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BlueprintInfoRow(label: "Dock Position", value: preferences.dockSettings.position.rawValue)
            BlueprintInfoRow(label: "Dock Size", value: "\(preferences.dockSettings.size)")
            BlueprintInfoRow(label: "System Preferences", value: preferences.systemPreferences.allowSystemPreferences ? "Allowed" : "Blocked")
            BlueprintInfoRow(label: "Accessibility", value: preferences.accessibilitySettings.voiceOver ? "Enabled" : "Disabled")
        }
    }
}

// MARK: - Compliance Rules View

struct ComplianceRulesView: View {
    let rules: ComplianceRules
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BlueprintInfoRow(label: "Device Rules", value: "\(rules.deviceCompliance.count)")
            BlueprintInfoRow(label: "Application Rules", value: "\(rules.applicationCompliance.count)")
            BlueprintInfoRow(label: "Network Rules", value: "\(rules.networkCompliance.count)")
            BlueprintInfoRow(label: "Security Rules", value: "\(rules.securityCompliance.count)")
        }
    }
}

// MARK: - Info Row View

struct BlueprintInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    DDMBlueprintsView()
}
