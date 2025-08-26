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
    PPPCService(id: "SystemPolicyAllFiles", name: "System Policy All Files", description: "Full disk access for system-wide file operations", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "SystemPolicyDownloadsFolder", name: "System Policy Downloads Folder", description: "Access to Downloads folder", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "SystemPolicyDesktopFolder", name: "System Policy Desktop Folder", description: "Access to Desktop folder", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "SystemPolicyDocumentsFolder", name: "System Policy Documents Folder", description: "Access to Documents folder", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    
    // Accessibility Services
    PPPCService(id: "Accessibility", name: "Accessibility", description: "Control other applications and system features", category: .accessibility, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "InputMonitoring", name: "Input Monitoring", description: "Monitor user input from keyboards and mice", category: .inputMonitoring, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    
    // Media Services
    PPPCService(id: "Camera", name: "Camera", description: "Access to camera hardware", category: .media, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "Microphone", name: "Microphone", description: "Access to microphone hardware", category: .media, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "ScreenCapture", name: "Screen Capture", description: "Capture screen content and record screen", category: .media, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    
    // Automation Services
    PPPCService(id: "AppleEvents", name: "Apple Events", description: "Send Apple Events to other applications", category: .automation, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    
    // Network Services
    PPPCService(id: "NetworkExtension", name: "Network Extension", description: "Configure network settings and VPN", category: .network, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    
    // Additional System Services
    PPPCService(id: "SystemPolicyRemovableVolumes", name: "System Policy Removable Volumes", description: "Access to removable storage devices", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true),
    PPPCService(id: "SystemPolicySysAdminFiles", name: "System Policy SysAdmin Files", description: "Access to system administration files", category: .systemPolicy, requiresBundleID: true, requiresCodeRequirement: false, requiresIdentifier: true)
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
    .init(name: "Security Baseline", description: "Essential security settings", payloadIDs: ["restrictions","firewall","filevault2","pppc"]),
    .init(name: "Network", description: "Wi-Fi + VPN", payloadIDs: ["wifi","vpn"]),
    .init(name: "Antivirus Setup", description: "EDR-friendly PPPC", payloadIDs: ["pppc"])
]

let categories: [String] = ["All","Network","Security","User Experience","Applications","Accounts","Certificates"]
