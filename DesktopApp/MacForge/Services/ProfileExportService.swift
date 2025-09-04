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
        
        // Check if we can write to the Downloads directory
        if !FileManager.default.isWritableFile(atPath: downloadsURL.path) {
            throw ProfileExportError.permissionDenied
        }
        
        // Try to write the file
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            // If direct write fails, try to create the directory first
            try FileManager.default.createDirectory(at: downloadsURL, withIntermediateDirectories: true, attributes: nil)
            try data.write(to: fileURL)
            return fileURL
        }
    }
    
    func validateProfile(_ profile: ConfigurationProfile) -> [ProfileValidationError] {
        var errors: [ProfileValidationError] = []
        
        // Check name
        if profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyName)
        } else if profile.name.count > 100 {
            errors.append(.nameTooLong)
        }
        
        // Check identifier
        if profile.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyIdentifier)
        } else if !isValidIdentifier(profile.identifier) {
            errors.append(.invalidIdentifier)
        }
        
        // Check organization
        if profile.organization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyOrganization)
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
                errors.append(contentsOf: payloadErrors)
            }
        }
        
        return errors
    }
    
    private func validatePayload(_ payload: ProfilePayload) -> [ProfileValidationError] {
        var errors: [ProfileValidationError] = []
        
        // Check payload type
        if payload.type.isEmpty {
            errors.append(.invalidPayloadType(payload.identifier))
        }
        
        // Check payload identifier
        if payload.identifier.isEmpty {
            errors.append(.emptyPayloadIdentifier)
        }
        
        // Check payload display name
        if payload.displayName.isEmpty {
            errors.append(.emptyPayloadDisplayName(payload.identifier))
        }
        
        // Validate PPPC payload specifically
        if payload.type == "com.apple.TCC" {
            let pppcErrors = validatePPPCPayload(payload)
            errors.append(contentsOf: pppcErrors)
        }
        
        // Validate WiFi payload specifically
        if payload.type == "com.apple.wifi.managed" {
            let wifiErrors = validateWiFiPayload(payload)
            errors.append(contentsOf: wifiErrors)
        }
        
        // Validate VPN payload specifically
        if payload.type == "com.apple.vpn.managed" {
            let vpnErrors = validateVPNPayload(payload)
            errors.append(contentsOf: vpnErrors)
        }
        
        return errors
    }
    
    private func validatePPPCPayload(_ payload: ProfilePayload) -> [ProfileValidationError] {
        var errors: [ProfileValidationError] = []
        
        guard let services = payload.settings["Services"] as? [[String: Any]] else {
            errors.append(.missingPPPCServices(payload.identifier))
            return errors
        }
        
        if services.isEmpty {
            errors.append(.emptyPPPCServices(payload.identifier))
            return errors
        }
        
        for (index, service) in services.enumerated() {
            // Check required fields
            if let serviceName = service["Service"] as? String, serviceName.isEmpty {
                errors.append(.invalidPPPCServiceName(payload.identifier, index))
            }
            
            if let authorization = service["Authorization"] as? String, authorization.isEmpty {
                errors.append(.missingPPPCAuthorization(payload.identifier, index))
            }
            
            // Check identifier requirements
            if let identifier = service["Identifier"] as? String, identifier.isEmpty {
                errors.append(.missingPPPCIdentifier(payload.identifier, index))
            }
        }
        
        return errors
    }
    
    private func validateWiFiPayload(_ payload: ProfilePayload) -> [ProfileValidationError] {
        var errors: [ProfileValidationError] = []
        
        // Check required SSID
        if let ssid = payload.settings["SSID"] as? String, ssid.isEmpty {
            errors.append(.missingWiFiSSID(payload.identifier))
        }
        
        // Check security type
        if let securityType = payload.settings["SecurityType"] as? String, securityType.isEmpty {
            errors.append(.missingWiFiSecurityType(payload.identifier))
        }
        
        // Check password for secured networks
        if let securityType = payload.settings["SecurityType"] as? String,
           securityType != "None",
           let password = payload.settings["Password"] as? String,
           password.isEmpty {
            errors.append(.missingWiFiPassword(payload.identifier))
        }
        
        return errors
    }
    
    private func validateVPNPayload(_ payload: ProfilePayload) -> [ProfileValidationError] {
        var errors: [ProfileValidationError] = []
        
        // Check required server address
        if let serverAddress = payload.settings["ServerAddress"] as? String, serverAddress.isEmpty {
            errors.append(.missingVPNServerAddress(payload.identifier))
        }
        
        // Check VPN type
        if let vpnType = payload.settings["VPNType"] as? String, vpnType.isEmpty {
            errors.append(.missingVPNType(payload.identifier))
        }
        
        // Check authentication method
        if let authMethod = payload.settings["AuthenticationMethod"] as? String, authMethod.isEmpty {
            errors.append(.missingVPNAuthenticationMethod(payload.identifier))
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
    case permissionDenied
    case serializationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            let errorMessages = errors.map { $0.localizedDescription }.joined(separator: "\n")
            return "Profile validation failed:\n\(errorMessages)"
        case .downloadsDirectoryNotFound:
            return "Could not access Downloads directory"
        case .permissionDenied:
            return "Permission denied: Cannot write to Downloads directory"
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
