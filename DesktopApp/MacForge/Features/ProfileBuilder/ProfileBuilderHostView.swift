//
//  ProfileBuilderHostView.swift
//  MacForge
//
//  Redesigned Profile Builder inspired by Jamf Pro Policy Editor Lite.
//  Intuitive interface with clear explanations of Apple MDM concepts.
//

import SwiftUI

struct ProfileBuilderHostView: View {
    let selectedMDM: MDMVendor?
    let model: BuilderModel
    let onHome: () -> Void
    
    @State private var selectedPayload: Payload?
    @State private var showingPayloadInfo = false
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with clear purpose
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Builder")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(LCARSTheme.accent)
                        
                        Text("Create Apple Configuration Profiles for macOS and iOS")
                            .font(.title3)
                            .foregroundStyle(LCARSTheme.textSecondary)
                        
                        Text("Build production-ready MDM payloads with guided assistance and clear explanations")
                            .font(.body)
                            .foregroundStyle(LCARSTheme.textMuted)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Button("Export Profile") {
                            // Export functionality
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(LCARSTheme.accent)
                        
                        Text("Profile: \(model.dropped.count) payloads")
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.textSecondary)
                    }
                }
                
                // Quick Start Guide
                HStack(spacing: 16) {
                    QuickStartStep(
                        number: 1,
                        title: "Choose Payloads",
                        description: "Select from Apple's supported configuration options"
                    )
                    
                    QuickStartStep(
                        number: 2,
                        title: "Configure Settings",
                        description: "Set values and options for each payload"
                    )
                    
                    QuickStartStep(
                        number: 3,
                        title: "Export & Deploy",
                        description: "Generate .mobileconfig for your MDM system"
                    )
                }
            }
            .padding(24)
            .background(LCARSTheme.panel)
            .cornerRadius(16)
            
            // Main Content Area
            HStack(spacing: 0) {
                // Left: Payload Library
                VStack(spacing: 0) {
                    // Search and Filter
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(LCARSTheme.textSecondary)
                            
                            TextField("Search payloads...", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Category Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["All", "Security", "Network", "Privacy", "Applications", "System", "Restrictions", "Enterprise"], id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        action: { selectedCategory = category }
                                    )
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(16)
                    .background(LCARSTheme.surface)
                    
                    // Payload List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPayloads, id: \.self) { payload in
                                PayloadLibraryItem(
                                    payload: payload,
                                    isSelected: model.dropped.contains(payload),
                                    onToggle: { togglePayload(payload) },
                                    onInfo: { selectedPayload = payload; showingPayloadInfo = true }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
                .frame(width: 400)
                .background(LCARSTheme.background)
                
                // Divider
                Rectangle()
                    .fill(LCARSTheme.primary.opacity(0.3))
                    .frame(width: 1)
                
                // Right: Profile Configuration
                VStack(spacing: 0) {
                    // Profile Header
                    HStack {
                        Text("Profile Configuration")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        Spacer()
                        
                        Button("Clear All") {
                            model.dropped.removeAll()
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.dropped.isEmpty)
                    }
                    .padding(16)
                    .background(LCARSTheme.surface)
                    
                    // Profile Content
                    if model.dropped.isEmpty {
                        EmptyProfileView()
                    } else {
                        ProfileConfigurationView(model: model)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(LCARSTheme.background)
            }
        }
        .background(LCARSTheme.background)
        .sheet(isPresented: $showingPayloadInfo) {
            if let payload = selectedPayload {
                // For now, show a simple info view since PayloadInfoSheet expects PayloadType
                VStack(spacing: 20) {
                    Text(payload.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(payload.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Button("Done") {
                        showingPayloadInfo = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
                .frame(width: 500, height: 300)
            }
        }
    }
    
    private var filteredPayloads: [Payload] {
        // For now, return a sample list. In a real implementation, this would come from a library
        let samplePayloads = [
            Payload(id: "filevault", name: "FileVault 2 Encryption", description: "Enable and configure FileVault 2 disk encryption for enhanced data security on macOS devices.", platforms: ["macOS"], icon: "lock.shield", category: "Security"),
            Payload(id: "gatekeeper", name: "Gatekeeper Security", description: "Control which applications can run on macOS devices based on their source and code signing status.", platforms: ["macOS"], icon: "shield", category: "Security"),
            Payload(id: "wifi", name: "Wi-Fi Configuration", description: "Configure Wi-Fi network settings including SSID, security type, and authentication methods.", platforms: ["macOS", "iOS"], icon: "wifi", category: "Network"),
            Payload(id: "vpn", name: "VPN Configuration", description: "Set up VPN connections with various protocols including IKEv2, L2TP, and PPTP.", platforms: ["macOS", "iOS"], icon: "network", category: "Network"),
            Payload(id: "pppc", name: "Privacy Preferences Policy Control", description: "Manage Privacy Preferences Policy Control (PPPC) to control app access to system resources.", platforms: ["macOS", "iOS"], icon: "hand.raised", category: "Privacy")
        ]
        
        let categoryFiltered = selectedCategory == "All" ? samplePayloads : samplePayloads.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { payload in
                payload.name.localizedCaseInsensitiveContains(searchText) ||
                payload.description.localizedCaseInsensitiveContains(searchText) ||
                payload.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func togglePayload(_ payload: Payload) {
        if model.dropped.contains(payload) {
            model.remove(payload.id)
        } else {
            model.dropped.append(payload)
        }
    }
    
    private func platformColor(for platform: String) -> Color {
        switch platform.lowercased() {
        case "macos": return .blue
        case "ios": return .green
        case "tvos": return .purple
        default: return .gray
        }
    }
}

// MARK: - Quick Start Step
struct QuickStartStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LCARSTheme.accent)
                .frame(width: 32, height: 32)
                .overlay(
                    Text("\(number)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(LCARSTheme.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? LCARSTheme.accent : LCARSTheme.panel)
                )
                .foregroundStyle(isSelected ? .black : LCARSTheme.textPrimary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Payload Library Item
struct PayloadLibraryItem: View {
    let payload: Payload
    let isSelected: Bool
    let onToggle: () -> Void
    let onInfo: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.name)
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    Text(payload.category)
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LCARSTheme.accent.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: onInfo) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(LCARSTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Learn more about this payload")
                    
                    Button(action: onToggle) {
                        Image(systemName: isSelected ? "minus.circle.fill" : "plus.circle")
                            .foregroundStyle(isSelected ? .red : LCARSTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .help(isSelected ? "Remove from profile" : "Add to profile")
                }
            }
            
            Text(payload.description)
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
                .lineLimit(3)
            
            // Platform Support
            HStack(spacing: 8) {
                ForEach(payload.platforms, id: \.self) { platform in
                    PlatformBadge(platform: platform, color: platformColor(for: platform))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LCARSTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? LCARSTheme.accent : Color.clear, lineWidth: 2)
                )
        )
    }
    
    private func platformColor(for platform: String) -> Color {
        switch platform.lowercased() {
        case "macos": return .blue
        case "ios": return .green
        case "tvos": return .purple
        default: return .gray
        }
    }
}

// MARK: - Platform Badge
struct PlatformBadge: View {
    let platform: String
    let color: Color
    
    var body: some View {
        Text(platform)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
}

// MARK: - Empty Profile View
struct EmptyProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundStyle(LCARSTheme.textSecondary)
            
            VStack(spacing: 12) {
                Text("No Payloads Selected")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(LCARSTheme.textPrimary)
                
                Text("Choose payloads from the library to start building your configuration profile")
                    .font(.body)
                    .foregroundStyle(LCARSTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LCARSTheme.background)
    }
}

// MARK: - Profile Configuration View
struct ProfileConfigurationView: View {
    let model: BuilderModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(model.dropped, id: \.self) { payload in
                    PayloadConfigurationCard(payload: payload)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Payload Configuration Card
struct PayloadConfigurationCard: View {
    let payload: Payload
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.name)
                        .font(.headline)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    Text(payload.category)
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.accent)
                }
                
                Spacer()
                
                Button("Configure") {
                    // Open configuration interface
                }
                .buttonStyle(.borderedProminent)
                .tint(LCARSTheme.accent)
            }
            
            Text(payload.description)
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
            
            // Configuration Status
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.green)
                Text("Ready for configuration")
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
                
                Spacer()
                
                Text("Click Configure to set options")
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textMuted)
            }
        }
        .padding(16)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
    }
}

#Preview {
    ProfileBuilderHostView(
        selectedMDM: .jamf,
        model: BuilderModel(),
        onHome: {}
    )
}
