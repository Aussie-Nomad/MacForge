//
//  MacForgeDownloadsServiceTests.swift
//  MacForgeTests
//
//  Tests for the MacForgeDownloadsService to verify folder structure creation
//  and basic export functionality.
//

import Testing
import XCTest
@testable import MacForge

// MARK: - Downloads Service Tests
struct MacForgeDownloadsServiceTests {
    
    @Test("Downloads service should initialize folder structure") func testFolderStructureInitialization() async throws {
        let service = MacForgeDownloadsService()
        
        // Wait for initialization to complete
        var attempts = 0
        while !service.isInitialized && attempts < 10 {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            attempts += 1
        }
        
        #expect(service.isInitialized == true)
        #expect(service.downloadsPath.path.contains("MacForge"))
        
        // Verify the downloads path exists
        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: service.downloadsPath.path))
    }
    
    @Test("Downloads service should create all required subfolders") func testSubfolderCreation() async throws {
        let service = MacForgeDownloadsService()
        
        // Wait for initialization
        var attempts = 0
        while !service.isInitialized && attempts < 10 {
            try await Task.sleep(nanoseconds: 100_000_000)
            attempts += 1
        }
        
        let fileManager = FileManager.default
        let basePath = service.downloadsPath
        
        // Check main folders
        let mainFolders = ["Profiles", "Scripts", "XML", "Packages", "Logs"]
        for folder in mainFolders {
            let folderPath = basePath.appendingPathComponent(folder)
            #expect(fileManager.fileExists(atPath: folderPath.path))
        }
        
        // Check profile subfolders
        let profileSubfolders = ["PPPC", "WiFi", "VPN", "Custom"]
        for folder in profileSubfolders {
            let folderPath = basePath.appendingPathComponent("Profiles").appendingPathComponent(folder)
            #expect(fileManager.fileExists(atPath: folderPath.path))
        }
        
        // Check script subfolders
        let scriptSubfolders = ["Generated", "Templates"]
        for folder in scriptSubfolders {
            let folderPath = basePath.appendingPathComponent("Scripts").appendingPathComponent(folder)
            #expect(fileManager.fileExists(atPath: folderPath.path))
        }
    }
    
    @Test("Downloads service should create README file") func testReadmeCreation() async throws {
        let service = MacForgeDownloadsService()
        
        // Wait for initialization
        var attempts = 0
        while !service.isInitialized && attempts < 10 {
            try await Task.sleep(nanoseconds: 100_000_000)
            attempts += 1
        }
        
        let readmePath = service.downloadsPath.appendingPathComponent("README.md")
        let fileManager = FileManager.default
        
        #expect(fileManager.fileExists(atPath: readmePath.path))
        
        // Verify README content
        if let readmeContent = try? String(contentsOf: readmePath) {
            #expect(readmeContent.contains("MacForge Downloads Folder"))
            #expect(readmeContent.contains("Profiles/"))
            #expect(readmeContent.contains("Scripts/"))
            #expect(readmeContent.contains("XML/"))
        }
    }
    
    @Test("Downloads service should handle export statistics") func testExportStatistics() async throws {
        let service = MacForgeDownloadsService()
        
        // Wait for initialization
        var attempts = 0
        while !service.isInitialized && attempts < 10 {
            try await Task.sleep(nanoseconds: 100_000_000)
            attempts += 1
        }
        
        let initialCount = service.exportCount
        let initialDate = service.lastExportDate
        
        // Simulate an export (this would normally be called by actual export methods)
        await service.updateExportStats()
        
        #expect(service.exportCount == initialCount + 1)
        #expect(service.lastExportDate != initialDate)
    }
}

// MARK: - Mock Profile for Testing
struct MockProfile: ExportableProfile {
    let name: String
    let description: String
    let identifier: String
    
    init(name: String = "Test Profile", description: String = "Test Description", identifier: String = "com.test.profile") {
        self.name = name
        self.description = description
        self.identifier = identifier
    }
}

// MARK: - Test Configuration
extension MacForgeDownloadsServiceTests {
    static let timeout: TimeInterval = 5.0
    static let testFolderName = "MacForgeTest"
}
