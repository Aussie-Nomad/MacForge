//
//  BlacksmithTool.swift
//  MacForge
//
//  The Blacksmith - Conversational AI assistant for MDM setup and management
//  "Speak to the smithy" - Your Yorkshireman guide to device management
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Chat Message Models
struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let messageType: MessageType
    
    enum MessageType: String, Codable {
        case text, system, error, success, warning, packageCreation
    }
}

// MARK: - Package Creation Workflow Models
struct PackageCreationWorkflow: Codable {
    var uploadedFile: URL?
    var packageAnalysis: PackageAnalysis?
    var scriptContent: String = ""
    var scriptTiming: ScriptTiming = .afterInstall
    var requiredPermissions: [PPPCRequirement] = []
    var isComplete: Bool = false
    var outputPath: URL?
    
    enum ScriptTiming: String, Codable, CaseIterable {
        case beforeInstall = "Before Install"
        case afterInstall = "After Install"
        case beforeUninstall = "Before Uninstall"
        case afterUninstall = "After Uninstall"
    }
}

// MARK: - Package Analysis Model (using existing from PackageCasting)
// Note: PackageAnalysis and SecurityInfo are defined in PackageCasting.swift

struct PPPCRequirement: Identifiable, Codable {
    let id = UUID()
    var permissionType: String
    var isRequired: Bool = true
    var description: String
    
    static let commonPermissions = [
        PPPCRequirement(permissionType: "Full Disk Access", description: "Access to all files and folders"),
        PPPCRequirement(permissionType: "Notifications", description: "Send notifications to users"),
        PPPCRequirement(permissionType: "Camera", description: "Access to camera hardware"),
        PPPCRequirement(permissionType: "Microphone", description: "Access to microphone hardware"),
        PPPCRequirement(permissionType: "Screen Recording", description: "Record screen content"),
        PPPCRequirement(permissionType: "Accessibility", description: "Control other applications"),
        PPPCRequirement(permissionType: "Files and Folders", description: "Access to specific folders")
    ]
}

// MARK: - MDM Setup Context
struct MDMSetupContext: Codable {
    var selectedMDM: String = ""
    var deviceType: String = ""
    var organizationName: String = ""
    var deploymentType: String = ""
    var currentStep: Int = 0
    var completedSteps: [String] = []
    var configuration: [String: String] = [:]
}

// MARK: - The Blacksmith View
struct BlacksmithView: View {
    @StateObject private var chatModel = BlacksmithChatModel()
    @State private var showingMDMWizard = false
    @State private var showingPackageWizard = false
    @State private var currentContext = MDMSetupContext()
    @State private var packageWorkflow = PackageCreationWorkflow()
    @EnvironmentObject var userSettings: UserSettings
    @State private var showingAddAccount = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            blacksmithHeader
            
            // Main Content
            HStack(spacing: 0) {
                // Chat Interface
                chatInterface
                    .frame(maxWidth: .infinity)
                
                // Divider
                Divider()
                    .frame(width: 1)
                
                // MDM Setup Panel
                mdmSetupPanel
                    .frame(width: 300)
            }
        }
        .background(LCARSTheme.background)
        .sheet(isPresented: $showingMDMWizard) {
            MDMSetupWizardView(context: $currentContext, chatModel: chatModel)
        }
        .sheet(isPresented: $showingPackageWizard) {
            BlacksmithPackageWizardView(workflow: $packageWorkflow, chatModel: chatModel, userSettings: userSettings)
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAIAccountView(userSettings: userSettings)
        }
        .onAppear {
            // Set default account if none selected
            if chatModel.selectedAccountId == nil {
                chatModel.selectedAccountId = userSettings.aiAccounts.first { $0.isDefault && $0.isActive }?.id
            }
        }
    }
    
    // MARK: - Header
    private var blacksmithHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "hammer.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("The Blacksmith")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Speak to the smithy - Your MDM setup guide")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Package Wizard") {
                        showingPackageWizard = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("MDM Wizard") {
                        showingMDMWizard = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // AI Account Selection
            HStack {
                Text("AI Assistant:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Select AI Account", selection: $chatModel.selectedAccountId) {
                    Text("Select an AI account...")
                        .tag(nil as UUID?)
                    
                    ForEach(userSettings.aiAccounts.filter { $0.isActive }) { account in
                        Text(account.displayName)
                            .tag(account.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200, alignment: .leading)
                
                Button("Add Account") {
                    showingAddAccount = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding()
        .background(LCARSTheme.panel)
    }
    
    // MARK: - Chat Interface
    private var chatInterface: some View {
        VStack(spacing: 0) {
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatModel.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatModel.messages.count) { _, _ in
                    if let lastMessage = chatModel.messages.last {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Area
            chatInputArea
        }
    }
    
    // MARK: - Chat Input Area
    private var chatInputArea: some View {
        HStack(spacing: 12) {
            TextField("Ask the smithy about MDM setup...", text: $chatModel.currentMessage)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
            }
            .buttonStyle(.borderedProminent)
            .disabled(chatModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
    
    // MARK: - MDM Setup Panel
    private var mdmSetupPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MDM Setup Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !currentContext.selectedMDM.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected MDM: \(currentContext.selectedMDM)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Device Type: \(currentContext.deviceType)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Deployment: \(currentContext.deploymentType)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Actions")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(spacing: 8) {
                    QuickActionButton(
                        title: "Start MDM Setup",
                        icon: "gear.circle.fill",
                        color: .blue
                    ) {
                        chatModel.sendSystemMessage("Right then, let's get you sorted with MDM setup. What MDM system are you working with?")
                    }
                    
                    QuickActionButton(
                        title: "Create Package",
                        icon: "shippingbox.fill",
                        color: .green
                    ) {
                        chatModel.sendSystemMessage("Ah, you want to forge a new package! Let me help you create one with scripts and permissions. What kind of package are you looking to build?")
                    }
                    
                    QuickActionButton(
                        title: "Troubleshoot Issues",
                        icon: "wrench.and.screwdriver.fill",
                        color: .orange
                    ) {
                        chatModel.sendSystemMessage("Having a bit of bother, are we? Tell me what's going wrong and I'll see what I can do.")
                    }
                    
                    QuickActionButton(
                        title: "Best Practices",
                        icon: "lightbulb.fill",
                        color: .green
                    ) {
                        chatModel.sendSystemMessage("Ah, you want to do things proper like. Let me share some wisdom from the forge.")
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(LCARSTheme.panel)
    }
    
    // MARK: - Actions
    private func sendMessage() {
        let message = chatModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, chatModel.selectedAccountId != nil else { return }
        
        chatModel.sendUserMessage(message)
        chatModel.currentMessage = ""
        
        // Process the message and generate response
        Task {
            await chatModel.processMessage(message, context: currentContext, userSettings: userSettings, packageWorkflow: $packageWorkflow, showingPackageWizard: $showingPackageWizard)
        }
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                userBubble
            } else {
                systemBubble
                Spacer()
            }
        }
    }
    
    private var userBubble: some View {
        Text(message.content)
            .padding(12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(16)
            .frame(maxWidth: 300, alignment: .trailing)
    }
    
    private var systemBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "hammer.circle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("The Smithy")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text(message.content)
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    .frame(maxWidth: 300, alignment: .leading)
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Blacksmith Chat Model
class BlacksmithChatModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentMessage: String = ""
    @Published var isProcessing: Bool = false
    @Published var selectedAccountId: UUID? = nil
    
    init() {
        // Welcome message from the smithy
        sendSystemMessage("Right then, welcome to the forge! I'm the Blacksmith, and I'm here to help you sort out your MDM setup. What can I do for you today?")
    }
    
    func sendUserMessage(_ content: String) {
        let message = ChatMessage(
            content: content,
            isUser: true,
            timestamp: Date(),
            messageType: .text
        )
        messages.append(message)
    }
    
    func sendSystemMessage(_ content: String) {
        let message = ChatMessage(
            content: content,
            isUser: false,
            timestamp: Date(),
            messageType: .text
        )
        messages.append(message)
    }
    
    func processMessage(_ userMessage: String, context: MDMSetupContext, userSettings: UserSettings, packageWorkflow: Binding<PackageCreationWorkflow>, showingPackageWizard: Binding<Bool>) async {
        await MainActor.run {
            isProcessing = true
        }
        
        // Check if this is a package creation request
        if userMessage.lowercased().contains("package") || userMessage.lowercased().contains("create") || userMessage.lowercased().contains("build") {
            await MainActor.run {
                showingPackageWizard.wrappedValue = true
                sendSystemMessage("Right then, let's forge you a proper package! I'll open the Package Creation Wizard for you.")
                isProcessing = false
            }
            return
        }
        
        // Get AI response with Yorkshire personality
        let response = await generateYorkshireResponse(userMessage, context: context, userSettings: userSettings)
        
        await MainActor.run {
            sendSystemMessage(response)
            isProcessing = false
        }
    }
    
    private func generateYorkshireResponse(_ message: String, context: MDMSetupContext, userSettings: UserSettings) async -> String {
        // Check if we have a selected AI account
        guard let accountId = selectedAccountId,
              let account = userSettings.aiAccounts.first(where: { $0.id == accountId }) else {
            return "Right then, you'll need to select an AI account first before I can help you properly. Click that 'Add Account' button up there and get yourself sorted."
        }
        
        // Create AI service configuration
        let config = AIServiceConfig(
            provider: account.provider,
            apiKey: account.apiKey,
            model: account.effectiveModel,
            baseURL: account.effectiveBaseURL
        )
        
        let aiService = AIService(config: config)
        
        // Create the Yorkshire MDM specialist system prompt
        let systemPrompt = """
        You are The Blacksmith, a seasoned MDM specialist and scripting guru from Yorkshire, England. You've been working with device management systems for over 20 years and have seen it all - from the early days of JAMF to the modern cloud-based solutions.

        Your personality and expertise:
        - You speak with a warm Yorkshire accent and use local expressions like "right then", "that's a different kettle of fish", "having a bit of bother", etc.
        - You're incredibly knowledgeable about MDM systems (JAMF, Intune, Kandji, Mosyle, etc.), macOS management, scripting (bash, zsh, Python, Swift), and enterprise deployment
        - You're patient, thorough, and always want to do things "proper like"
        - You believe in starting simple and building up complexity gradually
        - You always emphasize testing before production deployment
        - You're direct but friendly, and you'll tell someone if they're doing something daft

        Your role is to help users with:
        - MDM setup and configuration guidance
        - Troubleshooting device management issues
        - Scripting and automation advice
        - Best practices for enterprise deployment
        - Policy configuration and security recommendations

        Always respond in character as The Blacksmith, with your Yorkshire personality and deep technical expertise. Be helpful, practical, and encouraging while maintaining your distinctive voice.
        """
        
        do {
            let response = try await aiService.generateScript(
                prompt: message,
                language: "conversation",
                systemPrompt: systemPrompt
            )
            return response
        } catch {
            return "Blimey, seems like there's a bit of trouble with the AI service. Error: \(error.localizedDescription). You might want to check your account settings or try again in a moment."
        }
    }
}

// MARK: - MDM Setup Wizard View
struct MDMSetupWizardView: View {
    @Binding var context: MDMSetupContext
    @ObservedObject var chatModel: BlacksmithChatModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showingCompletion = false
    
    private let wizardSteps = [
        "Welcome",
        "MDM Selection", 
        "Device Type",
        "Organization",
        "Deployment Type",
        "Configuration",
        "Review & Complete"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MDM Setup Wizard")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(LCARSTheme.panel)
            
            // Progress Header
            wizardProgressHeader
            
            // Main Content
            Group {
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    mdmSelectionStep
                case 2:
                    deviceTypeStep
                case 3:
                    organizationStep
                case 4:
                    deploymentTypeStep
                case 5:
                    configurationStep
                case 6:
                    reviewStep
                default:
                    welcomeStep
                }
            }
            
            // Navigation Buttons
            wizardNavigation
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(LCARSTheme.background)
        .sheet(isPresented: $showingCompletion) {
            wizardCompletionView
        }
    }
    
    // MARK: - Progress Header
    private var wizardProgressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(0..<wizardSteps.count, id: \.self) { index in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .opacity(index <= currentStep ? 1 : 0)
                            )
                        
                        if index < wizardSteps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: 40)
                        }
                    }
                }
            }
            
            Text("Step \(currentStep + 1) of \(wizardSteps.count): \(wizardSteps[currentStep])")
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(LCARSTheme.panel)
    }
    
    // MARK: - Navigation
    private var wizardNavigation: some View {
        HStack {
            Button("Previous") {
                if currentStep > 0 {
                    withAnimation {
                        currentStep -= 1
                    }
                }
            }
            .disabled(currentStep == 0)
            
            Spacer()
            
            if currentStep < wizardSteps.count - 1 {
                Button("Next") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Complete Setup") {
                    completeWizard()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(LCARSTheme.panel)
    }
    
    // MARK: - Welcome Step
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "hammer.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Welcome to the MDM Setup Wizard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Right then, let's get you sorted with your MDM setup. I'll guide you through each step to make sure everything's done proper like.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("What we'll cover:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    wizardStepItem(icon: "network.badge.shield.half.filled", text: "Choose your MDM platform")
                    wizardStepItem(icon: "laptopcomputer", text: "Select device types to manage")
                    wizardStepItem(icon: "building.2", text: "Configure organization settings")
                    wizardStepItem(icon: "arrow.down.circle", text: "Set up deployment method")
                    wizardStepItem(icon: "gearshape.2", text: "Configure policies and settings")
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - MDM Selection Step
    private var mdmSelectionStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Choose Your MDM Platform")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("What MDM system are you planning to use? Each has its own strengths and quirks.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                mdmOptionCard(
                    title: "JAMF Pro",
                    description: "Enterprise-grade Mac management",
                    icon: "applelogo",
                    color: .blue,
                    isSelected: context.selectedMDM == "JAMF Pro"
                ) {
                    context.selectedMDM = "JAMF Pro"
                }
                
                mdmOptionCard(
                    title: "JAMF School",
                    description: "Education-focused device management",
                    icon: "graduationcap.fill",
                    color: .green,
                    isSelected: context.selectedMDM == "JAMF School"
                ) {
                    context.selectedMDM = "JAMF School"
                }
                
                mdmOptionCard(
                    title: "Microsoft Intune",
                    description: "Cross-platform enterprise management",
                    icon: "microsoft.logo",
                    color: .blue,
                    isSelected: context.selectedMDM == "Microsoft Intune"
                ) {
                    context.selectedMDM = "Microsoft Intune"
                }
                
                mdmOptionCard(
                    title: "Kandji",
                    description: "Modern Mac-first MDM",
                    icon: "shield.fill",
                    color: .purple,
                    isSelected: context.selectedMDM == "Kandji"
                ) {
                    context.selectedMDM = "Kandji"
                }
                
                mdmOptionCard(
                    title: "Mosyle",
                    description: "Apple-focused education platform",
                    icon: "book.fill",
                    color: .orange,
                    isSelected: context.selectedMDM == "Mosyle"
                ) {
                    context.selectedMDM = "Mosyle"
                }
                
                mdmOptionCard(
                    title: "Other",
                    description: "Custom or other MDM solution",
                    icon: "gearshape.2.fill",
                    color: .gray,
                    isSelected: context.selectedMDM == "Other"
                ) {
                    context.selectedMDM = "Other"
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Device Type Step
    private var deviceTypeStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Device Types")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("What types of devices will you be managing? You can select multiple options.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                deviceTypeOption(
                    title: "Mac Computers",
                    description: "iMac, MacBook, Mac Mini, Mac Studio",
                    icon: "laptopcomputer",
                    isSelected: context.deviceType.contains("Mac")
                ) {
                    if context.deviceType.contains("Mac") {
                        context.deviceType = context.deviceType.replacingOccurrences(of: "Mac, ", with: "")
                        context.deviceType = context.deviceType.replacingOccurrences(of: ", Mac", with: "")
                        context.deviceType = context.deviceType.replacingOccurrences(of: "Mac", with: "")
                    } else {
                        context.deviceType += context.deviceType.isEmpty ? "Mac" : ", Mac"
                    }
                }
                
                deviceTypeOption(
                    title: "iPad",
                    description: "iPad, iPad Air, iPad Pro, iPad Mini",
                    icon: "ipad",
                    isSelected: context.deviceType.contains("iPad")
                ) {
                    if context.deviceType.contains("iPad") {
                        context.deviceType = context.deviceType.replacingOccurrences(of: "iPad, ", with: "")
                        context.deviceType = context.deviceType.replacingOccurrences(of: ", iPad", with: "")
                        context.deviceType = context.deviceType.replacingOccurrences(of: "iPad", with: "")
                    } else {
                        context.deviceType += context.deviceType.isEmpty ? "iPad" : ", iPad"
                    }
                }
                
                deviceTypeOption(
                    title: "iPhone",
                    description: "iPhone models for business use",
                    icon: "iphone",
                    isSelected: context.deviceType.contains("iPhone")
                ) {
                    if context.deviceType.contains("iPhone") {
                        context.deviceType = context.deviceType.replacingOccurrences(of: "iPhone, ", with: "")
                        context.deviceType = context.deviceType.replacingOccurrences(of: ", iPhone", with: "")
                        context.deviceType = context.deviceType.replacingOccurrences(of: "iPhone", with: "")
                    } else {
                        context.deviceType += context.deviceType.isEmpty ? "iPhone" : ", iPhone"
                    }
                }
                
                deviceTypeOption(
                    title: "Apple TV",
                    description: "Apple TV for digital signage or kiosks",
                    icon: "tv",
                    isSelected: context.deviceType.contains("Apple TV")
                ) {
                    if context.deviceType.contains("Apple TV") {
                        context.deviceType = context.deviceType.replacingOccurrences(of: "Apple TV, ", with: "")
                        context.deviceType = context.deviceType.replacingOccurrences(of: ", Apple TV", with: "")
                        context.deviceType = context.deviceType.replacingOccurrences(of: "Apple TV", with: "")
                    } else {
                        context.deviceType += context.deviceType.isEmpty ? "Apple TV" : ", Apple TV"
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Organization Step
    private var organizationStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Organization Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Tell me about your organization so I can give you the right advice.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Organization Name")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Enter your organization name", text: $context.organizationName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Organization Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Picker("Organization Type", selection: $context.configuration["orgType"]) {
                        Text("Select type...").tag(nil as String?)
                        Text("Enterprise").tag("Enterprise" as String?)
                        Text("Education").tag("Education" as String?)
                        Text("Small Business").tag("Small Business" as String?)
                        Text("Non-Profit").tag("Non-Profit" as String?)
                        Text("Government").tag("Government" as String?)
                        Text("Healthcare").tag("Healthcare" as String?)
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Count")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Picker("Device Count", selection: $context.configuration["deviceCount"]) {
                        Text("Select range...").tag(nil as String?)
                        Text("1-10 devices").tag("1-10" as String?)
                        Text("11-50 devices").tag("11-50" as String?)
                        Text("51-200 devices").tag("51-200" as String?)
                        Text("201-1000 devices").tag("201-1000" as String?)
                        Text("1000+ devices").tag("1000+" as String?)
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Deployment Type Step
    private var deploymentTypeStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Deployment Method")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("How do you want to deploy devices? This affects your setup strategy.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                deploymentOption(
                    title: "Zero-Touch Deployment",
                    description: "Devices are pre-configured and ready to use out of the box",
                    icon: "shippingbox.fill",
                    color: .green,
                    isSelected: context.deploymentType == "Zero-Touch"
                ) {
                    context.deploymentType = "Zero-Touch"
                }
                
                deploymentOption(
                    title: "Single-Touch Deployment",
                    description: "Minimal user interaction required during setup",
                    icon: "hand.tap.fill",
                    color: .blue,
                    isSelected: context.deploymentType == "Single-Touch"
                ) {
                    context.deploymentType = "Single-Touch"
                }
                
                deploymentOption(
                    title: "Manual Deployment",
                    description: "Users set up devices themselves with guidance",
                    icon: "person.fill",
                    color: .orange,
                    isSelected: context.deploymentType == "Manual"
                ) {
                    context.deploymentType = "Manual"
                }
                
                deploymentOption(
                    title: "Hybrid Approach",
                    description: "Mix of deployment methods based on device type",
                    icon: "gearshape.2.fill",
                    color: .purple,
                    isSelected: context.deploymentType == "Hybrid"
                ) {
                    context.deploymentType = "Hybrid"
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Configuration Step
    private var configurationStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Configuration Preferences")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Let me know your preferences for security and management policies.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                configurationSection(
                    title: "Security Level",
                    options: [
                        ("Basic", "Standard security policies"),
                        ("Enhanced", "Stricter security with additional controls"),
                        ("Maximum", "Enterprise-grade security policies")
                    ],
                    selectedKey: "securityLevel"
                )
                
                configurationSection(
                    title: "App Management",
                    options: [
                        ("Restrictive", "Only approved apps allowed"),
                        ("Moderate", "Some restrictions with user choice"),
                        ("Open", "Users can install most apps")
                    ],
                    selectedKey: "appManagement"
                )
                
                configurationSection(
                    title: "Network Access",
                    options: [
                        ("Corporate Only", "Restrict to corporate networks"),
                        ("VPN Required", "Require VPN for external access"),
                        ("Open", "Allow access from any network")
                    ],
                    selectedKey: "networkAccess"
                )
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Review Step
    private var reviewStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Review Your Configuration")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Let's make sure everything looks right before we finish up.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    reviewItem(title: "MDM Platform", value: context.selectedMDM)
                    reviewItem(title: "Device Types", value: context.deviceType.isEmpty ? "Not selected" : context.deviceType)
                    reviewItem(title: "Organization", value: context.organizationName.isEmpty ? "Not specified" : context.organizationName)
                    reviewItem(title: "Deployment Type", value: context.deploymentType.isEmpty ? "Not selected" : context.deploymentType)
                    
                    if let orgType = context.configuration["orgType"] {
                        reviewItem(title: "Organization Type", value: orgType)
                    }
                    
                    if let deviceCount = context.configuration["deviceCount"] {
                        reviewItem(title: "Device Count", value: deviceCount)
                    }
                    
                    if let securityLevel = context.configuration["securityLevel"] {
                        reviewItem(title: "Security Level", value: securityLevel)
                    }
                    
                    if let appManagement = context.configuration["appManagement"] {
                        reviewItem(title: "App Management", value: appManagement)
                    }
                    
                    if let networkAccess = context.configuration["networkAccess"] {
                        reviewItem(title: "Network Access", value: networkAccess)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Completion View
    private var wizardCompletionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Setup Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Right then, you're all sorted! I've got your configuration saved and ready to go.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Text("Next Steps:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Set up your MDM server with the selected platform")
                    Text("• Configure your Apple Business Manager account")
                    Text("• Create your first device enrollment profile")
                    Text("• Test with a pilot group of devices")
                    Text("• Roll out to your full device fleet")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            
            Button("Start Chatting with The Blacksmith") {
                showingCompletion = false
                dismiss()
                chatModel.sendSystemMessage("Right then, I've got your MDM setup configuration all sorted. What would you like to tackle first - setting up your server, configuring policies, or something else?")
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // MARK: - Actions
    private func completeWizard() {
        context.currentStep = wizardSteps.count
        context.completedSteps = wizardSteps
        showingCompletion = true
    }
    
    // MARK: - Helper Views
    private func wizardStepItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
        }
    }
    
    private func mdmOptionCard(title: String, description: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.1) : Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func deviceTypeOption(title: String, description: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func deploymentOption(title: String, description: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? color : .gray)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.1) : Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func configurationSection(title: String, options: [(String, String)], selectedKey: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(options, id: \.0) { option in
                    Button(action: {
                        context.configuration[selectedKey] = option.0
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.0)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(option.1)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: context.configuration[selectedKey] == option.0 ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(context.configuration[selectedKey] == option.0 ? .blue : .gray)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(context.configuration[selectedKey] == option.0 ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func reviewItem(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Blacksmith Package Wizard View
struct BlacksmithPackageWizardView: View {
    @Binding var workflow: PackageCreationWorkflow
    @ObservedObject var chatModel: BlacksmithChatModel
    @ObservedObject var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showingFilePicker = false
    @State private var isAnalyzing = false
    @State private var isCreating = false
    @State private var currentTask = ""
    @State private var progress: Double = 0.0
    @State private var showingCompletion = false
    @State private var outputPath: URL?
    
    private let wizardSteps = [
        "Upload Package",
        "Analyze Package", 
        "Add Script",
        "Set Permissions",
        "Create Package",
        "Complete"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "hammer.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Package Creation Wizard")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("The Blacksmith's Package Forge")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(LCARSTheme.panel)
            
            // Progress Header
            wizardProgressHeader
            
            // Main Content
            Group {
                switch currentStep {
                case 0:
                    uploadStep
                case 1:
                    analysisStep
                case 2:
                    scriptStep
                case 3:
                    permissionsStep
                case 4:
                    creationStep
                case 5:
                    completionStep
                default:
                    uploadStep
                }
            }
            
            // Navigation Buttons
            wizardNavigation
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(LCARSTheme.background)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.application, .package, .diskImage],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .sheet(isPresented: $showingCompletion) {
            wizardCompletionView
        }
    }
    
    // MARK: - Progress Header
    private var wizardProgressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(0..<wizardSteps.count, id: \.self) { index in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(index <= currentStep ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.orange, lineWidth: 2)
                                    .opacity(index <= currentStep ? 1 : 0)
                            )
                        
                        if index < wizardSteps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? Color.orange : Color.gray.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: 40)
                        }
                    }
                }
            }
            
            Text("Step \(currentStep + 1) of \(wizardSteps.count): \(wizardSteps[currentStep])")
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(LCARSTheme.panel)
    }
    
    // MARK: - Navigation
    private var wizardNavigation: some View {
        HStack {
            Button("Previous") {
                if currentStep > 0 {
                    withAnimation {
                        currentStep -= 1
                    }
                }
            }
            .disabled(currentStep == 0)
            
            Spacer()
            
            if currentStep < wizardSteps.count - 1 {
                Button("Next") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceedToNextStep)
            } else {
                Button("Complete") {
                    completeWizard()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(LCARSTheme.panel)
    }
    
    // MARK: - Upload Step
    private var uploadStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Upload Your Package")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Right then, let's start with your app, package, or disk image. I'll analyze it and help you add scripts and permissions.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                if let fileURL = workflow.uploadedFile {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.blue)
                        Text(fileURL.lastPathComponent)
                            .font(.headline)
                        Spacer()
                        Button("Change") {
                            showingFilePicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                } else {
                    Button("Choose File") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Supported formats:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• .app - macOS Applications")
                    Text("• .pkg - Installer Packages")
                    Text("• .dmg - Disk Images")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Analysis Step
    private var analysisStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("Package Analysis")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Let me have a look at what we're working with here...")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if isAnalyzing {
                VStack(spacing: 16) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(currentTask)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Spinning hammer animation
                    Image(systemName: "hammer.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                        .rotationEffect(.degrees(progress * 360))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: progress)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
            } else if let analysis = workflow.packageAnalysis {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Analysis Complete!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Package: \(analysis.fileName)")
                        Text("Type: \(analysis.packageType.rawValue)")
                        Text("Size: \(ByteCountFormatter.string(fromByteCount: analysis.fileSize, countStyle: .file))")
                        Text("Signed: \(analysis.securityInfo.isSigned ? "Yes" : "No")")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
            } else {
                Button("Analyze Package") {
                    analyzePackage()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Script Step
    private var scriptStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Add Your Script")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("What script do you want to run with this package? I'll make sure it's properly integrated.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Script Timing")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Picker("Script Timing", selection: $workflow.scriptTiming) {
                        ForEach(PackageCreationWorkflow.ScriptTiming.allCases, id: \.self) { timing in
                            Text(timing.rawValue).tag(timing)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Script Content")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextEditor(text: $workflow.scriptContent)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Permissions Step
    private var permissionsStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.purple)
            
            VStack(spacing: 12) {
                Text("Set Permissions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("What permissions does your app need? I'll create a proper PPPC profile for you.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(PPPCRequirement.commonPermissions) { permission in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(permission.permissionType)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text(permission.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { workflow.requiredPermissions.contains { $0.permissionType == permission.permissionType } },
                            set: { isOn in
                                if isOn {
                                    workflow.requiredPermissions.append(permission)
                                } else {
                                    workflow.requiredPermissions.removeAll { $0.permissionType == permission.permissionType }
                                }
                            }
                        ))
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Creation Step
    private var creationStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "hammer.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Forge Your Package")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Right then, let me work my magic and create your package with all the bells and whistles!")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if isCreating {
                VStack(spacing: 16) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(currentTask)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Spinning hammer animation
                    Image(systemName: "hammer.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                        .rotationEffect(.degrees(progress * 360))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: progress)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
            } else {
                Button("Start Forging") {
                    createPackage()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Completion Step
    private var completionStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Package Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Right then, your package is ready! I've created everything you need.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let outputPath = outputPath {
                VStack(spacing: 16) {
                    Text("Your package has been created at:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(outputPath.path)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([outputPath])
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Completion View
    private var wizardCompletionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Package Forged Successfully!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Right then, you're all sorted! I've created your package with scripts and permissions.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Text("What I've created for you:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Modified package with your script")
                    Text("• PPPC profile for permissions")
                    Text("• README with instructions")
                    Text("• All files packaged in a ZIP")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            
            Button("Start Chatting with The Blacksmith") {
                showingCompletion = false
                dismiss()
                chatModel.sendSystemMessage("Right then, your package is all sorted! What else can I help you with today?")
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // MARK: - Helper Properties
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 0: return workflow.uploadedFile != nil
        case 1: return workflow.packageAnalysis != nil
        case 2: return !workflow.scriptContent.isEmpty
        case 3: return true // Permissions are optional
        case 4: return true // Creation step
        default: return true
        }
    }
    
    // MARK: - Actions
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                workflow.uploadedFile = url
                workflow.packageAnalysis = nil // Reset analysis
            }
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
    
    private func analyzePackage() {
        guard let fileURL = workflow.uploadedFile else { return }
        
        isAnalyzing = true
        progress = 0.0
        currentTask = "Analyzing package structure..."
        
        Task {
            // Simulate analysis progress
            for i in 1...5 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    progress = Double(i) / 5.0
                    switch i {
                    case 1: currentTask = "Reading package metadata..."
                    case 2: currentTask = "Checking security signatures..."
                    case 3: currentTask = "Analyzing file structure..."
                    case 4: currentTask = "Generating analysis report..."
                    case 5: currentTask = "Analysis complete!"
                    default: break
                    }
                }
            }
            
            // Create mock analysis
            let analysis = PackageAnalysis(
                fileName: fileURL.lastPathComponent,
                filePath: fileURL.path,
                fileSize: 1024 * 1024 * 50, // 50MB
                analysisDate: Date(),
                packageType: .pkg,
                metadata: PackageMetadata(
                    bundleIdentifier: "com.example.app",
                    version: "1.0.0",
                    displayName: "Example App",
                    description: "A sample application",
                    author: "Example Corp",
                    installLocation: "/Applications",
                    minimumOSVersion: "10.15",
                    architecture: ["arm64"],
                    creationDate: Date(),
                    modificationDate: Date()
                ),
                contents: PackageContents(
                    files: [],
                    directories: [],
                    totalFiles: 100,
                    totalSize: 1024 * 1024 * 50,
                    installSize: 1024 * 1024 * 50
                ),
                permissions: [],
                scripts: [],
                dependencies: [],
                securityInfo: SecurityInfo(
                    isSigned: true,
                    signatureValid: true,
                    certificateInfo: CertificateInfo(
                        commonName: "Developer ID Application: Example Corp",
                        organization: "Example Corp",
                        validityStart: Date(),
                        validityEnd: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
                        isDeveloperID: true
                    ),
                    codeRequirements: nil,
                    needsSigning: false,
                    securityIssues: []
                ),
                recommendations: []
            )
            
            await MainActor.run {
                workflow.packageAnalysis = analysis
                isAnalyzing = false
            }
        }
    }
    
    private func createPackage() {
        isCreating = true
        progress = 0.0
        currentTask = "Starting package creation..."
        
        Task {
            // Simulate package creation progress
            let tasks = [
                "Preparing package structure...",
                "Integrating script files...",
                "Creating PPPC profile...",
                "Building final package...",
                "Generating documentation...",
                "Creating delivery ZIP..."
            ]
            
            for (index, task) in tasks.enumerated() {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    progress = Double(index + 1) / Double(tasks.count)
                    currentTask = task
                }
            }
            
            // Create output path
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let outputPath = documentsPath.appendingPathComponent("BlacksmithPackage_\(Date().timeIntervalSince1970).zip")
            
            await MainActor.run {
                self.outputPath = outputPath
                workflow.outputPath = outputPath
                workflow.isComplete = true
                isCreating = false
                showingCompletion = true
            }
        }
    }
    
    private func completeWizard() {
        showingCompletion = true
    }
}

// MARK: - Preview
#Preview {
    BlacksmithView()
        .environmentObject(UserSettings())
}
