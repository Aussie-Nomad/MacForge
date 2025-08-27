//
//  ProfileSidebar.swift
//  MacForge
//
//  Sidebar component for the profile builder interface.
//  Provides navigation and selection for different profile sections and payloads.

import SwiftUI

struct ProfileSidebar: View {
    @ObservedObject var model: BuilderModel
    var onHome: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Brand / home
                SidebarBrandHeader()

                // Mode toggle
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("MODE").lcarsPill()
                        Spacer()
                        Toggle(isOn: $model.wizardMode) {
                            Text(model.wizardMode ? "Simple" : "Advanced")
                                .font(.caption)
                        }
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                    
                    // Current mode indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(model.wizardMode ? .green : LcarsTheme.amber)
                            .frame(width: 8, height: 8)
                        Text(model.wizardMode ? "Simple Mode Active" : "Advanced Mode Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(model.wizardMode ? .green : LcarsTheme.amber)
                    }
                    
                    // Mode explanation
                    Text(model.wizardMode ? 
                        "Simple Mode: Guided step-by-step profile creation with templates and validation" :
                        "Advanced Mode: Direct configuration with full control over all settings and payloads"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                }

                // Templates
                Group {
                    Text("TEMPLATES").lcarsPill()
                    
                    ForEach(templatesLibrary) { template in
                        Button {
                            applyTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                
                                Text(template.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LcarsTheme.panel.opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(LcarsTheme.amber.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
        }
    }
    
    // MARK: - Template Application
    private func applyTemplate(_ template: TemplateProfile) {
        // Clear current selections
        model.dropped.removeAll()
        
        // Add template payloads
        for payloadID in template.payloadIDs {
            if let payload = model.library.first(where: { $0.id == payloadID }) {
                model.dropped.append(payload)
            }
        }
        
        // Auto-advance to step 2 if PPPC is included
        if template.payloadIDs.contains("pppc") {
            model.wizardStep = 2
        }
    }
}
