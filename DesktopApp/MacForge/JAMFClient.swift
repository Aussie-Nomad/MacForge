//
//  JAMFClient.swift
//  MacForge
//
//  Created by Danny Mac on 13/08/2025.
//
// V3

import Foundation

// Support both token response formats from Jamf
private struct JamfTokenResponse: Decodable {
    let token: String?
    let access_token: String? // OAuth format
    
    var actualToken: String? {
        return token ?? access_token
    }
}

public final class JamfClient {
    /// Normalizes user input like "zappi.jamfcloud.com", "https://zappi.jamfcloud.com/", or
    /// accidental paths like "/api/doc" into a clean Jamf base URL.
    public static func normalizeBaseURL(from raw: String) -> URL? {
        // Trim whitespace and very common trailing punctuation that can sneak in from copy/paste
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: ",;"))
        // Remove known Jamf doc/API suffixes if pasted
        if s.hasSuffix("/api/doc") { s.removeLast("/api/doc".count) }
        if s.hasSuffix("/api") { s.removeLast("/api".count) }
        // Ensure scheme
        if !s.hasPrefix("http://") && !s.hasPrefix("https://") {
            s = "https://" + s
        }
        // Normalize to just scheme + host (drop any accidental path/query/fragment)
        guard var comps = URLComponents(string: s) else { return nil }
        comps.path = ""
        comps.query = nil
        comps.fragment = nil
        // Lowercase host and strip stray characters not allowed in hostnames
        if let h = comps.host {
            let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789.-")
            let cleaned = String(h.lowercased().unicodeScalars.filter { allowed.contains($0) })
            comps.host = cleaned
        }
        return comps.url
    }

    public enum JamfError: Error, LocalizedError {
        case http(Int, String?)
        case notAuthenticated
        case invalidResponse
        case noToken

        public var errorDescription: String? {
            switch self {
            case .http(let code, let message):
                if let message = message {
                    return "Jamf returned HTTP \(code): \(message)"
                } else {
                    return "Jamf returned HTTP \(code)"
                }
            case .notAuthenticated:
                return "Not authenticated"
            case .invalidResponse:
                return "Invalid response from Jamf server"
            case .noToken:
                return "No authentication token received"
            }
        }
    }

    public let baseURL: URL
    private var token: String?

    public init(baseURL: URL) {
        self.baseURL = baseURL
        print("🔍 JamfClient initialized with baseURL: \(baseURL.absoluteString)")
    }

    /// Quick connectivity probe (Jamf has a public ping endpoint).
    public func ping() async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/v1/ping"))
        req.httpMethod = "GET"
        req.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw JamfError.http((resp as? HTTPURLResponse)?.statusCode ?? -1, nil)
        }
    }

    // MARK: - Client ID + Secret (OAuth)
    public func authenticateClientID(clientID: String, clientSecret: String) async throws {
        // Try both OAuth endpoints - Jamf Pro uses different ones
        let endpoints = ["api/oauth/token", "api/v1/oauth/token"]
        
        for endpoint in endpoints {
            do {
                let url = baseURL.appendingPathComponent(endpoint)
                print("🔍 Trying OAuth endpoint: \(url.absoluteString)")
                
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                req.setValue("application/json", forHTTPHeaderField: "Accept")
                req.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
                req.timeoutInterval = 30.0

                // Jamf expects Basic auth with clientID:clientSecret for OAuth
                let basic = "\(clientID):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
                req.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")

                // Only the grant_type should be in the body
                req.httpBody = "grant_type=client_credentials".data(using: .utf8)
                
                print("🔍 Making OAuth request to \(endpoint)...")
                
                let (data, resp) = try await URLSession.shared.data(for: req)
                
                guard let http = resp as? HTTPURLResponse else {
                    print("🔍 OAuth: No HTTP response")
                    continue
                }
                
                print("🔍 OAuth response status: \(http.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 OAuth response body: \(responseString)")
                }
                
                guard http.statusCode == 200 else {
                    let errorMessage = String(data: data, encoding: .utf8)
                    print("🔍 OAuth failed with status \(http.statusCode): \(errorMessage ?? "no error message")")
                    continue // Try next endpoint
                }

                do {
                    let tokenResponse = try JSONDecoder().decode(JamfTokenResponse.self, from: data)
                    guard let receivedToken = tokenResponse.actualToken else {
                        print("🔍 OAuth: No token in response")
                        continue
                    }
                    
                    self.token = receivedToken
                    print("🔍 OAuth: Token received successfully from \(endpoint) (length: \(receivedToken.count))")
                    return // Success!
                    
                } catch {
                    print("🔍 OAuth: JSON parsing failed: \(error)")
                    continue // Try next endpoint
                }
            } catch {
                print("🔍 OAuth endpoint \(endpoint) failed: \(error)")
                continue // Try next endpoint
            }
        }
        
        // If we get here, all endpoints failed
        throw JamfError.http(401, "All OAuth endpoints failed. Check your client ID and secret.")
    }

    // Back-compat alias
    public func authenticate(clientID: String, clientSecret: String) async throws {
        try await authenticateClientID(clientID: clientID, clientSecret: clientSecret)
    }

    // MARK: - Username + Password (Basic → bearer)
    public func authenticatePassword(username: String, password: String) async throws {
        let endpoint = "api/v1/auth/token"
        let url = baseURL.appendingPathComponent(endpoint)
        print("🔍 Basic auth endpoint: \(url.absoluteString)")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 30.0

        let basic = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        req.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        
        print("🔍 Making Basic auth request...")

        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse else {
            print("🔍 Basic auth: No HTTP response")
            throw JamfError.invalidResponse
        }
        
        print("🔍 Basic auth response status: \(http.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 Basic auth response body: \(responseString)")
        }
        
        guard http.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8)
            print("🔍 Basic auth failed with status \(http.statusCode): \(errorMessage ?? "no error message")")
            throw JamfError.http(http.statusCode, errorMessage)
        }

        do {
            let tokenResponse = try JSONDecoder().decode(JamfTokenResponse.self, from: data)
            guard let receivedToken = tokenResponse.actualToken else {
                print("🔍 Basic auth: No token in response")
                throw JamfError.noToken
            }
            
            self.token = receivedToken
            print("🔍 Basic auth: Token received successfully (length: \(receivedToken.count))")
            
        } catch {
            print("🔍 Basic auth: JSON parsing failed: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Basic auth: Raw response: \(responseString)")
            }
            throw JamfError.invalidResponse
        }
    }

    // Back-compat alias
    public func authenticateBasic(username: String, password: String) async throws {
        try await authenticatePassword(username: username, password: password)
    }

    // MARK: - Authed requests
    private func authedRequest(_ path: String, method: String = "GET", contentType: String? = nil) throws -> URLRequest {
        guard let token else { throw JamfError.notAuthenticated }
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("MacForge/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let ct = contentType { req.setValue(ct, forHTTPHeaderField: "Content-Type") }
        return req
    }

    public func uploadComputerProfileXML(name: String, xmlPlist: Data) async throws {
        var req = try authedRequest("JSSResource/osxconfigurationprofiles/id/0", method: "POST", contentType: "application/xml")
        let encoded = xmlPlist.base64EncodedString()
        req.httpBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <os_x_configuration_profile>
          <general>
            <name>\(name)</name>
            <distribution_method>Install Automatically</distribution_method>
            <payloads>\(encoded)</payloads>
          </general>
        </os_x_configuration_profile>
        """.data(using: .utf8)

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...201).contains(http.statusCode) else {
            throw JamfError.http((resp as? HTTPURLResponse)?.statusCode ?? -1, nil)
        }
    }

    /// Attempts to create the profile, and if it already exists (409), updates it in-place by name.
    public func uploadOrUpdateComputerProfileXML(name: String, xmlPlist: Data) async throws {
        do {
            try await uploadComputerProfileXML(name: name, xmlPlist: xmlPlist)
            print("🔍 Profile created successfully")
            return
        } catch JamfError.http(let code, _) where code == 409 {
            print("🔍 Profile already exists (409), attempting to update...")
            try await updateComputerProfileXMLByName(name: name, xmlPlist: xmlPlist)
            print("🔍 Profile updated successfully")
        }
    }

    /// Updates an existing configuration profile by name using the Classic API.
    private func updateComputerProfileXMLByName(name: String, xmlPlist: Data) async throws {
        // First, try to find the existing profile by name
        let safeName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        let searchURL = baseURL.appendingPathComponent("JSSResource/osxconfigurationprofiles/name/\(safeName)")
        
        var searchReq = try authedRequest("JSSResource/osxconfigurationprofiles/name/\(safeName)", method: "GET")
        searchReq.url = searchURL
        
        let (searchData, searchResp) = try await URLSession.shared.data(for: searchReq)
        
        guard let searchHttp = searchResp as? HTTPURLResponse else {
            throw JamfError.invalidResponse
        }
        
        if searchHttp.statusCode == 404 {
            // Profile doesn't exist, try creating it again
            print("🔍 Profile not found by name, attempting to create...")
            try await uploadComputerProfileXML(name: name, xmlPlist: xmlPlist)
            return
        }
        
        guard searchHttp.statusCode == 200 else {
            let body = String(data: searchData, encoding: .utf8)
            throw JamfError.http(searchHttp.statusCode, body)
        }
        
        // Profile exists, now update it
        var req = try authedRequest("JSSResource/osxconfigurationprofiles/name/\(safeName)", method: "PUT", contentType: "application/xml")
        let encoded = xmlPlist.base64EncodedString()
        req.httpBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <os_x_configuration_profile>
          <general>
            <name>\(name)</name>
            <distribution_method>Install Automatically</distribution_method>
            <payloads>\(encoded)</payloads>
          </general>
        </os_x_configuration_profile>
        """.data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...201).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw JamfError.http((resp as? HTTPURLResponse)?.statusCode ?? -1, body)
        }
    }
}
