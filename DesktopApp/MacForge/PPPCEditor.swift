//
//  PPPCEditor.swift
//  MacForge
//
//  Created by Assistant on 20/08/2025.
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
            ForEach(model.pppcServices.indices, id: \.self) { i in
                let svc = model.pppcServices[i]
                VStack(alignment: .leading, spacing: 8) {
                    PermissionCard(title: svc.id, decision: $model.pppcServices[i].decision, highlight: model.suggestedServiceIDs.contains(svc.id))
                    if svc.id == "AppleEvents" {
                        HStack(spacing: 10) {
                            ThemedField(title: "AE Receiver (Bundle ID)", text: Binding(
                                get: { model.pppcServices[i].receiverBundleID ?? "" },
                                set: { model.pppcServices[i].receiverBundleID = $0 }
                            ))
                            Picker("Identifier Type", selection: Binding(
                                get: { model.pppcServices[i].receiverIdentifierType ?? "bundleID" },
                                set: { model.pppcServices[i].receiverIdentifierType = $0 }
                            )) {
                                Text("Bundle ID").tag("bundleID")
                                Text("Path").tag("path")
                                Text("Code Requirement").tag("codeRequirement")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 200)
                        }
                    }
                    if svc.id == "ScreenCapture" {
                        Picker("Screen Capture Type", selection: Binding(
                            get: { model.pppcServices[i].screenCaptureType ?? "All" },
                            set: { model.pppcServices[i].screenCaptureType = $0 }
                        )) {
                            Text("All").tag("All")
                            Text("Window Only").tag("WindowOnly")
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 360)
                    }
                }
            }
        }
    }
}


