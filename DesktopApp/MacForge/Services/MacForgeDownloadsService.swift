//
//  MacForgeDownloadsService.swift
//  MacForge
//
//  Core downloads service for MacForge application.
//  Manages folder structure, file organization, and export operations.
//

import Foundation
import SwiftUI

// Protocol for profile types to make the service more flexible
protocol ExportableProfile {
    var name: String { get }
    var description: String { get }
    var identifier: String { get }
}

// MARK: - Downloads Service
final class MacForgeDownloadsService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var downloadsPath: URL
    @Published var isInitialized = false
    @Published var lastExportDate: Date?
    @Published var exportCount: Int = 0
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Folder Structure Constants
    private struct FolderStructure {
        static let root = "MacForge"
        static let profiles = "Profiles"
        static let scripts = "Scripts"
        static let xml = "XML"
        static let packages = "Packages"
        static let logs = "Logs"
        
        // Profile subfolders
        static let pppc = "PPPC"
        static let wifi = "WiFi"
        static let vpn = "VPN"
        static let custom = "Custom"
        
        // Script subfolders
        static let generated = "Generated"
        static let templates = "Templates"
        
        // XML subfolders
        static let jamf = "JAMF"
        static let intune = "Intune"
        static let customXML = "Custom"
        
        // Package subfolders
        static let analyzed = "Analyzed"
        static let modified = "Modified"
        
        // Log subfolders
        static let build = "Build"
        static let export = "Export"
    }
    
    // MARK: - Initialization
    init() {
        // Get downloads path from user preferences or use default
        if let savedPath = userDefaults.url(forKey: "MacForge.DownloadsPath") {
            self.downloadsPath = savedPath
        } else {
            // Default to ~/Downloads/MacForge
            let downloadsFolder = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            self.downloadsPath = downloadsFolder.appendingPathComponent(FolderStructure.root)
        }
        
        // Initialize folder structure
        Task {
            await initializeFolderStructure()
        }
    }
    
    // MARK: - Public Methods
    
    /// Initialize the complete folder structure
    @MainActor
    func initializeFolderStructure() async {
        do {
            try await createFolderStructure()
            isInitialized = true
            print("✅ MacForge downloads folder structure initialized at: \(downloadsPath.path)")
        } catch {
            print("❌ Failed to initialize downloads folder structure: \(error)")
            isInitialized = false
        }
    }
    
    /// Export a profile to the appropriate folder
    func exportProfile(_ profile: ExportableProfile, type: ProfileType, name: String? = nil) async throws -> URL {
        let fileName = name ?? generateFileName(for: profile, type: type)
        let folderPath = getProfileFolder(for: type)
        let filePath = folderPath.appendingPathComponent(fileName)
        
        // Ensure folder exists
        try await ensureFolderExists(folderPath)
        
        // Export the profile
        let data = try await exportProfileData(profile)
        try data.write(to: filePath)
        
        // Update export statistics
        await updateExportStats()
        
        return filePath
    }
    
    /// Export a script to the scripts folder
    func exportScript(_ script: String, name: String, type: ScriptType = .generated) async throws -> URL {
        let fileName = name.hasSuffix(".sh") ? name : "\(name).sh"
        let folderPath = getScriptFolder(for: type)
        let filePath = folderPath.appendingPathComponent(fileName)
        
        // Ensure folder exists
        try await ensureFolderExists(folderPath)
        
        // Write script content
        try script.write(to: filePath, atomically: true, encoding: .utf8)
        
        // Update export statistics
        await updateExportStats()
        
        return filePath
    }
    
    /// Export XML content to the appropriate folder
    func exportXML(_ xmlContent: String, name: String, type: XMLType) async throws -> URL {
        let fileName = name.hasSuffix(".xml") ? name : "\(name).xml"
        let folderPath = getXMLFolder(for: type)
        let filePath = folderPath.appendingPathComponent(fileName)
        
        // Ensure folder exists
        try await ensureFolderExists(folderPath)
        
        // Write XML content
        try xmlContent.write(to: filePath, atomically: true, encoding: .utf8)
        
        // Update export statistics
        await updateExportStats()
        
        return filePath
    }
    
    /// Export package analysis results
    func exportPackageAnalysis(_ analysis: [String: String], name: String) async throws -> URL {
        let fileName = "\(name)_analysis.json"
        let folderPath = getPackageFolder(for: .analyzed)
        let filePath = folderPath.appendingPathComponent(fileName)
        
        // Ensure folder exists
        try await ensureFolderExists(folderPath)
        
        // Convert analysis to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(analysis)
        try data.write(to: filePath)
        
        // Update export statistics
        await updateExportStats()
        
        return filePath
    }
    
    /// Get the current downloads folder size
    func getDownloadsFolderSize() async -> Int64 {
        return await calculateFolderSize(downloadsPath)
    }
    
    /// Clear old exports (older than specified days)
    func clearOldExports(olderThan days: Int) async throws {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        try await clearFilesOlderThan(cutoffDate, in: downloadsPath)
    }
    
    /// Open the downloads folder in Finder
    func openDownloadsFolder() {
        NSWorkspace.shared.open(downloadsPath)
    }
    
    /// Change the downloads location
    func changeDownloadsLocation(to newPath: URL) async throws {
        // Validate the new path
        guard fileManager.isWritableFile(atPath: newPath.path) else {
            throw DownloadsError.pathNotWritable
        }
        
        // Move existing downloads if they exist
        if isInitialized {
            try await moveExistingDownloads(to: newPath)
        }
        
        // Update the path
        downloadsPath = newPath
        userDefaults.set(newPath, forKey: "MacForge.DownloadsPath")
        
        // Reinitialize folder structure
        await initializeFolderStructure()
    }
    
    // MARK: - Private Methods
    
    private func createFolderStructure() async throws {
        let folders = [
            downloadsPath,
            downloadsPath.appendingPathComponent(FolderStructure.profiles),
            downloadsPath.appendingPathComponent(FolderStructure.profiles).appendingPathComponent(FolderStructure.pppc),
            downloadsPath.appendingPathComponent(FolderStructure.profiles).appendingPathComponent(FolderStructure.wifi),
            downloadsPath.appendingPathComponent(FolderStructure.profiles).appendingPathComponent(FolderStructure.vpn),
            downloadsPath.appendingPathComponent(FolderStructure.profiles).appendingPathComponent(FolderStructure.custom),
            downloadsPath.appendingPathComponent(FolderStructure.scripts),
            downloadsPath.appendingPathComponent(FolderStructure.scripts).appendingPathComponent(FolderStructure.generated),
            downloadsPath.appendingPathComponent(FolderStructure.scripts).appendingPathComponent(FolderStructure.templates),
            downloadsPath.appendingPathComponent(FolderStructure.xml),
            downloadsPath.appendingPathComponent(FolderStructure.xml).appendingPathComponent(FolderStructure.jamf),
            downloadsPath.appendingPathComponent(FolderStructure.xml).appendingPathComponent(FolderStructure.intune),
            downloadsPath.appendingPathComponent(FolderStructure.xml).appendingPathComponent(FolderStructure.customXML),
            downloadsPath.appendingPathComponent(FolderStructure.packages),
            downloadsPath.appendingPathComponent(FolderStructure.packages).appendingPathComponent(FolderStructure.analyzed),
            downloadsPath.appendingPathComponent(FolderStructure.packages).appendingPathComponent(FolderStructure.modified),
            downloadsPath.appendingPathComponent(FolderStructure.logs),
            downloadsPath.appendingPathComponent(FolderStructure.logs).appendingPathComponent(FolderStructure.build),
            downloadsPath.appendingPathComponent(FolderStructure.logs).appendingPathComponent(FolderStructure.export)
        ]
        
        for folder in folders {
            try await ensureFolderExists(folder)
        }
        
        // Create a README file explaining the folder structure
        try await createReadmeFile()
    }
    
    private func ensureFolderExists(_ folder: URL) async throws {
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
    }
    
    private func createReadmeFile() async throws {
        let readmeContent = """
        # MacForge Downloads Folder
        
        This folder contains all exports and generated files from MacForge.
        
        ## Folder Structure
        
        ### Profiles/
        - **PPPC/**: Privacy Preferences Policy Control profiles
        - **WiFi/**: WiFi configuration profiles
        - **VPN/**: VPN configuration profiles
        - **Custom/**: Custom configuration profiles
        
        ### Scripts/
        - **Generated/**: AI-generated and custom scripts
        - **Templates/**: Script templates and examples
        
        ### XML/
        - **JAMF/**: JAMF Pro specific XML exports
        - **Intune/**: Microsoft Intune XML exports
        - **Custom/**: Custom XML configurations
        
        ### Packages/
        - **Analyzed/**: Package analysis results
        - **Modified/**: Modified package files
        
        ### Logs/
        - **Build/**: Build and compilation logs
        - **Export/**: Export operation logs
        
        ## File Naming Convention
        
        Files are automatically named using the pattern:
        `[ProfileName]_[Date]_[Time].[Extension]`
        
        Example: `PPPC_Profile_2025-08-29_14-30-00.mobileconfig`
        
        ## Notes
        
        - This folder structure is automatically maintained by MacForge
        - Old files can be cleaned up using the Clear Old Exports feature
        - All exports include metadata and timestamps
        """
        
        let readmePath = downloadsPath.appendingPathComponent("README.md")
        try readmeContent.write(to: readmePath, atomically: true, encoding: .utf8)
    }
    
    private func generateFileName(for profile: ExportableProfile, type: ProfileType) -> String {
        let timestamp = DateFormatter.fileTimestamp.string(from: Date())
        let sanitizedName = profile.name.replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
        
        switch type {
        case .pppc:
            return "\(sanitizedName)_\(timestamp).mobileconfig"
        case .wifi:
            return "\(sanitizedName)_\(timestamp).mobileconfig"
        case .vpn:
            return "\(sanitizedName)_\(timestamp).mobileconfig"
        case .custom:
            return "\(sanitizedName)_\(timestamp).mobileconfig"
        }
    }
    
    private func getProfileFolder(for type: ProfileType) -> URL {
        let baseFolder = downloadsPath.appendingPathComponent(FolderStructure.profiles)
        
        switch type {
        case .pppc:
            return baseFolder.appendingPathComponent(FolderStructure.pppc)
        case .wifi:
            return baseFolder.appendingPathComponent(FolderStructure.wifi)
        case .vpn:
            return baseFolder.appendingPathComponent(FolderStructure.vpn)
        case .custom:
            return baseFolder.appendingPathComponent(FolderStructure.custom)
        }
    }
    
    private func getScriptFolder(for type: ScriptType) -> URL {
        let baseFolder = downloadsPath.appendingPathComponent(FolderStructure.scripts)
        
        switch type {
        case .generated:
            return baseFolder.appendingPathComponent(FolderStructure.generated)
        case .templates:
            return baseFolder.appendingPathComponent(FolderStructure.templates)
        }
    }
    
    private func getXMLFolder(for type: XMLType) -> URL {
        let baseFolder = downloadsPath.appendingPathComponent(FolderStructure.xml)
        
        switch type {
        case .jamf:
            return baseFolder.appendingPathComponent(FolderStructure.jamf)
        case .intune:
            return baseFolder.appendingPathComponent(FolderStructure.intune)
        case .custom:
            return baseFolder.appendingPathComponent(FolderStructure.customXML)
        }
    }
    
    private func getPackageFolder(for type: PackageFolderType) -> URL {
        let baseFolder = downloadsPath.appendingPathComponent(FolderStructure.packages)
        
        switch type {
        case .analyzed:
            return baseFolder.appendingPathComponent(FolderStructure.analyzed)
        case .modified:
            return baseFolder.appendingPathComponent(FolderStructure.modified)
        }
    }
    
    private func exportProfileData(_ profile: ExportableProfile) async throws -> Data {
        // This will be implemented to work with the existing ProfileExportService
        // For now, return empty data as placeholder
        return Data()
    }
    
    private func updateExportStats() async {
        await MainActor.run {
            exportCount += 1
            lastExportDate = Date()
        }
    }
    
    private func calculateFolderSize(_ folder: URL) async -> Int64 {
        var totalSize: Int64 = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey])
            
            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                
                if let isDirectory = resourceValues.isDirectory, isDirectory {
                    totalSize += await calculateFolderSize(url)
                } else if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        } catch {
            print("Error calculating folder size: \(error)")
        }
        
        return totalSize
    }
    
    private func clearFilesOlderThan(_ date: Date, in folder: URL) async throws {
        let contents = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey])
        
        for url in contents {
            let resourceValues = try url.resourceValues(forKeys: [.creationDateKey, .isDirectoryKey])
            
            if let isDirectory = resourceValues.isDirectory, isDirectory {
                // Recursively clear subdirectories
                try await clearFilesOlderThan(date, in: url)
            } else if let creationDate = resourceValues.creationDate, creationDate < date {
                // Remove old file
                try fileManager.removeItem(at: url)
            }
        }
    }
    
    private func moveExistingDownloads(to newPath: URL) async throws {
        // Implementation for moving existing downloads
        // This would be called when changing download location
    }
}

// MARK: - Supporting Types

enum ProfileType {
    case pppc
    case wifi
    case vpn
    case custom
}

enum ScriptType {
    case generated
    case templates
}

enum XMLType {
    case jamf
    case intune
    case custom
}

enum PackageFolderType {
    case analyzed
    case modified
}

enum DownloadsError: LocalizedError {
    case pathNotWritable
    case folderCreationFailed
    case fileWriteFailed
    
    var errorDescription: String? {
        switch self {
        case .pathNotWritable:
            return "The selected path is not writable"
        case .folderCreationFailed:
            return "Failed to create downloads folder structure"
        case .fileWriteFailed:
            return "Failed to write file to downloads folder"
        }
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let fileTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
