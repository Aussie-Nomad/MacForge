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
    @StateObject private var model = BuilderModel()

    // MARK: - Layout
    private let sidebarWidth: CGFloat = 320

    // MARK: - Detail content
    @ViewBuilder
    private var detailContent: some View {
        if let tool = selectedTool {
            switch tool {
            case .profileBuilder:
                ProfileBuilderHostView(selectedMDM: selectedMDM, model: model, onHome: { resetTool() })

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
            .themeAwareBackground()
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // LEFT: Global sidebar
            GlobalSidebar(
                selectedMDM: $selectedMDM,
                onChangeMDM: {
                    selectedMDM  = nil
                    selectedTool = nil
                },
                onSelectTool: { tool in
                    selectedTool = tool
                }
            )
            .frame(width: 320)
            .background(LCARSTheme.background)

            // RIGHT: Main content area
            VStack(spacing: 0) {
                // Top Utility Bar
                HStack(spacing: 12) {
                    Button("Change MDM") {
                        selectedMDM  = nil
                        selectedTool = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .contentShape(Rectangle())

                    Button("Change Tool") {
                        selectedTool = nil
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedTool == nil)
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

                // Main Content
                detailContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
