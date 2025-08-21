//
//  SampleData.swift
//  MacForge
//
//  Created by Danny Mac on 14/08/2025.
//
// V3

import Foundation

let pppcServiceCatalog: [String] = [
    "Camera","Microphone","ScreenCapture","AppleEvents",
    "SystemPolicyAllFiles","SystemPolicyDownloadsFolder",
    "SystemPolicyDesktopFolder","SystemPolicyDocumentsFolder",
    "Accessibility"
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
