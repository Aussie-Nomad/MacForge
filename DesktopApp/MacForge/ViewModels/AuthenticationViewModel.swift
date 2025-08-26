//
//  AuthenticationViewModel.swift
//  MacForge
//
//  ViewModel for managing authentication UI state and user interactions.
//  Coordinates between the authentication service and UI components.
//

import SwiftUI
import Foundation

// MARK: - Authentication View Model
@MainActor
final class AuthenticationViewModel: ObservableObject {
    // MARK: - Dependencies
    private let authenticationService: JAMFAuthenticationService
    
    // MARK: - Published Properties
    @Published var serverURL = ""
    @Published var authenticationMode: AuthenticationMode = .oauth
    @Published var oauthClientID = ""
    @Published var oauthClientSecret = ""
    @Published var basicUsername = ""
    @Published var basicPassword = ""
    
    @Published var isConnecting = false
    @Published var errorMessage: String?
    @Published var connectionStatus: ConnectionStatus = .notStarted
    @Published var isAuthenticated = false
    @Published var currentToken: String?
    
    // MARK: - Initialization
    init(authenticationService: JAMFAuthenticationService = JAMFAuthenticationService()) {
        self.authenticationService = authenticationService
    }
    
    // MARK: - Public Methods
    
    func connect() async -> Bool {
        guard canConnect else {
            errorMessage = "Please fill in all required fields"
            return false
        }
        
        isConnecting = true
        errorMessage = nil
        connectionStatus = .connecting
        
        defer {
            isConnecting = false
        }
        
        do {
            // First validate connection
            try await authenticationService.validateConnection(to: serverURL)
            connectionStatus = .connected
            
            // Attempt authentication
            let token: String
            switch authenticationMode {
            case .oauth:
                token = try await authenticationService.authenticateOAuth(
                    clientID: oauthClientID,
                    clientSecret: oauthClientSecret,
                    serverURL: serverURL
                )
            case .basic:
                token = try await authenticationService.authenticateBasic(
                    username: basicUsername,
                    password: basicPassword,
                    serverURL: serverURL
                )
            }
            
            // Success
            currentToken = token
            isAuthenticated = true
            connectionStatus = .authenticated
            return true
            
        } catch {
            connectionStatus = .failed
            if let authError = error as? AuthenticationError {
                errorMessage = authError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func reset() {
        serverURL = ""
        oauthClientID = ""
        oauthClientSecret = ""
        basicUsername = ""
        basicPassword = ""
        errorMessage = nil
        connectionStatus = .notStarted
        isAuthenticated = false
        currentToken = nil
    }
    
    func logout() {
        authenticationService.logout()
        isAuthenticated = false
        currentToken = nil
        connectionStatus = .notStarted
    }
    
    // MARK: - Computed Properties
    
    var canConnect: Bool {
        guard !serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        switch authenticationMode {
        case .oauth:
            return !oauthClientID.isEmpty && !oauthClientSecret.isEmpty
        case .basic:
            return !basicUsername.isEmpty && !basicPassword.isEmpty
        }
    }
    
    var statusColor: Color {
        switch connectionStatus {
        case .notStarted:
            return .secondary
        case .connecting:
            return .orange
        case .connected:
            return .blue
        case .authenticated:
            return .green
        case .failed:
            return .red
        }
    }
    
    var statusText: String {
        switch connectionStatus {
        case .notStarted:
            return "Ready to connect"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected to server"
        case .authenticated:
            return "Authentication successful"
        case .failed:
            return "Connection failed"
        }
    }
}

// MARK: - Authentication Mode
enum AuthenticationMode: String, CaseIterable {
    case oauth = "OAuth"
    case basic = "Basic"
    
    var displayName: String {
        switch self {
        case .oauth:
            return "Client ID + Secret"
        case .basic:
            return "Username + Password"
        }
    }
    
    var description: String {
        switch self {
        case .oauth:
            return "Use OAuth client credentials for API access"
        case .basic:
            return "Use username and password for authentication"
        }
    }
}

// MARK: - Connection Status
enum ConnectionStatus {
    case notStarted
    case connecting
    case connected
    case authenticated
    case failed
}
