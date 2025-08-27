//
//  ProfileCenterPane.swift
//  MacForge
//
//  Center pane component for the profile builder interface.
//  Displays the main content area for profile configuration and editing.

import SwiftUI

struct ProfileCenterPane: View {
    @ObservedObject var model: BuilderModel
    @ObservedObject var viewModel: ProfileBuilderViewModel
    var onHome: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            ProfileTopToolbar(
                onHome: onHome,
                onExport: viewModel.exportProfile
            )

            // Main content area
            if model.wizardMode {
                SimpleModeContent(model: model, viewModel: viewModel, onHome: onHome)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                AdvancedModeContent(model: model, viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Simple Mode Content
struct SimpleModeContent: View {
    @ObservedObject var model: BuilderModel
    @ObservedObject var viewModel: ProfileBuilderViewModel
    var onHome: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator with workflow progression
            VStack(spacing: 12) {
                WizardHeader(step: viewModel.currentStep)
                
                // Workflow breadcrumbs
                HStack(spacing: 16) {
                    ForEach(1...3, id: \.self) { step in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(step <= viewModel.currentStep ? LcarsTheme.amber : .secondary.opacity(0.3))
                                .frame(width: 12, height: 12)
                            Text(stepTitle(for: step))
                                .font(.caption)
                                .foregroundStyle(step <= viewModel.currentStep ? LcarsTheme.amber : .secondary)
                        }
                        .opacity(step == viewModel.currentStep ? 1.0 : 0.6)
                        
                        if step < 3 {
                            Rectangle()
                                .fill(.secondary.opacity(0.3))
                                .frame(width: 20, height: 1)
                        }
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            // Step content with proper scrolling
            ScrollView {
                VStack(spacing: 20) {
                    switch viewModel.currentStep {
                    case 1:
                        Step1Content(model: model, viewModel: viewModel)
                    case 2:
                        Step2Content(model: model, viewModel: viewModel)
                    case 3:
                        Step3Content(model: model, viewModel: viewModel)
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Additional action buttons
            HStack(spacing: 16) {
                Button("Add PPPC Payload") {
                    viewModel.addPPPCPayload()
                }
                .disabled(!viewModel.hasPPPCPayload)
                .help("Add a Privacy Preferences Policy Control (PPPC) payload to configure app permissions like Full Disk Access, Accessibility, Input Monitoring, and other system services that require user approval.")
                .contentShape(Rectangle())
                .onHover { isHovered in
                    if isHovered {
                        // Show enhanced tooltip with more context
                        // This will be enhanced with a custom tooltip system
                    }
                }
                
                Button("Configure Permissions") {
                    // Auto-advance to step 2 for PPPC configuration
                    if viewModel.hasPPPCPayload {
                        viewModel.nextStep()
                    }
                }
                .disabled(!viewModel.hasPPPCPayload)
                .help("Configure the specific permissions and services for the selected application. This allows you to set which system services the app can access.")
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 20)
            
            // Navigation buttons - always at bottom
            HStack(spacing: 20) {
                // Previous button - bottom left, 3x larger
                Button("Previous") {
                    viewModel.previousStep()
                }
                .disabled(!viewModel.canGoToPreviousStep)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .contentShape(Rectangle())
                .font(.title2)
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Next/Finish button - bottom right, 3x larger
                Button(viewModel.nextButtonTitle == "Finish" ? "Submit to MDM" : viewModel.nextButtonTitle) {
                    if viewModel.nextButtonTitle == "Finish" {
                        // Submit to MDM instead of just finishing
                        viewModel.submitProfile()
                    } else {
                        viewModel.nextStep()
                    }
                }
                .disabled(!viewModel.canAdvanceToNextStep)
                .buttonStyle(.borderedProminent)
                .tint(viewModel.nextButtonTitle == "Finish" ? .red : .blue)
                .contentShape(Rectangle())
                .font(.title2)
                .frame(height: 60)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helper Functions
    private func stepTitle(for step: Int) -> String {
        switch step {
        case 1: return "Profile Setup"
        case 2: return "PPPC Config"
        case 3: return "Review & Submit"
        default: return "Step \(step)"
        }
    }
}

// MARK: - Advanced Mode Content
struct AdvancedModeContent: View {
    @ObservedObject var model: BuilderModel
    @ObservedObject var viewModel: ProfileBuilderViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile settings
                    SettingsHeader(settings: $viewModel.profileSettings)

                    // Available payloads
                    Group {
                        Text("AVAILABLE PAYLOADS")
                            .font(.headline)
                            .foregroundStyle(LcarsTheme.amber)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(model.library) { payload in
                                PayloadTile(
                                    payload: payload,
                                    isSelected: model.dropped.contains { $0.id == payload.id },
                                    onToggle: { viewModel.togglePayload(payload) }
                                )
                            }
                        }
                    }

                    // Selected payloads
                    if !model.dropped.isEmpty {
                        Group {
                            Text("SELECTED PAYLOADS")
                                .font(.headline)
                                .foregroundStyle(LcarsTheme.amber)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(model.dropped) { payload in
                                    PayloadTile(
                                        payload: payload,
                                        isSelected: true,
                                        onToggle: { viewModel.togglePayload(payload) }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            
            // Expert mode action buttons
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button("Add PPPC Payload") {
                        viewModel.addPPPCPayload()
                    }
                    .disabled(!viewModel.hasPPPCPayload)
                    .help("Add a Privacy Preferences Policy Control (PPPC) payload to configure app permissions like Full Disk Access, Accessibility, Input Monitoring, and other system services that require user approval.")
                    .contentShape(Rectangle())
                    
                    Button("Configure Permissions") {
                        // Auto-advance to step 2 for PPPC configuration
                        if viewModel.hasPPPCPayload {
                            viewModel.nextStep()
                        }
                    }
                    .disabled(!viewModel.hasPPPCPayload)
                    .help("Configure the specific permissions and services for the selected application. This allows you to set which system services the app can access.")
                    .contentShape(Rectangle())
                }
                
                // Export/Submit buttons
                HStack(spacing: 16) {
                    Button("Export Profile") {
                        viewModel.exportProfile()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .contentShape(Rectangle())
                    
                    Spacer()
                    
                    Button("Submit to MDM") {
                        viewModel.submitProfile()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Payload Tile
struct PayloadTile: View {
    let payload: Payload
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(payload.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                Text(payload.description)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? LcarsTheme.amber : LcarsTheme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? LcarsTheme.amber : .secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
