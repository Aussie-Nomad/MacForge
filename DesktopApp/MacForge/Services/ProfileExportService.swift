//
//  ProfileExportService.swift
//  MacForge
//
//  Service for exporting configuration profiles in various formats.
//  Handles profile serialization, validation, and file generation.
//

import Foundation

// MARK: - Profile Export Service Protocol
protocol ProfileExportServiceProtocol {
    func exportProfile(_ profile: ConfigurationProfile) throws -> Data
    func saveProfileToDownloads(_ profile: ConfigurationProfile) throws -> URL
    func validateProfile(_ profile: ConfigurationProfile) -> [ProfileValidationError]
}

// MARK: - Configuration Profile Model
struct ConfigurationProfile {
    let name: String
    let description: String
    let identifier: String
    let organization: String
    let scope: String
    let payloads: [ProfilePayload]
    
    init(name: String, description: String, identifier: String, organization: String, scope: String, payloads: [ProfilePayload]) {
        self.name = name
        self.description = description
        self.identifier = identifier
        self.organization = organization
        self.scope = scope
        self.payloads = payloads
    }
}

// MARK: - Profile Payload Model
struct ProfilePayload {
    let type: String
    let identifier: String
    let uuid: String
    let displayName: String
    let description: String
    let version: Int
    let enabled: Bool
    let settings: [String: Any]
    
    init(type: String, identifier: String, uuid: String, displayName: String, description: String, version: Int, enabled: Bool, settings: [String: Any]) {
        self.type = type
        self.identifier = identifier
        self.uuid = uuid
        self.displayName = displayName
        self.description = description
        self.version = version
        self.enabled = enabled
        self.settings = settings
    }
}

// MARK: - Profile Validation Errors
enum ProfileValidationError: LocalizedError, Equatable {
    case emptyName
    case emptyIdentifier
    case invalidIdentifier
    case noPayloads
    case duplicatePayloadIdentifier(String)
    case emptyDescription
    case invalidOrganization
    case invalidPayloadType(String)
    case payloadConfigurationError(String, String)
    case invalidScope
    case profileTooLarge(Int)
    case unsupportedPlatform(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Profile name cannot be empty"
        case .emptyIdentifier:
            return "Profile identifier cannot be empty"
        case .invalidIdentifier:
            return "Profile identifier must be a valid reverse domain name (e.g., com.company.profile)"
        case .noPayloads:
            return "Profile must contain at least one payload"
        case .duplicatePayloadIdentifier(let identifier):
            return "Duplicate payload identifier: \(identifier)"
        case .emptyDescription:
            return "Profile description cannot be empty"
        case .invalidOrganization:
            return "Organization name cannot be empty"
        case .invalidPayloadType(let type):
            return "Invalid payload type: \(type)"
        case .payloadConfigurationError(let payload, let error):
            return "Payload '\(payload)' configuration error: \(error)"
        case .invalidScope:
            return "Profile scope must be 'System' or 'User'"
        case .profileTooLarge(let size):
            return "Profile size (\(size) bytes) exceeds recommended limit"
        case .unsupportedPlatform(let platform):
            return "Platform '\(platform)' is not supported for this profile type"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .emptyName:
            return "Enter a descriptive name for your profile"
        case .emptyIdentifier:
            return "Enter a unique identifier for your profile"
        case .invalidIdentifier:
            return "Use format: com.yourcompany.profilename (e.g., com.acme.wifi-config)"
        case .noPayloads:
            return "Add at least one payload configuration"
        case .duplicatePayloadIdentifier:
            return "Ensure each payload has a unique identifier"
        case .emptyDescription:
            return "Provide a clear description of what this profile does"
        case .invalidOrganization:
            return "Enter your organization's name"
        case .invalidPayloadType:
            return "Check Apple's documentation for supported payload types"
        case .payloadConfigurationError:
            return "Review the payload configuration and required fields"
        case .invalidScope:
            return "Choose 'System' for device-wide settings or 'User' for user-specific settings"
        case .profileTooLarge:
            return "Consider splitting into multiple profiles or removing unnecessary options"
        case .unsupportedPlatform:
            return "Verify platform compatibility for your target devices"
        }
    }
}

// MARK: - Profile Validation Warnings
enum ProfileValidationWarning: LocalizedError, Equatable {
    case longProfileName(String)
    case longDescription(String)
    case manyPayloads(Int)
    case complexConfiguration
    case deprecatedPayloadType(String)
    case missingOptionalFields(String)
    
    var errorDescription: String? {
        switch self {
        case .longProfileName(let name):
            return "Profile name '\(name)' is longer than recommended (50 characters)"
        case .longDescription:
            return "Description is longer than recommended (200 characters)"
        case .manyPayloads(let count):
            return "Profile contains \(count) payloads, consider splitting for better management"
        case .complexConfiguration:
            return "Profile configuration is complex, review for potential issues"
        case .deprecatedPayloadType(let type):
            return "Payload type '\(type)' is deprecated, consider alternatives"
        case .missingOptionalFields(let fields):
            return "Consider adding optional fields: \(fields)"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .longProfileName:
            return "Use a shorter, more concise name"
        case .longDescription:
            return "Keep description under 200 characters for better readability"
        case .manyPayloads:
            return "Split into logical groups: security, network, applications, etc."
        case .complexConfiguration:
            return "Test thoroughly before deployment"
        case .deprecatedPayloadType:
            return "Check Apple's documentation for current alternatives"
        case .missingOptionalFields:
            return "Add optional fields to improve profile functionality"
        }
    }
}

// MARK: - Compliance Errors
enum ComplianceError: LocalizedError, Equatable {
    case unsupportedPayloadCombination([String])
    case missingRequiredFields(String, [String])
    case invalidFieldValue(String, String, String)
    case dependencyNotMet(String, String)
    case versionMismatch(String, String, String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedPayloadCombination(let payloads):
            return "Unsupported combination of payloads: \(payloads.joined(separator: ", "))"
        case .missingRequiredFields(let payload, let fields):
            return "Payload '\(payload)' missing required fields: \(fields.joined(separator: ", "))"
        case .invalidFieldValue(let payload, let field, let value):
            return "Payload '\(payload)' field '\(field)' has invalid value: \(value)"
        case .dependencyNotMet(let payload, let dependency):
            return "Payload '\(payload)' requires '\(dependency)' to be configured first"
        case .versionMismatch(let payload, let current, let required):
            return "Payload '\(payload)' version \(current) is incompatible with required version \(required)"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .unsupportedPayloadCombination:
            return "Check Apple's documentation for compatible payload combinations"
        case .missingRequiredFields:
            return "Fill in all required fields for the payload"
        case .invalidFieldValue:
            return "Use valid values as specified in Apple's documentation"
        case .dependencyNotMet:
            return "Configure the required dependency first"
        case .versionMismatch:
            return "Update to a compatible version or use alternative payload"
        }
    }
}

// MARK: - Validation Suggestions
struct ValidationSuggestion {
    let title: String
    let description: String
    let priority: SuggestionPriority
    let action: String
}

enum SuggestionPriority: String, CaseIterable {
    case high = "High Priority"
    case medium = "Medium Priority"
    case low = "Low Priority"
    
    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "blue"
        }
    }
}

// MARK: - Payload Validation Errors
enum PayloadValidationError: LocalizedError, Equatable {
    case missingRequiredField(String)
    case invalidFieldValue(String, String)
    case unsupportedValue(String, String, [String])
    case fieldDependencyNotMet(String, String)
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Required field '\(field)' is missing"
        case .invalidFieldValue(let field, let value):
            return "Field '\(field)' has invalid value: \(value)"
        case .unsupportedValue(let field, let value, let supported):
            return "Field '\(field)' value '\(value)' not supported. Supported values: \(supported.joined(separator: ", "))"
        case .fieldDependencyNotMet(let field, let dependency):
            return "Field '\(field)' requires '\(dependency)' to be set first"
        }
    }
}

// MARK: - Profile Export Service Implementation
final class ProfileExportService: ProfileExportServiceProtocol {
    
    func exportProfile(_ profile: ConfigurationProfile) throws -> Data {
        // Validate profile before export
        let validationErrors = validateProfile(profile)
        guard validationErrors.isEmpty else {
            throw ProfileExportError.validationFailed(validationErrors)
        }
        
        // Convert profile to property list format
        let profileDict = try profileToPropertyList(profile)
        
        // Serialize to XML plist format
        let data = try PropertyListSerialization.data(
            fromPropertyList: profileDict,
            format: .xml,
            options: 0
        )
        
        return data
    }
    
    func saveProfileToDownloads(_ profile: ConfigurationProfile) throws -> URL {
        let data = try exportProfile(profile)
        
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw ProfileExportError.downloadsDirectoryNotFound
        }
        
        let filename = sanitizeFilename("\(profile.name).mobileconfig")
        let fileURL = downloadsURL.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    func validateProfile(_ profile: ConfigurationProfile) -> [ProfileValidationError] {
        var errors: [ProfileValidationError] = []
        
        // Check name
        if profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyName)
        }
        
        // Check identifier
        if profile.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyIdentifier)
        } else if !isValidIdentifier(profile.identifier) {
            errors.append(.invalidIdentifier)
        }
        
        // Check description
        if profile.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyDescription)
        }
        
        // Check organization
        if profile.organization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.invalidOrganization)
        }
        
        // Check scope
        if !isValidScope(profile.scope) {
            errors.append(.invalidScope)
        }
        
        // Check payloads
        if profile.payloads.isEmpty {
            errors.append(.noPayloads)
        } else {
            // Check for duplicate identifiers
            let identifiers = profile.payloads.map { $0.identifier }
            let duplicates = identifiers.duplicates()
            for duplicate in duplicates {
                errors.append(.duplicatePayloadIdentifier(duplicate))
            }
            
            // Validate individual payloads
            for payload in profile.payloads {
                let payloadErrors = validatePayload(payload)
                for error in payloadErrors {
                    errors.append(.payloadConfigurationError(payload.displayName, error.localizedDescription))
                }
            }
        }
        
        return errors
    }
    
    // MARK: - Enhanced Validation Methods
    
    func validatePayload(_ payload: ProfilePayload) -> [PayloadValidationError] {
        var errors: [PayloadValidationError] = []
        
        // Validate based on payload type
        switch payload.type {
        case "com.apple.MCX.FileVault2":
            errors.append(contentsOf: validateFileVaultPayload(payload))
        case "com.apple.syspolicy.gatekeeper":
            errors.append(contentsOf: validateGatekeeperPayload(payload))
        case "com.apple.wifi.managed":
            errors.append(contentsOf: validateWiFiPayload(payload))
        case "com.apple.vpn.managed":
            errors.append(contentsOf: validateVPNPayload(payload))
        case "com.apple.TCC.configuration-profile-policy":
            errors.append(contentsOf: validatePPTCPayload(payload))
        default:
            // Generic validation for unknown payload types
            errors.append(contentsOf: validateGenericPayload(payload))
        }
        
        return errors
    }
    
    func checkAppleCompliance(_ profile: ConfigurationProfile) -> [ComplianceError] {
        var issues: [ComplianceError] = []
        
        // Check payload combinations
        let payloadTypes = profile.payloads.map { $0.type }
        if hasUnsupportedPayloadCombination(payloadTypes) {
            issues.append(.unsupportedPayloadCombination(payloadTypes))
        }
        
        // Check for missing required fields in each payload
        for payload in profile.payloads {
            let missingFields = getMissingRequiredFields(for: payload.type)
            if !missingFields.isEmpty {
                issues.append(.missingRequiredFields(payload.displayName, missingFields))
            }
        }
        
        // Check version compatibility
        for payload in profile.payloads {
            if let versionIssue = checkVersionCompatibility(payload) {
                issues.append(versionIssue)
            }
        }
        
        return issues
    }
    
    func generateValidationReport(_ profile: ConfigurationProfile) -> String {
        let errors = validateProfile(profile)
        let complianceIssues = checkAppleCompliance(profile)
        let warnings = generateWarnings(profile)
        let suggestions = generateSuggestions(profile, errors: errors, warnings: warnings, complianceIssues: complianceIssues)
        
        var report = "Profile Validation Report\n"
        report += "========================\n\n"
        
        // Summary
        let isValid = errors.isEmpty && complianceIssues.isEmpty
        report += "Summary:\n"
        report += "• Valid: \(isValid ? "Yes" : "No")\n"
        report += "• Errors: \(errors.count)\n"
        report += "• Warnings: \(warnings.count)\n"
        report += "• Compliance Issues: \(complianceIssues.count)\n"
        report += "• Suggestions: \(suggestions.count)\n\n"
        
        // Errors
        if !errors.isEmpty {
            report += "Errors:\n"
            report += "-------\n"
            for error in errors {
                report += "• \(error.localizedDescription)\n"
                if let suggestion = error.suggestion {
                    report += "  Suggestion: \(suggestion)\n"
                }
                report += "\n"
            }
        }
        
        // Warnings
        if !warnings.isEmpty {
            report += "Warnings:\n"
            report += "---------\n"
            for warning in warnings {
                report += "• \(warning.localizedDescription)\n"
                if let suggestion = warning.suggestion {
                    report += "  Suggestion: \(suggestion)\n"
                }
                report += "\n"
            }
        }
        
        // Compliance Issues
        if !complianceIssues.isEmpty {
            report += "Compliance Issues:\n"
            report += "------------------\n"
            for issue in complianceIssues {
                report += "• \(issue.localizedDescription)\n"
                if let suggestion = issue.suggestion {
                    report += "  Suggestion: \(suggestion)\n"
                }
                report += "\n"
            }
        }
        
        // Suggestions
        if !suggestions.isEmpty {
            report += "Suggestions:\n"
            report += "------------\n"
            for suggestion in suggestions.sorted(by: { $0.priority.rawValue < $1.priority.rawValue }) {
                report += "• [\(suggestion.priority.rawValue)] \(suggestion.title)\n"
                report += "  \(suggestion.description)\n"
                report += "  Action: \(suggestion.action)\n\n"
            }
        }
        
        return report
    }
    
    // MARK: - Private Methods
    
    private func isValidScope(_ scope: String) -> Bool {
        return ["System", "User"].contains(scope)
    }
    
    private func validateFileVaultPayload(_ payload: ProfilePayload) -> [PayloadValidationError] {
        var errors: [PayloadValidationError] = []
        
        // Check if FileVault is enabled
        if let enabled = payload.settings["EnableFileVault"] as? Bool, enabled {
            // If enabled, check for required recovery key configuration
            if payload.settings["PersonalRecoveryKey"] == nil && payload.settings["InstitutionalRecoveryKey"] == nil {
                errors.append(.missingRequiredField("Recovery Key"))
            }
        }
        
        return errors
    }
    
    private func validateGatekeeperPayload(_ payload: ProfilePayload) -> [PayloadValidationError] {
        var errors: [PayloadValidationError] = []
        
        // Check for allowed sources configuration
        if payload.settings["AllowedSources"] == nil {
            errors.append(.missingRequiredField("Allowed Sources"))
        }
        
        return errors
    }
    
    private func validateWiFiPayload(_ payload: ProfilePayload) -> [PayloadValidationError] {
        var errors: [PayloadValidationError] = []
        
        // Check for required SSID
        if payload.settings["SSID"] == nil {
            errors.append(.missingRequiredField("SSID"))
        }
        
        // Check for security type
        if payload.settings["SecurityType"] == nil {
            errors.append(.missingRequiredField("Security Type"))
        }
        
        return errors
    }
    
    private func validateVPNPayload(_ payload: ProfilePayload) -> [PayloadValidationError] {
        var errors: [PayloadValidationError] = []
        
        // Check for required server address
        if payload.settings["ServerAddress"] == nil {
            errors.append(.missingRequiredField("Server Address"))
        }
        
        // Check for VPN type
        if payload.settings["VPNType"] == nil {
            errors.append(.missingRequiredField("VPN Type"))
        }
        
        return errors
    }
    
    private func validatePPTCPayload(_ payload: ProfilePayload) -> [PayloadValidationError] {
        var errors: [PayloadValidationError] = []
        
        // Check for service configuration
        if payload.settings["Services"] == nil {
            errors.append(.missingRequiredField("Services"))
        }
        
        return errors
    }
    
    private func validateGenericPayload(_ payload: ProfilePayload) -> [PayloadValidationError] {
        var errors: [PayloadValidationError] = []
        
        // Basic validation for unknown payload types
        if payload.settings.isEmpty {
            errors.append(.missingRequiredField("Configuration"))
        }
        
        return errors
    }
    
    private func hasUnsupportedPayloadCombination(_ payloadTypes: [String]) -> Bool {
        // Define unsupported combinations based on Apple's documentation
        let unsupportedCombinations: Set<Set<String>> = [
            // Example: Some payloads can't be used together
            ["com.apple.MCX.FileVault2", "com.apple.syspolicy.gatekeeper"]
        ]
        
        let currentCombination = Set(payloadTypes)
        return unsupportedCombinations.contains { $0.isSubset(of: currentCombination) }
    }
    
    private func getMissingRequiredFields(for payloadType: String) -> [String] {
        // Define required fields for each payload type
        let requiredFields: [String: [String]] = [
            "com.apple.MCX.FileVault2": ["EnableFileVault"],
            "com.apple.syspolicy.gatekeeper": ["AllowedSources"],
            "com.apple.wifi.managed": ["SSID", "SecurityType"],
            "com.apple.vpn.managed": ["ServerAddress", "VPNType"],
            "com.apple.TCC.configuration-profile-policy": ["Services"]
        ]
        
        return requiredFields[payloadType] ?? []
    }
    
    private func checkVersionCompatibility(_ payload: ProfilePayload) -> ComplianceError? {
        // Check if payload version is compatible with current macOS version
        // This is a simplified check - in practice, you'd compare against actual version requirements
        
        if payload.version < 1 {
            return .versionMismatch(payload.displayName, "\(payload.version)", "1")
        }
        
        return nil
    }
    
    private func generateWarnings(_ profile: ConfigurationProfile) -> [ProfileValidationWarning] {
        var warnings: [ProfileValidationWarning] = []
        
        // Check profile name length
        if profile.name.count > 50 {
            warnings.append(.longProfileName(profile.name))
        }
        
        // Check description length
        if profile.description.count > 200 {
            warnings.append(.longDescription(profile.description))
        }
        
        // Check number of payloads
        if profile.payloads.count > 10 {
            warnings.append(.manyPayloads(profile.payloads.count))
        }
        
        // Check for complex configuration
        let totalSettings = profile.payloads.reduce(0) { $0 + $1.settings.count }
        if totalSettings > 50 {
            warnings.append(.complexConfiguration)
        }
        
        return warnings
    }
    
    private func generateSuggestions(_ profile: ConfigurationProfile, errors: [ProfileValidationError], warnings: [ProfileValidationWarning], complianceIssues: [ComplianceError]) -> [ValidationSuggestion] {
        var suggestions: [ValidationSuggestion] = []
        
        // Generate suggestions based on errors
        if errors.contains(where: { $0 == .emptyName }) {
            suggestions.append(ValidationSuggestion(
                title: "Add Profile Name",
                description: "A descriptive name helps identify the profile's purpose",
                priority: .high,
                action: "Enter a clear, descriptive name for your profile"
            ))
        }
        
        if errors.contains(where: { $0 == .noPayloads }) {
            suggestions.append(ValidationSuggestion(
                title: "Add Payloads",
                description: "Profiles need at least one payload to be functional",
                priority: .high,
                action: "Select and configure appropriate payloads for your needs"
            ))
        }
        
        // Generate suggestions based on warnings
        if warnings.contains(where: { 
            if case .manyPayloads = $0 { return true }
            return false
        }) {
            suggestions.append(ValidationSuggestion(
                title: "Consider Splitting Profile",
                description: "Large profiles can be difficult to manage and troubleshoot",
                priority: .medium,
                action: "Split into logical groups: security, network, applications"
            ))
        }
        
        // Generate suggestions based on compliance issues
        if !complianceIssues.isEmpty {
            suggestions.append(ValidationSuggestion(
                title: "Review Apple Documentation",
                description: "Some configurations may not comply with Apple's requirements",
                priority: .high,
                action: "Check Apple's MDM documentation for compliance requirements"
            ))
        }
        
        // General suggestions
        if profile.payloads.count == 1 {
            suggestions.append(ValidationSuggestion(
                title: "Consider Additional Payloads",
                description: "Single-payload profiles may be limiting",
                priority: .low,
                action: "Explore other payload types that might be useful"
            ))
        }
        
        return suggestions
    }
    
    private func profileToPropertyList(_ profile: ConfigurationProfile) throws -> [String: Any] {
        let payloadDicts = try profile.payloads.map { payload in
            try payloadToPropertyList(payload)
        }
        
        return [
            "PayloadType": "Configuration",
            "PayloadDisplayName": profile.name,
            "PayloadDescription": profile.description,
            "PayloadIdentifier": profile.identifier,
            "PayloadOrganization": profile.organization,
            "PayloadScope": profile.scope,
            "PayloadUUID": UUID().uuidString,
            "PayloadVersion": 1,
            "PayloadContent": payloadDicts
        ]
    }
    
    private func payloadToPropertyList(_ payload: ProfilePayload) throws -> [String: Any] {
        var dict: [String: Any] = [
            "PayloadType": payload.type,
            "PayloadIdentifier": payload.identifier,
            "PayloadUUID": payload.uuid,
            "PayloadDisplayName": payload.displayName,
            "PayloadDescription": payload.description,
            "PayloadVersion": payload.version,
            "PayloadEnabled": payload.enabled
        ]
        
        // Add custom settings
        for (key, value) in payload.settings {
            dict[key] = value
        }
        
        return dict
    }
    
    private func isValidIdentifier(_ identifier: String) -> Bool {
        // Basic validation for reverse domain format
        let components = identifier.components(separatedBy: ".")
        guard components.count >= 2 else { return false }
        
        let validCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
        
        for component in components {
            if component.isEmpty || component.first?.isNumber == true {
                return false
            }
            
            let filtered = String(component.lowercased().unicodeScalars.filter { validCharacters.contains($0) })
            if filtered != component.lowercased() {
                return false
            }
        }
        
        return true
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return filename.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

// MARK: - Profile Export Errors
enum ProfileExportError: LocalizedError {
    case validationFailed([ProfileValidationError])
    case downloadsDirectoryNotFound
    case serializationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            let errorMessages = errors.map { $0.localizedDescription }.joined(separator: "\n")
            return "Profile validation failed:\n\(errorMessages)"
        case .downloadsDirectoryNotFound:
            return "Could not access Downloads directory"
        case .serializationFailed(let error):
            return "Failed to serialize profile: \(error.localizedDescription)"
        }
    }
}

// MARK: - Array Extension for Duplicates
extension Array where Element: Hashable {
    func duplicates() -> [Element] {
        let counts = self.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.filter { $0.value > 1 }.map { $0.key }
    }
}
