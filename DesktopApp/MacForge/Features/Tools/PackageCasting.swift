//
//  PackageCasting.swift
//  MacForge
//
//  Comprehensive package management and repackaging tool inspired by JAMF Composer.
//  Supports analysis, repackaging, signing, and MDM deployment of macOS applications.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Package Analysis Models
struct PackageAnalysis: Identifiable {
    let id = UUID()
    let fileName: String
    let filePath: String
    let fileSize: Int64
    let analysisDate: Date
    let packageType: PackageType
    let metadata: PackageMetadata
    let contents: PackageContents
    let permissions: [FilePermission]
    let scripts: [PackageScript]
    let dependencies: [PackageDependency]
    let securityInfo: SecurityInfo
    let recommendations: [PackageRecommendation]
}

struct PackageMetadata {
    let bundleIdentifier: String?
    let version: String?
    let displayName: String?
    let description: String?
    let author: String?
    let installLocation: String?
    let minimumOSVersion: String?
    let architecture: [String]
    let creationDate: Date?
    let modificationDate: Date?
}

struct PackageContents {
    let files: [PackageFile]
    let directories: [PackageDirectory]
    let totalFiles: Int
    let totalSize: Int64
    let installSize: Int64
}

struct PackageFile: Identifiable {
    let id = UUID()
    let path: String
    let size: Int64
    let permissions: String
    let modificationDate: Date?
    let isExecutable: Bool
    let fileType: String?
}

struct PackageDirectory: Identifiable {
    let id = UUID()
    let path: String
    let permissions: String
    let modificationDate: Date?
}

struct FilePermission {
    let path: String
    let owner: String
    let group: String
    let permissions: String
    let needsRepair: Bool
}

struct PackageScript: Identifiable {
    let id = UUID()
    let name: String
    let type: PackageScriptType
    let content: String
    let isExecutable: Bool
    let needsModification: Bool
}

struct PackageDependency: Identifiable {
    let id = UUID()
    let name: String
    let version: String?
    let type: DependencyType
    let isInstalled: Bool
    let installPath: String?
}

struct SecurityInfo {
    let isSigned: Bool
    let signatureValid: Bool
    let certificateInfo: CertificateInfo?
    let codeRequirements: String?
    let needsSigning: Bool
    let securityIssues: [SecurityIssue]
}

struct CertificateInfo {
    let commonName: String
    let organization: String
    let validityStart: Date
    let validityEnd: Date
    let isDeveloperID: Bool
}

struct SecurityIssue {
    let severity: PackageSecuritySeverity
    let description: String
    let recommendation: String
}

struct PackageRecommendation {
    let type: RecommendationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let action: String
}

// MARK: - Package Types and Enums
enum PackageType: String, CaseIterable {
    case pkg = "PKG"
    case dmg = "DMG"
    case app = "APP"
    case zip = "ZIP"
    case unknown = "UNKNOWN"
    
    var icon: String {
        switch self {
        case .pkg: return "shippingbox.fill"
        case .dmg: return "opticaldisc.fill"
        case .app: return "app.fill"
        case .zip: return "archivebox.fill"
        case .unknown: return "questionmark.folder.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pkg: return .blue
        case .dmg: return .green
        case .app: return .purple
        case .zip: return .orange
        case .unknown: return .gray
        }
    }
}

enum PackageScriptType: String, CaseIterable {
    case preinstall = "Preinstall"
    case postinstall = "Postinstall"
    case preuninstall = "Preuninstall"
    case postuninstall = "Postuninstall"
    case preupgrade = "Preupgrade"
    case postupgrade = "Postupgrade"
    
    var icon: String {
        switch self {
        case .preinstall: return "arrow.down.circle"
        case .postinstall: return "checkmark.circle"
        case .preuninstall: return "arrow.up.circle"
        case .postuninstall: return "xmark.circle"
        case .preupgrade: return "arrow.clockwise.circle"
        case .postupgrade: return "checkmark.circle.fill"
        }
    }
}

enum DependencyType: String, CaseIterable {
    case framework = "Framework"
    case library = "Library"
    case application = "Application"
    case system = "System"
    case unknown = "Unknown"
}

enum PackageSecuritySeverity: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case info = "Info"
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .info: return .green
        }
    }
}

enum RecommendationType: String, CaseIterable {
    case signing = "Code Signing"
    case permissions = "Permissions"
    case scripts = "Scripts"
    case dependencies = "Dependencies"
    case security = "Security"
    case optimization = "Optimization"
    case mdm = "MDM Compatibility"
}

enum RecommendationPriority: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

// MARK: - Repackaging Models
struct RepackagingOptions {
    var addScripts: [PackageScript] = []
    var modifyPermissions: [FilePermission] = []
    var signPackage: Bool = false
    var certificateID: String?
    var addPPPCProfile: Bool = false
    var pppcServices: [String] = []
    var outputFormat: PackageType = .pkg
    var outputName: String = ""
    var version: String = ""
    var bundleID: String = ""
}

struct RepackagingResult {
    let success: Bool
    let outputPath: String?
    let errorMessage: String?
    let warnings: [String]
    let newPackageInfo: PackageAnalysis?
}

// MARK: - Package Analysis Service
@MainActor
class PackageAnalysisService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analysisResult: PackageAnalysis?
    @Published var isRepackaging = false
    @Published var repackagingResult: RepackagingResult?
    
    private let supportedFileTypes: [UTType] = [
        .package,
        .diskImage,
        .application,
        .zip
    ]
    
    func analyzePackage(at url: URL) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let result = await performPackageAnalysis(url: url)
        analysisResult = result
    }
    
    func repackagePackage(options: RepackagingOptions) async {
        guard let analysis = analysisResult else { return }
        
        isRepackaging = true
        repackagingResult = nil
        
        defer { isRepackaging = false }
        
        let result = await performRepackaging(analysis: analysis, options: options)
        repackagingResult = result
    }
    
    private func performPackageAnalysis(url: URL) async -> PackageAnalysis {
        let fileName = url.lastPathComponent
        let fileSize = getFileSize(url: url)
        let packageType = determinePackageType(url: url)
        
        // Simulate analysis - in real implementation, this would use actual package analysis tools
        let metadata = PackageMetadata(
            bundleIdentifier: extractBundleIdentifier(from: url),
            version: extractVersion(from: url),
            displayName: extractDisplayName(from: url),
            description: "Package created with Package Casting",
            author: "Unknown",
            installLocation: "/Applications",
            minimumOSVersion: "12.0",
            architecture: ["x86_64", "arm64"],
            creationDate: Date(),
            modificationDate: Date()
        )
        
        let contents = PackageContents(
            files: extractFiles(from: url),
            directories: extractDirectories(from: url),
            totalFiles: 0, // Would be calculated
            totalSize: fileSize,
            installSize: fileSize
        )
        
        let permissions = analyzePermissions(from: url)
        let scripts = extractScripts(from: url)
        let dependencies = analyzeDependencies(from: url)
        let securityInfo = analyzeSecurity(from: url)
        let recommendations = generateRecommendations(
            packageType: packageType,
            securityInfo: securityInfo,
            scripts: scripts,
            permissions: permissions
        )
        
        return PackageAnalysis(
            fileName: fileName,
            filePath: url.path,
            fileSize: fileSize,
            analysisDate: Date(),
            packageType: packageType,
            metadata: metadata,
            contents: contents,
            permissions: permissions,
            scripts: scripts,
            dependencies: dependencies,
            securityInfo: securityInfo,
            recommendations: recommendations
        )
    }
    
    private func performRepackaging(analysis: PackageAnalysis, options: RepackagingOptions) async -> RepackagingResult {
        // Simulate repackaging process
        // In real implementation, this would:
        // 1. Extract the original package
        // 2. Apply modifications (scripts, permissions, etc.)
        // 3. Sign the package if requested
        // 4. Create new package in specified format
        // 5. Generate PPPC profile if requested
        
        let outputPath = "/tmp/\(options.outputName.isEmpty ? analysis.fileName : options.outputName).\(options.outputFormat.rawValue.lowercased())"
        
        // Simulate successful repackaging
        return RepackagingResult(
            success: true,
            outputPath: outputPath,
            errorMessage: nil,
            warnings: ["Package successfully repackaged"],
            newPackageInfo: nil // Would contain analysis of new package
        )
    }
    
    // MARK: - Helper Methods
    
    private func getFileSize(url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func determinePackageType(url: URL) -> PackageType {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "pkg": return .pkg
        case "dmg": return .dmg
        case "app": return .app
        case "zip": return .zip
        default: return .unknown
        }
    }
    
    private func extractBundleIdentifier(from url: URL) -> String? {
        // In real implementation, would extract from Info.plist or package metadata
        return "com.example.\(url.deletingPathExtension().lastPathComponent.lowercased())"
    }
    
    private func extractVersion(from url: URL) -> String? {
        // In real implementation, would extract from package metadata
        return "1.0.0"
    }
    
    private func extractDisplayName(from url: URL) -> String? {
        return url.deletingPathExtension().lastPathComponent
    }
    
    private func extractFiles(from url: URL) -> [PackageFile] {
        // In real implementation, would extract actual file list
        return []
    }
    
    private func extractDirectories(from url: URL) -> [PackageDirectory] {
        // In real implementation, would extract actual directory list
        return []
    }
    
    private func analyzePermissions(from url: URL) -> [FilePermission] {
        // In real implementation, would analyze actual permissions
        return []
    }
    
    private func extractScripts(from url: URL) -> [PackageScript] {
        // In real implementation, would extract actual scripts
        return []
    }
    
    private func analyzeDependencies(from url: URL) -> [PackageDependency] {
        // In real implementation, would analyze actual dependencies
        return []
    }
    
    private func analyzeSecurity(from url: URL) -> SecurityInfo {
        // In real implementation, would analyze actual security
        return SecurityInfo(
            isSigned: false,
            signatureValid: false,
            certificateInfo: nil,
            codeRequirements: nil,
            needsSigning: true,
            securityIssues: [
                SecurityIssue(
                    severity: .high,
                    description: "Package is not code signed",
                    recommendation: "Sign package with Apple Developer ID certificate"
                )
            ]
        )
    }
    
    private func generateRecommendations(
        packageType: PackageType,
        securityInfo: SecurityInfo,
        scripts: [PackageScript],
        permissions: [FilePermission]
    ) -> [PackageRecommendation] {
        var recommendations: [PackageRecommendation] = []
        
        if securityInfo.needsSigning {
            recommendations.append(PackageRecommendation(
                type: .signing,
                priority: .high,
                title: "Code Sign Package",
                description: "Package is not signed and may be blocked by Gatekeeper",
                action: "Sign with Apple Developer ID certificate"
            ))
        }
        
        if packageType == .app {
            recommendations.append(PackageRecommendation(
                type: .mdm,
                priority: .medium,
                title: "Generate PPPC Profile",
                description: "Application may require privacy permissions for MDM deployment",
                action: "Create PPPC profile for required services"
            ))
        }
        
        return recommendations
    }
}

// MARK: - Package Casting View
struct PackageCastingView: View {
    @StateObject private var analysisService = PackageAnalysisService()
    @State private var isDragOver = false
    @State private var showingAnalysis = false
    @State private var showingRepackaging = false
    @State private var uploadedFileName: String? = nil
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "shippingbox.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Package Casting")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Package Analysis & Repackaging Tool")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Drag & Drop Zone
            VStack(spacing: 16) {
                if analysisService.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Analyzing package...")
                            .font(.headline)
                        if let fileName = uploadedFileName {
                            Text("Processing: \(fileName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Text("This may take a moment for large packages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                } else if let fileName = uploadedFileName, analysisService.analysisResult != nil {
                    // Package analyzed successfully
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Package Analyzed Successfully!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        VStack(spacing: 4) {
                            Text("File: \(fileName)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let result = analysisService.analysisResult {
                                Text("\(result.packageType.rawValue) • \(ByteCountFormatter.string(fromByteCount: result.fileSize, countStyle: .file))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button("View Analysis") {
                                showingAnalysis = true
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Repackage") {
                                showingRepackaging = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            )
                    )
                } else {
                    // Initial state or file uploaded but not analyzed yet
                    VStack(spacing: 16) {
                        Image(systemName: uploadedFileName != nil ? "shippingbox.fill" : "shippingbox")
                            .font(.system(size: 48))
                            .foregroundColor(uploadedFileName != nil ? .blue : (isDragOver ? .blue : .gray))
                        
                        if let fileName = uploadedFileName {
                            Text("Package Ready for Analysis")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            VStack(spacing: 4) {
                                Text("File: \(fileName)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Click 'Analyze' to inspect the package")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Analyze Package") {
                                // Trigger analysis
                                if let fileName = uploadedFileName {
                                    Task {
                                        await analysisService.analyzePackage(at: URL(fileURLWithPath: "/tmp/\(fileName)"))
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                        } else {
                            Text("Drag & Drop Packages Here")
                                .font(.headline)
                                .foregroundColor(isDragOver ? .blue : .primary)
                            
                            Text("Supports: .pkg, .dmg, .app, .zip files")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Browse Files") {
                                showingFilePicker = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(uploadedFileName != nil ? Color.blue.opacity(0.1) : (isDragOver ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(uploadedFileName != nil ? Color.blue : (isDragOver ? Color.blue : Color.gray.opacity(0.3)), style: StrokeStyle(lineWidth: 2, dash: uploadedFileName != nil ? [] : [5]))
                            )
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                        handleFileDrop(providers: providers)
                    }
                }
            }
            
            // Error Message
            if let errorMessage = analysisService.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Package Casting")
        .sheet(isPresented: $showingAnalysis) {
            if let result = analysisService.analysisResult {
                PackageAnalysisView(analysis: result)
            }
        }
        .sheet(isPresented: $showingRepackaging) {
            if let result = analysisService.analysisResult {
                PackageRepackagingView(analysis: result, analysisService: analysisService)
            }
        }
        .onChange(of: showingFilePicker) { _, showing in
            if showing {
                handleFilePicker()
                showingFilePicker = false
            }
        }
    }
    
    // MARK: - File Picker
    private func handleFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.package, .diskImage, .application, .zip]
        panel.title = "Select Package File"
        panel.message = "Choose a package file to analyze (.pkg, .dmg, .app, or .zip)"
        
        if panel.runModal() == .OK, let url = panel.url {
            handleFileSelection(url: url)
        }
    }
    
    private func handleFileSelection(url: URL) {
        uploadedFileName = url.lastPathComponent
        
        Task {
            await analysisService.analyzePackage(at: url)
        }
    }
    
    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    uploadedFileName = url.lastPathComponent
                    // Haptic feedback for successful file drop
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                }
            }
        }
        
        return true
    }
}

// MARK: - Package Analysis View
struct PackageAnalysisView: View {
    let analysis: PackageAnalysis
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Package Info Header
                    PackageInfoHeader(analysis: analysis)
                    
                    // Security Analysis
                    SecurityAnalysisCard(securityInfo: analysis.securityInfo)
                    
                    // Recommendations
                    if !analysis.recommendations.isEmpty {
                        RecommendationsCard(recommendations: analysis.recommendations)
                    }
                    
                    // Package Contents
                    PackageContentsCard(contents: analysis.contents)
                    
                    // Scripts
                    if !analysis.scripts.isEmpty {
                        ScriptsCard(scripts: analysis.scripts)
                    }
                    
                    // Dependencies
                    if !analysis.dependencies.isEmpty {
                        DependenciesCard(dependencies: analysis.dependencies)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Package Analysis")
            .navigationSubtitle(analysis.fileName)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Package Repackaging View
struct PackageRepackagingView: View {
    let analysis: PackageAnalysis
    @ObservedObject var analysisService: PackageAnalysisService
    @Environment(\.dismiss) private var dismiss
    
    @State private var options = RepackagingOptions()
    @State private var showingPPPCGenerator = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Repackaging Options
                    RepackagingOptionsCard(options: $options)
                    
                    // Script Injection
                    ScriptInjectionCard(options: $options)
                    
                    // Code Signing
                    CodeSigningCard(options: $options)
                    
                    // PPPC Profile Generation
                    PPPCProfileCard(options: $options, showingPPPCGenerator: $showingPPPCGenerator)
                    
                    // Output Options
                    OutputOptionsCard(options: $options)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button("Start Repackaging") {
                            Task {
                                await analysisService.repackagePackage(options: options)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(analysisService.isRepackaging)
                        
                        if analysisService.isRepackaging {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Repackaging package...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Repackage Package")
            .navigationSubtitle(analysis.fileName)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingPPPCGenerator) {
            PPPCGeneratorView(analysis: analysis, options: $options)
        }
    }
}

// MARK: - Supporting Views (Placeholders)
struct PackageInfoHeader: View {
    let analysis: PackageAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: analysis.packageType.icon)
                    .font(.title2)
                    .foregroundColor(analysis.packageType.color)
                Text(analysis.fileName)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                InfoItem(title: "Type", value: analysis.packageType.rawValue, icon: analysis.packageType.icon, color: analysis.packageType.color)
                InfoItem(title: "Size", value: ByteCountFormatter.string(fromByteCount: analysis.fileSize, countStyle: .file), icon: "doc", color: .blue)
                InfoItem(title: "Files", value: "\(analysis.contents.totalFiles)", icon: "folder", color: .green)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct SecurityAnalysisCard: View {
    let securityInfo: SecurityInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title2)
                    .foregroundColor(securityInfo.isSigned ? .green : .red)
                Text("Security Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: securityInfo.isSigned ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(securityInfo.isSigned ? .green : .red)
                        Text("Code Signed: \(securityInfo.isSigned ? "Yes" : "No")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    if securityInfo.needsSigning {
                        Text("⚠️ Package requires code signing for MDM deployment")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct RecommendationsCard: View {
    let recommendations: [PackageRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Text("Recommendations")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(recommendations, id: \.title) { recommendation in
                    RecommendationRow(recommendation: recommendation)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct PackageContentsCard: View {
    let contents: PackageContents
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Package Contents")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                InfoItem(title: "Total Files", value: "\(contents.totalFiles)", icon: "doc.text", color: .blue)
                InfoItem(title: "Install Size", value: ByteCountFormatter.string(fromByteCount: contents.installSize, countStyle: .file), icon: "externaldrive", color: .green)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct ScriptsCard: View {
    let scripts: [PackageScript]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "terminal.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("Package Scripts")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(scripts) { script in
                    ScriptRow(script: script)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct DependenciesCard: View {
    let dependencies: [PackageDependency]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "link")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Dependencies")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(dependencies) { dependency in
                    DependencyRow(dependency: dependency)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Repackaging Views
struct RepackagingOptionsCard: View {
    @Binding var options: RepackagingOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Repackaging Options")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                Toggle("Sign Package", isOn: $options.signPackage)
                Toggle("Generate PPPC Profile", isOn: $options.addPPPCProfile)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct ScriptInjectionCard: View {
    @Binding var options: RepackagingOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "terminal.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("Script Injection")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            Text("Add custom scripts to fix application issues (e.g., SolarWinds Discovery Agent time sync)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Add Script") {
                // TODO: Implement script addition
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct CodeSigningCard: View {
    @Binding var options: RepackagingOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "signature")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Code Signing")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if options.signPackage {
                VStack(spacing: 12) {
                    Picker("Certificate", selection: $options.certificateID) {
                        Text("Select Certificate").tag("")
                        Text("Developer ID Application").tag("dev-id-app")
                        Text("Developer ID Installer").tag("dev-id-installer")
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct PPPCProfileCard: View {
    @Binding var options: RepackagingOptions
    @Binding var showingPPPCGenerator: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("PPPC Profile Generation")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if options.addPPPCProfile {
                VStack(spacing: 12) {
                    Text("Automatically generate PPPC profile for MDM deployment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Configure PPPC Services") {
                        showingPPPCGenerator = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct OutputOptionsCard: View {
    @Binding var options: RepackagingOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Output Options")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Output Format:")
                    Spacer()
                    Picker("Format", selection: $options.outputFormat) {
                        ForEach(PackageType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Text("Output Name:")
                    Spacer()
                    TextField("Package name", text: $options.outputName)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Supporting Components
struct InfoItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct RecommendationRow: View {
    let recommendation: PackageRecommendation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(recommendation.priority.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ScriptRow: View {
    let script: PackageScript
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: script.type.icon)
                .foregroundColor(.purple)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(script.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(script.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct DependencyRow: View {
    let dependency: PackageDependency
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "link")
                .foregroundColor(dependency.isInstalled ? .green : .red)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dependency.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(dependency.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PPPC Generator View (Placeholder)
struct PPPCGeneratorView: View {
    let analysis: PackageAnalysis
    @Binding var options: RepackagingOptions
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("PPPC Profile Generator")
                    .font(.title)
                    .padding()
                
                Text("This would integrate with Config Foundry to generate PPPC profiles")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("PPPC Generator")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    PackageCastingView()
}
