//
//  Types.swift
//  MacForge
//
//  Core data types and models shared across the application.
//  Centralized to avoid circular dependencies.
//

import Foundation

// MARK: - Profile Validation Error
enum ProfileValidationError: LocalizedError {
    case invalidName
    case emptyName
    case nameTooLong
    case invalidIdentifier
    case emptyIdentifier
    case emptyOrganization
    case noPayloads
    case duplicatePayloadIdentifier(String)
    case emptyPayloadIdentifier
    case emptyPayloadDisplayName(String)
    case invalidPayloadType(String)
    
    // PPPC-specific errors
    case missingPPPCServices(String)
    case emptyPPPCServices(String)
    case invalidPPPCServiceName(String, Int)
    case missingPPPCAuthorization(String, Int)
    case missingPPPCIdentifier(String, Int)
    
    // WiFi-specific errors
    case missingWiFiSSID(String)
    case missingWiFiSecurityType(String)
    case missingWiFiPassword(String)
    
    // VPN-specific errors
    case missingVPNServerAddress(String)
    case missingVPNType(String)
    case missingVPNAuthenticationMethod(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Profile name is invalid"
        case .emptyName:
            return "Profile name is required"
        case .nameTooLong:
            return "Profile name is too long (maximum 100 characters)"
        case .invalidIdentifier:
            return "Profile identifier is invalid"
        case .emptyIdentifier:
            return "Profile identifier is required"
        case .emptyOrganization:
            return "Organization name is required"
        case .noPayloads:
            return "At least one payload is required"
        case .duplicatePayloadIdentifier(let identifier):
            return "Duplicate payload identifier: \(identifier)"
        case .emptyPayloadIdentifier:
            return "Payload identifier is required"
        case .emptyPayloadDisplayName(let identifier):
            return "Display name is required for payload: \(identifier)"
        case .invalidPayloadType(let identifier):
            return "Invalid payload type for: \(identifier)"
        case .missingPPPCServices(let identifier):
            return "PPPC services are missing for payload: \(identifier)"
        case .emptyPPPCServices(let identifier):
            return "PPPC services list is empty for payload: \(identifier)"
        case .invalidPPPCServiceName(let identifier, let index):
            return "Invalid PPPC service name at index \(index) for payload: \(identifier)"
        case .missingPPPCAuthorization(let identifier, let index):
            return "Missing PPPC authorization at index \(index) for payload: \(identifier)"
        case .missingPPPCIdentifier(let identifier, let index):
            return "Missing PPPC identifier at index \(index) for payload: \(identifier)"
        case .missingWiFiSSID(let identifier):
            return "WiFi SSID is missing for payload: \(identifier)"
        case .missingWiFiSecurityType(let identifier):
            return "WiFi security type is missing for payload: \(identifier)"
        case .missingWiFiPassword(let identifier):
            return "WiFi password is missing for secured network in payload: \(identifier)"
        case .missingVPNServerAddress(let identifier):
            return "VPN server address is missing for payload: \(identifier)"
        case .missingVPNType(let identifier):
            return "VPN type is missing for payload: \(identifier)"
        case .missingVPNAuthenticationMethod(let identifier):
            return "VPN authentication method is missing for payload: \(identifier)"
        }
    }
}

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

// MARK: - Template Profile
struct TemplateProfile: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let description: String
    let payloadIDs: [String]
}

// MARK: - PPPC Service Models
struct PPPCService: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: PPPCServiceCategory
    let requiresBundleID: Bool
    let requiresCodeRequirement: Bool
    let requiresIdentifier: Bool
    
    var displayName: String { name }
}

enum PPPCServiceCategory: String, CaseIterable {
    case system = "System"
    case accessibility = "Accessibility"
    case automation = "Automation"
    case inputMonitoring = "Input Monitoring"
    case media = "Media"
    case network = "Network"
    case systemPolicy = "System Policy"
    
    var displayName: String { rawValue }
}

// MARK: - PPPC Configuration Model
struct PPPCConfiguration: Identifiable, Hashable {
    let id = UUID()
    var service: PPPCService
    var identifier: String
    var identifierType: PPPCIdentifierType
    var codeRequirement: String?
    var allowed: Bool
    var userOverride: Bool
    var comment: String?
    
    init(service: PPPCService, identifier: String, identifierType: PPPCIdentifierType = .bundleID) {
        self.service = service
        self.identifier = identifier
        self.identifierType = identifierType
        self.allowed = true
        self.userOverride = false
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance 
    static func == (lhs: PPPCConfiguration, rhs: PPPCConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
}

enum PPPCIdentifierType: String, CaseIterable {
    case bundleID = "Bundle Identifier"
    case path = "Path"
    case codeRequirement = "Code Requirement"
    
    var displayName: String { rawValue }
}

// MARK: - App Info Model
struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleID: String
    let path: String
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Sample Data
// PPPC Service Catalog (String Identifiers)
let pppcServiceCatalog: [String] = [
    "Camera","Microphone","ScreenCapture","AppleEvents",
    "SystemPolicyAllFiles","SystemPolicyDownloadsFolder",
    "SystemPolicyDesktopFolder","SystemPolicyDocumentsFolder",
    "Accessibility"
]

// Comprehensive PPPC Services
let pppcServices: [PPPCService] = [
    // System Services
    PPPCService(id: "SystemPolicyAllFiles", name: "Full Disk Access", description: "Allows the app to access all files on your Mac - commonly needed for security tools, backup apps, and file managers", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "SystemPolicyDownloadsFolder", name: "Downloads Folder Access", description: "Lets the app read and write files in your Downloads folder - useful for apps that download or process files", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "SystemPolicyDesktopFolder", name: "Desktop Folder Access", description: "Allows the app to access files on your Desktop - helpful for apps that need to work with desktop files", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "SystemPolicyDocumentsFolder", name: "Documents Folder Access", description: "Gives the app access to your Documents folder - needed for document editors and file organizers", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    
    // Accessibility Services
    PPPCService(id: "Accessibility", name: "Accessibility Control", description: "Allows the app to control other apps and system features - essential for automation tools, screen readers, and accessibility apps", category: .accessibility, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "InputMonitoring", name: "Input Monitoring", description: "Lets the app see what you type and click - needed for password managers, automation tools, and security software", category: .inputMonitoring, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    
    // Media Services
    PPPCService(id: "Camera", name: "Camera Access", description: "Allows the app to use your Mac's camera - needed for video chat apps, photo apps, and security cameras", category: .media, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "Microphone", name: "Microphone Access", description: "Lets the app record audio from your microphone - required for voice chat, recording apps, and speech recognition", category: .media, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "ScreenCapture", name: "Screen Recording", description: "Allows the app to record your screen or take screenshots - needed for tutorials, presentations, and security monitoring", category: .media, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    
    // Automation Services
    PPPCService(id: "AppleEvents", name: "Apple Events", description: "Lets the app control other applications - essential for automation tools, workflow apps, and productivity software", category: .automation, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    
    // Network Services
    PPPCService(id: "NetworkExtension", name: "Network Configuration", description: "Allows the app to configure network settings and VPN connections - needed for network management tools and VPN apps", category: .network, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    
    // Additional System Services
    PPPCService(id: "SystemPolicyRemovableVolumes", name: "Removable Drive Access", description: "Lets the app access USB drives, SD cards, and other removable storage - useful for backup tools and file managers", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "SystemPolicySysAdminFiles", name: "System Files Access", description: "Allows the app to access system administration files - needed for system utilities and development tools", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true)
]

// All Payloads Library
let allPayloadsLibrary: [Payload] = [
    // MARK: - Security & Privacy
    .init(id: "filevault2", name: "FileVault 2", description: "Configure FileVault 2 disk encryption settings", platforms: ["macOS"], icon: "🔐", category: "Security"),
    .init(id: "gatekeeper", name: "Gatekeeper", description: "Control application execution policies", platforms: ["macOS"], icon: "🚪", category: "Security"),
    .init(id: "firewall", name: "Firewall", description: "Configure macOS firewall settings", platforms: ["macOS"], icon: "🛡️", category: "Security"),
    .init(id: "systemIntegrity", name: "System Integrity", description: "Kernel extension and system policy controls", platforms: ["macOS"], icon: "🛡️", category: "Security"),
    .init(id: "codeSigning", name: "Code Signing", description: "Application code signing policies", platforms: ["macOS"], icon: "✍️", category: "Security"),
    .init(id: "pppc", name: "Privacy Preferences", description: "PPPC (TCC) permissions and privacy controls", platforms: ["macOS"], icon: "🔒", category: "Security"),
    .init(id: "tcc", name: "TCC Controls", description: "Transparency, Consent, and Control settings", platforms: ["macOS", "iOS"], icon: "👁️", category: "Security"),
    .init(id: "restrictions", name: "Device Restrictions", description: "General device and application restrictions", platforms: ["iOS", "macOS", "tvOS"], icon: "🚫", category: "Security"),
    
    // MARK: - Network & Connectivity
    .init(id: "wifi", name: "Wi-Fi", description: "Configure Wi-Fi network settings and profiles", platforms: ["iOS", "macOS", "tvOS"], icon: "📶", category: "Network"),
    .init(id: "vpn", name: "VPN", description: "Virtual Private Network configuration", platforms: ["iOS", "macOS", "tvOS"], icon: "🔒", category: "Network"),
    .init(id: "proxy", name: "Proxy", description: "HTTP and HTTPS proxy configuration", platforms: ["iOS", "macOS", "tvOS"], icon: "🌐", category: "Network"),
    .init(id: "ethernet", name: "Ethernet", description: "Wired network configuration", platforms: ["macOS"], icon: "🔌", category: "Network"),
    .init(id: "cellular", name: "Cellular", description: "Cellular network settings", platforms: ["iOS"], icon: "📱", category: "Network"),
    
    // MARK: - Application Management
    .init(id: "appStore", name: "App Store", description: "App Store access and installation controls", platforms: ["iOS", "macOS"], icon: "🛒", category: "Applications"),
    .init(id: "appRestrictions", name: "App Restrictions", description: "Application functionality and feature restrictions", platforms: ["iOS", "macOS"], icon: "🚫", category: "Applications"),
    .init(id: "appUpdates", name: "App Updates", description: "Automatic application update policies", platforms: ["iOS", "macOS"], icon: "🔄", category: "Applications"),
    .init(id: "appInstallation", name: "App Installation", description: "Application installation policies", platforms: ["iOS", "macOS"], icon: "📦", category: "Applications"),
    
    // MARK: - System Settings
    .init(id: "loginWindow", name: "Login Window", description: "Login window appearance and behavior", platforms: ["macOS"], icon: "🖥️", category: "System"),
    .init(id: "energySaver", name: "Energy Saver", description: "Power management and energy saving settings", platforms: ["macOS"], icon: "🔋", category: "System"),
    .init(id: "notifications", name: "Notifications", description: "System and application notification settings", platforms: ["iOS", "macOS"], icon: "🔔", category: "System"),
    .init(id: "dock", name: "Dock", description: "Dock appearance and behavior configuration", platforms: ["macOS"], icon: "⚓", category: "System"),
    .init(id: "finder", name: "Finder", description: "Finder preferences and sidebar configuration", platforms: ["macOS"], icon: "📁", category: "System"),
    
    // MARK: - User Restrictions
    .init(id: "userRestrictions", name: "User Restrictions", description: "User-level application and feature restrictions", platforms: ["iOS", "macOS"], icon: "👤", category: "Restrictions"),
    .init(id: "deviceRestrictions", name: "Device Restrictions", description: "Device-level restrictions and limitations", platforms: ["iOS", "macOS"], icon: "📱", category: "Restrictions"),
    .init(id: "webContent", name: "Web Content Filter", description: "Web content filtering and access controls", platforms: ["iOS", "macOS"], icon: "🌍", category: "Restrictions"),
    .init(id: "mediaAccess", name: "Media Access", description: "Media library and camera roll access controls", platforms: ["iOS", "macOS"], icon: "📸", category: "Restrictions"),
    .init(id: "gameCenter", name: "Game Center", description: "Game Center access and multiplayer controls", platforms: ["iOS", "macOS"], icon: "🎮", category: "Restrictions"),
    
    // MARK: - Enterprise Features
    .init(id: "ldap", name: "LDAP", description: "Lightweight Directory Access Protocol configuration", platforms: ["macOS"], icon: "🏢", category: "Enterprise"),
    .init(id: "exchange", name: "Exchange", description: "Microsoft Exchange account configuration", platforms: ["iOS", "macOS"], icon: "📧", category: "Enterprise"),
    .init(id: "caldav", name: "CalDAV", description: "CalDAV calendar synchronization", platforms: ["iOS", "macOS"], icon: "📅", category: "Enterprise"),
    .init(id: "carddav", name: "CardDAV", description: "CardDAV contact synchronization", platforms: ["iOS", "macOS"], icon: "👥", category: "Enterprise"),
    .init(id: "webClip", name: "Web Clips", description: "Web application shortcuts and bookmarks", platforms: ["iOS"], icon: "📱", category: "Enterprise")
]

// Enhanced Template Library
let templatesLibrary: [TemplateProfile] = [
    .init(name: "Security Baseline", description: "Essential security settings for enterprise devices", payloadIDs: ["restrictions", "firewall", "filevault2", "pppc"]),
    .init(name: "Network Configuration", description: "Wi-Fi and VPN settings for network management", payloadIDs: ["wifi", "vpn"]),
    .init(name: "Antivirus & EDR", description: "Security tool permissions with PPPC configuration", payloadIDs: ["pppc"]),
    .init(name: "Development Tools", description: "Developer-friendly permissions for coding apps", payloadIDs: ["pppc"]),
    .init(name: "Media & Communication", description: "Camera, microphone, and screen sharing permissions", payloadIDs: ["pppc"]),
    .init(name: "File Management", description: "Full disk access and folder permissions", payloadIDs: ["pppc"]),
    .init(name: "Enterprise Standard", description: "Standard enterprise configuration with LDAP and Exchange", payloadIDs: ["ldap", "exchange", "wifi", "vpn"]),
    .init(name: "K-12 Education", description: "Educational device restrictions and content filtering", payloadIDs: ["webContent", "appRestrictions", "userRestrictions"]),
    .init(name: "Healthcare Compliance", description: "HIPAA-compliant device security and privacy", payloadIDs: ["filevault2", "pppc", "restrictions", "firewall"]),
    .init(name: "Financial Services", description: "High-security configuration for financial institutions", payloadIDs: ["filevault2", "gatekeeper", "firewall", "pppc", "restrictions"])
]

let categories: [String] = ["All","Network","Security","User Experience","Applications","Accounts","Certificates"]

// MARK: - MDM Vendor
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

// MARK: - JAMF Authentication Result
enum JamfAuthResult {
    case success(baseURL: URL, clientID: String, clientSecret: String)
    case failure(Error)
    case cancelled
}

// MARK: - MDM Account
struct MDMAccount: Codable, Identifiable, Hashable {
    var id = UUID()
    var vendor: String
    var serverURL: String
    var username: String
    var displayName: String
    var lastUsed: Date
    var isDefault: Bool
    var authToken: String?
    var tokenExpiry: Date?
    
    init(vendor: String, serverURL: String, username: String, displayName: String) {
        self.vendor = vendor
        self.serverURL = serverURL
        self.username = username
        self.displayName = displayName
        self.lastUsed = Date()
        self.isDefault = false
        self.authToken = nil
        self.tokenExpiry = nil
    }
}

