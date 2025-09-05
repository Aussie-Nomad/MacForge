//
//  ValidationService.swift
//  MacForge
//
//  Comprehensive input validation and sanitization service.
//  Prevents injection attacks and ensures data integrity.
//

import Foundation

// MARK: - Validation Service
final class ValidationService {
    static let shared = ValidationService()
    
    private init() {}
    
    // MARK: - URL Validation
    
    /// Validate and sanitize server URL
    func validateServerURL(_ urlString: String) throws -> URL {
        // Remove whitespace
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for empty string
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyURL
        }
        
        // Check length
        guard trimmed.count <= 2048 else {
            throw ValidationError.urlTooLong
        }
        
        // Add https:// if no scheme provided
        let normalizedURL: String
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            normalizedURL = trimmed
        } else {
            normalizedURL = "https://\(trimmed)"
        }
        
        // Validate URL format
        guard let url = URL(string: normalizedURL) else {
            throw ValidationError.invalidURLFormat
        }
        
        // Validate scheme
        guard url.scheme == "https" else {
            throw ValidationError.insecureScheme
        }
        
        // Validate host
        guard let host = url.host, !host.isEmpty else {
            throw ValidationError.invalidHost
        }
        
        // Check for suspicious patterns
        if host.contains("..") || host.contains("//") {
            throw ValidationError.suspiciousURL
        }
        
        return url
    }
    
    // MARK: - Credential Validation
    
    /// Validate client ID
    func validateClientID(_ clientID: String) throws -> String {
        let trimmed = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyClientID
        }
        
        guard trimmed.count >= 8 && trimmed.count <= 128 else {
            throw ValidationError.invalidClientIDLength
        }
        
        // Check for valid characters (alphanumeric, hyphens, underscores)
        let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard trimmed.rangeOfCharacter(from: validCharacterSet.inverted) == nil else {
            throw ValidationError.invalidClientIDCharacters
        }
        
        return trimmed
    }
    
    /// Validate client secret
    func validateClientSecret(_ clientSecret: String) throws -> String {
        let trimmed = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyClientSecret
        }
        
        guard trimmed.count >= 16 && trimmed.count <= 256 else {
            throw ValidationError.invalidClientSecretLength
        }
        
        // Check for valid characters (alphanumeric, special chars)
        let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?"))
        guard trimmed.rangeOfCharacter(from: validCharacterSet.inverted) == nil else {
            throw ValidationError.invalidClientSecretCharacters
        }
        
        return trimmed
    }
    
    /// Validate username
    func validateUsername(_ username: String) throws -> String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyUsername
        }
        
        guard trimmed.count >= 3 && trimmed.count <= 64 else {
            throw ValidationError.invalidUsernameLength
        }
        
        // Check for valid characters (alphanumeric, dots, hyphens, underscores, @ for email addresses)
        let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_@"))
        guard trimmed.rangeOfCharacter(from: validCharacterSet.inverted) == nil else {
            throw ValidationError.invalidUsernameCharacters
        }
        
        return trimmed
    }
    
    /// Validate password
    func validatePassword(_ password: String) throws -> String {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyPassword
        }
        
        guard trimmed.count >= 8 && trimmed.count <= 128 else {
            throw ValidationError.invalidPasswordLength
        }
        
        // Check for at least one uppercase, lowercase, and number
        let hasUppercase = trimmed.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = trimmed.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumber = trimmed.rangeOfCharacter(from: .decimalDigits) != nil
        
        guard hasUppercase && hasLowercase && hasNumber else {
            throw ValidationError.weakPassword
        }
        
        return trimmed
    }
    
    // MARK: - Profile Validation
    
    /// Validate profile name
    func validateProfileName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyProfileName
        }
        
        guard trimmed.count <= 100 else {
            throw ValidationError.profileNameTooLong
        }
        
        // Check for dangerous characters
        let dangerousChars = CharacterSet(charactersIn: "<>:\"/\\|?*")
        guard trimmed.rangeOfCharacter(from: dangerousChars) == nil else {
            throw ValidationError.dangerousCharactersInProfileName
        }
        
        return trimmed
    }
    
    /// Validate bundle identifier
    func validateBundleIdentifier(_ bundleID: String) throws -> String {
        let trimmed = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyBundleID
        }
        
        guard trimmed.count <= 255 else {
            throw ValidationError.bundleIDTooLong
        }
        
        // Check format: com.company.app
        let components = trimmed.components(separatedBy: ".")
        guard components.count >= 2 else {
            throw ValidationError.invalidBundleIDFormat
        }
        
        // Validate each component
        for component in components {
            guard !component.isEmpty else {
                throw ValidationError.emptyBundleIDComponent
            }
            
            // Check for valid characters (alphanumeric, hyphens)
            let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
            guard component.rangeOfCharacter(from: validCharacterSet.inverted) == nil else {
                throw ValidationError.invalidBundleIDCharacters
            }
            
            // Must start with letter
            guard component.first?.isLetter == true else {
                throw ValidationError.bundleIDComponentMustStartWithLetter
            }
        }
        
        return trimmed
    }
    
    // MARK: - File Validation
    
    /// Validate file path
    func validateFilePath(_ path: String) throws -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyFilePath
        }
        
        guard trimmed.count <= 1024 else {
            throw ValidationError.filePathTooLong
        }
        
        // Check for path traversal attempts
        if trimmed.contains("..") || trimmed.contains("~") {
            throw ValidationError.pathTraversalAttempt
        }
        
        return trimmed
    }
    
    /// Validate file extension
    func validateFileExtension(_ extension: String) throws -> String {
        let trimmed = `extension`.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyFileExtension
        }
        
        guard trimmed.count <= 10 else {
            throw ValidationError.fileExtensionTooLong
        }
        
        // Check for valid characters (alphanumeric)
        let validCharacterSet = CharacterSet.alphanumerics
        guard trimmed.rangeOfCharacter(from: validCharacterSet.inverted) == nil else {
            throw ValidationError.invalidFileExtensionCharacters
        }
        
        return trimmed
    }
    
    // MARK: - Rate Limiting
    
    private var requestCounts: [String: (count: Int, lastReset: Date)] = [:]
    private let rateLimitWindow: TimeInterval = 300 // 5 minutes
    private let maxRequestsPerWindow = 10
    
    /// Check if request is within rate limits
    func checkRateLimit(for identifier: String) throws {
        let now = Date()
        let key = "rate_limit_\(identifier)"
        
        if let existing = requestCounts[key] {
            // Reset if window has passed
            if now.timeIntervalSince(existing.lastReset) > rateLimitWindow {
                requestCounts[key] = (count: 1, lastReset: now)
            } else {
                // Check if limit exceeded
                if existing.count >= maxRequestsPerWindow {
                    throw ValidationError.rateLimitExceeded
                }
                requestCounts[key] = (count: existing.count + 1, lastReset: existing.lastReset)
            }
        } else {
            requestCounts[key] = (count: 1, lastReset: now)
        }
    }
    
    // MARK: - Sanitization
    
    /// Sanitize string for display
    func sanitizeForDisplay(_ string: String) -> String {
        return string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
    }
    
    /// Sanitize string for logging
    func sanitizeForLogging(_ string: String) -> String {
        // Remove sensitive patterns
        var sanitized = string
        
        // Remove potential tokens (long alphanumeric strings)
        let tokenPattern = "[A-Za-z0-9]{32,}"
        sanitized = sanitized.replacingOccurrences(of: tokenPattern, with: "[REDACTED]", options: .regularExpression)
        
        // Remove potential passwords (strings with special chars)
        let passwordPattern = "[^\\s]{8,}"
        sanitized = sanitized.replacingOccurrences(of: passwordPattern, with: "[REDACTED]", options: .regularExpression)
        
        return sanitized
    }
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    // URL Validation
    case emptyURL
    case urlTooLong
    case invalidURLFormat
    case insecureScheme
    case invalidHost
    case suspiciousURL
    
    // Credential Validation
    case emptyClientID
    case invalidClientIDLength
    case invalidClientIDCharacters
    case emptyClientSecret
    case invalidClientSecretLength
    case invalidClientSecretCharacters
    case emptyUsername
    case invalidUsernameLength
    case invalidUsernameCharacters
    case emptyPassword
    case invalidPasswordLength
    case weakPassword
    
    // Profile Validation
    case emptyProfileName
    case profileNameTooLong
    case dangerousCharactersInProfileName
    case emptyBundleID
    case bundleIDTooLong
    case invalidBundleIDFormat
    case emptyBundleIDComponent
    case invalidBundleIDCharacters
    case bundleIDComponentMustStartWithLetter
    
    // File Validation
    case emptyFilePath
    case filePathTooLong
    case pathTraversalAttempt
    case emptyFileExtension
    case fileExtensionTooLong
    case invalidFileExtensionCharacters
    
    // Rate Limiting
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .emptyURL:
            return "Server URL cannot be empty"
        case .urlTooLong:
            return "Server URL is too long (maximum 2048 characters)"
        case .invalidURLFormat:
            return "Invalid URL format"
        case .insecureScheme:
            return "Only HTTPS URLs are allowed for security"
        case .invalidHost:
            return "Invalid host in URL"
        case .suspiciousURL:
            return "URL contains suspicious patterns"
        case .emptyClientID:
            return "Client ID cannot be empty"
        case .invalidClientIDLength:
            return "Client ID must be between 8 and 128 characters"
        case .invalidClientIDCharacters:
            return "Client ID can only contain letters, numbers, hyphens, and underscores"
        case .emptyClientSecret:
            return "Client Secret cannot be empty"
        case .invalidClientSecretLength:
            return "Client Secret must be between 16 and 256 characters"
        case .invalidClientSecretCharacters:
            return "Client Secret contains invalid characters"
        case .emptyUsername:
            return "Username cannot be empty"
        case .invalidUsernameLength:
            return "Username must be between 3 and 64 characters"
        case .invalidUsernameCharacters:
            return "Username can only contain letters, numbers, dots, hyphens, underscores, and @ symbols"
        case .emptyPassword:
            return "Password cannot be empty"
        case .invalidPasswordLength:
            return "Password must be between 8 and 128 characters"
        case .weakPassword:
            return "Password must contain at least one uppercase letter, one lowercase letter, and one number"
        case .emptyProfileName:
            return "Profile name cannot be empty"
        case .profileNameTooLong:
            return "Profile name is too long (maximum 100 characters)"
        case .dangerousCharactersInProfileName:
            return "Profile name contains dangerous characters"
        case .emptyBundleID:
            return "Bundle ID cannot be empty"
        case .bundleIDTooLong:
            return "Bundle ID is too long (maximum 255 characters)"
        case .invalidBundleIDFormat:
            return "Bundle ID must be in format 'com.company.app'"
        case .emptyBundleIDComponent:
            return "Bundle ID components cannot be empty"
        case .invalidBundleIDCharacters:
            return "Bundle ID can only contain letters, numbers, and hyphens"
        case .bundleIDComponentMustStartWithLetter:
            return "Bundle ID components must start with a letter"
        case .emptyFilePath:
            return "File path cannot be empty"
        case .filePathTooLong:
            return "File path is too long (maximum 1024 characters)"
        case .pathTraversalAttempt:
            return "File path contains path traversal attempts"
        case .emptyFileExtension:
            return "File extension cannot be empty"
        case .fileExtensionTooLong:
            return "File extension is too long (maximum 10 characters)"
        case .invalidFileExtensionCharacters:
            return "File extension can only contain letters and numbers"
        case .rateLimitExceeded:
            return "Too many requests. Please wait before trying again."
        }
    }
}
