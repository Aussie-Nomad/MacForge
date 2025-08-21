//
//  GlobalListeners.swift
//  MacForge
//
//  Created by Danny Mac on 14/08/2025.
//
// V3

import SwiftUI

private struct GlobalEventListeners: ViewModifier {
    @ObservedObject var model: BuilderModel
    @Binding var selectedMDM: MDMVendor?
    @Binding var selectedTool: ToolModule?

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .jfHomeRequested)) { _ in
                selectedTool = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: .jfChangeMDMRequested)) { _ in
                model.jamfAuthOK = false
                model.mdmLocked = false
                selectedMDM = nil
                selectedTool = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: .jfReportBugRequested)) { _ in
                // no-op here, handled in UI
            }
    }
}

extension View {
    func jamforgeGlobalListeners(model: BuilderModel,
                                 selectedMDM: Binding<MDMVendor?>,
                                 selectedTool: Binding<ToolModule?>) -> some View { self.modifier(GlobalEventListeners(model: model, selectedMDM: selectedMDM, selectedTool: selectedTool)) }
}
