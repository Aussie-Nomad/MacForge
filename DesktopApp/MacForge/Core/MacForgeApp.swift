//
//  MacForgeApp.swift
//  MacForge
//
//  Main application entry point and global configuration.
//  Handles cross-platform orientation, window sizing, global commands, and app lifecycle events.
//  Uses NotificationCenter for decoupled communication between app components.

import SwiftUI


// MARK: - macOS Application Configuration
// MacForge is designed specifically for macOS MDM administration
// No cross-platform support needed for this desktop tool

// MARK: - App‑Wide Events (decoupled via NotificationCenter)
extension Notification.Name {
    /// User tapped "Home" in the toolbar/menu.
    static let jfHomeRequested = Notification.Name("jf.home.requested")
    /// User tapped "Change MDM" in the toolbar/menu.
    static let jfChangeMDMRequested = Notification.Name("jf.changeMDM.requested")
    /// User tapped "Report Bug".
    static let jfReportBugRequested = Notification.Name("jf.reportBug.requested")
    /// Scene phase changes so models can react (e.g., refresh tokens).
    static let jfAppBecameActive = Notification.Name("jf.app.becameActive")
    static let jfAppBackgrounded = Notification.Name("jf.app.backgrounded")
    /// Deep link routing (e.g., macforge://open/profilebuilder).
    static let jfOpenDeepLink = Notification.Name("jf.open.deepLink")
}

/// Convenience to post app‑wide events
@inline(__always)
private func jfPost(_ name: Notification.Name, _ payload: [AnyHashable: Any]? = nil) {
    NotificationCenter.default.post(name: name, object: nil, userInfo: payload)
}

// MARK: - MacForge Application
@main
struct MacForgeApp: App {
    // NOTE: We let ContentView own its own @StateObject private var model = BuilderModel()
    // Avoid injecting a second, competing instance here.

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.themeManager, ThemeManager.shared)

                /// Scene phase → broadcast so models can refresh, invalidate tokens, etc.
                .onChange(of: scenePhase, initial: true) { oldPhase, newPhase in
                    switch newPhase {
                    case .active:
                        jfPost(.jfAppBecameActive)
                    case .background:
                        jfPost(.jfAppBackgrounded)
                    default:
                        break
                    }
                }

                // Handle deep links (e.g., macforge://open/profilebuilder)
                .onOpenURL { url in
                    jfPost(.jfOpenDeepLink, ["url": url])
                }
        }
        // macOS window configuration: responsive sizing with proper minimums
        .defaultSize(width: 1440, height: 900)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
        .frame(minWidth: 1000, minHeight: 700)

        // Global command menu (posted as notifications)
        .commands {
            CommandMenu("MacForge") {
                Button("Home") { jfPost(.jfHomeRequested) }
                    .keyboardShortcut("h", modifiers: [.command])

                Button("Change MDM") { jfPost(.jfChangeMDMRequested) }
                    .keyboardShortcut("m", modifiers: [.command, .shift])

                Button("Report Bug") { jfPost(.jfReportBugRequested) }
                    .keyboardShortcut("b", modifiers: [.command, .shift])
            }
        }

        // Settings / About
        Settings {
            SettingsPane()
                .frame(minWidth: 520, idealWidth: 620, maxWidth: 800,
                       minHeight: 360, idealHeight: 420, maxHeight: 600)
        }
    }
}

// MARK: - Minimal Settings Pane (safe placeholder)
private struct SettingsPane: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Uses Assets.xcassets/MacForge (falls back to an empty image at runtime if missing)
                Image("MacForge")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel("MacForge Icon")

                VStack(alignment: .leading, spacing: 6) {
                    Text("MacForge")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("A toolbox for building and managing Apple MDM payloads.")
                        .foregroundStyle(.secondary)
                    Text("© \(Calendar.current.component(.year, from: .now)) Daniel McDermott")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
                Spacer()
            }

            Divider()

            Grid(horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text("Default Window Size")
                    Spacer()
                    Text("1440 × 900")
                        .monospaced()
                        .foregroundStyle(.secondary)
                }
                GridRow {
                    Text("Color Scheme")
                    Spacer()
                    Text("Dark (enforced)")
                        .foregroundStyle(.secondary)
                }
                GridRow {
                    Text("Platform")
                    Spacer()
                    Text("macOS Native")
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack {
                Link("GitHub", destination: URL(string: "https://github.com/")!)
                Link("Email", destination: URL(string: "mailto:daniel.mcdermott@zappistore.com")!)
                Spacer()
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"))")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
        .padding(20)
    }
}
