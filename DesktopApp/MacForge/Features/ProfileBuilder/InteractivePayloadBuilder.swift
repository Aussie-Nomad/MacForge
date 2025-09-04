//
//  InteractivePayloadBuilder.swift
//  MacForge
//
//  Interactive MDM payload builder interface with visual configuration forms,
//  real-time preview, and validation against Apple's requirements.
//

import SwiftUI

// MARK: - Main Interactive Payload Builder
struct InteractivePayloadBuilder: View {
    @ObservedObject var model: BuilderModel
    @State private var selectedPayload: Payload?
    @State private var showingPayloadConfig = false
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingPreview = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Main Content
            HStack(spacing: 0) {
                // Left Panel - Payload Library
                payloadLibraryPanel
                
                // Right Panel - Configuration Area
                configurationPanel
            }
        }
        .background(LCARSTheme.background)
        .sheet(isPresented: $showingPayloadConfig) {
            if let payload = selectedPayload {
                PayloadConfigurationSheet(
                    payload: payload,
                    model: model,
                    isPresented: $showingPayloadConfig
                )
            }
        }
        .sheet(isPresented: $showingPreview) {
            ProfilePreviewSheet(model: model)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INTERACTIVE PAYLOAD BUILDER")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundStyle(LCARSTheme.accent)
                    
                    Text("Configure MDM payloads with visual forms and real-time validation")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button("Preview Profile") {
                        showingPreview = true
                    }
                    .buttonStyle(LcarsButtonStyle())
                    
                    Button("Export Profile") {
                        exportProfile()
                    }
                    .buttonStyle(LcarsButtonStyle())
                    .disabled(model.dropped.isEmpty)
                }
            }
            
            // Progress Indicator
            if !model.dropped.isEmpty {
                HStack {
                    Text("\(model.dropped.count) payloads configured")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("Profile ready for export")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LCARSTheme.accent.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(LCARSTheme.surface)
    }
    
    // MARK: - Payload Library Panel
    private var payloadLibraryPanel: some View {
        VStack(spacing: 0) {
            // Search and Filter
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    TextField("Search payloads...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(16)
            .background(LCARSTheme.panel)
            
            // Payload Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(filteredPayloads) { payload in
                        PayloadLibraryCard(
                            payload: payload,
                            isSelected: model.dropped.contains(where: { $0.id == payload.id }),
                            onSelect: { selectPayload(payload) }
                        )
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 400)
        .background(LCARSTheme.surface)
    }
    
    // MARK: - Configuration Panel
    private var configurationPanel: some View {
        VStack(spacing: 0) {
            if model.dropped.isEmpty {
                emptyConfigurationView
            } else {
                configuredPayloadsView
            }
        }
        .frame(maxWidth: .infinity)
        .background(LCARSTheme.surface)
    }
    
    // MARK: - Empty Configuration View
    private var emptyConfigurationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.gearshape")
                .font(.system(size: 64))
                .foregroundStyle(LCARSTheme.textMuted)
            
            Text("No Payloads Configured")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            Text("Select payloads from the library to start building your configuration profile")
                .font(.body)
                .foregroundStyle(LCARSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Browse Payload Library") {
                // Focus on library
            }
            .buttonStyle(LcarsButtonStyle())
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Configured Payloads View
    private var configuredPayloadsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Configured Payloads")
                    .font(.headline)
                    .foregroundStyle(LCARSTheme.textPrimary)
                
                Spacer()
                
                Text("\(model.dropped.count) of \(model.library.count)")
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
            }
            .padding(16)
            .background(LCARSTheme.panel)
            
            // Payload List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(model.dropped) { payload in
                        ConfiguredPayloadRow(
                            payload: payload,
                            onEdit: { editPayload(payload) },
                            onRemove: { removePayload(payload) }
                        )
                    }
                }
                .padding(16)
            }
        }
    }
    
    // MARK: - Helper Methods
    private var filteredPayloads: [Payload] {
        let categoryFiltered = selectedCategory == "All" ? model.library : model.library.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { payload in
                payload.name.localizedCaseInsensitiveContains(searchText) ||
                payload.description.localizedCaseInsensitiveContains(searchText) ||
                payload.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func selectPayload(_ payload: Payload) {
        if model.dropped.contains(where: { $0.id == payload.id }) {
            model.remove(payload.id)
        } else {
            model.add(payload)
        }
    }
    
    private func editPayload(_ payload: Payload) {
        selectedPayload = payload
        showingPayloadConfig = true
    }
    
    private func removePayload(_ payload: Payload) {
        model.remove(payload.id)
    }
    
    private func exportProfile() {
        // Handle profile export
        do {
            let url = try model.saveProfileToDownloads()
            print("Profile exported to: \(url)")
        } catch {
            print("Export failed: \(error)")
        }
    }
}

// MARK: - Payload Library Card
struct PayloadLibraryCard: View {
    let payload: Payload
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(payload.icon)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(payload.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(LCARSTheme.textPrimary)
                        
                        Text(payload.category)
                            .font(.caption)
                            .foregroundStyle(LCARSTheme.accent)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(LCARSTheme.accent)
                    }
                }
                
                // Description
                Text(payload.description)
                    .font(.caption)
                    .foregroundStyle(LCARSTheme.textSecondary)
                    .lineLimit(2)
                
                // Platforms
                HStack {
                    ForEach(payload.platforms, id: \.self) { platform in
                        PlatformBadge(platform: platform, color: LCARSTheme.accent)
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? LCARSTheme.accent.opacity(0.1) : LCARSTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? LCARSTheme.accent : LCARSTheme.primary.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Configured Payload Row
struct ConfiguredPayloadRow: View {
    let payload: Payload
    let onEdit: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon and Info
            HStack(spacing: 12) {
                Text(payload.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(LCARSTheme.textPrimary)
                    
                    Text(payload.description)
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Remove") {
                    onRemove()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    InteractivePayloadBuilder(model: BuilderModel())
}
