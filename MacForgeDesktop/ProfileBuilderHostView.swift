//
//  ProfileBuilderHostView.swift
//  MacForge
//
//  Created by Danny Mac on 15/08/2025.
//
//  V4 – scaffolded PPPC-like host with sidebar/center/detail panes.
//  The views below are placeholders so the screen runs end-to-end.
//  Wire real editors and templates into the scaffold incrementally.

import SwiftUI

// MARK: - Builder Host (sidebar + center + detail)
struct ProfileBuilderHostView: View {
    @ObservedObject var model: BuilderModel
    let selectedMDM: MDMVendor?
    var onHome: () -> Void

    @State private var showJamfAuthSheet = false
    @State private var submitError: String?

    var body: some View {
        HStack(spacing: 0) {
            // 1) Sidebar
            ProfileSidebar(model: model, onHome: onHome)
                .frame(width: 260)
                .background(LcarsTheme.bg)

            Divider()

            // 2) Center + top toolbar
            VStack(spacing: 0) {
                ProfileTopToolbar(
                    onHome: onHome,
                    onExport: exportProfile,
                    onSubmit: submitProfile
                )
                Divider()
                ProfileCenterPane(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            // 3) Detail inspector (hide in wizard mode)
            if !model.wizardMode {
                ProfileDetailPane(model: model)
                    .frame(width: 320)
                    .background(LcarsTheme.bg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LcarsTheme.bg)
        .sheet(isPresented: $showJamfAuthSheet) {
            // Placeholder auth sheet hook – supply your implementation.
            JamfAuthSheet { result in
                switch result {
                case .success(let client):
                    Task {
                        do {
                            let data = try model.exportMobileConfig()
                            do {
                                try await client.uploadOrUpdateComputerProfileXML(name: model.settings.name, xmlPlist: data)
                                submitError = nil
                            } catch let JamfClient.JamfError.http(code, message) {
                                submitError = "Jamf returned HTTP \(code)\(message != nil ? ": \(message!)" : "")"
                            }
                        } catch {
                            submitError = error.localizedDescription
                        }
                    }
                case .failure(let error):
                    submitError = error.localizedDescription
                case .cancelled:
                    break
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let err = submitError {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Actions
    private func exportProfile() {
        do {
            let data = try model.exportMobileConfig()
            saveProfileToDownloads(data, name: model.settings.name)
            submitError = nil
        } catch {
            submitError = error.localizedDescription
        }
    }

    private func submitProfile() {
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
}

// MARK: - Sidebar (placeholders)
struct ProfileSidebar: View {
    @ObservedObject var model: BuilderModel
    var onHome: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Brand / home
                SidebarBrandHeader()

                // Mode toggle
                HStack {
                    Text("MODE").lcarsPill()
                    Spacer()
                    Toggle(isOn: $model.wizardMode) {
                        Text(model.wizardMode ? "Wizard" : "Expert")
                            .font(.caption)
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()
                }

                // Templates (placeholder)
                Group {
                    Text("TEMPLATES").lcarsPill()
                    LcarsDisabledTile(
                        title: "Security Tools",
                        subtitle: "SentinelOne, CrowdStrike (placeholder)"
                    )
                    LcarsDisabledTile(
                        title: "Asset Management",
                        subtitle: "SolarWinds Service Desk (placeholder)"
                    )
                    LcarsDisabledTile(
                        title: "Browsers",
                        subtitle: "Chrome, Firefox (placeholder)"
                    )
                    LcarsDisabledTile(
                        title: "Developer Tools",
                        subtitle: "Xcode, Docker (placeholder)"
                    )
                    LcarsDisabledTile(
                        title: "Custom Templates",
                        subtitle: "Your saved presets (placeholder)"
                    )
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Top Toolbar (placeholders)
struct ProfileTopToolbar: View {
    var onHome: () -> Void
    var onExport: () -> Void
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("Back") { onHome() }
                .buttonStyle(.bordered)

            Spacer()

            Button("Download .mobileconfig") { onExport() }
                .buttonStyle(.bordered)

            Button("Submit to MDM") { onSubmit() }
                .buttonStyle(.borderedProminent)
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Step 1 Content
struct Step1Content: View {
    @ObservedObject var model: BuilderModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Profile settings
            SettingsHeader(settings: $model.settings)
            
            // App target section
            if let idx = model.dropped.firstIndex(where: { $0.id == "pppc" }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("APP TARGET").font(.headline).foregroundStyle(LcarsTheme.amber)
                    
                    HStack(spacing: 12) {
                        Text("IDENTIFIER TYPE").font(.caption).fontWeight(.heavy).foregroundStyle(LcarsTheme.amber)
                        Picker("Identifier Type", selection: $model.identifierType) {
                            Text("Bundle ID").tag("bundleID")
                            Text("Path").tag("path")
                            Text("Code Requirement").tag("codeRequirement")
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 420)
                    }
                    
                    AppTargetDropView(model: model, payload: $model.dropped[idx])
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ADD PRIVACY PERMISSIONS").font(.headline).foregroundStyle(LcarsTheme.amber)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            if let p = model.library.first(where: { $0.id == "pppc" }) { 
                                model.add(p)
                                // Auto-advance to step 2 after adding PPPC
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation { model.wizardStep = 2 }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(LcarsTheme.amber)
                                Text("Add Privacy Permissions (PPPC)")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Text("This will add the Privacy Preferences Policy Control payload, which allows you to configure app permissions.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(LcarsTheme.panel.opacity(0.3)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(LcarsTheme.amber.opacity(0.5), lineWidth: 1))
                }
            }
        }
    }
}

// MARK: - Step 2 Content
struct Step2Content: View {
    @ObservedObject var model: BuilderModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONFIGURE PERMISSIONS").font(.headline).foregroundStyle(LcarsTheme.amber)
            
            if model.dropped.contains(where: { $0.id == "pppc" }) {
                PPPCServicesEditor(model: model)
                
                // Auto-advance hint
                if model.hasConfiguredPermissions() {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Permissions configured!")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        Text("Click 'Next' to review your configuration.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.green.opacity(0.1)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.green.opacity(0.3), lineWidth: 1))
                }
            } else {
                Text("No PPPC payload found. Please go back to step 1.")
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Step 3 Content
struct Step3Content: View {
    @ObservedObject var model: BuilderModel
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("REVIEW & SAVE").font(.headline).foregroundStyle(LcarsTheme.amber)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(model.humanSummary(), id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(line)
                            .font(.body)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(LcarsTheme.panel.opacity(0.3)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(LcarsTheme.amber.opacity(0.5), lineWidth: 1))
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Download .mobileconfig") {
                    model.saveProfileToDownloads()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Submit to MDM") {
                    onSubmit()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Center Pane (PPPC editor wired in)
struct ProfileCenterPane: View {
    @ObservedObject var model: BuilderModel
    @State private var showJamfAuthSheet = false
    @State private var submitError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LcarsHeader(title: "PROFILE BUILDER")

                // Wizard header + step controls
                VStack(spacing: 8) {
                    WizardHeader(step: model.wizardStep)
                    HStack {
                        Button("Back") { withAnimation { model.wizardStep = max(1, model.wizardStep - 1) } }
                            .buttonStyle(.bordered)
                            .disabled(model.wizardStep == 1)
                        Spacer()
                        Button(model.wizardStep < 3 ? "Next" : "Finish") {
                            withAnimation { model.wizardStep = min(3, model.wizardStep + 1) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                // Step content
                switch model.wizardStep {
                case 1:
                    Step1Content(model: model)
                case 2:
                    Step2Content(model: model)
                case 3:
                    Step3Content(model: model, onSubmit: submitToMDM)
                default:
                    EmptyView()
                }
                
                // Error display
                if let error = submitError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.red.opacity(0.1)))
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showJamfAuthSheet) {
            JamfAuthSheet { result in
                switch result {
                case .success(let client):
                    Task {
                        do {
                            let data = try model.exportMobileConfig()
                            do {
                                try await client.uploadOrUpdateComputerProfileXML(name: model.settings.name, xmlPlist: data)
                                submitError = nil
                            } catch let JamfClient.JamfError.http(code, message) {
                                submitError = "Jamf returned HTTP \(code)\(message != nil ? ": \(message!)" : "")"
                            } catch {
                                submitError = error.localizedDescription
                            }
                        } catch {
                            submitError = "Failed to export profile: \(error.localizedDescription)"
                        }
                    }
                case .failure(let error):
                    submitError = error.localizedDescription
                case .cancelled:
                    break
                }
            }
        }
    }
    
    private func submitToMDM() {
        showJamfAuthSheet = true
    }
}

// MARK: - Detail Pane (placeholder)
struct ProfileDetailPane: View {
    @ObservedObject var model: BuilderModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("DETAILS").lcarsPill()
                LcarsDisabledTile(
                    title: "Inspector",
                    subtitle: "Contextual settings appear here (placeholder)."
                )
                LcarsDisabledTile(
                    title: "Summary",
                    subtitle: model.humanSummary().joined(separator: "\n")
                )
            }
            .padding(12)
        }
    }
}
