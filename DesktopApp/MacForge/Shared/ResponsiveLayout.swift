//
//  ResponsiveLayout.swift
//  MacForge
//
//  Responsive layout utilities for consistent spacing and layout patterns.
//  Provides adaptive layouts that work well at different window sizes.
//

import SwiftUI

// MARK: - Responsive Layout Constants
struct ResponsiveLayout {
    // Spacing values that adapt to window size
    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 16
    static let largeSpacing: CGFloat = 24
    static let extraLargeSpacing: CGFloat = 32
    
    // Padding values
    static let smallPadding: CGFloat = 12
    static let mediumPadding: CGFloat = 20
    static let largePadding: CGFloat = 24
    static let extraLargePadding: CGFloat = 32
    
    // Corner radius values
    static let smallCornerRadius: CGFloat = 6
    static let mediumCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 12
    static let extraLargeCornerRadius: CGFloat = 16
    
    // Minimum sizes for responsive elements
    static let minimumButtonHeight: CGFloat = 32
    static let minimumCardHeight: CGFloat = 80
    static let minimumSectionHeight: CGFloat = 120
}

// MARK: - Responsive Grid Layout
struct ResponsiveGrid<Content: View>: View {
    let columns: [GridItem]
    let spacing: CGFloat
    let content: () -> Content
    
    init(columns: Int = 2, spacing: CGFloat = ResponsiveLayout.mediumSpacing, @ViewBuilder content: @escaping () -> Content) {
        self.columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            content()
        }
    }
}

// MARK: - Responsive Card Layout
struct ResponsiveCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let backgroundColor: Color
    
    init(padding: CGFloat = ResponsiveLayout.mediumPadding,
         cornerRadius: CGFloat = ResponsiveLayout.mediumCornerRadius,
         backgroundColor: Color = LcarsTheme.panel.opacity(0.3),
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(LcarsTheme.orange.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Responsive Section Layout
struct ResponsiveSection<Header: View, Content: View>: View {
    let header: Header
    let content: Content
    let spacing: CGFloat
    
    init(spacing: CGFloat = ResponsiveLayout.mediumSpacing,
         @ViewBuilder header: () -> Header,
         @ViewBuilder content: () -> Content) {
        self.header = header()
        self.content = content()
        self.spacing = spacing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            header
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Responsive Button Layout
struct ResponsiveButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    let style: ButtonStyle
    let isEnabled: Bool
    
    init(action: @escaping () -> Void,
         isEnabled: Bool = true,
         style: ButtonStyle = .bordered,
         @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
        self.style = style
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(style)
        .disabled(!isEnabled)
        .contentShape(Rectangle())
        .frame(minHeight: ResponsiveLayout.minimumButtonHeight)
    }
}

// MARK: - Responsive Scroll Container
struct ResponsiveScrollContainer<Content: View>: View {
    let content: Content
    let showsIndicators: Bool
    let padding: EdgeInsets
    
    init(showsIndicators: Bool = true,
         padding: EdgeInsets = EdgeInsets(top: ResponsiveLayout.mediumPadding,
                                        leading: ResponsiveLayout.mediumPadding,
                                        bottom: ResponsiveLayout.mediumPadding,
                                        trailing: ResponsiveLayout.mediumPadding),
         @ViewBuilder content: () -> Content) {
        self.showsIndicators = showsIndicators
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            content
                .padding(padding)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Responsive Layout Extensions
extension View {
    /// Applies responsive padding that adapts to window size
    func responsivePadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        let paddingValue = length ?? ResponsiveLayout.mediumPadding
        return self.padding(edges, paddingValue)
    }
    
    /// Applies responsive spacing between elements
    func responsiveSpacing(_ length: CGFloat? = nil) -> some View {
        let spacingValue = length ?? ResponsiveLayout.mediumSpacing
        return self.frame(maxWidth: .infinity, minHeight: spacingValue)
    }
    
    /// Makes a view responsive with proper sizing
    func responsiveFrame(minHeight: CGFloat? = nil, maxHeight: CGFloat? = nil) -> some View {
        let minHeightValue = minHeight ?? ResponsiveLayout.minimumCardHeight
        return self.frame(maxWidth: .infinity, minHeight: minHeightValue, maxHeight: maxHeight)
    }
    
    /// Applies responsive corner radius
    func responsiveCornerRadius(_ radius: CGFloat? = nil) -> some View {
        let radiusValue = radius ?? ResponsiveLayout.mediumCornerRadius
        return self.clipShape(RoundedRectangle(cornerRadius: radiusValue))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: ResponsiveLayout.largeSpacing) {
        ResponsiveCard {
            Text("Sample Card")
                .font(.headline)
        }
        
        ResponsiveButton(action: {}) {
            Text("Sample Button")
        }
        
        ResponsiveSection {
            Text("Section Header")
                .font(.headline)
        } content: {
            Text("Section content goes here")
        }
        
        ResponsiveGrid(columns: 3) {
            ForEach(0..<6, id: \.self) { index in
                Text("Item \(index)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    .padding()
    .background(LcarsTheme.bg)
}
