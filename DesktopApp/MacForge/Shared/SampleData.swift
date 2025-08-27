//
//  SampleData.swift
//  MacForge
//
//  Sample data and mock objects for development and testing purposes.
//  Provides realistic test data for profile building and MDM operations.

import Foundation

let pppcServiceCatalog: [String] = [
    "Camera","Microphone","ScreenCapture","AppleEvents",
    "SystemPolicyAllFiles","SystemPolicyDownloadsFolder",
    "SystemPolicyDesktopFolder","SystemPolicyDocumentsFolder",
    "Accessibility"
]

// MARK: - Comprehensive PPPC Services
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

let allPayloadsLibrary: [Payload] = [
    .init(id: "wifi", name: "Wi-Fi", description: "Configure Wi-Fi settings", platforms: ["iOS","macOS","tvOS"], icon: "📶", category: "Network"),
    .init(id: "vpn", name: "VPN", description: "Virtual Private Network", platforms: ["iOS","macOS","tvOS"], icon: "🔒", category: "Network"),
    .init(id: "restrictions", name: "Restrictions", description: "Device & app restrictions", platforms: ["iOS","macOS","tvOS"], icon: "🚫", category: "Security"),
    .init(id: "filevault2", name: "FileVault 2", description: "Disk encryption", platforms: ["macOS"], icon: "🔐", category: "Security"),
    .init(id: "firewall", name: "Firewall", description: "macOS firewall", platforms: ["macOS"], icon: "🛡️", category: "Security"),
    .init(id: "notifications", name: "Notifications", description: "Per-app notifications", platforms: ["iOS","macOS"], icon: "🔔", category: "User Experience"),
    .init(id: "pppc", name: "Privacy Preferences", description: "PPPC (TCC) permissions", platforms: ["macOS"], icon: "🔐", category: "Security")
]

let templatesLibrary: [TemplateProfile] = [
    .init(name: "Security Baseline", description: "Essential security settings for enterprise devices", payloadIDs: ["restrictions","firewall","filevault2","pppc"]),
    .init(name: "Network Configuration", description: "Wi-Fi and VPN settings for network management", payloadIDs: ["wifi","vpn"]),
    .init(name: "Antivirus & EDR", description: "Security tool permissions with PPPC configuration", payloadIDs: ["pppc"]),
    .init(name: "Development Tools", description: "Developer-friendly permissions for coding apps", payloadIDs: ["pppc"]),
    .init(name: "Media & Communication", description: "Camera, microphone, and screen sharing permissions", payloadIDs: ["pppc"]),
    .init(name: "File Management", description: "Full disk access and folder permissions", payloadIDs: ["pppc"])
]

let categories: [String] = ["All","Network","Security","User Experience","Applications","Accounts","Certificates"]
