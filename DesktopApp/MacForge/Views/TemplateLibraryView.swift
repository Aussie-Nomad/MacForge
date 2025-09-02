import SwiftUI

/// Template Library View for browsing and managing DDM Blueprint templates
struct TemplateLibraryView: View {
    
    // MARK: - Properties
    
    let service: DDMBlueprintsService
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory: BlueprintCategory?
    @State private var selectedComplexity: BlueprintComplexity?
    @State private var sortBy: BlueprintSortOption = .name
    @State private var sortOrder: SortOrder = .ascending
    @State private var showingFilters = false
    @State private var selectedTemplate: DDMBlueprint?
    @State private var showingTemplateDetail = false
    @State private var showingCloneDialog = false
    @State private var cloneName = ""
    
    // MARK: - Computed Properties
    
    private var filteredTemplates: [DDMBlueprint] {
        var templates = service.templates
        
        // Filter by search text
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }
        
        // Filter by complexity
        if let complexity = selectedComplexity {
            templates = templates.filter { $0.metadata.complexity == complexity }
        }
        
        // Sort templates
        templates = sortTemplates(templates)
        
        return templates
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if filteredTemplates.isEmpty {
                    emptyStateView
                } else {
                    templatesGridView
                }
            }
            .navigationTitle("Template Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Filters") {
                        showingFilters.toggle()
                    }
                    
                    Button("Sort") {
                        // Show sort options
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search templates...")
            .sheet(isPresented: $showingFilters) {
                TemplateFiltersView(
                    selectedCategory: $selectedCategory,
                    selectedComplexity: $selectedComplexity,
                    sortBy: $sortBy,
                    sortOrder: $sortOrder
                )
            }
            .sheet(isPresented: $showingTemplateDetail) {
                if let template = selectedTemplate {
                    TemplateDetailView(template: template, service: service)
                }
            }
            .alert("Clone Template", isPresented: $showingCloneDialog) {
                TextField("New Blueprint Name", text: $cloneName)
                Button("Clone") {
                    cloneTemplate()
                }
                Button("Cancel", role: .cancel) {
                    cloneName = ""
                }
            } message: {
                Text("Enter a name for your new blueprint based on this template.")
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Template Library")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Browse and clone pre-built configuration templates")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(filteredTemplates.count) templates")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Ready to use")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Quick Stats
            HStack(spacing: 20) {
                ForEach(BlueprintCategory.allCases.prefix(4), id: \.self) { category in
                    let count = service.templates.filter { $0.category == category }.count
                    if count > 0 {
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text(category.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(.quaternary)
            .cornerRadius(8)
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Templates Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Try adjusting your search criteria or filters")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Clear Filters") {
                clearFilters()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Templates Grid View
    
    private var templatesGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(filteredTemplates) { template in
                    TemplateCardView(template: template) {
                        selectedTemplate = template
                        showingTemplateDetail = true
                    } onClone: {
                        selectedTemplate = template
                        cloneName = "\(template.name) Copy"
                        showingCloneDialog = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func sortTemplates(_ templates: [DDMBlueprint]) -> [DDMBlueprint] {
        let sorted: [DDMBlueprint]
        
        switch sortBy {
        case .name:
            sorted = templates.sorted { $0.name < $1.name }
        case .dateCreated:
            sorted = templates.sorted { $0.createdAt > $1.createdAt }
        case .dateUpdated:
            sorted = templates.sorted { $0.updatedAt > $1.updatedAt }
        case .rating:
            sorted = templates.sorted { $0.metadata.ratings.averageRating > $1.metadata.ratings.averageRating }
        case .popularity:
            sorted = templates.sorted { $0.metadata.usage.downloadCount > $1.metadata.usage.downloadCount }
        case .complexity:
            let complexityOrder: [BlueprintComplexity] = [.simple, .medium, .complex, .expert]
            sorted = templates.sorted { 
                complexityOrder.firstIndex(of: $0.metadata.complexity) ?? 0 < 
                complexityOrder.firstIndex(of: $1.metadata.complexity) ?? 0 
            }
        }
        
        return sortOrder == .ascending ? sorted : sorted.reversed()
    }
    
    private func clearFilters() {
        selectedCategory = nil
        selectedComplexity = nil
        searchText = ""
    }
    
    private func cloneTemplate() {
        guard let template = selectedTemplate else { return }
        
        Task {
            do {
                try await service.cloneTemplate(template, newName: cloneName)
                await MainActor.run {
                    cloneName = ""
                    selectedTemplate = nil
                }
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - Template Card View

struct TemplateCardView: View {
    let template: DDMBlueprint
    let onTap: () -> Void
    let onClone: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: template.category.icon)
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    if template.isPublic {
                        Image(systemName: "globe")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            // Category and Complexity
            HStack {
                Text(template.category.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.2))
                    .cornerRadius(4)
                
                Text(template.metadata.complexity.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                if template.metadata.ratings.totalRatings > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        
                        Text(String(format: "%.1f", template.metadata.ratings.averageRating))
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Tags
            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(template.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(.quaternary)
                                .cornerRadius(4)
                        }
                        
                        if template.tags.count > 3 {
                            Text("+\(template.tags.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // Metadata
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("By \(template.author)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("v\(template.version)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(template.metadata.estimatedDeploymentTime) min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if template.metadata.usage.downloadCount > 0 {
                        Text("\(template.metadata.usage.downloadCount) downloads")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Actions
            HStack(spacing: 8) {
                Button("View Details") {
                    onTap()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Clone") {
                    onClone()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Template Filters View

struct TemplateFiltersView: View {
    @Binding var selectedCategory: BlueprintCategory?
    @Binding var selectedComplexity: BlueprintComplexity?
    @Binding var sortBy: BlueprintSortOption
    @Binding var sortOrder: SortOrder
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag(nil as BlueprintCategory?)
                        ForEach(BlueprintCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category as BlueprintCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Complexity") {
                    Picker("Complexity", selection: $selectedComplexity) {
                        Text("All Complexities").tag(nil as BlueprintComplexity?)
                        ForEach(BlueprintComplexity.allCases, id: \.self) { complexity in
                            Text(complexity.rawValue).tag(complexity as BlueprintComplexity?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Sort By") {
                    Picker("Sort By", selection: $sortBy) {
                        ForEach(BlueprintSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Order", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Apply") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Template Detail View

struct TemplateDetailView: View {
    let template: DDMBlueprint
    let service: DDMBlueprintsService
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingCloneDialog = false
    @State private var cloneName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    templateHeaderView
                    
                    // Description
                    if !template.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(template.description)
                                .font(.body)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    }
                    
                    // Configuration Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Configuration Preview")
                            .font(.headline)
                        
                        ConfigurationPreviewView(configuration: template.configuration)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Template Information")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Version", value: template.version)
                            InfoRow(label: "Author", value: template.author)
                            InfoRow(label: "Category", value: template.category.rawValue)
                            InfoRow(label: "Complexity", value: template.metadata.complexity.rawValue)
                            InfoRow(label: "Deployment Time", value: "\(template.metadata.estimatedDeploymentTime) minutes")
                            
                            if template.metadata.ratings.totalRatings > 0 {
                                InfoRow(label: "Rating", value: "\(String(format: "%.1f", template.metadata.ratings.averageRating)) ⭐ (\(template.metadata.ratings.totalRatings) reviews)")
                            }
                            
                            if template.metadata.usage.downloadCount > 0 {
                                InfoRow(label: "Downloads", value: "\(template.metadata.usage.downloadCount)")
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Clone Template") {
                        cloneName = "\(template.name) Copy"
                        showingCloneDialog = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .alert("Clone Template", isPresented: $showingCloneDialog) {
            TextField("New Blueprint Name", text: $cloneName)
            Button("Clone") {
                cloneTemplate()
            }
            Button("Cancel", role: .cancel) {
                cloneName = ""
            }
        } message: {
            Text("Enter a name for your new blueprint based on this template.")
        }
    }
    
    private var templateHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Label(template.category.rawValue, systemImage: template.category.icon)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if template.isPublic {
                        Label("Public", systemImage: "globe")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    
                    Text("Template")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // Tags
            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(template.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.quaternary)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private func cloneTemplate() {
        Task {
            do {
                try await service.cloneTemplate(template, newName: cloneName)
                await MainActor.run {
                    cloneName = ""
                    dismiss()
                }
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - Configuration Preview View

struct ConfigurationPreviewView: View {
    let configuration: BlueprintConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Security Policies")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Passcode: \(configuration.securityPolicies.passcodePolicy.requirePasscode ? "Required" : "Not Required")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("FileVault: \(configuration.securityPolicies.encryptionSettings.requireFileVault ? "Enabled" : "Disabled")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Network")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("WiFi: \(configuration.networkConfigurations.wifiSettings.networks.count) networks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Proxy: \(configuration.networkConfigurations.proxySettings.enabled ? "Enabled" : "Disabled")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Applications")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Allowed: \(configuration.applicationSettings.allowedApplications.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Blocked: \(configuration.applicationSettings.blockedApplications.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Compliance")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    let totalRules = configuration.complianceRules.deviceCompliance.count +
                                   configuration.complianceRules.applicationCompliance.count +
                                   configuration.complianceRules.networkCompliance.count +
                                   configuration.complianceRules.securityCompliance.count
                    
                    Text("\(totalRules) rules configured")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TemplateLibraryView(service: DDMBlueprintsService())
}
