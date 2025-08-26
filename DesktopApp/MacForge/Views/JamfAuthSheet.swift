//
//  JamfAuthSheet.swift
//  MacForge
//
//  Authentication sheet for JAMF Pro login and configuration.
//  Provides a clean interface for entering JAMF server details and credentials.
//

import SwiftUI

struct JamfAuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthenticationViewModel()
    
    let onComplete: (JamfAuthResult) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Connect to JAMF Pro")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your JAMF Pro server details and credentials to connect")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Server URL
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server URL")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    TextField("https://your-jamf-instance.com", text: $viewModel.serverURL)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                }
                
                // Authentication Mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("Authentication Method")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Picker("Authentication Method", selection: $viewModel.authenticationMode) {
                        ForEach(AuthenticationMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(viewModel.authenticationMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Credentials
                Group {
                    switch viewModel.authenticationMode {
                    case .oauth:
                        OAuthCredentialsView(viewModel: viewModel)
                    case .basic:
                        BasicCredentialsView(viewModel: viewModel)
                    }
                }
                
                // Status and Error
                VStack(spacing: 8) {
                    // Connection Status
                    HStack {
                        Circle()
                            .fill(viewModel.statusColor)
                            .frame(width: 8, height: 8)
                        Text(viewModel.statusText)
                            .font(.caption)
                            .foregroundStyle(viewModel.statusColor)
                    }
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .contentShape(Rectangle())
                    
                    Spacer()
                    
                    Button(action: connect) {
                        if viewModel.isConnecting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            Text("Connect")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canConnect || viewModel.isConnecting)
                    .contentShape(Rectangle())
                }
            }
            .padding(24)
            .navigationTitle("JAMF Authentication")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onChange(of: viewModel.serverURL) { _, _ in
            viewModel.reset()
        }
        .onChange(of: viewModel.authenticationMode) { _, _ in
            viewModel.reset()
        }
    }
    
    // MARK: - Private Methods
    
    private func connect() {
        Task {
            let success = await viewModel.connect()
            
            if success {
                // Convert to JamfAuthResult format for backward compatibility
                let jamfResult: JamfAuthResult
                if viewModel.authenticationMode == .oauth {
                    jamfResult = .success(
                        URL(string: viewModel.serverURL) ?? URL(string: "https://example.com")!,
                        viewModel.oauthClientID,
                        viewModel.oauthClientSecret
                    )
                } else {
                    jamfResult = .success(
                        URL(string: viewModel.serverURL) ?? URL(string: "https://example.com")!,
                        viewModel.basicUsername,
                        viewModel.basicPassword
                    )
                }
                
                onComplete(jamfResult)
                dismiss()
            }
        }
    }
}

// MARK: - OAuth Credentials View
struct OAuthCredentialsView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Client ID")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                TextField("Your OAuth client ID", text: $viewModel.oauthClientID)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Client Secret")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                SecureField("Your OAuth client secret", text: $viewModel.oauthClientSecret)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }
        }
    }
}

// MARK: - Basic Credentials View
struct BasicCredentialsView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                TextField("Your JAMF username", text: $viewModel.basicUsername)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                SecureField("Your JAMF password", text: $viewModel.basicPassword)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }
        }
    }
}

// MARK: - Jamf Auth Result (Backward Compatibility)
enum JamfAuthResult {
    case success(URL, String, String)
    case failure(Error)
    case cancelled
}

#Preview {
    JamfAuthSheet { _ in }
}
