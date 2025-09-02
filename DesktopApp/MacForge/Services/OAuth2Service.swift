//
//  OAuth2Service.swift
//  MacForge
//
//  OAuth 2.0 with PKCE implementation for secure authentication.
//  Provides enhanced security over basic authentication methods.
//

import Foundation
import CryptoKit

// MARK: - OAuth 2.0 Service
final class OAuth2Service {
    static let shared = OAuth2Service()
    
    private let session: URLSession
    private let validationService = ValidationService.shared
    private let secureLogger = SecureLogger.shared
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - PKCE Implementation
    
    /// Generate PKCE code verifier
    func generateCodeVerifier() -> String {
        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return data.base64URLEncodedString()
    }
    
    /// Generate PKCE code challenge from verifier
    func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncodedString()
    }
    
    /// Generate secure state parameter
    func generateState() -> String {
        let data = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        return data.base64URLEncodedString()
    }
    
    // MARK: - OAuth 2.0 Flow
    
    /// Start OAuth 2.0 authorization flow with PKCE
    func startAuthorizationFlow(
        clientID: String,
        redirectURI: String,
        serverURL: String,
        scopes: [String] = ["read", "write"]
    ) async throws -> OAuth2AuthorizationResult {
        
        // Validate inputs
        let validatedClientID = try validationService.validateClientID(clientID)
        let validatedServerURL = try validationService.validateServerURL(serverURL)
        let validatedRedirectURI = try validationService.validateServerURL(redirectURI)
        
        // Check rate limiting
        try validationService.checkRateLimit(for: "oauth_flow_\(validatedServerURL.host ?? "unknown")")
        
        // Generate PKCE parameters
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let state = generateState()
        
        // Build authorization URL
        guard let baseURL = URL(string: validatedServerURL.absoluteString) else {
            throw OAuth2Error.invalidServerURL
        }
        
        let authURL = buildAuthorizationURL(
            baseURL: baseURL,
            clientID: validatedClientID,
            redirectURI: validatedRedirectURI.absoluteString,
            codeChallenge: codeChallenge,
            state: state,
            scopes: scopes
        )
        
        secureLogger.log("Starting OAuth 2.0 authorization flow", level: .info)
        
        return OAuth2AuthorizationResult(
            authorizationURL: authURL,
            codeVerifier: codeVerifier,
            state: state,
            redirectURI: validatedRedirectURI.absoluteString
        )
    }
    
    /// Exchange authorization code for access token
    func exchangeCodeForToken(
        authorizationCode: String,
        codeVerifier: String,
        clientID: String,
        redirectURI: String,
        serverURL: String
    ) async throws -> OAuth2TokenResponse {
        
        // Validate inputs
        let validatedClientID = try validationService.validateClientID(clientID)
        let validatedServerURL = try validationService.validateServerURL(serverURL)
        let validatedRedirectURI = try validationService.validateServerURL(redirectURI)
        
        // Check rate limiting
        try validationService.checkRateLimit(for: "oauth_token_\(validatedServerURL.host ?? "unknown")")
        
        guard let baseURL = URL(string: validatedServerURL.absoluteString) else {
            throw OAuth2Error.invalidServerURL
        }
        
        let tokenURL = baseURL.appendingPathComponent("api/oauth/token")
        
        // Build token request
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "authorization_code",
            "code": authorizationCode,
            "redirect_uri": validatedRedirectURI.absoluteString,
            "client_id": validatedClientID,
            "code_verifier": codeVerifier
        ]
        
        request.httpBody = buildFormData(from: parameters)
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuth2Error.invalidResponse
        }
        
        secureLogger.logNetworkRequest(
            url: tokenURL.absoluteString,
            method: "POST",
            statusCode: httpResponse.statusCode
        )
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                throw OAuth2Error.tokenExchangeFailed("HTTP \(httpResponse.statusCode): \(errorString)")
            }
            throw OAuth2Error.tokenExchangeFailed("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse token response
        let tokenResponse = try JSONDecoder().decode(OAuth2TokenResponse.self, from: data)
        
        secureLogger.log("OAuth 2.0 token exchange successful", level: .info)
        
        return tokenResponse
    }
    
    /// Refresh access token using refresh token
    func refreshAccessToken(
        refreshToken: String,
        clientID: String,
        serverURL: String
    ) async throws -> OAuth2TokenResponse {
        
        // Validate inputs
        let validatedClientID = try validationService.validateClientID(clientID)
        let validatedServerURL = try validationService.validateServerURL(serverURL)
        
        // Check rate limiting
        try validationService.checkRateLimit(for: "oauth_refresh_\(validatedServerURL.host ?? "unknown")")
        
        guard let baseURL = URL(string: validatedServerURL.absoluteString) else {
            throw OAuth2Error.invalidServerURL
        }
        
        let tokenURL = baseURL.appendingPathComponent("api/oauth/token")
        
        // Build refresh request
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": validatedClientID
        ]
        
        request.httpBody = buildFormData(from: parameters)
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuth2Error.invalidResponse
        }
        
        secureLogger.logNetworkRequest(
            url: tokenURL.absoluteString,
            method: "POST",
            statusCode: httpResponse.statusCode
        )
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                throw OAuth2Error.tokenRefreshFailed("HTTP \(httpResponse.statusCode): \(errorString)")
            }
            throw OAuth2Error.tokenRefreshFailed("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse token response
        let tokenResponse = try JSONDecoder().decode(OAuth2TokenResponse.self, from: data)
        
        secureLogger.log("OAuth 2.0 token refresh successful", level: .info)
        
        return tokenResponse
    }
    
    // MARK: - Helper Methods
    
    private func buildAuthorizationURL(
        baseURL: URL,
        clientID: String,
        redirectURI: String,
        codeChallenge: String,
        state: String,
        scopes: [String]
    ) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/oauth/authorize"), resolvingAgainstBaseURL: false)!
        
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " "))
        ]
        
        return components.url!
    }
    
    private func buildFormData(from parameters: [String: String]) -> Data {
        let formData = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        return formData.data(using: .utf8)!
    }
}

// MARK: - Supporting Types

struct OAuth2AuthorizationResult: Equatable {
    let authorizationURL: URL
    let codeVerifier: String
    let state: String
    let redirectURI: String
}

struct OAuth2TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int?
    let refreshToken: String?
    let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
    
    var expiresAt: Date? {
        guard let expiresIn = expiresIn else { return nil }
        return Date().addingTimeInterval(TimeInterval(expiresIn))
    }
}

// MARK: - OAuth 2.0 Errors

enum OAuth2Error: LocalizedError {
    case invalidServerURL
    case invalidResponse
    case tokenExchangeFailed(String)
    case tokenRefreshFailed(String)
    case invalidAuthorizationCode
    case invalidState
    case unsupportedGrantType
    
    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            return "Invalid server URL for OAuth 2.0"
        case .invalidResponse:
            return "Invalid response from OAuth 2.0 server"
        case .tokenExchangeFailed(let message):
            return "Token exchange failed: \(message)"
        case .tokenRefreshFailed(let message):
            return "Token refresh failed: \(message)"
        case .invalidAuthorizationCode:
            return "Invalid authorization code"
        case .invalidState:
            return "Invalid state parameter"
        case .unsupportedGrantType:
            return "Unsupported grant type"
        }
    }
}

// MARK: - Base64 URL Encoding Extension

extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
