//
//  WizardHeader.swift
//  MacForge
//
//  Reusable wizard header component for step-by-step workflows.
//  Provides consistent navigation and progress indication for wizard interfaces.

import SwiftUI

struct WizardHeader: View {
    let step: Int
    let totalSteps: Int
    
    init(step: Int, totalSteps: Int = 3) {
        self.step = step
        self.totalSteps = totalSteps
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("STEP \(step) OF \(totalSteps)")
                .font(.headline)
                .foregroundStyle(LcarsTheme.amber)
            
            HStack(spacing: 16) {
                ForEach(1...totalSteps, id: \.self) { stepNumber in
                    Circle()
                        .fill(stepNumber <= step ? LcarsTheme.amber : LcarsTheme.panel)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(LcarsTheme.amber, lineWidth: stepNumber <= step ? 2 : 1)
                        )
                }
            }
        }
    }
}
