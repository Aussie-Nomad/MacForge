import SwiftUI

struct JamfDebugView: View {
    @State private var serverURL = ""
    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var results: [String] = []
    
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
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(Array(results.enumerated()), id: \ .offset) { index, result in
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
        
        guard let url = JamfClient.normalizeBaseURL(from: serverURL) else {
            results.append("❌ Invalid server URL")
            return
        }
        
        results.append("🔍 Testing: \(url.absoluteString)")
        
        Task {
            let client = JamfClient(baseURL: url)
            
            // Test 1: Basic connectivity
            do {
                try await client.ping()
                await MainActor.run {
                    results.append("✅ Server reachable")
                }
            } catch {
                await MainActor.run {
                    results.append("❌ Ping failed: \(error.localizedDescription)")
                }
                return
            }
            
            // Test 2: Auth endpoint
            do {
                let testResult = try await client.testConnection()
                await MainActor.run {
                    results.append("✅ Auth endpoint: \(testResult)")
                }
            } catch {
                await MainActor.run {
                    results.append("❌ Auth endpoint failed: \(error.localizedDescription)")
                }
            }
            
            // Test 3: Authentication
            if !clientID.isEmpty && !clientSecret.isEmpty {
                do {
                    try await client.authenticate(clientID: clientID, clientSecret: clientSecret)
                    await MainActor.run {
                        results.append("✅ Authentication successful")
                    }
                } catch {
                    await MainActor.run {
                        results.append("❌ Authentication failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
