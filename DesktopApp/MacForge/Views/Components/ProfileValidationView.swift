//
//  ProfileValidationView.swift
//  MacForge
//
//  Profile validation results display component.
//  Shows errors, warnings, compliance issues, and suggestions.
//

import SwiftUI

struct ProfileValidationView: View {
    let validationResult: ProfileValidationResult
    let onFixError: ((ProfileValidationError) -> Void)?
    let onApplySuggestion: ((ValidationSuggestion) -> Void)?
    
    @State private var selectedTab = "Errors"
    @State private var showingReport = false
    
    private let tabs = ["Errors", "Warnings", "Compliance", "Suggestions"]
    
    init(validationResult: ProfileValidationResult, 
         onFixError: ((ProfileValidationError) -> Void)? = nil,
         onApplySuggestion: ((ValidationSuggestion) -> Void)? = nil) {
        self.validationResult = validationResult
        self.onFixError = onFixError
        self.onApplySuggestion = onApplySuggestion
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Validation")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(validationResult.isValid ? "Profile is valid" : "Profile has issues")
                        .font(.subheadline)
                        .foregroundStyle(validationResult.isValid ? .green : .red)
                }
                
                Spacer()
                
                Button("View Report") {
                    showingReport = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(LCARSTheme.panel)
            
            // Tab Navigation
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    Button(tab) {
                        selectedTab = tab
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? LCARSTheme.accent : Color.clear)
                    .foregroundStyle(selectedTab == tab ? .black : LCARSTheme.textPrimary)
                    .cornerRadius(8)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            // Tab Content
            TabView(selection: $selectedTab) {
                // Errors Tab
                ValidationErrorsView(
                    errors: validationResult.errors,
                    onFixError: onFixError
                )
                .tag("Errors")
                
                // Warnings Tab
                ValidationWarningsView(
                    warnings: validationResult.warnings
                )
                .tag("Warnings")
                
                // Compliance Tab
                ComplianceIssuesView(
                    issues: validationResult.complianceIssues
                )
                .tag("Compliance")
                
                // Suggestions Tab
                ValidationSuggestionsView(
                    suggestions: validationResult.suggestions,
                    onApplySuggestion: onApplySuggestion
                )
                .tag("Suggestions")
            }
            .tabViewStyle(.automatic)
        }
        .sheet(isPresented: $showingReport) {
            ValidationReportSheet(validationResult: validationResult)
        }
    }
}

// MARK: - Validation Errors View
struct ValidationErrorsView: View {
    let errors: [ProfileValidationError]
    let onFixError: ((ProfileValidationError) -> Void)?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if errors.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        
                        Text("No Errors Found")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.textPrimary)
                        
                        Text("Your profile configuration is error-free!")
                            .font(.body)
                            .foregroundStyle(LCARSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    ForEach(Array(errors.enumerated()), id: \.offset) { index, error in
                        ValidationErrorCard(
                            error: error,
                            index: index + 1,
                            onFix: onFixError
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Validation Warnings View
struct ValidationWarningsView: View {
    let warnings: [ProfileValidationWarning]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if warnings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                        
                        Text("No Warnings")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.textPrimary)
                        
                        Text("Your profile configuration has no warnings.")
                            .font(.body)
                            .foregroundStyle(LCARSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    ForEach(Array(warnings.enumerated()), id: \.offset) { index, warning in
                        ValidationWarningCard(
                            warning: warning,
                            index: index + 1
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Compliance Issues View
struct ComplianceIssuesView: View {
    let issues: [ComplianceError]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if issues.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        
                        Text("No Compliance Issues")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.textPrimary)
                        
                        Text("Your profile complies with Apple's MDM requirements.")
                            .font(.body)
                            .foregroundStyle(LCARSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    ForEach(Array(issues.enumerated()), id: \.offset) { index, issue in
                        ComplianceIssueCard(
                            issue: issue,
                            index: index + 1
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Validation Suggestions View
struct ValidationSuggestionsView: View {
    let suggestions: [ValidationSuggestion]
    let onApplySuggestion: ((ValidationSuggestion) -> Void)?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if suggestions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)
                        
                        Text("No Suggestions")
                            .font(.headline)
                            .foregroundStyle(LCARSTheme.textPrimary)
                        
                        Text("Your profile configuration is optimal!")
                            .font(.body)
                            .foregroundStyle(LCARSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        ValidationSuggestionCard(
                            suggestion: suggestion,
                            index: index + 1,
                            onApply: onApplySuggestion
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Validation Cards

struct ValidationErrorCard: View {
    let error: ProfileValidationError
    let index: Int
    let onFix: ((ProfileValidationError) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Error \(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                if onFix != nil {
                    Button("Fix") {
                        onFix?(error)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            // ProfileValidationError doesn't have suggestion property
            // Using errorDescription instead
        }
        .padding()
        .background(LCARSTheme.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ValidationWarningCard: View {
    let warning: ProfileValidationWarning
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Warning \(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
            }
            
            Text(warning.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            if let recommendation = warning.recommendation {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendation:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    Text(recommendation)
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                }
            }
        }
        .padding()
        .background(LCARSTheme.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ComplianceIssueCard: View {
    let issue: ComplianceError
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Compliance Issue \(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
            }
            
            Text(issue.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            if let remediation = issue.remediation {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remediation:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    Text(remediation)
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                }
            }
        }
        .padding()
        .background(LCARSTheme.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ValidationSuggestionCard: View {
    let suggestion: ValidationSuggestion
    let index: Int
    let onApply: ((ValidationSuggestion) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Suggestion \(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(suggestionPriorityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(suggestionPriorityColor.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                if onApply != nil {
                    Button("Apply") {
                        onApply?(suggestion)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            Text(suggestion.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(LCARSTheme.textPrimary)
            
            Text(suggestion.impact)
                .font(.caption)
                .foregroundStyle(LCARSTheme.textSecondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Implementation:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(LCARSTheme.textSecondary)
                
                if let implementation = suggestion.implementation {
                    Text(implementation)
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textSecondary)
                } else {
                    Text("No specific implementation details")
                        .font(.caption)
                        .foregroundStyle(LCARSTheme.textMuted)
                        .italic()
                }
            }
        }
        .padding()
        .background(LCARSTheme.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(suggestionPriorityColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var suggestionPriorityColor: Color {
        switch suggestion.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Validation Report Sheet
struct ValidationReportSheet: View {
    let validationResult: ProfileValidationResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(validationResult.isValid ? "Profile Validation Passed" : "Profile Validation Failed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(validationResult.isValid ? .green : .red)
                    
                    Text("Detailed validation report for your configuration profile")
                        .font(.body)
                        .foregroundStyle(LCARSTheme.textSecondary)
                    
                    Divider()
                    
                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("Valid:")
                            Spacer()
                            Text(validationResult.isValid ? "Yes" : "No")
                                .fontWeight(.semibold)
                                .foregroundStyle(validationResult.isValid ? .green : .red)
                        }
                        
                        HStack {
                            Text("Errors:")
                            Spacer()
                            Text("\(validationResult.errors.count)")
                                .fontWeight(.semibold)
                                .foregroundStyle(validationResult.errors.isEmpty ? .green : .red)
                        }
                        
                        HStack {
                            Text("Warnings:")
                            Spacer()
                            Text("\(validationResult.warnings.count)")
                                .fontWeight(.semibold)
                                .foregroundStyle(validationResult.warnings.isEmpty ? .green : .orange)
                        }
                        
                        HStack {
                            Text("Compliance Issues:")
                            Spacer()
                            Text("\(validationResult.complianceIssues.count)")
                                .fontWeight(.semibold)
                                .foregroundStyle(validationResult.complianceIssues.isEmpty ? .green : .red)
                        }
                        
                        HStack {
                            Text("Suggestions:")
                            Spacer()
                            Text("\(validationResult.suggestions.count)")
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(LCARSTheme.surface)
                    .cornerRadius(8)
                    
                    // Export Report Button
                    Button("Export Report") {
                        exportReport()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("Validation Report")
            .navigationTitle("Validation Report")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportReport() {
        // TODO: Implement report export functionality
        print("Export validation report")
    }
}

#Preview {
    let sampleErrors = [
        ProfileValidationError.invalidName,
        ProfileValidationError.invalidIdentifier
    ]
    
    let sampleWarnings = [
        ProfileValidationWarning(
            type: .bestPractice,
            message: "Profile name 'Very Long Profile Name That Exceeds Recommended Length' is longer than recommended (50 characters)",
            severity: .low,
            recommendation: "Consider using a shorter, more concise name"
        ),
        ProfileValidationWarning(
            type: .performance,
            message: "Profile contains 15 payloads, which may impact performance",
            severity: .medium,
            recommendation: "Consider splitting into multiple profiles if possible"
        )
    ]
    
    let sampleComplianceIssues = [
        ComplianceError(
            type: .apple,
            message: "WiFi payload is missing required fields: SSID, SecurityType",
            severity: .critical,
            requirement: "All required fields must be present for WiFi payloads",
            remediation: "Add the missing required fields: SSID, SecurityType",
            missingRequiredFields: ["SSID", "SecurityType"]
        )
    ]
    
    let sampleSuggestions = [
        ValidationSuggestion(
            type: .userExperience,
            message: "Add Profile Name",
            priority: .high,
            impact: "A descriptive name helps identify the profile's purpose",
            implementation: "Enter a clear, descriptive name for your profile"
        )
    ]
    
    let sampleResult = ProfileValidationResult(
        isValid: false,
        errors: sampleErrors,
        warnings: sampleWarnings,
        complianceIssues: sampleComplianceIssues,
        suggestions: sampleSuggestions
    )
    
    ProfileValidationView(validationResult: sampleResult)
}
