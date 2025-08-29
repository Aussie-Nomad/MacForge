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
    func uploadProfile(name: String, xmlData: Data) async throws
    func uploadOrUpdateProfile(name: String, xmlData: Data) async throws
    func findProfileByName(_ name: String) async throws -> JAMFProfile?
}

// MARK: - JAMF Profile Model
struct JAMFProfile: Codable {
    let id: Int
    let name: String
    let distributionMethod: String?
    let payloads: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case distributionMethod = "distribution_method"
        case payloads
    }
}

// MARK: - JAMF Profiles Response (v1 API)
struct JAMFProfilesResponse: Codable {
    let totalCount: Int
    let results: [JAMFProfile]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "totalCount"
        case results
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
