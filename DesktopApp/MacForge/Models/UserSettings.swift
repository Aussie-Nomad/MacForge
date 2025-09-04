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
    @Published var aiAccounts: [AIAccount]
    @Published var generalSettings: GeneralSettings
    @Published var hasSeenWelcome: Bool
    
    private let keychainService = KeychainService.shared
    private let secureLogger = SecureLogger.shared
    
    init() {
        self.profileDefaults = ProfileDefaults()
        self.themePreferences = ThemePreferences()
        self.mdmAccounts = []
        self.aiAccounts = []
        self.generalSettings = GeneralSettings()
        self.hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
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
        UserDefaults.standard.set(hasSeenWelcome, forKey: "hasSeenWelcome")
        
        // Save sensitive accounts to Keychain
        saveMDMAccountsToKeychain()
        saveAIAccountsToKeychain()
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
        
        // Load sensitive accounts from Keychain
        loadMDMAccountsFromKeychain()
        loadAIAccountsFromKeychain()
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
    
    private func saveAIAccountsToKeychain() {
        do {
            // Store each AI account securely in keychain
            for account in aiAccounts {
                try keychainService.storeAIAccount(account)
            }
            
            // Store account IDs list in UserDefaults (non-sensitive)
            let accountIds = aiAccounts.map { $0.id.uuidString }
            UserDefaults.standard.set(accountIds, forKey: "aiAccountIds")
            
        } catch {
            secureLogger.logError(error, context: "Failed to save AI accounts to keychain")
        }
    }
    
    private func loadAIAccountsFromKeychain() {
        // Get account IDs from UserDefaults
        guard let accountIds = UserDefaults.standard.array(forKey: "aiAccountIds") as? [String] else {
            return
        }
        
        var loadedAccounts: [AIAccount] = []
        
        for accountIdString in accountIds {
            guard let accountId = UUID(uuidString: accountIdString) else { continue }
            
            do {
                // Load account from keychain
                let account = try keychainService.retrieveAIAccount(id: accountId)
                loadedAccounts.append(account)
                
            } catch {
                secureLogger.logError(error, context: "Failed to load AI account \(accountIdString)")
                continue
            }
        }
        
        aiAccounts = loadedAccounts
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
    
    // MARK: - AI Account Management
    
    func addAIAccount(_ account: AIAccount) {
        aiAccounts.append(account)
        saveSettings()
    }
    
    func updateAIAccount(_ account: AIAccount) {
        if let index = aiAccounts.firstIndex(where: { $0.id == account.id }) {
            aiAccounts[index] = account
            saveSettings()
        }
    }
    
    func deleteAIAccount(id: UUID) {
        do {
            // Remove from keychain
            try keychainService.delete(key: "ai_account_\(id.uuidString)", service: "MacForge.AI")
            
            // Remove from local array
            aiAccounts.removeAll { $0.id == id }
            
            // Update stored account IDs
            let accountIds = aiAccounts.map { $0.id.uuidString }
            UserDefaults.standard.set(accountIds, forKey: "aiAccountIds")
            
            secureLogger.log("AI account \(id) deleted")
            
        } catch {
            secureLogger.logError(error, context: "Failed to delete AI account \(id)")
        }
    }
    
    func getDefaultAIAccount() -> AIAccount? {
        return aiAccounts.first { $0.isDefault && $0.isActive }
    }
    
    func getActiveAIAccounts() -> [AIAccount] {
        return aiAccounts.filter { $0.isActive }
    }
    
    func setDefaultAIAccount(id: UUID) {
        // Remove default from all accounts
        for index in aiAccounts.indices {
            aiAccounts[index].isDefault = false
        }
        
        // Set new default
        if let index = aiAccounts.firstIndex(where: { $0.id == id }) {
            aiAccounts[index].isDefault = true
            saveSettings()
        }
    }
    
    // MARK: - Welcome Management
    func markWelcomeAsSeen() {
        hasSeenWelcome = true
        saveSettings()
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
            aiAccounts: aiAccounts,
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
            defaults.removeObject(forKey: "aiAccountIds")
            
            // Reset to defaults
            profileDefaults = ProfileDefaults()
            themePreferences = ThemePreferences()
            generalSettings = GeneralSettings()
            mdmAccounts = []
            aiAccounts = []
            
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
    let aiAccounts: [AIAccount]
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
