//  ContentView.swift
//  MacForge
//
//  Created by Danny Mac on 11/08/2025.
//
// V3

import SwiftUI

struct ContentView: View {
    // MARK: - App State
    @State private var selectedTool: ToolModule? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedMDM: MDMVendor? = nil
    @StateObject private var model = BuilderModel()

    // MARK: - Layout
    private let sidebarWidth: CGFloat = LcarsTheme.Sidebar.width

    // MARK: - Detail content
    @ViewBuilder
    private var detailContent: some View {
        if let tool = selectedTool {
            switch tool {
            case .profileBuilder:
                ProfileBuilderHostView(model: model, selectedMDM: selectedMDM, onHome: { resetTool() })

            case .packageSmelting:
                PackageSmeltingHostView(model: model, selectedMDM: selectedMDM)

            case .deviceFoundry:
                DeviceFoundryHostView(model: model, selectedMDM: selectedMDM)

            case .blueprintBuilder:
                BlueprintBuilderHostView(model: model, selectedMDM: selectedMDM)

            case .hammeringScripts:
                HammeringScriptsHostView(model: model, selectedMDM: selectedMDM)
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
            .background(LcarsTheme.bg)
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
            .background(LcarsTheme.bg)

        } detail: {
            // RIGHT: Main canvas
            ScalableContainer(base: kDesignBase) {
                // Top Utility Bar
                HStack(spacing: 12) {
                    Button("Change MDM") {
                        selectedMDM  = nil
                        selectedTool = nil
                        columnVisibility = .all
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Change Tool") {
                        selectedTool = nil
                        columnVisibility = .all
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedTool == nil)

                    Spacer()

                    Button("Report Bug") {
                        NotificationCenter.default.post(name: .jfReportBugRequested, object: nil)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .background(.ultraThinMaterial)
                .overlay(Divider(), alignment: .bottom)

                // Main Content
                detailContent
            }
        }
        .navigationSplitViewStyle(.balanced)

        // Modern onChange (macOS 14+ signature). We’re not using the deprecated one.
        .onChange(of: selectedTool) { _, newValue in
            if newValue != nil { columnVisibility = .detailOnly }
        }

        .jamforgeGlobalListeners(
            model: model,
            selectedMDM: $selectedMDM,
            selectedTool: $selectedTool
        )
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
