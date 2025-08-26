//
//  PPPCConfigurationTests.swift
//  MacForgeTests
//
//  Specialized tests for PPPC (Privacy Preferences Policy Control) configuration
//  following Apple's testing guidelines and device management best practices.
//

import Testing
import XCTest
@testable import MacForge

// MARK: - PPPC Service Category Tests
struct PPPCServiceCategoryTests {
    
    @Test("PPPCServiceCategory should provide proper display names") func testCategoryDisplayNames() async throws {
        #expect(PPPCServiceCategory.system.displayName == "System")
        #expect(PPPCServiceCategory.accessibility.displayName == "Accessibility")
        #expect(PPPCServiceCategory.automation.displayName == "Automation")
        #expect(PPPCServiceCategory.inputMonitoring.displayName == "Input Monitoring")
        #expect(PPPCServiceCategory.media.displayName == "Media")
        #expect(PPPCServiceCategory.network.displayName == "Network")
        #expect(PPPCServiceCategory.systemPolicy.displayName == "System Policy")
    }
    
    @Test("PPPCServiceCategory should support all cases") func testAllCategories() async throws {
        let allCategories = PPPCServiceCategory.allCases
        #expect(allCategories.count == 7, "Should have exactly 7 PPPC service categories")
        
        // Verify each category has a unique identifier
        let uniqueIds = Set(allCategories.map { $0.rawValue })
        #expect(uniqueIds.count == allCategories.count, "All categories should have unique identifiers")
    }
}

// MARK: - PPPC Service Validation Tests
struct PPPCServiceValidationTests {
    
    @Test("PPPCService should validate required fields correctly") func testServiceValidation() async throws {
        // Test service with all required fields
        let validService = PPPCService(
            id: "SystemPolicyAllFiles",
            name: "System Policy All Files",
            description: "Full disk access for system-wide file operations",
            category: .systemPolicy,
            requiresBundleID: true,
            requiresCodeRequirement: false,
            requiresIdentifier: true
        )
        
        #expect(validService.id.isEmpty == false)
        #expect(validService.name.isEmpty == false)
        #expect(validService.description.isEmpty == false)
        #expect(validService.displayName == validService.name)
        
        // Test service with minimal fields
        let minimalService = PPPCService(
            id: "MinimalService",
            name: "Minimal",
            description: "Minimal description",
            category: .system,
            requiresBundleID: false,
            requiresCodeRequirement: false,
            requiresIdentifier: false
        )
        
        #expect(minimalService.id == "MinimalService")
        #expect(minimalService.requiresBundleID == false)
    }
    
    @Test("PPPCService should handle special cases correctly") func testSpecialServiceCases() async throws {
        // Test Apple Events service (requires special handling)
        let appleEventsService = PPPCService(
            id: "AppleEvents",
            name: "Apple Events",
            description: "Send Apple Events to other applications",
            category: .automation,
            requiresBundleID: true,
            requiresCodeRequirement: false,
            requiresIdentifier: true
        )
        
        #expect(appleEventsService.category == .automation)
        #expect(appleEventsService.requiresBundleID == true)
        
        // Test Screen Capture service
        let screenCaptureService = PPPCService(
            id: "ScreenCapture",
            name: "Screen Capture",
            description: "Capture screen content",
            category: .media,
            requiresBundleID: true,
            requiresCodeRequirement: false,
            requiresIdentifier: true
        )
        
        #expect(screenCaptureService.category == .media)
    }
}

// MARK: - PPPC Configuration Tests
struct PPPCConfigurationTests {
    
    @Test("PPPCConfiguration should initialize with default values") func testDefaultInitialization() async throws {
        let service = PPPCService(
            id: "TestService",
            name: "Test Service",
            description: "Test description",
            category: .system,
            requiresBundleID: true,
            requiresCodeRequirement: false,
            requiresIdentifier: true
        )
        
        let config = PPPCConfiguration(service: service, identifier: "com.test.app")
        
        #expect(config.service.id == "TestService")
        #expect(config.identifier == "com.test.app")
        #expect(config.identifierType == .bundleID)
        #expect(config.allowed == true)
        #expect(config.userOverride == false)
        #expect(config.comment == nil)
    }
    
    @Test("PPPCConfiguration should support custom identifier types") func testCustomIdentifierTypes() async throws {
        let service = PPPCService(
            id: "CustomService",
            name: "Custom Service",
            description: "Custom description",
            category: .system,
            requiresBundleID: false,
            requiresCodeRequirement: true,
            requiresIdentifier: true
        )
        
        let pathConfig = PPPCConfiguration(
            service: service,
            identifier: "/Applications/Custom.app",
            identifierType: .path
        )
        
        #expect(pathConfig.identifierType == .path)
        #expect(pathConfig.identifier == "/Applications/Custom.app")
        
        let codeConfig = PPPCConfiguration(
            service: service,
            identifier: "code requirement string",
            identifierType: .codeRequirement
        )
        
        #expect(codeConfig.identifierType == .codeRequirement)
    }
    
    @Test("PPPCConfiguration should handle user override settings") func testUserOverrideSettings() async throws {
        let service = PPPCService(
            id: "OverrideService",
            name: "Override Service",
            description: "Service with user override",
            category: .accessibility,
            requiresBundleID: true,
            requiresCodeRequirement: false,
            requiresIdentifier: true
        )
        
        var config = PPPCConfiguration(service: service, identifier: "com.override.app")
        config.userOverride = true
        config.comment = "User can override this setting"
        
        #expect(config.userOverride == true)
        #expect(config.comment == "User can override this setting")
    }
}

// MARK: - PPPC Service Catalog Tests
struct PPPCServiceCatalogTests {
    
    @Test("PPPC service catalog should contain expected services") func testServiceCatalog() async throws {
        let services = pppcServices
        
        #expect(services.isEmpty == false, "Service catalog should not be empty")
        
        // Test that critical services are present
        let criticalServiceIds = [
            "SystemPolicyAllFiles",
            "Accessibility",
            "ScreenCapture",
            "AppleEvents",
            "Microphone",
            "Camera"
        ]
        
        for serviceId in criticalServiceIds {
            let service = services.first { $0.id == serviceId }
            #expect(service != nil, "Critical service \(serviceId) should be present in catalog")
        }
    }
    
    @Test("PPPC service catalog should have proper categorization") func testServiceCategorization() async throws {
        let services = pppcServices
        
        // Test that services are properly categorized
        let systemPolicyServices = services.filter { $0.category == .systemPolicy }
        #expect(systemPolicyServices.isEmpty == false, "Should have system policy services")
        
        let accessibilityServices = services.filter { $0.category == .accessibility }
        #expect(accessibilityServices.isEmpty == false, "Should have accessibility services")
        
        let mediaServices = services.filter { $0.category == .media }
        #expect(mediaServices.isEmpty == false, "Should have media services")
    }
    
    @Test("PPPC service catalog should have consistent data quality") func testServiceDataQuality() async throws {
        let services = pppcServices
        
        for service in services {
            // Each service should have required fields
            #expect(service.id.isEmpty == false, "Service should have non-empty ID")
            #expect(service.name.isEmpty == false, "Service should have non-empty name")
            #expect(service.description.isEmpty == false, "Service should have non-empty description")
            
            // Service ID should be unique
            let duplicateServices = services.filter { $0.id == service.id }
            #expect(duplicateServices.count == 1, "Service ID should be unique: \(service.id)")
        }
    }
}

// MARK: - PPPC Configuration Management Tests
struct PPPCConfigurationManagementTests {
    
    @Test("BuilderModel should properly manage PPPC configurations") func testConfigurationManagement() async throws {
        let model = BuilderModel(
            authenticationService: MockJAMFAuthenticationService(),
            jamfService: nil,
            profileExportService: MockProfileExportService()
        )
        
        // Test adding configurations
        let service = pppcServices.first!
        let config = PPPCConfiguration(service: service, identifier: "com.test.app")
        
        model.pppcConfigurations.append(config)
        #expect(model.pppcConfigurations.count == 1)
        #expect(model.hasConfiguredPermissions() == true)
        
        // Test removing configurations
        model.pppcConfigurations.removeAll()
        #expect(model.pppcConfigurations.isEmpty)
        #expect(model.hasConfiguredPermissions() == false)
    }
    
    @Test("BuilderModel should validate PPPC configurations") func testConfigurationValidation() async throws {
        let model = BuilderModel(
            authenticationService: MockJAMFAuthenticationService(),
            jamfService: nil,
            profileExportService: MockProfileExportService()
        )
        
        // Test with valid configuration
        let validService = pppcServices.first!
        let validConfig = PPPCConfiguration(service: validService, identifier: "com.valid.app")
        model.pppcConfigurations.append(validConfig)
        
        #expect(model.hasConfiguredPermissions() == true)
        
        // Test with empty configurations
        model.pppcConfigurations.removeAll()
        #expect(model.hasConfiguredPermissions() == false)
    }
}

// MARK: - PPPC Export Tests
struct PPPCExportTests {
    
    @Test("PPPC configurations should export correctly") func testConfigurationExport() async throws {
        let model = BuilderModel(
            authenticationService: MockJAMFAuthenticationService(),
            jamfService: nil,
            profileExportService: MockProfileExportService()
        )
        
        // Add test configurations
        let accessibilityService = pppcServices.first { $0.id == "Accessibility" }!
        let accessibilityConfig = PPPCConfiguration(
            service: accessibilityService,
            identifier: "com.accessibility.app"
        )
        
        let screenCaptureService = pppcServices.first { $0.id == "ScreenCapture" }!
        let screenCaptureConfig = PPPCConfiguration(
            service: screenCaptureService,
            identifier: "com.screencapture.app"
        )
        
        model.pppcConfigurations.append(contentsOf: [accessibilityConfig, screenCaptureConfig])
        
        // Test export
        let exportedServices = model.buildPPPCServices()
        #expect(exportedServices.count == 2)
        
        // Verify exported data structure
        let accessibilityExport = exportedServices.first { $0["Service"] as? String == "Accessibility" }
        #expect(accessibilityExport != nil)
        #expect(accessibilityExport?["Authorization"] as? String == "Allow")
        #expect(accessibilityExport?["ReceiverIdentifier"] as? String == "com.accessibility.app")
    }
}

// MARK: - Test Utilities
extension PPPCConfigurationTests {
    
    func createTestService(id: String, category: PPPCServiceCategory) -> PPPCService {
        return PPPCService(
            id: id,
            name: "Test \(id)",
            description: "Test description for \(id)",
            category: category,
            requiresBundleID: true,
            requiresCodeRequirement: false,
            requiresIdentifier: true
        )
    }
    
    func createTestConfiguration(service: PPPCService, identifier: String) -> PPPCConfiguration {
        return PPPCConfiguration(
            service: service,
            identifier: identifier,
            identifierType: .bundleID
        )
    }
}
