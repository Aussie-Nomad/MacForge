//
//  LoginViews.swift
//  MacForge
//
//  Created by Danny Mac on 15/08/2025.
//
// V3

import SwiftUI

// MARK: - Jamf auth result wrapper used by sheets
enum JamfAuthResult {
    case success(JamfClient)
    case failure(Error)
    case cancelled
}

// MARK: - Jamf Authentication Sheet
/// Modal sheet for authenticating to Jamf. Supports client ID/secret today;
/// username/password path is stubbed (Jamf’s modern API prefers OAuth clients).
struct JamfAuthSheet: View {
    @Environment(\.dismiss) private var dismiss

    // User-entered values
    @State private var server = ""
    @State private var mode: Int = 0 // 0 = ClientID/Secret, 1 = Username/Password
    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var username = ""
    @State private var password = ""

    @State private var errorMessage: String?
    let onComplete: (JamfAuthResult) -> Void

    // Build a proper Jamf base URL from common user inputs.
    private func connectURL() -> URL? {
        let raw = server.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        // Prefer client utility to normalize the base URL robustly
        if let url = JamfClient.normalizeBaseURL(from: raw) { return url }
        // Fallback minimal handling
        if raw.lowercased().hasPrefix("http") { return URL(string: raw) }
        return URL(string: "https://\(raw)")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Server field
                ThemedField(title: "Jamf Server",
                            text: $server,
                            placeholder: "zappi or zappi.jamfcloud.com")

                // Auth method selector
                Picker("Method", selection: $mode) {
                    Text("Client ID + Secret").tag(0)
                    Text("Username + Password").tag(1)
                }
                // ...existing code...
                private func connect() {
                    guard let base = connectURL() else {
                        errorMessage = "Please enter a valid Jamf server (e.g. zappi or zappi.jamfcloud.com)."
                        return
                    }

                    let client = JamfClient(baseURL: base)

                    Task {
                        do {
                            // Test connection first
                            let testResult = try await client.testConnection()
                            print("🔍 Connection test: \(testResult)")

                            // Then try authentication
                            switch mode {
                            case 0:
                                try await client.authenticate(clientID: clientID, clientSecret: clientSecret)
                            default:
                                try await client.authenticateBasic(username: username, password: password)
                            }

                            await MainActor.run {
                                errorMessage = nil
                                onComplete(.success(client))
                                dismiss()
                            }

                        } catch let JamfClient.JamfError.http(code, message) {
                            await MainActor.run {
                                switch code {
                                case 400:
                                    errorMessage = "Bad request. Check your credentials format."
                                case 401:
                                    errorMessage = "Authentication failed. Verify your credentials."
                                case 403:
                                    errorMessage = "Access denied. Check API permissions."
                                case 404:
                                    errorMessage = "API endpoint not found. Verify server URL."
                                case 500:
                                    errorMessage = "Jamf server error. Try again later."
                                default:
                                    errorMessage = "Jamf returned HTTP \(code)\(message != nil ? ": \(message!)" : "")"
                                }
                            }
                        } catch let urlError as URLError {
                            await MainActor.run {
                                switch urlError.code {
                                case .cannotFindHost:
                                    errorMessage = "Cannot find server. Check the hostname: \(base.host ?? "unknown")"
                                case .notConnectedToInternet:
                                    errorMessage = "No internet connection."
                                case .timedOut:
                                    errorMessage = "Connection timed out. Check firewall/VPN."
                                case .secureConnectionFailed:
                                    errorMessage = "SSL/TLS connection failed. Check certificates."
                                default:
                                    errorMessage = "Network error: \(urlError.localizedDescription)"
                                }
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = "Unexpected error: \(error.localizedDescription)"
                            }
                        }
                    }
                }
                        errorMessage = uerr.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Jamf Login View (inline)
// Legacy inline version used in some flows; emits a simple onConnect callback.
struct JamfLoginView: View {
    @State private var serverURL: String = ""
    @State private var clientID: String = ""
    @State private var clientSecret: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var useClientAuth: Bool = true

    /// Called with three strings. For client auth: (serverURL, clientID, clientSecret)
    /// For username/password: (serverURL, username, password)
    var onConnect: (String, String, String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Server URL
            ThemedField(title: "Server URL", text: $serverURL)

            // Auth toggle
            Picker("Authentication Method", selection: $useClientAuth) {
                Text("Client ID + Secret").tag(true)
                Text("Username + Password").tag(false)
            }
            .pickerStyle(.segmented)

            // Credentials
            if useClientAuth {
                ThemedField(title: "Client ID", text: $clientID)
                ThemedField(title: "Client Secret", text: $clientSecret, secure: true)
            } else {
                ThemedField(title: "Username", text: $username)
                ThemedField(title: "Password", text: $password, secure: true)
            }

            // Action
            Button("Connect") {
                if useClientAuth {
                    onConnect(serverURL, clientID, clientSecret)
                } else {
                    onConnect(serverURL, username, password)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Microsoft Intune Login
struct IntuneLoginView: View {
    var onBack: () -> Void

    @State private var tenantId = ""
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var isConnecting = false
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                LcarsHeader(title: "Microsoft Intune Login")

                Text("API CREDENTIALS REQUIRED")
                    .font(.caption)
                    .foregroundStyle(LcarsTheme.amber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LcarsTheme.amber.opacity(0.2))
                    .cornerRadius(6)

                ThemedField(title: "Tenant ID", text: $tenantId, placeholder: "your-tenant-id")
                ThemedField(title: "Client ID", text: $clientId, placeholder: "application-client-id")
                ThemedField(title: "Client Secret", text: $clientSecret, placeholder: "client-secret", secure: true)

                Text("You'll need to register an app in Azure AD with Microsoft Graph API permissions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                HStack {
                    Button("Back", action: onBack)
                        .buttonStyle(.plain)
                        .lcarsPanel(tint: LcarsTheme.orange.opacity(0.7))
                        .frame(width: 80)

                    Spacer()

                    Button(isConnecting ? "Connecting…" : "Connect") {
                        Task { await connect() }
                    }
                    .disabled(isConnecting || !canConnect)
                    .buttonStyle(LcarsButtonStyle())
                }

                if let errorText {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ERROR").font(.caption).bold()
                        Text(errorText).font(.footnote)
                    }
                    .lcarsPanel(tint: .red.opacity(0.9))
                }
            }
            .frame(maxWidth: LcarsTheme.Welcome.maxTextWidth)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .background(LcarsTheme.bg)
    }

    var canConnect: Bool {
        !tenantId.isEmpty && !clientId.isEmpty && !clientSecret.isEmpty
    }

    @MainActor
    private func connect() async {
        isConnecting = true
        defer { isConnecting = false }
        errorText = "Intune integration coming soon!"
    }
}

// MARK: - Kandji Login
struct KandjiLoginView: View {
    var onBack: () -> Void

    @State private var serverURL = ""
    @State private var apiToken = ""
    @State private var isConnecting = false
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                LcarsHeader(title: "Kandji Login")

                Text("API TOKEN REQUIRED")
                    .font(.caption)
                    .foregroundStyle(LcarsTheme.amber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LcarsTheme.amber.opacity(0.2))
                    .cornerRadius(6)

                ThemedField(title: "Server URL", text: $serverURL, placeholder: "your-company.api.kandji.io")
                ThemedField(title: "API Token", text: $apiToken, placeholder: "your-api-token", secure: true)

                Text("Generate an API token from Settings > Access > API Token in your Kandji instance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                HStack {
                    Button("Back", action: onBack)
                        .buttonStyle(.plain)
                        .lcarsPanel(tint: LcarsTheme.orange.opacity(0.7))
                        .frame(width: 80)

                    Spacer()

                    Button(isConnecting ? "Connecting…" : "Connect") {
                        Task { await connect() }
                    }
                    .disabled(isConnecting || !canConnect)
                    .buttonStyle(LcarsButtonStyle())
                }

                if let errorText {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ERROR").font(.caption).bold()
                        Text(errorText).font(.footnote)
                    }
                    .lcarsPanel(tint: .red.opacity(0.9))
                }
            }
            .frame(maxWidth: LcarsTheme.Welcome.maxTextWidth)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .background(LcarsTheme.bg)
    }

    var canConnect: Bool {
        !serverURL.isEmpty && !apiToken.isEmpty
    }

    @MainActor
    private func connect() async {
        isConnecting = true
        defer { isConnecting = false }
        errorText = "Kandji integration coming soon!"
    }
}

// MARK: - Mosyle Login
struct MosyleLoginView: View {
    var onBack: () -> Void

    @State private var accessToken = ""
    @State private var isConnecting = false
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                LcarsHeader(title: "Mosyle Login")

                Text("ACCESS TOKEN REQUIRED")
                    .font(.caption)
                    .foregroundStyle(LcarsTheme.amber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LcarsTheme.amber.opacity(0.2))
                    .cornerRadius(6)

                ThemedField(title: "Access Token", text: $accessToken, placeholder: "your-access-token", secure: true)

                Text("Get your access token from Manager > Settings > API Tokens in your Mosyle Business account.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                HStack {
                    Button("Back", action: onBack)
                        .buttonStyle(.plain)
                        .lcarsPanel(tint: LcarsTheme.orange.opacity(0.7))
                        .frame(width: 80)

                    Spacer()

                    Button(isConnecting ? "Connecting…" : "Connect") {
                        Task { await connect() }
                    }
                    .disabled(isConnecting || !canConnect)
                    .buttonStyle(LcarsButtonStyle())
                }

                if let errorText {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ERROR").font(.caption).bold()
                        Text(errorText).font(.footnote)
                    }
                    .lcarsPanel(tint: .red.opacity(0.9))
                }
            }
            .frame(maxWidth: LcarsTheme.Welcome.maxTextWidth)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .background(LcarsTheme.bg)
    }

    var canConnect: Bool {
        !accessToken.isEmpty
    }

    @MainActor
    private func connect() async {
        isConnecting = true
        defer { isConnecting = false }
        errorText = "Mosyle integration coming soon!"
    }
}
