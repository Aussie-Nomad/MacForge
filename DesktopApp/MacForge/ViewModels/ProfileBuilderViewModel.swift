//
//  ProfileBuilderViewModel.swift
//  MacForge
//
//  ViewModel for profile building operations and business logic.
//  Manages profile state, validation, and coordinates with services.

import SwiftUI
import Foundation

// MARK: - PPPC Profile Creator View Model
@MainActor
final class ProfileBuilderViewModel: ObservableObject {
    // MARK: - Dependencies
    private let builderModel: BuilderModel
    private let profileExportService: ProfileExportServiceProtocol
    private let selectedMDM: MDMVendor?
    
    // MARK: - Published Properties
    @Published var wizardStep = 1
    @Published var wizardMode = true
    @Published var showJamfAuthSheet = false
    @Published var submitError: String?
    @Published var isSubmitting = false
    @Published var profileSettings: ProfileSettings
    
    // MARK: - Computed Properties
    var currentStep: Int { wizardStep }
    
    // MARK: - Initialization
    init(builderModel: BuilderModel, selectedMDM: MDMVendor? = nil) {
        self.builderModel = builderModel
        self.selectedMDM = selectedMDM
        self.profileExportService = ProfileExportService()
        self.profileSettings = builderModel.settings
        
        // Clear any pre-selected payloads when ProfileBuilder is initialized
        builderModel.dropped.removeAll()
    }
    
    // MARK: - Public Methods
    
    func nextStep() {
        guard canAdvanceToNextStep else { return }
        
        // Validate current step before advancing
        if !validateCurrentStep() {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            wizardStep = min(3, wizardStep + 1)
        }
        
        // Update builder model wizard step for consistency
        builderModel.wizardStep = wizardStep
    }
    
    func previousStep() {
        guard canGoToPreviousStep else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            wizardStep = max(1, wizardStep - 1)
        }
        
        // Update builder model wizard step for consistency
        builderModel.wizardStep = wizardStep
    }
    
    func goToStep(_ step: Int) {
        guard step >= 1 && step <= 3 else { return }
        
        // Validate that we can go to the target step
        if step > wizardStep && !canAdvanceToStep(step) {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            wizardStep = step
        }
        
        // Update builder model wizard step for consistency
        builderModel.wizardStep = wizardStep
    }
    
    func resetWizard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            wizardStep = 1
        }
        
        // Clear any existing configurations when resetting
        builderModel.pppcConfigurations.removeAll()
        builderModel.suggestedServiceIDs.removeAll()
        builderModel.dropped.removeAll()
        builderModel.selectedApp = nil
        
        // Update builder model wizard step for consistency
        builderModel.wizardStep = wizardStep
    }
    
    func togglePayload(_ payload: Payload) {
        if builderModel.dropped.contains(where: { $0.id == payload.id }) {
            builderModel.remove(payload.id)
        } else {
            builderModel.add(payload)
        }
    }
    
    func exportProfile() {
        do {
            let data = try builderModel.exportProfile()
            saveProfileToDownloads(data, name: builderModel.settings.name)
            submitError = nil
        } catch {
            submitError = error.localizedDescription
        }
    }
    
    func submitProfile() {
        guard let mdm = selectedMDM else {
            submitError = "Pick an MDM before submitting."
            return
        }
        
        switch mdm {
        case .jamf:
            showJamfAuthSheet = true
        default:
            submitError = "Submitting to \(mdm.rawValue) is coming soon."
        }
    }
    
    func handleJamfAuthResult(_ result: JamfAuthResult) {
        switch result {
        case .success(let baseURL, let clientID, let clientSecret):
            Task {
                await submitToJAMF(baseURL: baseURL, clientID: clientID, clientSecret: clientSecret)
            }
        case .failure(let error):
            submitError = error.localizedDescription
        case .cancelled:
            break
        }
    }
    
    func addPPPCPayload() {
        if let p = builderModel.library.first(where: { $0.id == "pppc" }) {
            builderModel.add(p)
            // Auto-advance to step 2 after adding PPPC
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { self.wizardStep = 2 }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var canAdvanceToNextStep: Bool {
        switch wizardStep {
        case 1:
            return hasPPPCPayload && hasValidAppSelection
        case 2:
            return hasConfiguredPermissions && hasValidPermissions
        case 3:
            return hasValidProfileSettings
        default:
            return false
        }
    }
    
    var canGoToPreviousStep: Bool {
        return wizardStep > 1
    }
    
    var canAdvanceToStep: (Int) -> Bool {
        return { targetStep in
            switch targetStep {
            case 1:
                return true // Always can go to first step
            case 2:
                return self.hasPPPCPayload && self.hasValidAppSelection
            case 3:
                return self.hasPPPCPayload && self.hasValidAppSelection && self.hasConfiguredPermissions && self.hasValidPermissions
            default:
                return false
            }
        }
    }
    
    var nextButtonTitle: String {
        return wizardStep < 3 ? "Next" : "Finish"
    }
    
    var hasPPPCPayload: Bool {
        return builderModel.dropped.contains { $0.id == "pppc" }
    }
    
    var hasValidAppSelection: Bool {
        return builderModel.selectedApp != nil
    }
    
    var hasConfiguredPermissions: Bool {
        // Check if PPPC payload is selected and has configurations
        if builderModel.dropped.contains(where: { $0.id == "pppc" }) {
            return !builderModel.pppcConfigurations.isEmpty
        }
        return true // Other payloads don't need special permission configuration
    }
    
    var hasValidPermissions: Bool {
        // Validate that all PPPC configurations have required fields
        for config in builderModel.pppcConfigurations {
            if config.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
            
            if config.service.requiresCodeRequirement && (config.codeRequirement?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                return false
            }
        }
        return true
    }
    
    var hasValidProfileSettings: Bool {
        let settings = builderModel.settings
        return !settings.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !settings.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !settings.organization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var humanSummary: [String] {
        return builderModel.humanSummary()
    }
    
    // MARK: - Private Methods
    
    private func validateCurrentStep() -> Bool {
        switch wizardStep {
        case 1:
            return hasPPPCPayload && hasValidAppSelection
        case 2:
            return hasConfiguredPermissions && hasValidPermissions
        case 3:
            return hasValidProfileSettings
        default:
            return false
        }
    }
    
    private func submitToJAMF(baseURL: URL, clientID: String, clientSecret: String) async {
        isSubmitting = true
        submitError = nil
        
        defer { isSubmitting = false }
        
        do {
            // For now, just export the profile - authentication will be handled separately
            _ = try builderModel.exportProfile()
            
            // TODO: Implement proper JAMF submission after authentication
            // This would involve using the AuthenticationService to get a token
            // and then using JAMFService to submit the profile
            
            submitError = nil
        } catch {
            submitError = error.localizedDescription
        }
    }
    
    private func saveProfileToDownloads(_ data: Data, name: String) {
        do {
            let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            let fileName = "\(name).mobileconfig"
            
            guard let fileURL = downloadsPath?.appendingPathComponent(fileName) else {
                submitError = "Could not access Downloads directory"
                return
            }
            
            try data.write(to: fileURL)
            
            // Show success feedback
            DispatchQueue.main.async {
                // You could add a success message here
                print("Profile saved successfully to: \(fileURL.path)")
            }
            
        } catch {
            submitError = "Failed to save profile: \(error.localizedDescription)"
            print("Save error: \(error)")
        }
    }
}
