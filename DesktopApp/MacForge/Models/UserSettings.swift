//
//  UserSettings.swift
//  MacForge
//
//  Basic user settings and preferences for MacForge.
//

import Foundation
import SwiftUI

// MARK: - User Settings Model
class UserSettings: ObservableObject {
    @Published var profileDefaults: ProfileDefaults
    @Published var themePreferences: ThemePreferences
    @Published var mdmAccounts: [MDMAccount]
    @Published var generalSettings: GeneralSettings
    
    private let keychainService = KeychainService.shared
    private let secureLogger = SecureLogger.shared
    
    init() {
        self.profileDefaults = ProfileDefaults()
        self.themePreferences = ThemePreferences()
        self.mdmAccounts = []
        self.generalSettings = GeneralSettings()
        loadSettings()
    }
    
    // MARK: - Save/Load
    private func saveSettings() {
        // Save non-sensitive data to UserDefaults
        if let encoded = try? JSONEncoder().encode(profileDefaults) {
            UserDefaults.standard.set(encoded, forKey: "profileDefaults")
        }
        if let encoded = try? JSONEncoder().encode(themePreferences) {
            UserDefaults.standard.set(encoded, forKey: "themePreferences")
        }
        if let encoded = try? JSONEncoder().encode(generalSettings) {
            UserDefaults.standard.set(encoded, forKey: "generalSettings")
        }
        
        // Save sensitive MDM accounts to Keychain
        saveMDMAccountsToKeychain()
    }
    
    private func saveMDMAccountsToKeychain() {
        do {
            // Store each MDM account securely in keychain
            for account in mdmAccounts {
                try keychainService.storeMDMAccount(account)
                
                // Store auth token separately if it exists
                if let token = account.authToken {
                    try keychainService.storeAuthToken(
                        accountId: account.id,
                        token: token,
                        expiry: account.tokenExpiry
                    )
                }
            }
            
            // Store account IDs list in UserDefaults (non-sensitive)
            let accountIds = mdmAccounts.map { $0.id.uuidString }
            UserDefaults.standard.set(accountIds, forKey: "mdmAccountIds")
            
        } catch {
            secureLogger.logError(error, context: "Failed to save MDM accounts to keychain")
        }
    }
    
    private func loadSettings() {
        // Load non-sensitive data from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "profileDefaults"),
           let decoded = try? JSONDecoder().decode(ProfileDefaults.self, from: data) {
            profileDefaults = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "themePreferences"),
           let decoded = try? JSONDecoder().decode(ThemePreferences.self, from: data) {
            themePreferences = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "generalSettings"),
           let decoded = try? JSONDecoder().decode(GeneralSettings.self, from: data) {
            generalSettings = decoded
        }
        
        // Load sensitive MDM accounts from Keychain
        loadMDMAccountsFromKeychain()
    }
    
    private func loadMDMAccountsFromKeychain() {
        // Get account IDs from UserDefaults
        guard let accountIds = UserDefaults.standard.array(forKey: "mdmAccountIds") as? [String] else {
            return
        }
        
        var loadedAccounts: [MDMAccount] = []
        
        for accountIdString in accountIds {
            guard let accountId = UUID(uuidString: accountIdString) else { continue }
            
            do {
                // Load account from keychain
                let account = try keychainService.retrieveMDMAccount(id: accountId)
                
                // Load auth token if it exists
                do {
                    let tokenData = try keychainService.retrieveAuthToken(accountId: accountId)
                    var updatedAccount = account
                    updatedAccount.authToken = tokenData.isExpired ? nil : tokenData.token
                    updatedAccount.tokenExpiry = tokenData.expiry
                    loadedAccounts.append(updatedAccount)
                } catch {
                    // No auth token stored, use account as-is
                    loadedAccounts.append(account)
                }
                
            } catch {
                secureLogger.logError(error, context: "Failed to load MDM account \(accountIdString)")
                continue
            }
        }
        
        mdmAccounts = loadedAccounts
    }
    
    // MARK: - MDM Account Management
    
    func updateMDMAccountAuth(_ accountId: UUID, token: String, expiry: Date?) {
        if let index = mdmAccounts.firstIndex(where: { $0.id == accountId }) {
            mdmAccounts[index].authToken = token
            mdmAccounts[index].tokenExpiry = expiry
            mdmAccounts[index].lastUsed = Date()
            
            // Store auth token securely in keychain
            do {
                try keychainService.storeAuthToken(accountId: accountId, token: token, expiry: expiry)
            } catch {
                secureLogger.logError(error, context: "Failed to store auth token in keychain")
            }
            
            saveSettings()
        }
    }
    
    func getValidMDMAccount() -> MDMAccount? {
        return mdmAccounts.first { account in
            guard account.authToken != nil else { return false }
            
            // Check if token is expired
            if let expiry = account.tokenExpiry, expiry < Date() {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - GDPR Compliance Methods
    
    /// Export all user data for GDPR compliance
    func exportUserData() -> UserDataExport {
        let appPreferences: [String: String] = [
            "isLCARSActive": String(themePreferences.isLCARSActive),
            "panelOpacity": String(themePreferences.panelOpacity),
            "animationSpeed": themePreferences.animationSpeed.rawValue,
            "accentColor": themePreferences.accentColor.rawValue,
            "defaultIdentifierPrefix": profileDefaults.defaultIdentifierPrefix,
            "defaultProfileName": profileDefaults.defaultProfileName,
            "defaultExportLocation": profileDefaults.defaultExportLocation,
            "autoSaveInterval": String(profileDefaults.autoSaveInterval),
            "includeMetadata": String(profileDefaults.includeMetadata),
            "exportFormat": "JSON"
        ]
        
        let metadata = ExportMetadata(
            totalAccounts: mdmAccounts.count,
            totalProfiles: 1, // ProfileDefaults is a single object
            exportFormat: "JSON",
            dataStructure: "v2.0"
        )
        
        return UserDataExport(
            exportDate: Date(),
            exportVersion: "2.0.0",
            mdmAccounts: mdmAccounts,
            profileDefaults: profileDefaults,
            appPreferences: appPreferences,
            metadata: metadata
        )
    }
    
    /// Delete all user data for GDPR compliance
    func deleteAllUserData() {
        do {
            // Clear all keychain data
            try keychainService.clearAllData()
            
            // Clear UserDefaults
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "profileDefaults")
            defaults.removeObject(forKey: "themePreferences")
            defaults.removeObject(forKey: "generalSettings")
            defaults.removeObject(forKey: "mdmAccountIds")
            
            // Reset to defaults
            profileDefaults = ProfileDefaults()
            themePreferences = ThemePreferences()
            generalSettings = GeneralSettings()
            mdmAccounts = []
            
            secureLogger.log("All user data deleted for GDPR compliance")
            
        } catch {
            secureLogger.logError(error, context: "Failed to delete all user data")
        }
    }
    
    /// Delete specific MDM account data
    func deleteMDMAccount(id: UUID) {
        do {
            // Remove from keychain
            try keychainService.delete(key: "mdm_account_\(id.uuidString)", service: "MacForge.MDM")
            try keychainService.deleteAuthToken(accountId: id)
            
            // Remove from local array
            mdmAccounts.removeAll { $0.id == id }
            
            // Update stored account IDs
            let accountIds = mdmAccounts.map { $0.id.uuidString }
            UserDefaults.standard.set(accountIds, forKey: "mdmAccountIds")
            
            secureLogger.log("MDM account \(id) deleted")
            
        } catch {
            secureLogger.logError(error, context: "Failed to delete MDM account \(id)")
        }
    }
}

// MARK: - Profile Defaults
struct ProfileDefaults: Codable {
    var defaultIdentifierPrefix: String = "com.yourcompany"
    var defaultProfileName: String = "New Profile"
    var defaultExportLocation: String = "~/Downloads"
    var autoSaveInterval: Int = 5 // minutes
    var includeMetadata: Bool = true
    
    mutating func update() {
        // Trigger save when modified
    }
}

// MARK: - Theme Preferences
struct ThemePreferences: Codable {
    var isLCARSActive: Bool = true
    var panelOpacity: Double = 0.3
    var animationSpeed: AnimationSpeed = .normal
    var accentColor: AccentColor = .amber
    
    enum AnimationSpeed: String, CaseIterable, Codable {
        case slow = "Slow"
        case normal = "Normal"
        case fast = "Fast"
        
        var duration: Double {
            switch self {
            case .slow: return 0.5
            case .normal: return 0.3
            case .fast: return 0.1
            }
        }
    }
    
    enum AccentColor: String, CaseIterable, Codable {
        case amber = "Amber"
        case orange = "Orange"
        case purple = "Purple"
        
        var color: Color {
            switch self {
            case .amber: return .orange
            case .orange: return .red
            case .purple: return .purple
            }
        }
    }
}

// MARK: - MDM Account
// Note: MDMAccount is now defined in Types.swift for consistency

// MARK: - General Settings
struct GeneralSettings: Codable {
    var startupBehavior: StartupBehavior = .showLandingPage
    var rememberLastProfile: Bool = true
    var recentProfilesCount: Int = 10
    var enableNotifications: Bool = true
    
    enum StartupBehavior: String, CaseIterable, Codable {
        case showLandingPage = "Show Landing Page"
        case openLastProfile = "Open Last Profile"
        case promptForMDM = "Prompt for MDM Selection"
    }
}

// MARK: - GDPR Compliance Types

struct UserDataExport: Codable {
    let exportDate: Date
    let exportVersion: String
    let mdmAccounts: [MDMAccount]
    let profileDefaults: ProfileDefaults
    let appPreferences: [String: String]
    let metadata: ExportMetadata
    
    var jsonData: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    var formattedJSON: String? {
        guard let data = jsonData else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

struct ExportMetadata: Codable {
    let totalAccounts: Int
    let totalProfiles: Int
    let exportFormat: String
    let dataStructure: String
}
