//
//  PPPCEditor.swift
//  MacForge
//
//  Privacy Preferences Policy Control (PPPC) editor for managing app permissions.
//  Allows administrators to configure which apps can access system resources.
//

import SwiftUI
import UniformTypeIdentifiers
import Security
#if os(macOS)
import AppKit
#endif

// MARK: - App Target (bundle + code requirement) with drag-and-drop
struct AppTargetDropView: View {
    @ObservedObject var model: BuilderModel
    @Binding var payload: Payload

    @State private var bundleID: String = ""
    @State private var codeRequirement: String = ""
    @State private var appPath: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("APP TARGET").font(.caption).fontWeight(.heavy).foregroundStyle(LCARSTheme.accent)

            VStack(alignment: .leading, spacing: 8) {
                Text("Bundle Identifier")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("com.company.app", text: $bundleID)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Code Requirement")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("designated => ...", text: $codeRequirement)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Path")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(appPath.isEmpty ? "No app selected" : appPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Choose App…") { chooseApp() }
                    .buttonStyle(.bordered)
                    .contentShape(Rectangle())
            }

            // Drop Zone
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LCARSTheme.panel)
                    .frame(height: 110)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(LCARSTheme.primary, lineWidth: 2)
                    )
                VStack(spacing: 6) {
                    Text("Drop .app here")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(LCARSTheme.accent)
                    if !appPath.isEmpty {
                        Text(appPath).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                handleDrop(providers)
                return true
            }
        }
        .onAppear(perform: restore)
        .onChange(of: bundleID) { _, newValue in payload.settings["BundleIdentifier"] = .init(newValue) }
        .onChange(of: codeRequirement) { _, newValue in payload.settings["CodeRequirement"] = .init(newValue) }
    }

    private func restore() {
        if let v = payload.settings["BundleIdentifier"]?.value as? String { bundleID = v }
        if let v = payload.settings["CodeRequirement"]?.value as? String { codeRequirement = v }
        if let v = payload.settings["AppPath"]?.value as? String { appPath = v }
    }

    private func chooseApp() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK, let url = panel.url {
            applyApp(at: url)
        }
        #endif
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
            if let url = item as? URL {
                applyApp(at: url)
            } else if let data = item as? Data {
                if let url = URL(dataRepresentation: data, relativeTo: nil) {
                    applyApp(at: url)
                }
            }
        }
        return true
    }

    private func applyApp(at url: URL) {
        DispatchQueue.main.async {
            appPath = url.path
            payload.settings["AppPath"] = .init(url.path)
            if let bid = Bundle(url: url)?.bundleIdentifier {
                bundleID = bid
                payload.settings["BundleIdentifier"] = .init(bid)
                model.identifierType = "bundleID"
            }
            if let req = designatedRequirement(for: url) {
                codeRequirement = req
                payload.settings["CodeRequirement"] = .init(req)
            }
            // Auto-advance the wizard to permissions after selecting an app
            model.wizardStep = max(model.wizardStep, 2)
        }
    }

    private func designatedRequirement(for appURL: URL) -> String? {
        #if os(macOS)
        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(appURL as CFURL, SecCSFlags(), &staticCode)
        guard status == errSecSuccess, let sc = staticCode else { return nil }
        var req: SecRequirement?
        guard SecCodeCopyDesignatedRequirement(sc, SecCSFlags(), &req) == errSecSuccess, let req else { return nil }
        var cfStr: CFString?
        guard SecRequirementCopyString(req, SecCSFlags(), &cfStr) == errSecSuccess, let str = cfStr as String? else { return nil }
        return str
        #else
        return nil
        #endif
    }
}

// MARK: - PPPC Services Editor
struct PPPCServicesEditor: View {
    @ObservedObject var model: BuilderModel
    @State private var showingAddService = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PERMISSIONS").font(.headline).foregroundStyle(LCARSTheme.accent)
                Spacer()
                Button("Add Permission") {
                    showingAddService = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            if model.pppcConfigurations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised")
                        .font(.system(size: 48))
                        .foregroundStyle(LCARSTheme.textMuted)
                    
                    Text("No PPPC permissions configured")
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    Text("Configure privacy permissions for the selected application. Use the Add Permission button to configure permissions.")
                        .font(.body)
                        .foregroundStyle(LCARSTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LCARSTheme.surface.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LCARSTheme.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                )
            } else {
                ForEach(model.pppcConfigurations) { config in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(config.service.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(config.allowed ? "Allow" : "Deny")
                                .font(.caption)
                                .foregroundStyle(config.allowed ? .green : .red)
                            
                            Button("Remove") {
                                model.removePPPCConfiguration(for: config.service.id)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        Text("Identifier: \(config.identifier)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let comment = config.comment {
                            Text("Comment: \(comment)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LCARSTheme.panel.opacity(0.3))
                    )
                }
            }
        }
        .sheet(isPresented: $showingAddService) {
            AddPPPCServiceSheet(
                model: model,
                isPresented: $showingAddService
            )
        }
    }
}

// MARK: - Add PPPC Service Sheet
struct AddPPPCServiceSheet: View {
    @ObservedObject var model: BuilderModel
    @Binding var isPresented: Bool
    
    @State private var selectedService: PPPCService?
    @State private var identifier = ""
    @State private var identifierType = PPPCIdentifierType.bundleID
    @State private var isAllowed = true
    @State private var comment = ""
    
    var body: some View {
        NavigationView {
            VStack {
                serviceSection
                configurationSection
                if let selectedService = selectedService {
                    previewSection
                }
                Spacer()
            }
            .navigationTitle("Add PPPC Permission")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addConfiguration()
                    }
                    .disabled(selectedService == nil || identifier.isEmpty)
                }
            }
            .onAppear {
                // Auto-populate identifier if we have a selected app
                if let bundleID = model.selectedApp?.bundleID {
                    identifier = bundleID
                    identifierType = .bundleID
                }
            }
        }
    }
    
    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Service")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Picker("Privacy Service", selection: $selectedService) {
                Text("Select a service").tag(nil as PPPCService?)
                ForEach(pppcServices) { service in
                    Text(service.name).tag(service as PPPCService?)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Configuration")
                .font(.headline)
                .foregroundStyle(.primary)
            
            TextField("Identifier (Bundle ID or Path)", text: $identifier)
                .textFieldStyle(.roundedBorder)
            
            Picker("Identifier Type", selection: $identifierType) {
                Text("Bundle ID").tag(PPPCIdentifierType.bundleID)
                Text("Path").tag(PPPCIdentifierType.path)
            }
            .pickerStyle(.segmented)
            
            Toggle("Allow Access", isOn: $isAllowed)
            
            TextField("Comment (Optional)", text: $comment)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Service: \(selectedService?.name ?? "")")
                Text("Identifier: \(identifier)")
                Text("Type: \(identifierType.rawValue)")
                Text("Access: \(isAllowed ? "Allow" : "Deny")")
                if !comment.isEmpty {
                    Text("Comment: \(comment)")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func addConfiguration() {
        guard let service = selectedService, !identifier.isEmpty else { return }
        
        var config = PPPCConfiguration(
            service: service,
            identifier: identifier,
            identifierType: identifierType
        )
        config.allowed = isAllowed
        config.comment = comment.isEmpty ? nil : comment
        
        model.addPPPCConfiguration(config)
        isPresented = false
    }
}
