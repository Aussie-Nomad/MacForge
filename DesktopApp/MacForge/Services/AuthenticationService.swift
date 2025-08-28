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
    
    // Callback for storing tokens in UserSettings
    var onTokenReceived: ((String, Date?) -> Void)?
    
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
        
        // Notify callback about the new token
        onTokenReceived?(token, nil) // OAuth tokens typically don't have expiry
        
        return token
    }
    
    /// Authenticate using Basic authentication with SSO support
    func authenticateBasic(username: String, password: String, serverURL: String) async throws -> String {
        guard let baseURL = normalizeServerURL(serverURL) else {
            throw AuthenticationError.invalidServerURL
        }
        
        // Test connection first
        try await validateConnection(to: serverURL)
        
        // Try multiple authentication methods for JAMF Pro
        do {
            // First try modern JAMF Pro authentication
            let token = try await authenticateWithJAMFPro(
                baseURL: baseURL,
                username: username,
                password: password
            )
            
            await MainActor.run {
                self.currentToken = token
                self.isAuthenticated = true
            }
            
            onTokenReceived?(token, nil)
            return token
            
        } catch {
            // Fall back to basic authentication
            let token = try await authenticateWithBasic(
                baseURL: baseURL,
                username: username,
                password: password
            )
            
            await MainActor.run {
                self.currentToken = token
                self.isAuthenticated = true
            }
            
            onTokenReceived?(token, nil)
            return token
        }
    }
    
    /// Authenticate using SSO (Single Sign-On) for enterprise environments
    func authenticateSSO(serverURL: String) async throws -> String {
        guard let baseURL = normalizeServerURL(serverURL) else {
            throw AuthenticationError.invalidServerURL
        }
        
        // Test connection first
        try await validateConnection(to: serverURL)
        
        // For SSO, we need to handle different authentication flows
        // This is a placeholder for future SSO implementation
        // For now, we'll try to detect SSO endpoints and provide guidance
        
        let ssoEndpoints = [
            "api/v1/sso/auth",
            "api/sso/auth",
            "api/v1/oauth/authorize",
            "api/oauth/authorize"
        ]
        
        for endpoint in ssoEndpoints {
            do {
                let url = baseURL.appendingPathComponent(endpoint)
                let (_, response) = try await session.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 || httpResponse.statusCode == 302 {
                    // SSO endpoint found, but we need user interaction
                    throw AuthenticationError.ssoAuthenticationRequired("SSO authentication detected. Please authenticate through your browser and return to MacForge.")
                }
            } catch {
                continue
            }
        }
        
        throw AuthenticationError.authenticationFailed("SSO authentication not available. Please use username/password authentication.")
    }
    
    /// Validate server connection
    func validateConnection(to serverURL: String) async throws {
        guard let baseURL = normalizeServerURL(serverURL) else {
            throw AuthenticationError.invalidServerURL
        }
        
        do {
            // Test basic connectivity with multiple endpoints
            let isReachable = try await testMultipleEndpoints(baseURL)
            
            guard isReachable else {
                throw AuthenticationError.serverUnreachable
            }
            
        } catch {
            throw AuthenticationError.networkError(error.localizedDescription)
        }
    }
    
    /// Logout and clear authentication state
    func logout() {
        currentToken = nil
        isAuthenticated = false
    }
    
    /// Debug method to test JAMF Pro endpoints and see what's available
    func debugJAMFEndpoints(serverURL: String) async -> String {
        guard let baseURL = normalizeServerURL(serverURL) else {
            return "❌ Invalid server URL: \(serverURL)"
        }
        
        var debugInfo = "🔍 JAMF Pro Endpoint Debug for: \(serverURL)\n\n"
        
        let testEndpoints = [
            "api/v1/ping",
            "api/ping", 
            "api/v1/health",
            "api/health",
            "api/v1/version",
            "api/version",
            "api/v1/auth/token",
            "api/auth/token",
            "api/v1/oauth/token",
            "api/oauth/token"
        ]
        
        for endpoint in testEndpoints {
            do {
                let url = baseURL.appendingPathComponent(endpoint)
                let (data, response) = try await session.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    let status = httpResponse.statusCode
                    let statusIcon = status == 200 ? "✅" : status < 400 ? "⚠️" : "❌"
                    
                    debugInfo += "\(statusIcon) \(endpoint): HTTP \(status)\n"
                    
                    if status == 200, let responseString = String(data: data, encoding: .utf8) {
                        debugInfo += "   Response: \(responseString.prefix(100))...\n"
                    }
                }
            } catch {
                debugInfo += "❌ \(endpoint): \(error.localizedDescription)\n"
            }
        }
        
        return debugInfo
    }
    
    // MARK: - Private Implementation
    
    /// Modern JAMF Pro authentication supporting SSO and modern auth flows
    private func authenticateWithJAMFPro(baseURL: URL, username: String, password: String) async throws -> String {
        // Try multiple JAMF Pro authentication endpoints
        let endpoints = [
            "api/v1/auth/token",           // Modern JAMF Pro
            "api/oauth/token",             // OAuth endpoint
            "api/v1/oauth/token",          // Alternative OAuth
            "api/auth/token"               // Legacy endpoint
        ]
        
        var lastError: Error?
        
        for endpoint in endpoints {
            do {
                let url = baseURL.appendingPathComponent(endpoint)
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                
                // Try different authentication methods
                let authMethods = [
                    ("grant_type", "password", "username", username, "password", password),
                    ("grant_type", "client_credentials", "client_id", username, "client_secret", password),
                    ("grant_type", "password", "username", username, "password", password)
                ]
                
                for (grantType, grantValue, userField, userValue, passField, passValue) in authMethods {
                    do {
                        let body = "\(grantType)=\(grantValue)&\(userField)=\(userValue)&\(passField)=\(passValue)"
                        request.httpBody = body.data(using: .utf8)
                        
                        let (data, response) = try await session.data(for: request)
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            continue
                        }
                        
                        if httpResponse.statusCode == 200 {
                            // Try to decode the response
                            if let tokenResponse = try? JSONDecoder().decode(OAuthTokenResponse.self, from: data) {
                                return tokenResponse.access_token
                            }
                            
                            // Try alternative response format
                            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let token = json["access_token"] as? String {
                                return token
                            }
                        }
                    } catch {
                        lastError = error
                        continue
                    }
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        throw AuthenticationError.authenticationFailed("All JAMF Pro authentication methods failed: \(lastError?.localizedDescription ?? "Unknown error")")
    }
    
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
        // Try multiple JAMF Pro authentication endpoints
        let endpoints = [
            "api/v1/auth/token",           // Modern JAMF Pro
            "api/auth/token",              // Legacy JAMF Pro
            "api/v1/oauth/token",          // Alternative OAuth
            "api/oauth/token"              // Standard OAuth
        ]
        
        var lastError: Error?
        
        for endpoint in endpoints {
            do {
                let token = try await performBasicAuthRequest(
                    baseURL: baseURL,
                    endpoint: endpoint,
                    username: username,
                    password: password
                )
                return token
            } catch {
                lastError = error
                continue
            }
        }
        
        throw AuthenticationError.authenticationFailed("All basic authentication endpoints failed: \(lastError?.localizedDescription ?? "Unknown error")")
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
        
        // For JAMF Pro, we need to send the credentials in the request body
        let body = "username=\(username)&password=\(password)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthenticationError.networkError("Invalid response")
        }
        
        // Log the response for debugging
        print("🔐 Auth Response - Status: \(httpResponse.statusCode), Endpoint: \(endpoint)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔐 Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                throw AuthenticationError.authenticationFailed("HTTP \(httpResponse.statusCode): \(errorString)")
            } else {
                throw AuthenticationError.authenticationFailed("HTTP \(httpResponse.statusCode)")
            }
        }
        
        // Try multiple response formats
        do {
            // First try standard OAuth response
            let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
            return tokenResponse.access_token
        } catch {
            // Try alternative response formats
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Look for token in various possible fields
                if let token = json["access_token"] as? String {
                    return token
                }
                if let token = json["token"] as? String {
                    return token
                }
                if let token = json["auth_token"] as? String {
                    return token
                }
                if let token = json["jamf_token"] as? String {
                    return token
                }
                
                // Log the JSON structure for debugging
                print("🔐 JSON Response Structure: \(json)")
            }
            
            // If we can't parse the response, throw a detailed error
            throw AuthenticationError.authenticationFailed("Could not parse authentication response. Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
        }
    }
    
    /// Test multiple endpoints to determine server reachability
    private func testMultipleEndpoints(_ baseURL: URL) async throws -> Bool {
        let endpoints = [
            "api/v1/ping",           // Modern JAMF Pro
            "api/ping",              // Legacy JAMF Pro
            "api/v1/health",         // Health check
            "api/health",            // Alternative health check
            "api/v1/version",        // Version info
            "api/version"            // Legacy version
        ]
        
        for endpoint in endpoints {
            do {
                let url = baseURL.appendingPathComponent(endpoint)
                let (_, response) = try await session.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    return true
                }
            } catch {
                continue
            }
        }
        
        // If no standard endpoints work, try a simple HEAD request to the base URL
        do {
            var request = URLRequest(url: baseURL)
            request.httpMethod = "HEAD"
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode < 500 { // Any response < 500 means server is reachable
                return true
            }
        } catch {
            // Continue to next test
        }
        
        return false
    }
    
    private func pingServer(_ baseURL: URL) async throws {
        let pingURL = baseURL.appendingPathComponent("api/v1/ping")
        let (_, response) = try await session.data(from: pingURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthenticationError.serverUnreachable
        }
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
    case ssoAuthenticationRequired(String)
    
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
        case .ssoAuthenticationRequired(let message):
            return message
        }
    }
}
