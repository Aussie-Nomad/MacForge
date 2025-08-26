//
//  JamfDebugView.swift
//  MacForge
//
//  Debug interface for JAMF Pro operations and authentication testing.
//  Provides detailed logging and troubleshooting tools for development.
// 
import SwiftUI

struct JamfDebugView: View {
    @State private var serverURL = ""
    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var results: [String] = []
    @State private var authenticationService = JAMFAuthenticationService()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jamf Connection Debug")
                .font(.headline)
            Group {
                TextField("Server URL", text: $serverURL)
                TextField("Client ID", text: $clientID)
                SecureField("Client Secret", text: $clientSecret)
            }
            .textFieldStyle(.roundedBorder)
            Button("Test Connection") {
                testConnection()
            }
            .disabled(serverURL.isEmpty)
            .contentShape(Rectangle())
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                        Text(result)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(result.contains("❌") ? .red :
                                           result.contains("✅") ? .green : .primary)
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
    }

    private func testConnection() {
        results.removeAll()
        
        // Test 1: URL validation
        guard let url = URL(string: serverURL) else {
            results.append("❌ Invalid server URL format")
            return
        }
        results.append("🔍 Testing: \(url.absoluteString)")
        
        Task {
            do {
                // Test 2: Connection validation
                try await authenticationService.validateConnection(to: serverURL)
                await MainActor.run {
                    results.append("✅ Server reachable")
                }
                
                // Test 3: Authentication
                if !clientID.isEmpty && !clientSecret.isEmpty {
                    do {
                        _ = try await authenticationService.authenticateOAuth(
                            clientID: clientID,
                            clientSecret: clientSecret,
                            serverURL: serverURL
                        )
                        
                        await MainActor.run {
                            results.append("✅ Authentication successful")
                        }
                    } catch {
                        await MainActor.run {
                            results.append("❌ Authentication failed: \(error.localizedDescription)")
                        }
                    }
                } else {
                    await MainActor.run {
                        results.append("ℹ️ Skipping authentication test (no credentials provided)")
                    }
                }
            } catch {
                await MainActor.run {
                    results.append("❌ Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
