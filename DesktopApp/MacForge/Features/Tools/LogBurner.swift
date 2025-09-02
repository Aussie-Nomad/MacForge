//
//  LogBurner.swift
//  MacForge
//
//  Log Analysis Tool - AI-powered log file analysis with drag & drop interface.
//  Provides smart summaries, error extraction, and security event detection.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Log Analysis Models
struct LogAnalysisResult: Identifiable {
    let id = UUID()
    let fileName: String
    let fileSize: Int64
    let analysisDate: Date
    let rawContent: String
    let summary: LogSummary
    let errors: [LogError]
    let warnings: [LogWarning]
    let securityEvents: [SecurityEvent]
    let timeline: [TimelineEvent]
    let statistics: LogStatistics
}

struct LogSummary {
    let totalLines: Int
    let errorCount: Int
    let warningCount: Int
    let criticalIssues: Int
    let timeRange: String
    let keyFindings: [String]
}

struct LogError: Identifiable {
    let id = UUID()
    let timestamp: String?
    let message: String
    let severity: ErrorSeverity
    let context: String?
    let lineNumber: Int?
}

struct LogWarning: Identifiable {
    let id = UUID()
    let timestamp: String?
    let message: String
    let context: String?
    let lineNumber: Int?
}

struct SecurityEvent: Identifiable {
    let id = UUID()
    let timestamp: String?
    let eventType: SecurityEventType
    let description: String
    let severity: SecuritySeverity
    let context: String?
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let event: String
    let type: EventType
}

struct LogStatistics {
    let totalLines: Int
    let errorRate: Double
    let warningRate: Double
    let averageLineLength: Int
    let timeSpan: TimeInterval
    let mostCommonErrors: [String: Int]
}

enum ErrorSeverity: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

enum SecurityEventType: String, CaseIterable {
    case authentication = "Authentication"
    case authorization = "Authorization"
    case fileAccess = "File Access"
    case networkActivity = "Network Activity"
    case systemChange = "System Change"
    case suspiciousActivity = "Suspicious Activity"
    
    var icon: String {
        switch self {
        case .authentication: return "person.badge.key"
        case .authorization: return "lock.shield"
        case .fileAccess: return "doc.text"
        case .networkActivity: return "network"
        case .systemChange: return "gear"
        case .suspiciousActivity: return "exclamationmark.triangle"
        }
    }
}

enum SecuritySeverity: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

enum EventType: String, CaseIterable {
    case error = "Error"
    case warning = "Warning"
    case info = "Info"
    case security = "Security"
    
    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        case .security: return .purple
        }
    }
}

// MARK: - Log Analysis Service
@MainActor
class LogAnalysisService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analysisResult: LogAnalysisResult?
    
    private let supportedFileTypes: [UTType] = [
        .plainText,
        .log,
        .data,
        .text
    ]
    
    func analyzeLogFile(at url: URL) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let fileData = try Data(contentsOf: url)
            let content = String(data: fileData, encoding: .utf8) ?? ""
            
            let result = await performLogAnalysis(
                fileName: url.lastPathComponent,
                fileSize: Int64(fileData.count),
                content: content
            )
            
            analysisResult = result
            
        } catch {
            errorMessage = "Failed to read log file: \(error.localizedDescription)"
        }
    }
    
    private func performLogAnalysis(fileName: String, fileSize: Int64, content: String) async -> LogAnalysisResult {
        let lines = content.components(separatedBy: .newlines)
        
        // Parse log content
        let errors = extractErrors(from: lines)
        let warnings = extractWarnings(from: lines)
        let securityEvents = extractSecurityEvents(from: lines)
        let timeline = extractTimeline(from: lines)
        let statistics = calculateStatistics(from: lines)
        
        // Generate summary
        let summary = LogSummary(
            totalLines: lines.count,
            errorCount: errors.count,
            warningCount: warnings.count,
            criticalIssues: errors.filter { $0.severity == .critical }.count,
            timeRange: extractTimeRange(from: lines),
            keyFindings: generateKeyFindings(errors: errors, warnings: warnings, securityEvents: securityEvents)
        )
        
        return LogAnalysisResult(
            fileName: fileName,
            fileSize: fileSize,
            analysisDate: Date(),
            rawContent: content,
            summary: summary,
            errors: errors,
            warnings: warnings,
            securityEvents: securityEvents,
            timeline: timeline,
            statistics: statistics
        )
    }
    
    private func extractErrors(from lines: [String]) -> [LogError] {
        var errors: [LogError] = []
        
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            
            // Common error patterns
            if lowercased.contains("error") || lowercased.contains("failed") || lowercased.contains("exception") {
                let severity = determineErrorSeverity(line)
                let timestamp = extractTimestamp(from: line)
                
                errors.append(LogError(
                    timestamp: timestamp,
                    message: line.trimmingCharacters(in: .whitespacesAndNewlines),
                    severity: severity,
                    context: extractContext(from: line),
                    lineNumber: index + 1
                ))
            }
        }
        
        return errors
    }
    
    private func extractWarnings(from lines: [String]) -> [LogWarning] {
        var warnings: [LogWarning] = []
        
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            
            if lowercased.contains("warning") || lowercased.contains("warn") {
                let timestamp = extractTimestamp(from: line)
                
                warnings.append(LogWarning(
                    timestamp: timestamp,
                    message: line.trimmingCharacters(in: .whitespacesAndNewlines),
                    context: extractContext(from: line),
                    lineNumber: index + 1
                ))
            }
        }
        
        return warnings
    }
    
    private func extractSecurityEvents(from lines: [String]) -> [SecurityEvent] {
        var events: [SecurityEvent] = []
        
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            
            // Security-related patterns
            if lowercased.contains("authentication") || lowercased.contains("authorization") ||
               lowercased.contains("login") || lowercased.contains("access denied") ||
               lowercased.contains("permission") || lowercased.contains("unauthorized") {
                
                let eventType = determineSecurityEventType(line)
                let severity = determineSecuritySeverity(line)
                let timestamp = extractTimestamp(from: line)
                
                events.append(SecurityEvent(
                    timestamp: timestamp,
                    eventType: eventType,
                    description: line.trimmingCharacters(in: .whitespacesAndNewlines),
                    severity: severity,
                    context: extractContext(from: line)
                ))
            }
        }
        
        return events
    }
    
    private func extractTimeline(from lines: [String]) -> [TimelineEvent] {
        var timeline: [TimelineEvent] = []
        
        for line in lines {
            if let timestamp = extractTimestamp(from: line) {
                let date = parseTimestamp(timestamp)
                let eventType = determineEventType(line)
                
                timeline.append(TimelineEvent(
                    timestamp: date,
                    event: line.trimmingCharacters(in: .whitespacesAndNewlines),
                    type: eventType
                ))
            }
        }
        
        return timeline.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func calculateStatistics(from lines: [String]) -> LogStatistics {
        let totalLines = lines.count
        let errorCount = lines.filter { $0.lowercased().contains("error") }.count
        let warningCount = lines.filter { $0.lowercased().contains("warning") }.count
        
        let errorRate = totalLines > 0 ? Double(errorCount) / Double(totalLines) * 100 : 0
        let warningRate = totalLines > 0 ? Double(warningCount) / Double(totalLines) * 100 : 0
        
        let averageLineLength = lines.isEmpty ? 0 : lines.map { $0.count }.reduce(0, +) / lines.count
        
        // Calculate time span
        let timestamps = lines.compactMap { extractTimestamp(from: $0) }
        let timeSpan = calculateTimeSpan(from: timestamps)
        
        // Most common errors
        let errorLines = lines.filter { $0.lowercased().contains("error") }
        let mostCommonErrors = Dictionary(grouping: errorLines, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .reduce(into: [String: Int]()) { result, pair in
                result[pair.key] = pair.value
            }
        
        return LogStatistics(
            totalLines: totalLines,
            errorRate: errorRate,
            warningRate: warningRate,
            averageLineLength: averageLineLength,
            timeSpan: timeSpan,
            mostCommonErrors: mostCommonErrors
        )
    }
    
    // MARK: - Helper Methods
    
    private func determineErrorSeverity(_ line: String) -> ErrorSeverity {
        let lowercased = line.lowercased()
        
        if lowercased.contains("critical") || lowercased.contains("fatal") {
            return .critical
        } else if lowercased.contains("severe") || lowercased.contains("major") {
            return .high
        } else if lowercased.contains("minor") || lowercased.contains("info") {
            return .low
        } else {
            return .medium
        }
    }
    
    private func determineSecurityEventType(_ line: String) -> SecurityEventType {
        let lowercased = line.lowercased()
        
        if lowercased.contains("authentication") || lowercased.contains("login") {
            return .authentication
        } else if lowercased.contains("authorization") || lowercased.contains("permission") {
            return .authorization
        } else if lowercased.contains("file") || lowercased.contains("directory") {
            return .fileAccess
        } else if lowercased.contains("network") || lowercased.contains("connection") {
            return .networkActivity
        } else if lowercased.contains("system") || lowercased.contains("config") {
            return .systemChange
        } else {
            return .suspiciousActivity
        }
    }
    
    private func determineSecuritySeverity(_ line: String) -> SecuritySeverity {
        let lowercased = line.lowercased()
        
        if lowercased.contains("critical") || lowercased.contains("fatal") {
            return .critical
        } else if lowercased.contains("high") || lowercased.contains("severe") {
            return .high
        } else if lowercased.contains("medium") || lowercased.contains("moderate") {
            return .medium
        } else {
            return .low
        }
    }
    
    private func determineEventType(_ line: String) -> EventType {
        let lowercased = line.lowercased()
        
        if lowercased.contains("error") {
            return .error
        } else if lowercased.contains("warning") {
            return .warning
        } else if lowercased.contains("security") || lowercased.contains("auth") {
            return .security
        } else {
            return .info
        }
    }
    
    private func extractTimestamp(from line: String) -> String? {
        // Common timestamp patterns
        let patterns = [
            "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}",  // 2024-01-01 12:00:00
            "\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2}",  // 01/01/2024 12:00:00
            "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}",  // 2024-01-01T12:00:00
            "\\[\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\]"  // [2024-01-01 12:00:00]
        ]
        
        for pattern in patterns {
            if let range = line.range(of: pattern, options: .regularExpression) {
                return String(line[range])
            }
        }
        
        return nil
    }
    
    private func extractContext(from line: String) -> String? {
        // Extract context around the main message
        let components = line.components(separatedBy: .whitespaces)
        if components.count > 10 {
            return components.suffix(5).joined(separator: " ")
        }
        return nil
    }
    
    private func extractTimeRange(from lines: [String]) -> String {
        let timestamps = lines.compactMap { extractTimestamp(from: $0) }
        if timestamps.count >= 2 {
            return "\(timestamps.first ?? "Unknown") to \(timestamps.last ?? "Unknown")"
        } else if let first = timestamps.first {
            return first
        } else {
            return "No timestamps found"
        }
    }
    
    private func generateKeyFindings(errors: [LogError], warnings: [LogWarning], securityEvents: [SecurityEvent]) -> [String] {
        var findings: [String] = []
        
        if errors.count > 0 {
            findings.append("Found \(errors.count) errors in the log")
        }
        
        if warnings.count > 0 {
            findings.append("Found \(warnings.count) warnings in the log")
        }
        
        if securityEvents.count > 0 {
            findings.append("Detected \(securityEvents.count) security-related events")
        }
        
        let criticalErrors = errors.filter { $0.severity == .critical }
        if criticalErrors.count > 0 {
            findings.append("⚠️ \(criticalErrors.count) critical errors require immediate attention")
        }
        
        return findings
    }
    
    private func parseTimestamp(_ timestamp: String) -> Date {
        let formatters = [
            "yyyy-MM-dd HH:mm:ss",
            "MM/dd/yyyy HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "[yyyy-MM-dd HH:mm:ss]"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: timestamp) {
                return date
            }
        }
        
        return Date()
    }
    
    private func calculateTimeSpan(from timestamps: [String]) -> TimeInterval {
        let dates = timestamps.compactMap { parseTimestamp($0) }
        if dates.count >= 2 {
            return dates.max()!.timeIntervalSince(dates.min()!)
        }
        return 0
    }
}

// MARK: - Log Burner View
struct LogBurnerView: View {
    @StateObject private var logAnalysisService = LogAnalysisService()
    @State private var isDragOver = false
    @State private var showingResults = false
    @State private var uploadedFileName: String? = nil
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "flame.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Log Burner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("AI-Powered Log Analysis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Drag & Drop Zone
            VStack(spacing: 16) {
                if logAnalysisService.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Analyzing log file...")
                            .font(.headline)
                        if let fileName = uploadedFileName {
                            Text("Processing: \(fileName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Text("This may take a moment for large files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                } else if let fileName = uploadedFileName, logAnalysisService.analysisResult != nil {
                    // File uploaded and analyzed successfully
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("File Analyzed Successfully!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        VStack(spacing: 4) {
                            Text("File: \(fileName)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let result = logAnalysisService.analysisResult {
                                Text("\(result.summary.totalLines) lines • \(result.summary.errorCount) errors • \(result.summary.warningCount) warnings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button("Analyze Another File") {
                            uploadedFileName = nil
                            logAnalysisService.analysisResult = nil
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            )
                    )
                } else {
                    // Initial state or file uploaded but not analyzed yet
                    VStack(spacing: 16) {
                        Image(systemName: uploadedFileName != nil ? "doc.text.fill" : "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(uploadedFileName != nil ? .blue : (isDragOver ? .blue : .gray))
                        
                        if let fileName = uploadedFileName {
                            Text("File Ready for Analysis")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            VStack(spacing: 4) {
                                Text("File: \(fileName)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Click 'Analyze' to process the log file")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Analyze File") {
                                // Trigger analysis
                                if let fileName = uploadedFileName {
                                    // For demo purposes, we'll simulate analysis
                                    Task {
                                        await logAnalysisService.analyzeLogFile(at: URL(fileURLWithPath: "/tmp/\(fileName)"))
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                        } else {
                            Text("Drag & Drop Log Files Here")
                                .font(.headline)
                                .foregroundColor(isDragOver ? .blue : .primary)
                            
                            Text("Supports: .log, .txt, system logs, and more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Browse Files") {
                                showingFilePicker = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(uploadedFileName != nil ? Color.blue.opacity(0.1) : (isDragOver ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(uploadedFileName != nil ? Color.blue : (isDragOver ? Color.blue : Color.gray.opacity(0.3)), style: StrokeStyle(lineWidth: 2, dash: uploadedFileName != nil ? [] : [5]))
                            )
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                        handleFileDrop(providers: providers)
                    }
                }
            }
            
            // Error Message
            if let errorMessage = logAnalysisService.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Analysis Results
            if let result = logAnalysisService.analysisResult {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Analysis Complete!")
                            .font(.headline)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    
                    Button("View Analysis Results") {
                        showingResults = true
                    }
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $showingResults) {
                        LogAnalysisResultsView(result: result)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Log Burner")
        .onChange(of: showingFilePicker) { _, showing in
            if showing {
                handleFilePicker()
                showingFilePicker = false
            }
        }
    }
    
    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    uploadedFileName = url.lastPathComponent
                    // Haptic feedback for successful file drop
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                }
                Task {
                    await logAnalysisService.analyzeLogFile(at: url)
                }
            }
        }
        
        return true
    }
    
    // MARK: - File Picker
    private func handleFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.log, .text, .plainText]
        panel.title = "Select Log File"
        panel.message = "Choose a log file to analyze (.log, .txt, or system logs)"
        
        if panel.runModal() == .OK, let url = panel.url {
            handleFileSelection(url: url)
        }
    }
    
    private func handleFileSelection(url: URL) {
        do {
            uploadedFileName = url.lastPathComponent
            
            Task {
                await logAnalysisService.analyzeLogFile(at: url)
            }
        } catch {
            logAnalysisService.errorMessage = "Failed to read file: \(error.localizedDescription)"
        }
    }
}

// MARK: - Log Analysis Results View
struct LogAnalysisResultsView: View {
    let result: LogAnalysisResult
    @Environment(\.dismiss) private var dismiss
    @State private var rawLogContent: String = ""
    @State private var highlightedLine: Int? = nil
    
    var body: some View {
        NavigationSplitView {
            // LEFT SIDEBAR - Raw Log Content
            VStack(alignment: .leading, spacing: 12) {
                // Sidebar header
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title3)
                        .foregroundColor(.blue)
                    Text("Raw Log Content")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // File info
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.fileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(ByteCountFormatter.string(fromByteCount: result.fileSize, countStyle: .file)) • \(result.summary.totalLines) lines")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                Divider()
                
                // Scrollable log content
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(rawLogContent.components(separatedBy: .newlines).enumerated()), id: \.offset) { index, line in
                            HStack(alignment: .top, spacing: 8) {
                                // Line number
                                Text("\(index + 1)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                                
                                // Line content with syntax highlighting
                                Text(line)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(getLineColor(for: line))
                                    .textSelection(.enabled)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(getLineBackgroundColor(for: line, isHighlighted: highlightedLine == index + 1))
                            )
                            .onTapGesture {
                                highlightedLine = highlightedLine == index + 1 ? nil : index + 1
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .frame(minWidth: 300, maxWidth: 400)
            .background(Color(.controlBackgroundColor))
            
        } detail: {
            // RIGHT MAIN AREA - Analysis Results
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // File info header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Analysis Results")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Text("Analyzed \(result.analysisDate, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("File Size:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(ByteCountFormatter.string(fromByteCount: result.fileSize, countStyle: .file))
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.controlBackgroundColor))
                    )
                    
                    // Summary Card
                    SummaryCard(summary: result.summary)
                    
                    // Statistics Card
                    StatisticsCard(statistics: result.statistics)
                    
                    // Errors Section
                    if !result.errors.isEmpty {
                        ErrorsSection(errors: result.errors, onErrorTap: { lineNumber in
                            highlightedLine = lineNumber
                        })
                    }
                    
                    // Warnings Section
                    if !result.warnings.isEmpty {
                        WarningsSection(warnings: result.warnings, onWarningTap: { lineNumber in
                            highlightedLine = lineNumber
                        })
                    }
                    
                    // Security Events Section
                    if !result.securityEvents.isEmpty {
                        SecurityEventsSection(events: result.securityEvents)
                    }
                    
                    // Timeline Section
                    if !result.timeline.isEmpty {
                        TimelineSection(timeline: result.timeline)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Log Analysis Results")
            .navigationSubtitle(result.fileName)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Export Report") {
                        // TODO: Implement export functionality
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .onAppear {
            loadRawLogContent()
        }
    }
    
    private func loadRawLogContent() {
        rawLogContent = result.rawContent
    }
    
    private func getLineColor(for line: String) -> Color {
        let lowercased = line.lowercased()
        
        if lowercased.contains("critical") || lowercased.contains("fatal") {
            return .red
        } else if lowercased.contains("error") || lowercased.contains("failed") {
            return .red
        } else if lowercased.contains("warning") || lowercased.contains("warn") {
            return .orange
        } else if lowercased.contains("security") || lowercased.contains("auth") {
            return .purple
        } else if lowercased.contains("info") {
            return .blue
        } else {
            return .primary
        }
    }
    
    private func getLineBackgroundColor(for line: String, isHighlighted: Bool = false) -> Color {
        if isHighlighted {
            return .blue.opacity(0.2)
        }
        
        let lowercased = line.lowercased()
        
        if lowercased.contains("critical") || lowercased.contains("fatal") {
            return .red.opacity(0.1)
        } else if lowercased.contains("error") || lowercased.contains("failed") {
            return .red.opacity(0.05)
        } else if lowercased.contains("warning") || lowercased.contains("warn") {
            return .orange.opacity(0.05)
        } else if lowercased.contains("security") || lowercased.contains("auth") {
            return .purple.opacity(0.05)
        } else {
            return .clear
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let summary: LogSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Analysis Summary")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Main statistics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticItem(
                    title: "Total Lines", 
                    value: "\(summary.totalLines)",
                    icon: "doc.text",
                    color: .blue
                )
                StatisticItem(
                    title: "Errors", 
                    value: "\(summary.errorCount)", 
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                StatisticItem(
                    title: "Warnings", 
                    value: "\(summary.warningCount)", 
                    icon: "exclamationmark.triangle",
                    color: .orange
                )
                StatisticItem(
                    title: "Critical", 
                    value: "\(summary.criticalIssues)", 
                    icon: "bolt.fill",
                    color: .purple
                )
            }
            
            // Time range
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Time Range:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(summary.timeRange)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top, 8)
            
            // Key findings with better styling
            if !summary.keyFindings.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Key Findings")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(summary.keyFindings, id: \.self) { finding in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                    .padding(.top, 2)
                                Text(finding)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Statistics Card
struct StatisticsCard: View {
    let statistics: LogStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Performance Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticItem(
                    title: "Error Rate", 
                    value: String(format: "%.1f%%", statistics.errorRate), 
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                StatisticItem(
                    title: "Warning Rate", 
                    value: String(format: "%.1f%%", statistics.warningRate), 
                    icon: "exclamationmark.triangle",
                    color: .orange
                )
                StatisticItem(
                    title: "Avg Line Length", 
                    value: "\(statistics.averageLineLength)",
                    icon: "text.alignleft",
                    color: .blue
                )
                StatisticItem(
                    title: "Time Span", 
                    value: formatTimeSpan(statistics.timeSpan),
                    icon: "clock",
                    color: .purple
                )
            }
            
            // Most common errors section
            if !statistics.mostCommonErrors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundColor(.orange)
                        Text("Most Common Errors")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(statistics.mostCommonErrors.prefix(3)), id: \.key) { error, count in
                            HStack {
                                Text("•")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text("(\(count))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func formatTimeSpan(_ timeSpan: TimeInterval) -> String {
        let hours = Int(timeSpan) / 3600
        let minutes = Int(timeSpan) % 3600 / 60
        let seconds = Int(timeSpan) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Errors Section
struct ErrorsSection: View {
    let errors: [LogError]
    let onErrorTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                Text("Errors (\(errors.count))")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(errors.prefix(10)) { error in
                    ErrorRow(error: error, onTap: {
                        if let lineNumber = error.lineNumber {
                            onErrorTap(lineNumber)
                        }
                    })
                }
                
                if errors.count > 10 {
                    HStack {
                        Spacer()
                        Text("... and \(errors.count - 10) more errors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Warnings Section
struct WarningsSection: View {
    let warnings: [LogWarning]
    let onWarningTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Warnings (\(warnings.count))")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(warnings.prefix(10)) { warning in
                    WarningRow(warning: warning, onTap: {
                        if let lineNumber = warning.lineNumber {
                            onWarningTap(lineNumber)
                        }
                    })
                }
                
                if warnings.count > 10 {
                    HStack {
                        Spacer()
                        Text("... and \(warnings.count - 10) more warnings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Security Events Section
struct SecurityEventsSection: View {
    let events: [SecurityEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("Security Events (\(events.count))")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(events.prefix(10)) { event in
                    SecurityEventRow(event: event)
                }
                
                if events.count > 10 {
                    HStack {
                        Spacer()
                        Text("... and \(events.count - 10) more security events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Timeline Section
struct TimelineSection: View {
    let timeline: [TimelineEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Event Timeline")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(timeline.prefix(20)) { event in
                    TimelineRow(event: event)
                }
                
                if timeline.count > 20 {
                    HStack {
                        Spacer()
                        Text("... and \(timeline.count - 20) more events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Row Components
struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String?
    let color: Color
    
    init(title: String, value: String, icon: String? = nil, color: Color = .primary) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ErrorRow: View {
    let error: LogError
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(error.severity.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(error.message)
                    .font(.caption)
                    .lineLimit(3)
                
                if let timestamp = error.timestamp {
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .onTapGesture {
            onTap()
        }
    }
}

struct WarningRow: View {
    let warning: LogWarning
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(warning.message)
                    .font(.caption)
                    .lineLimit(3)
                
                if let timestamp = warning.timestamp {
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .onTapGesture {
            onTap()
        }
    }
}

struct SecurityEventRow: View {
    let event: SecurityEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.eventType.icon)
                .foregroundColor(event.severity.color)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.description)
                    .font(.caption)
                    .lineLimit(3)
                
                HStack {
                    Text(event.eventType.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(event.severity.color.opacity(0.2))
                        .cornerRadius(4)
                    
                    if let timestamp = event.timestamp {
                        Text(timestamp)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TimelineRow: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(event.type.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.event)
                    .font(.caption)
                    .lineLimit(2)
                
                Text(event.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LogBurnerView()
}
