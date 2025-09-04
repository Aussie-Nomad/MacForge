import Foundation

// MARK: - DDM Blueprint Models

/// Represents a DDM Blueprint template for device configuration
struct DDMBlueprint: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var description: String
    var category: BlueprintCategory
    var version: String
    var author: String
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var isTemplate: Bool
    var isPublic: Bool
    var configuration: BlueprintConfiguration
    var metadata: BlueprintMetadata
    
    init(
        name: String,
        description: String,
        category: BlueprintCategory,
        version: String = "1.0.0",
        author: String = "MacForge User",
        tags: [String] = [],
        isTemplate: Bool = false,
        isPublic: Bool = false,
        configuration: BlueprintConfiguration = BlueprintConfiguration()
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.category = category
        self.version = version
        self.author = author
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = tags
        self.isTemplate = isTemplate
        self.isPublic = isPublic
        self.configuration = configuration
        self.metadata = BlueprintMetadata()
    }
}

/// Categories for organizing blueprints
enum BlueprintCategory: String, CaseIterable, Codable, Hashable {
    case deviceManagement = "Device Management"
    case security = "Security"
    case network = "Network"
    case applications = "Applications"
    case userExperience = "User Experience"
    case compliance = "Compliance"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .deviceManagement: return "laptopcomputer"
        case .security: return "lock.shield"
        case .network: return "network"
        case .applications: return "app.badge"
        case .userExperience: return "person.crop.circle"
        case .compliance: return "checkmark.shield"
        case .custom: return "wrench.and.screwdriver"
        }
    }
    
    var color: String {
        switch self {
        case .deviceManagement: return "blue"
        case .security: return "red"
        case .network: return "green"
        case .applications: return "purple"
        case .userExperience: return "orange"
        case .compliance: return "indigo"
        case .custom: return "gray"
        }
    }
}

/// Core configuration structure for a blueprint
struct BlueprintConfiguration: Codable, Equatable, Hashable {
    var deviceSettings: DeviceSettings
    var securityPolicies: SecurityPolicies
    var networkConfigurations: NetworkConfigurations
    var applicationSettings: ApplicationSettings
    var userPreferences: UserPreferences
    var complianceRules: ComplianceRules
    
    init() {
        self.deviceSettings = DeviceSettings()
        self.securityPolicies = SecurityPolicies()
        self.networkConfigurations = NetworkConfigurations()
        self.applicationSettings = ApplicationSettings()
        self.userPreferences = UserPreferences()
        self.complianceRules = ComplianceRules()
    }
}

// MARK: - Device Settings

struct DeviceSettings: Codable, Equatable, Hashable {
    var deviceName: String?
    var deviceModel: String?
    var serialNumber: String?
    var assetTag: String?
    var location: String?
    var department: String?
    var user: String?
    var enrollmentDate: Date?
    var warrantyExpiration: Date?
    var customFields: [String: String]
    
    init() {
        self.customFields = [:]
    }
}

// MARK: - Security Policies

struct SecurityPolicies: Codable, Equatable, Hashable {
    var passcodePolicy: PasscodePolicy
    var encryptionSettings: EncryptionSettings
    var firewallRules: FirewallRules
    var vpnConfiguration: VPNConfiguration
    var certificateSettings: CertificateSettings
    var privacySettings: PrivacySettings
    
    init() {
        self.passcodePolicy = PasscodePolicy()
        self.encryptionSettings = EncryptionSettings()
        self.firewallRules = FirewallRules()
        self.vpnConfiguration = VPNConfiguration()
        self.certificateSettings = CertificateSettings()
        self.privacySettings = PrivacySettings()
    }
}

struct PasscodePolicy: Codable, Equatable, Hashable {
    var requirePasscode: Bool
    var minimumLength: Int
    var requireComplexity: Bool
    var maximumFailedAttempts: Int
    var lockoutDuration: Int // minutes
    var requireBiometric: Bool
    var allowSimplePasscode: Bool
    
    init() {
        self.requirePasscode = true
        self.minimumLength = 6
        self.requireComplexity = false
        self.maximumFailedAttempts = 5
        self.lockoutDuration = 15
        self.requireBiometric = false
        self.allowSimplePasscode = true
    }
}

struct EncryptionSettings: Codable, Equatable, Hashable {
    var requireFileVault: Bool
    var requireDataProtection: Bool
    var encryptionLevel: EncryptionLevel
    var keyRecoveryEnabled: Bool
    
    init() {
        self.requireFileVault = true
        self.requireDataProtection = true
        self.encryptionLevel = .aes256
        self.keyRecoveryEnabled = false
    }
}

enum EncryptionLevel: String, CaseIterable, Codable, Hashable {
    case aes128 = "AES-128"
    case aes256 = "AES-256"
    case aes512 = "AES-512"
}

struct FirewallRules: Codable, Equatable, Hashable {
    var enableFirewall: Bool
    var blockIncomingConnections: Bool
    var allowSignedApplications: Bool
    var stealthMode: Bool
    var customRules: [FirewallRule]
    
    init() {
        self.enableFirewall = true
        self.blockIncomingConnections = true
        self.allowSignedApplications = true
        self.stealthMode = false
        self.customRules = []
    }
}

struct FirewallRule: Codable, Equatable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var action: FirewallAction
    var direction: FirewallDirection
    var protocolType: FirewallProtocol
    var port: Int?
    var sourceAddress: String?
    var destinationAddress: String?
    var application: String?
    
    init(
        name: String,
        action: FirewallAction,
        direction: FirewallDirection,
        protocolType: FirewallProtocol,
        port: Int? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.action = action
        self.direction = direction
        self.protocolType = protocolType
        self.port = port
    }
}

enum FirewallAction: String, CaseIterable, Codable, Hashable {
    case allow = "Allow"
    case deny = "Deny"
    case reject = "Reject"
}

enum FirewallDirection: String, CaseIterable, Codable, Hashable {
    case inbound = "Inbound"
    case outbound = "Outbound"
    case both = "Both"
}

enum FirewallProtocol: String, CaseIterable, Codable, Hashable {
    case tcp = "TCP"
    case udp = "UDP"
    case icmp = "ICMP"
    case any = "Any"
}

struct VPNConfiguration: Codable, Equatable, Hashable {
    var enabled: Bool
    var connectionName: String?
    var serverAddress: String?
    var authenticationMethod: VPNAuthenticationMethod
    var username: String?
    var certificate: String?
    var sharedSecret: String?
    var onDemand: Bool
    var splitTunnel: Bool
    
    init() {
        self.enabled = false
        self.authenticationMethod = .password
        self.onDemand = false
        self.splitTunnel = false
    }
}

enum VPNAuthenticationMethod: String, CaseIterable, Codable, Hashable {
    case password = "Password"
    case certificate = "Certificate"
    case sharedSecret = "Shared Secret"
    case both = "Certificate + Password"
}

struct CertificateSettings: Codable, Equatable, Hashable {
    var installCertificates: Bool
    var certificates: [DDMCertificateInfo]
    var trustSettings: TrustSettings
    
    init() {
        self.installCertificates = false
        self.certificates = []
        self.trustSettings = TrustSettings()
    }
}

struct DDMCertificateInfo: Codable, Equatable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var issuer: String
    var subject: String
    var validFrom: Date
    var validTo: Date
    var fingerprint: String
    var purpose: CertificatePurpose
    
    init(name: String, issuer: String, subject: String) {
        self.id = UUID()
        self.name = name
        self.issuer = issuer
        self.subject = subject
        self.validFrom = Date()
        self.validTo = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year
        self.fingerprint = ""
        self.purpose = .authentication
    }
}

enum CertificatePurpose: String, CaseIterable, Codable, Hashable {
    case authentication = "Authentication"
    case encryption = "Encryption"
    case signing = "Code Signing"
    case ssl = "SSL/TLS"
    case email = "Email"
}

struct TrustSettings: Codable, Equatable, Hashable {
    var trustSystemRoots: Bool
    var trustUserRoots: Bool
    var customTrustPolicies: [TrustPolicy]
    
    init() {
        self.trustSystemRoots = true
        self.trustUserRoots = false
        self.customTrustPolicies = []
    }
}

struct TrustPolicy: Codable, Equatable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var certificateFingerprint: String
    var trustLevel: TrustLevel
    var purpose: CertificatePurpose
    
    init(name: String, certificateFingerprint: String, trustLevel: TrustLevel) {
        self.id = UUID()
        self.name = name
        self.certificateFingerprint = certificateFingerprint
        self.trustLevel = trustLevel
        self.purpose = .authentication
    }
}

enum TrustLevel: String, CaseIterable, Codable, Hashable {
    case trusted = "Trusted"
    case untrusted = "Untrusted"
    case unknown = "Unknown"
}

struct PrivacySettings: Codable, Equatable, Hashable {
    var locationServices: Bool
    var cameraAccess: Bool
    var microphoneAccess: Bool
    var contactsAccess: Bool
    var calendarAccess: Bool
    var photosAccess: Bool
    var customPrivacyRules: [PrivacyRule]
    
    init() {
        self.locationServices = false
        self.cameraAccess = false
        self.microphoneAccess = false
        self.contactsAccess = false
        self.calendarAccess = false
        self.photosAccess = false
        self.customPrivacyRules = []
    }
}

struct PrivacyRule: Codable, Equatable, Identifiable, Hashable {
    let id: UUID
    var application: String
    var permission: PrivacyPermission
    var accessLevel: PrivacyAccessLevel
    var justification: String
    
    init(application: String, permission: PrivacyPermission, accessLevel: PrivacyAccessLevel) {
        self.id = UUID()
        self.application = application
        self.permission = permission
        self.accessLevel = accessLevel
        self.justification = ""
    }
}

enum PrivacyPermission: String, CaseIterable, Codable, Hashable {
    case location = "Location"
    case camera = "Camera"
    case microphone = "Microphone"
    case contacts = "Contacts"
    case calendar = "Calendar"
    case photos = "Photos"
    case files = "Files"
    case network = "Network"
}

enum PrivacyAccessLevel: String, CaseIterable, Codable, Hashable {
    case allow = "Allow"
    case deny = "Deny"
    case ask = "Ask"
}

// MARK: - Network Configurations

struct NetworkConfigurations: Codable, Equatable, Hashable {
    var wifiSettings: WiFiSettings
    var ethernetSettings: EthernetSettings
    var proxySettings: ProxySettings
    var dnsSettings: DNSSettings
    
    init() {
        self.wifiSettings = WiFiSettings()
        self.ethernetSettings = EthernetSettings()
        self.proxySettings = ProxySettings()
        self.dnsSettings = DNSSettings()
    }
}

struct WiFiSettings: Codable, Equatable, Hashable {
    var autoJoin: Bool
    var networks: [WiFiNetwork]
    var preferredNetworks: [String]
    
    init() {
        self.autoJoin = true
        self.networks = []
        self.preferredNetworks = []
    }
}

struct WiFiNetwork: Codable, Equatable, Identifiable, Hashable {
    let id: UUID
    var ssid: String
    var securityType: WiFiSecurityType
    var password: String?
    var hidden: Bool
    var autoJoin: Bool
    var priority: Int
    
    init(ssid: String, securityType: WiFiSecurityType) {
        self.id = UUID()
        self.ssid = ssid
        self.securityType = securityType
        self.hidden = false
        self.autoJoin = true
        self.priority = 0
    }
}

enum WiFiSecurityType: String, CaseIterable, Codable, Hashable {
    case none = "None"
    case wep = "WEP"
    case wpa = "WPA"
    case wpa2 = "WPA2"
    case wpa3 = "WPA3"
    case enterprise = "Enterprise"
}

struct EthernetSettings: Codable, Equatable, Hashable {
    var autoConfigure: Bool
    var ipAddress: String?
    var subnetMask: String?
    var router: String?
    var dnsServers: [String]
    
    init() {
        self.autoConfigure = true
        self.dnsServers = []
    }
}

struct ProxySettings: Codable, Equatable, Hashable {
    var enabled: Bool
    var type: ProxyType
    var server: String?
    var port: Int?
    var username: String?
    var password: String?
    var bypassList: [String]
    
    init() {
        self.enabled = false
        self.type = .http
        self.bypassList = []
    }
}

enum ProxyType: String, CaseIterable, Codable, Hashable {
    case http = "HTTP"
    case https = "HTTPS"
    case socks4 = "SOCKS4"
    case socks5 = "SOCKS5"
    case auto = "Auto"
}

struct DNSSettings: Codable, Equatable, Hashable {
    var servers: [String]
    var searchDomains: [String]
    var order: [String]
    
    init() {
        self.servers = ["8.8.8.8", "8.8.4.4"] // Google DNS
        self.searchDomains = []
        self.order = []
    }
}

// MARK: - Application Settings

struct ApplicationSettings: Codable, Equatable, Hashable {
    var allowedApplications: [String]
    var blockedApplications: [String]
    var requiredApplications: [String]
    var applicationRestrictions: [ApplicationRestriction]
    var appStoreSettings: AppStoreSettings
    
    init() {
        self.allowedApplications = []
        self.blockedApplications = []
        self.requiredApplications = []
        self.applicationRestrictions = []
        self.appStoreSettings = AppStoreSettings()
    }
}

struct ApplicationRestriction: Codable, Equatable, Identifiable, Hashable {
    let id: UUID
    var application: String
    var restrictionType: ApplicationRestrictionType
    var parameters: [String: String]
    
    init(application: String, restrictionType: ApplicationRestrictionType) {
        self.id = UUID()
        self.application = application
        self.restrictionType = restrictionType
        self.parameters = [:]
    }
}

enum ApplicationRestrictionType: String, CaseIterable, Codable, Hashable {
    case timeLimit = "Time Limit"
    case contentFilter = "Content Filter"
    case networkAccess = "Network Access"
    case fileAccess = "File Access"
    case printing = "Printing"
    case camera = "Camera Access"
    case microphone = "Microphone Access"
}

struct AppStoreSettings: Codable, Equatable, Hashable {
    var allowAppStore: Bool
    var allowInAppPurchases: Bool
    var requirePassword: Bool
    var allowedCategories: [AppStoreCategory]
    var blockedCategories: [AppStoreCategory]
    
    init() {
        self.allowAppStore = true
        self.allowInAppPurchases = true
        self.requirePassword = false
        self.allowedCategories = []
        self.blockedCategories = []
    }
}

enum AppStoreCategory: String, CaseIterable, Codable, Hashable {
    case business = "Business"
    case developer = "Developer Tools"
    case education = "Education"
    case entertainment = "Entertainment"
    case finance = "Finance"
    case games = "Games"
    case graphics = "Graphics & Design"
    case lifestyle = "Lifestyle"
    case medical = "Medical"
    case music = "Music"
    case news = "News"
    case productivity = "Productivity"
    case reference = "Reference"
    case social = "Social Networking"
    case sports = "Sports"
    case travel = "Travel"
    case utilities = "Utilities"
    case weather = "Weather"
}

// MARK: - User Preferences

struct UserPreferences: Codable, Equatable, Hashable {
    var desktopSettings: DesktopSettings
    var dockSettings: DockSettings
    var menuBarSettings: MenuBarSettings
    var systemPreferences: SystemPreferences
    var accessibilitySettings: AccessibilitySettings
    
    init() {
        self.desktopSettings = DesktopSettings()
        self.dockSettings = DockSettings()
        self.menuBarSettings = MenuBarSettings()
        self.systemPreferences = SystemPreferences()
        self.accessibilitySettings = AccessibilitySettings()
    }
}

struct DesktopSettings: Codable, Equatable, Hashable {
    var wallpaper: String?
    var screenSaver: String?
    var screenSaverTimeout: Int // minutes
    var showDesktopIcons: Bool
    var iconSize: Int
    
    init() {
        self.screenSaverTimeout = 20
        self.showDesktopIcons = true
        self.iconSize = 64
    }
}

struct DockSettings: Codable, Equatable, Hashable {
    var position: DockPosition
    var size: Int
    var magnification: Bool
    var magnificationSize: Int
    var minimizeEffect: MinimizeEffect
    var showRecentApplications: Bool
    
    init() {
        self.position = .bottom
        self.size = 64
        self.magnification = false
        self.magnificationSize = 128
        self.minimizeEffect = .genie
        self.showRecentApplications = true
    }
}

enum DockPosition: String, CaseIterable, Codable, Hashable {
    case left = "Left"
    case bottom = "Bottom"
    case right = "Right"
}

enum MinimizeEffect: String, CaseIterable, Codable, Hashable {
    case genie = "Genie"
    case scale = "Scale"
    case suck = "Suck"
}

struct MenuBarSettings: Codable, Equatable, Hashable {
    var showBatteryPercentage: Bool
    var showBluetooth: Bool
    var showWiFi: Bool
    var showVolume: Bool
    var showClock: Bool
    var clockFormat: ClockFormat
    var showDate: Bool
    
    init() {
        self.showBatteryPercentage = false
        self.showBluetooth = true
        self.showWiFi = true
        self.showVolume = true
        self.showClock = true
        self.clockFormat = .twelveHour
        self.showDate = false
    }
}

enum ClockFormat: String, CaseIterable, Codable, Hashable {
    case twelveHour = "12 Hour"
    case twentyFourHour = "24 Hour"
}

struct SystemPreferences: Codable, Equatable, Hashable {
    var allowSystemPreferences: Bool
    var allowedPanes: [String]
    var blockedPanes: [String]
    var requirePassword: Bool
    
    init() {
        self.allowSystemPreferences = true
        self.allowedPanes = []
        self.blockedPanes = []
        self.requirePassword = false
    }
}

struct AccessibilitySettings: Codable, Equatable, Hashable {
    var voiceOver: Bool
    var zoom: Bool
    var highContrast: Bool
    var reduceMotion: Bool
    var increaseContrast: Bool
    var reduceTransparency: Bool
    var largeText: Bool
    
    init() {
        self.voiceOver = false
        self.zoom = false
        self.highContrast = false
        self.reduceMotion = false
        self.increaseContrast = false
        self.reduceTransparency = false
        self.largeText = false
    }
}

// MARK: - Compliance Rules

struct ComplianceRules: Codable, Equatable, Hashable {
    var deviceCompliance: [ComplianceRule]
    var applicationCompliance: [ComplianceRule]
    var networkCompliance: [ComplianceRule]
    var securityCompliance: [ComplianceRule]
    
    init() {
        self.deviceCompliance = []
        self.applicationCompliance = []
        self.networkCompliance = []
        self.securityCompliance = []
    }
}

struct ComplianceRule: Codable, Equatable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var category: ComplianceCategory
    var severity: ComplianceSeverity
    var condition: ComplianceCondition
    var action: ComplianceAction
    var isEnabled: Bool
    
    init(
        name: String,
        description: String,
        category: ComplianceCategory,
        severity: ComplianceSeverity,
        condition: ComplianceCondition,
        action: ComplianceAction
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.category = category
        self.severity = severity
        self.condition = condition
        self.action = action
        self.isEnabled = true
    }
}

enum ComplianceCategory: String, CaseIterable, Codable, Hashable {
    case device = "Device"
    case application = "Application"
    case network = "Network"
    case security = "Security"
    case user = "User"
    case data = "Data"
}

enum ComplianceSeverity: String, CaseIterable, Codable, Hashable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

struct ComplianceCondition: Codable, Equatable, Hashable {
    var type: ComplianceConditionType
    var parameter: String
    var operatorType: ComplianceOperator
    var value: String
    
    init(type: ComplianceConditionType, parameter: String, operatorType: ComplianceOperator, value: String) {
        self.type = type
        self.parameter = parameter
        self.operatorType = operatorType
        self.value = value
    }
}

enum ComplianceConditionType: String, CaseIterable, Codable, Hashable {
    case deviceProperty = "Device Property"
    case applicationInstalled = "Application Installed"
    case networkConnection = "Network Connection"
    case securitySetting = "Security Setting"
    case userAction = "User Action"
    case timeBased = "Time Based"
}

enum ComplianceOperator: String, CaseIterable, Codable, Hashable {
    case equals = "Equals"
    case notEquals = "Not Equals"
    case contains = "Contains"
    case notContains = "Not Contains"
    case greaterThan = "Greater Than"
    case lessThan = "Less Than"
    case isTrue = "Is True"
    case isFalse = "Is False"
}

struct ComplianceAction: Codable, Equatable, Hashable {
    var type: ComplianceActionType
    var parameters: [String: String]
    var delay: Int // seconds
    
    init(type: ComplianceActionType, parameters: [String: String] = [:], delay: Int = 0) {
        self.type = type
        self.parameters = parameters
        self.delay = delay
    }
}

enum ComplianceActionType: String, CaseIterable, Codable, Hashable {
    case notify = "Notify"
    case lock = "Lock Device"
    case wipe = "Wipe Device"
    case quarantine = "Quarantine"
    case block = "Block Access"
    case allow = "Allow Access"
    case log = "Log Event"
    case escalate = "Escalate"
}

// MARK: - Blueprint Metadata

struct BlueprintMetadata: Codable, Equatable, Hashable {
    var complexity: BlueprintComplexity
    var estimatedDeploymentTime: Int // minutes
    var requiredPermissions: [String]
    var dependencies: [String]
    var compatibility: CompatibilityInfo
    var usage: UsageStatistics
    var ratings: RatingInfo
    
    init() {
        self.complexity = .medium
        self.estimatedDeploymentTime = 15
        self.requiredPermissions = []
        self.dependencies = []
        self.compatibility = CompatibilityInfo()
        self.usage = UsageStatistics()
        self.ratings = RatingInfo()
    }
}

enum BlueprintComplexity: String, CaseIterable, Codable, Hashable {
    case simple = "Simple"
    case medium = "Medium"
    case complex = "Complex"
    case expert = "Expert"
}

struct CompatibilityInfo: Codable, Equatable, Hashable {
    var minimumOSVersion: String
    var maximumOSVersion: String?
    var supportedArchitectures: [String]
    var requiredHardware: [String]
    var incompatibleSoftware: [String]
    
    init() {
        self.minimumOSVersion = "14.0"
        self.supportedArchitectures = ["arm64", "x86_64"]
        self.requiredHardware = []
        self.incompatibleSoftware = []
    }
}

struct UsageStatistics: Codable, Equatable, Hashable {
    var downloadCount: Int
    var deploymentCount: Int
    var successRate: Double
    var averageDeploymentTime: Int // minutes
    var lastUsed: Date?
    
    init() {
        self.downloadCount = 0
        self.deploymentCount = 0
        self.successRate = 0.0
        self.averageDeploymentTime = 0
    }
}

struct RatingInfo: Codable, Equatable, Hashable {
    var averageRating: Double
    var totalRatings: Int
    var ratingDistribution: [Int] // [1-star, 2-star, 3-star, 4-star, 5-star]
    
    init() {
        self.averageRating = 0.0
        self.totalRatings = 0
        self.ratingDistribution = [0, 0, 0, 0, 0]
    }
}

// MARK: - Blueprint Library

struct BlueprintLibrary: Codable, Equatable, Hashable {
    var templates: [DDMBlueprint]
    var userBlueprints: [DDMBlueprint]
    var categories: [BlueprintCategory]
    var tags: [String]
    var lastUpdated: Date
    
    init() {
        self.templates = []
        self.userBlueprints = []
        self.categories = BlueprintCategory.allCases
        self.tags = []
        self.lastUpdated = Date()
    }
}

// MARK: - Blueprint Search and Filter

struct BlueprintSearchCriteria: Codable, Equatable, Hashable {
    var query: String
    var categories: [BlueprintCategory]
    var tags: [String]
    var complexity: [BlueprintComplexity]
    var isTemplate: Bool?
    var isPublic: Bool?
    var author: String?
    var minimumRating: Double?
    var sortBy: BlueprintSortOption
    var sortOrder: SortOrder
    
    init() {
        self.query = ""
        self.categories = []
        self.tags = []
        self.complexity = []
        self.sortBy = .name
        self.sortOrder = .ascending
    }
}

enum BlueprintSortOption: String, CaseIterable, Codable, Hashable {
    case name = "Name"
    case dateCreated = "Date Created"
    case dateUpdated = "Date Updated"
    case rating = "Rating"
    case popularity = "Popularity"
    case complexity = "Complexity"
}

enum SortOrder: String, CaseIterable, Codable, Hashable {
    case ascending = "Ascending"
    case descending = "Descending"
}
