//  ContentView.swift
//  MacForge
//
//  Main content view that manages the app's navigation structure.
//  Contains the global sidebar and main content area with tool selection.

import SwiftUI

struct ContentView: View {
    // MARK: - App State
    @State private var selectedTool: ToolModule? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedMDM: MDMVendor? = nil
    @State private var showingAccountSettings = false
    @StateObject private var model = BuilderModel()

    // MARK: - Layout
    private let sidebarWidth: CGFloat = LCARSTheme.Sidebar.width

    // MARK: - Detail content
    @ViewBuilder
    private var detailContent: some View {
        if let tool = selectedTool {
            switch tool {
            case .profileBuilder:
                ProfileBuilderHostView(selectedMDM: selectedMDM, model: model, onHome: { resetTool() })

            case .packageCasting:
                PackageCastingHostView(model: model, selectedMDM: selectedMDM)

            case .deviceFoundry:
                DeviceFoundryHostView(model: model, selectedMDM: selectedMDM)

            case .blueprintBuilder:
                DDMBlueprintsHostView(model: model, selectedMDM: selectedMDM)

            case .ddmBlueprints:
                DDMBlueprintsHostView(model: model, selectedMDM: selectedMDM)

            case .hammeringScripts:
                HammeringScriptsHostView(model: model, selectedMDM: selectedMDM)

            case .logBurner:
                LogBurnerHostView(model: model, selectedMDM: selectedMDM)
            }
        } else {
            // No tool chosen yet → landing / author notes
            LandingPage(
                model: model,
                selectedMDM: selectedMDM,
                onChangeMDM: { resetMDM() },
                onPickMDM:   { selectedMDM = $0 },   // keep sidebar open
                onHome:      { resetTool() }
            )
            .themeAwareBackground()
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // LEFT: Global sidebar – stays open after MDM selection.
            GlobalSidebar(
                selectedMDM: $selectedMDM,
                onChangeMDM: {
                    selectedMDM  = nil
                    selectedTool = nil
                    columnVisibility = .all
                },
                onSelectTool: { tool in
                    selectedTool = tool
                    // Sidebar collapses only when a tool is chosen
                    columnVisibility = .detailOnly
                }
            )
            .frame(width: sidebarWidth)
            .themeAwareBackground()

        } detail: {
            // RIGHT: Main canvas with responsive layout
            VStack(spacing: 0) {
                // Top Utility Bar
                HStack(spacing: 12) {
                    Button("Change MDM") {
                        selectedMDM  = nil
                        selectedTool = nil
                        columnVisibility = .all
                    }
                    .buttonStyle(.borderedProminent)
                    .contentShape(Rectangle())

                    Button("Change Tool") {
                        selectedTool = nil
                        columnVisibility = .all
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedTool == nil)
                    .contentShape(Rectangle())

                    Button("Account Settings") {
                        showingAccountSettings = true
                    }
                    .buttonStyle(.bordered)
                    .contentShape(Rectangle())

                    Spacer()

                    Button("Report Bug") {
                        NotificationCenter.default.post(name: .jfReportBugRequested, object: nil)
                    }
                    .buttonStyle(.bordered)
                    .contentShape(Rectangle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
                .overlay(Divider(), alignment: .bottom)

                // Main Content with proper scaling
                ScalableContainer(base: ResponsiveLayout.kDesignBase) {
                    detailContent
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)

        // Modern onChange (macOS 14+ signature). We’re not using the deprecated one.
        .onChange(of: selectedTool) { _, newValue in
            if newValue != nil { columnVisibility = .detailOnly }
        }

        // Global event listeners for app-wide functionality
        .onReceive(NotificationCenter.default.publisher(for: .jfHomeRequested)) { _ in
            resetTool()
        }
        .onReceive(NotificationCenter.default.publisher(for: .jfChangeMDMRequested)) { _ in
            resetMDM()
        }
        .onReceive(NotificationCenter.default.publisher(for: .jfAccountSettingsRequested)) { _ in
            showingAccountSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .jfReportBugRequested)) { _ in
            // Handle bug reporting - could open email or GitHub issue
            print("Bug report requested")
        }
        .sheet(isPresented: $showingAccountSettings) {
            SettingsView(userSettings: UserSettings())
        }
    }

    // MARK: - Reset helpers
    private func resetTool() {
        selectedTool = nil
        columnVisibility = .all
    }

    private func resetMDM() {
        selectedMDM  = nil
        selectedTool = nil
        columnVisibility = .all
    }
}

#Preview { ContentView() }
