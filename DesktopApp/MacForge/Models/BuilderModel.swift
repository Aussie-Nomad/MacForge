//
//  BuilderModel.swift
//  MacForge
//
//  Core data model for profile building operations.
//  Manages the state and data flow for configuration profile creation.
//

import SwiftUI
import Foundation

// MARK: - Core Data Models
struct Payload: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var description: String
    var platforms: [String]
    var icon: String
    var category: String
    var settings: [String: CodableValue] = [:]
    var enabled: Bool = true
    var uuid: String = UUID().uuidString
}

struct CodableValue: Codable, Hashable {
    var value: AnyHashable
    init(_ v: AnyHashable) { value = v }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) { value = b }
        else if let i = try? c.decode(Int.self) { value = i }
        else if let d = try? c.decode(Double.self) { value = d }
        else if let s = try? c.decode(String.self) { value = s }
        else if let a = try? c.decode([String].self) { value = AnyHashable(a) }
        else { value = "" }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let b as Bool: try c.encode(b)
        case let i as Int: try c.encode(i)
        case let d as Double: try c.encode(d)
        case let s as String: try c.encode(s)
        case let a as [String]: try c.encode(a)
        default: try c.encode(String(describing: value))
        }
    }
}

struct ProfileSettings: Codable, Hashable {
    var name: String = "New Configuration Profile"
    var description: String = "Created with MacForge"
    var identifier: String = "com.macforge.profile.\(Int(Date().timeIntervalSince1970))"
    var organization: String = "Your Organization"
    var scope: String = "System"
}

struct TemplateProfile: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let description: String
    let payloadIDs: [String]
}

enum MDMVendor: String, CaseIterable, Identifiable {
    case jamf = "Jamf Pro"
    case intune = "Microsoft Intune"
    case kandji = "Kandji"
    case mosyle = "Mosyle"
    
    var id: String { rawValue }
    var asset: String {
        switch self {
        case .jamf:   return "mdm_jamf"
        case .intune: return "mdm_intune"
        case .kandji: return "mdm_kandji"
        case .mosyle: return "mdm_mosyle"
        }
    }
    var sfFallback: String { "building.2.crop.circle" }
}

enum ToolModule: String, CaseIterable, Identifiable {
    case profileBuilder
    case packageSmelting
    case deviceFoundry
    case blueprintBuilder
    case hammeringScripts

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .profileBuilder: return "Profile Builder"
        case .packageSmelting: return "Package Smelting"
        case .deviceFoundry: return "Device Foundry"
        case .blueprintBuilder: return "Blueprint Builder"
        case .hammeringScripts: return "Hammering Scripts"
        }
    }

    var icon: String {
        switch self {
        case .profileBuilder: return "doc.badge.gearshape"
        case .packageSmelting: return "shippingbox"
        case .deviceFoundry: return "desktopcomputer"
        case .blueprintBuilder: return "square.grid.3x3"
        case .hammeringScripts: return "hammer"
        }
    }
}

enum AuthDecision: String, Codable, CaseIterable, Hashable {
    case allow = "Allow"
    case ask = "Prompt"
    case deny = "Deny"
}



// MARK: - App Info Model
struct AppInfo: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let bundleID: String
    let path: String
}

// MARK: - PPPC Service Model
struct PPPCService: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: PPPCServiceCategory
    let requiresBundleID: Bool
    let requiresCodeRequirement: Bool
    let requiresIdentifier: Bool
    
    var displayName: String { name }
}

enum PPPCServiceCategory: String, CaseIterable {
    case system = "System"
    case accessibility = "Accessibility"
    case automation = "Automation"
    case inputMonitoring = "Input Monitoring"
    case media = "Media"
    case network = "Network"
    case systemPolicy = "System Policy"
    
    var displayName: String { rawValue }
}

// MARK: - PPPC Configuration Model
struct PPPCConfiguration: Identifiable, Equatable {
    let id = UUID()
    var service: PPPCService
    var identifier: String
    var identifierType: PPPCIdentifierType
    var codeRequirement: String?
    var allowed: Bool
    var userOverride: Bool
    var comment: String?
    
    init(service: PPPCService, identifier: String, identifierType: PPPCIdentifierType = .bundleID) {
        self.service = service
        self.identifier = identifier
        self.identifierType = identifierType
        self.allowed = true
        self.userOverride = false
    }
}

enum PPPCIdentifierType: String, CaseIterable {
    case bundleID = "Bundle Identifier"
    case path = "Path"
    case codeRequirement = "Code Requirement"
    
    var displayName: String { rawValue }
}

// MARK: - Builder Model
@MainActor
final class BuilderModel: ObservableObject {
    // MARK: - Dependencies
    private let authenticationService: JAMFAuthenticationService
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
    
    // MARK: - Initialization
    init(
        authenticationService: JAMFAuthenticationService = JAMFAuthenticationService(),
        jamfService: JAMFServiceProtocol? = nil,
        profileExportService: ProfileExportServiceProtocol = ProfileExportService()
    ) {
        self.authenticationService = authenticationService
        self.jamfService = jamfService
        self.profileExportService = profileExportService
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
    
    private func buildPPPCServices() -> [[String: Any]] {
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
        
        if template.name == "Antivirus Setup" {
            if !dropped.contains(where: { $0.id == "pppc" }),
               let pppcPayload = library.first(where: { $0.id == "pppc" }) {
                add(pppcPayload)
            }
            
            // Add default PPPC configurations for antivirus
            let antivirusServices = ["SystemPolicyAllFiles", "ScreenCapture", "Accessibility"]
            for serviceID in antivirusServices {
                // Create a basic PPPC service for testing
                let service = PPPCService(
                    id: serviceID,
                    name: serviceID,
                    description: "Service for \(serviceID)",
                    category: .systemPolicy,
                    requiresBundleID: true,
                    requiresCodeRequirement: false,
                    requiresIdentifier: true
                )
                
                if let selectedApp = selectedApp {
                    let config = PPPCConfiguration(
                        service: service,
                        identifier: selectedApp.bundleID
                    )
                    pppcConfigurations.append(config)
                }
            }
            suggestedServiceIDs = Set(antivirusServices)
        }
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
