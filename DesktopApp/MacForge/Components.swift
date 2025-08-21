//
//  Components.swift
//  MacForge
//
//  Created by Danny Mac on 14/08/2025.
//
// V3

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Sidebar Brand Header (tall card at the very top)
struct SidebarBrandHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                JamforgeMark(38) // falls back to SF Symbol if asset missing
                VStack(alignment: .leading, spacing: 2) {
                    Text("MacForge")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                    Text("Author: Daniel McDermott")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Last Updated: \(Date.now.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: LcarsTheme.Sidebar.tileCorner, style: .continuous)
                .stroke(LcarsTheme.amber, lineWidth: LcarsTheme.Sidebar.tileStroke)
        )
    }
}

// MARK: - Shared chrome for LCARS inputs
private struct LcarsFieldChrome: ViewModifier {
    var corner: CGFloat = 12
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(LcarsTheme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(LcarsTheme.orange, lineWidth: 2)
            )
    }
}

extension View {
    func lcarsFieldChrome(corner: CGFloat = 12) -> some View {
        modifier(LcarsFieldChrome(corner: corner))
    }
}

// MARK: - Small LCARS "pill" label used in the sidebar
struct LcarsPill: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(LcarsTheme.amber, lineWidth: 2)
            )
    }
}

// MARK: - Small button ("Change…") used under MDM list
struct LcarsSmallButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LcarsTheme.amber, lineWidth: 2)
        )
    }
}

// MARK: - ThemedField
/// `ThemedField(title: "Bundle Identifier", text: $bundleID)`
/// `ThemedField(title: "Team ID", text: Binding.constant(teamID))`
struct ThemedField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var monospaced: Bool = false
    var secure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2).fontWeight(.semibold)
                .foregroundStyle(LcarsTheme.amber.opacity(0.9))

            Group {
                if secure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .controlSize(.large)          // <- gives AppKit a friendlier default size
            .frame(minHeight: 28)         // <- avoids "min == max" complaints
            .font(monospaced ? .system(.body, design: .monospaced) : .body)
            .lcarsFieldChrome()
        }
    }
}

// MARK: - Top Toolbar (global actions for builder screens)
struct TopToolbar: View {
    var onHome: () -> Void
    var onChangeMDM: () -> Void
    var onReportBug: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // App mark + title at left
            HStack(spacing: 10) {
                JamforgeMark(24)
                Text("MacForge")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LcarsTheme.amber, lineWidth: 2)
            )

            Spacer()

            // Primary actions on the right
            Button("Home", action: onHome)
                .buttonStyle(LcarsButtonStyle())

            Button("Change MDM", action: onChangeMDM)
                .buttonStyle(LcarsButtonStyle())

            Button("Report Bug", action: onReportBug)
                .buttonStyle(LcarsButtonStyle())
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LcarsTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LcarsTheme.orange, lineWidth: 2)
                )
        )
    }
}

// MARK: - Disabled tile (Tools section before MDM connect)
struct LcarsDisabledTile: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
            if let s = subtitle {
                Text(s)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: LcarsTheme.Sidebar.tileCorner, style: .continuous)
                .stroke(LcarsTheme.amber, lineWidth: LcarsTheme.Sidebar.tileStroke)
        )
        .opacity(0.6)
    }
}

// MARK: - DropTarget
/// Tiny wrapper around `.onDrop` that gives you a styled, highlightable drop zone.
struct DropTarget<Content: View>: View {
    var acceptedTypes: [UTType] = [.fileURL]
    var onDrop: ([NSItemProvider]) -> Bool
    @ViewBuilder var content: () -> Content

    @State private var isTargeted = false

    var body: some View {
        content()
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isTargeted ? LcarsTheme.amber
                                       : LcarsTheme.orange.opacity(0.45),
                            lineWidth: isTargeted ? 3 : 2)
            )
            .onDrop(of: acceptedTypes.map(\.identifier),
                    isTargeted: $isTargeted,
                    perform: onDrop)
    }
}

// MARK: - Sidebar tile row (Jamf / Intune / Kandji / Mosyle)
struct LcarsTileItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let imageName: String   // asset name like "mdm_jamf"
}

struct LcarsTileRow: View {
    let items: [LcarsTileItem]
    let action: (LcarsTileItem) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(items) { item in
                LcarsTileButton(item: item, action: action)
            }
        }
    }
}

// Extract the button into a separate view to simplify the compiler's job
private struct LcarsTileButton: View {
    let item: LcarsTileItem
    let action: (LcarsTileItem) -> Void
    
    var body: some View {
        Button {
            action(item)
        } label: {
            HStack(spacing: 10) {
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.25), lineWidth: 1)
                    )
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .semibold))
                    .opacity(0.4)
            }
            .padding(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: LcarsTheme.Sidebar.tileCorner, style: .continuous)
                .fill(LcarsTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LcarsTheme.Sidebar.tileCorner, style: .continuous)
                .stroke(LcarsTheme.amber, lineWidth: LcarsTheme.Sidebar.tileStroke)
        )
    }
}
