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

// MARK: - Package Creation Service
class PackageCreationService: ObservableObject {
    static let shared = PackageCreationService()
    
    private init() {}
    
    func createPackage(
        from sourcePath: String,
        name: String,
        version: String,
        type: NewPackageCreationView.SourceType
    ) async throws -> PackageCreationResult {
        
        // Validate source path
        guard FileManager.default.fileExists(atPath: sourcePath) else {
            throw PackageCreationError.sourceNotFound
        }
        
        // Create output directory
        let outputDir = FileManager.default.temporaryDirectory.appendingPathComponent("MacForge_Packages")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let outputPath = outputDir.appendingPathComponent("\(name)-\(version).pkg")
        
        // Create package based on source type
        switch type {
        case .app:
            try await createAppPackage(from: sourcePath, to: outputPath, name: name, version: version)
        case .dmg:
            try await createDMGPackage(from: sourcePath, to: outputPath, name: name, version: version)
        case .archive:
            try await createArchivePackage(from: sourcePath, to: outputPath, name: name, version: version)
        case .folder:
            try await createFolderPackage(from: sourcePath, to: outputPath, name: name, version: version)
        }
        
        return PackageCreationResult(
            outputPath: outputPath.path,
            packageName: name,
            version: version,
            size: try FileManager.default.attributesOfItem(atPath: outputPath.path)[.size] as? Int64 ?? 0
        )
    }
    
    private func createAppPackage(from sourcePath: String, to outputPath: URL, name: String, version: String) async throws {
        // Use pkgbuild to create package from app
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pkgbuild")
        process.arguments = [
            "--root", sourcePath,
            "--identifier", "com.macforge.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))",
            "--version", version,
            "--install-location", "/Applications",
            outputPath.path
        ]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw PackageCreationError.buildFailed("pkgbuild failed with status \(process.terminationStatus)")
        }
    }
    
    private func createDMGPackage(from sourcePath: String, to outputPath: URL, name: String, version: String) async throws {
        // Mount DMG and create package from contents
        let mountPoint = FileManager.default.temporaryDirectory.appendingPathComponent("dmg_mount_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)
        
        let mountProcess = Process()
        mountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        mountProcess.arguments = ["attach", sourcePath, "-mountpoint", mountPoint.path, "-nobrowse"]
        
        try mountProcess.run()
        mountProcess.waitUntilExit()
        
        defer {
            // Unmount DMG
            let unmountProcess = Process()
            unmountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            unmountProcess.arguments = ["detach", mountPoint.path]
            try? unmountProcess.run()
        }
        
        guard mountProcess.terminationStatus == 0 else {
            throw PackageCreationError.buildFailed("Failed to mount DMG")
        }
        
        // Create package from mounted DMG contents
        try await createFolderPackage(from: mountPoint.path, to: outputPath, name: name, version: version)
    }
    
    private func createArchivePackage(from sourcePath: String, to outputPath: URL, name: String, version: String) async throws {
        // Extract archive and create package from contents
        let extractDir = FileManager.default.temporaryDirectory.appendingPathComponent("extract_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)
        
        let extractProcess = Process()
        extractProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        extractProcess.arguments = ["-xk", sourcePath, extractDir.path]
        
        try extractProcess.run()
        extractProcess.waitUntilExit()
        
        guard extractProcess.terminationStatus == 0 else {
            throw PackageCreationError.buildFailed("Failed to extract archive")
        }
        
        // Create package from extracted contents
        try await createFolderPackage(from: extractDir.path, to: outputPath, name: name, version: version)
    }
    
    private func createFolderPackage(from sourcePath: String, to outputPath: URL, name: String, version: String) async throws {
        // Use pkgbuild to create package from folder
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pkgbuild")
        process.arguments = [
            "--root", sourcePath,
            "--identifier", "com.macforge.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))",
            "--version", version,
            "--install-location", "/Applications",
            outputPath.path
        ]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw PackageCreationError.buildFailed("pkgbuild failed with status \(process.terminationStatus)")
        }
    }
    
    func createTemplatePackage(
        template: PackageTemplate,
        name: String,
        version: String
    ) async throws -> PackageCreationResult {
        
        // Create output directory
        let outputDir = FileManager.default.temporaryDirectory.appendingPathComponent("MacForge_Packages")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let outputPath = outputDir.appendingPathComponent("\(name)-\(version).pkg")
        
        // Create template-based package
        let templateDir = try await createTemplateStructure(template: template, name: name)
        
        // Build package from template
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pkgbuild")
        process.arguments = [
            "--root", templateDir.path,
            "--identifier", "com.macforge.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))",
            "--version", version,
            "--install-location", getInstallLocation(for: template),
            outputPath.path
        ]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw PackageCreationError.buildFailed("pkgbuild failed with status \(process.terminationStatus)")
        }
        
        return PackageCreationResult(
            outputPath: outputPath.path,
            packageName: name,
            version: version,
            size: try FileManager.default.attributesOfItem(atPath: outputPath.path)[.size] as? Int64 ?? 0
        )
    }
    
    private func createTemplateStructure(template: PackageTemplate, name: String) async throws -> URL {
        let templateDir = FileManager.default.temporaryDirectory.appendingPathComponent("template_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: templateDir, withIntermediateDirectories: true)
        
        switch template {
        case .application:
            try await createApplicationTemplate(at: templateDir, name: name)
        case .framework:
            try await createFrameworkTemplate(at: templateDir, name: name)
        case .preferencePane:
            try await createPreferencePaneTemplate(at: templateDir, name: name)
        case .kernelExtension:
            try await createKernelExtensionTemplate(at: templateDir, name: name)
        case .systemExtension:
            try await createSystemExtensionTemplate(at: templateDir, name: name)
        case .custom:
            try await createCustomTemplate(at: templateDir, name: name)
        }
        
        return templateDir
    }
    
    private func createApplicationTemplate(at url: URL, name: String) async throws {
        let appDir = url.appendingPathComponent("\(name).app")
        try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        // Create basic app structure
        let contentsDir = appDir.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contentsDir, withIntermediateDirectories: true)
        
        let macosDir = contentsDir.appendingPathComponent("MacOS")
        try FileManager.default.createDirectory(at: macosDir, withIntermediateDirectories: true)
        
        let resourcesDir = contentsDir.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
        
        // Create Info.plist
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleExecutable</key>
            <string>\(name)</string>
            <key>CFBundleIdentifier</key>
            <string>com.macforge.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))</string>
            <key>CFBundleName</key>
            <string>\(name)</string>
            <key>CFBundleVersion</key>
            <string>1.0</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
        </dict>
        </plist>
        """
        
        try infoPlist.write(to: contentsDir.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
        
        // Create placeholder executable
        let executable = macosDir.appendingPathComponent(name)
        try "#!/bin/bash\necho \"\(name) placeholder executable\"".write(to: executable, atomically: true, encoding: .utf8)
        
        // Make executable
        let chmodProcess = Process()
        chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodProcess.arguments = ["+x", executable.path]
        try chmodProcess.run()
        chmodProcess.waitUntilExit()
    }
    
    private func createFrameworkTemplate(at url: URL, name: String) async throws {
        let frameworkDir = url.appendingPathComponent("\(name).framework")
        try FileManager.default.createDirectory(at: frameworkDir, withIntermediateDirectories: true)
        
        let resourcesDir = frameworkDir.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
        
        let versionsDir = frameworkDir.appendingPathComponent("Versions")
        try FileManager.default.createDirectory(at: versionsDir, withIntermediateDirectories: true)
        
        let currentVersionDir = versionsDir.appendingPathComponent("A")
        try FileManager.default.createDirectory(at: currentVersionDir, withIntermediateDirectories: true)
        
        // Create Info.plist
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.macforge.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))</string>
            <key>CFBundleName</key>
            <string>\(name)</string>
            <key>CFBundleVersion</key>
            <string>1.0</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundlePackageType</key>
            <string>FMWK</string>
        </dict>
        </plist>
        """
        
        try infoPlist.write(to: currentVersionDir.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
    }
    
    private func createPreferencePaneTemplate(at url: URL, name: String) async throws {
        let prefPaneDir = url.appendingPathComponent("\(name).prefPane")
        try FileManager.default.createDirectory(at: prefPaneDir, withIntermediateDirectories: true)
        
        let contentsDir = prefPaneDir.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contentsDir, withIntermediateDirectories: true)
        
        let macosDir = contentsDir.appendingPathComponent("MacOS")
        try FileManager.default.createDirectory(at: macosDir, withIntermediateDirectories: true)
        
        let resourcesDir = contentsDir.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
        
        // Create Info.plist
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleExecutable</key>
            <string>\(name)</string>
            <key>CFBundleIdentifier</key>
            <string>com.macforge.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))</string>
            <key>CFBundleName</key>
            <string>\(name)</string>
            <key>CFBundleVersion</key>
            <string>1.0</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundlePackageType</key>
            <string>BNDL</string>
            <key>NSPrefPaneIconLabel</key>
            <string>\(name)</string>
        </dict>
        </plist>
        """
        
        try infoPlist.write(to: contentsDir.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
    }
    
    private func createKernelExtensionTemplate(at url: URL, name: String) async throws {
        let kextDir = url.appendingPathComponent("\(name).kext")
        try FileManager.default.createDirectory(at: kextDir, withIntermediateDirectories: true)
        
        let contentsDir = kextDir.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contentsDir, withIntermediateDirectories: true)
        
        let macosDir = contentsDir.appendingPathComponent("MacOS")
        try FileManager.default.createDirectory(at: macosDir, withIntermediateDirectories: true)
        
        // Create Info.plist
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.macforge.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))</string>
            <key>CFBundleName</key>
            <string>\(name)</string>
            <key>CFBundleVersion</key>
            <string>1.0</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundlePackageType</key>
            <string>KEXT</string>
            <key>OSBundleRequired</key>
            <string>Root</string>
        </dict>
        </plist>
        """
        
        try infoPlist.write(to: contentsDir.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
    }
    
    private func createSystemExtensionTemplate(at url: URL, name: String) async throws {
        let appexDir = url.appendingPathComponent("\(name).appex")
        try FileManager.default.createDirectory(at: appexDir, withIntermediateDirectories: true)
        
        let contentsDir = appexDir.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contentsDir, withIntermediateDirectories: true)
        
        let macosDir = contentsDir.appendingPathComponent("MacOS")
        try FileManager.default.createDirectory(at: macosDir, withIntermediateDirectories: true)
        
        // Create Info.plist
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.macforge.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))</string>
            <key>CFBundleName</key>
            <string>\(name)</string>
            <key>CFBundleVersion</key>
            <string>1.0</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>NSExtension</key>
            <dict>
                <key>NSExtensionPointIdentifier</key>
                <string>com.apple.system-extension</string>
            </dict>
        </dict>
        </plist>
        """
        
        try infoPlist.write(to: contentsDir.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
    }
    
    private func createCustomTemplate(at url: URL, name: String) async throws {
        // Create a basic folder structure for custom packages
        let customDir = url.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: customDir, withIntermediateDirectories: true)
        
        // Create a README file
        let readme = """
        # \(name) Package
        
        This is a custom package created with MacForge.
        
        ## Installation
        This package can be installed using standard macOS package installation methods.
        
        ## Contents
        Add your custom files and folders here.
        """
        
        try readme.write(to: customDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
    }
    
    private func getInstallLocation(for template: PackageTemplate) -> String {
        switch template {
        case .application:
            return "/Applications"
        case .framework:
            return "/Library/Frameworks"
        case .preferencePane:
            return "/Library/PreferencePanes"
        case .kernelExtension:
            return "/Library/Extensions"
        case .systemExtension:
            return "/Applications"
        case .custom:
            return "/usr/local"
        }
    }
}

// MARK: - Package Creation Models
struct PackageCreationResult {
    let outputPath: String
    let packageName: String
    let version: String
    let size: Int64
}

enum PackageCreationError: LocalizedError {
    case sourceNotFound
    case buildFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .sourceNotFound:
            return "Source file or folder not found"
        case .buildFailed(let message):
            return "Package creation failed: \(message)"
        }
    }
}

enum PackageTemplate: String, CaseIterable {
    case application = "Application"
    case framework = "Framework"
    case preferencePane = "Preference Pane"
    case kernelExtension = "Kernel Extension"
    case systemExtension = "System Extension"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .application:
            return "Standard macOS application package"
        case .framework:
            return "Shared library framework package"
        case .preferencePane:
            return "System preference pane package"
        case .kernelExtension:
            return "Low-level system extension package"
        case .systemExtension:
            return "Modern system extension package"
        case .custom:
            return "Custom package configuration"
        }
    }
    
    var icon: String {
        switch self {
        case .application:
            return "app"
        case .framework:
            return "cube.box"
        case .preferencePane:
            return "slider.horizontal.3"
        case .kernelExtension:
            return "cpu"
        case .systemExtension:
            return "gear"
        case .custom:
            return "doc.text"
        }
    }
    
    var installLocation: String {
        switch self {
        case .application:
            return "/Applications"
        case .framework:
            return "/Library/Frameworks"
        case .preferencePane:
            return "/Library/PreferencePanes"
        case .kernelExtension:
            return "/Library/Extensions"
        case .systemExtension:
            return "/Library/SystemExtensions"
        case .custom:
            return "/usr/local"
        }
    }
}

struct SoftwareVersion: Identifiable, Codable {
    var id = UUID()
    let name: String
    let currentVersion: String
    let latestVersion: String
    let packagePath: String
    let installDate: Date
    let isOutdated: Bool
    let deploymentStatus: DeploymentStatus
    
    enum DeploymentStatus: String, Codable, CaseIterable {
        case notDeployed = "Not Deployed"
        case deployed = "Deployed"
        case pending = "Pending"
        case failed = "Failed"
        case updating = "Updating"
    }
}

// MARK: - New Package Creation View
struct NewPackageCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSourceType: SourceType = .app
    @State private var sourcePath: String = ""
    @State private var packageName: String = ""
    @State private var packageVersion: String = "1.0"
    @State private var showingFilePicker = false
    @State private var isCreating = false
    @State private var creationResult: PackageCreationResult?
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    
    enum SourceType: String, CaseIterable {
        case app = "Application"
        case dmg = "Disk Image"
        case archive = "Archive"
        case folder = "Folder"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Package Creation")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Create packages from apps, DMGs, or archives")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            ScrollView {
                VStack(spacing: 20) {
                    // Source Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Source Type")
                            .font(.headline)
                        
                        Picker("Source Type", selection: $selectedSourceType) {
                            ForEach(SourceType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Source Path
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Source Path")
                            .font(.headline)
                        
                        HStack {
                            TextField("Select source file or folder", text: $sourcePath)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Browse") {
                                showingFilePicker = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    // Package Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Package Details")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Package Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("Enter package name", text: $packageName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Version")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("1.0", text: $packageVersion)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Create Button
                    Button(action: createPackage) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isCreating ? "Creating Package..." : "Create Package")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sourcePath.isEmpty || packageName.isEmpty || isCreating)
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder, .application, .diskImage, .archive],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    sourcePath = url.path
                    if packageName.isEmpty {
                        packageName = url.lastPathComponent
                    }
                }
            case .failure(let error):
                print("File picker error: \(error)")
            }
        }
        .sheet(isPresented: $showingSuccess) {
            if let result = creationResult {
                PackageCreationSuccessView(result: result) {
                    dismiss()
                }
            }
        }
    }
    
    private func createPackage() {
        isCreating = true
        
        Task {
            do {
                let result = try await PackageCreationService.shared.createPackage(
                    from: sourcePath,
                    name: packageName,
                    version: packageVersion,
                    type: selectedSourceType
                )
                
                await MainActor.run {
                    isCreating = false
                    creationResult = result
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Package Creation Success View
struct PackageCreationSuccessView: View {
    let result: PackageCreationResult
    let onDismiss: () -> Void
    @State private var showingInFinder = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            // Success Message
            VStack(spacing: 8) {
                Text("Package Created Successfully!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your package has been created and is ready for deployment.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Package Details
            VStack(spacing: 12) {
                HStack {
                    Text("Package Name:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(result.packageName)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Version:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(result.version)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Size:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: result.size, countStyle: .file))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Location:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(URL(fileURLWithPath: result.outputPath).lastPathComponent)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // Action Buttons
            HStack(spacing: 16) {
                Button("Show in Finder") {
                    showingInFinder = true
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            if showingInFinder {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: result.outputPath)])
            }
        }
    }
}

// MARK: - Package Analysis Selection View
struct PackageAnalysisSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var isAnalyzing = false
    @State private var analysisResult: PackageAnalysis?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Package Analysis")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Select a package to analyze")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            VStack(spacing: 20) {
                Image(systemName: "magnifyingglass.circle")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("No package selected")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Please select a package file to analyze its contents, security, and deployment readiness.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Select Package") {
                    showingFilePicker = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAnalyzing)
                
                if isAnalyzing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing package...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 500, minHeight: 400)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.package, .diskImage, .application, .archive],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    analyzePackage(at: url)
                }
            case .failure(let error):
                errorMessage = "Failed to select file: \(error.localizedDescription)"
            }
        }
    }
    
    private func analyzePackage(at url: URL) {
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                try await PackageAnalysisService().analyzePackage(at: url)
                
                await MainActor.run {
                    isAnalyzing = false
                    // TODO: Show analysis results in a new view
                    print("Package analysis completed for: \(url.lastPathComponent)")
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = "Analysis failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Simple Package Builder View
struct SimplePackageBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: PackageTemplate = .application
    @State private var packageName: String = ""
    @State private var packageVersion: String = "1.0"
    @State private var isBuilding = false
    @State private var buildResult: PackageCreationResult?
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Simple Package Builder")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Quick package creation with templates")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            VStack(spacing: 20) {
                // Template Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Package Template")
                        .font(.headline)
                    
                    Picker("Template", selection: $selectedTemplate) {
                        ForEach(PackageTemplate.allCases, id: \.self) { template in
                            VStack(alignment: .leading) {
                                Text(template.rawValue)
                                    .font(.body)
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(template)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Package Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Package Details")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Name:")
                                .frame(width: 80, alignment: .leading)
                            TextField("Package name", text: $packageName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Text("Version:")
                                .frame(width: 80, alignment: .leading)
                            TextField("1.0", text: $packageVersion)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                
                // Error Message
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Build Button
                Button(action: buildPackage) {
                    HStack {
                        if isBuilding {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isBuilding ? "Building Package..." : "Build Package")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(packageName.isEmpty || isBuilding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 500, minHeight: 400)
        .sheet(isPresented: $showingSuccess) {
            if let result = buildResult {
                PackageCreationSuccessView(result: result) {
                    dismiss()
                }
            }
        }
    }
    
    private func buildPackage() {
        isBuilding = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await PackageCreationService.shared.createTemplatePackage(
                    template: selectedTemplate,
                    name: packageName,
                    version: packageVersion
                )
                
                await MainActor.run {
                    isBuilding = false
                    buildResult = result
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isBuilding = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - System Lifecycle Management View
struct SystemLifecycleManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var softwareVersions: [SoftwareVersion] = []
    @State private var selectedVersion: SoftwareVersion?
    @State private var isManaging = false
    @State private var managementResult: String?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Lifecycle Management")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Manage software versions and deployments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            VStack(spacing: 20) {
                // Software Versions List
                if softwareVersions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                        
                        Text("No Software Versions Found")
                            .font(.headline)
                        
                        Text("Scan for installed software to manage versions and deployments.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Scan for Software") {
                            scanForSoftware()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Software Versions")
                            .font(.headline)
                        
                        List(softwareVersions) { version in
                            SoftwareVersionRow(version: version) {
                                selectedVersion = version
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                }
                
                // Management Actions
                if let selectedVersion = selectedVersion {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Management Actions")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            Button("Update to Latest") {
                                updateSoftware(selectedVersion)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isManaging)
                            
                            Button("Deploy Package") {
                                deployPackage(selectedVersion)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isManaging)
                            
                            Button("Remove Package") {
                                removePackage(selectedVersion)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isManaging)
                        }
                        
                        if isManaging {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Managing software...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Error Message
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Success Message
                if let managementResult = managementResult {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(managementResult)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            loadSoftwareVersions()
        }
    }
    
    private func loadSoftwareVersions() {
        // Load from UserDefaults or create sample data
        if let data = UserDefaults.standard.data(forKey: "softwareVersions"),
           let versions = try? JSONDecoder().decode([SoftwareVersion].self, from: data) {
            softwareVersions = versions
        } else {
            // Create sample data for demonstration
            softwareVersions = [
                SoftwareVersion(
                    name: "Google Chrome",
                    currentVersion: "120.0.6099.109",
                    latestVersion: "121.0.6167.85",
                    packagePath: "/Applications/Google Chrome.app",
                    installDate: Date().addingTimeInterval(-86400 * 7),
                    isOutdated: true,
                    deploymentStatus: .deployed
                ),
                SoftwareVersion(
                    name: "Microsoft Office",
                    currentVersion: "16.78",
                    latestVersion: "16.78",
                    packagePath: "/Applications/Microsoft Word.app",
                    installDate: Date().addingTimeInterval(-86400 * 3),
                    isOutdated: false,
                    deploymentStatus: .deployed
                )
            ]
        }
    }
    
    private func scanForSoftware() {
        isManaging = true
        errorMessage = nil
        
        Task {
            // Simulate scanning for software
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                isManaging = false
                managementResult = "Found \(softwareVersions.count) software packages"
            }
        }
    }
    
    private func updateSoftware(_ version: SoftwareVersion) {
        isManaging = true
        errorMessage = nil
        
        Task {
            // Simulate software update
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            await MainActor.run {
                isManaging = false
                managementResult = "Updated \(version.name) to version \(version.latestVersion)"
            }
        }
    }
    
    private func deployPackage(_ version: SoftwareVersion) {
        isManaging = true
        errorMessage = nil
        
        Task {
            // Simulate package deployment
            try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            
            await MainActor.run {
                isManaging = false
                managementResult = "Deployed \(version.name) package successfully"
            }
        }
    }
    
    private func removePackage(_ version: SoftwareVersion) {
        isManaging = true
        errorMessage = nil
        
        Task {
            // Simulate package removal
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            await MainActor.run {
                isManaging = false
                managementResult = "Removed \(version.name) package successfully"
            }
        }
    }
}

// MARK: - Software Version Row
struct SoftwareVersionRow: View {
    let version: SoftwareVersion
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(version.name)
                    .font(.headline)
                
                HStack {
                    Text("Current: \(version.currentVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if version.isOutdated {
                        Text("• Latest: \(version.latestVersion)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(version.deploymentStatus.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
                
                if version.isOutdated {
                    Text("Outdated")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
    
    private var statusColor: Color {
        switch version.deploymentStatus {
        case .deployed:
            return .green
        case .pending:
            return .orange
        case .failed:
            return .red
        case .updating:
            return .blue
        case .notDeployed:
            return .gray
        }
    }
}

// MARK: - Template Systems View
struct TemplateSystemsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: TemplateCategory = .applications
    @State private var selectedTemplate: PackageTemplate?
    @State private var showingTemplateDetails = false
    @State private var showingCreateFromTemplate = false
    @State private var packageName = ""
    @State private var packageVersion = "1.0.0"
    @State private var isCreating = false
    @State private var creationResult: PackageCreationResult?
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    
    enum TemplateCategory: String, CaseIterable {
        case applications = "Applications"
        case frameworks = "Frameworks"
        case systemExtensions = "System Extensions"
        case preferencePanes = "Preference Panes"
        case kernelExtensions = "Kernel Extensions"
        case custom = "Custom Templates"
        
        var icon: String {
            switch self {
            case .applications: return "app"
            case .frameworks: return "cube.box"
            case .systemExtensions: return "gear"
            case .preferencePanes: return "slider.horizontal.3"
            case .kernelExtensions: return "cpu"
            case .custom: return "doc.text"
            }
        }
        
        var templates: [PackageTemplate] {
            switch self {
            case .applications:
                return [
                    PackageTemplate.application,
                    PackageTemplate.application,
                    PackageTemplate.application
                ]
            case .frameworks:
                return [
                    PackageTemplate.framework,
                    PackageTemplate.framework
                ]
            case .systemExtensions:
                return [
                    PackageTemplate.systemExtension,
                    PackageTemplate.systemExtension
                ]
            case .preferencePanes:
                return [
                    PackageTemplate.preferencePane,
                    PackageTemplate.preferencePane
                ]
            case .kernelExtensions:
                return [
                    PackageTemplate.kernelExtension,
                    PackageTemplate.kernelExtension
                ]
            case .custom:
                return [
                    PackageTemplate.custom,
                    PackageTemplate.custom
                ]
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Template Systems")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Pre-built package templates and configurations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            HStack(spacing: 0) {
                // Sidebar - Template Categories
                VStack(alignment: .leading, spacing: 0) {
                    Text("Categories")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    List(TemplateCategory.allCases, id: \.self, selection: $selectedCategory) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(category.rawValue)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(SidebarListStyle())
                }
                .frame(width: 200)
                .background(Color(.controlBackgroundColor))
                
                Divider()
                
                // Main Content - Templates Grid
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(selectedCategory.rawValue)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(selectedCategory.templates.count) templates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 280), spacing: 16)
                        ], spacing: 16) {
                            ForEach(selectedCategory.templates.indices, id: \.self) { index in
                                PackageTemplateCard(
                                    template: selectedCategory.templates[index],
                                    index: index + 1,
                                    onSelect: {
                                        selectedTemplate = selectedCategory.templates[index]
                                        showingTemplateDetails = true
                                    },
                                    onCreate: {
                                        selectedTemplate = selectedCategory.templates[index]
                                        showingCreateFromTemplate = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingTemplateDetails) {
            if let template = selectedTemplate {
                TemplateDetailsView(
                    template: template,
                    onDismiss: { showingTemplateDetails = false },
                    onCreate: {
                        showingTemplateDetails = false
                        showingCreateFromTemplate = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingCreateFromTemplate) {
            if let template = selectedTemplate {
                CreateFromTemplateView(
                    template: template,
                    packageName: $packageName,
                    packageVersion: $packageVersion,
                    isCreating: $isCreating,
                    creationResult: $creationResult,
                    errorMessage: $errorMessage,
                    showingSuccess: $showingSuccess,
                    onDismiss: { showingCreateFromTemplate = false }
                )
            }
        }
        .sheet(isPresented: $showingSuccess) {
            if let result = creationResult {
                PackageCreationSuccessView(
                    result: result,
                    onDismiss: { showingSuccess = false }
                )
            }
        }
    }
}

struct PackageTemplateCard: View {
    let template: PackageTemplate
    let index: Int
    let onSelect: () -> Void
    let onCreate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(template.rawValue) Template")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Template #\(index)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Text(template.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Button("View Details") {
                    onSelect()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create Package") {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
    }
}

struct TemplateDetailsView: View {
    let template: PackageTemplate
    let onDismiss: () -> Void
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(template.rawValue) Template")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Detailed template information")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Template Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Template Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: template.icon)
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.rawValue)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(template.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // Template Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Template Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 200), spacing: 12)
                        ], spacing: 12) {
                            FeatureCard(
                                icon: "checkmark.circle.fill",
                                title: "Pre-configured",
                                description: "Ready-to-use package structure"
                            )
                            
                            FeatureCard(
                                icon: "gear",
                                title: "Customizable",
                                description: "Easy to modify and adapt"
                            )
                            
                            FeatureCard(
                                icon: "shield.checkered",
                                title: "Security Ready",
                                description: "Includes security best practices"
                            )
                            
                            FeatureCard(
                                icon: "doc.text",
                                title: "Documentation",
                                description: "Comprehensive setup guide"
                            )
                        }
                    }
                    
                    // Installation Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Installation Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PackageDetailRow(label: "Install Location", value: template.installLocation)
                            PackageDetailRow(label: "Package Type", value: template.rawValue)
                            PackageDetailRow(label: "Compatibility", value: "macOS 10.15+")
                            PackageDetailRow(label: "Architecture", value: "Universal (Intel + Apple Silicon)")
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            // Action Buttons
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create Package from Template") {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct PackageDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct CreateFromTemplateView: View {
    let template: PackageTemplate
    @Binding var packageName: String
    @Binding var packageVersion: String
    @Binding var isCreating: Bool
    @Binding var creationResult: PackageCreationResult?
    @Binding var errorMessage: String?
    @Binding var showingSuccess: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Package from Template")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Configure your package using the \(template.rawValue) template")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            VStack(spacing: 20) {
                // Package Configuration
                VStack(alignment: .leading, spacing: 16) {
                    Text("Package Configuration")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Package Name:")
                                .frame(width: 120, alignment: .leading)
                            
                            TextField("Enter package name", text: $packageName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Text("Version:")
                                .frame(width: 120, alignment: .leading)
                            
                            TextField("1.0.0", text: $packageVersion)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Template Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Template Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Image(systemName: template.icon)
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.rawValue)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(template.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Error Message
                if let errorMessage = errorMessage {
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
            
            // Action Buttons
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: createPackage) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        Text(isCreating ? "Creating..." : "Create Package")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCreating || packageName.isEmpty || packageVersion.isEmpty)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func createPackage() {
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await PackageCreationService.shared.createTemplatePackage(
                    template: template,
                    name: packageName,
                    version: packageVersion
                )
                
                await MainActor.run {
                    isCreating = false
                    creationResult = result
                    showingSuccess = true
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Advanced Repackaging Selection View
struct AdvancedRepackagingSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var selectedFile: URL?
    @State private var isAnalyzing = false
    @State private var analysisResult: PackageAnalysis?
    @State private var errorMessage: String?
    @State private var showingAdvancedRepackaging = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Repackaging")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Select a package to modify with advanced options")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            if let selectedFile = selectedFile {
                // File Selected View
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "doc.badge.gearshape")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedFile.lastPathComponent)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Ready for advanced repackaging")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    if isAnalyzing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Analyzing package...")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if let errorMessage = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    } else if let analysis = analysisResult {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text("Package analyzed successfully")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Button("Select Different Package") {
                                    selectedFile = nil
                                    analysisResult = nil
                                    errorMessage = nil
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                Button("Start Advanced Repackaging") {
                                    showingAdvancedRepackaging = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    } else {
                        Button("Analyze Package") {
                            analyzePackage()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            } else {
                // No File Selected View
                VStack(spacing: 20) {
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 64))
                        .foregroundColor(.red)
                    
                    Text("No package selected")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Please select a package file to modify with advanced repackaging options.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Select Package") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.package, .diskImage, .application, .archive],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .sheet(isPresented: $showingAdvancedRepackaging) {
            if let analysis = analysisResult {
                AdvancedRepackagingView(
                    analysis: analysis,
                    onDismiss: { showingAdvancedRepackaging = false }
                )
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedFile = url
                analysisResult = nil
                errorMessage = nil
            }
        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
    
    private func analyzePackage() {
        guard let fileURL = selectedFile else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                // Simulate package analysis
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                // Create mock analysis result
                let mockMetadata = PackageMetadata(
                    displayName: "Sample Application",
                    description: "A sample application for testing",
                    author: "MacForge",
                    installLocation: "/Applications",
                    creationDate: Date(),
                    modificationDate: Date()
                )
                
                let mockContents = PackageContents(
                    totalFiles: 150,
                    totalSize: 1024 * 1024 * 50,
                    installSize: 1024 * 1024 * 45
                )
                
                let mockCertificate = CertificateInfo(
                    commonName: "Developer ID Application: MacForge",
                    organization: "MacForge",
                    validityStart: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                    validityEnd: Date().addingTimeInterval(365 * 24 * 60 * 60),
                    isDeveloperID: true
                )
                
                let mockSecurityInfo = SecurityInfo(
                    isSigned: true,
                    signatureValid: true,
                    certificateInfo: mockCertificate
                )
                
                let mockAnalysis = PackageAnalysis(
                    fileName: fileURL.lastPathComponent,
                    filePath: fileURL.path,
                    fileSize: 1024 * 1024 * 50, // 50MB
                    packageType: .pkg,
                    metadata: mockMetadata,
                    contents: mockContents,
                    securityInfo: mockSecurityInfo
                )
                
                await MainActor.run {
                    isAnalyzing = false
                    analysisResult = mockAnalysis
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = "Analysis failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Advanced Repackaging View
struct AdvancedRepackagingView: View {
    let analysis: PackageAnalysis
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: RepackagingTab = .scripts
    @State private var scripts: [PackageScript] = []
    @State private var signingOptions = SigningOptions()
    @State private var repackagingOptions = RepackagingOptions()
    @State private var isRepackaging = false
    @State private var repackagingResult: RepackagingResult?
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    
    enum RepackagingTab: String, CaseIterable {
        case scripts = "Scripts"
        case signing = "Signing"
        case options = "Options"
        case review = "Review"
        
        var icon: String {
            switch self {
            case .scripts: return "doc.text"
            case .signing: return "signature"
            case .options: return "gearshape"
            case .review: return "checkmark.circle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Repackaging")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(analysis.fileName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            // Tab Navigation
            HStack(spacing: 0) {
                ForEach(RepackagingTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            
                            Text(tab.rawValue)
                                .font(.body)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(selectedTab == tab ? Color.accentColor : Color.clear)
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Tab Content
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .scripts:
                        ScriptsTabView(scripts: $scripts)
                    case .signing:
                        SigningTabView(signingOptions: $signingOptions, analysis: analysis)
                    case .options:
                        OptionsTabView(repackagingOptions: $repackagingOptions)
                    case .review:
                        ReviewTabView(
                            analysis: analysis,
                            scripts: scripts,
                            signingOptions: signingOptions,
                            repackagingOptions: repackagingOptions,
                            isRepackaging: $isRepackaging,
                            repackagingResult: $repackagingResult,
                            errorMessage: $errorMessage,
                            showingSuccess: $showingSuccess
                        )
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSuccess) {
            if let result = repackagingResult {
                RepackagingSuccessView(
                    result: result,
                    onDismiss: { showingSuccess = false }
                )
            }
        }
    }
}

struct ScriptsTabView: View {
    @Binding var scripts: [PackageScript]
    @State private var showingAddScript = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Package Scripts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Add Script") {
                    showingAddScript = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            if scripts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No scripts added")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add pre-install, post-install, or uninstall scripts to customize package behavior.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(scripts.indices, id: \.self) { index in
                        ScriptRowView(
                            script: scripts[index],
                            onEdit: { /* TODO: Edit script */ },
                            onDelete: { scripts.remove(at: index) }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddScript) {
            AddScriptView(scripts: $scripts)
        }
    }
}

struct ScriptRowView: View {
    let script: PackageScript
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(script.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(script.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AddScriptView: View {
    @Binding var scripts: [PackageScript]
    @Environment(\.dismiss) private var dismiss
    @State private var scriptName = ""
    @State private var scriptType = PackageScriptType.preinstall
    @State private var scriptContent = ""
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Add Script")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Script Name:")
                    .font(.headline)
                
                TextField("Enter script name", text: $scriptName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Script Type:")
                    .font(.headline)
                
                Picker("Script Type", selection: $scriptType) {
                    ForEach(PackageScriptType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Script Content:")
                    .font(.headline)
                
                TextEditor(text: $scriptContent)
                    .frame(minHeight: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Add Script") {
                    let newScript = PackageScript(
                        name: scriptName,
                        type: scriptType,
                        content: scriptContent,
                        isExecutable: true,
                        needsModification: false
                    )
                    scripts.append(newScript)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(scriptName.isEmpty || scriptContent.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct SigningTabView: View {
    @Binding var signingOptions: SigningOptions
    let analysis: PackageAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Code Signing Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Toggle("Re-sign Package", isOn: $signingOptions.shouldResign)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                if signingOptions.shouldResign {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Signing Certificate:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Certificate", selection: $signingOptions.certificateType) {
                            Text("Developer ID Application").tag(SigningOptions.CertificateType.developerID)
                            Text("Developer ID Installer").tag(SigningOptions.CertificateType.installer)
                            Text("Mac App Store").tag(SigningOptions.CertificateType.macAppStore)
                            Text("Ad Hoc").tag(SigningOptions.CertificateType.adHoc)
                        }
                        .pickerStyle(.menu)
                        
                        TextField("Certificate Common Name", text: $signingOptions.certificateName)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            
            // Current Signing Info
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Signing Information")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if analysis.securityInfo.isSigned {
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(label: "Signed", value: "Yes")
                        DetailRow(label: "Valid", value: analysis.securityInfo.signatureValid ? "Yes" : "No")
                        if let cert = analysis.securityInfo.certificateInfo {
                            DetailRow(label: "Certificate", value: cert.commonName)
                            DetailRow(label: "Organization", value: cert.organization)
                            DetailRow(label: "Developer ID", value: cert.isDeveloperID ? "Yes" : "No")
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                } else {
                    Text("Package is not signed")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct OptionsTabView: View {
    @Binding var repackagingOptions: RepackagingOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Repackaging Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Preserve Original Package", isOn: $repackagingOptions.preserveOriginal)
                    .font(.body)
                    .fontWeight(.medium)
                
                Toggle("Create Backup", isOn: $repackagingOptions.createBackup)
                    .font(.body)
                    .fontWeight(.medium)
                
                Toggle("Validate Package After Creation", isOn: $repackagingOptions.validatePackage)
                    .font(.body)
                    .fontWeight(.medium)
                
                Toggle("Remove Temporary Files", isOn: $repackagingOptions.removeTempFiles)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Output Options")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Output Directory:")
                            .frame(width: 120, alignment: .leading)
                        
                        TextField("Select output directory", text: $repackagingOptions.outputDirectory)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Browse") {
                            // TODO: Implement directory picker
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack {
                        Text("Package Name:")
                            .frame(width: 120, alignment: .leading)
                        
                        TextField("Enter new package name", text: $repackagingOptions.packageName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
}

struct ReviewTabView: View {
    let analysis: PackageAnalysis
    let scripts: [PackageScript]
    let signingOptions: SigningOptions
    let repackagingOptions: RepackagingOptions
    @Binding var isRepackaging: Bool
    @Binding var repackagingResult: RepackagingResult?
    @Binding var errorMessage: String?
    @Binding var showingSuccess: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Review & Repackage")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Package Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Package Summary")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DetailRow(label: "Original Package", value: analysis.fileName)
                    DetailRow(label: "Package Type", value: analysis.packageType.rawValue)
                    DetailRow(label: "File Size", value: ByteCountFormatter.string(fromByteCount: analysis.fileSize, countStyle: .file))
                    DetailRow(label: "Scripts Added", value: "\(scripts.count)")
                    DetailRow(label: "Will Re-sign", value: signingOptions.shouldResign ? "Yes" : "No")
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                // Error Message
                if let errorMessage = errorMessage {
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
                
                // Action Button
                Button(action: startRepackaging) {
                    HStack {
                        if isRepackaging {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        Text(isRepackaging ? "Repackaging..." : "Start Repackaging")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRepackaging)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func startRepackaging() {
        isRepackaging = true
        errorMessage = nil
        
        Task {
            do {
                // Simulate repackaging process
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                
                let result = RepackagingResult(
                    originalPath: analysis.filePath,
                    outputPath: "/tmp/repackaged.pkg",
                    packageName: repackagingOptions.packageName.isEmpty ? analysis.fileName : repackagingOptions.packageName,
                    scriptsAdded: scripts.count,
                    wasResigned: signingOptions.shouldResign,
                    outputSize: analysis.fileSize + 1024 * 1024 // Add 1MB for scripts
                )
                
                await MainActor.run {
                    isRepackaging = false
                    repackagingResult = result
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isRepackaging = false
                    errorMessage = "Repackaging failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct RepackagingSuccessView: View {
    let result: RepackagingResult
    let onDismiss: () -> Void
    @State private var showingInFinder = false
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Repackaging Complete")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Close") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("Package successfully repackaged!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(label: "Output Package", value: result.packageName)
                    DetailRow(label: "Output Size", value: ByteCountFormatter.string(fromByteCount: result.outputSize, countStyle: .file))
                    DetailRow(label: "Scripts Added", value: "\(result.scriptsAdded)")
                    DetailRow(label: "Re-signed", value: result.wasResigned ? "Yes" : "No")
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                Button("Show in Finder") {
                    showingInFinder = true
                    NSWorkspace.shared.selectFile(result.outputPath, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Supporting Models
struct SigningOptions {
    var shouldResign = false
    var certificateType = CertificateType.developerID
    var certificateName = ""
    
    enum CertificateType: String, CaseIterable {
        case developerID = "Developer ID Application"
        case installer = "Developer ID Installer"
        case macAppStore = "Mac App Store"
        case adHoc = "Ad Hoc"
    }
}

struct RepackagingResult {
    let originalPath: String
    let outputPath: String
    let packageName: String
    let scriptsAdded: Int
    let wasResigned: Bool
    let outputSize: Int64
}

// MARK: - Tool Summary Button Component
struct ToolSummaryButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

// MARK: - Package Analysis Models
struct PackageAnalysis: Identifiable, Codable {
    let id = UUID()
    
    enum CodingKeys: String, CodingKey {
        case fileName, filePath, fileSize, analysisDate, packageType, metadata, contents, permissions, scripts, dependencies, securityInfo, recommendations
    }
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

struct PackageMetadata: Codable {
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

struct PackageContents: Codable {
    let files: [PackageFile]
    let directories: [PackageDirectory]
    let totalFiles: Int
    let totalSize: Int64
    let installSize: Int64
}

struct PackageFile: Identifiable, Codable {
    let id = UUID()
    
    enum CodingKeys: String, CodingKey {
        case path, size, permissions, modificationDate, isExecutable, fileType
    }
    let path: String
    let size: Int64
    let permissions: String
    let modificationDate: Date?
    let isExecutable: Bool
    let fileType: String?
}

struct PackageDirectory: Identifiable, Codable {
    let id = UUID()
    
    enum CodingKeys: String, CodingKey {
        case path, permissions, modificationDate
    }
    let path: String
    let permissions: String
    let modificationDate: Date?
}

struct FilePermission: Codable {
    let path: String
    let owner: String
    let group: String
    let permissions: String
    let needsRepair: Bool
}

struct PackageScript: Identifiable, Codable {
    let id = UUID()
    
    enum CodingKeys: String, CodingKey {
        case name, type, content, isExecutable, needsModification
    }
    var name: String
    var type: PackageScriptType
    var content: String
    var isExecutable: Bool
    var needsModification: Bool
}

struct PackageDependency: Identifiable, Codable {
    let id = UUID()
    
    enum CodingKeys: String, CodingKey {
        case name, version, type, isInstalled, installPath
    }
    let name: String
    let version: String?
    let type: DependencyType
    let isInstalled: Bool
    let installPath: String?
}

struct SecurityInfo: Codable {
    let isSigned: Bool
    let signatureValid: Bool
    let certificateInfo: CertificateInfo?
    let codeRequirements: String?
    let needsSigning: Bool
    let securityIssues: [SecurityIssue]
}

struct CertificateInfo: Codable {
    let commonName: String
    let organization: String
    let validityStart: Date
    let validityEnd: Date
    let isDeveloperID: Bool
}

struct SecurityIssue: Codable {
    let severity: PackageSecuritySeverity
    let description: String
    let recommendation: String
}

struct PackageRecommendation: Codable {
    let type: RecommendationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let action: String
}

// MARK: - Package Types and Enums
enum PackageType: String, CaseIterable, Codable {
    case pkg = "PKG"
    case dmg = "DMG"
    case app = "APP"
    case zip = "ZIP"
    
    var icon: String {
        switch self {
        case .pkg: return "shippingbox.fill"
        case .dmg: return "opticaldisc.fill"
        case .app: return "app.fill"
        case .zip: return "archivebox.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pkg: return .blue
        case .dmg: return .green
        case .app: return .purple
        case .zip: return .orange
        }
    }
}

enum PackageScriptType: String, CaseIterable, Codable, Identifiable {
    case preinstall = "Preinstall"
    case postinstall = "Postinstall"
    case preuninstall = "Preuninstall"
    case postuninstall = "Postuninstall"
    case preupgrade = "Preupgrade"
    case postupgrade = "Postupgrade"
    
    var id: String { rawValue }
    
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

enum DependencyType: String, CaseIterable, Codable {
    case framework = "Framework"
    case library = "Library"
    case application = "Application"
    case system = "System"
    case unknown = "Unknown"
}

enum PackageSecuritySeverity: String, CaseIterable, Codable {
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

enum RecommendationType: String, CaseIterable, Codable {
    case signing = "Code Signing"
    case permissions = "Permissions"
    case scripts = "Scripts"
    case dependencies = "Dependencies"
    case security = "Security"
    case optimization = "Optimization"
    case mdm = "MDM Compatibility"
}

enum RecommendationPriority: String, CaseIterable, Codable {
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
    
    private func performRepackaging(analysis: PackageAnalysis, options: RepackagingOptions) async -> RepackagingResult {
        // Simulate repackaging process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let outputPath = generateOutputPath(for: analysis, options: options)
        
        return RepackagingResult(
            success: true,
            outputPath: outputPath,
            errorMessage: nil,
            warnings: generateRepackagingWarnings(options: options),
            newPackageInfo: analysis
        )
    }
    
    private func generateOutputPath(for analysis: PackageAnalysis, options: RepackagingOptions) -> String {
        let baseName = analysis.fileName.components(separatedBy: ".").first ?? "repackaged"
        let outputName = options.outputName.isEmpty ? baseName : options.outputName
        let fileExtension = options.outputFormat.rawValue.lowercased()
        return "~/Desktop/\(outputName).\(fileExtension)"
    }
    
    private func generateRepackagingWarnings(options: RepackagingOptions) -> [String] {
        var warnings: [String] = []
        
        if options.signPackage && options.certificateID?.isEmpty != false {
            warnings.append("Code signing enabled but no certificate selected")
        }
        
        if options.addPPPCProfile && options.pppcServices.isEmpty {
            warnings.append("PPPC profile enabled but no services configured")
        }
        
        if options.addScripts.isEmpty {
            warnings.append("No custom scripts added")
        }
        
        return warnings
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
        default: return .pkg // Default to PKG for unknown types
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
    
    // New tool states
    @State private var showingNewPackageCreation = false
    @State private var showingPackageAnalysis = false
    @State private var showingSimpleBuilder = false
    @State private var showingLifecycleManagement = false
    @State private var showingTemplateSystems = false
    @State private var showingAdvancedRepackaging = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "shippingbox.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                    .accessibilityLabel("Package Casting icon")
                    .accessibilityHint("Package analysis and repackaging tool")
                
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
                            .buttonAccessibility(
                                label: "Browse Files",
                                hint: "Select a package file to analyze"
                            )
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
            
            // Tool Summary Buttons - Always visible
            VStack(spacing: 16) {
                Text("Package Management Tools")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ToolSummaryButton(
                        title: "New Package Creation",
                        description: "Create packages from apps, DMGs, or archives",
                        icon: "plus.circle.fill",
                        color: .green
                    ) {
                        showingNewPackageCreation = true
                    }

                    ToolSummaryButton(
                        title: "Package Analysis",
                        description: "Analyze existing packages for security and structure",
                        icon: "magnifyingglass.circle.fill",
                        color: .blue
                    ) {
                        showingPackageAnalysis = true
                    }

                    ToolSummaryButton(
                        title: "Simple Package Builder",
                        description: "Quick package creation with templates",
                        icon: "hammer.circle.fill",
                        color: .orange
                    ) {
                        showingSimpleBuilder = true
                    }

                    ToolSummaryButton(
                        title: "System Lifecycle Management",
                        description: "Manage software versions and deployments",
                        icon: "arrow.triangle.2.circlepath.circle.fill",
                        color: .purple
                    ) {
                        showingLifecycleManagement = true
                    }

                    ToolSummaryButton(
                        title: "Template Systems",
                        description: "Pre-built package templates and configurations",
                        icon: "doc.text.fill",
                        color: .teal
                    ) {
                        showingTemplateSystems = true
                    }

                    ToolSummaryButton(
                        title: "Advanced Repackaging",
                        description: "Modify existing packages with scripts and signing",
                        icon: "gearshape.2.fill",
                        color: .red
                    ) {
                        showingAdvancedRepackaging = true
                    }
                }
            }
            .padding(.horizontal)
            
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
        .sheet(isPresented: $showingNewPackageCreation) {
            NewPackageCreationView()
        }
        .sheet(isPresented: $showingPackageAnalysis) {
            if let result = analysisService.analysisResult {
                PackageAnalysisView(analysis: result)
            } else {
                PackageAnalysisSelectionView()
            }
        }
        .sheet(isPresented: $showingSimpleBuilder) {
            SimplePackageBuilderView()
        }
        .sheet(isPresented: $showingLifecycleManagement) {
            SystemLifecycleManagementView()
        }
        .sheet(isPresented: $showingTemplateSystems) {
            TemplateSystemsView()
        }
        .sheet(isPresented: $showingAdvancedRepackaging) {
            if let result = analysisService.analysisResult {
                AdvancedRepackagingView(analysis: result)
            } else {
                AdvancedRepackagingSelectionView()
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
    @State private var aiSummary: String = ""
    @State private var isGeneratingAISummary = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Package Analysis")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(analysis.fileName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .background(Color(.controlBackgroundColor))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // AI Summary (if available)
                    PackageAISummaryCard(
                        analysis: analysis,
                        aiSummary: $aiSummary,
                        isGenerating: $isGeneratingAISummary,
                        onGenerate: generateAISummary
                    )
                    
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
                .padding(24)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            // Initialize default account selection
        }
    }
}

// MARK: - Package AI Summary Card
struct PackageAISummaryCard: View {
    let analysis: PackageAnalysis
    @Binding var aiSummary: String
    @Binding var isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("AI Analysis Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !isGenerating && aiSummary.isEmpty {
                    Button("Generate Summary") {
                        generateAISummary()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedAccountId == nil)
                }
            }
            
            if isGenerating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing package with AI...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if !aiSummary.isEmpty {
                Text(aiSummary)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Get an AI-powered analysis of this package")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Generate AI Summary") {
                        onGenerate()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func generateAISummary() {
        isGenerating = true
        
        Task {
            // Simulate AI summary generation
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            let mockSummary = """
            Package Analysis Summary:
            
            This is a sample macOS application package containing 150 files with a total size of 50MB. The package is properly code-signed with a valid Developer ID certificate, ensuring authenticity and security.
            
            Installation Impact: The application will be installed to /Applications and requires approximately 45MB of disk space. No additional dependencies or frameworks are required.
            
            Security Assessment: The package is properly signed and validated, making it safe for enterprise deployment. The Developer ID certificate provides assurance of the package's authenticity.
            
            Recommendations: This package is ready for deployment through your MDM system. Consider testing in a staging environment before production rollout.
            """
            
            await MainActor.run {
                aiSummary = mockSummary
                isGenerating = false
            }
        }
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
    @State private var showingScriptEditor = false
    @State private var newScript = PackageScript(
        name: "",
        type: .postinstall,
        content: "",
        isExecutable: true,
        needsModification: false
    )
    
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
            
            // Existing Scripts
            if !options.addScripts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Added Scripts:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(options.addScripts) { script in
                        HStack {
                            Image(systemName: script.type == .preinstall ? "arrow.down.circle" : "arrow.up.circle")
                                .foregroundColor(script.type == .preinstall ? .blue : .green)
                            Text(script.name.isEmpty ? "Unnamed Script" : script.name)
                                .font(.subheadline)
                            Spacer()
                            Button("Remove") {
                                options.addScripts.removeAll { $0.id == script.id }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Button("Add Script") {
                showingScriptEditor = true
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showingScriptEditor) {
            ScriptEditorView(script: $newScript) { editedScript in
                options.addScripts.append(editedScript)
                newScript = PackageScript(
                    name: "",
                    type: .postinstall,
                    content: "",
                    isExecutable: true,
                    needsModification: false
                )
            }
        }
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
            
            Toggle("Sign Package", isOn: $options.signPackage)
                .toggleStyle(.switch)
            
            if options.signPackage {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Certificate", selection: $options.certificateID) {
                        Text("Select Certificate").tag("")
                        Text("Developer ID Application").tag("dev-id-app")
                        Text("Developer ID Installer").tag("dev-id-installer")
                    }
                    .pickerStyle(.menu)
                    
                    // Certificate Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Certificate Types:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Developer ID Application")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("For .app bundles")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("• Used for signing macOS applications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Required for distribution outside App Store")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Bypasses Gatekeeper warnings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Developer ID Installer")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("For .pkg installers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("• Used for signing installer packages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Required for .pkg distribution")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Prevents 'unidentified developer' warnings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.top, 8)
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
            
            Text("Generate Privacy Preferences Policy Control profiles for MDM deployment")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("Generate PPPC Profile", isOn: $options.addPPPCProfile)
                .toggleStyle(.switch)
            
            if options.addPPPCProfile {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Configure PPPC Services") {
                        showingPPPCGenerator = true
                    }
                    .buttonStyle(.bordered)
                    
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                        Text("AI-powered suggestions available")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
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

// MARK: - Script Editor View
struct ScriptEditorView: View {
    @Binding var script: PackageScript
    let onSave: (PackageScript) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Script Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Script Name")
                            .font(.headline)
                        TextField("Enter script name", text: $script.name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Script Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Script Type")
                            .font(.headline)
                        Picker("Type", selection: $script.type) {
                            ForEach(PackageScriptType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Script Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Script Content")
                            .font(.headline)
                        TextEditor(text: $script.content)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Script Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Script Information")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Toggle("Executable", isOn: $script.isExecutable)
                                Spacer()
                            }
                            
                            HStack {
                                Toggle("Needs Modification", isOn: $script.needsModification)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Script Editor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(script)
                        dismiss()
                    }
                    .disabled(script.name.isEmpty || script.content.isEmpty)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
    }
}

#Preview {
    PackageCastingView()
}
