//
//  WelcomeView.swift
//  MacForge
//
//  Welcome/tutorial popup for first-time users
//  Guides users through initial setup steps with flashy animations
//

import SwiftUI

struct WelcomeView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var showingAnimation = false
    @State private var pulseScale: CGFloat = 1.0
    
    private let steps = [
        WelcomeStep(
            icon: "gear.badge.checkmark",
            title: "Set Up Your Accounts",
            description: "Configure your MDM and AI provider accounts in Settings",
            color: .blue,
            action: "Go to Settings"
        ),
        WelcomeStep(
            icon: "building.2.crop.circle",
            title: "Choose Your MDM",
            description: "Select your MDM vendor from the sidebar menu",
            color: .green,
            action: "Pick MDM Vendor"
        ),
        WelcomeStep(
            icon: "hammer.fill",
            title: "Select Your Tool",
            description: "Choose from Profile Builder, Script Smelter, Log Burner, and more",
            color: .orange,
            action: "Pick a Tool"
        ),
        WelcomeStep(
            icon: "sparkles",
            title: "Start Forging!",
            description: "You're ready to build, deploy, and manage macOS configurations",
            color: .purple,
            action: "Let's Go!"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                colors: [LCARSTheme.background, LCARSTheme.background.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundStyle(.yellow)
                            .scaleEffect(pulseScale)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                        
                        Text("Welcome to MacForge")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(LCARSTheme.primary)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundStyle(.yellow)
                            .scaleEffect(pulseScale)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                    }
                    
                    Text("Your macOS Configuration Forge")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Progress indicator
                HStack(spacing: 12) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? steps[index].color : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .scaleEffect(index == currentStep ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
                .padding(.bottom, 40)
                
                // Current step content
                VStack(spacing: 24) {
                    // Icon with animation
                    ZStack {
                        Circle()
                            .fill(steps[currentStep].color.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .scaleEffect(showingAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.6), value: showingAnimation)
                        
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(steps[currentStep].color)
                            .scaleEffect(showingAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.6), value: showingAnimation)
                    }
                    
                    // Text content
                    VStack(spacing: 12) {
                        Text(steps[currentStep].title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(LCARSTheme.primary)
                            .multilineTextAlignment(.center)
                        
                        Text(steps[currentStep].description)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation(.spring(response: 0.5)) {
                                currentStep -= 1
                                showingAnimation = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showingAnimation = true
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == steps.count - 1 ? "Get Started!" : "Next") {
                        if currentStep == steps.count - 1 {
                            // Final step - close welcome
                            withAnimation(.spring(response: 0.6)) {
                                isPresented = false
                            }
                        } else {
                            // Next step
                            withAnimation(.spring(response: 0.5)) {
                                currentStep += 1
                                showingAnimation = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showingAnimation = true
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(steps[currentStep].color)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(width: 600, height: 500)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            // Start animations
            showingAnimation = true
            pulseScale = 1.2
        }
    }
}

// MARK: - Welcome Step Model
struct WelcomeStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: String
}

// MARK: - Preview
#Preview {
    WelcomeView(isPresented: .constant(true))
}
