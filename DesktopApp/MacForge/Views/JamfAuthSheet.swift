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
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Connect to JAMF Pro")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your JAMF Pro server details and credentials to connect")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Server URL
                VStack(alignment: .leading, spacing: 12) {
                    Text("Server URL")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    TextField("https://your-jamf-instance.com", text: $viewModel.serverURL)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .frame(height: 40)
                }
                
                // Authentication Mode
                VStack(alignment: .leading, spacing: 12) {
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
                        .font(.body)
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
                .frame(maxWidth: .infinity)
                
                // Status and Error
                VStack(spacing: 12) {
                    // Connection Status
                    HStack {
                        Circle()
                            .fill(viewModel.statusColor)
                            .frame(width: 12, height: 12)
                        Text(viewModel.statusText)
                            .font(.body)
                            .foregroundStyle(viewModel.statusColor)
                    }
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.body)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .contentShape(Rectangle())
                    .frame(height: 44)
                    
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
                    .frame(height: 44)
                }
            }
            .padding(32)
            .frame(minWidth: 500, minHeight: 600)
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
                        baseURL: URL(string: viewModel.serverURL) ?? URL(string: "https://example.com")!,
                        clientID: viewModel.oauthClientID,
                        clientSecret: viewModel.oauthClientSecret
                    )
                } else {
                    jamfResult = .success(
                        baseURL: URL(string: viewModel.serverURL) ?? URL(string: "https://example.com")!,
                        clientID: viewModel.basicUsername,
                        clientSecret: viewModel.basicPassword
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
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Client ID")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                TextField("Your OAuth client ID", text: $viewModel.oauthClientID)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .frame(height: 40)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Client Secret")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                SecureField("Your OAuth client secret", text: $viewModel.oauthClientSecret)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .frame(height: 40)
            }
        }
    }
}

// MARK: - Basic Credentials View
struct BasicCredentialsView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Username")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                TextField("Your JAMF username", text: $viewModel.basicUsername)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .frame(height: 40)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Password")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                SecureField("Your JAMF password", text: $viewModel.basicPassword)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .frame(height: 40)
            }
        }
    }
}

// MARK: - Jamf Auth Result (Backward Compatibility)
// Note: JamfAuthResult is now defined in Types.swift for consistency

#Preview {
    JamfAuthSheet { _ in }
}
