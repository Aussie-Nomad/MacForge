//
//  ToolHost.swift
//  MacForge
//
//  Hosting environment for external AI tools and assistants.
//  Manages communication with OpenAI and Anthropic APIs for enhanced functionality.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(LCARSTheme.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Package Casting
struct PackageCastingHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?
    
    var body: some View {
        PackageCastingView()
    }
}

// MARK: - Script Builder
class ScriptBuilderModel: ObservableObject {
    @Published var prompt = ""
    @Published var script = ""
    @Published var language = "zsh"
    @Published var outputMode = "script"
    @Published var isRunning = false
    @Published var errorText: String?
    
    struct Config {
        var provider: AIProviderType = .openai
        var apiKey = ""
        var model = ""
        var baseURL = ""
    }
    
    @Published var config = Config()
    
    func getOutputModeDescription() -> String {
        switch outputMode {
        case "script":
            return "scripts"
        case "extension_attribute":
            return "extension attributes for JAMF (use <result> tags, keep simple and fast)"
        case "one_liner":
            return "one-liner commands (single line, no functions)"
        case "function":
            return "reusable functions (define function, no main execution)"
        default:
            return "scripts"
        }
    }
    
    func askAI(system: String) async {
        await MainActor.run {
            isRunning = true
            errorText = nil
        }
        
        defer {
            Task { @MainActor in
                isRunning = false
            }
        }
        
        do {
            // Validate configuration
            try validateConfiguration()
            
            // Create AI service
            let aiConfig = AIServiceConfig(
                provider: config.provider,
                apiKey: config.apiKey,
                model: config.model,
                baseURL: config.baseURL
            )
            
            let aiService = AIService(config: aiConfig)
            
            // Determine the action based on system prompt
            let result: String
            if system.contains("Generate") {
                result = try await aiService.generateScript(
                    prompt: prompt,
                    language: language,
                    systemPrompt: system
                )
            } else if system.contains("Explain") {
                result = try await aiService.explainScript(
                    script: script,
                    systemPrompt: system
                )
            } else if system.contains("Harden") {
                result = try await aiService.hardenScript(
                    script: script,
                    systemPrompt: system
                )
            } else {
                result = try await aiService.generateScript(
                    prompt: prompt,
                    language: language,
                    systemPrompt: system
                )
            }
            
            await MainActor.run {
                if system.contains("Explain") {
                    // For explanations, append to script with clear separation
                    script = "\(script)\n\n# ===== EXPLANATION =====\n\(result)"
                } else {
                    script = result
                }
                errorText = nil
            }
            
        } catch {
            await MainActor.run {
                errorText = error.localizedDescription
            }
        }
    }
    
    private func validateConfiguration() throws {
        switch config.provider {
        case .openai, .anthropic:
            if config.apiKey.isEmpty {
                throw AIError.missingAPIKey
            }
        case .ollama:
            // Ollama doesn't require API key, but we should validate URL
            if config.baseURL.isEmpty {
                config.baseURL = "http://localhost:11434"
            }
        case .custom:
            if config.baseURL.isEmpty {
                throw AIError.invalidConfiguration
            }
        }
    }
}






struct HammeringScriptsHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?
    @StateObject private var vm = ScriptBuilderModel()

    var body: some View {
        HStack(spacing: 16) {
            ScriptBuilderSettingsView(vm: vm)
            ScriptBuilderMainView(vm: vm)
        }
        .padding(24)
        .background(LCARSTheme.background)
    }
}

struct ScriptBuilderSettingsView: View {
    @ObservedObject var vm: ScriptBuilderModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔨 Script Builder").font(.largeTitle).bold()
            Text("Generate, fix and explain admin scripts with AI").foregroundStyle(.secondary)

            Group {
                Text("AI PROVIDER").lcarsPill()
                Picker("Provider", selection: $vm.config.provider) {
                    ForEach(AIProviderType.allCases) { p in Text(p.displayName).tag(p) }
                }.pickerStyle(.segmented)

                if vm.config.provider == .openai || vm.config.provider == .anthropic {
                    ThemedField(title: "API Key", text: $vm.config.apiKey, secure: true)
                    ThemedField(title: "Model", text: $vm.config.model, placeholder: vm.config.provider == .openai ? "gpt-4o-mini" : "claude-3-5-sonnet-20240620")
                    ThemedField(title: "Base URL (optional)", text: $vm.config.baseURL, placeholder: "")
                } else if vm.config.provider == .ollama {
                    ThemedField(title: "Ollama URL", text: $vm.config.baseURL, placeholder: "http://localhost:11434")
                    ThemedField(title: "Model", text: $vm.config.model, placeholder: "codellama:7b-instruct")
                    Text("No API key required for local Ollama")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                
                Text("OUTPUT MODE").lcarsPill()
                Picker("Output Mode", selection: $vm.outputMode) {
                    Text("Script").tag("script")
                    Text("Extension Attribute").tag("extension_attribute")
                    Text("One-liner").tag("one_liner")
                    Text("Function").tag("function")
                }.pickerStyle(.segmented)
            }
            Spacer()
        }
        .frame(width: 340)
        .padding(16)
        .background(LCARSTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ScriptBuilderMainView: View {
    @ObservedObject var vm: ScriptBuilderModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROMPT").lcarsPill()
            TextEditor(text: $vm.prompt)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(LCARSTheme.primary, lineWidth: 1))

            ScriptBuilderButtonsView(vm: vm)

            if let err = vm.errorText { Text(err).foregroundStyle(.red).font(.footnote) }

            Text("SCRIPT").lcarsPill()
            TextEditor(text: $vm.script)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 260)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(LCARSTheme.primary, lineWidth: 1))

            ScriptBuilderActionButtonsView(vm: vm)
        }
    }
}

struct ScriptBuilderButtonsView: View {
    @ObservedObject var vm: ScriptBuilderModel
    
    var body: some View {
        HStack {
            Button(vm.isRunning ? "Generating…" : "Generate Script") { 
                Task { await vm.askAI(system: "You are a macOS endpoint management expert. Generate clean, production-ready \(vm.language) \(vm.getOutputModeDescription()). Return ONLY the code without explanations, comments, or markdown formatting. Use proper shebang for \(vm.language). Ensure the code is functional and follows best practices.") } 
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isRunning)
            .contentShape(Rectangle())
            
            Button("Explain") { 
                Task { await vm.askAI(system: "Explain the following \(vm.language) script in detail. Include: 1) What the script does, 2) How it works, 3) Security considerations, 4) Potential improvements. Format as a clear explanation with bullet points.") } 
            }
            .buttonStyle(.bordered)
            .disabled(vm.isRunning)
            .contentShape(Rectangle())
            
            Button("Harden") { 
                Task { await vm.askAI(system: "Refactor and harden the following \(vm.language) script. Add: 1) Proper error handling, 2) Input validation, 3) Logging, 4) Idempotence, 5) Security improvements. Return ONLY the improved script code without explanations or markdown.") } 
            }
            .buttonStyle(.bordered)
            .disabled(vm.isRunning)
            .contentShape(Rectangle())
        }
    }
}

struct ScriptBuilderActionButtonsView: View {
    @ObservedObject var vm: ScriptBuilderModel
    
    var body: some View {
        HStack {
            Button("Copy") { 
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(vm.script, forType: .string) 
            }
            .buttonStyle(.bordered)
            .contentShape(Rectangle())
            
            Button("Save to Downloads") { 
                let ext = getFileExtension(for: vm.language)
                saveScriptToDownloads(text: vm.script, ext: ext)
            }
            .buttonStyle(.bordered)
            .contentShape(Rectangle())
        }
    }
    
    private func getFileExtension(for language: String) -> String {
        switch language {
        case "python":
            return "py"
        case "applescript":
            return "applescript"
        default:
            return "sh"
        }
    }
    
    private func saveScriptToDownloads(text: String, ext: String) {
        let fm = FileManager.default
        if let dir = fm.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let url = dir.appendingPathComponent("macforge_script_\(Int(Date().timeIntervalSince1970)).\(ext)")
            try? text.data(using: .utf8)?.write(to: url)
        }
    }
}

// MARK: - Package Info Model
struct PackageInfo {
    let name: String
    let bundleID: String
    let version: String
    let size: Int64
    let contents: [String]
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Device Foundry Lookup
struct DeviceFoundryHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?

    var body: some View {
        SerialNumberCheckerView()
    }
}

// MARK: - Log Burner
struct LogBurnerHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?

    var body: some View {
        LogBurnerView()
    }
}

// MARK: - DDM Blueprints
struct DDMBlueprintsHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?

    var body: some View {
        DDMBlueprintsView()
    }
}