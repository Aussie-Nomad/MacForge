//
//  DataDeletionView.swift
//  MacForge
//
//  GDPR Article 17 - Right to Erasure
//  Allows users to permanently delete all their data from MacForge.
//

import SwiftUI
import Foundation

struct DataDeletionView: View {
    @ObservedObject var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var isDeleting = false
    @State private var deletionProgress: Double = 0.0
    @State private var deletionStatus = "Ready to delete"
    @State private var deletionError: String? = nil
    @State private var confirmationText = ""
    @State private var showConfirmation = false
    @State private var deletionCompleted = false
    
    private let requiredConfirmationText = "DELETE MY DATA"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Warning Header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                        .imageAccessibility(label: "Warning icon", hint: "This action cannot be undone")
                    
                    Text("Delete All Data")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .accessibilityLabel("Delete All Data")
                    
                    Text("This action will permanently delete ALL your MacForge data and cannot be undone.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("This action will permanently delete ALL your MacForge data and cannot be undone")
                }
                .padding(.top)
                
                // Data to be deleted
                VStack(alignment: .leading, spacing: 16) {
                    Text("The following data will be permanently deleted:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DeletionDataRow(
                            title: "MDM Account Information",
                            description: "All server URLs, authentication tokens, and account preferences",
                            hasData: !userSettings.mdmAccounts.isEmpty
                        )
                        
                        DeletionDataRow(
                            title: "Profile Configurations",
                            description: "All PPPC settings, payload configurations, and templates",
                            hasData: true
                        )
                        
                        DeletionDataRow(
                            title: "Application Preferences",
                            description: "Theme settings, default values, and UI preferences",
                            hasData: true
                        )
                        
                        DeletionDataRow(
                            title: "Keychain Data",
                            description: "All securely stored credentials and tokens",
                            hasData: true
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.05))
                    )
                }
                
                // Confirmation Section
                if !deletionCompleted {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Confirmation Required")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("To confirm deletion, type the following text exactly:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(requiredConfirmationText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                            )
                        
                        TextField("Type confirmation text here", text: $confirmationText)
                            .textFieldStyle(.roundedBorder)
                            .textFieldAccessibility(
                                label: "Confirmation text input",
                                hint: "Type \(requiredConfirmationText) to confirm deletion"
                            )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.05))
                    )
                }
                
                // Progress Section
                if isDeleting {
                    VStack(spacing: 12) {
                        ProgressView(value: deletionProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .accessibilityLabel("Deletion progress: \(Int(deletionProgress * 100)) percent complete")
                        
                        Text(deletionStatus)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Deletion status: \(deletionStatus)")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
                }
                
                // Status Messages
                if let error = deletionError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                        .accessibilityLabel("Deletion error: \(error)")
                }
                
                if deletionCompleted {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                            .imageAccessibility(label: "Deletion completed", hint: "All data has been successfully deleted")
                        
                        Text("Data deletion completed successfully!")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                        
                        Text("All your MacForge data has been permanently removed.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                    )
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .buttonAccessibility(
                        label: "Cancel",
                        hint: "Close the data deletion dialog"
                    )
                    
                    if !deletionCompleted {
                        Button(action: deleteData) {
                            HStack {
                                if isDeleting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "trash.fill")
                                }
                                Text(isDeleting ? "Deleting..." : "Delete All Data")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.white)
                        .background(Color.red)
                        .disabled(isDeleting || confirmationText != requiredConfirmationText)
                        .buttonAccessibility(
                            label: isDeleting ? "Deleting Data" : "Delete All Data",
                            hint: isDeleting ? "Please wait while your data is being deleted" : "Permanently delete all your MacForge data",
                            isEnabled: !isDeleting && confirmationText == requiredConfirmationText
                        )
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonAccessibility(
                            label: "Close",
                            hint: "Close the data deletion dialog"
                        )
                    }
                }
            }
            .padding()
            .navigationTitle("Delete Data")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonAccessibility(label: "Close", hint: "Close the data deletion view")
                }
            }
        }
    }
    
    private func deleteData() {
        isDeleting = true
        deletionProgress = 0.0
        deletionStatus = "Starting deletion process..."
        deletionError = nil
        
        Task {
            do {
                // Step 1: Delete MDM accounts
                await MainActor.run {
                    deletionProgress = 0.2
                    deletionStatus = "Deleting MDM account data..."
                }
                
                try await deleteMDMAccounts()
                
                // Step 2: Delete profile configurations
                await MainActor.run {
                    deletionProgress = 0.4
                    deletionStatus = "Deleting profile configurations..."
                }
                
                try await deleteProfileConfigurations()
                
                // Step 3: Delete application preferences
                await MainActor.run {
                    deletionProgress = 0.6
                    deletionStatus = "Deleting application preferences..."
                }
                
                try await deleteApplicationPreferences()
                
                // Step 4: Delete keychain data
                await MainActor.run {
                    deletionProgress = 0.8
                    deletionStatus = "Deleting keychain data..."
                }
                
                try await deleteKeychainData()
                
                // Step 5: Final cleanup
                await MainActor.run {
                    deletionProgress = 0.9
                    deletionStatus = "Final cleanup..."
                }
                
                try await performFinalCleanup()
                
                await MainActor.run {
                    deletionProgress = 1.0
                    deletionStatus = "Deletion completed!"
                    deletionCompleted = true
                    isDeleting = false
                }
                
            } catch {
                await MainActor.run {
                    deletionError = "Deletion failed: \(error.localizedDescription)"
                    isDeleting = false
                }
            }
        }
    }
    
    private func deleteMDMAccounts() async throws {
        // Clear MDM accounts from UserSettings
        await MainActor.run {
            userSettings.mdmAccounts.removeAll()
        }
        
        // Delete from Keychain
        let keychainService = KeychainService.shared
        for account in userSettings.mdmAccounts {
            try keychainService.deleteAuthToken(accountId: account.id)
        }
    }
    
    private func deleteProfileConfigurations() async throws {
        // Clear profile defaults
        await MainActor.run {
            userSettings.profileDefaults = ProfileDefaults()
        }
    }
    
    private func deleteApplicationPreferences() async throws {
        // Clear theme preferences
        await MainActor.run {
            userSettings.themePreferences = ThemePreferences()
        }
        
        // Clear general settings
        await MainActor.run {
            userSettings.generalSettings = GeneralSettings()
        }
    }
    
    private func deleteKeychainData() async throws {
        // Delete all keychain items related to MacForge
        let keychainService = KeychainService.shared
        // Delete all MDM account tokens
        for account in userSettings.mdmAccounts {
            try keychainService.deleteAuthToken(accountId: account.id)
        }
    }
    
    private func performFinalCleanup() async throws {
        // Clear any remaining UserDefaults
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix("MacForge") {
                defaults.removeObject(forKey: key)
            }
        }
        
        // Force save changes
        defaults.synchronize()
    }
}

// MARK: - Deletion Data Row
struct DeletionDataRow: View {
    let title: String
    let description: String
    let hasData: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: hasData ? "exclamationmark.triangle.fill" : "minus.circle.fill")
                .foregroundColor(hasData ? .red : .gray)
                .imageAccessibility(
                    label: hasData ? "Data will be deleted" : "No data to delete",
                    hint: "Indicates whether this type of data will be deleted"
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description). \(hasData ? "Data will be deleted" : "No data to delete")")
    }
}

#Preview {
    DataDeletionView(userSettings: UserSettings())
}
