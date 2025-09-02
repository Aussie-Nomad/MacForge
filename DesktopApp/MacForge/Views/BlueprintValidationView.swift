import SwiftUI

/// Blueprint Validation View for displaying validation results
struct BlueprintValidationView: View {
    let result: BlueprintValidationResult
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    validationHeaderView
                    
                    // Errors
                    if !result.errors.isEmpty {
                        validationSectionView(
                            title: "Errors",
                            icon: "exclamationmark.triangle.fill",
                            color: .red,
                            items: result.errors.map { $0.localizedDescription }
                        )
                    }
                    
                    // Warnings
                    if !result.warnings.isEmpty {
                        validationSectionView(
                            title: "Warnings",
                            icon: "exclamationmark.triangle",
                            color: .orange,
                            items: result.warnings.map { $0.localizedDescription }
                        )
                    }
                    
                    // Summary
                    validationSummaryView
                }
                .padding()
            }
            .navigationTitle("Blueprint Validation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var validationHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(result.isValid ? .green : .red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.isValid ? "Validation Passed" : "Validation Failed")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(result.isValid ? "Blueprint is ready for deployment" : "Please fix the errors below")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Statistics
            HStack(spacing: 20) {
                VStack {
                    Text("\(result.errors.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                    
                    Text("Errors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text("\(result.warnings.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    
                    Text("Warnings")
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
    
    private func validationSectionView(title: String, icon: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(items.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundStyle(color)
                            .padding(.top, 6)
                        
                        Text(item)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var validationSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                if result.isValid {
                    Text("✅ Your blueprint configuration is valid and ready for deployment.")
                        .font(.body)
                        .foregroundStyle(.green)
                } else {
                    Text("❌ Your blueprint has validation errors that must be fixed before deployment.")
                        .font(.body)
                        .foregroundStyle(.red)
                }
                
                if !result.warnings.isEmpty {
                    Text("⚠️ Consider addressing the warnings to improve your blueprint's quality and security.")
                        .font(.body)
                        .foregroundStyle(.orange)
                }
                
                Text("You can now test your blueprint or save it for future use.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    BlueprintValidationView(result: BlueprintValidationResult(
        isValid: false,
        errors: [
            .emptyName,
            .weakPasscodePolicy
        ],
        warnings: [
            .emptyDescription,
            .fileVaultNotRequired
        ]
    ))
}
