//
//  SettingsView.swift
//  MacForge
//
//  User settings and preferences interface for MacForge.
//

import SwiftUI
import Foundation

struct SettingsView: View {
    @ObservedObject var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddAccount = false
    @State private var selectedTab = "General"
    
    private let tabs = ["General", "Profile Defaults", "Theme", "MDM Accounts"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MacForge Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(LCARSTheme.panel)
            
            // Tab Navigation
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    Button(tab) {
                        selectedTab = tab
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? LCARSTheme.accent : Color.clear)
                    .foregroundStyle(selectedTab == tab ? .black : LCARSTheme.textPrimary)
                    .cornerRadius(8)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            // Tab Content
            TabView(selection: $selectedTab) {
                GeneralSettingsTab(userSettings: userSettings)
                    .tag("General")
                
                ProfileDefaultsTab(userSettings: userSettings)
                    .tag("Profile Defaults")
                
                ThemeSettingsTab(userSettings: userSettings)
                    .tag("Theme")
                
                MDMAccountsTab(userSettings: userSettings, showingAddAccount: $showingAddAccount)
                    .tag("MDM Accounts")
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 600, height: 500)
        .background(LCARSTheme.background)
        .sheet(isPresented: $showingAddAccount) {
            AddMDMAccountView(userSettings: userSettings)
        }
    }
}

// MARK: - General Settings Tab
struct GeneralSettingsTab: View {
    @ObservedObject var userSettings: UserSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Startup Behavior")
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    Picker("Startup Behavior", selection: $userSettings.generalSettings.startupBehavior) {
                        ForEach(GeneralSettings.StartupBehavior.allCases, id: \.self) { behavior in
                            Text(behavior.rawValue).tag(behavior)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Profile Management")
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    Toggle("Remember Last Profile", isOn: $userSettings.generalSettings.rememberLastProfile)
                    Toggle("Enable Notifications", isOn: $userSettings.generalSettings.enableNotifications)
                    
                    HStack {
                        Text("Recent Profiles to Remember:")
                        Spacer()
                        Stepper("\(userSettings.generalSettings.recentProfilesCount)", value: $userSettings.generalSettings.recentProfilesCount, in: 5...50)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Profile Defaults Tab
struct ProfileDefaultsTab: View {
    @ObservedObject var userSettings: UserSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Default Values")
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Identifier Prefix")
                        TextField("com.yourcompany", text: $userSettings.profileDefaults.defaultIdentifierPrefix)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Profile Name")
                        TextField("New Profile", text: $userSettings.profileDefaults.defaultProfileName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export Location")
                        TextField("~/Downloads", text: $userSettings.profileDefaults.defaultExportLocation)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Auto-save")
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    HStack {
                        Text("Auto-save every:")
                        Spacer()
                        Stepper("\(userSettings.profileDefaults.autoSaveInterval) minutes", value: $userSettings.profileDefaults.autoSaveInterval, in: 1...30)
                    }
                    
                    Toggle("Include Metadata", isOn: $userSettings.profileDefaults.includeMetadata)
                }
            }
            .padding()
        }
    }
}

// MARK: - Theme Settings Tab
struct ThemeSettingsTab: View {
    @ObservedObject var userSettings: UserSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance")
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accent Color")
                        Picker("Accent Color", selection: $userSettings.themePreferences.accentColor) {
                            ForEach(ThemePreferences.AccentColor.allCases, id: \.self) { color in
                                HStack {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 16, height: 16)
                                    Text(color.rawValue)
                                }
                                .tag(color)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Panel Opacity: \(Int(userSettings.themePreferences.panelOpacity * 100))%")
                        Slider(value: $userSettings.themePreferences.panelOpacity, in: 0.1...0.9, step: 0.1)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Animations")
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    Picker("Animation Speed", selection: $userSettings.themePreferences.animationSpeed) {
                        ForEach(ThemePreferences.AnimationSpeed.allCases, id: \.self) { speed in
                            Text(speed.rawValue).tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
        }
    }
}

// MARK: - MDM Accounts Tab
struct MDMAccountsTab: View {
    @ObservedObject var userSettings: UserSettings
    @Binding var showingAddAccount: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Saved MDM Accounts")
                    .font(.headline)
                    .foregroundStyle(LCARSTheme.accent)
                
                Spacer()
                
                Button("Add Account") {
                    showingAddAccount = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            if userSettings.mdmAccounts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    Text("No MDM accounts saved")
                        .font(.title3)
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    Text("Add your MDM accounts to quickly connect without re-entering credentials")
                        .font(.body)
                        .foregroundStyle(LCARSTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(userSettings.mdmAccounts) { account in
                        MDMAccountRow(account: account, userSettings: userSettings)
                    }
                    .onDelete(perform: deleteAccount)
                }
            }
        }
        .padding()
    }
    
    private func deleteAccount(offsets: IndexSet) {
        userSettings.mdmAccounts.remove(atOffsets: offsets)
    }
}

// MARK: - MDM Account Row
struct MDMAccountRow: View {
    let account: MDMAccount
    @ObservedObject var userSettings: UserSettings
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.displayName)
                    .font(.headline)
                    .foregroundStyle(LCARSTheme.textPrimary)
                
                Text(account.vendor)
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
                
                Text(account.serverURL)
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textMuted)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if account.isDefault {
                    Text("DEFAULT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(LCARSTheme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LCARSTheme.accent.opacity(0.2))
                        .cornerRadius(4)
                }
                
                // Show authentication status
                if let _ = account.authToken {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption2)
                        Text("Authenticated")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                        Text("No Auth")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                
                Text("Last used: \(account.lastUsed, style: .relative)")
                    .font(.caption2)
                    .foregroundStyle(LCARSTheme.textMuted)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add MDM Account View
struct AddMDMAccountView: View {
    @ObservedObject var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = JAMFAuthenticationService()
    
    @State private var vendor = ""
    @State private var serverURL = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var isAuthenticating = false
    @State private var authStatus = ""
    @State private var showingPassword = false
    
    private let vendors = ["Jamf Pro", "Microsoft Intune", "Kandji", "Mosyle", "Other"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add MDM Account")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MDM Vendor")
                    Picker("Vendor", selection: $vendor) {
                        ForEach(vendors, id: \.self) { vendor in
                            Text(vendor).tag(vendor)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server URL")
                    TextField("https://your-mdm-server.com", text: $serverURL)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                    TextField("your-username", text: $username)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                    TextField("My Company MDM", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                    HStack {
                        if showingPassword {
                            TextField("your-password", text: $password)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("your-password", text: $password)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button(action: { showingPassword.toggle() }) {
                            Image(systemName: showingPassword ? "eye.slash" : "eye")
                                .foregroundStyle(LCARSTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Add Account") {
                    addAccount()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vendor.isEmpty || serverURL.isEmpty || username.isEmpty || displayName.isEmpty || password.isEmpty)
            }
            
            if !authStatus.isEmpty {
                Text(authStatus)
                    .font(.caption)
                    .foregroundStyle(authStatus.contains("success") ? .green : .red)
                    .multilineTextAlignment(.center)
            }
            
            if isAuthenticating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Authenticating...")
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(width: 400)
        .background(LCARSTheme.background)
    }
    
    private func addAccount() {
        isAuthenticating = true
        authStatus = ""
        
        // Set up the authentication callback to store the token
        authService.onTokenReceived = { token, expiry in
            Task { @MainActor in
                // Create the account with authentication
                var newAccount = MDMAccount(
                    vendor: vendor,
                    serverURL: serverURL,
                    username: username,
                    displayName: displayName
                )
                
                // If this is the first account, make it default
                if userSettings.mdmAccounts.isEmpty {
                    newAccount.isDefault = true
                }
                
                // Store the authentication token
                newAccount.authToken = token
                newAccount.tokenExpiry = expiry
                
                // Add the account to user settings
                userSettings.mdmAccounts.append(newAccount)
                
                // Update the authentication status
                authStatus = "Account added successfully with authentication!"
                isAuthenticating = false
                
                // Dismiss after a short delay to show success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        
        // Attempt authentication
        Task {
            do {
                if vendor == "Jamf Pro" {
                    // For Jamf Pro, we'll use basic authentication for now
                    // In a real implementation, you might want to support OAuth
                    _ = try await authService.authenticateBasic(
                        username: username,
                        password: password,
                        serverURL: serverURL
                    )
                } else {
                    // For other vendors, just create the account without authentication for now
                    await MainActor.run {
                        var newAccount = MDMAccount(
                            vendor: vendor,
                            serverURL: serverURL,
                            username: username,
                            displayName: displayName
                        )
                        
                        if userSettings.mdmAccounts.isEmpty {
                            newAccount.isDefault = true
                        }
                        
                        userSettings.mdmAccounts.append(newAccount)
                        authStatus = "Account added successfully!"
                        isAuthenticating = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    authStatus = "Authentication failed: \(error.localizedDescription)"
                    isAuthenticating = false
                }
            }
        }
    }
}

#Preview {
    SettingsView(userSettings: UserSettings())
}
