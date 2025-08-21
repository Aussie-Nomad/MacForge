//
//  WizardAndDetails.swift
//  MacForge
//
//  Created by Danny Mac on 14/08/2025.
//
// V3

import SwiftUI

struct WizardHeader: View {
    let step: Int
    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { s in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(s <= step ? LcarsTheme.amber : LcarsTheme.panel)
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            
            // Step indicators
            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { s in
                    VStack(spacing: 8) {
                        // Step circle
                        ZStack {
                            Circle()
                                .fill(s <= step ? LcarsTheme.amber : LcarsTheme.panel)
                                .frame(width: 32, height: 32)
                            
                            if s < step {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.black)
                            } else {
                                Text("\(s)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(s == step ? .black : .secondary)
                            }
                        }
                        
                        // Step label
                        Text(["Select App", "Permissions", "Review"][s-1])
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(s <= step ? LcarsTheme.amber : .secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct PermissionCard: View {
    let title: String
    @Binding var decision: AuthDecision
    var highlight: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).fontWeight(.heavy).foregroundStyle(LcarsTheme.amber)
            HStack(spacing: 8) {
                ForEach(AuthDecision.allCases, id: \.self) { d in
                    let isSelected = decision == d
                    Button { withAnimation(.easeInOut(duration: 0.12)) { decision = d } } label: {
                        Text(d.rawValue).font(.caption).fontWeight(.black)
                            .padding(.vertical, 6).padding(.horizontal, 10)
                            .frame(minWidth: 56)
                    }
                    .buttonStyle(.bordered)
                    .tint(isSelected ? (d == .allow ? .green : d == .deny ? .red : .yellow) : Color.gray.opacity(0.14))
                    .controlSize(.small)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? .white.opacity(0.9) : .clear, lineWidth: 1.5))
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16).fill(LcarsTheme.panel))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(highlight ? .red : LcarsTheme.orange, lineWidth: highlight ? 3 : 2))
    }
}

struct SettingsHeader: View {
    @Binding var settings: ProfileSettings
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROFILE SETTINGS").font(.headline).foregroundStyle(LcarsTheme.amber)
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    ThemedField(title: "Name", text: $settings.name)
                    ThemedField(title: "Organization", text: $settings.organization)
                }
                HStack(spacing: 12) { ThemedField(title: "Identifier", text: $settings.identifier) }
            }
        }
    }
}

struct ActivePayloadRow: View {
    let payload: Payload
    var isSelected: Bool
    var onSelect: () -> Void
    var onRemove: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(payload.icon).font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(payload.name).font(.headline)
                    Text(payload.description).font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 6) { ForEach(payload.platforms, id: \.self) { Image(systemName: platformSymbol($0)) } }
                }
                Spacer()
                HStack(spacing: 8) {
                    Button(action: onSelect) { Image(systemName: "gearshape") }
                    Button(role: .destructive, action: onRemove) { Image(systemName: "trash") }
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(4)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}
