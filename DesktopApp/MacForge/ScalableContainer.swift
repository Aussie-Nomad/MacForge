//
//  ScalableContainer.swift
//  MacForge
//
//  Created by Danny Mac on 14/08/2025.
//
//  V4 – hit‑test safe scaler. Keeps interactive controls clickable when scaled.
//

import SwiftUI

/// A canvas that centers a fixed logical design size inside whatever space is available,
/// scaling down (never up) while preserving hit testing for interactive controls.
struct ScalableContainer<Content: View>: View {
    let base: CGSize
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let safeSize = CGSize(width: max(geo.size.width, 1), height: max(geo.size.height, 1))
            let safeBase = CGSize(width: max(base.width, 1), height: max(base.height, 1))

            // Compute a uniform scale but never upscale beyond 1.0
            let scale = min(min(safeSize.width / safeBase.width, safeSize.height / safeBase.height), 1.0)
            let scaledSize = CGSize(width: safeBase.width * scale, height: safeBase.height * scale)

            ZStack {
                LcarsTheme.bg.ignoresSafeArea()

                // Use a wrapper that owns the transform, then give it a Rectangle contentShape
                // so SwiftUI performs hit testing inside the *visible* area after scaling.
                content()
                    .frame(width: safeBase.width, height: safeBase.height)
                    .compositingGroup()                 // fixes some transform/hit-test quirks
                    .scaleEffect(scale, anchor: .center) // downscale uniformly
                    .contentShape(Rectangle())           // correct hit test region
                    .frame(width: scaledSize.width, height: scaledSize.height)
            }
            // Center the scaled canvas and let it breathe
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        // A sensible minimum so controls never get absurdly tiny
        .frame(minWidth: 900, minHeight: 600)
    }
}
