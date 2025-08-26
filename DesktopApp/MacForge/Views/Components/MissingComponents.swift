//
//  MissingComponents.swift
//  MacForge
//
//  UI components that were previously in the deleted Components.swift file.
//  Contains essential UI elements needed for the application to function properly.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - LCARS Tile Row Component
struct LcarsTileRow: View {
    let items: [LcarsTileItem]
    let onTap: ((LcarsTileItem) -> Void)?
    
    init(items: [LcarsTileItem], onTap: ((LcarsTileItem) -> Void)? = nil) {
        self.items = items
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                LcarsTile(item: item)
                    .onTapGesture {
                        onTap?(item)
                    }
            }
        }
    }
}

// MARK: - LCARS Tile Component
struct LcarsTile: View {
    let item: LcarsTileItem
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: item.imageName)
                .font(.title2)
                .foregroundStyle(LcarsTheme.amber)
            Text(item.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(width: 60, height: 60)
        .background(RoundedRectangle(cornerRadius: 8).fill(LcarsTheme.panel.opacity(0.3)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - LCARS Small Button Component
struct LcarsSmallButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(title, action: action)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(LcarsTheme.amber)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 4).fill(LcarsTheme.panel.opacity(0.3)))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(LcarsTheme.amber.opacity(0.5), lineWidth: 1))
            .contentShape(Rectangle())
    }
}

// MARK: - LCARS Tile Item Model
struct LcarsTileItem: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
}

// MARK: - Drop Target Component
struct DropTarget: View {
    let acceptedTypes: [UTType]
    let onDrop: ([NSItemProvider]) -> Bool
    let content: () -> AnyView
    
    init<Content: View>(acceptedTypes: [UTType], onDrop: @escaping ([NSItemProvider]) -> Bool, @ViewBuilder content: @escaping () -> Content) {
        self.acceptedTypes = acceptedTypes
        self.onDrop = onDrop
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        content()
            .onDrop(of: acceptedTypes, isTargeted: nil, perform: onDrop)
    }
}

// MARK: - Permission Card Component
struct PermissionCard: View {
    let title: String
    @Binding var decision: AuthDecision
    let highlight: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(highlight ? LcarsTheme.amber : .primary)
            
            Picker("Decision", selection: $decision) {
                Text("Ask").tag(AuthDecision.ask)
                Text("Allow").tag(AuthDecision.allow)
                Text("Deny").tag(AuthDecision.deny)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(highlight ? LcarsTheme.amber.opacity(0.1) : LcarsTheme.panel.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(highlight ? LcarsTheme.amber.opacity(0.5) : .secondary.opacity(0.3), lineWidth: 1)
        )
    }
}
