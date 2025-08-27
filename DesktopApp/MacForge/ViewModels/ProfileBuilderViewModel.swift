//
//  ProfileBuilderViewModel.swift
//  MacForge
//
//  ViewModel for profile building operations and business logic.
//  Manages profile state, validation, and coordinates with services.

import SwiftUI
import Foundation

// MARK: - Profile Builder View Model
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
        withAnimation {
            wizardStep = min(3, wizardStep + 1)
        }
    }
    
    func previousStep() {
        guard canGoToPreviousStep else { return }
        withAnimation {
            wizardStep = max(1, wizardStep - 1)
        }
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
            return hasPPPCPayload
        case 2:
            return hasConfiguredPermissions
        case 3:
            return true
        default:
            return false
        }
    }
    
    var canGoToPreviousStep: Bool {
        return wizardStep > 1
    }
    
    var nextButtonTitle: String {
        return wizardStep < 3 ? "Next" : "Finish"
    }
    
    var hasPPPCPayload: Bool {
        return builderModel.dropped.contains { $0.id == "pppc" }
    }
    
    var hasConfiguredPermissions: Bool {
        // Check if PPPC payload is selected and has configurations
        if builderModel.dropped.contains(where: { $0.id == "pppc" }) {
            return !builderModel.pppcConfigurations.isEmpty
        }
        return true // Other payloads don't need special permission configuration
    }
    
    var humanSummary: [String] {
        return builderModel.humanSummary()
    }
    
    // MARK: - Private Methods
    
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
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        let fileName = "\(name).mobileconfig"
        let fileURL = downloadsPath?.appendingPathComponent(fileName)
        
        if let fileURL = fileURL {
            try? data.write(to: fileURL)
        }
    }
}
