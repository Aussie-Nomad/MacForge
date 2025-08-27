//
//  ProfileDetailPane.swift
//  MacForge
//
//  Detail pane component for the profile builder interface.
//  Shows detailed configuration options and settings for selected profile sections.

import SwiftUI

struct ProfileDetailPane: View {
    @ObservedObject var model: BuilderModel
    @ObservedObject var viewModel: ProfileBuilderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("PROFILE DETAILS")
                .font(.headline)
                .foregroundStyle(LcarsTheme.amber)

            // Profile summary
            if viewModel.hasPPPCPayload {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PROFILE SUMMARY")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.humanSummary, id: \.self) { summary in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(summary)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
            }

            // Selected payloads detail
            if !model.dropped.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECTED PAYLOADS")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(model.dropped) { payload in
                            PayloadDetailRow(payload: payload)
                        }
                    }
                }
            }

            // Configuration status
            VStack(alignment: .leading, spacing: 8) {
                Text("CONFIGURATION STATUS")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    StatusRow(
                        title: "PPPCP Payload",
                        status: viewModel.hasPPPCPayload ? .configured : .notConfigured
                    )
                    StatusRow(
                        title: "Permissions",
                        status: viewModel.hasConfiguredPermissions ? .configured : .notConfigured
                    )
                    StatusRow(
                        title: "Profile Settings",
                        status: .configured
                    )
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button("Add PPPC Payload") {
                    viewModel.addPPPCPayload()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.hasPPPCPayload)
                .help("Add a Privacy Preferences Policy Control (PPPC) payload to configure app permissions like Full Disk Access, Accessibility, Input Monitoring, and other system services that require user approval.")
                .contentShape(Rectangle())

                Button("Configure Permissions") {
                    // Auto-advance to step 2 for PPPC configuration
                    if viewModel.hasPPPCPayload {
                        viewModel.nextStep()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.hasPPPCPayload)
                .help("Configure the specific permissions and services for the selected application. This allows you to set which system services the app can access.")
                .contentShape(Rectangle())
            }
        }
        .padding(16)
    }
}

// MARK: - Payload Detail Row
struct PayloadDetailRow: View {
    let payload: Payload

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(payload.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text(payload.id)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text(payload.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(LcarsTheme.panel.opacity(0.3)))
    }
}

// MARK: - Status Row
struct StatusRow: View {
    let title: String
    let status: ConfigurationStatus

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: status.iconName)
                    .font(.caption2)
                Text(status.displayText)
                    .font(.caption2)
            }
            .foregroundStyle(status.color)
        }
    }
}

// MARK: - Configuration Status
enum ConfigurationStatus {
    case configured
    case notConfigured
    case error

    var iconName: String {
        switch self {
        case .configured:
            return "checkmark.circle.fill"
        case .notConfigured:
            return "circle"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    var displayText: String {
        switch self {
        case .configured:
            return "Configured"
        case .notConfigured:
            return "Not Configured"
        case .error:
            return "Error"
        }
    }

    var color: Color {
        switch self {
        case .configured:
            return .green
        case .notConfigured:
            return .secondary
        case .error:
            return .red
        }
    }
}
