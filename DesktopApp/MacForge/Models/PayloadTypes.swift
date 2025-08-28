//
//  PayloadTypes.swift
//  MacForge
//
//  Comprehensive Apple MDM payload types with clear descriptions and categories.
//  Inspired by Jamf Pro Policy Editor Lite for intuitive user experience.
//

import Foundation

// MARK: - Payload Category
enum PayloadCategory: String, CaseIterable {
    case all = "All"
    case security = "Security"
    case network = "Network"
    case privacy = "Privacy"
    case applications = "Applications"
    case system = "System"
    case restrictions = "Restrictions"
    case enterprise = "Enterprise"
    
    var displayName: String {
        switch self {
        case .all: return "All Categories"
        case .security: return "Security & Privacy"
        case .network: return "Network & Connectivity"
        case .privacy: return "Privacy & TCC"
        case .applications: return "App Management"
        case .system: return "System Settings"
        case .restrictions: return "User Restrictions"
        case .enterprise: return "Enterprise Features"
        }
    }
    
    var description: String {
        switch self {
        case .all: return "Browse all available payload types"
        case .security: return "FileVault, Gatekeeper, Firewall, and security policies"
        case .network: return "Wi-Fi, VPN, Proxy, and network configuration"
        case .privacy: return "PPPC, TCC, and privacy preference controls"
        case .applications: return "App installation, updates, and restrictions"
        case .system: return "Login, energy, notifications, and system preferences"
        case .restrictions: return "User limitations and access controls"
        case .enterprise: return "Advanced enterprise management features"
        }
    }
}

// MARK: - Payload Type
enum PayloadType: String, CaseIterable, Hashable {
    // MARK: - Security Payloads
    case fileVault = "com.apple.MCX.FileVault2"
    case gatekeeper = "com.apple.syspolicy.gatekeeper"
    case firewall = "com.apple.security.firewall"
    case systemIntegrity = "com.apple.syspolicy.kernel-extension-policy"
    case codeSigning = "com.apple.syspolicy.code-signing"
    
    // MARK: - Network Payloads
    case wifi = "com.apple.wifi.managed"
    case vpn = "com.apple.vpn.managed"
    case proxy = "com.apple.proxy.http.global"
    case ethernet = "com.apple.ethernet.managed"
    case cellular = "com.apple.cellular"
    
    // MARK: - Privacy Payloads
    case pppc = "com.apple.TCC.configuration-profile-policy"
    case tcc = "com.apple.TCC.transparency-control"
    case location = "com.apple.locationd"
    case contacts = "com.apple.contacts"
    case calendar = "com.apple.calendar"
    
    // MARK: - Application Payloads
    case appStore = "com.apple.app.lock"
    case appRestrictions = "com.apple.applicationaccess"
    case appUpdates = "com.apple.softwareupdate.policy"
    case appInstallation = "com.apple.softwareupdate.installation"
    case appRemoval = "com.apple.applicationaccess.removal"
    
    // MARK: - System Payloads
    case loginWindow = "com.apple.loginwindow"
    case energySaver = "com.apple.energysaver"
    case notifications = "com.apple.notificationsettings"
    case dock = "com.apple.dock"
    case finder = "com.apple.finder"
    
    // MARK: - Restriction Payloads
    case userRestrictions = "com.apple.applicationaccess.user"
    case deviceRestrictions = "com.apple.applicationaccess.device"
    case webContent = "com.apple.webcontent-filter"
    case mediaAccess = "com.apple.applicationaccess.media"
    case gameCenter = "com.apple.applicationaccess.gamecenter"
    
    // MARK: - Enterprise Payloads
    case ldap = "com.apple.openldap"
    case exchange = "com.apple.eas"
    case caldav = "com.apple.caldav.account"
    case carddav = "com.apple.carddav.account"
    case webClip = "com.apple.webClip.managed"
    
    var displayName: String {
        switch self {
        case .fileVault: return "FileVault 2 Encryption"
        case .gatekeeper: return "Gatekeeper Security"
        case .firewall: return "Firewall Configuration"
        case .systemIntegrity: return "System Integrity Protection"
        case .codeSigning: return "Code Signing Policy"
        case .wifi: return "Wi-Fi Configuration"
        case .vpn: return "VPN Configuration"
        case .proxy: return "Proxy Settings"
        case .ethernet: return "Ethernet Configuration"
        case .cellular: return "Cellular Settings"
        case .pppc: return "Privacy Preferences Policy Control"
        case .tcc: return "Transparency, Consent, and Control"
        case .location: return "Location Services"
        case .contacts: return "Contacts Access"
        case .calendar: return "Calendar Access"
        case .appStore: return "App Store Restrictions"
        case .appRestrictions: return "Application Restrictions"
        case .appUpdates: return "App Update Policy"
        case .appInstallation: return "App Installation Policy"
        case .appRemoval: return "App Removal Policy"
        case .loginWindow: return "Login Window Settings"
        case .energySaver: return "Energy Saver Preferences"
        case .notifications: return "Notification Settings"
        case .dock: return "Dock Configuration"
        case .finder: return "Finder Preferences"
        case .userRestrictions: return "User Restrictions"
        case .deviceRestrictions: return "Device Restrictions"
        case .webContent: return "Web Content Filtering"
        case .mediaAccess: return "Media Access Control"
        case .gameCenter: return "Game Center Settings"
        case .ldap: return "LDAP Directory"
        case .exchange: return "Microsoft Exchange"
        case .caldav: return "CalDAV Calendar"
        case .carddav: return "CardDAV Contacts"
        case .webClip: return "Web Clip Applications"
        }
    }
    
    var description: String {
        switch self {
        case .fileVault: return "Enable and configure FileVault 2 disk encryption for enhanced data security on macOS devices."
        case .gatekeeper: return "Control which applications can run on macOS devices based on their source and code signing status."
        case .firewall: return "Configure macOS firewall settings to control network access and protect against unauthorized connections."
        case .systemIntegrity: return "Manage System Integrity Protection (SIP) settings to protect critical system files and processes."
        case .codeSigning: return "Define code signing policies and requirements for applications and kernel extensions."
        case .wifi: return "Configure Wi-Fi network settings including SSID, security type, and authentication methods."
        case .vpn: return "Set up VPN connections with various protocols including IKEv2, L2TP, and PPTP."
        case .proxy: return "Configure proxy server settings for HTTP, HTTPS, and other network protocols."
        case .ethernet: return "Manage Ethernet network configuration including IP settings and DNS configuration."
        case .cellular: return "Control cellular data settings and roaming policies for iOS devices."
        case .pppc: return "Manage Privacy Preferences Policy Control (PPPC) to control app access to system resources."
        case .tcc: return "Configure Transparency, Consent, and Control (TCC) settings for privacy and security."
        case .location: return "Control location services access and accuracy settings for location-aware applications."
        case .contacts: return "Manage access to contacts database and control which apps can read contact information."
        case .calendar: return "Control calendar access and manage which applications can read calendar data."
        case .appStore: return "Restrict access to the App Store and control app purchasing and installation."
        case .appRestrictions: return "Limit which applications can run and control app functionality and features."
        case .appUpdates: return "Manage automatic app updates and control update policies and scheduling."
        case .appInstallation: return "Control which applications can be installed and manage installation policies."
        case .appRemoval: return "Manage app removal policies and control which applications can be uninstalled."
        case .loginWindow: return "Configure login window appearance, behavior, and security settings."
        case .energySaver: return "Manage power management settings and energy-saving preferences for macOS devices."
        case .notifications: return "Control notification settings and manage notification permissions for applications."
        case .dock: return "Customize dock appearance, behavior, and application organization."
        case .finder: return "Configure Finder preferences and control file management and display options."
        case .userRestrictions: return "Apply restrictions to user accounts and control user capabilities and access."
        case .deviceRestrictions: return "Set device-wide restrictions and control device functionality and features."
        case .webContent: return "Filter web content and control access to websites and online resources."
        case .mediaAccess: return "Control access to media files, cameras, and microphones on devices."
        case .gameCenter: return "Manage Game Center settings and control gaming features and social interactions."
        case .ldap: return "Configure LDAP directory services for user authentication and management."
        case .exchange: return "Set up Microsoft Exchange email, calendar, and contact synchronization."
        case .caldav: return "Configure CalDAV calendar synchronization for enterprise calendar systems."
        case .carddav: return "Set up CardDAV contact synchronization for enterprise contact management."
        case .webClip: return "Create web clip applications that provide quick access to web-based resources."
        }
    }
    
    var category: PayloadCategory {
        switch self {
        case .fileVault, .gatekeeper, .firewall, .systemIntegrity, .codeSigning:
            return .security
        case .wifi, .vpn, .proxy, .ethernet, .cellular:
            return .network
        case .pppc, .tcc, .location, .contacts, .calendar:
            return .privacy
        case .appStore, .appRestrictions, .appUpdates, .appInstallation, .appRemoval:
            return .applications
        case .loginWindow, .energySaver, .notifications, .dock, .finder:
            return .system
        case .userRestrictions, .deviceRestrictions, .webContent, .mediaAccess, .gameCenter:
            return .restrictions
        case .ldap, .exchange, .caldav, .carddav, .webClip:
            return .enterprise
        }
    }
    
    var supportsMacOS: Bool {
        switch self {
        case .cellular, .webClip:
            return false
        default:
            return true
        }
    }
    
    var supportsIOS: Bool {
        switch self {
        case .fileVault, .gatekeeper, .systemIntegrity, .codeSigning, .ethernet, .energySaver, .dock, .finder:
            return false
        default:
            return true
        }
    }
    
    var supportsTvOS: Bool {
        switch self {
        case .fileVault, .gatekeeper, .systemIntegrity, .codeSigning, .ethernet, .energySaver, .dock, .finder, .cellular, .ldap, .exchange, .caldav, .carddav:
            return false
        default:
            return true
        }
    }
    
    var complexity: PayloadComplexity {
        switch self {
        case .fileVault, .gatekeeper, .firewall, .systemIntegrity, .codeSigning, .vpn, .pppc, .tcc:
            return .advanced
        case .wifi, .proxy, .ethernet, .appRestrictions, .userRestrictions, .deviceRestrictions:
            return .intermediate
        default:
            return .basic
        }
    }
    
    var documentationURL: String {
        // Apple's official documentation URLs for each payload type
        switch self {
        case .fileVault: return "https://developer.apple.com/documentation/devicemanagement/filevault"
        case .gatekeeper: return "https://developer.apple.com/documentation/devicemanagement/gatekeeper"
        case .firewall: return "https://developer.apple.com/documentation/devicemanagement/firewall"
        case .pppc: return "https://developer.apple.com/documentation/devicemanagement/privacypreferencespolicycontrol"
        case .wifi: return "https://developer.apple.com/documentation/devicemanagement/wifi"
        case .vpn: return "https://developer.apple.com/documentation/devicemanagement/vpn"
        default: return "https://developer.apple.com/documentation/devicemanagement"
        }
    }
}

// MARK: - Payload Complexity
enum PayloadComplexity: String, CaseIterable {
    case basic = "Basic"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var description: String {
        switch self {
        case .basic: return "Simple configuration with few options"
        case .intermediate: return "Moderate complexity with multiple configuration options"
        case .advanced: return "Complex configuration requiring technical expertise"
        }
    }
    
    var color: String {
        switch self {
        case .basic: return "green"
        case .intermediate: return "orange"
        case .advanced: return "red"
        }
    }
}

// MARK: - Profile Validation Result
struct ProfileValidationResult {
    let isValid: Bool
    let errors: [ProfileValidationError]
    let warnings: [ProfileValidationWarning]
    let complianceIssues: [ComplianceError]
    let suggestions: [ValidationSuggestion]
    
    init(isValid: Bool, errors: [ProfileValidationError], warnings: [ProfileValidationWarning], complianceIssues: [ComplianceError], suggestions: [ValidationSuggestion]) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.complianceIssues = complianceIssues
        self.suggestions = suggestions
    }
}
