//
//  OAuth2AuthorizationView.swift
//  MacForge
//
//  OAuth 2.0 authorization flow interface.
//  Handles the complete OAuth 2.0 with PKCE authentication process.
//

import SwiftUI
import WebKit

struct OAuth2AuthorizationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var authorizationResult: OAuth2AuthorizationResult?
    @State private var webView: WKWebView?
    
    let clientID: String
    let redirectURI: String
    let serverURL: String
    let scopes: [String]
    let onSuccess: (OAuth2TokenResponse) -> Void
    let onFailure: (Error) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let result = authorizationResult {
                    OAuth2WebView(
                        authorizationURL: result.authorizationURL,
                        redirectURI: result.redirectURI,
                        onAuthorizationCode: { code in
                            Task {
                                await handleAuthorizationCode(code, result: result)
                            }
                        },
                        onError: { error in
                            handleError(error)
                        }
                    )
                } else {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Preparing OAuth 2.0 Authorization")
                            .font(.headline)
                        
                        Text("Setting up secure authentication flow...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("OAuth 2.0 Authentication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await startAuthorizationFlow()
        }
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func startAuthorizationFlow() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await OAuth2Service.shared.startAuthorizationFlow(
                clientID: clientID,
                redirectURI: redirectURI,
                serverURL: serverURL,
                scopes: scopes
            )
            
            await MainActor.run {
                self.authorizationResult = result
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showingError = true
                self.isLoading = false
            }
        }
    }
    
    private func handleAuthorizationCode(_ code: String, result: OAuth2AuthorizationResult) async {
        do {
            let tokenResponse = try await OAuth2Service.shared.exchangeCodeForToken(
                authorizationCode: code,
                codeVerifier: result.codeVerifier,
                clientID: clientID,
                redirectURI: redirectURI,
                serverURL: serverURL
            )
            
            await MainActor.run {
                onSuccess(tokenResponse)
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                handleError(error)
            }
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

// MARK: - OAuth 2.0 Web View

struct OAuth2WebView: NSViewRepresentable {
    let authorizationURL: URL
    let redirectURI: String
    let onAuthorizationCode: (String) -> Void
    let onError: (Error) -> Void
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: authorizationURL)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: OAuth2WebView
        
        init(_ parent: OAuth2WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            // Check if this is a redirect to our redirect URI
            if url.absoluteString.hasPrefix(parent.redirectURI) {
                decisionHandler(.cancel)
                
                // Parse authorization code from URL
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems {
                    
                    // Check for authorization code
                    if let code = queryItems.first(where: { $0.name == "code" })?.value {
                        parent.onAuthorizationCode(code)
                        return
                    }
                    
                    // Check for error
                    if let error = queryItems.first(where: { $0.name == "error" })?.value {
                        let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value ?? error
                        parent.onError(OAuth2Error.tokenExchangeFailed(errorDescription))
                        return
                    }
                }
                
                // If we get here, the redirect didn't contain expected parameters
                parent.onError(OAuth2Error.invalidAuthorizationCode)
            } else {
                decisionHandler(.allow)
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.onError(error)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onError(error)
        }
    }
}

// MARK: - OAuth 2.0 Configuration View

struct OAuth2ConfigurationView: View {
    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var serverURL = ""
    @State private var redirectURI = ""
    @State private var selectedScopes: Set<String> = ["read", "write"]
    @State private var showingAuthorization = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    let onSuccess: (OAuth2TokenResponse) -> Void
    let onCancel: () -> Void
    
    private let availableScopes = [
        "read": "Read access to resources",
        "write": "Write access to resources",
        "admin": "Administrative access",
        "users": "User management access",
        "devices": "Device management access"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OAuth 2.0 Configuration")) {
                    TextField("Client ID", text: $clientID)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Client Secret", text: $clientSecret)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Server URL", text: $serverURL)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Redirect URI", text: $redirectURI)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section(header: Text("Scopes")) {
                    ForEach(Array(availableScopes.keys.sorted()), id: \.self) { scope in
                        HStack {
                            Button(action: {
                                if selectedScopes.contains(scope) {
                                    selectedScopes.remove(scope)
                                } else {
                                    selectedScopes.insert(scope)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedScopes.contains(scope) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedScopes.contains(scope) ? .blue : .gray)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(scope)
                                            .font(.headline)
                                        Text(availableScopes[scope] ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section(header: Text("Security Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.green)
                            Text("OAuth 2.0 with PKCE")
                                .font(.headline)
                        }
                        
                        Text("This authentication method uses OAuth 2.0 with Proof Key for Code Exchange (PKCE) for enhanced security. Your credentials are never transmitted directly.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("OAuth 2.0 Setup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Authenticate") {
                        startAuthentication()
                    }
                    .disabled(!isConfigurationValid)
                }
            }
        }
        .sheet(isPresented: $showingAuthorization) {
            OAuth2AuthorizationView(
                clientID: clientID,
                redirectURI: redirectURI,
                serverURL: serverURL,
                scopes: Array(selectedScopes),
                onSuccess: onSuccess,
                onFailure: { error in
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            )
        }
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var isConfigurationValid: Bool {
        return !clientID.isEmpty &&
               !clientSecret.isEmpty &&
               !serverURL.isEmpty &&
               !redirectURI.isEmpty &&
               !selectedScopes.isEmpty
    }
    
    private func startAuthentication() {
        showingAuthorization = true
    }
}

#Preview {
    OAuth2ConfigurationView(
        onSuccess: { _ in },
        onCancel: { }
    )
}
