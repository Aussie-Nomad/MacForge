//
//  AddAIAccountView.swift
//  MacForge
//
//  Add AI provider account interface for MacForge settings.
//

import SwiftUI

struct AddAIAccountView: View {
    @ObservedObject var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var provider: AIProviderType = .openai
    @State private var displayName = ""
    @State private var apiKey = ""
    @State private var model = ""
    @State private var baseURL = ""
    @State private var isDefault = false
    @State private var isActive = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Add AI Tool Account")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            Form {
                Section("Account Information") {
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Provider", selection: $provider) {
                        ForEach(AIProviderType.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Configuration") {
                    if provider == .openai || provider == .anthropic {
                        SecureField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Model", text: $model)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Base URL (optional)", text: $baseURL)
                            .textFieldStyle(.roundedBorder)
                    } else if provider == .ollama {
                        TextField("Ollama URL", text: $baseURL)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Model", text: $model)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("No API key required for local Ollama")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        TextField("Endpoint URL", text: $baseURL)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Model (optional)", text: $model)
                            .textFieldStyle(.roundedBorder)
                        
                        SecureField("API Key (optional)", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                Section("Options") {
                    Toggle("Set as Default", isOn: $isDefault)
                    Toggle("Active", isOn: $isActive)
                }
            }
            
            // Action Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Add Account") {
                    addAccount()
                }
                .buttonStyle(.borderedProminent)
                .disabled(displayName.isEmpty || (provider != .ollama && apiKey.isEmpty))
            }
        }
        .padding()
        .frame(width: 500, height: 600)
        .background(LCARSTheme.background)
        .onAppear {
            setupDefaults()
        }
        .onChange(of: provider) { _, newProvider in
            updateDisplayName(for: newProvider)
        }
    }
    
    private func updateDisplayName(for provider: AIProviderType) {
        // Only update if the display name is still the default format
        if displayName.isEmpty || displayName.hasSuffix(" Account") {
            displayName = "\(provider.displayName) Account"
        }
    }
    
    private func setupDefaults() {
        if displayName.isEmpty {
            displayName = "\(provider.displayName) Account"
        }
        
        if model.isEmpty {
            switch provider {
            case .openai:
                model = "gpt-4o-mini"
            case .anthropic:
                model = "claude-3-5-sonnet-20240620"
            case .ollama:
                model = "codellama:7b-instruct"
            case .custom:
                model = ""
            }
        }
        
        if baseURL.isEmpty {
            switch provider {
            case .openai:
                baseURL = "https://api.openai.com/v1"
            case .anthropic:
                baseURL = "https://api.anthropic.com/v1"
            case .ollama:
                baseURL = "http://localhost:11434"
            case .custom:
                baseURL = ""
            }
        }
    }
    
    private func addAccount() {
        let account = AIAccount(
            provider: provider,
            displayName: displayName,
            apiKey: apiKey,
            model: model,
            baseURL: baseURL
        )
        
        var newAccount = account
        newAccount.isDefault = isDefault
        newAccount.isActive = isActive
        
        // If this is set as default, remove default from other accounts
        if isDefault {
            for index in userSettings.aiAccounts.indices {
                userSettings.aiAccounts[index].isDefault = false
            }
        }
        
        userSettings.addAIAccount(newAccount)
        dismiss()
    }
}

#Preview {
    AddAIAccountView(userSettings: UserSettings())
}
