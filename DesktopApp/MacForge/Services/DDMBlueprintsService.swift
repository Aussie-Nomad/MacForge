import Foundation
import Combine

/// Service for managing DDM Blueprints
@MainActor
class DDMBlueprintsService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var blueprints: [DDMBlueprint] = []
    @Published var templates: [DDMBlueprint] = []
    @Published var userBlueprints: [DDMBlueprint] = []
    @Published var library: BlueprintLibrary = BlueprintLibrary()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [DDMBlueprint] = []
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let blueprintsDirectory: URL
    private let templatesDirectory: URL
    
    // MARK: - Initialization
    
    init() {
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.blueprintsDirectory = documentsDirectory.appendingPathComponent("DDMBlueprints")
        self.templatesDirectory = documentsDirectory.appendingPathComponent("DDMTemplates")
        
        setupDirectories()
        loadBlueprints()
        loadDefaultTemplates()
    }
    
    // MARK: - Directory Setup
    
    private func setupDirectories() {
        try? fileManager.createDirectory(at: blueprintsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: templatesDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Blueprint Management
    
    /// Create a new blueprint
    func createBlueprint(_ blueprint: DDMBlueprint) async throws {
        isLoading = true
        defer { isLoading = false }
        
        var newBlueprint = blueprint
        newBlueprint.updatedAt = Date()
        
        if newBlueprint.isTemplate {
            templates.append(newBlueprint)
            try await saveTemplates()
        } else {
            userBlueprints.append(newBlueprint)
            try await saveUserBlueprints()
        }
        
        blueprints = templates + userBlueprints
        updateLibrary()
    }
    
    /// Update an existing blueprint
    func updateBlueprint(_ blueprint: DDMBlueprint) async throws {
        isLoading = true
        defer { isLoading = false }
        
        var updatedBlueprint = blueprint
        updatedBlueprint.updatedAt = Date()
        
        if updatedBlueprint.isTemplate {
            if let index = templates.firstIndex(where: { $0.id == blueprint.id }) {
                templates[index] = updatedBlueprint
                try await saveTemplates()
            }
        } else {
            if let index = userBlueprints.firstIndex(where: { $0.id == blueprint.id }) {
                userBlueprints[index] = updatedBlueprint
                try await saveUserBlueprints()
            }
        }
        
        blueprints = templates + userBlueprints
        updateLibrary()
    }
    
    /// Delete a blueprint
    func deleteBlueprint(_ blueprint: DDMBlueprint) async throws {
        isLoading = true
        defer { isLoading = false }
        
        if blueprint.isTemplate {
            templates.removeAll { $0.id == blueprint.id }
            try await saveTemplates()
        } else {
            userBlueprints.removeAll { $0.id == blueprint.id }
            try await saveUserBlueprints()
        }
        
        blueprints = templates + userBlueprints
        updateLibrary()
    }
    
    /// Duplicate a blueprint
    func duplicateBlueprint(_ blueprint: DDMBlueprint, newName: String) async throws {
        var duplicatedBlueprint = blueprint
        duplicatedBlueprint.id = UUID()
        duplicatedBlueprint.name = newName
        duplicatedBlueprint.createdAt = Date()
        duplicatedBlueprint.updatedAt = Date()
        duplicatedBlueprint.isTemplate = false
        
        try await createBlueprint(duplicatedBlueprint)
    }
    
    /// Clone a template to user blueprints
    func cloneTemplate(_ template: DDMBlueprint, newName: String) async throws {
        var clonedBlueprint = template
        clonedBlueprint.id = UUID()
        clonedBlueprint.name = newName
        clonedBlueprint.createdAt = Date()
        clonedBlueprint.updatedAt = Date()
        clonedBlueprint.isTemplate = false
        
        try await createBlueprint(clonedBlueprint)
    }
    
    // MARK: - Search and Filter
    
    /// Search blueprints based on criteria
    func searchBlueprints(_ criteria: BlueprintSearchCriteria) {
        var results = blueprints
        
        // Filter by query
        if !criteria.query.isEmpty {
            results = results.filter { blueprint in
                blueprint.name.localizedCaseInsensitiveContains(criteria.query) ||
                blueprint.description.localizedCaseInsensitiveContains(criteria.query) ||
                blueprint.tags.contains { $0.localizedCaseInsensitiveContains(criteria.query) }
            }
        }
        
        // Filter by categories
        if !criteria.categories.isEmpty {
            results = results.filter { criteria.categories.contains($0.category) }
        }
        
        // Filter by tags
        if !criteria.tags.isEmpty {
            results = results.filter { blueprint in
                criteria.tags.allSatisfy { tag in
                    blueprint.tags.contains { $0.localizedCaseInsensitiveContains(tag) }
                }
            }
        }
        
        // Filter by complexity
        if !criteria.complexity.isEmpty {
            results = results.filter { criteria.complexity.contains($0.metadata.complexity) }
        }
        
        // Filter by template status
        if let isTemplate = criteria.isTemplate {
            results = results.filter { $0.isTemplate == isTemplate }
        }
        
        // Filter by public status
        if let isPublic = criteria.isPublic {
            results = results.filter { $0.isPublic == isPublic }
        }
        
        // Filter by author
        if let author = criteria.author, !author.isEmpty {
            results = results.filter { $0.author.localizedCaseInsensitiveContains(author) }
        }
        
        // Filter by minimum rating
        if let minimumRating = criteria.minimumRating {
            results = results.filter { $0.metadata.ratings.averageRating >= minimumRating }
        }
        
        // Sort results
        results = sortBlueprints(results, by: criteria.sortBy, order: criteria.sortOrder)
        
        searchResults = results
    }
    
    /// Get blueprints by category
    func getBlueprintsByCategory(_ category: BlueprintCategory) -> [DDMBlueprint] {
        return blueprints.filter { $0.category == category }
    }
    
    /// Get blueprints by tag
    func getBlueprintsByTag(_ tag: String) -> [DDMBlueprint] {
        return blueprints.filter { $0.tags.contains { $0.localizedCaseInsensitiveContains(tag) } }
    }
    
    /// Get popular blueprints
    func getPopularBlueprints(limit: Int = 10) -> [DDMBlueprint] {
        return blueprints
            .sorted { $0.metadata.usage.downloadCount > $1.metadata.usage.downloadCount }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get recently updated blueprints
    func getRecentlyUpdatedBlueprints(limit: Int = 10) -> [DDMBlueprint] {
        return blueprints
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Blueprint Validation
    
    /// Validate a blueprint configuration
    func validateBlueprint(_ blueprint: DDMBlueprint) -> BlueprintValidationResult {
        var errors: [BlueprintValidationError] = []
        var warnings: [BlueprintValidationWarning] = []
        
        // Validate basic information
        if blueprint.name.isEmpty {
            errors.append(.emptyName)
        }
        
        if blueprint.description.isEmpty {
            warnings.append(.emptyDescription)
        }
        
        // Validate security policies
        let securityValidation = validateSecurityPolicies(blueprint.configuration.securityPolicies)
        errors.append(contentsOf: securityValidation.errors)
        warnings.append(contentsOf: securityValidation.warnings)
        
        // Validate network configurations
        let networkValidation = validateNetworkConfigurations(blueprint.configuration.networkConfigurations)
        errors.append(contentsOf: networkValidation.errors)
        warnings.append(contentsOf: networkValidation.warnings)
        
        // Validate compliance rules
        let complianceValidation = validateComplianceRules(blueprint.configuration.complianceRules)
        errors.append(contentsOf: complianceValidation.errors)
        warnings.append(contentsOf: complianceValidation.warnings)
        
        return BlueprintValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    private func validateSecurityPolicies(_ policies: SecurityPolicies) -> BlueprintValidationResult {
        var errors: [BlueprintValidationError] = []
        var warnings: [BlueprintValidationWarning] = []
        
        // Validate passcode policy
        if policies.passcodePolicy.requirePasscode && policies.passcodePolicy.minimumLength < 4 {
            errors.append(.weakPasscodePolicy)
        }
        
        // Validate encryption settings
        if !policies.encryptionSettings.requireFileVault {
            warnings.append(.fileVaultNotRequired)
        }
        
        return BlueprintValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    private func validateNetworkConfigurations(_ configs: NetworkConfigurations) -> BlueprintValidationResult {
        var errors: [BlueprintValidationError] = []
        var warnings: [BlueprintValidationWarning] = []
        
        // Validate WiFi settings
        for network in configs.wifiSettings.networks {
            if network.securityType != .none && network.password?.isEmpty != false {
                errors.append(.insecureWiFiNetwork(network.ssid))
            }
        }
        
        // Validate proxy settings
        if configs.proxySettings.enabled {
            if configs.proxySettings.server?.isEmpty != false {
                errors.append(.invalidProxyConfiguration)
            }
        }
        
        return BlueprintValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    private func validateComplianceRules(_ rules: ComplianceRules) -> BlueprintValidationResult {
        var errors: [BlueprintValidationError] = []
        var warnings: [BlueprintValidationWarning] = []
        
        let allRules = rules.deviceCompliance + rules.applicationCompliance + 
                      rules.networkCompliance + rules.securityCompliance
        
        for rule in allRules {
            if rule.name.isEmpty {
                errors.append(.emptyComplianceRuleName)
            }
            
            if rule.condition.parameter.isEmpty {
                errors.append(.emptyComplianceCondition)
            }
        }
        
        return BlueprintValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Blueprint Testing
    
    /// Test a blueprint configuration
    func testBlueprint(_ blueprint: DDMBlueprint) async throws -> BlueprintTestResult {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate blueprint testing
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let validationResult = validateBlueprint(blueprint)
        
        if !validationResult.isValid {
            throw BlueprintTestError.validationFailed(validationResult.errors)
        }
        
        // Simulate deployment test
        let testResult = BlueprintTestResult(
            success: true,
            deploymentTime: blueprint.metadata.estimatedDeploymentTime,
            issues: validationResult.warnings.map { _ in .warning("Warning") },
            recommendations: generateRecommendations(for: blueprint)
        )
        
        return testResult
    }
    
    private func generateRecommendations(for blueprint: DDMBlueprint) -> [BlueprintRecommendation] {
        var recommendations: [BlueprintRecommendation] = []
        
        // Security recommendations
        if !blueprint.configuration.securityPolicies.encryptionSettings.requireFileVault {
            recommendations.append(.security(.enableFileVault))
        }
        
        if blueprint.configuration.securityPolicies.passcodePolicy.minimumLength < 8 {
            recommendations.append(.security(.increasePasscodeLength))
        }
        
        // Network recommendations
        if blueprint.configuration.networkConfigurations.wifiSettings.networks.contains(where: { $0.securityType == .none }) {
            recommendations.append(.network(.secureWiFiNetworks))
        }
        
        // Compliance recommendations
        if blueprint.configuration.complianceRules.deviceCompliance.isEmpty {
            recommendations.append(.compliance(.addDeviceCompliance))
        }
        
        return recommendations
    }
    
    // MARK: - Blueprint Export/Import
    
    /// Export blueprint to file
    func exportBlueprint(_ blueprint: DDMBlueprint, to url: URL) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(blueprint)
        try data.write(to: url)
    }
    
    /// Import blueprint from file
    func importBlueprint(from url: URL) async throws -> DDMBlueprint {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var blueprint = try decoder.decode(DDMBlueprint.self, from: data)
        blueprint.id = UUID() // Generate new ID
        blueprint.createdAt = Date()
        blueprint.updatedAt = Date()
        
        return blueprint
    }
    
    /// Export multiple blueprints to archive
    func exportBlueprints(_ blueprints: [DDMBlueprint], to url: URL) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(blueprints)
        try data.write(to: url)
    }
    
    /// Import multiple blueprints from archive
    func importBlueprints(from url: URL) async throws -> [DDMBlueprint] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importedBlueprints = try decoder.decode([DDMBlueprint].self, from: data)
        
        var newBlueprints: [DDMBlueprint] = []
        for var blueprint in importedBlueprints {
            blueprint.id = UUID() // Generate new ID
            blueprint.createdAt = Date()
            blueprint.updatedAt = Date()
            newBlueprints.append(blueprint)
        }
        
        return newBlueprints
    }
    
    // MARK: - Statistics and Analytics
    
    /// Get blueprint statistics
    func getBlueprintStatistics() -> BlueprintStatistics {
        let totalBlueprints = blueprints.count
        let totalTemplates = templates.count
        let totalUserBlueprints = userBlueprints.count
        
        let categoryCounts = Dictionary(grouping: blueprints, by: { $0.category })
            .mapValues { $0.count }
        
        let complexityCounts = Dictionary(grouping: blueprints, by: { $0.metadata.complexity })
            .mapValues { $0.count }
        
        let averageRating = blueprints.isEmpty ? 0.0 : 
            blueprints.map { $0.metadata.ratings.averageRating }.reduce(0, +) / Double(blueprints.count)
        
        return BlueprintStatistics(
            totalBlueprints: totalBlueprints,
            totalTemplates: totalTemplates,
            totalUserBlueprints: totalUserBlueprints,
            categoryCounts: categoryCounts,
            complexityCounts: complexityCounts,
            averageRating: averageRating,
            lastUpdated: library.lastUpdated
        )
    }
    
    // MARK: - Private Methods
    
    private func loadBlueprints() {
        loadTemplates()
        loadUserBlueprints()
        blueprints = templates + userBlueprints
        updateLibrary()
    }
    
    private func loadTemplates() {
        let templatesURL = templatesDirectory.appendingPathComponent("templates.json")
        
        guard fileManager.fileExists(atPath: templatesURL.path) else {
            templates = []
            return
        }
        
        do {
            let data = try Data(contentsOf: templatesURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            templates = try decoder.decode([DDMBlueprint].self, from: data)
        } catch {
            print("Error loading templates: \(error)")
            templates = []
        }
    }
    
    private func loadUserBlueprints() {
        let blueprintsURL = blueprintsDirectory.appendingPathComponent("user_blueprints.json")
        
        guard fileManager.fileExists(atPath: blueprintsURL.path) else {
            userBlueprints = []
            return
        }
        
        do {
            let data = try Data(contentsOf: blueprintsURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            userBlueprints = try decoder.decode([DDMBlueprint].self, from: data)
        } catch {
            print("Error loading user blueprints: \(error)")
            userBlueprints = []
        }
    }
    
    private func saveTemplates() async throws {
        let templatesURL = templatesDirectory.appendingPathComponent("templates.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(templates)
        try data.write(to: templatesURL)
    }
    
    private func saveUserBlueprints() async throws {
        let blueprintsURL = blueprintsDirectory.appendingPathComponent("user_blueprints.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(userBlueprints)
        try data.write(to: blueprintsURL)
    }
    
    private func updateLibrary() {
        library.templates = templates
        library.userBlueprints = userBlueprints
        library.lastUpdated = Date()
        
        // Update tags
        let allTags = Set(blueprints.flatMap { $0.tags })
        library.tags = Array(allTags).sorted()
    }
    
    private func sortBlueprints(_ blueprints: [DDMBlueprint], by sortBy: BlueprintSortOption, order: SortOrder) -> [DDMBlueprint] {
        let sorted: [DDMBlueprint]
        
        switch sortBy {
        case .name:
            sorted = blueprints.sorted { $0.name < $1.name }
        case .dateCreated:
            sorted = blueprints.sorted { $0.createdAt > $1.createdAt }
        case .dateUpdated:
            sorted = blueprints.sorted { $0.updatedAt > $1.updatedAt }
        case .rating:
            sorted = blueprints.sorted { $0.metadata.ratings.averageRating > $1.metadata.ratings.averageRating }
        case .popularity:
            sorted = blueprints.sorted { $0.metadata.usage.downloadCount > $1.metadata.usage.downloadCount }
        case .complexity:
            let complexityOrder: [BlueprintComplexity] = [.simple, .medium, .complex, .expert]
            sorted = blueprints.sorted { 
                complexityOrder.firstIndex(of: $0.metadata.complexity) ?? 0 < 
                complexityOrder.firstIndex(of: $1.metadata.complexity) ?? 0 
            }
        }
        
        return order == .ascending ? sorted : sorted.reversed()
    }
    
    private func loadDefaultTemplates() {
        if templates.isEmpty {
            let defaultTemplates = createDefaultTemplates()
            templates = defaultTemplates
            Task {
                try? await saveTemplates()
            }
        }
    }
    
    private func createDefaultTemplates() -> [DDMBlueprint] {
        return [
            createBasicSecurityTemplate(),
            createEnterpriseTemplate(),
            createKioskTemplate(),
            createDeveloperTemplate(),
            createComplianceTemplate()
        ]
    }
    
    private func createBasicSecurityTemplate() -> DDMBlueprint {
        var config = BlueprintConfiguration()
        config.securityPolicies.passcodePolicy.minimumLength = 8
        config.securityPolicies.passcodePolicy.requireComplexity = true
        config.securityPolicies.encryptionSettings.requireFileVault = true
        config.securityPolicies.firewallRules.enableFirewall = true
        
        return DDMBlueprint(
            name: "Basic Security",
            description: "Essential security settings for general use",
            category: .security,
            tags: ["security", "basic", "essential"],
            isTemplate: true,
            isPublic: true,
            configuration: config
        )
    }
    
    private func createEnterpriseTemplate() -> DDMBlueprint {
        var config = BlueprintConfiguration()
        config.securityPolicies.passcodePolicy.minimumLength = 12
        config.securityPolicies.passcodePolicy.requireComplexity = true
        config.securityPolicies.encryptionSettings.requireFileVault = true
        config.securityPolicies.firewallRules.enableFirewall = true
        config.networkConfigurations.proxySettings.enabled = true
        config.networkConfigurations.proxySettings.type = .http
        
        return DDMBlueprint(
            name: "Enterprise Configuration",
            description: "Comprehensive enterprise security and management settings",
            category: .deviceManagement,
            tags: ["enterprise", "security", "management"],
            isTemplate: true,
            isPublic: true,
            configuration: config
        )
    }
    
    private func createKioskTemplate() -> DDMBlueprint {
        var config = BlueprintConfiguration()
        config.applicationSettings.blockedApplications = ["Safari", "Mail", "Messages"]
        config.userPreferences.systemPreferences.allowSystemPreferences = false
        config.userPreferences.dockSettings.position = .bottom
        config.userPreferences.dockSettings.size = 32
        
        return DDMBlueprint(
            name: "Kiosk Mode",
            description: "Restricted environment for public access devices",
            category: .userExperience,
            tags: ["kiosk", "restricted", "public"],
            isTemplate: true,
            isPublic: true,
            configuration: config
        )
    }
    
    private func createDeveloperTemplate() -> DDMBlueprint {
        var config = BlueprintConfiguration()
        config.applicationSettings.allowedApplications = ["Xcode", "Terminal", "Git"]
        config.userPreferences.systemPreferences.allowSystemPreferences = true
        config.securityPolicies.passcodePolicy.minimumLength = 6
        
        return DDMBlueprint(
            name: "Developer Environment",
            description: "Optimized settings for software development",
            category: .applications,
            tags: ["developer", "xcode", "programming"],
            isTemplate: true,
            isPublic: true,
            configuration: config
        )
    }
    
    private func createComplianceTemplate() -> DDMBlueprint {
        var config = BlueprintConfiguration()
        config.complianceRules.deviceCompliance = [
            ComplianceRule(
                name: "Device Encryption Required",
                description: "Ensure device is encrypted",
                category: .security,
                severity: .high,
                condition: ComplianceCondition(
                    type: .securitySetting,
                    parameter: "filevault_enabled",
                    operatorType: .isTrue,
                    value: "true"
                ),
                action: ComplianceAction(type: .notify)
            )
        ]
        
        return DDMBlueprint(
            name: "Compliance Ready",
            description: "Pre-configured compliance rules for regulatory requirements",
            category: .compliance,
            tags: ["compliance", "regulatory", "audit"],
            isTemplate: true,
            isPublic: true,
            configuration: config
        )
    }
}

// MARK: - Supporting Types

struct BlueprintValidationResult {
    let isValid: Bool
    let errors: [BlueprintValidationError]
    let warnings: [BlueprintValidationWarning]
}

enum BlueprintValidationError: Error, LocalizedError {
    case emptyName
    case weakPasscodePolicy
    case insecureWiFiNetwork(String)
    case invalidProxyConfiguration
    case emptyComplianceRuleName
    case emptyComplianceCondition
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Blueprint name cannot be empty"
        case .weakPasscodePolicy:
            return "Passcode policy is too weak (minimum 4 characters required)"
        case .insecureWiFiNetwork(let ssid):
            return "WiFi network '\(ssid)' is insecure (no password set)"
        case .invalidProxyConfiguration:
            return "Proxy configuration is invalid"
        case .emptyComplianceRuleName:
            return "Compliance rule name cannot be empty"
        case .emptyComplianceCondition:
            return "Compliance condition cannot be empty"
        }
    }
}

enum BlueprintValidationWarning: LocalizedError {
    case emptyDescription
    case fileVaultNotRequired
    
    var errorDescription: String? {
        switch self {
        case .emptyDescription:
            return "Blueprint description is empty"
        case .fileVaultNotRequired:
            return "FileVault encryption is not required"
        }
    }
}

struct BlueprintTestResult {
    let success: Bool
    let deploymentTime: Int
    let issues: [BlueprintTestIssue]
    let recommendations: [BlueprintRecommendation]
}

enum BlueprintTestIssue {
    case warning(String)
    case error(String)
    case info(String)
}

enum BlueprintRecommendation {
    case security(SecurityRecommendation)
    case network(NetworkRecommendation)
    case compliance(ComplianceRecommendation)
    case application(ApplicationRecommendation)
    
    var description: String {
        switch self {
        case .security(let rec):
            return rec.description
        case .network(let rec):
            return rec.description
        case .compliance(let rec):
            return rec.description
        case .application(let rec):
            return rec.description
        }
    }
}

enum SecurityRecommendation {
    case enableFileVault
    case increasePasscodeLength
    case enableFirewall
    case requireBiometric
    
    var description: String {
        switch self {
        case .enableFileVault:
            return "Enable FileVault encryption for better security"
        case .increasePasscodeLength:
            return "Increase minimum passcode length to 8 characters"
        case .enableFirewall:
            return "Enable firewall to block unauthorized connections"
        case .requireBiometric:
            return "Require biometric authentication for enhanced security"
        }
    }
}

enum NetworkRecommendation {
    case secureWiFiNetworks
    case configureProxy
    case enableVPN
    
    var description: String {
        switch self {
        case .secureWiFiNetworks:
            return "Secure all WiFi networks with strong passwords"
        case .configureProxy:
            return "Configure proxy settings for enterprise networks"
        case .enableVPN:
            return "Enable VPN for secure remote access"
        }
    }
}

enum ComplianceRecommendation {
    case addDeviceCompliance
    case addApplicationCompliance
    case addSecurityCompliance
    
    var description: String {
        switch self {
        case .addDeviceCompliance:
            return "Add device compliance rules for better control"
        case .addApplicationCompliance:
            return "Add application compliance rules"
        case .addSecurityCompliance:
            return "Add security compliance rules"
        }
    }
}

enum ApplicationRecommendation {
    case restrictAppStore
    case allowSpecificApps
    case blockUnwantedApps
    
    var description: String {
        switch self {
        case .restrictAppStore:
            return "Restrict App Store access to prevent unauthorized installations"
        case .allowSpecificApps:
            return "Allow only specific applications to run"
        case .blockUnwantedApps:
            return "Block unwanted applications"
        }
    }
}

enum BlueprintTestError: Error, LocalizedError {
    case validationFailed([BlueprintValidationError])
    case deploymentFailed(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return "Validation failed: \(errors.map { $0.localizedDescription }.joined(separator: ", "))"
        case .deploymentFailed(let message):
            return "Deployment failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

struct BlueprintStatistics {
    let totalBlueprints: Int
    let totalTemplates: Int
    let totalUserBlueprints: Int
    let categoryCounts: [BlueprintCategory: Int]
    let complexityCounts: [BlueprintComplexity: Int]
    let averageRating: Double
    let lastUpdated: Date
}
