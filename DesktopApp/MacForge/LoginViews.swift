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
    /// success(baseURL, clientID, clientSecret) - clientID/clientSecret will be empty if username/password used
    case success(URL, String, String)
    case failure(Error)
    case cancelled
}

// MARK: - Jamf Authentication Sheet
/// Modal sheet for authenticating to Jamf. Supports client ID/secret today;
/// username/password path is provided but Jamf Pro typically prefers OAuth clients.
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
    @State private var isConnecting: Bool = false
    let onComplete: (JamfAuthResult) -> Void

    // Build a proper Jamf base URL from common user inputs.
    private func connectURL() -> URL? {
        var s = server.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: ",;"))
        if s.hasSuffix("/api/doc") { s.removeLast("/api/doc".count) }
        if s.hasSuffix("/api") { s.removeLast("/api".count) }
        if !s.hasPrefix("http://") && !s.hasPrefix("https://") { s = "https://" + s }
        guard var comps = URLComponents(string: s) else { return nil }
        comps.path = ""
        comps.query = nil
        comps.fragment = nil
        if let h = comps.host {
            let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789.-")
            let cleaned = String(h.lowercased().unicodeScalars.filter { allowed.contains($0) })
            comps.host = cleaned
        }
        return comps.url
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ThemedField(title: "Jamf Server",
                            text: $server,
                            placeholder: "zappi or zappi.jamfcloud.com")

                Picker("Method", selection: $mode) {
                    Text("Client ID + Secret").tag(0)
                    Text("Username + Password").tag(1)
                }
                .pickerStyle(.segmented)

                if mode == 0 {
                    ThemedField(title: "Client ID", text: $clientID)
                    ThemedField(title: "Client Secret", text: $clientSecret, secure: true)
                } else {
                    ThemedField(title: "Username", text: $username)
                    ThemedField(title: "Password", text: $password, secure: true)
                }

                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 4)
                }

                HStack {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)

                    Spacer()

                    Button(action: { Task { await connect() } }) {
                        if isConnecting {
                            ProgressView().progressViewStyle(.circular)
                        } else {
                            Text("Connect")
                        }
                    }
                    .disabled(isConnecting || !canConnect)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Jamf Login")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    var canConnect: Bool {
        guard !server.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if mode == 0 { return !clientID.isEmpty && !clientSecret.isEmpty }
        return !username.isEmpty && !password.isEmpty
    }

    @MainActor
    private func connect() async {
        guard !isConnecting else { return }
        guard let base = connectURL() else {
            errorMessage = "Please enter a valid Jamf server (e.g. zappi or zappi.jamfcloud.com)."
            return
        }

        isConnecting = true
        defer { isConnecting = false }
        // Local helper: ping
        func ping(_ base: URL) async throws {
            var req = URLRequest(url: base.appendingPathComponent("api/v1/ping"))
            req.httpMethod = "GET"
            req.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
        }

        // Local helper: test auth endpoint
        func testAuth(_ base: URL) async throws -> String {
            let authURL = base.appendingPathComponent("api/v1/auth")
            var req = URLRequest(url: authURL)
            req.httpMethod = "GET"
            req.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode == 401 { return "Connection successful - auth endpoint reachable" }
            return "Unexpected response: \(http.statusCode)"
        }

        // Local helper: OAuth client credentials
        func authenticateClientID(_ base: URL, clientID: String, clientSecret: String) async throws {
            let endpoints = ["api/oauth/token", "api/v1/oauth/token"]
            for endpoint in endpoints {
                let url = base.appendingPathComponent(endpoint)
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                req.setValue("application/json", forHTTPHeaderField: "Accept")
                req.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
                req.timeoutInterval = 30.0
                let basic = "\(clientID):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
                req.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
                req.httpBody = "grant_type=client_credentials".data(using: .utf8)

                let (_, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse else { continue }
                if http.statusCode == 200 { return }
            }
            throw URLError(.userAuthenticationRequired)
        }

        // Local helper: basic username/password
        func authenticateBasic(_ base: URL, username: String, password: String) async throws {
            let endpoint = "api/v1/auth/token"
            let url = base.appendingPathComponent(endpoint)
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.timeoutInterval = 30.0
            let basic = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
            req.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")

            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            guard http.statusCode == 200 else { throw URLError(.userAuthenticationRequired) }
        }

        do {
            try await ping(base)
            _ = try await testAuth(base)

            if mode == 0 {
                try await authenticateClientID(base, clientID: clientID, clientSecret: clientSecret)
            } else {
                try await authenticateBasic(base, username: username, password: password)
            }

            errorMessage = nil
            if mode == 0 {
                onComplete(.success(base, clientID, clientSecret))
            } else {
                onComplete(.success(base, username, password))
            }
            dismiss()

        } catch let urlError as URLError {
            switch urlError.code {
            case .cannotFindHost:
                errorMessage = "Cannot find server. Check the hostname: \(base.host ?? "unknown")"
            case .notConnectedToInternet:
                errorMessage = "No internet connection."
            case .timedOut:
                errorMessage = "Connection timed out. Check firewall/VPN."
            case .userAuthenticationRequired:
                errorMessage = "Authentication failed. Verify your credentials."
            default:
                errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
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
