//
//  ThemeManager.swift
//  MacForge
//
//  Manages application themes and provides a centralized way to switch between
//  different UI themes (Default and LCARS).
//

import SwiftUI
import Combine

// MARK: - Theme Manager
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .default
    @Published var isLCARSActive: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "MacForge.AppTheme"
    
    init() {
        loadSavedTheme()
    }
    
    // MARK: - Theme Management
    func switchTheme(to theme: AppTheme) {
        currentTheme = theme
        isLCARSActive = (theme == .lcars)
        saveTheme()
    }
    
    func toggleTheme() {
        let newTheme: AppTheme = currentTheme == .default ? .lcars : .default
        switchTheme(to: newTheme)
    }
    
    // MARK: - Persistence
    private func saveTheme() {
        userDefaults.set(currentTheme.rawValue, forKey: themeKey)
    }
    
    private func loadSavedTheme() {
        if let savedTheme = userDefaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
            isLCARSActive = (theme == .lcars)
        }
    }
    
    // MARK: - Theme-Specific Properties
    var backgroundColor: Color {
        switch currentTheme {
        case .default:
            return DefaultTheme.bg
        case .lcars:
            return LCARSTheme.background
        }
    }
    
    var surfaceColor: Color {
        switch currentTheme {
        case .default:
            return DefaultTheme.panel
        case .lcars:
            return LCARSTheme.surface
        }
    }
    
    var primaryColor: Color {
        switch currentTheme {
        case .default:
            return DefaultTheme.amber
        case .lcars:
            return LCARSTheme.primary
        }
    }
    
    var secondaryColor: Color {
        switch currentTheme {
        case .default:
            return DefaultTheme.orange
        case .lcars:
            return LCARSTheme.secondary
        }
    }
    
    var accentColor: Color {
        switch currentTheme {
        case .default:
            return DefaultTheme.amber
        case .lcars:
            return LCARSTheme.accent
        }
    }
    
    var panelColor: Color {
        switch currentTheme {
        case .default:
            return DefaultTheme.panel
        case .lcars:
            return LCARSTheme.panel
        }
    }
}

// MARK: - App Theme Enum
enum AppTheme: String, CaseIterable, Identifiable {
    case `default` = "default"
    case lcars = "lcars"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .default: return "Default Theme"
        case .lcars: return "LCARS Theme"
        }
    }
    
    var description: String {
        switch self {
        case .default: return "Clean, modern macOS interface"
        case .lcars: return "Star Trek-inspired futuristic interface"
        }
    }
    
    var icon: String {
        switch self {
        case .default: return "paintbrush"
        case .lcars: return "sparkles"
        }
    }
}

// MARK: - Theme Environment Key
struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeManager = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Theme-Aware View Modifier
struct ThemeAwareBackground: ViewModifier {
    @Environment(\.themeManager) var themeManager
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.backgroundColor)
    }
}

extension View {
    func themeAwareBackground() -> some View {
        self.modifier(ThemeAwareBackground())
    }
}
