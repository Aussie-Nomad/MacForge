//
//  ScalableContainer.swift
//  MacForge
//
//  Scalable container that maintains hit-test accuracy for interactive controls.
//  Ensures UI elements remain clickable and accessible when the view is scaled.
//

import SwiftUI

/// A responsive container that adapts content to available window space
/// while maintaining proper proportions and adding scrolling when needed.
struct ScalableContainer<Content: View>: View {
    let base: CGSize
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let availableSize = geo.size
            let safeBase = CGSize(width: max(base.width, 1), height: max(base.height, 1))
            
            // Calculate if we need to scale down or if we have enough space
            let needsScaling = availableSize.width < safeBase.width || availableSize.height < safeBase.height
            
            if needsScaling {
                // Scale down approach for smaller windows
                let scale = min(availableSize.width / safeBase.width, availableSize.height / safeBase.height)
                let scaledSize = CGSize(width: safeBase.width * scale, height: safeBase.height * scale)
                
                ZStack {
                    Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
                    
                    content()
                        .frame(width: safeBase.width, height: safeBase.height)
                        .compositingGroup()
                        .scaleEffect(scale, anchor: .topLeading)
                        .contentShape(Rectangle())
                        .frame(width: scaledSize.width, height: scaledSize.height, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                // Full size approach with proper padding for larger windows
                ZStack {
                    Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
                    
                    content()
                        .frame(maxWidth: safeBase.width, maxHeight: safeBase.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.horizontal, max(0, (availableSize.width - safeBase.width) / 2))
                        .padding(.vertical, max(0, (availableSize.height - safeBase.height) / 2))
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
}
