//
//  LandingPage.swift
//  MacForge
//
//  Main landing page view that displays when no tool is selected.
//  Provides information about the app, current work status, and contact details.
//

import SwiftUI

// MARK: - Main Landing View
struct LandingPage: View {
    @ObservedObject var model: BuilderModel
    @Environment(\.themeManager) var themeManager
    let selectedMDM: MDMVendor?                 // may be nil
    var onChangeMDM: () -> Void
    var onPickMDM: (MDMVendor) -> Void
    var onHome: () -> Void
    @Binding var showingWelcome: Bool
    
    var body: some View {
        ZStack {
            // Animated background effect
            AnimatedBackground()
            
            VStack(spacing: 24) {
                // Hero Section
                heroSection
                
                // Responsive layout that adapts to window size
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 24),
                    GridItem(.flexible(), spacing: 24)
                ], spacing: 24) {
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
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, minHeight: 600)
        }
        .themeAwareBackground()
    }
    
    // MARK: - Utility Functions
    private func openURL(_ s: String) {
        #if os(macOS)
        if let url = URL(string: s) { NSWorkspace.shared.open(url) }
        #elseif canImport(UIKit)
        if let url = URL(string: s) { UIApplication.shared.open(url) }
        #endif
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Large animated title
            AnimatedHeader(title: "WELCOME TO MACFORGE")
            
            // Subtitle with glow effect
            Text("ADVANCED MDM PAYLOAD MANAGEMENT SYSTEM")
                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                .foregroundStyle(LCARSTheme.accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LCARSTheme.accent.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LCARSTheme.accent, lineWidth: 2)
                        )
                )
                .shadow(color: LCARSTheme.accent.opacity(0.3), radius: 8)
            
            Text("Choose an MDM from the left to begin.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Tutorial Button
            Button(action: {
                showingWelcome = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("START TUTORIAL")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LCARSTheme.accent)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LCARSTheme.accent, lineWidth: 2)
                        )
                )
                .shadow(color: LCARSTheme.accent.opacity(0.4), radius: 6)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }
    
    // MARK: - Section Views
    private var authorsNotesSection: some View {
        lcarsPanel(color: LcarsTheme.orange) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("AUTHORS NOTES", color: LcarsTheme.orange)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MacForge has evolved into a comprehensive MDM toolkit with AI-powered features.")
                            .font(.headline)
                            .foregroundStyle(LcarsTheme.amber)
                        
                        Text("The latest release introduces The Blacksmith - a conversational AI wizard for MDM setup, plus six specialized Package Management Tools with AI-powered analysis. MacForge now provides intelligent assistance for package creation, security assessment, and deployment recommendations, making it the ultimate toolkit for Mac administrators.")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .padding(.trailing, 8) // Add padding for scrollbar
                }
                .frame(height: 120) // Fixed height instead of maxHeight
            }
        }
        .frame(height: 200) // Fixed panel height
    }
    
    private var currentWorkSection: some View {
        lcarsPanel(color: Color.blue) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("CURRENTLY WORKING ON", color: Color.blue)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        workItem("Package Management Tools Suite", status: "COMPLETED")
                        workItem("The Blacksmith MDM Wizard", status: "COMPLETED")
                        workItem("AI-Powered Package Analysis", status: "COMPLETED")
                        workItem("Script Builder CLI Integration", status: "COMPLETED")
                        workItem("Package Casting UI Enhancements", status: "COMPLETED")
                        workItem("Blacksmith Yorkshire Personality", status: "COMPLETED")
                        workItem("Package Tool Navigation System", status: "COMPLETED")
                        workItem("Advanced Package Repackaging", status: "IN PROGRESS")
                        workItem("Template Systems Implementation", status: "NEXT")
                        workItem("System Lifecycle Management", status: "NEXT")
                    }
                    .padding(.trailing, 8) // Add padding for scrollbar
                }
                .frame(height: 200) // Fixed height instead of maxHeight
            }
        }
        .frame(height: 280) // Fixed panel height
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
                    contactButton("WIKI", destination: "https://github.com/Aussie-Nomad/MacForge/wiki/MacForge-Wiki-%F0%9F%93%9A", color: .green)
                    contactButton("REPORT BUG", destination: "https://github.com/Aussie-Nomad/MacForge/issues", color: .red)
                }
            }
        }
        .frame(height: 180) // Fixed panel height
    }
    
    private var bugsSection: some View {
        lcarsPanel(color: Color.red) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("REPORTED BUGS & KNOWN ISSUES", color: Color.red)
                
                Text("CURRENT STATUS: MOSTLY RESOLVED")
                    .font(.caption)
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        issueItem("Blacksmith MDM Wizard UI Layout", severity: "RESOLVED", color: .green)
                        issueItem("Package Analysis AI Integration", severity: "RESOLVED", color: .green)
                        issueItem("Package Management Tools Visibility", severity: "RESOLVED", color: .green)
                        issueItem("AISummaryCard Naming Conflict", severity: "RESOLVED", color: .green)
                        issueItem("Package Tool Navigation System", severity: "RESOLVED", color: .green)
                        issueItem("Test Suite Compilation Errors", severity: "PENDING", color: .orange)
                    }
                    .padding(.trailing, 8) // Add padding for scrollbar
                }
                .frame(height: 120) // Fixed height for scrollable content
                
                Text("Report bugs using the 'REPORT BUG' button above.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .frame(height: 220) // Fixed panel height
    }
    
    private var versionSection: some View {
        lcarsPanel(color: LcarsTheme.amber) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("SYSTEM VERSION", color: LcarsTheme.amber)
                
                VStack(spacing: 8) {
                    infoRow("VERSION", "2.1.1 (Beta) - Meet the Blacksmith")
                    infoRow("BUILD DATE", "January 15, 2025")
                    infoRow("PLATFORMS", "macOS 12+")
                    infoRow("STATUS", "BUILD SUCCESSFUL")
                    infoRow("AI PROVIDERS", "OpenAI, Anthropic, Ollama, Custom")
                    infoRow("CI/CD", "FUNCTIONAL")
                }
            }
        }
        .frame(height: 180) // Fixed panel height
    }

    // MARK: - Helper Components
    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(themeManager.isLCARSActive ? LCARSTheme.textPrimary : color)
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
    
    private func issueItem(_ text: String, severity: String, color: Color = .red) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.body)
            Spacer()
            Text(severity)
                .font(.caption)
                .foregroundStyle(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
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
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func lcarsPanel<Content: View>(color: Color = LcarsTheme.orange, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading) { content() }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.isLCARSActive ? LCARSTheme.panel : LcarsTheme.panel)
                    .shadow(color: color.opacity(0.3), radius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color, lineWidth: 3)
                    .shadow(color: color.opacity(0.6), radius: 2)
            )
    }
}

// MARK: - Animated Components
struct AnimatedHeader: View {
    let title: String
    @Environment(\.themeManager) var themeManager
    @State private var isAnimating = false
    
    var body: some View {
        Text(title)
            .font(.system(size: 32, weight: .black, design: .monospaced))
            .foregroundStyle(themeManager.isLCARSActive ? LCARSTheme.primary : LcarsTheme.amber)
            .shadow(color: (themeManager.isLCARSActive ? LCARSTheme.primary : LcarsTheme.amber).opacity(0.8), radius: isAnimating ? 12 : 4)
            .scaleEffect(isAnimating ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct AnimatedBackground: View {
    @Environment(\.themeManager) var themeManager
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
                    with: .color((themeManager.isLCARSActive ? LCARSTheme.primary : LcarsTheme.amber).opacity(0.05)),
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
                                (themeManager.isLCARSActive ? LCARSTheme.primary : LcarsTheme.amber).opacity(0.1),
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
