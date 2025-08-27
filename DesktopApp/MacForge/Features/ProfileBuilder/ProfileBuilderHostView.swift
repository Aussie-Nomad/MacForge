//
//  ProfileBuilderHostView.swift
//  MacForge
//
//  Main host view for the profile builder tool.
//  Coordinates the profile building workflow and manages the overall builder state.

import SwiftUI

struct ProfileBuilderHostView: View {
    @StateObject private var viewModel: ProfileBuilderViewModel
    @ObservedObject var model: BuilderModel
    var onHome: () -> Void

    init(selectedMDM: MDMVendor?, model: BuilderModel, onHome: @escaping () -> Void) {
        self.model = model
        self.onHome = onHome
        self._viewModel = StateObject(wrappedValue: ProfileBuilderViewModel(builderModel: model, selectedMDM: selectedMDM))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left sidebar
            ProfileSidebar(model: model, onHome: onHome)
                .frame(width: LcarsTheme.Sidebar.width)

            // Center content
            ProfileCenterPane(model: model, viewModel: viewModel, onHome: onHome)
                .frame(maxWidth: .infinity)

            // Right detail pane
            ProfileDetailPane(model: model, viewModel: viewModel)
                .frame(width: 300)
        }
        .sheet(isPresented: $viewModel.showJamfAuthSheet) {
            JamfAuthSheet { result in
                viewModel.handleJamfAuthResult(result)
            }
        }
    }
}
