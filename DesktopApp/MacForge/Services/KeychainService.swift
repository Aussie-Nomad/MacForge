//
//  KeychainService.swift
//  MacForge
//
//  Secure credential storage using Keychain Services.
//  Replaces insecure UserDefaults storage for sensitive data.
//

import Foundation
import Security

// MARK: - Keychain Service
final class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Generic Keychain Operations
    
    /// Store data securely in keychain
    func store(key: String, data: Data, service: String = "MacForge") throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    /// Retrieve data from keychain
    func retrieve(key: String, service: String = "MacForge") throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    /// Delete data from keychain
    func delete(key: String, service: String = "MacForge") throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    /// Check if key exists in keychain
    func exists(key: String, service: String = "MacForge") -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Convenience Methods for Common Data Types
    
    /// Store string securely
    func storeString(key: String, value: String, service: String = "MacForge") throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try store(key: key, data: data, service: service)
    }
    
    /// Retrieve string securely
    func retrieveString(key: String, service: String = "MacForge") throws -> String {
        let data = try retrieve(key: key, service: service)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
    
    /// Store codable object securely
    func storeCodable<T: Codable>(key: String, value: T, service: String = "MacForge") throws {
        let data = try JSONEncoder().encode(value)
        try store(key: key, data: data, service: service)
    }
    
    /// Retrieve codable object securely
    func retrieveCodable<T: Codable>(key: String, type: T.Type, service: String = "MacForge") throws -> T {
        let data = try retrieve(key: key, service: service)
        return try JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - MDM Account Specific Methods
    
    /// Store MDM account securely
    func storeMDMAccount(_ account: MDMAccount) throws {
        try storeCodable(key: "mdm_account_\(account.id.uuidString)", value: account, service: "MacForge.MDM")
    }
    
    /// Retrieve MDM account securely
    func retrieveMDMAccount(id: UUID) throws -> MDMAccount {
        return try retrieveCodable(key: "mdm_account_\(id.uuidString)", type: MDMAccount.self, service: "MacForge.MDM")
    }
    
    /// Store authentication token securely
    func storeAuthToken(accountId: UUID, token: String, expiry: Date?) throws {
        let tokenData = AuthTokenData(token: token, expiry: expiry)
        try storeCodable(key: "auth_token_\(accountId.uuidString)", value: tokenData, service: "MacForge.Auth")
    }
    
    /// Retrieve authentication token securely
    func retrieveAuthToken(accountId: UUID) throws -> AuthTokenData {
        return try retrieveCodable(key: "auth_token_\(accountId.uuidString)", type: AuthTokenData.self, service: "MacForge.Auth")
    }
    
    /// Delete authentication token
    func deleteAuthToken(accountId: UUID) throws {
        try delete(key: "auth_token_\(accountId.uuidString)", service: "MacForge.Auth")
    }
    
    /// List all stored MDM accounts
    func listMDMAccounts() throws -> [MDMAccount] {
        // This is a simplified implementation
        // In a real implementation, you'd need to query all items with the service prefix
        return []
    }
    
    /// Clear all MacForge data from keychain
    func clearAllData() throws {
        let services = ["MacForge", "MacForge.MDM", "MacForge.Auth"]
        
        for service in services {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service
            ]
            
            SecItemDelete(query as CFDictionary)
        }
    }
}

// MARK: - Supporting Types

struct AuthTokenData: Codable {
    let token: String
    let expiry: Date?
    
    var isExpired: Bool {
        guard let expiry = expiry else { return false }
        return expiry < Date()
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case itemNotFound
    case invalidData
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store data in keychain (OSStatus: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve data from keychain (OSStatus: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete data from keychain (OSStatus: \(status))"
        case .itemNotFound:
            return "Item not found in keychain"
        case .invalidData:
            return "Invalid data format"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}

// MARK: - Secure Logging

final class SecureLogger {
    static let shared = SecureLogger()
    
    private init() {}
    
    /// Log message securely (no sensitive data)
    func log(_ message: String, level: LogLevel = .info) {
        #if DEBUG
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] [\(level.rawValue.uppercased())] \(message)")
        #endif
    }
    
    /// Log error securely (no sensitive data)
    func logError(_ error: Error, context: String = "") {
        let message = context.isEmpty ? "Error: \(error.localizedDescription)" : "\(context): \(error.localizedDescription)"
        log(message, level: .error)
    }
    
    /// Log network request securely (no sensitive data)
    func logNetworkRequest(url: String, method: String, statusCode: Int? = nil) {
        let status = statusCode != nil ? " (\(statusCode!))" : ""
        log("Network: \(method) \(url)\(status)", level: .debug)
    }
}

enum LogLevel: String {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
