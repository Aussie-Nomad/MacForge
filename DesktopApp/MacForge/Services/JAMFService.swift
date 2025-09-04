//
//  JAMFService.swift
//  MacForge
//
//  Service layer for JAMF Pro operations and API interactions.
//  Handles profile management, device operations, and JAMF-specific functionality.
//

import Foundation

// MARK: - JAMF Service Protocol
protocol JAMFServiceProtocol {
    // Profile Operations
    func uploadProfile(name: String, xmlData: Data) async throws
    func uploadOrUpdateProfile(name: String, xmlData: Data) async throws
    func findProfileByName(_ name: String) async throws -> JAMFProfile?
    func getAllConfigurationProfiles() async throws -> [JAMFProfile]
    func getConfigurationProfile(by id: Int) async throws -> JAMFProfile?
    
    // Policy Operations
    func getAllPolicies() async throws -> [JAMFPolicy]
    func getPolicy(by id: Int) async throws -> JAMFPolicy?
    func getPolicy(by name: String) async throws -> JAMFPolicy?
    
    // Connection Testing
    func testConnection() async throws -> Bool
}

// MARK: - JAMF Profile Model
struct JAMFProfile: Codable, Identifiable {
    let id: Int
    let name: String
    let distributionMethod: String?
    let payloads: String?
    let description: String?
    let category: String?
    let site: String?
    let userRemovable: Bool?
    let level: String?
    let redeployOnUpdate: String?
    let payloadsData: [JAMFPayload]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case distributionMethod = "distribution_method"
        case payloads
        case description
        case category
        case site
        case userRemovable = "user_removable"
        case level
        case redeployOnUpdate = "redeploy_on_update"
        case payloadsData = "payloads_data"
    }
}

// MARK: - JAMF Policy Model
struct JAMFPolicy: Codable, Identifiable {
    let id: Int
    let name: String
    let enabled: Bool?
    let trigger: String?
    let triggerCheckin: Bool?
    let triggerEnrollmentComplete: Bool?
    let triggerLogin: Bool?
    let triggerLogout: Bool?
    let triggerNetworkStateChanged: Bool?
    let triggerStartup: Bool?
    let triggerOther: String?
    let frequency: String?
    let retryEvent: String?
    let retryAttempts: Int?
    let notifyOnEachFailedRetry: Bool?
    let locationUserOnly: Bool?
    let targetDrive: String?
    let offline: Bool?
    let category: String?
    let site: String?
    let payloads: [JAMFPayload]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case enabled
        case trigger
        case triggerCheckin = "trigger_checkin"
        case triggerEnrollmentComplete = "trigger_enrollment_complete"
        case triggerLogin = "trigger_login"
        case triggerLogout = "trigger_logout"
        case triggerNetworkStateChanged = "trigger_network_state_changed"
        case triggerStartup = "trigger_startup"
        case triggerOther = "trigger_other"
        case frequency
        case retryEvent = "retry_event"
        case retryAttempts = "retry_attempts"
        case notifyOnEachFailedRetry = "notify_on_each_failed_retry"
        case locationUserOnly = "location_user_only"
        case targetDrive = "target_drive"
        case offline
        case category
        case site
        case payloads
    }
}

// MARK: - JAMF Payload Model
struct JAMFPayload: Codable {
    let payloadType: String?
    let payloadIdentifier: String?
    let payloadUUID: String?
    let payloadVersion: Int?
    let payloadDisplayName: String?
    let payloadDescription: String?
    let payloadOrganization: String?
    let payloadRemovalDisallowed: Bool?
    let payloadContent: String?
    
    enum CodingKeys: String, CodingKey {
        case payloadType = "PayloadType"
        case payloadIdentifier = "PayloadIdentifier"
        case payloadUUID = "PayloadUUID"
        case payloadVersion = "PayloadVersion"
        case payloadDisplayName = "PayloadDisplayName"
        case payloadDescription = "PayloadDescription"
        case payloadOrganization = "PayloadOrganization"
        case payloadRemovalDisallowed = "PayloadRemovalDisallowed"
        case payloadContent = "PayloadContent"
    }
}

// MARK: - JAMF Service Implementation
final class JAMFService: JAMFServiceProtocol {
    private let baseURL: URL
    private let token: String
    private let session: URLSession
    
    init(baseURL: URL, token: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
    }
    
    // MARK: - Profile Operations
    
    func uploadProfile(name: String, xmlData: Data) async throws {
        let endpoint = "JSSResource/osxconfigurationprofiles/id/0"
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0
        
        let encodedPayload = xmlData.base64EncodedString()
        let xmlBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <os_x_configuration_profile>
          <general>
            <name>\(name)</name>
            <distribution_method>Install Automatically</distribution_method>
            <payloads>\(encodedPayload)</payloads>
          </general>
        </os_x_configuration_profile>
        """
        
        request.httpBody = xmlBody.data(using: .utf8)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        guard (200...201).contains(httpResponse.statusCode) else {
            throw JAMFError.http(httpResponse.statusCode, "Failed to upload profile")
        }
    }
    
    func uploadOrUpdateProfile(name: String, xmlData: Data) async throws {
        do {
            try await uploadProfile(name: name, xmlData: xmlData)
        } catch JAMFError.http(let code, _) where code == 409 {
            // Profile already exists, try to update it
            try await updateProfileByName(name, xmlData: xmlData)
        }
    }
    
    func findProfileByName(_ name: String) async throws -> JAMFProfile? {
        let safeName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        let endpoint = "JSSResource/osxconfigurationprofiles/name/\(safeName)"
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            return nil // Profile doesn't exist
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw JAMFError.http(httpResponse.statusCode, errorBody)
        }
        
        // Parse the profile response
        let profile = try JSONDecoder().decode(JAMFProfile.self, from: data)
        return profile
    }
    
    // MARK: - Configuration Profile Retrieval
    
    func getAllConfigurationProfiles() async throws -> [JAMFProfile] {
        let endpoint = "JSSResource/osxconfigurationprofiles"
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw JAMFError.http(httpResponse.statusCode, errorBody)
        }
        
        // Parse the profiles response
        let profilesResponse = try JSONDecoder().decode(JAMFProfilesResponse.self, from: data)
        return profilesResponse.osXConfigurationProfiles ?? []
    }
    
    func getConfigurationProfile(by id: Int) async throws -> JAMFProfile? {
        let endpoint = "JSSResource/osxconfigurationprofiles/id/\(id)"
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            return nil // Profile doesn't exist
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw JAMFError.http(httpResponse.statusCode, errorBody)
        }
        
        // Parse the profile response
        let profile = try JSONDecoder().decode(JAMFProfile.self, from: data)
        return profile
    }
    
    // MARK: - Policy Operations
    
    func getAllPolicies() async throws -> [JAMFPolicy] {
        let endpoint = "JSSResource/policies"
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw JAMFError.http(httpResponse.statusCode, errorBody)
        }
        
        // Parse the policies response
        let policiesResponse = try JSONDecoder().decode(JAMFPoliciesResponse.self, from: data)
        return policiesResponse.policies ?? []
    }
    
    func getPolicy(by id: Int) async throws -> JAMFPolicy? {
        let endpoint = "JSSResource/policies/id/\(id)"
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            return nil // Policy doesn't exist
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw JAMFError.http(httpResponse.statusCode, errorBody)
        }
        
        // Parse the policy response
        let policy = try JSONDecoder().decode(JAMFPolicy.self, from: data)
        return policy
    }
    
    func getPolicy(by name: String) async throws -> JAMFPolicy? {
        let safeName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        let endpoint = "JSSResource/policies/name/\(safeName)"
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            return nil // Policy doesn't exist
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw JAMFError.http(httpResponse.statusCode, errorBody)
        }
        
        // Parse the policy response
        let policy = try JSONDecoder().decode(JAMFPolicy.self, from: data)
        return policy
    }
    
    // MARK: - Connection Testing
    
    func testConnection() async throws -> Bool {
        let endpoint = "api/v1/ping"
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }
    
    // MARK: - Private Methods
    
    private func updateProfileByName(_ name: String, xmlData: Data) async throws {
        let safeName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        let endpoint = "JSSResource/osxconfigurationprofiles/name/\(safeName)"
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0
        
        let encodedPayload = xmlData.base64EncodedString()
        let xmlBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <os_x_configuration_profile>
          <general>
            <name>\(name)</name>
            <distribution_method>Install Automatically</distribution_method>
            <payloads>\(encodedPayload)</payloads>
          </general>
        </os_x_configuration_profile>
        """
        
        request.httpBody = xmlBody.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        guard (200...201).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw JAMFError.http(httpResponse.statusCode, errorBody)
        }
    }
}

// MARK: - JAMF Response Models
struct JAMFProfilesResponse: Codable {
    let osXConfigurationProfiles: [JAMFProfile]?
    
    enum CodingKeys: String, CodingKey {
        case osXConfigurationProfiles = "os_x_configuration_profiles"
    }
}

struct JAMFPoliciesResponse: Codable {
    let policies: [JAMFPolicy]?
}

// MARK: - JAMF Errors
enum JAMFError: LocalizedError, Equatable {
    case http(Int, String?)
    case invalidResponse
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .http(let code, let message):
            if let message = message {
                return "JAMF returned HTTP \(code): \(message)"
            } else {
                return "JAMF returned HTTP \(code)"
            }
        case .invalidResponse:
            return "Invalid response from JAMF server"
        case .notAuthenticated:
            return "Not authenticated with JAMF"
        }
    }
}
