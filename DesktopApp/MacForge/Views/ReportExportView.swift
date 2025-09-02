//
//  ReportExportView.swift
//  MacForge
//
//  Report export interface for analysis results.
//  Provides multiple export formats with professional styling.
//

import SwiftUI

struct ReportExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ReportFormat = .pdf
    @State private var isGenerating = false
    @State private var generatedURL: URL?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingSuccess = false
    
    let logAnalysisResult: LogAnalysisResult?
    let packageAnalysisResult: PackageAnalysis?
    
    init(logAnalysisResult: LogAnalysisResult) {
        self.logAnalysisResult = logAnalysisResult
        self.packageAnalysisResult = nil
    }
    
    init(packageAnalysisResult: PackageAnalysis) {
        self.logAnalysisResult = nil
        self.packageAnalysisResult = packageAnalysisResult
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Export Report")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Generate a professional report of your analysis results")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Report Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Report Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let logResult = logAnalysisResult {
                            ReportInfoRow(label: "File Name", value: logResult.fileName)
                            ReportInfoRow(label: "File Size", value: formatFileSize(logResult.fileSize))
                            ReportInfoRow(label: "Analysis Date", value: formatDate(logResult.analysisDate))
                            ReportInfoRow(label: "Total Lines", value: "\(logResult.summary.totalLines)")
                            ReportInfoRow(label: "Errors Found", value: "\(logResult.summary.errorCount)")
                            ReportInfoRow(label: "Warnings Found", value: "\(logResult.summary.warningCount)")
                        } else if let packageResult = packageAnalysisResult {
                            ReportInfoRow(label: "File Name", value: packageResult.fileName)
                            ReportInfoRow(label: "File Size", value: formatFileSize(packageResult.fileSize))
                            ReportInfoRow(label: "Package Type", value: packageResult.packageType.rawValue)
                            ReportInfoRow(label: "Analysis Date", value: formatDate(packageResult.analysisDate))
                            ReportInfoRow(label: "Bundle ID", value: packageResult.metadata.bundleIdentifier ?? "N/A")
                            ReportInfoRow(label: "Version", value: packageResult.metadata.version ?? "N/A")
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.controlBackgroundColor))
                    )
                }
                
                // Format Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Format")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        ForEach(ReportFormat.allCases, id: \.self) { format in
                            FormatRow(
                                format: format,
                                isSelected: selectedFormat == format,
                                onSelect: { selectedFormat = format }
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.controlBackgroundColor))
                    )
                }
                
                // Format Descriptions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Format Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FormatDescription(format: selectedFormat)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.controlBackgroundColor))
                    )
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: generateReport) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "doc.badge.plus")
                            }
                            Text(isGenerating ? "Generating..." : "Generate Report")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating)
                }
            }
            .padding()
            .navigationTitle("Export Report")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Export Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .alert("Report Generated", isPresented: $showingSuccess) {
            Button("OK") { }
            Button("Open Report") {
                if let url = generatedURL {
                    NSWorkspace.shared.open(url)
                }
            }
        } message: {
            Text("Your report has been generated successfully.")
        }
    }
    
    private func generateReport() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let url: URL
                
                if let logResult = logAnalysisResult {
                    url = try await ReportGenerationService.shared.generateLogAnalysisReport(logResult, format: selectedFormat)
                } else if let packageResult = packageAnalysisResult {
                    url = try await ReportGenerationService.shared.generatePackageAnalysisReport(packageResult, format: selectedFormat)
                } else {
                    throw ReportGenerationError.noDataAvailable
                }
                
                await MainActor.run {
                    self.generatedURL = url
                    self.isGenerating = false
                    self.showingSuccess = true
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isGenerating = false
                    self.showingError = true
                }
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct ReportInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct FormatRow: View {
    let format: ReportFormat
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: formatIcon)
                    .foregroundColor(formatColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formatDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private var formatIcon: String {
        switch format {
        case .pdf: return "doc.richtext.fill"
        case .html: return "globe"
        case .json: return "curlybraces"
        }
    }
    
    private var formatColor: Color {
        switch format {
        case .pdf: return .red
        case .html: return .blue
        case .json: return .green
        }
    }
    
    private var formatDescription: String {
        switch format {
        case .pdf: return "Professional PDF document"
        case .html: return "Web-viewable HTML report"
        case .json: return "Machine-readable JSON data"
        }
    }
}

struct FormatDescription: View {
    let format: ReportFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch format {
            case .pdf:
                VStack(alignment: .leading, spacing: 4) {
                    Text("PDF Report")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("• Professional document format")
                    Text("• Print-ready layout")
                    Text("• Includes charts and visualizations")
                    Text("• Best for sharing and archiving")
                }
                
            case .html:
                VStack(alignment: .leading, spacing: 4) {
                    Text("HTML Report")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("• Viewable in any web browser")
                    Text("• Interactive elements")
                    Text("• Responsive design")
                    Text("• Easy to share via email or web")
                }
                
            case .json:
                VStack(alignment: .leading, spacing: 4) {
                    Text("JSON Report")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("• Machine-readable format")
                    Text("• Complete raw data")
                    Text("• API integration ready")
                    Text("• Best for further processing")
                }
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

// MARK: - Report Generation Error

enum ReportGenerationError: LocalizedError {
    case noDataAvailable
    case generationFailed(String)
    case fileSaveFailed
    
    var errorDescription: String? {
        switch self {
        case .noDataAvailable:
            return "No analysis data available for report generation"
        case .generationFailed(let message):
            return "Report generation failed: \(message)"
        case .fileSaveFailed:
            return "Failed to save report file"
        }
    }
}

#Preview {
    // Create a sample log analysis result for preview
    let sampleResult = LogAnalysisResult(
        fileName: "sample.log",
        fileSize: 1024 * 1024,
        analysisDate: Date(),
        rawContent: "Sample log content",
        summary: LogSummary(
            totalLines: 1000,
            errorCount: 5,
            warningCount: 10,
            criticalIssues: 2,
            timeRange: "2024-01-01 to 2024-01-02",
            keyFindings: ["High error rate detected", "Memory leaks identified"]
        ),
        errors: [],
        warnings: [],
        securityEvents: [],
        timeline: [],
        statistics: LogStatistics(
            totalLines: 1000,
            errorRate: 0.5,
            warningRate: 0.1,
            averageLineLength: 50,
            timeSpan: 86400,
            mostCommonErrors: ["Error 1": 3, "Error 2": 2],
            timeRange: "24 hours",
            peakActivityHour: "14:00",
            uniqueErrorCount: 3
        )
    )
    
    ReportExportView(logAnalysisResult: sampleResult)
}
