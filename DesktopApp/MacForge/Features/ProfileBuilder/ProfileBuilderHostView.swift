//
//  ProfileBuilderHostView.swift
//  MacForge
//
//  PPPC Profile Creator Host View - Uses the comprehensive ProfileBuilderWizard
//  for guided profile creation with 4-step process.
//

import SwiftUI

struct ProfileBuilderHostView: View {
    let selectedMDM: MDMVendor?
    let model: BuilderModel
    let onHome: () -> Void
    
    var body: some View {
        ProfileBuilderWizard(
            selectedMDM: selectedMDM,
            model: model,
            onHome: onHome
        )
    }
}

#Preview {
    ProfileBuilderHostView(
        selectedMDM: .jamf,
        model: BuilderModel(),
        onHome: {}
    )
}
