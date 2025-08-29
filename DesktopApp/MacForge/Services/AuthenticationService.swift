//
//  AuthenticationService.swift
//  MacForge
//
//  JAMF Pro authentication service for MacForge.
//  Handles OAuth and Basic authentication with simplified, focused implementation.

import Foundation
import SwiftUI

// MARK: - JAMF Authentication Service
final class JAMFAuthenticationService: ObservableObject {
    private let session: URLSession
    @Published var isAuthenticated = false
    @Published var currentToken: String?
    
    // MARK: - Callback Properties
    var onTokenReceived: ((String, Date) -> Void)?
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Authentication Methods
    
    /// Authenticate using OAuth client credentials
    func authenticateOAuth(clientID: String, clientSecret: String, serverURL: String) async throws -> String {
        guard let baseURL = normalizeServerURL(serverURL) else {
            throw AuthenticationError.invalidServerURL
        }
        
        // Test connection first
        try await validateConnection(to: serverURL)
        
        // Attempt OAuth authentication
        let token = try await authenticateWithOAuth(
            baseURL: baseURL,
            clientID: clientID,
            clientSecret: clientSecret
        )
        
        await MainActor.run {
            self.currentToken = token
            self.isAuthenticated = true
        }
        
        // Call the callback if provided
        if let callback = onTokenReceived {
            let expiry = Date().addingTimeInterval(3600) // Default 1 hour expiry
            callback(token, expiry)
        }
        
        return token
    }
    
    /// Authenticate using Basic authentication
    func authenticateBasic(username: String, password: String, serverURL: String) async throws -> String {
        guard let baseURL = normalizeServerURL(serverURL) else {
            throw AuthenticationError.invalidServerURL
        }
        
        // Test connection first
        try await validateConnection(to: serverURL)
        
        // Attempt Basic authentication
        let token = try await authenticateWithBasic(
            baseURL: baseURL,
            username: username,
            password: password
        )
        
        await MainActor.run {
            self.currentToken = token
            self.isAuthenticated = true
        }
        
        // Call the callback if provided
        if let callback = onTokenReceived {
            let expiry = Date().addingTimeInterval(3600) // Default 1 hour expiry
            callback(token, expiry)
        }
        
        return token
    }
    
    /// Validate server connection
    func validateConnection(to serverURL: String) async throws {
        guard let baseURL = normalizeServerURL(serverURL) else {
            throw AuthenticationError.invalidServerURL
        }
        
        do {
            // Test basic connectivity with multiple endpoints
            try await pingServer(baseURL)
            
            // Test auth endpoint accessibility
            let authEndpointReachable = try await testAuthEndpoint(baseURL)
            
            guard authEndpointReachable else {
                throw AuthenticationError.serverUnreachable
            }
        } catch {
            throw AuthenticationError.serverUnreachable
        }
    }
    
    /// Logout and clear authentication state
    func logout() {
        currentToken = nil
        isAuthenticated = false
    }
    
    /// Debug JAMF endpoints to check connectivity and API availability
    func debugJAMFEndpoints(serverURL: String) async -> String {
        guard let baseURL = normalizeServerURL(serverURL) else {
            return "Error: Invalid server URL format"
        }
        
        var debugInfo = "JAMF Server Debug Information\n"
        debugInfo += "===============================\n\n"
        
        // Test basic connectivity
        do {
            try await pingServer(baseURL)
            debugInfo += "✅ Server ping: SUCCESS\n"
        } catch {
            debugInfo += "❌ Server ping: FAILED - \(error.localizedDescription)\n"
        }
        
        // Test auth endpoint
        do {
            let authReachable = try await testAuthEndpoint(baseURL)
            debugInfo += authReachable ? "✅ Auth endpoint: REACHABLE\n" : "❌ Auth endpoint: NOT REACHABLE\n"
        } catch {
            debugInfo += "❌ Auth endpoint test: ERROR - \(error.localizedDescription)\n"
        }
        
        // Test common JAMF endpoints
        let commonEndpoints = [
            "JSSResource/computers",
            "JSSResource/osxconfigurationprofiles",
            "JSSResource/accounts"
        ]
        
        for endpoint in commonEndpoints {
            do {
                let url = baseURL.appendingPathComponent(endpoint)
                let (_, response) = try await session.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    let status = httpResponse.statusCode
                    if status == 200 || status == 401 || status == 403 {
                        debugInfo += "✅ \(endpoint): HTTP \(status)\n"
                    } else {
                        debugInfo += "⚠️ \(endpoint): HTTP \(status)\n"
                    }
                } else {
                    debugInfo += "❌ \(endpoint): Invalid response\n"
                }
            } catch {
                debugInfo += "❌ \(endpoint): \(error.localizedDescription)\n"
            }
        }
        
        debugInfo += "\nDebug completed at: \(Date())\n"
        return debugInfo
    }
    
    // MARK: - Private Implementation
    
    private func authenticateWithOAuth(baseURL: URL, clientID: String, clientSecret: String) async throws -> String {
        let endpoints = ["api/oauth/token", "api/v1/oauth/token"]
        
        for endpoint in endpoints {
            do {
                let token = try await performOAuthRequest(
                    baseURL: baseURL,
                    endpoint: endpoint,
                    clientID: clientID,
                    clientSecret: clientSecret
                )
                return token
            } catch {
                // Continue to next endpoint if this one fails
                continue
            }
        }
        
        throw AuthenticationError.authenticationFailed("All OAuth endpoints failed")
    }
    
    private func authenticateWithBasic(baseURL: URL, username: String, password: String) async throws -> String {
        let endpoint = "api/v1/auth/token"
        
        let token = try await performBasicAuthRequest(
            baseURL: baseURL,
            endpoint: endpoint,
            username: username,
            password: password
        )
        
        return token
    }
    
    private func performOAuthRequest(baseURL: URL, endpoint: String, clientID: String, clientSecret: String) async throws -> String {
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=client_credentials&client_id=\(clientID)&client_secret=\(clientSecret)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthenticationError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AuthenticationError.authenticationFailed("HTTP \(httpResponse.statusCode)")
        }
        
        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        return tokenResponse.access_token
    }
    
    private func performBasicAuthRequest(baseURL: URL, endpoint: String, username: String, password: String) async throws -> String {
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(username):\(password)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthenticationError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AuthenticationError.authenticationFailed("HTTP \(httpResponse.statusCode)")
        }
        
        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        return tokenResponse.access_token
    }
    
    private func pingServer(_ baseURL: URL) async throws {
        // Try multiple ping endpoints for JAMF Pro
        let pingEndpoints = [
            "api/v1/ping",           // Modern JAMF Pro v1 API
            "JSSResource/accounts",  // Classic JAMF Pro
            "api/ping"               // Alternative ping endpoint
        ]
        
        var lastError: Error?
        
        for endpoint in pingEndpoints {
            do {
                let pingURL = baseURL.appendingPathComponent(endpoint)
                
                var request = URLRequest(url: pingURL)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.timeoutInterval = 10.0
                
                let (_, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continue
                }
                
                // Accept 200 (OK), 401 (Unauthorized), or 403 (Forbidden) as successful connections
                // 401/403 mean the server is reachable but requires authentication
                if [200, 401, 403].contains(httpResponse.statusCode) {
                    return // Server is reachable
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        // If we get here, none of the ping endpoints worked
        throw AuthenticationError.serverUnreachable
    }
    
    private func testAuthEndpoint(_ baseURL: URL) async throws -> Bool {
        let authURL = baseURL.appendingPathComponent("api/oauth/token")
        
        do {
            let (_, response) = try await session.data(from: authURL)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode != 404
        } catch {
            return false
        }
    }
    
    private func normalizeServerURL(_ urlString: String) -> URL? {
        var urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        return URL(string: urlString)
    }
}

// MARK: - Supporting Types

struct OAuthTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int?
}

enum AuthenticationError: LocalizedError, Equatable {
    case invalidServerURL
    case networkError(String)
    case authenticationFailed(String)
    case serverUnreachable
    
    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            return "Invalid server URL format"
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .serverUnreachable:
            return "Server is unreachable"
        }
    }
}
