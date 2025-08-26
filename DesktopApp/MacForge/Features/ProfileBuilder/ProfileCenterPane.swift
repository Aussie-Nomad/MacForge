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
                onExport: viewModel.exportProfile,
                onSubmit: viewModel.submitProfile
            )

            // Main content area
            if model.wizardMode {
                WizardModeContent(model: model, viewModel: viewModel)
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

            // Navigation buttons - always at bottom
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button("Previous") {
                        viewModel.previousStep()
                    }
                    .disabled(!viewModel.canGoToPreviousStep)
                    .contentShape(Rectangle())

                    Spacer()

                    Button(viewModel.nextButtonTitle) {
                        viewModel.nextStep()
                    }
                    .disabled(!viewModel.canAdvanceToNextStep)
                    .contentShape(Rectangle())
                }
                
                // Additional action buttons
                HStack(spacing: 16) {
                    Button("Add PPPC Payload") {
                        viewModel.addPPPCPayload()
                    }
                    .disabled(!viewModel.hasPPPCPayload)
                    .contentShape(Rectangle())
                    
                    Button("Configure Permissions") {
                        // Auto-advance to step 2 for PPPC configuration
                        if viewModel.hasPPPCPayload {
                            viewModel.nextStep()
                        }
                    }
                    .disabled(!viewModel.hasPPPCPayload)
                    .contentShape(Rectangle())
                }
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
