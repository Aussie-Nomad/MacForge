//
//  MacForgeTests.swift
//  MacForgeTests
//
//  Comprehensive unit tests for MacForge following Apple's testing guidelines
//  and best practices from device management repositories.
//

import Testing
import XCTest
@testable import MacForge

// MARK: - Core Model Tests
struct ModelTests {
    
    @Test("AppInfo model should properly initialize and compare") func testAppInfoModel() async throws {
        let app1 = AppInfo(name: "Test App", bundleID: "com.test.app", path: "/Applications/Test.app")
        let app2 = AppInfo(name: "Test App", bundleID: "com.test.app", path: "/Applications/Test.app")
        let app3 = AppInfo(name: "Different App", bundleID: "com.different.app", path: "/Applications/Different.app")
        
        #expect(app1 == app2)
        #expect(app1 != app3)
        #expect(app1.bundleID == "com.test.app")
        #expect(app1.path == "/Applications/Test.app")
    }
    
    @Test("PPPCService model should properly categorize services") func testPPPCServiceModel() async throws {
        let systemService = PPPCService(
            id: "SystemPolicyAllFiles",
            name: "System Policy All Files",
            description: "Full disk access",
            category: .systemPolicy,
            requiresBundleID: true,
            requiresCodeRequirement: false,
            requiresIdentifier: true
        )
        
        #expect(systemService.category == .systemPolicy)
        #expect(systemService.requiresBundleID == true)
        #expect(systemService.displayName == "System Policy All Files")
    }
    
    @Test("PPPCConfiguration model should properly initialize and validate") func testPPPCConfigurationModel() async throws {
        let service = PPPCService(
            id: "Accessibility",
            name: "Accessibility",
            description: "Accessibility services",
            category: .accessibility,
            requiresBundleID: true,
            requiresCodeRequirement: false,
            requiresIdentifier: true
        )
        
        let config = PPPCConfiguration(
            service: service,
            identifier: "com.test.app",
            identifierType: .bundleID
        )
        
        #expect(config.service.id == "Accessibility")
        #expect(config.identifier == "com.test.app")
        #expect(config.identifierType == .bundleID)
        #expect(config.allowed == true)
        #expect(config.userOverride == false)
    }
}

// MARK: - Builder Model Tests
struct BuilderModelTests {
    
    @Test("BuilderModel should properly manage payloads") func testPayloadManagement() async throws {
        await MainActor.run {
            let model = BuilderModel(
                authenticationService: JAMFAuthenticationService(),
                jamfService: nil,
                profileExportService: MockProfileExportService()
            )
            
            // Test adding payloads
            let payload = Payload(
                id: "test",
                name: "Test Payload",
                description: "Test Description",
                platforms: ["macOS"],
                icon: "test-icon",
                category: "Test"
            )
            
            model.add(payload)
            #expect(model.dropped.count == 1)
            #expect(model.dropped.first?.id == "test")
            
            // Test removing payloads
            model.remove("test")
            #expect(model.dropped.isEmpty)
        }
    }
    
    @Test("BuilderModel should properly handle PPPC configurations") func testPPPCConfigurationManagement() async throws {
        await MainActor.run {
            let model = BuilderModel(
                authenticationService: JAMFAuthenticationService(),
                jamfService: nil,
                profileExportService: MockProfileExportService()
            )
            
            let service = PPPCService(
                id: "Accessibility",
                name: "Accessibility",
                description: "Accessibility services",
                category: .accessibility,
                requiresBundleID: true,
                requiresCodeRequirement: false,
                requiresIdentifier: true
            )
            
            let config = PPPCConfiguration(service: service, identifier: "com.test.app")
            
            model.pppcConfigurations.append(config)
            #expect(model.hasConfiguredPermissions() == true)
            #expect(model.pppcConfigurations.count == 1)
        }
    }
    
    @Test("BuilderModel should properly apply templates") func testTemplateApplication() async throws {
        await MainActor.run {
            let model = BuilderModel(
                authenticationService: JAMFAuthenticationService(),
                jamfService: nil,
                profileExportService: MockProfileExportService()
            )
            
            let template = TemplateProfile(
                name: "Test Template",
                description: "Test template description",
                payloadIDs: ["pppc", "restrictions"]
            )
            
            model.apply(template: template)
            
            #expect(model.dropped.count == 2)
            #expect(model.dropped.contains { $0.id == "pppc" })
            #expect(model.dropped.contains { $0.id == "restrictions" })
        }
    }
}

    // MARK: - PPPC Profile Creator ViewModel Tests
struct ProfileBuilderViewModelTests {
    
    @Test("ProfileBuilderViewModel should properly manage wizard steps") func testWizardStepManagement() async throws {
        await MainActor.run {
            let model = BuilderModel(
                authenticationService: JAMFAuthenticationService(),
                jamfService: nil,
                profileExportService: MockProfileExportService()
            )
            
            let viewModel = ProfileBuilderViewModel(builderModel: model)
            
            #expect(viewModel.currentStep == 1)
            #expect(viewModel.canAdvanceToNextStep == false)
            
            // Add PPPC payload to enable next step
            model.dropped.append(Payload(
                id: "pppc",
                name: "PPPC",
                description: "Privacy Preferences",
                platforms: ["macOS"],
                icon: "lock.shield",
                category: "Security"
            ))
            
            #expect(viewModel.hasPPPCPayload == true)
            #expect(viewModel.canAdvanceToNextStep == true)
        }
    }
    
    @Test("ProfileBuilderViewModel should properly handle step navigation") func testStepNavigation() async throws {
        await MainActor.run {
            let model = BuilderModel(
                authenticationService: JAMFAuthenticationService(),
                jamfService: nil,
                profileExportService: MockProfileExportService()
            )
            
            let viewModel = ProfileBuilderViewModel(builderModel: model)
            
            // Add PPPC payload
            model.dropped.append(Payload(
                id: "pppc",
                name: "PPPC",
                description: "Privacy Preferences",
                platforms: ["macOS"],
                icon: "lock.shield",
                category: "Security"
            ))
            
            // Test next step
            viewModel.nextStep()
            #expect(viewModel.currentStep == 2)
            
            // Test previous step
            viewModel.previousStep()
            #expect(viewModel.currentStep == 1)
        }
    }
}

// MARK: - Authentication Service Tests
struct AuthenticationServiceTests {
    
    @Test("JAMFAuthenticationService should properly validate connections") func testConnectionValidation() async throws {
        let service = JAMFAuthenticationService()
        
        // Test with invalid URL
        do {
            try await service.validateConnection(to: "invalid-url")
            XCTFail("Should have thrown an error")
        } catch {
            #expect(error is AuthenticationError)
        }
    }
    
    @Test("JAMFAuthenticationService should handle authentication errors") func testAuthenticationErrorHandling() async throws {
        let service = JAMFAuthenticationService()
        
        do {
            try await service.authenticateOAuth(
                clientID: "invalid",
                clientSecret: "invalid",
                serverURL: "https://invalid.example.com"
            )
            XCTFail("Should have thrown an error")
        } catch {
            #expect(error is AuthenticationError)
        }
    }
}

// MARK: - Mock Services for Testing
class MockJAMFAuthenticationService: JAMFAuthenticationServiceProtocol {
    @Published var isAuthenticated = false
    @Published var currentToken: String?
    
    func validateConnection(to serverURL: String) async throws {
        // Mock implementation for testing
    }
    
    func authenticateOAuth(clientID: String, clientSecret: String, serverURL: String) async throws -> String {
        return "mock-token"
    }
    
    func authenticateBasic(username: String, password: String, serverURL: String) async throws -> String {
        return "mock-token"
    }
    
    func logout() {
        currentToken = nil
        isAuthenticated = false
    }
    
    func debugJAMFEndpoints(serverURL: String) async -> String {
        return "Mock JAMF Debug Info\n✅ Server ping: SUCCESS\n✅ Auth endpoint: REACHABLE\n✅ JSSResource/computers: HTTP 401\n✅ JSSResource/osxconfigurationprofiles: HTTP 401\n✅ JSSResource/accounts: HTTP 401\n\nDebug completed at: \(Date())"
    }
}

class MockProfileExportService: ProfileExportServiceProtocol {
    func exportProfile(_ profile: ConfigurationProfile) throws -> Data {
        return Data()
    }
    
    func saveProfileToDownloads(_ profile: ConfigurationProfile) throws -> URL {
        return URL(fileURLWithPath: "/tmp/mock-profile.mobileconfig")
    }
    
    func validateProfile(_ profile: ConfigurationProfile) -> [ProfileValidationError] {
        return []
    }
}

// MARK: - Test Configuration
struct TestConfiguration {
    static let timeout: TimeInterval = 5.0
    static let testBundleID = "com.test.app"
    static let testAppPath = "/Applications/Test.app"
}

