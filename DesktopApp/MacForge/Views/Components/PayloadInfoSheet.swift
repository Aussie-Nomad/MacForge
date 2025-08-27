//
//  PayloadInfoSheet.swift
//  MacForge
//
//  Detailed information sheet for payload types.
//  Provides comprehensive explanations and usage guidance.
//

import SwiftUI

struct PayloadInfoSheet: View {
    let payload: PayloadType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(payload.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(LCARSTheme.accent)
                    
                    Text(payload.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(LCARSTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LCARSTheme.accent.opacity(0.2))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(LCARSTheme.accent)
            }
            .padding(20)
            .background(LCARSTheme.panel)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        Text(payload.description)
                            .font(.body)
                            .foregroundStyle(LCARSTheme.textSecondary)
                            .lineLimit(nil)
                    }
                    
                    // Platform Support
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Platform Support")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        HStack(spacing: 16) {
                            if payload.supportsMacOS {
                                PlatformSupportCard(
                                    platform: "macOS",
                                    icon: "desktopcomputer",
                                    color: .blue,
                                    description: "Full support for macOS devices"
                                )
                            }
                            
                            if payload.supportsIOS {
                                PlatformSupportCard(
                                    platform: "iOS",
                                    icon: "iphone",
                                    color: .green,
                                    description: "Full support for iOS devices"
                                )
                            }
                            
                            if payload.supportsTvOS {
                                PlatformSupportCard(
                                    platform: "tvOS",
                                    icon: "tv",
                                    color: .purple,
                                    description: "Full support for tvOS devices"
                                )
                            }
                        }
                    }
                    
                    // Complexity Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Configuration Complexity")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        HStack(spacing: 16) {
                            ComplexityIndicator(complexity: payload.complexity)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(payload.complexity.description)
                                    .font(.body)
                                    .foregroundStyle(LCARSTheme.textSecondary)
                                
                                Text("This payload requires \(payload.complexity.rawValue.lowercased()) knowledge to configure properly.")
                                    .font(.caption)
                                    .foregroundStyle(LCARSTheme.textMuted)
                            }
                        }
                    }
                    
                    // Use Cases
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Common Use Cases")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(useCases, id: \.self) { useCase in
                                UseCaseCard(useCase: useCase)
                            }
                        }
                    }
                    
                    // Technical Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Technical Details")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "Identifier", value: payload.rawValue)
                            DetailRow(label: "Category", value: payload.category.displayName)
                            DetailRow(label: "Complexity", value: payload.complexity.rawValue)
                        }
                        .padding(12)
                        .background(LCARSTheme.surface)
                        .cornerRadius(8)
                    }
                    
                    // Documentation Link
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Learn More")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.accent)
                        
                        Link(destination: URL(string: payload.documentationURL)!) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Apple Developer Documentation")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .padding(12)
                            .background(LCARSTheme.panel)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(LCARSTheme.accent, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 700, height: 600)
        .background(LCARSTheme.background)
    }
    
    private var useCases: [String] {
        switch payload {
        case .fileVault:
            return ["Enterprise data protection", "Compliance requirements", "Device security", "Data loss prevention"]
        case .gatekeeper:
            return ["Application security", "Malware prevention", "Developer tool control", "Enterprise app management"]
        case .firewall:
            return ["Network security", "Access control", "Traffic filtering", "Security compliance"]
        case .pppc:
            return ["Privacy protection", "App permissions", "System resource access", "User privacy control"]
        case .wifi:
            return ["Corporate network access", "Guest network setup", "Network security", "Roaming profiles"]
        case .vpn:
            return ["Remote access", "Secure connections", "Corporate network access", "Data encryption"]
        default:
            return ["Device management", "Policy enforcement", "User experience", "Security compliance"]
        }
    }
}

// MARK: - Platform Support Card
struct PlatformSupportCard: View {
    let platform: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(platform)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(LCARSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(LCARSTheme.panel)
        .cornerRadius(12)
    }
}

// MARK: - Complexity Indicator
struct ComplexityIndicator: View {
    let complexity: PayloadComplexity
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(complexityColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(complexity.rawValue.prefix(1))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                )
            
            Text(complexity.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(complexityColor)
        }
    }
    
    private var complexityColor: Color {
        switch complexity {
        case .basic: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Use Case Card
struct UseCaseCard: View {
    let useCase: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            
            Text(useCase)
                .font(.caption)
                .foregroundStyle(LCARSTheme.textSecondary)
                .lineLimit(2)
        }
        .padding(8)
        .background(LCARSTheme.surface)
        .cornerRadius(6)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(LCARSTheme.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundStyle(LCARSTheme.textPrimary)
                .font(.system(.caption, design: .monospaced))
            
            Spacer()
        }
    }
}

#Preview {
    PayloadInfoSheet(payload: .fileVault)
}
