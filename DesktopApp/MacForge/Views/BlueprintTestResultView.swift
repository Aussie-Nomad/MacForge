import SwiftUI

/// Blueprint Test Result View for displaying test results
struct BlueprintTestResultView: View {
    let result: BlueprintTestResult
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    testResultHeaderView
                    
                    // Test Summary
                    testSummaryView
                    
                    // Issues
                    if !result.issues.isEmpty {
                        issuesSectionView
                    }
                    
                    // Recommendations
                    if !result.recommendations.isEmpty {
                        recommendationsSectionView
                    }
                    
                    // Next Steps
                    nextStepsView
                }
                .padding()
            }
            .navigationTitle("Test Results")

            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var testResultHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(result.success ? .green : .red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.success ? "Test Passed" : "Test Failed")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(result.success ? "Blueprint is ready for deployment" : "Blueprint test failed")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Test Statistics
            HStack(spacing: 20) {
                VStack {
                    Text("\(result.deploymentTime)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    
                    Text("Minutes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text("\(result.issues.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    
                    Text("Issues")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text("\(result.recommendations.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    
                    Text("Recommendations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var testSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Deployment Time:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(result.deploymentTime) minutes")
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Test Status:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.success ? .green : .red)
                        
                        Text(result.success ? "Passed" : "Failed")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                
                HStack {
                    Text("Issues Found:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(result.issues.count)")
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Recommendations:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(result.recommendations.count)")
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var issuesSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 20)
                
                Text("Issues Found")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(result.issues.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(result.issues.enumerated()), id: \.offset) { index, issue in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: issueIcon(for: issue))
                            .font(.caption)
                            .foregroundStyle(issueColor(for: issue))
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(issueTitle(for: issue))
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text(issueDescription(for: issue))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(.quaternary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var recommendationsSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.green)
                    .frame(width: 20)
                
                Text("Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(result.recommendations.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.2))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(result.recommendations.enumerated()), id: \.offset) { index, recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recommendationTitle(for: recommendation))
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text(recommendation.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(.quaternary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var nextStepsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Steps")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                if result.success {
                    Text("✅ Your blueprint test was successful! You can now:")
                        .font(.body)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Save the blueprint for future use")
                        Text("• Deploy it to test devices")
                        Text("• Share it with your team")
                        Text("• Export it for backup")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                } else {
                    Text("❌ Your blueprint test failed. Please:")
                        .font(.body)
                        .foregroundStyle(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Review and fix the issues above")
                        Text("• Address any warnings or recommendations")
                        Text("• Re-test the blueprint")
                        Text("• Contact support if problems persist")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func issueIcon(for issue: BlueprintTestIssue) -> String {
        switch issue {
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        case .info:
            return "info.circle"
        }
    }
    
    private func issueColor(for issue: BlueprintTestIssue) -> Color {
        switch issue {
        case .warning:
            return .orange
        case .error:
            return .red
        case .info:
            return .blue
        }
    }
    
    private func issueTitle(for issue: BlueprintTestIssue) -> String {
        switch issue {
        case .warning(let message):
            return "Warning: \(message)"
        case .error(let message):
            return "Error: \(message)"
        case .info(let message):
            return "Info: \(message)"
        }
    }
    
    private func issueDescription(for issue: BlueprintTestIssue) -> String {
        switch issue {
        case .warning:
            return "This is a warning that should be addressed for better security or functionality."
        case .error:
            return "This is an error that must be fixed before deployment."
        case .info:
            return "This is informational and may help improve your blueprint."
        }
    }
    
    private func recommendationTitle(for recommendation: BlueprintRecommendation) -> String {
        switch recommendation {
        case .security:
            return "Security Recommendation"
        case .network:
            return "Network Recommendation"
        case .compliance:
            return "Compliance Recommendation"
        case .application:
            return "Application Recommendation"
        }
    }
}

// MARK: - Preview

#Preview {
    BlueprintTestResultView(result: BlueprintTestResult(
        success: true,
        deploymentTime: 15,
        issues: [
            .warning("FileVault encryption is not required"),
            .info("Consider adding more compliance rules")
        ],
        recommendations: [
            .security(.enableFileVault),
            .network(.secureWiFiNetworks),
            .compliance(.addDeviceCompliance)
        ]
    ))
}
