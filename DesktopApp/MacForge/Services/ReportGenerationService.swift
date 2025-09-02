//
//  ReportGenerationService.swift
//  MacForge
//
//  Comprehensive report generation service for analysis results.
//  Supports PDF, HTML, and JSON export formats with professional styling.
//

import Foundation
import PDFKit
import WebKit

// MARK: - Report Generation Service
final class ReportGenerationService {
    static let shared = ReportGenerationService()
    
    private init() {}
    
    // MARK: - Report Generation
    
    /// Generate a comprehensive report for log analysis results
    func generateLogAnalysisReport(_ result: LogAnalysisResult, format: ReportFormat) async throws -> URL {
        switch format {
        case .pdf:
            return try await generatePDFReport(for: result)
        case .html:
            return try await generateHTMLReport(for: result)
        case .json:
            return try await generateJSONReport(for: result)
        }
    }
    
    /// Generate a comprehensive report for package analysis results
    func generatePackageAnalysisReport(_ result: PackageAnalysis, format: ReportFormat) async throws -> URL {
        switch format {
        case .pdf:
            return try await generatePDFReport(for: result)
        case .html:
            return try await generateHTMLReport(for: result)
        case .json:
            return try await generateJSONReport(for: result)
        }
    }
    
    // MARK: - PDF Report Generation
    
    private func generatePDFReport(for result: LogAnalysisResult) async throws -> URL {
        let htmlContent = try await generateHTMLContent(for: result)
        return try await convertHTMLToPDF(htmlContent, fileName: "log_analysis_report_\(Date().timeIntervalSince1970).pdf")
    }
    
    private func generatePDFReport(for result: PackageAnalysis) async throws -> URL {
        let htmlContent = try await generateHTMLContent(for: result)
        return try await convertHTMLToPDF(htmlContent, fileName: "package_analysis_report_\(Date().timeIntervalSince1970).pdf")
    }
    
    // MARK: - HTML Report Generation
    
    private func generateHTMLReport(for result: LogAnalysisResult) async throws -> URL {
        let htmlContent = try await generateHTMLContent(for: result)
        return try await saveHTMLContent(htmlContent, fileName: "log_analysis_report_\(Date().timeIntervalSince1970).html")
    }
    
    private func generateHTMLReport(for result: PackageAnalysis) async throws -> URL {
        let htmlContent = try await generateHTMLContent(for: result)
        return try await saveHTMLContent(htmlContent, fileName: "package_analysis_report_\(Date().timeIntervalSince1970).html")
    }
    
    // MARK: - JSON Report Generation
    
    private func generateJSONReport(for result: LogAnalysisResult) async throws -> URL {
        let jsonData = try JSONEncoder().encode(result)
        return try await saveJSONData(jsonData, fileName: "log_analysis_report_\(Date().timeIntervalSince1970).json")
    }
    
    private func generateJSONReport(for result: PackageAnalysis) async throws -> URL {
        let jsonData = try JSONEncoder().encode(result)
        return try await saveJSONData(jsonData, fileName: "package_analysis_report_\(Date().timeIntervalSince1970).json")
    }
    
    // MARK: - HTML Content Generation
    
    private func generateHTMLContent(for result: LogAnalysisResult) async throws -> String {
        let template = LogAnalysisHTMLTemplate()
        return template.generateHTML(for: result)
    }
    
    private func generateHTMLContent(for result: PackageAnalysis) async throws -> String {
        let template = PackageAnalysisHTMLTemplate()
        return template.generateHTML(for: result)
    }
    
    // MARK: - File Operations
    
    private func convertHTMLToPDF(_ htmlContent: String, fileName: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let webView = WKWebView()
                webView.loadHTMLString(htmlContent, baseURL: nil)
                
                webView.evaluateJavaScript("document.readyState") { _, _ in
                    let config = WKPDFConfiguration()
                    config.rect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
                    
                    webView.createPDF(configuration: config) { result in
                        switch result {
                        case .success(let data):
                            do {
                                let url = try self.savePDFData(data, fileName: fileName)
                                continuation.resume(returning: url)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
    
    private func saveHTMLContent(_ content: String, fileName: String) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func saveJSONData(_ data: Data, fileName: String) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    private func savePDFData(_ data: Data, fileName: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Report Format

enum ReportFormat: String, CaseIterable {
    case pdf = "PDF"
    case html = "HTML"
    case json = "JSON"
    
    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .html: return "html"
        case .json: return "json"
        }
    }
    
    var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .html: return "text/html"
        case .json: return "application/json"
        }
    }
}

// MARK: - HTML Templates

struct LogAnalysisHTMLTemplate {
    func generateHTML(for result: LogAnalysisResult) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Log Analysis Report - \(result.fileName)</title>
            <style>
                \(getCSS())
            </style>
        </head>
        <body>
            <div class="container">
                <header class="report-header">
                    <h1>Log Analysis Report</h1>
                    <div class="report-meta">
                        <p><strong>File:</strong> \(result.fileName)</p>
                        <p><strong>Size:</strong> \(formatFileSize(result.fileSize))</p>
                        <p><strong>Analysis Date:</strong> \(formatDate(result.analysisDate))</p>
                    </div>
                </header>
                
                <section class="summary-section">
                    <h2>Executive Summary</h2>
                    <div class="summary-grid">
                        <div class="summary-card">
                            <h3>Total Lines</h3>
                            <span class="metric">\(result.summary.totalLines)</span>
                        </div>
                        <div class="summary-card error">
                            <h3>Errors</h3>
                            <span class="metric">\(result.summary.errorCount)</span>
                        </div>
                        <div class="summary-card warning">
                            <h3>Warnings</h3>
                            <span class="metric">\(result.summary.warningCount)</span>
                        </div>
                        <div class="summary-card critical">
                            <h3>Critical Issues</h3>
                            <span class="metric">\(result.summary.criticalIssues)</span>
                        </div>
                    </div>
                </section>
                
                <section class="findings-section">
                    <h2>Key Findings</h2>
                    <ul class="findings-list">
                        \(result.summary.keyFindings.map { "<li>\($0)</li>" }.joined())
                    </ul>
                </section>
                
                <section class="errors-section">
                    <h2>Errors (\(result.errors.count))</h2>
                    \(generateErrorsHTML(result.errors))
                </section>
                
                <section class="warnings-section">
                    <h2>Warnings (\(result.warnings.count))</h2>
                    \(generateWarningsHTML(result.warnings))
                </section>
                
                <section class="security-section">
                    <h2>Security Events (\(result.securityEvents.count))</h2>
                    \(generateSecurityEventsHTML(result.securityEvents))
                </section>
                
                <section class="statistics-section">
                    <h2>Statistics</h2>
                    \(generateStatisticsHTML(result.statistics))
                </section>
                
                <footer class="report-footer">
                    <p>Generated by MacForge on \(formatDate(Date()))</p>
                </footer>
            </div>
        </body>
        </html>
        """
    }
    
    private func generateErrorsHTML(_ errors: [LogError]) -> String {
        if errors.isEmpty {
            return "<p class='no-items'>No errors found.</p>"
        }
        
        return """
        <div class="items-list">
            \(errors.map { error in
                """
                <div class="item-card error">
                    <div class="item-header">
                        <span class="severity \(error.severity.rawValue.lowercased())">\(error.severity.rawValue)</span>
                        \(error.timestamp != nil ? "<span class='timestamp'>\(error.timestamp!)</span>" : "")
                    </div>
                    <div class="item-content">
                        <p>\(error.message)</p>
                        \(error.context != nil ? "<p class='context'>\(error.context!)</p>" : "")
                        \(error.lineNumber != nil ? "<p class='line-number'>Line \(error.lineNumber!)</p>" : "")
                    </div>
                </div>
                """
            }.joined())
        </div>
        """
    }
    
    private func generateWarningsHTML(_ warnings: [LogWarning]) -> String {
        if warnings.isEmpty {
            return "<p class='no-items'>No warnings found.</p>"
        }
        
        return """
        <div class="items-list">
            \(warnings.map { warning in
                """
                <div class="item-card warning">
                    <div class="item-header">
                        <span class="severity warning">WARNING</span>
                        \(warning.timestamp != nil ? "<span class='timestamp'>\(warning.timestamp!)</span>" : "")
                    </div>
                    <div class="item-content">
                        <p>\(warning.message)</p>
                        \(warning.context != nil ? "<p class='context'>\(warning.context!)</p>" : "")
                    </div>
                </div>
                """
            }.joined())
        </div>
        """
    }
    
    private func generateSecurityEventsHTML(_ events: [SecurityEvent]) -> String {
        if events.isEmpty {
            return "<p class='no-items'>No security events found.</p>"
        }
        
        return """
        <div class="items-list">
            \(events.map { event in
                """
                <div class="item-card security">
                    <div class="item-header">
                        <span class="severity \(event.severity.rawValue.lowercased())">\(event.severity.rawValue)</span>
                        <span class="event-type">\(event.eventType.rawValue)</span>
                    </div>
                    <div class="item-content">
                        <p>\(event.description)</p>
                        \(event.context != nil ? "<p class='source'>Context: \(event.context!)</p>" : "")
                    </div>
                </div>
                """
            }.joined())
        </div>
        """
    }
    
    private func generateStatisticsHTML(_ stats: LogStatistics) -> String {
        return """
        <div class="stats-grid">
            <div class="stat-item">
                <h4>Time Range</h4>
                <p>\(formatTimeSpan(stats.timeSpan))</p>
            </div>
            <div class="stat-item">
                <h4>Peak Activity</h4>
                <p>\(stats.peakActivityHour)</p>
            </div>
            <div class="stat-item">
                <h4>Error Rate</h4>
                <p>\(String(format: "%.2f%%", stats.errorRate))</p>
            </div>
            <div class="stat-item">
                <h4>Unique Errors</h4>
                <p>\(stats.uniqueErrorCount)</p>
            </div>
        </div>
        """
    }
    
    func getCSS() -> String {
        return """
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f8f9fa;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: white;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        
        .report-header {
            text-align: center;
            margin-bottom: 40px;
            padding-bottom: 20px;
            border-bottom: 2px solid #e9ecef;
        }
        
        .report-header h1 {
            color: #2c3e50;
            margin-bottom: 20px;
            font-size: 2.5em;
        }
        
        .report-meta {
            display: flex;
            justify-content: center;
            gap: 30px;
            flex-wrap: wrap;
        }
        
        .report-meta p {
            margin: 5px 0;
            color: #6c757d;
        }
        
        section {
            margin-bottom: 40px;
        }
        
        h2 {
            color: #2c3e50;
            margin-bottom: 20px;
            font-size: 1.8em;
            border-bottom: 1px solid #dee2e6;
            padding-bottom: 10px;
        }
        
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .summary-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        
        .summary-card.error {
            background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
        }
        
        .summary-card.warning {
            background: linear-gradient(135deg, #feca57 0%, #ff9ff3 100%);
        }
        
        .summary-card.critical {
            background: linear-gradient(135deg, #ff3838 0%, #c44569 100%);
        }
        
        .summary-card h3 {
            margin-bottom: 10px;
            font-size: 1.1em;
        }
        
        .metric {
            font-size: 2em;
            font-weight: bold;
        }
        
        .findings-list {
            list-style: none;
            padding-left: 0;
        }
        
        .findings-list li {
            background-color: #f8f9fa;
            margin-bottom: 10px;
            padding: 15px;
            border-left: 4px solid #007bff;
            border-radius: 0 5px 5px 0;
        }
        
        .items-list {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }
        
        .item-card {
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 15px;
            background-color: white;
        }
        
        .item-card.error {
            border-left: 4px solid #dc3545;
        }
        
        .item-card.warning {
            border-left: 4px solid #ffc107;
        }
        
        .item-card.security {
            border-left: 4px solid #6f42c1;
        }
        
        .item-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .severity {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8em;
            font-weight: bold;
            text-transform: uppercase;
        }
        
        .severity.critical {
            background-color: #dc3545;
            color: white;
        }
        
        .severity.high {
            background-color: #fd7e14;
            color: white;
        }
        
        .severity.medium {
            background-color: #ffc107;
            color: black;
        }
        
        .severity.low {
            background-color: #28a745;
            color: white;
        }
        
        .severity.warning {
            background-color: #ffc107;
            color: black;
        }
        
        .timestamp {
            color: #6c757d;
            font-size: 0.9em;
        }
        
        .context {
            color: #6c757d;
            font-style: italic;
            margin-top: 5px;
        }
        
        .line-number {
            color: #007bff;
            font-weight: bold;
            margin-top: 5px;
        }
        
        .no-items {
            text-align: center;
            color: #6c757d;
            font-style: italic;
            padding: 20px;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }
        
        .stat-item {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        
        .stat-item h4 {
            color: #495057;
            margin-bottom: 10px;
        }
        
        .report-footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #dee2e6;
            color: #6c757d;
        }
        
        @media print {
            body {
                background-color: white;
            }
            
            .container {
                box-shadow: none;
                max-width: none;
            }
        }
        """
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
    
    private func formatTimeSpan(_ timeSpan: TimeInterval) -> String {
        let hours = Int(timeSpan) / 3600
        let minutes = Int(timeSpan.truncatingRemainder(dividingBy: 3600)) / 60
        return "\(hours)h \(minutes)m"
    }
    
}

struct PackageAnalysisHTMLTemplate {
    func generateHTML(for result: PackageAnalysis) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Package Analysis Report - \(result.fileName)</title>
            <style>
                \(getCSS())
            </style>
        </head>
        <body>
            <div class="container">
                <header class="report-header">
                    <h1>Package Analysis Report</h1>
                    <div class="report-meta">
                        <p><strong>File:</strong> \(result.fileName)</p>
                        <p><strong>Size:</strong> \(formatFileSize(result.fileSize))</p>
                        <p><strong>Type:</strong> \(result.packageType.rawValue)</p>
                        <p><strong>Analysis Date:</strong> \(formatDate(result.analysisDate))</p>
                    </div>
                </header>
                
                <section class="metadata-section">
                    <h2>Package Metadata</h2>
                    <div class="metadata-grid">
                        <div class="metadata-item">
                            <strong>Bundle ID:</strong> \(result.metadata.bundleIdentifier ?? "N/A")
                        </div>
                        <div class="metadata-item">
                            <strong>Version:</strong> \(result.metadata.version ?? "N/A")
                        </div>
                        <div class="metadata-item">
                            <strong>Display Name:</strong> \(result.metadata.displayName ?? "N/A")
                        </div>
                        <div class="metadata-item">
                            <strong>Author:</strong> \(result.metadata.author ?? "N/A")
                        </div>
                        <div class="metadata-item">
                            <strong>Install Location:</strong> \(result.metadata.installLocation ?? "N/A")
                        </div>
                        <div class="metadata-item">
                            <strong>Minimum OS:</strong> \(result.metadata.minimumOSVersion ?? "N/A")
                        </div>
                    </div>
                </section>
                
                <section class="contents-section">
                    <h2>Package Contents</h2>
                    <div class="contents-summary">
                        <p><strong>Total Files:</strong> \(result.contents.totalFiles)</p>
                        <p><strong>Total Size:</strong> \(formatFileSize(result.contents.totalSize))</p>
                        <p><strong>Install Size:</strong> \(formatFileSize(result.contents.installSize))</p>
                    </div>
                </section>
                
                <section class="security-section">
                    <h2>Security Analysis</h2>
                    \(generateSecurityHTML(result.securityInfo))
                </section>
                
                <section class="recommendations-section">
                    <h2>Recommendations</h2>
                    \(generateRecommendationsHTML(result.recommendations))
                </section>
                
                <footer class="report-footer">
                    <p>Generated by MacForge on \(formatDate(Date()))</p>
                </footer>
            </div>
        </body>
        </html>
        """
    }
    
    private func generateSecurityHTML(_ security: SecurityInfo) -> String {
        if security.securityIssues.isEmpty {
            return "<p class='no-items'>No security issues found.</p>"
        }
        
        return """
        <div class="items-list">
            \(security.securityIssues.map { issue in
                """
                <div class="item-card security">
                    <div class="item-header">
                        <span class="severity \(issue.severity.rawValue.lowercased())">\(issue.severity.rawValue)</span>
                        <span class="issue-type">Security Issue</span>
                    </div>
                    <div class="item-content">
                        <p>\(issue.description)</p>
                        <p class='recommendation'>Recommendation: \(issue.recommendation)</p>
                    </div>
                </div>
                """
            }.joined())
        </div>
        """
    }
    
    private func generateRecommendationsHTML(_ recommendations: [PackageRecommendation]) -> String {
        if recommendations.isEmpty {
            return "<p class='no-items'>No recommendations available.</p>"
        }
        
        return """
        <div class="items-list">
            \(recommendations.map { rec in
                """
                <div class="item-card recommendation">
                    <div class="item-header">
                        <span class="priority \(rec.priority.rawValue.lowercased())">\(rec.priority.rawValue)</span>
                    </div>
                    <div class="item-content">
                        <p>\(rec.description)</p>
                        <p class='action'>Action: \(rec.action)</p>
                    </div>
                </div>
                """
            }.joined())
        </div>
        """
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
    
    func getCSS() -> String {
        return LogAnalysisHTMLTemplate().getCSS()
    }
}
