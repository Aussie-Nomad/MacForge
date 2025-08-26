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
            Text("APP TARGET").font(.caption).fontWeight(.heavy).foregroundStyle(LcarsTheme.amber)

            ThemedField(title: "Bundle Identifier", text: $bundleID, placeholder: "com.company.app")
            ThemedField(title: "Code Requirement", text: $codeRequirement, placeholder: "designated => ...", monospaced: true)

            HStack(spacing: 8) {
                ThemedField(title: "App Path", text: Binding.constant(appPath))
                    .opacity(0.8)
                Button("Choose App…") { chooseApp() }
                    .buttonStyle(.bordered)
                    .contentShape(Rectangle())
            }

            DropTarget(acceptedTypes: [.fileURL], onDrop: handleDrop) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LcarsTheme.panel)
                        .frame(height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(LcarsTheme.orange, lineWidth: 2)
                        )
                    VStack(spacing: 6) {
                        Text("Drop .app here")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(LcarsTheme.amber)
                        if !appPath.isEmpty {
                            Text(appPath).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PERMISSIONS").font(.headline).foregroundStyle(LcarsTheme.amber)
            
            if model.pppcConfigurations.isEmpty {
                Text("No PPPC permissions configured. Use the Profile Builder to configure permissions.")
                    .foregroundStyle(.secondary)
                    .italic()
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
                            .fill(LcarsTheme.panel.opacity(0.3))
                    )
                }
            }
        }
    }
}


