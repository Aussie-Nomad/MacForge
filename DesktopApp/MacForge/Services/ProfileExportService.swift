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
        }
        
        return errors
    }
    
    // MARK: - Private Methods
    
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
