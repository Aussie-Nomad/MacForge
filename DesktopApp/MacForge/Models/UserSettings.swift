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
    
    init() {
        self.profileDefaults = ProfileDefaults()
        self.themePreferences = ThemePreferences()
        self.mdmAccounts = []
        self.generalSettings = GeneralSettings()
        loadSettings()
    }
    
    // MARK: - Save/Load
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(profileDefaults) {
            UserDefaults.standard.set(encoded, forKey: "profileDefaults")
        }
        if let encoded = try? JSONEncoder().encode(themePreferences) {
            UserDefaults.standard.set(encoded, forKey: "themePreferences")
        }
        if let encoded = try? JSONEncoder().encode(mdmAccounts) {
            UserDefaults.standard.set(encoded, forKey: "mdmAccounts")
        }
        if let encoded = try? JSONEncoder().encode(generalSettings) {
            UserDefaults.standard.set(encoded, forKey: "generalSettings")
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "profileDefaults"),
           let decoded = try? JSONDecoder().decode(ProfileDefaults.self, from: data) {
            profileDefaults = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "themePreferences"),
           let decoded = try? JSONDecoder().decode(ThemePreferences.self, from: data) {
            themePreferences = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "mdmAccounts"),
           let decoded = try? JSONDecoder().decode([MDMAccount].self, from: data) {
            mdmAccounts = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "generalSettings"),
           let decoded = try? JSONDecoder().decode(GeneralSettings.self, from: data) {
            generalSettings = decoded
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
struct MDMAccount: Codable, Identifiable, Hashable {
    var id = UUID()
    var vendor: String
    var serverURL: String
    var username: String
    var displayName: String
    var lastUsed: Date
    var isDefault: Bool
    
    init(vendor: String, serverURL: String, username: String, displayName: String) {
        self.vendor = vendor
        self.serverURL = serverURL
        self.username = username
        self.displayName = displayName
        self.lastUsed = Date()
        self.isDefault = false
    }
}

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
