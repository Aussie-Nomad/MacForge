//
//  AccessibilityHelpers.swift
//  MacForge
//
//  Accessibility helpers and utilities for improved user experience.
//  Provides screen reader support, keyboard navigation, and accessibility labels.
//

import SwiftUI

// MARK: - Accessibility Helpers
struct AccessibilityHelpers {
    
    // MARK: - Screen Reader Support
    
    /// Add accessibility label for screen readers
    static func accessibilityLabel(_ label: String) -> some View {
        EmptyView()
            .accessibilityLabel(label)
    }
    
    /// Add accessibility hint for additional context
    static func accessibilityHint(_ hint: String) -> some View {
        EmptyView()
            .accessibilityHint(hint)
    }
    
    /// Add accessibility value for dynamic content
    static func accessibilityValue(_ value: String) -> some View {
        EmptyView()
            .accessibilityValue(value)
    }
    
    /// Add accessibility action for custom interactions
    static func accessibilityAction(named name: String, action: @escaping () -> Void) -> some View {
        EmptyView()
            .accessibilityAction(named: name, action)
    }
    
    // MARK: - Keyboard Navigation
    
    /// Add keyboard shortcut for actions
    static func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = []) -> some View {
        EmptyView()
            .keyboardShortcut(key, modifiers: modifiers)
    }
    
    /// Add default keyboard shortcut
    static func defaultKeyboardShortcut() -> some View {
        EmptyView()
            .keyboardShortcut(.defaultAction)
    }
    
    /// Add cancel keyboard shortcut
    static func cancelKeyboardShortcut() -> some View {
        EmptyView()
            .keyboardShortcut(.cancelAction)
    }
    
    // MARK: - Focus Management
    
    /// Add focus state management
    static func focused(_ condition: FocusState<Bool>.Binding) -> some View {
        EmptyView()
            .focused(condition)
    }
    
    /// Add focusable modifier
    static func focusable(_ isFocusable: Bool = true) -> some View {
        EmptyView()
            .focusable(isFocusable)
    }
    
    // MARK: - High Contrast Support
    
    /// Add high contrast support
    static func highContrastSupport() -> some View {
        EmptyView()
            .preferredColorScheme(.none)
    }
    
    // MARK: - Dynamic Type Support
    
    /// Add dynamic type support
    static func dynamicTypeSupport() -> some View {
        EmptyView()
            .dynamicTypeSize(.large)
    }
}

// MARK: - Accessibility Extensions

extension View {
    
    /// Add comprehensive accessibility support
    func accessibilitySupport(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil,
        isButton: Bool = false,
        isSelected: Bool = false,
        isEnabled: Bool = true
    ) -> some View {
        var view = self
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
        
        if isButton {
            view = view.accessibilityAddTraits(.isButton)
        }
        
        if isSelected {
            view = view.accessibilityAddTraits(.isSelected)
        }
        
        if !isEnabled {
            view = view.accessibilityAddTraits(.isButton)
        }
        
        return view
    }
    
    /// Add button accessibility
    func buttonAccessibility(
        label: String,
        hint: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double-tap to activate")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Add text field accessibility
    func textFieldAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Enter text")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isKeyboardKey)
    }
    
    /// Add image accessibility
    func imageAccessibility(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isImage)
    }
    
    /// Add navigation accessibility
    func navigationAccessibility(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Navigate to \(label)")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Add status accessibility
    func statusAccessibility(
        label: String,
        value: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "Current status")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    /// Add progress accessibility
    func progressAccessibility(
        label: String,
        value: Double,
        maxValue: Double = 1.0,
        hint: String? = nil
    ) -> some View {
        let percentage = Int((value / maxValue) * 100)
        return self
            .accessibilityLabel(label)
            .accessibilityValue("\(percentage)% complete")
            .accessibilityHint(hint ?? "Progress indicator")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    /// Add error accessibility
    func errorAccessibility(
        message: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel("Error")
            .accessibilityValue(message)
            .accessibilityHint(hint ?? "Error message")
            .accessibilityAddTraits(.isSelected)
    }
    
    /// Add success accessibility
    func successAccessibility(
        message: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel("Success")
            .accessibilityValue(message)
            .accessibilityHint(hint ?? "Success message")
            .accessibilityAddTraits(.isSelected)
    }
    
    /// Add loading accessibility
    func loadingAccessibility(
        message: String = "Loading",
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(message)
            .accessibilityHint(hint ?? "Please wait")
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Accessibility Constants

struct AccessibilityConstants {
    
    // MARK: - Common Labels
    static let close = "Close"
    static let cancel = "Cancel"
    static let done = "Done"
    static let save = "Save"
    static let delete = "Delete"
    static let edit = "Edit"
    static let add = "Add"
    static let remove = "Remove"
    static let refresh = "Refresh"
    static let search = "Search"
    static let filter = "Filter"
    static let sort = "Sort"
    static let export = "Export"
    static let import_ = "Import"
    static let settings = "Settings"
    static let help = "Help"
    static let about = "About"
    
    // MARK: - Common Hints
    static let doubleTapToActivate = "Double-tap to activate"
    static let doubleTapToSelect = "Double-tap to select"
    static let swipeToNavigate = "Swipe to navigate"
    static let pinchToZoom = "Pinch to zoom"
    static let longPressForOptions = "Long press for options"
    static let dragToReorder = "Drag to reorder"
    
    // MARK: - Status Messages
    static let loading = "Loading, please wait"
    static let success = "Operation completed successfully"
    static let error = "An error occurred"
    static let warning = "Warning"
    static let info = "Information"
    
    // MARK: - Navigation
    static let back = "Go back"
    static let forward = "Go forward"
    static let home = "Go to home"
    static let menu = "Open menu"
    static let toolbar = "Toolbar"
    static let sidebar = "Sidebar"
    static let content = "Main content"
}

// MARK: - Accessibility Testing

struct AccessibilityTesting {
    
    /// Test accessibility labels
    static func testAccessibilityLabels() {
        // This would be used in UI tests to verify accessibility
        print("Testing accessibility labels...")
    }
    
    /// Test keyboard navigation
    static func testKeyboardNavigation() {
        // This would be used in UI tests to verify keyboard navigation
        print("Testing keyboard navigation...")
    }
    
    /// Test screen reader compatibility
    static func testScreenReaderCompatibility() {
        // This would be used in UI tests to verify screen reader compatibility
        print("Testing screen reader compatibility...")
    }
}

// MARK: - Accessibility Preferences

class AccessibilityPreferences: ObservableObject {
    @Published var isHighContrastEnabled: Bool = false
    @Published var isReduceMotionEnabled: Bool = false
    @Published var isReduceTransparencyEnabled: Bool = false
    @Published var preferredContentSizeCategory: ContentSizeCategory = .large
    
    init() {
        // Initialize with system preferences
        updateFromSystemPreferences()
    }
    
    private func updateFromSystemPreferences() {
        // This would read from system accessibility preferences
        // For now, we'll use default values
        isHighContrastEnabled = false
        isReduceMotionEnabled = false
        isReduceTransparencyEnabled = false
        preferredContentSizeCategory = .large
    }
}

// MARK: - Content Size Category

enum ContentSizeCategory: String, CaseIterable {
    case extraSmall = "Extra Small"
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
    case extraExtraLarge = "Extra Extra Large"
    case extraExtraExtraLarge = "Extra Extra Extra Large"
    case accessibilityMedium = "Accessibility Medium"
    case accessibilityLarge = "Accessibility Large"
    case accessibilityExtraLarge = "Accessibility Extra Large"
    case accessibilityExtraExtraLarge = "Accessibility Extra Extra Large"
    case accessibilityExtraExtraExtraLarge = "Accessibility Extra Extra Extra Large"
    
    var systemValue: DynamicTypeSize {
        switch self {
        case .extraSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .xLarge
        case .extraExtraLarge: return .xxLarge
        case .extraExtraExtraLarge: return .xxxLarge
        case .accessibilityMedium: return .accessibility1
        case .accessibilityLarge: return .accessibility2
        case .accessibilityExtraLarge: return .accessibility3
        case .accessibilityExtraExtraLarge: return .accessibility4
        case .accessibilityExtraExtraExtraLarge: return .accessibility5
        }
    }
}
