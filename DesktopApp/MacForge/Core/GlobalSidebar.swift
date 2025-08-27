//
//  GlobalSidebar.swift
//  MacForge
//
//  Global navigation sidebar that provides access to all available tools and MDM selection.
//  Manages the main navigation flow of the application.

import SwiftUI

struct GlobalSidebar: View {
    @Binding var selectedMDM: MDMVendor?        // <- new
    var onChangeMDM: () -> Void                 // <- new
    var onSelectTool: (ToolModule) -> Void      // <- new


    var body: some View {
        ScrollView {
            VStack(spacing: LCARSTheme.Sidebar.sectionGap) {
                SidebarBrandHeader()

                // MDM section
                VStack(alignment: .leading, spacing: 10) {
                    Text(selectedMDM == nil ? "MOBILE DEVICE MANAGER" : "SELECTED MDM")
                        .lcarsPill()

                    if let mdm = selectedMDM {
                        // Show only the chosen MDM with a "Change…" button
                        LcarsTileRow(
                            items: [.init(title: mdm.rawValue, imageName: mdm.asset)]
                        )

                        LcarsSmallButton(title: "Change…") {
                            onChangeMDM()
                        }
                    } else {
                        // Show all MDMs
                        LcarsTileRow(
                            items: MDMVendor.allCases.map { .init(title: $0.rawValue, imageName: $0.asset) },
                            onTap: { item in
                                // Map back title -> enum
                                if let mdm = MDMVendor.allCases.first(where: { $0.rawValue == item.title }) {
                                    selectedMDM = mdm         // keep sidebar open
                                    // We *do not* collapse here
                                    // Authentication will be triggered when user tries to submit
                                }
                            }
                        )
                    }
                }

                // Tools
                VStack(alignment: .leading, spacing: 10) {
                    Text("TOOLS").lcarsPill()

                    // Enable tools after an MDM is chosen
                    if selectedMDM != nil {
                        ForEach(ToolModule.allCases, id: \.self) { tool in
                            Button {
                                onSelectTool(tool)   // collapses sidebar handled in ContentView
                            } label: {
                                HStack {
                                    Label(tool.displayName, systemImage: tool.icon)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: LCARSTheme.Sidebar.tileCorner)
                                        .stroke(LCARSTheme.accent, lineWidth: LCARSTheme.Sidebar.tileStroke)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        // Show disabled tiles for all tools when no MDM selected
                        ForEach(ToolModule.allCases, id: \.self) { tool in
                            LcarsDisabledTile(
                                title: tool.displayName,
                                subtitle: "Select an MDM to enable tools."
                            )
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(LCARSTheme.Sidebar.outerPadding)
        }
        .frame(width: LCARSTheme.Sidebar.width)
        .themeAwareBackground()
    }
}

// MARK: - Compact Brand Header
struct CompactBrandHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            JamforgeMark(32) // Smaller icon
            VStack(alignment: .leading, spacing: 1) {
                Text("MacForge")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                Text("By Daniel McDermott")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(8) // Reduced padding
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LCARSTheme.accent, lineWidth: 2)
        )
    }
}

// MARK: - Improved MDM Tiles
struct ImprovedMDMTiles: View {
    let onSelect: (MDMVendor) -> Void
    
    private let mdmOptions: [(vendor: MDMVendor, imageName: String)] = [
        (.jamf, "mdm_jamf"),
        (.intune, "mdm_intune"),
        (.kandji, "mdm_kandji"),
        (.mosyle, "mdm_mosyle")
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(mdmOptions, id: \.vendor) { option in
                MDMTileButton(
                    vendor: option.vendor,
                    imageName: option.imageName,
                    onSelect: onSelect
                )
            }
        }
    }
}

// MARK: - Individual MDM Tile Button
struct MDMTileButton: View {
    let vendor: MDMVendor
    let imageName: String
    let onSelect: (MDMVendor) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            print("🔥 MDM Button tapped: \(vendor.rawValue)") // Debug
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            // Call the selection handler
            onSelect(vendor)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        } label: {
            HStack(spacing: 16) {
                // MDM Logo - DOUBLED SIZE
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80) // Doubled from 40x40
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.black.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName(for: vendor))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle(for: vendor))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LCARSTheme.accent)
            }
            .padding(16) // Increased padding for larger buttons
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                                        colors: [
                    LCARSTheme.primary.opacity(isPressed ? 0.9 : 0.7),
                    LCARSTheme.primary.opacity(isPressed ? 0.7 : 0.5)
                ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LCARSTheme.primary, lineWidth: 3)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(color: LCARSTheme.primary.opacity(0.4), radius: 6)
    }
    
    private func displayName(for vendor: MDMVendor) -> String {
        switch vendor {
        case .jamf: return "Jamf Pro"
        case .intune: return "Microsoft Intune"
        case .kandji: return "Kandji"
        case .mosyle: return "Mosyle"
        }
    }
    
    private func subtitle(for vendor: MDMVendor) -> String {
        switch vendor {
        case .jamf: return "Enterprise MDM"
        case .intune: return "Microsoft 365"
        case .kandji: return "Apple-focused MDM"
        case .mosyle: return "Education & Business"
        }
    }
}
