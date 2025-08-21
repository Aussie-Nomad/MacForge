//
//  Helpers.swift
//  MacForge
//
//  Created by Danny Mac on 15/08/2025.
//
//  V3.1 – small URL/host helpers + tidy docs
//

import SwiftUI
import Foundation

// MARK: - File / Export

/// Saves a `.mobileconfig` to the user's Downloads folder.
/// - Parameters:
///   - data: Raw profile data (XML plist).
///   - name: Base filename (extension is added automatically).
func saveProfileToDownloads(_ data: Data, name: String) {
#if os(macOS)
    let fm = FileManager.default
    let downloads = fm.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    let safe = name
        .replacingOccurrences(of: "/", with: "-")
        .replacingOccurrences(of: ":", with: "-")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    let url = downloads.appendingPathComponent("\(safe).mobileconfig")
    do {
        try data.write(to: url, options: .atomic)
        print("Saved profile to: \(url.path)")
    } catch {
        print("Failed to save profile:", error.localizedDescription)
    }
#endif
}

// MARK: - Display helpers (non-duplicated)

/// Friendly display name for an internal key or identifier.
/// Falls back to a prettified (title-cased) version of the raw string.
func friendlyName(_ raw: String) -> String {
    let map: [String: String] = [
        "pppc"            : "Privacy Permissions",
        "systemextensions": "System Extensions",
        "notifications"   : "Notifications",
        "firewall"        : "Firewall",
        "filevault"       : "FileVault",
        "wifi"            : "Wi‑Fi"
    ]
    if let pretty = map[raw.lowercased()] { return pretty }
    return raw
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(of: "-", with: " ")
        .capitalized
}

/// SF Symbol for a platform string.
func platformSymbol(_ platform: String) -> String {
    switch platform.lowercased() {
    case "macos", "mac": return "laptopcomputer"
    case "ios", "iphone": return "iphone"
    case "ipados", "ipad": return "ipad"
    case "watchos": return "applewatch"
    case "tvos": return "appletv"
    default: return "gear"
    }
}

// MARK: - URL / Host normalization (for MDM fields)

/// Returns `true` if the user-typed host *looks* like a Jamf Cloud hostname.
/// This is only a light heuristic, not a definitive check.
func isLikelyJamfCloudHost(_ host: String) -> Bool {
    let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return trimmed.hasSuffix(".jamfcloud.com") || trimmed.hasSuffix(".jamfcloud.eu")
}

/// Normalizes common user inputs into a consistent HTTPS base URL.
/// Examples:
/// - "zappi"                → https://zappi.jamfcloud.com
/// - "zappi.jamfcloud.com"  → https://zappi.jamfcloud.com
/// - "http://foo"           → https://foo
/// - "https://foo"          → https://foo
///
/// If `forceJamfCloudSuffix` is true and the input does not include a dot,
/// we append ".jamfcloud.com".
func normalizedMDMBaseURL(
    from input: String,
    forceJamfCloudSuffix: Bool = true
) -> URL? {
    var raw = input
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)

    // If it has no scheme, assume https
    if !raw.lowercased().hasPrefix("http://") && !raw.lowercased().hasPrefix("https://") {
        raw = "https://\(raw)"
    }

    // Build a URL we can tweak
    guard var comps = URLComponents(string: raw) else { return nil }

    // Force HTTPS
    comps.scheme = "https"

    // If host is missing (common when user typed only a word), try to treat path as host.
    if comps.host == nil, let first = comps.path.split(separator: "/").first {
        comps.host = String(first)
        comps.path = comps.path.dropFirst(first.count).isEmpty ? "" : String(comps.path.dropFirst(first.count))
    }

    // For single-token hosts (no dot), optionally append jamfcloud suffix.
    if forceJamfCloudSuffix, let host = comps.host, !host.contains(".") {
        comps.host = "\(host).jamfcloud.com"
    }

    // Drop any path/query/fragment – we want the base
    comps.path = ""
    comps.query = nil
    comps.fragment = nil

    return comps.url
}

/// Tries to build the best-guess Jamf base URL from a text field.
/// Returns both the final URL and a short, user-facing reason if it fails.
func coalescedServerFieldToURL(_ field: String) -> (url: URL?, errorHint: String?) {
    guard !field.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return (nil, "Please enter a server address.")
    }
    if let url = normalizedMDMBaseURL(from: field, forceJamfCloudSuffix: true) {
        return (url, nil)
    }
    return (nil, "That server address doesn’t look valid.")
}

// MARK: - Small conveniences

/// Runs a closure on the main actor with a default animation (nice for state flips).
@discardableResult
func withMainAnimation<Result>(_ animation: Animation = .easeInOut(duration: 0.2),
                               _ body: @escaping () -> Result) -> Result {
    var result: Result!
    Task { @MainActor in
        withAnimation(animation) {
            result = body()
        }
    }
    return result
}
