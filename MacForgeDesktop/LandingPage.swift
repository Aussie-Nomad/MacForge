//
//  LandingPage.swift
//  MacForge
//
//  Created by Danny Mac on 15/08/2025.
//
// V3

import SwiftUI

// MARK: - Main Landing View
struct LandingPage: View {
    @ObservedObject var model: BuilderModel
    let selectedMDM: MDMVendor?                 // may be nil
    var onChangeMDM: () -> Void
    var onPickMDM: (MDMVendor) -> Void
    var onHome: () -> Void
    var jamfClient: JamfClient?
    
    var body: some View {
        ZStack {
            // Animated background effect
            AnimatedBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection
                    
                    // Two-column layout
                    HStack(alignment: .top, spacing: 24) {
                        // Left Column
                        VStack(spacing: 20) {
                            authorsNotesSection
                            currentWorkSection
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Column
                        VStack(spacing: 20) {
                            contactSection
                            bugsSection
                            versionSection
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(32)
            }
        }
        .background(LcarsTheme.bg)
    }
    
    // MARK: - Links
        private func openURL(_ s: String) {
            #if os(macOS)
            if let url = URL(string: s) { NSWorkspace.shared.open(url) }
            #elseif canImport(UIKit)
            if let url = URL(string: s) { UIApplication.shared.open(url) }
            #endif
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Large animated title
            AnimatedHeader(title: "WELCOME TO MACFORGE")
            
            // Subtitle with glow effect
            Text("ADVANCED MDM PAYLOAD MANAGEMENT SYSTEM")
                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                .foregroundStyle(LcarsTheme.amber)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LcarsTheme.amber.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LcarsTheme.amber, lineWidth: 2)
                        )
                )
                .shadow(color: LcarsTheme.amber.opacity(0.3), radius: 8)
            
            Text("Choose an MDM from the left to begin.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Section Views
    private var authorsNotesSection: some View {
        lcarsPanel(color: LcarsTheme.orange) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("AUTHORS NOTES", color: LcarsTheme.orange)
                
                Text("MacForge is a cutting-edge toolbox for building and managing Apple MDM payloads.")
                    .font(.headline)
                    .foregroundStyle(LcarsTheme.amber)
                
                Text("This application streamlines the creation of configuration profiles for macOS and iOS devices. Whether you're managing PPPC permissions, Wi-Fi settings, or security policies, MacForge provides an intuitive LCARS-inspired interface for building production-ready profiles.")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
    }
    
    private var currentWorkSection: some View {
        lcarsPanel(color: Color.blue) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("CURRENTLY WORKING ON", color: Color.blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    workItem("Jamf Pro Blueprints integration", status: "IN PROGRESS")
                    workItem("Full PPPC parity with PPPC Utility", status: "PLANNING")
                    workItem("Cross-MDM export adapters", status: "RESEARCH")
                    workItem("Advanced certificate payload support", status: "BACKLOG")
                    workItem("Custom payload template system", status: "CONCEPT")
                }
            }
        }
    }
    
    private var contactSection: some View {
        lcarsPanel(color: Color.green) {
            VStack(spacing: 16) {
                sectionHeader("CONTACT AUTHOR", color: Color.green)
                
                Text("Thank you for using MacForge")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    contactButton("GITHUB", destination: "https://github.com/Aussie-Nomad", color: .blue)
                    contactButton("EMAIL", destination: "mailto:", color: .orange)
                    contactButton("WIKI", destination: "https://github.com/dannymcdermott/macforge/wiki", color: .green)
                }
            }
        }
    }
    
    private var bugsSection: some View {
        lcarsPanel(color: Color.red) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("REPORTED BUGS & KNOWN ISSUES", color: Color.red)
                
                Text("CURRENT STATUS: MONITORING")
                    .font(.caption)
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 6) {
                    issueItem("Some MDM image assets may not display correctly", severity: "LOW")
                    issueItem("Profile validation needs enhancement", severity: "MEDIUM")
                    issueItem("Export error handling improvements needed", severity: "LOW")
                }
                
                Text("Report bugs using the 'Report Bug' button when connected to an MDM.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }
    
    private var versionSection: some View {
        lcarsPanel(color: LcarsTheme.amber) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("SYSTEM VERSION", color: LcarsTheme.amber)
                
                VStack(spacing: 8) {
                    infoRow("VERSION", "1.0.0 (Beta)")
                    infoRow("BUILD DATE", "August 15, 2025")
                    infoRow("PLATFORMS", "macOS 12+, iOS 15+")
                    infoRow("STATUS", "OPERATIONAL")
                }
            }
        }
    }

    // MARK: - Helper Components
    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(color)
            Spacer()
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.8), radius: 4)
        }
    }
    
    private func workItem(_ text: String, status: String) -> some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.body)
            Spacer()
            Text(status)
                .font(.caption)
                .foregroundStyle(Color.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(6)
        }
    }
    
    private func issueItem(_ text: String, severity: String) -> some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.body)
            Spacer()
            Text(severity)
                .font(.caption)
                .foregroundStyle(Color.red)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.2))
                .cornerRadius(4)
        }
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(LcarsTheme.amber)
                .fontWeight(.semibold)
        }
    }
    
    private func contactButton(_ title: String, destination: String, color: Color) -> some View {
        Link(destination: URL(string: destination)!) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(color)
                .cornerRadius(20)
                .shadow(color: color.opacity(0.4), radius: 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func lcarsPanel<Content: View>(color: Color = LcarsTheme.orange, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading) { content() }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LcarsTheme.panel)
                    .shadow(color: color.opacity(0.3), radius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color, lineWidth: 3)
                    .shadow(color: color.opacity(0.6), radius: 2)
            )
    }


// MARK: - Animated Components
struct AnimatedHeader: View {
    let title: String
    @State private var isAnimating = false
    
    var body: some View {
        Text(title)
            .font(.system(size: 32, weight: .black, design: .monospaced))
            .foregroundStyle(LcarsTheme.amber)
            .shadow(color: LcarsTheme.amber.opacity(0.8), radius: isAnimating ? 12 : 4)
            .scaleEffect(isAnimating ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct AnimatedBackground: View {
    @State private var animationPhase = 0.0
    
    var body: some View {
        ZStack {
            // Subtle grid pattern
            Canvas { context, size in
                let gridSize: CGFloat = 40
                context.stroke(
                    Path { path in
                        for x in stride(from: 0, through: size.width, by: gridSize) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        for y in stride(from: 0, through: size.height, by: gridSize) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                        }
                    },
                    with: .color(LcarsTheme.amber.opacity(0.05)),
                    lineWidth: 1
                )
            }
            
            // Animated energy lines
            ForEach(0..<3) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                LcarsTheme.amber.opacity(0.1),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .offset(x: animationPhase * 1000 + CGFloat(i * 300))
                    .animation(
                        .linear(duration: 8.0 + Double(i))
                        .repeatForever(autoreverses: false),
                        value: animationPhase
                    )
                    .position(x: 400, y: CGFloat(100 + i * 200))
            }
        }
        .onAppear {
            animationPhase = 1.0
        }
    }
}

// MARK: - Default "nothing selected" card
struct SelectMDMPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            LcarsHeader(title: "SELECT MOBILE DEVICE MANAGER")
            Text("Choose an MDM from the left to begin.")
                .font(.footnote)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).stroke(LcarsTheme.amber, lineWidth: 2))
            Spacer()
        }
        .padding(20)
        .background(LcarsTheme.bg)
    }
}

//V1 Landing Page
//  Created by Danny Mac on 11/08/2025.
//
//import SwiftUI

// MARK: - Main Landing View
//struct LandingHomeView: View {
//    @ObservedObject var model: BuilderModel
//    let selectedMDM: MDMVendor
//    let onChangeMDM: () -> Void
//    let onPickMDM: (MDMVendor) -> Void
//    let onHome: () -> Void
//    var jamfClient: JamfClient?
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 16) {
//                LcarsHeader(title: "WELCOME TO MACFORGE")
//                
//                Text("Choose an MDM from the left to begin.")
//                    .font(.footnote)
//                    .padding(.horizontal, 14)
//                    .padding(.vertical, 6)
//                    .background(RoundedRectangle(cornerRadius: 10).stroke(LcarsTheme.amber, lineWidth: 2))
//
//                // Contact / links
//                lcarsPanel {
//                    VStack(spacing: 12) {
//                        Text("Thank you for using MacForge\nYou can reach the author using the buttons below.")
//                            .multilineTextAlignment(.center)
//                        HStack(spacing: 12) {
//                            Link("GitHub", destination: URL(string: "https://github.com/dannymcdermott")!)
//                                .buttonStyle(.borderedProminent)
//                            Link("Email", destination: URL(string: "mailto:daniel.mcdermott@zappistore.com")!)
//                                .buttonStyle(.bordered)
//                            Link("Wiki", destination: URL(string: "https://github.com/dannymcdermott/macforge/wiki")!)
//                                .buttonStyle(.bordered)
//                        }
//                    }
//                }
//
//                sectionHeader("AUTHORS NOTES")
//                lcarsPanel {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("MacForge is a toolbox for building and managing Apple MDM payloads. Pick an MDM on the left, connect, then open a tool.")
//                        Text("")
//                        Text("This app is designed to streamline the creation of configuration profiles for macOS and iOS devices. Whether you're managing PPPC permissions, Wi-Fi settings, or security policies, MacForge provides an intuitive interface for building production-ready profiles.")
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                }
//
//                sectionHeader("CURRENTLY WORKING ON")
//                lcarsPanel {
//                    VStack(alignment: .leading, spacing: 8) {
//                        bullet("Jamf Pro Blueprints integration")
//                        bullet("Full PPPC parity with PPPC Utility")
//                        bullet("Cross-MDM export adapters (Intune, Kandji, Mosyle)")
//                        bullet("Advanced certificate payload support")
//                        bullet("Custom payload template system")
//                    }
//                }
//
//                sectionHeader("REPORTED BUGS & KNOWN ISSUES")
//                lcarsPanel {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Current known issues:")
//                        bullet("Some MDM image assets may not display correctly")
//                        bullet("Profile validation could be more comprehensive")
//                        bullet("Export functionality needs error handling improvements")
//                        Text("")
//                        Text("Please report any bugs or feature requests using the 'Report Bug' button in the toolbar when connected to an MDM.")
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                }
//                
//                sectionHeader("VERSION INFO")
//                lcarsPanel {
//                    VStack(alignment: .leading, spacing: 8) {
//                        HStack {
//                            Text("Version:")
//                            Spacer()
//                            Text("1.0.0 (Beta)")
//                                .foregroundStyle(LcarsTheme.amber)
//                        }
//                        HStack {
//                            Text("Build Date:")
//                            Spacer()
//                            Text("August 15, 2025")
//                                .foregroundStyle(.secondary)
//                        }
//                        HStack {
//                            Text("Supported Platforms:")
//                            Spacer()
//                            Text("macOS 12+, iOS 15+")
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                }
//            }
//            .padding(20)
//        }
//        .background(LcarsTheme.bg)
//    }
//
//    private func sectionHeader(_ title: String) -> some View {
//        Text(title)
//            .font(.headline).fontWeight(.heavy)
//            .foregroundStyle(LcarsTheme.amber)
//            .padding(.horizontal, 12)
//            .padding(.vertical, 6)
//            .background(RoundedRectangle(cornerRadius: 12).stroke(LcarsTheme.amber, lineWidth: 2))
//    }
//
//    private func bullet(_ text: String) -> some View {
//        HStack(alignment: .firstTextBaseline, spacing: 8) {
//            Circle()
//                .fill(LcarsTheme.amber)
//                .frame(width: 6, height: 6)
//            Text(text)
//        }
//    }
//
//    @ViewBuilder
//    private func lcarsPanel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
//        VStack(alignment: .leading) { content() }
//            .padding(16)
//            .background(
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(LcarsTheme.panel)
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 16)
//                    .stroke(LcarsTheme.orange, lineWidth: 3)
//            )
//    }
//}
//
//// MARK: - Default "nothing selected" card
//struct SelectMDMPlaceholder: View {
//    var body: some View {
//        VStack(spacing: 12) {
//            LcarsHeader(title: "SELECT MOBILE DEVICE MANAGER")
//            Text("Choose an MDM from the left to begin.")
//                .font(.footnote)
//                .padding(.horizontal, 14)
//                .padding(.vertical, 6)
//                .background(RoundedRectangle(cornerRadius: 10).stroke(LcarsTheme.amber, lineWidth: 2))
//            Spacer()
//        }
//        .padding(20)
//        .background(LcarsTheme.bg)
//    }
//}
