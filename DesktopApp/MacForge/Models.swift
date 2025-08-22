//
//  Models.swift
//  MacForge
//
//  Created by Danny Mac on 14/08/2025.
//
// V3

import SwiftUI


// MARK: - Core Data Models
struct Payload: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var description: String
    var platforms: [String]
    var icon: String
    var category: String
    var settings: [String: CodableValue] = [:]
    var enabled: Bool = true
    var uuid: String = UUID().uuidString
}

struct CodableValue: Codable, Hashable {
    var value: AnyHashable
    init(_ v: AnyHashable) { value = v }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) { value = b }
        else if let i = try? c.decode(Int.self) { value = i }
        else if let d = try? c.decode(Double.self) { value = d }
        else if let s = try? c.decode(String.self) { value = s }
        else if let a = try? c.decode([String].self) { value = AnyHashable(a) }
        else { value = "" }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let b as Bool: try c.encode(b)
        case let i as Int: try c.encode(i)
        case let d as Double: try c.encode(d)
        case let s as String: try c.encode(s)
        case let a as [String]: try c.encode(a)
        default: try c.encode(String(describing: value))
        }
    }
}

struct ProfileSettings: Codable, Hashable {
    var name: String = "New Configuration Profile"
    var description: String = "Created with MacForge"
    var identifier: String = "com.macforge.profile.\(Int(Date().timeIntervalSince1970))"
    var organization: String = "Your Organization"
    var scope: String = "System"
}

struct TemplateProfile: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let description: String
    let payloadIDs: [String]
}

enum MDMVendor: String, CaseIterable, Identifiable {
    case jamf = "Jamf Pro"
    case intune = "Microsoft Intune"
    case kandji = "Kandji"
    case mosyle = "Mosyle"
    var id: String { rawValue }
    var asset: String {
        switch self {
        case .jamf:   return "mdm_jamf"
        case .intune: return "mdm_intune"
        case .kandji: return "mdm_kandji"
        case .mosyle: return "mdm_mosyle"
        }
    }
    var sfFallback: String { "building.2.crop.circle" }
}

enum ToolModule: String, CaseIterable, Identifiable {
    case profileBuilder
    case packageSmelting
    case deviceFoundry
    case blueprintBuilder
    case hammeringScripts

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .profileBuilder: return "Profile Builder"
        case .packageSmelting: return "Package Smelting"
        case .deviceFoundry: return "Device Foundry"
        case .blueprintBuilder: return "Blueprint Builder"
        case .hammeringScripts: return "Hammering Scripts"
        }
    }

    var icon: String {
        switch self {
        case .profileBuilder: return "doc.badge.gearshape"
        case .packageSmelting: return "shippingbox"
        case .deviceFoundry: return "desktopcomputer"
        case .blueprintBuilder: return "square.grid.3x3"
        case .hammeringScripts: return "hammer"
        }
    }
}

enum AuthDecision: String, Codable, CaseIterable, Hashable {
    case allow = "Allow", ask = "Prompt", deny = "Deny"
}

struct PPPCService: Identifiable, Codable, Hashable {
    var id: String
    var decision: AuthDecision = .ask
    var receiverBundleID: String? = nil
    var receiverIdentifierType: String? = "bundleID" // bundleID | path | codeRequirement
    var screenCaptureType: String? = nil            // "All" | "WindowOnly"
}

// MARK: - Builder Model
@MainActor
final class BuilderModel: ObservableObject {
    // Library/selection
    @Published var searchTerm = ""
    @Published var selectedCategory = "All"
    @Published var library: [Payload] = allPayloadsLibrary
    @Published var dropped: [Payload] = []
    @Published var selected: Payload? = nil

    // Profile
    @Published var settings: ProfileSettings = .init()
    @Published var showTemplates = false

    // Wizard
    @Published var wizardMode = true
    @Published var wizardStep = 1
    @Published var pppcServices: [PPPCService] = pppcServiceCatalog.map { .init(id: $0) }
    @Published var suggestedServiceIDs: Set<String> = []
    @Published var identifierType: String = "bundleID"

    // Jamf
    @Published var jamfClient: JamfClient? = nil
    @Published var jamfAuthOK = false
    @Published var mdmLocked = false

    func connectJamf(serverURL: String, clientID: String, clientSecret: String) async {
        guard let url = URL(string: serverURL) else { jamfAuthOK = false; mdmLocked = false; return }
        let client = JamfClient(baseURL: url)
        do {
            try await client.authenticate(clientID: clientID, clientSecret: clientSecret)
            self.jamfClient = client
            self.jamfAuthOK = true
            self.mdmLocked = true
        } catch {
            self.jamfAuthOK = false
            self.mdmLocked = false
        }
    }

    func uploadProfileToJamf(_ data: Data) async throws {
        guard let client = jamfClient else { throw URLError(.userAuthenticationRequired) }
        try await client.uploadComputerProfileXML(name: settings.name, xmlPlist: data)
    }

    func applyCategorySuggestions(_ category: String) {
        let map: [String: [String]] = [
            "Security EDR": ["Accessibility","SystemPolicyAllFiles","ScreenCapture","AppleEvents","Microphone","Camera"],
            "Browser": ["ScreenCapture","AppleEvents","SystemPolicyDownloadsFolder"],
            "Communications": ["Camera","Microphone","AppleEvents"],
            "General": []
        ]
        suggestedServiceIDs = Set(map[category] ?? [])
        pppcServices.sort { a, b in
            let asug = suggestedServiceIDs.contains(a.id), bsug = suggestedServiceIDs.contains(b.id)
            if asug != bsug { return asug && !bsug }
            return a.id < b.id
        }
    }

    func filtered() -> [Payload] {
        library.filter { p in
            (selectedCategory == "All" || p.category == selectedCategory) &&
            (searchTerm.isEmpty || p.name.lowercased().contains(searchTerm.lowercased()) ||
             p.description.lowercased().contains(searchTerm.lowercased()))
        }
    }

    func add(_ payload: Payload) {
        guard !dropped.contains(where: { $0.id == payload.id }) else { return }
        var copy = payload
        copy.uuid = UUID().uuidString
        copy.enabled = true
        dropped.append(copy)
    }

    func remove(_ payloadID: String) {
        dropped.removeAll { $0.id == payloadID }
        if selected?.id == payloadID { selected = nil }
    }

    func apply(template: TemplateProfile) {
        dropped = template.payloadIDs.compactMap { id in library.first { $0.id == id } }
            .map { var c = $0; c.uuid = UUID().uuidString; c.enabled = true; return c }
        if template.name == "Antivirus Setup" {
            if !dropped.contains(where: { $0.id == "pppc" }), let p = library.first(where: { $0.id == "pppc" }) { add(p) }
            for i in pppcServices.indices {
                switch pppcServices[i].id {
                case "SystemPolicyAllFiles", "ScreenCapture", "Accessibility": pppcServices[i].decision = .allow
                default: break
                }
            }
            suggestedServiceIDs = ["SystemPolicyAllFiles","ScreenCapture","Accessibility"]
        }
    }

    func humanSummary() -> [String] {
        var out: [String] = []
        if let sel = selected, sel.id == "pppc",
           let bid = sel.settings["BundleIdentifier"]?.value as? String, !bid.isEmpty { out.append("Apply permissions to \(bid)") }
        for svc in pppcServices where svc.decision != .ask {
            let verb = (svc.decision == .allow ? "Allow" : "Deny")
            if svc.id == "AppleEvents", let r = svc.receiverBundleID, !r.isEmpty { out.append("\(verb) AppleEvents to \(r)") }
            else { out.append("\(verb) " + friendlyName(svc.id)) }
        }
        return out.isEmpty ? ["No changes selected yet"] : out
    }

    // Check if any PPPC permissions have been configured (not just default 'ask' state)
    func hasConfiguredPermissions() -> Bool {
        return pppcServices.contains { $0.decision != .ask }
    }

    // ...existing code...

    // Maps internal TCC service identifiers to human‑friendly names shown in summaries.
    private func friendlyName(_ id: String) -> String {
        let map: [String: String] = [
            "Accessibility":                 "Accessibility",
            "SystemPolicyAllFiles":         "Full Disk Access",
            "SystemPolicyDownloadsFolder":  "Downloads Folder",
            "ScreenCapture":                "Screen Recording",
            "AppleEvents":                  "Apple Events",
            "Microphone":                   "Microphone",
            "Camera":                       "Camera"
        ]
        return map[id] ?? id
    }

    // Build .mobileconfig (XML Plist)
    func exportMobileConfig() throws -> Data {
        let payloadDicts: [[String: Any]] = dropped.map { p in
            if p.id == "pppc" {
                var services: [[String: Any]] = []
                for svc in pppcServices {
                    var item: [String: Any] = ["Service": svc.id, "Authorization": svc.decision.rawValue]
                    if svc.id == "AppleEvents", let r = svc.receiverBundleID, !r.isEmpty {
                        item["AEReceiverIdentifier"] = r
                        item["AEReceiverIdentifierType"] = svc.receiverIdentifierType ?? "bundleID"
                    }
                    if svc.id == "ScreenCapture", let t = svc.screenCaptureType { item["ScreenCaptureType"] = t }
                    services.append(item)
                }
                var tcc: [String: Any] = [
                    "PayloadType": "com.apple.TCC",
                    "PayloadIdentifier": "\(settings.identifier).\(p.id)",
                    "PayloadUUID": p.uuid,
                    "PayloadDisplayName": p.name,
                    "PayloadDescription": p.description,
                    "PayloadVersion": 1,
                    "PayloadEnabled": p.enabled,
                    "Services": services,
                    "IdentifierType": identifierType
                ]
                if let bid = p.settings["BundleIdentifier"]?.value as? String { tcc["Identifier"] = bid }
                if let cr  = p.settings["CodeRequirement"]?.value as? String { tcc["CodeRequirement"] = cr }
                return tcc
            }
            var dict: [String: Any] = [
                "PayloadType": "com.apple.\(p.id)",
                "PayloadIdentifier": "\(settings.identifier).\(p.id)",
                "PayloadUUID": p.uuid,
                "PayloadDisplayName": p.name,
                "PayloadDescription": p.description,
                "PayloadVersion": 1,
                "PayloadEnabled": p.enabled
            ]
            for (k,v) in p.settings { dict[k] = v.value }
            return dict
        }

        let profile: [String: Any] = [
            "PayloadType": "Configuration",
            "PayloadDisplayName": settings.name,
            "PayloadDescription": settings.description,
            "PayloadIdentifier": settings.identifier,
            "PayloadOrganization": settings.organization,
            "PayloadScope": settings.scope,
            "PayloadUUID": UUID().uuidString,
            "PayloadVersion": 1,
            "PayloadContent": payloadDicts
        ]
        return try PropertyListSerialization.data(fromPropertyList: profile, format: .xml, options: 0)
    }
    
        // MARK: - BuilderModel extension for .mobileconfig export
        func saveProfileToDownloads() {
            do {
                let data = try exportMobileConfig()
                let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                let filename = "\(settings.name).mobileconfig"
                let fileURL = downloadsURL.appendingPathComponent(filename)
                try data.write(to: fileURL)
                print("Profile saved to: \(fileURL.path)")
            } catch {
                print("❌ Failed to export profile: \(error)")
            }
        }
}
