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

// MARK: - AI Provider Type
enum AIProviderType: String, CaseIterable, Identifiable, Codable {
    case openai = "openai"
    case anthropic = "anthropic"
    case ollama = "ollama"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .ollama: return "Ollama"
        case .custom: return "Custom"
        }
    }
}

// MARK: - AI Account
struct AIAccount: Codable, Identifiable, Hashable {
    var id = UUID()
    var provider: AIProviderType
    var displayName: String
    var apiKey: String
    var model: String
    var baseURL: String
    var lastUsed: Date
    var isDefault: Bool
    var isActive: Bool
    
    init(provider: AIProviderType, displayName: String, apiKey: String = "", model: String = "", baseURL: String = "") {
        self.provider = provider
        self.displayName = displayName
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.lastUsed = Date()
        self.isDefault = false
        self.isActive = true
    }
    
    var effectiveBaseURL: String {
        if baseURL.isEmpty {
            switch provider {
            case .openai:
                return "https://api.openai.com/v1"
            case .anthropic:
                return "https://api.anthropic.com/v1"
            case .ollama:
                return "http://localhost:11434"
            case .custom:
                return ""
            }
        }
        return baseURL
    }
    
    var effectiveModel: String {
        if model.isEmpty {
            switch provider {
            case .openai:
                return "gpt-4o-mini"
            case .anthropic:
                return "claude-3-5-sonnet-20240620"
            case .ollama:
                return "codellama:7b-instruct"
            case .custom:
                return ""
            }
        }
        return model
    }
}

// MARK: - Profile Defaults
struct ProfileDefaults: Codable {
    var organization: String
    var identifierPrefix: String
    var description: String
    
    init() {
        self.organization = "Your Organization"
        self.identifierPrefix = "com.yourorganization"
        self.description = "Configuration Profile"
    }
}

// MARK: - Theme Preferences
struct ThemePreferences: Codable, Equatable {
    var selectedTheme: ThemeType
    var accentColor: AccentColor
    var animationSpeed: AnimationSpeed
    
    init() {
        self.selectedTheme = .default
        self.accentColor = .blue
        self.animationSpeed = .normal
    }
}

enum ThemeType: String, CaseIterable, Codable {
    case `default` = "Default"
    case lcars = "LCARS"
    
    var displayName: String { rawValue }
}

enum AccentColor: String, CaseIterable, Codable, Equatable {
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case red = "Red"
    case purple = "Purple"
    case pink = "Pink"
    
    var displayName: String { rawValue }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .pink: return .pink
        }
    }
}

enum AnimationSpeed: String, CaseIterable, Codable, Equatable {
    case slow = "Slow"
    case normal = "Normal"
    case fast = "Fast"
    
    var displayName: String { rawValue }
}

// MARK: - General Settings
struct GeneralSettings: Codable {
    var autoSave: Bool
    var showWelcomeOnLaunch: Bool
    var enableAnalytics: Bool
    var logLevel: LogLevel
    
    init() {
        self.autoSave = true
        self.showWelcomeOnLaunch = true
        self.enableAnalytics = false
        self.logLevel = .info
    }
}

enum LogLevel: String, CaseIterable, Codable {
    case debug = "Debug"
    case info = "Info"
    case warning = "Warning"
    case error = "Error"
    
    var displayName: String { rawValue }
}

// MARK: - User Data Export
struct UserDataExport: Codable {
    let profileDefaults: ProfileDefaults
    let themePreferences: ThemePreferences
    let generalSettings: GeneralSettings
    let mdmAccounts: [MDMAccount]
    let aiAccounts: [AIAccount]
    let exportDate: Date
    let version: String
    
    init(profileDefaults: ProfileDefaults, themePreferences: ThemePreferences, generalSettings: GeneralSettings, mdmAccounts: [MDMAccount], aiAccounts: [AIAccount]) {
        self.profileDefaults = profileDefaults
        self.themePreferences = themePreferences
        self.generalSettings = generalSettings
        self.mdmAccounts = mdmAccounts
        self.aiAccounts = aiAccounts
        self.exportDate = Date()
        self.version = "2.1.1"
    }
}

// MARK: - Tool Module
enum ToolModule: String, CaseIterable, Identifiable {
    case profileBuilder = "Profile Builder"
    case packageCasting = "Package Casting"
    case deviceFoundry = "Device Foundry"
    case ddmBlueprints = "DDM Blueprints"
    case scriptSmelter = "Script Smelter"
    case logBurner = "Log Burner"
    case blacksmith = "The Blacksmith"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .profileBuilder: return "doc.text.fill"
        case .packageCasting: return "shippingbox.fill"
        case .deviceFoundry: return "laptopcomputer"
        case .ddmBlueprints: return "blueprint"
        case .scriptSmelter: return "hammer.fill"
        case .logBurner: return "flame.fill"
        case .blacksmith: return "hammer.circle.fill"
        }
    }
}

// MARK: - Package Script Type
enum PackageScriptType: String, CaseIterable, Identifiable, Codable {
    case preinstall = "Pre-install"
    case postinstall = "Post-install"
    case preuninstall = "Pre-uninstall"
    case postuninstall = "Post-uninstall"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - Package Script
struct PackageScript: Identifiable, Codable {
    var id = UUID()
    var name: String
    var type: PackageScriptType
    var content: String
    var isExecutable: Bool
    var needsModification: Bool
    
    init(name: String, type: PackageScriptType, content: String, isExecutable: Bool = true, needsModification: Bool = false) {
        self.name = name
        self.type = type
        self.content = content
        self.isExecutable = isExecutable
        self.needsModification = needsModification
    }
}

// MARK: - Package Type
enum PackageType: String, CaseIterable, Codable {
    case pkg = "PKG"
    case dmg = "DMG"
    case app = "APP"
    
    var displayName: String { rawValue }
}

// MARK: - File Permission
struct FilePermission: Identifiable, Codable {
    var id = UUID()
    var path: String
    var permission: String
    var recursive: Bool
    
    init(path: String, permission: String, recursive: Bool = false) {
        self.path = path
        self.permission = permission
        self.recursive = recursive
    }
}

// MARK: - Package Analysis Models
struct PackageAnalysis: Codable {
    let fileName: String
    let filePath: String
    let fileSize: Int64
    let packageType: PackageType
    let metadata: PackageMetadata
    let contents: PackageContents
    let securityInfo: SecurityInfo
    let scripts: [PackageScript]
    let dependencies: [PackageDependency]
    let recommendations: [PackageRecommendation]
}

struct PackageMetadata: Codable {
    let bundleIdentifier: String
    let version: String
    let displayName: String
    let description: String
    let author: String
    let installLocation: String
    let minimumOSVersion: String
    let architecture: [String]
    let creationDate: Date
    let modificationDate: Date
}

struct PackageContents: Codable {
    let totalFiles: Int
    let totalSize: Int64
    let installSize: Int64
}

struct SecurityInfo: Codable {
    let isSigned: Bool
    let signatureValid: Bool
    let certificateInfo: CertificateInfo?
}

struct CertificateInfo: Codable {
    let commonName: String
    let organization: String
    let validityStart: Date
    let validityEnd: Date
    let isDeveloperID: Bool
}

struct PackageDependency: Identifiable, Codable {
    var id = UUID()
    let name: String
    let version: String
    let required: Bool
}

struct PackageRecommendation: Identifiable, Codable {
    var id = UUID()
    let type: RecommendationType
    let message: String
    let severity: RecommendationSeverity
}

enum RecommendationType: String, Codable {
    case security = "Security"
    case performance = "Performance"
    case compatibility = "Compatibility"
    case bestPractice = "Best Practice"
}

enum RecommendationSeverity: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

// MARK: - AI Service Models
struct AIServiceConfig: Codable {
    let provider: AIProviderType
    let apiKey: String
    let model: String
    let baseURL: String
    let temperature: Double
    let maxTokens: Int
    
    init(provider: AIProviderType, apiKey: String = "", model: String = "", baseURL: String = "", temperature: Double = 0.7, maxTokens: Int = 2000) {
        self.provider = provider
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.temperature = temperature
        self.maxTokens = maxTokens
    }
}

enum AIError: LocalizedError {
    case invalidConfiguration
    case networkError(Error)
    case apiError(String)
    case rateLimitExceeded
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid AI service configuration"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Invalid response from AI service"
        }
    }
}

// MARK: - LCARS Theme
struct LCARSTheme {
    static let primary = Color(red: 0.0, green: 0.2, blue: 0.4)
    static let secondary = Color(red: 0.8, green: 0.4, blue: 0.0)
    static let accent = Color(red: 0.0, green: 0.8, blue: 0.8)
    static let background = Color(red: 0.0, green: 0.0, blue: 0.1)
    static let surface = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    static func accentColor(for themePreferences: ThemePreferences) -> Color {
        return themePreferences.accentColor.color
    }
}

// MARK: - Lcars Theme (Alternative naming)
typealias LcarsTheme = LCARSTheme

// MARK: - Lcars Header
struct LcarsHeader: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(color, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Themed Field
struct ThemedField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// MARK: - Text Extensions
extension Text {
    func lcarsPill(color: Color = .blue) -> some View {
        self
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
            )
    }
}

// MARK: - View Extensions
extension View {
    func themeAwareBackground() -> some View {
        self.background(Color(.controlBackgroundColor))
    }
}

// MARK: - Lcars Panel
struct LcarsPanel<Content: View>: View {
    let color: Color
    let content: Content
    
    init(color: Color, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color, lineWidth: 2)
                )
        )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let color: Color
    
    var body: some View {
        LcarsHeader(title: title, color: color)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Work Item
struct WorkItem: View {
    let title: String
    let status: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(status)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor.opacity(0.2))
                )
        }
    }
    
    private var statusColor: Color {
        switch status {
        case "COMPLETED": return .green
        case "IN PROGRESS": return .orange
        case "NEXT": return .blue
        case "PENDING": return .gray
        default: return .gray
        }
    }
}

// MARK: - Issue Item
struct IssueItem: View {
    let title: String
    let severity: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(severity)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                )
        }
    }
}

// MARK: - Contact Button
struct ContactButton: View {
    let title: String
    let destination: String
    let color: Color
    
    var body: some View {
        Button(action: {
            if let url = URL(string: destination) {
                NSWorkspace.shared.open(url)
            }
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Animated Background
struct AnimatedBackground: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.0, blue: 0.1),
                        Color(red: 0.0, green: 0.1, blue: 0.2),
                        Color(red: 0.0, green: 0.0, blue: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Animated particles
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: CGFloat.random(in: 2...8))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: animationOffset + CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            Animation.linear(duration: Double.random(in: 10...20))
                                .repeatForever(autoreverses: false),
                            value: animationOffset
                        )
                }
            }
        }
        .onAppear {
            animationOffset = -1000
        }
    }
}

