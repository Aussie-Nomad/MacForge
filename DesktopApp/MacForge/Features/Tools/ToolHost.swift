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
            
            // Tool Purpose
            VStack(alignment: .leading, spacing: 16) {
                Text("Tool Purpose")
                    .font(.title2).bold()
                    .foregroundStyle(LCARSTheme.accent)
                
                Text("Package Smelting is a distribution package manager that allows you to analyze, modify, and deploy macOS packages (.pkg files) to your MDM system. This tool helps you understand package contents, validate compatibility, and streamline deployment workflows.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                // Feature Rows
                VStack(spacing: 12) {
                    FeatureRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Package Analysis",
                        description: "Deep inspection of package contents, dependencies, and metadata"
                    )
                    
                    FeatureRow(
                        icon: "arrow.up.doc",
                        title: "MDM Integration",
                        description: "Direct upload and deployment to connected MDM systems"
                    )
                    
                    FeatureRow(
                        icon: "gearshape.2",
                        title: "Package Modification",
                        description: "Edit package properties and customize installation behavior"
                    )
                }
            }
            .padding()
            .background(LCARSTheme.panel)
            .cornerRadius(12)
            
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
                            .contentShape(Rectangle())
                        }
                        .padding()
                        .background(LCARSTheme.panel)
                        .cornerRadius(12)
                        
                    } else {
                        // Drop Zone
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 48))
                                .foregroundStyle(LCARSTheme.accent)
                            
                            Text("Drop a .pkg file here")
                                .font(.headline)
                            
                            Text("or click to browse")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LCARSTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .fill(LCARSTheme.panel.opacity(0.3))
                        )
                        .onTapGesture {
                            selectPackage()
                        }
                        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                            let _ = handlePackageDrop(providers)
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
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
        }
        .padding(24)
        .background(LCARSTheme.background)
    }
    
    private func selectPackage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.fileURL]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            if let _ = panel.url {
                let _ = handlePackageDrop([NSItemProvider()])
                // TODO: Use the selected URL for package analysis
            }
        }
    }
    
    private func handlePackageDrop(_ providers: [NSItemProvider]) -> Bool {
        // TODO: Implement package analysis
        return true
    }
    
    private func uploadToMDM() {
        // TODO: Implement MDM upload
    }
}

// MARK: - Script Builder
class ScriptBuilderModel: ObservableObject {
    @Published var prompt = ""
    @Published var script = ""
    @Published var language = "zsh"
    @Published var isRunning = false
    @Published var errorText: String?
    
    struct Config {
        var provider: AIProviderType = .openai
        var apiKey = ""
        var model = ""
        var baseURL = ""
    }
    
    @Published var config = Config()
    
    func askAI(system: String) async {
        // TODO: Implement AI integration
    }
}

enum AIProviderType: String, CaseIterable, Identifiable {
    case openai = "openai"
    case anthropic = "anthropic"
    case custom = "custom"
    
    var id: String { rawValue }
}



extension Text {
    func lcarsPill() -> some View {
        self.font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(LCARSTheme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LCARSTheme.accent.opacity(0.2))
            )
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
                Task { await vm.askAI(system: "You are a macOS endpoint management expert. Generate production-ready scripts.") } 
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isRunning)
            .contentShape(Rectangle())
            
            Button("Explain") { 
                Task { await vm.askAI(system: "Explain the following script in detail and include security considerations. Return explanation only.") } 
            }
            .buttonStyle(.bordered)
            .disabled(vm.isRunning)
            .contentShape(Rectangle())
            
            Button("Harden") { 
                Task { await vm.askAI(system: "Refactor and harden the following script. Add logging, error handling, and idempotence. Return only the script.") } 
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

// MARK: - Device Foundry
struct DeviceFoundryHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 48))
                            .foregroundStyle(LCARSTheme.accent)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Device Foundry")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(LCARSTheme.accent)
                            Text("Smart & Static Group Creator for devices")
                                .font(.title2)
                                .foregroundStyle(LCARSTheme.textSecondary)
                        }
                    }
                }
                
                // Tool Purpose
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tool Purpose")
                        .font(.title2).bold()
                        .foregroundStyle(LCARSTheme.accent)
                    
                    Text("Device Foundry is a comprehensive device management tool that enables you to create, organize, and manage device groups within your MDM system. This tool provides both smart (dynamic) and static grouping capabilities, allowing you to efficiently categorize devices based on various criteria and manage them at scale.")
                        .font(.body)
                        .foregroundStyle(LCARSTheme.textSecondary)
                }
                
                // Feature Breakdown
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "Smart Groups",
                        description: "Dynamic device grouping based on device properties, user attributes, and real-time conditions"
                    )
                    
                    FeatureRow(
                        icon: "list.bullet.clipboard",
                        title: "Static Groups",
                        description: "Manual device assignment for specific organizational needs and custom workflows"
                    )
                    
                    FeatureRow(
                        icon: "chart.bar.xaxis",
                        title: "Device Analytics",
                        description: "Comprehensive reporting on device distribution, compliance status, and group performance"
                    )
                    
                    FeatureRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Auto-Refresh",
                        description: "Automatic group updates based on changing device conditions and user attributes"
                    )
                    
                    FeatureRow(
                        icon: "network",
                        title: "MDM Integration",
                        description: "Seamless integration with JAMF Pro, Microsoft Intune, and other MDM platforms"
                    )
                    
                    FeatureRow(
                        icon: "gearshape.2",
                        title: "Policy Assignment",
                        description: "Direct policy and profile assignment to device groups for streamlined management"
                    )
                }
                
                // Coming Soon Features
                VStack(alignment: .leading, spacing: 16) {
                    Text("Coming Soon")
                        .font(.title2).bold()
                        .foregroundStyle(LCARSTheme.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ComingSoonFeature(
                            title: "AI-Powered Grouping",
                            description: "Machine learning algorithms to suggest optimal device groupings based on usage patterns"
                        )
                        
                        ComingSoonFeature(
                            title: "Advanced Filtering",
                            description: "Complex filtering rules with AND/OR logic for precise device selection"
                        )
                        
                        ComingSoonFeature(
                            title: "Group Templates",
                            description: "Pre-built group configurations for common enterprise scenarios"
                        )
                        
                        ComingSoonFeature(
                            title: "Bulk Operations",
                            description: "Mass device operations across multiple groups simultaneously"
                        )
                    }
                }
                
                // Status
                HStack {
                    StatusBadge(status: .development, text: "In Development")
                    Spacer()
                    Text("Estimated Release: Q4 2025")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textMuted)
                }
            }
            .padding(24)
        }
        .background(LCARSTheme.background)
    }
}

// MARK: - Blueprint Builder
struct BlueprintBuilderHostView: View {
    var model: BuilderModel
    var selectedMDM: MDMVendor?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 48))
                            .foregroundStyle(LCARSTheme.accent)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Blueprint Builder")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(LCARSTheme.accent)
                            Text("Design reusable configuration blueprints")
                                .font(.title2)
                                .foregroundStyle(LCARSTheme.textSecondary)
                        }
                    }
                }
                
                // Tool Purpose
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tool Purpose")
                        .font(.title2).bold()
                        .foregroundStyle(LCARSTheme.accent)
                    
                    Text("Blueprint Builder is a powerful template system that allows you to create, save, and reuse configuration profiles across different environments and use cases. This tool streamlines the profile creation process by providing pre-built templates and allowing you to customize them for specific organizational needs.")
                        .font(.body)
                        .foregroundStyle(LCARSTheme.textSecondary)
                }
                
                // Feature Breakdown
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    FeatureRow(
                        icon: "doc.on.doc",
                        title: "Template Library",
                        description: "Extensive collection of pre-built configuration templates for common enterprise scenarios"
                    )
                    
                    FeatureRow(
                        icon: "paintbrush",
                        title: "Custom Templates",
                        description: "Create and save your own configuration templates for repeated use"
                    )
                    
                    FeatureRow(
                        icon: "arrow.triangle.branch",
                        title: "Template Inheritance",
                        description: "Build complex templates by combining and extending existing ones"
                    )
                    
                    FeatureRow(
                        icon: "slider.horizontal.3",
                        title: "Variable Substitution",
                        description: "Use placeholders and variables for dynamic configuration generation"
                    )
                    
                    FeatureRow(
                        icon: "square.and.arrow.up",
                        title: "Template Sharing",
                        description: "Export and share templates with team members and other organizations"
                    )
                    
                    FeatureRow(
                        icon: "checkmark.shield",
                        title: "Validation Engine",
                        description: "Built-in validation to ensure templates meet MDM requirements"
                    )
                }
                
                // Template Categories
                VStack(alignment: .leading, spacing: 16) {
                    Text("Template Categories")
                        .font(.title2).bold()
                        .foregroundStyle(LCARSTheme.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        TemplateCategoryCard(
                            title: "Security",
                            description: "Firewall, FileVault, Gatekeeper",
                            icon: "shield",
                            color: .red
                        )
                        
                        TemplateCategoryCard(
                            title: "Network",
                            description: "Wi-Fi, VPN, Proxy",
                            icon: "network",
                            color: .blue
                        )
                        
                        TemplateCategoryCard(
                            title: "Privacy",
                            description: "PPPC, TCC, Location",
                            icon: "lock.shield",
                            color: .green
                        )
                        
                        TemplateCategoryCard(
                            title: "Applications",
                            description: "App restrictions, Updates",
                            icon: "app.badge",
                            color: .orange
                        )
                        
                        TemplateCategoryCard(
                            title: "System",
                            description: "Login, Energy, Notifications",
                            icon: "gearshape",
                            color: .purple
                        )
                        
                        TemplateCategoryCard(
                            title: "Custom",
                            description: "User-defined configurations",
                            icon: "plus.circle",
                            color: .gray
                        )
                    }
                }
                
                // Coming Soon Features
                VStack(alignment: .leading, spacing: 16) {
                    Text("Coming Soon")
                        .font(.title2).bold()
                        .foregroundStyle(LCARSTheme.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ComingSoonFeature(
                            title: "AI Template Suggestions",
                            description: "Intelligent recommendations for template combinations based on your organization's needs"
                        )
                        
                        ComingSoonFeature(
                            title: "Version Control",
                            description: "Track template changes and rollback to previous versions when needed"
                        )
                        
                        ComingSoonFeature(
                            title: "Template Marketplace",
                            description: "Community-driven template sharing and rating system"
                        )
                        
                        ComingSoonFeature(
                            title: "Advanced Variables",
                            description: "Complex variable types including arrays, objects, and conditional logic"
                        )
                    }
                }
                
                // Status
                HStack {
                    StatusBadge(status: .planning, text: "In Planning")
                    Spacer()
                    Text("Estimated Release: Q1 2026")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textMuted)
                }
            }
            .padding(24)
        }
        .background(LCARSTheme.background)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: StatusType
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
    }
}

enum StatusType: CaseIterable {
    case development
    case planning
    case completed
    case testing
    
    var color: Color {
        switch self {
        case .development:
            return .blue
        case .planning:
            return .orange
        case .completed:
            return .green
        case .testing:
            return .yellow
        }
    }
}

// MARK: - Template Category Card
struct TemplateCategoryCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(title)
                .font(.headline)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(LCARSTheme.textSecondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Coming Soon Feature
struct ComingSoonFeature: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "clock.badge")
                .font(.title3)
                .foregroundStyle(LCARSTheme.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(LCARSTheme.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
            }
        }
        .padding(12)
        .background(LCARSTheme.panel.opacity(0.5))
        .cornerRadius(8)
    }
}
