//
//  ToolHost.swift
//  MacForge
//
//  Hosting environment for external AI tools and assistants.
//  Manages communication with OpenAI and Anthropic APIs for enhanced functionality.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Package Smelting
struct PackageSmeltingHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?
    
    @State private var selectedPackage: URL?
    @State private var packageInfo: PackageInfo?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("📦 Package Smelting")
                    .font(.largeTitle).bold()
                Spacer()
                if let mdm = selectedMDM {
                    Text("Connected to: \(mdm.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Main content with proper scrolling
            ScrollView {
                VStack(spacing: 16) {
                Text("Distribution Package Manager")
                    .font(.headline)
                
                if let packageInfo = packageInfo {
                    // Package Info Display
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Package Name:")
                            Spacer()
                            Text(packageInfo.name)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Bundle ID:")
                            Spacer()
                            Text(packageInfo.bundleID)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        HStack {
                            Text("Version:")
                            Spacer()
                            Text(packageInfo.version)
                        }
                        
                        HStack {
                            Text("Size:")
                            Spacer()
                            Text(packageInfo.formattedSize)
                        }
                        
                        Button("Upload to \(selectedMDM?.rawValue ?? "MDM")") {
                            // TODO: Implement MDM upload
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedMDM == nil)
                    }
                    .padding()
                    .background(LcarsTheme.panel)
                    .cornerRadius(12)
                    
                } else {
                    // Drop Zone
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(LcarsTheme.amber)
                        
                        Text("Drop a .pkg file here")
                            .font(.headline)
                        
                        Text("or click to browse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LcarsTheme.amber, style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .fill(LcarsTheme.panel.opacity(0.3))
                    )
                    .onTapGesture {
                        selectPackage()
                    }
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handlePackageDrop(providers)
                        return true
                    }
                }
                
                if isAnalyzing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing package...")
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
        }
        .padding(24)
        .background(LcarsTheme.bg)
    }
    
    private func selectPackage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.package]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            selectedPackage = panel.url
            analyzePackage()
        }
    }
    
    private func handlePackageDrop(_ providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    selectedPackage = url
                    analyzePackage()
                }
            }
        }
    }
    
    private func analyzePackage() {
        guard let url = selectedPackage else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        // Simulate package analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            do {
                let packageInfo = try PackageInfo.fromPackage(at: url)
                self.packageInfo = packageInfo
            } catch {
                self.errorMessage = "Failed to analyze package: \(error.localizedDescription)"
            }
            self.isAnalyzing = false
        }
    }
}

// MARK: - Package Info Model
struct PackageInfo {
    let name: String
    let bundleID: String
    let version: String
    let size: Int64
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    static func fromPackage(at url: URL) throws -> PackageInfo {
        // This is a simplified implementation
        // In a real app, you'd parse the package contents
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attributes[.size] as? Int64 ?? 0
        
        return PackageInfo(
            name: url.deletingPathExtension().lastPathComponent,
            bundleID: "com.example.package",
            version: "1.0.0",
            size: size
        )
    }
}

// MARK: - Device Foundry
struct DeviceFoundryHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?

    var body: some View {
        VStack(spacing: 12) {
            Text("🖥 Device Foundry")
                .font(.largeTitle).bold()
            Text("Smart & Static Group Creator for devices.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(LcarsTheme.bg)
    }
}

// MARK: - Blueprint Builder
struct BlueprintBuilderHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?

    var body: some View {
        VStack(spacing: 12) {
            Text("📐 Blueprint Builder")
                .font(.largeTitle).bold()
            Text("Design reusable configuration blueprints.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(LcarsTheme.bg)
    }
}

// MARK: - Hammering Scripts (AI-powered script builder)
private enum AIProviderType: String, CaseIterable, Identifiable, Codable { case openai, anthropic, custom; var id: String { rawValue } }

private struct AIProviderConfig: Codable {
    var provider: AIProviderType = .openai
    var apiKey: String = ""
    var model: String = "gpt-4o-mini"
    var baseURL: String = ""
}

private final class ScriptBuilderModel: ObservableObject {
    @Published var language: String = "zsh"
    @Published var prompt: String = "Create a script to ..."
    @Published var script: String = ""
    @Published var isRunning: Bool = false
    @Published var errorText: String?
    @Published var config: AIProviderConfig = .init()

    func askAI(system: String? = nil) async {
        errorText = nil
        isRunning = true
        defer { isRunning = false }

        do {
            let reply: String
            switch config.provider {
            case .openai:
                reply = try await callOpenAI(system: system)
            case .anthropic:
                reply = try await callAnthropic(system: system)
            case .custom:
                reply = try await callCustom()
            }
            await MainActor.run { self.script = reply }
        } catch {
            await MainActor.run { self.errorText = error.localizedDescription }
        }
    }

    // MARK: - Providers
    private func callOpenAI(system: String?) async throws -> String {
        guard !config.apiKey.isEmpty else { throw NSError(domain: "AI", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key required"]) }
        let url = URL(string: (config.baseURL.isEmpty ? "https://api.openai.com" : config.baseURL) + "/v1/chat/completions")!

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                system != nil ? ["role": "system", "content": system!] : nil,
                ["role": "user", "content": promptForLanguage()]
            ].compactMap { $0 },
            "temperature": 0.2
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw NSError(domain: "AI", code: -1) }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8)
            throw NSError(domain: "AI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg ?? "OpenAI error \(http.statusCode)"])
        }
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let msgObj = choices.first?["message"] as? [String: Any],
           let content = msgObj["content"] as? String {
            return content
        }
        throw NSError(domain: "AI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Malformed OpenAI response"])
    }

    private func callAnthropic(system: String?) async throws -> String {
        guard !config.apiKey.isEmpty else { throw NSError(domain: "AI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Anthropic API key required"]) }
        let url = URL(string: (config.baseURL.isEmpty ? "https://api.anthropic.com" : config.baseURL) + "/v1/messages")!
        let body: [String: Any] = [
            "model": config.model.isEmpty ? "claude-3-5-sonnet-20240620" : config.model,
            "system": system ?? "You are a senior macOS admin script expert.",
            "max_tokens": 1200,
            "messages": [["role": "user", "content": promptForLanguage()]]
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8)
            throw NSError(domain: "AI", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: msg ?? "Anthropic error"])
        }
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let content = json["content"] as? [[String: Any]],
           let first = content.first,
           let text = first["text"] as? String ?? (first["content"] as? String) {
            return text
        }
        throw NSError(domain: "AI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Malformed Anthropic response"])
    }

    private func callCustom() async throws -> String {
        guard let url = URL(string: config.baseURL) else { throw NSError(domain: "AI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Custom endpoint URL required"]) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["prompt": promptForLanguage(), "model": config.model, "apiKey": config.apiKey]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8)
            throw NSError(domain: "AI", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: msg ?? "Custom endpoint error"])
        }
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], let text = json["text"] as? String { return text }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func promptForLanguage() -> String {
        "Write a robust \(language) script. Requirements:\n\(prompt)\nReturn only the final script in a fenced code block."
    }
}

struct HammeringScriptsHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?
    @StateObject private var vm = ScriptBuilderModel()

    var body: some View {
        HStack(spacing: 16) {
            // Left: Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("🔨 Script Builder").font(.largeTitle).bold()
                Text("Generate, fix and explain admin scripts with AI").foregroundStyle(.secondary)

                Group {
                    Text("AI PROVIDER").lcarsPill()
                    Picker("Provider", selection: $vm.config.provider) {
                        ForEach(AIProviderType.allCases) { p in Text(p.rawValue.capitalized).tag(p) }
                    }.pickerStyle(.segmented)

                    if vm.config.provider == .openai || vm.config.provider == .anthropic {
                        ThemedField(title: "API Key", text: $vm.config.apiKey, secure: true)
                        ThemedField(title: "Model", text: $vm.config.model, placeholder: vm.config.provider == .openai ? "gpt-4o-mini" : "claude-3-5-sonnet-20240620")
                        ThemedField(title: "Base URL (optional)", text: $vm.config.baseURL, placeholder: "")
                    } else {
                        ThemedField(title: "Endpoint URL", text: $vm.config.baseURL, placeholder: "https://your-endpoint")
                        ThemedField(title: "Model (optional)", text: $vm.config.model)
                        ThemedField(title: "API Key (optional)", text: $vm.config.apiKey, secure: true)
                    }

                    Text("LANGUAGE").lcarsPill()
                    Picker("Language", selection: $vm.language) {
                        Text("zsh").tag("zsh")
                        Text("bash").tag("bash")
                        Text("python").tag("python")
                        Text("applescript").tag("applescript")
                    }.pickerStyle(.segmented)
                }
                Spacer()
            }
            .frame(width: 340)
            .padding(16)
            .background(LcarsTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Right: Prompt + Script
            VStack(alignment: .leading, spacing: 12) {
                Text("PROMPT").lcarsPill()
                TextEditor(text: $vm.prompt)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(LcarsTheme.orange, lineWidth: 1))

                HStack {
                    Button(vm.isRunning ? "Generating…" : "Generate Script") { Task { await vm.askAI(system: "You are a macOS endpoint management expert. Generate production-ready scripts.") } }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isRunning)
                        .contentShape(Rectangle())
                    Button("Explain") { Task { await vm.askAI(system: "Explain the following script in detail and include security considerations. Return explanation only.") } }
                        .buttonStyle(.bordered)
                        .disabled(vm.isRunning)
                        .contentShape(Rectangle())
                    Button("Harden") { Task { await vm.askAI(system: "Refactor and harden the following script. Add logging, error handling, and idempotence. Return only the script.") } }
                        .buttonStyle(.bordered)
                        .disabled(vm.isRunning)
                        .contentShape(Rectangle())
                }

                if let err = vm.errorText { Text(err).foregroundStyle(.red).font(.footnote) }

                Text("SCRIPT").lcarsPill()
                TextEditor(text: $vm.script)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 260)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(LcarsTheme.orange, lineWidth: 1))

                HStack {
                    Button("Copy") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(vm.script, forType: .string) }
                        .buttonStyle(.bordered)
                        .contentShape(Rectangle())
                    Button("Save to Downloads") { saveScriptToDownloads(text: vm.script, ext: vm.language == "python" ? "py" : (vm.language == "applescript" ? "applescript" : "sh")) }
                        .buttonStyle(.bordered)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(24)
        .background(LcarsTheme.bg)
    }

    private func saveScriptToDownloads(text: String, ext: String) {
        let fm = FileManager.default
        if let dir = fm.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let url = dir.appendingPathComponent("macforge_script_\(Int(Date().timeIntervalSince1970)).\(ext)")
            try? text.data(using: .utf8)?.write(to: url)
        }
    }
}
