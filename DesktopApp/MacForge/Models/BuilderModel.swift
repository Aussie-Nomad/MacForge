//
//  BuilderModel.swift
//  MacForge
//
//  Core data model for profile building operations.
//  Manages the state and data flow for configuration profile creation.
//

import SwiftUI
import Foundation

// MARK: - JAMF Connection Types
struct JAMFConnection {
    let account: MDMAccount
    let service: JAMFService
    let token: String
    
    var serverURL: String { account.serverURL }
    var displayName: String { account.displayName }
    var vendor: String { account.vendor }
}

enum JAMFConnectionStatus {
    case disconnected
    case connecting
    case connected
    case failed
}

// MARK: - Profile Settings
struct ProfileSettings: Codable, Hashable {
    var name: String = "New Configuration Profile"
    var description: String = "Created with MacForge"
    var identifier: String = "com.macforge.profile.\(Int(Date().timeIntervalSince1970))"
    var organization: String = "Your Organization"
    var scope: String = "System"
}

enum ToolModule: String, CaseIterable, Identifiable {
    case profileBuilder
    case packageCasting
    case deviceFoundry
    case ddmBlueprints
    case hammeringScripts
    case logBurner
    case blacksmith

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .profileBuilder: return "Profile Workbench (PPPC)"
        case .packageCasting: return "Package Casting"
        case .deviceFoundry: return "Device Foundry Lookup"
        case .ddmBlueprints: return "Apple DDM Builder"
        case .hammeringScripts: return "Script Smelter"
        case .logBurner: return "Log Burner"
        case .blacksmith: return "The Blacksmith"
        }
    }

    var icon: String {
        switch self {
        case .profileBuilder: return "doc.badge.gearshape"
        case .packageCasting: return "shippingbox"
        case .deviceFoundry: return "magnifyingglass.circle.fill"
        case .ddmBlueprints: return "network.badge.shield.half.filled"
        case .hammeringScripts: return "hammer"
        case .logBurner: return "flame.circle.fill"
        case .blacksmith: return "hammer.circle.fill"
        }
    }
}

enum AuthDecision: String, Codable, CaseIterable, Hashable {
    case allow = "Allow"
    case ask = "Prompt"
    case deny = "Deny"
}

// MARK: - Builder Model
@MainActor
final class BuilderModel: ObservableObject {
    // MARK: - Dependencies
    private let authenticationService: any JAMFAuthenticationServiceProtocol
    private let jamfService: JAMFServiceProtocol?
    private let profileExportService: ProfileExportServiceProtocol
    
    // MARK: - Published Properties
    @Published var searchTerm = ""
    @Published var selectedCategory = "All"
    @Published var library: [Payload] = allPayloadsLibrary
    @Published var dropped: [Payload] = []
    @Published var selected: Payload? = nil
    
    // Profile settings
    @Published var settings: ProfileSettings = .init()
    @Published var showTemplates = false
    @Published var selectedApp: AppInfo? = nil
    @Published var pppcConfigurations: [PPPCConfiguration] = []
    
    // Wizard state
    @Published var wizardMode = true
    @Published var wizardStep = 1

    @Published var suggestedServiceIDs: Set<String> = []
    @Published var identifierType: String = "bundleID"
    
    // Authentication state
    @Published var isAuthenticated = false
    @Published var authenticationError: String?
    @Published var isAuthenticating = false
    
    // JAMF Connection state
    @Published var currentJAMFConnection: JAMFConnection?
    @Published var jamfConnectionStatus: JAMFConnectionStatus = .disconnected
    
    // MARK: - Initialization
    init(
        authenticationService: any JAMFAuthenticationServiceProtocol = JAMFAuthenticationService(),
        jamfService: JAMFServiceProtocol? = nil,
        profileExportService: ProfileExportServiceProtocol = ProfileExportService()
    ) {
        self.authenticationService = authenticationService
        self.jamfService = jamfService
        self.profileExportService = profileExportService
        
        // Load saved PPPC configurations
        loadPPPCConfigurations()
    }
    
    // MARK: - PPPC Configuration Management
    
    func addPPPCConfiguration(_ configuration: PPPCConfiguration) {
        // Remove existing configuration for the same service if it exists
        pppcConfigurations.removeAll { $0.service.id == configuration.service.id }
        pppcConfigurations.append(configuration)
        
        // Update suggested services
        suggestedServiceIDs.insert(configuration.service.id)
        
        // Persist to UserDefaults for wizard step persistence
        savePPPCConfigurations()
    }
    
    func removePPPCConfiguration(for serviceID: String) {
        pppcConfigurations.removeAll { $0.service.id == serviceID }
        suggestedServiceIDs.remove(serviceID)
        
        // Persist to UserDefaults for wizard step persistence
        savePPPCConfigurations()
    }
    
    func updatePPPCConfiguration(_ configuration: PPPCConfiguration) {
        if let index = pppcConfigurations.firstIndex(where: { $0.service.id == configuration.service.id }) {
            pppcConfigurations[index] = configuration
            // Persist to UserDefaults for wizard step persistence
            savePPPCConfigurations()
        }
    }
    
    func getPPPCConfiguration(for serviceID: String) -> PPPCConfiguration? {
        return pppcConfigurations.first { $0.service.id == serviceID }
    }
    
    private func savePPPCConfigurations() {
        // Convert configurations to UserDefaults-compatible format
        let configData = pppcConfigurations.map { config in
            [
                "serviceID": config.service.id,
                "identifier": config.identifier,
                "identifierType": config.identifierType.rawValue,
                "codeRequirement": config.codeRequirement ?? "",
                "allowed": config.allowed,
                "userOverride": config.userOverride,
                "comment": config.comment ?? ""
            ]
        }
        
        UserDefaults.standard.set(configData, forKey: "MacForge.PPPCConfigurations")
        UserDefaults.standard.set(Array(suggestedServiceIDs), forKey: "MacForge.SuggestedServiceIDs")
    }
    
    private func loadPPPCConfigurations() {
        guard let configData = UserDefaults.standard.array(forKey: "MacForge.PPPCConfigurations") as? [[String: Any]] else {
            return
        }
        
        pppcConfigurations = configData.compactMap { data -> PPPCConfiguration? in
            guard let serviceID = data["serviceID"] as? String,
                  let identifier = data["identifier"] as? String,
                  let identifierTypeRaw = data["identifierType"] as? String,
                  let identifierType = PPPCIdentifierType(rawValue: identifierTypeRaw),
                  let allowed = data["allowed"] as? Bool,
                  let userOverride = data["userOverride"] as? Bool else {
                return nil
            }
            
            // Find the service from our catalog
            let service = pppcServices.first { $0.id == serviceID } ?? PPPCService(
                id: serviceID,
                name: serviceID,
                description: "Service for \(serviceID)",
                category: .systemPolicy,
                requiresBundleID: true,
                requiresCodeRequirement: false,
                requiresIdentifier: true
            )
            
            var config = PPPCConfiguration(service: service, identifier: identifier, identifierType: identifierType)
            config.allowed = allowed
            config.userOverride = userOverride
            config.codeRequirement = data["codeRequirement"] as? String
            config.comment = data["comment"] as? String
            
            return config
        }
        
        // Load suggested service IDs
        if let suggestedIDs = UserDefaults.standard.array(forKey: "MacForge.SuggestedServiceIDs") as? [String] {
            suggestedServiceIDs = Set(suggestedIDs)
        }
    }
    
    // MARK: - Public Methods
    
    func connectToJAMF(serverURL: String, clientID: String, clientSecret: String) async {
        await authenticateWithJAMF(serverURL: serverURL, clientID: clientID, clientSecret: clientSecret)
    }
    
    func exportProfile() throws -> Data {
        let profile = buildConfigurationProfile()
        return try profileExportService.exportProfile(profile)
    }
    
    func saveProfileToDownloads() throws -> URL {
        let profile = buildConfigurationProfile()
        return try profileExportService.saveProfileToDownloads(profile)
    }
    
    func submitProfileToJAMF() async throws {
        guard let jamfService = jamfService else {
            throw BuilderError.notAuthenticated
        }
        
        let profileData = try exportProfile()
        try await jamfService.uploadOrUpdateProfile(name: settings.name, xmlData: profileData)
    }
    
    // MARK: - Profile Building
    
    func buildConfigurationProfile() -> ConfigurationProfile {
        let payloads = dropped.map { payload in
            buildProfilePayload(from: payload)
        }
        
        return ConfigurationProfile(
            name: settings.name,
            description: settings.description,
            identifier: settings.identifier,
            organization: settings.organization,
            scope: settings.scope,
            payloads: payloads
        )
    }
    
    private func buildProfilePayload(from payload: Payload) -> ProfilePayload {
        var payloadSettings: [String: Any] = [:]
        
        // Add custom settings
        for (key, value) in payload.settings {
            payloadSettings[key] = value.value
        }
        
        // Handle PPPC payload specially
        if payload.id == "pppc" {
            payloadSettings["Services"] = buildPPPCServices()
            if let bundleID = payload.settings["BundleIdentifier"]?.value as? String {
                payloadSettings["Identifier"] = bundleID
            }
            if let codeRequirement = payload.settings["CodeRequirement"]?.value as? String {
                payloadSettings["CodeRequirement"] = codeRequirement
            }
        }
        
        return ProfilePayload(
            type: payload.id == "pppc" ? "com.apple.TCC" : "com.apple.\(payload.id)",
            identifier: "\(settings.identifier).\(payload.id)",
            uuid: payload.uuid,
            displayName: payload.name,
            description: payload.description,
            version: 1,
            enabled: payload.enabled,
            settings: payloadSettings
        )
    }
    
    func buildPPPCServices() -> [[String: Any]] {
        return pppcConfigurations.compactMap { config in
            var item: [String: Any] = [
                "Service": config.service.id,
                "Authorization": config.allowed ? "Allow" : "Deny"
            ]
            
            if config.service.id == "AppleEvents" {
                item["AEReceiverIdentifier"] = config.identifier
                item["AEReceiverIdentifierType"] = config.identifierType.rawValue.lowercased()
            }
            
            if config.service.id == "ScreenCapture" {
                item["ScreenCaptureType"] = "All"
            }
            
            if let comment = config.comment {
                item["Comment"] = comment
            }
            
            return item
        }
    }
    
    // MARK: - Authentication
    
    private func authenticateWithJAMF(serverURL: String, clientID: String, clientSecret: String) async {
        isAuthenticating = true
        authenticationError = nil
        
        defer { isAuthenticating = false }
        
        do {
            try await authenticationService.validateConnection(to: serverURL)
            _ = try await authenticationService.authenticateOAuth(
                clientID: clientID,
                clientSecret: clientSecret,
                serverURL: serverURL
            )
            
            isAuthenticated = true
            authenticationError = nil
            
        } catch {
            isAuthenticated = false
            if let authError = error as? AuthenticationError {
                authenticationError = authError.localizedDescription
            } else {
                authenticationError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func filtered() -> [Payload] {
        library.filter { payload in
            (selectedCategory == "All" || payload.category == selectedCategory) &&
            (searchTerm.isEmpty || 
             payload.name.lowercased().contains(searchTerm.lowercased()) ||
             payload.description.lowercased().contains(searchTerm.lowercased()))
        }
    }
    
    func add(_ payload: Payload) {
        guard !dropped.contains(where: { $0.id == payload.id }) else { return }
        var copy = payload
        copy.uuid = UUID().uuidString
        copy.enabled = true
        dropped.append(copy)
    }
    
    func remove(_ payloadID: String) {
        dropped.removeAll { $0.id == payloadID }
        if selected?.id == payloadID { selected = nil }
    }
    
    func apply(template: TemplateProfile) {
        dropped = template.payloadIDs.compactMap { id in
            library.first { $0.id == id }
        }.map { payload in
            var copy = payload
            copy.uuid = UUID().uuidString
            copy.enabled = true
            return copy
        }
        
        // Clear existing PPPC configurations when applying a new template
        pppcConfigurations.removeAll()
        suggestedServiceIDs.removeAll()
        
        if template.name == "Antivirus Setup" {
            if !dropped.contains(where: { $0.id == "pppc" }),
               let pppcPayload = library.first(where: { $0.id == "pppc" }) {
                add(pppcPayload)
            }
            
            // Add default PPPC configurations for antivirus with proper service configuration
            let antivirusServices = ["SystemPolicyAllFiles", "ScreenCapture", "Accessibility"]
            for serviceID in antivirusServices {
                if let service = pppcServices.first(where: { $0.id == serviceID }) {
                    if let selectedApp = selectedApp {
                        let config = PPPCConfiguration(
                            service: service,
                            identifier: selectedApp.bundleID
                        )
                        addPPPCConfiguration(config)
                    }
                }
            }
        } else if template.name == "Security Baseline" {
            // Configure security baseline with proper PPPC settings
            let securityServices = ["SystemPolicyAllFiles", "Accessibility", "InputMonitoring"]
            for serviceID in securityServices {
                if let service = pppcServices.first(where: { $0.id == serviceID }) {
                    if let selectedApp = selectedApp {
                        let config = PPPCConfiguration(
                            service: service,
                            identifier: selectedApp.bundleID
                        )
                        addPPPCConfiguration(config)
                    }
                }
            }
        } else if template.name == "Development Tools" {
            // Configure development tools with appropriate permissions
            let devServices = ["SystemPolicyAllFiles", "Accessibility", "AppleEvents"]
            for serviceID in devServices {
                if let service = pppcServices.first(where: { $0.id == serviceID }) {
                    if let selectedApp = selectedApp {
                        let config = PPPCConfiguration(
                            service: service,
                            identifier: selectedApp.bundleID
                        )
                        addPPPCConfiguration(config)
                    }
                }
            }
        }
        
        // Save configurations after applying template
        savePPPCConfigurations()
    }
    
    func applyCategorySuggestions(_ category: String) {
        let categoryMap: [String: [String]] = [
            "Security EDR": ["Accessibility", "SystemPolicyAllFiles", "ScreenCapture", "AppleEvents", "Microphone", "Camera"],
            "Browser": ["ScreenCapture", "AppleEvents", "SystemPolicyDownloadsFolder"],
            "Communications": ["Camera", "Microphone", "AppleEvents"],
            "General": []
        ]
        
        suggestedServiceIDs = Set(categoryMap[category] ?? [])
    }
    
    func hasConfiguredPermissions() -> Bool {
        return !pppcConfigurations.isEmpty
    }
    
    func humanSummary() -> [String] {
        var summary: [String] = []
        
        if let selectedApp = selectedApp {
            summary.append("Apply permissions to \(selectedApp.name)")
        }
        
        for config in pppcConfigurations {
            let verb = config.allowed ? "Allow" : "Deny"
            if config.service.id == "AppleEvents" {
                summary.append("\(verb) AppleEvents to \(config.identifier)")
            } else {
                summary.append("\(verb) \(friendlyName(config.service.id))")
            }
        }
        
        return summary.isEmpty ? ["No changes selected yet"] : summary
    }
    
    private func friendlyName(_ id: String) -> String {
        let nameMap: [String: String] = [
            "Accessibility": "Accessibility",
            "SystemPolicyAllFiles": "Full Disk Access",
            "SystemPolicyDownloadsFolder": "Downloads Folder",
            "ScreenCapture": "Screen Recording",
            "AppleEvents": "Apple Events",
            "Microphone": "Microphone",
            "Camera": "Camera"
        ]
        return nameMap[id] ?? id
    }
}

// MARK: - Builder Errors
enum BuilderError: LocalizedError {
    case notAuthenticated
    case profileExportFailed(Error)
    case submissionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with JAMF"
        case .profileExportFailed(let error):
            return "Failed to export profile: \(error.localizedDescription)"
        case .submissionFailed(let error):
            return "Failed to submit profile: \(error.localizedDescription)"
        }
    }
}
