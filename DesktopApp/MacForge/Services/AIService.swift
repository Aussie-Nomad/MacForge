//
//  AIService.swift
//  MacForge
//
//  AI service for handling multiple providers (OpenAI, Anthropic, Ollama, Custom)
//  Provides unified interface for script generation and analysis.
//

import Foundation

// MARK: - AI Provider Type
enum AIProviderType: String, CaseIterable, Identifiable, Codable {
    case openai = "openai"
    case anthropic = "anthropic"
    case ollama = "ollama"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .ollama: return "Ollama"
        case .custom: return "Custom"
        }
    }
}

// MARK: - AI Service Protocol
protocol AIServiceProtocol {
    func generateScript(prompt: String, language: String, systemPrompt: String) async throws -> String
    func explainScript(script: String, systemPrompt: String) async throws -> String
    func hardenScript(script: String, systemPrompt: String) async throws -> String
}

// MARK: - AI Service Configuration
struct AIServiceConfig {
    let provider: AIProviderType
    let apiKey: String
    let model: String
    let baseURL: String
    
    var effectiveBaseURL: String {
        if baseURL.isEmpty {
            switch provider {
            case .openai:
                return "https://api.openai.com/v1"
            case .anthropic:
                return "https://api.anthropic.com/v1"
            case .ollama:
                return "http://localhost:11434"
            case .custom:
                return ""
            }
        }
        return baseURL
    }
    
    var effectiveModel: String {
        if model.isEmpty {
            switch provider {
            case .openai:
                return "gpt-4o-mini"
            case .anthropic:
                return "claude-3-5-sonnet-20240620"
            case .ollama:
                return "codellama:7b-instruct"
            case .custom:
                return ""
            }
        }
        return model
    }
}

// MARK: - AI Service Implementation
final class AIService: AIServiceProtocol {
    private let config: AIServiceConfig
    private let session: URLSession
    
    init(config: AIServiceConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }
    
    // MARK: - Public Methods
    
    func generateScript(prompt: String, language: String, systemPrompt: String) async throws -> String {
        let fullPrompt = "\(systemPrompt)\n\nGenerate a \(language) script for: \(prompt)"
        let result = try await makeRequest(prompt: fullPrompt)
        return cleanScriptOutput(result, language: language)
    }
    
    func explainScript(script: String, systemPrompt: String) async throws -> String {
        let fullPrompt = "\(systemPrompt)\n\nExplain this script:\n\n\(script)"
        return try await makeRequest(prompt: fullPrompt)
    }
    
    func hardenScript(script: String, systemPrompt: String) async throws -> String {
        let fullPrompt = "\(systemPrompt)\n\nHarden and improve this script:\n\n\(script)"
        let result = try await makeRequest(prompt: fullPrompt)
        return cleanScriptOutput(result, language: detectLanguage(from: script))
    }
    
    // MARK: - Private Methods
    
    private func makeRequest(prompt: String) async throws -> String {
        switch config.provider {
        case .openai:
            return try await makeOpenAIRequest(prompt: prompt)
        case .anthropic:
            return try await makeAnthropicRequest(prompt: prompt)
        case .ollama:
            return try await makeOllamaRequest(prompt: prompt)
        case .custom:
            return try await makeCustomRequest(prompt: prompt)
        }
    }
    
    // MARK: - Provider-Specific Implementations
    
    private func makeOpenAIRequest(prompt: String) async throws -> String {
        guard let url = URL(string: "\(config.effectiveBaseURL)/chat/completions") else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0
        
        let requestBody: [String: Any] = [
            "model": config.effectiveModel,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 4000,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return openAIResponse.choices.first?.message.content ?? ""
    }
    
    private func makeAnthropicRequest(prompt: String) async throws -> String {
        guard let url = URL(string: "\(config.effectiveBaseURL)/messages") else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("anthropic-2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.timeoutInterval = 60.0
        
        let requestBody: [String: Any] = [
            "model": config.effectiveModel,
            "max_tokens": 4000,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return anthropicResponse.content.first?.text ?? ""
    }
    
    private func makeOllamaRequest(prompt: String) async throws -> String {
        guard let url = URL(string: "\(config.effectiveBaseURL)/api/generate") else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120.0 // Ollama can be slower
        
        let requestBody: [String: Any] = [
            "model": config.effectiveModel,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": 0.7,
                "num_predict": 4000
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return ollamaResponse.response
    }
    
    private func makeCustomRequest(prompt: String) async throws -> String {
        guard let url = URL(string: config.effectiveBaseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0
        
        if !config.apiKey.isEmpty {
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Generic OpenAI-compatible format
        let requestBody: [String: Any] = [
            "model": config.effectiveModel,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 4000,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        // Try to parse as OpenAI-compatible response
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return openAIResponse.choices.first?.message.content ?? ""
    }
    
    // MARK: - Output Cleaning Methods
    
    private func cleanScriptOutput(_ output: String, language: String) -> String {
        var cleaned = output
        
        // Remove markdown code blocks
        cleaned = cleaned.replacingOccurrences(of: "```\(language)", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```bash", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```zsh", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```python", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```applescript", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        
        // Remove common AI response prefixes
        let prefixes = [
            "Here is a \(language) script:",
            "Here's a \(language) script:",
            "Here is the \(language) script:",
            "Here's the \(language) script:",
            "Here is a script:",
            "Here's a script:",
            "Here is the script:",
            "Here's the script:",
            "Here is the code:",
            "Here's the code:",
            "Here is the code for:",
            "Here's the code for:"
        ]
        
        for prefix in prefixes {
            if cleaned.lowercased().hasPrefix(prefix.lowercased()) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }
        
        // Remove trailing explanations
        let explanationMarkers = [
            "\n\nThis script",
            "\n\nTo use this script",
            "\n\nTo run this script",
            "\n\nThis code",
            "\n\nTo use this code",
            "\n\nTo run this code"
        ]
        
        for marker in explanationMarkers {
            if let range = cleaned.range(of: marker) {
                cleaned = String(cleaned[..<range.lowerBound])
                break
            }
        }
        
        // Ensure proper shebang if missing
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.hasPrefix("#!") {
            let shebang = getShebang(for: language)
            cleaned = "\(shebang)\n\(trimmed)"
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func detectLanguage(from script: String) -> String {
        if script.contains("#!/bin/bash") || script.contains("#!/usr/bin/env bash") {
            return "bash"
        } else if script.contains("#!/bin/zsh") || script.contains("#!/usr/bin/env zsh") {
            return "zsh"
        } else if script.contains("#!/usr/bin/env python") || script.contains("#!/usr/bin/python") {
            return "python"
        } else if script.contains("#!/usr/bin/osascript") {
            return "applescript"
        }
        return "bash" // default
    }
    
    private func getShebang(for language: String) -> String {
        switch language.lowercased() {
        case "bash":
            return "#!/bin/bash"
        case "zsh":
            return "#!/bin/zsh"
        case "python":
            return "#!/usr/bin/env python3"
        case "applescript":
            return "#!/usr/bin/osascript"
        default:
            return "#!/bin/bash"
        }
    }
}

// MARK: - Response Models

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
    
    struct OpenAIChoice: Codable {
        let message: OpenAIMessage
    }
    
    struct OpenAIMessage: Codable {
        let content: String
    }
}

struct AnthropicResponse: Codable {
    let content: [AnthropicContent]
    
    struct AnthropicContent: Codable {
        let text: String
    }
}

struct OllamaResponse: Codable {
    let response: String
}

// MARK: - AI Errors

enum AIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case missingAPIKey
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .missingAPIKey:
            return "API key is required for this provider"
        case .invalidConfiguration:
            return "Invalid AI service configuration"
        }
    }
}
