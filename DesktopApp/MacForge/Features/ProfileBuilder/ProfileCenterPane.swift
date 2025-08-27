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
                WizardModeContent(model: model, viewModel: viewModel, onHome: onHome)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ExpertModeContent(model: model, viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Wizard Mode Content
struct WizardModeContent: View {
    @ObservedObject var model: BuilderModel
    @ObservedObject var viewModel: ProfileBuilderViewModel
    var onHome: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            WizardHeader(step: viewModel.currentStep)
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
}

// MARK: - Expert Mode Content
struct ExpertModeContent: View {
    @ObservedObject var model: BuilderModel
    @ObservedObject var viewModel: ProfileBuilderViewModel

    var body: some View {
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
