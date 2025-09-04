import SwiftUI
import UniformTypeIdentifiers

/// Blueprint Import View for importing blueprints from files
struct BlueprintImportView: View {
    
    // MARK: - Properties
    
    let service: DDMBlueprintsService
    @Environment(\.dismiss) private var dismiss
    
    @State private var isImporting = false
    @State private var importProgress: Double = 0.0
    @State private var importStatus = ""
    @State private var showingFilePicker = false
    @State private var importedBlueprints: [DDMBlueprint] = []
    @State private var showingImportResults = false
    @State private var importError: Error?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                importHeaderView
                
                if isImporting {
                    // Import Progress
                    importProgressView
                } else if !importedBlueprints.isEmpty {
                    // Import Results
                    importResultsView
                } else {
                    // Import Options
                    importOptionsView
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import Blueprints")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !importedBlueprints.isEmpty && !isImporting {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Import All") {
                            importAllBlueprints()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.json, UTType(filenameExtension: "blueprint") ?? .data],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
        }
    }
    
    // MARK: - Import Header View
    
    private var importHeaderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            VStack(spacing: 4) {
                Text("Import Blueprints")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Import blueprint configurations from files")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Import Options View
    
    private var importOptionsView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Import Options")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Supported Formats:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• JSON files (.json)")
                        Text("• Blueprint files (.blueprint)")
                        Text("• Archive files (.zip)")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import Process:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Select one or more blueprint files")
                        Text("2. Review the imported blueprints")
                        Text("3. Choose which blueprints to import")
                        Text("4. Blueprints will be added to your library")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            
            Button("Select Files") {
                showingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    // MARK: - Import Progress View
    
    private var importProgressView: some View {
        VStack(spacing: 16) {
            ProgressView(value: importProgress, total: 1.0)
                .progressViewStyle(.linear)
            
            Text(importStatus)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if importProgress >= 1.0 {
                Button("View Results") {
                    showingImportResults = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Import Results View
    
    private var importResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Import Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(importedBlueprints.count) blueprints")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(importedBlueprints) { blueprint in
                        ImportedBlueprintRowView(blueprint: blueprint)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            importBlueprints(from: urls)
        case .failure(let error):
            importError = error
        }
    }
    
    private func importBlueprints(from urls: [URL]) {
        isImporting = true
        importProgress = 0.0
        importStatus = "Starting import..."
        
        Task {
            do {
                var imported: [DDMBlueprint] = []
                let totalFiles = urls.count
                
                for (index, url) in urls.enumerated() {
                    await MainActor.run {
                        importStatus = "Importing \(url.lastPathComponent)..."
                    }
                    
                    let blueprints = try await service.importBlueprints(from: url)
                    imported.append(contentsOf: blueprints)
                    
                    await MainActor.run {
                        importProgress = Double(index + 1) / Double(totalFiles)
                    }
                }
                
                await MainActor.run {
                    importedBlueprints = imported
                    importStatus = "Import completed successfully"
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importError = error
                    importStatus = "Import failed: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }
    
    private func importAllBlueprints() {
        isImporting = true
        importProgress = 0.0
        importStatus = "Adding blueprints to library..."
        
        Task {
            do {
                let totalBlueprints = importedBlueprints.count
                
                for (index, blueprint) in importedBlueprints.enumerated() {
                    try await service.createBlueprint(blueprint)
                    
                    await MainActor.run {
                        importProgress = Double(index + 1) / Double(totalBlueprints)
                        importStatus = "Added \(blueprint.name)..."
                    }
                }
                
                await MainActor.run {
                    importStatus = "All blueprints imported successfully"
                    isImporting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    importError = error
                    importStatus = "Import failed: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }
}

// MARK: - Imported Blueprint Row View

struct ImportedBlueprintRowView: View {
    let blueprint: DDMBlueprint
    @State private var isSelected = true
    
    var body: some View {
        HStack {
            Toggle("", isOn: $isSelected)
                .toggleStyle(.checkbox)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(blueprint.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(blueprint.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(blueprint.category.rawValue, systemImage: blueprint.category.icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(blueprint.metadata.complexity.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Button("Preview") {
                // Show preview
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    BlueprintImportView(service: DDMBlueprintsService())
}
