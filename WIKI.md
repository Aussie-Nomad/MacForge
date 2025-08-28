# MacForge Wiki 📚

**MacForge** is a powerful macOS application for creating and managing configuration profiles, with specialized support for **Privacy Preferences Policy Control (PPPC)** and **MDM integration**. This wiki provides comprehensive documentation for users, developers, and contributors.

[![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![Status](https://img.shields.io/badge/Status-Beta-orange.svg)](https://github.com/Aussie-Nomad/MacForge)

## 🚀 **Quick Navigation**

| **For Users** | **For Developers** | **For Contributors** |
|---------------|-------------------|---------------------|
| [Getting Started](#getting-started) | [Architecture Overview](#architecture-overview) | [Contributor WIKI](Contributor_WIKI.md) |
| [Current Features](#current-features) | [Technical Architecture](#technical-architecture) | [Development Guidelines](#development-guidelines) |
| [User Interface](#user-interface) | [Code Structure](#code-structure) | [Improvement Roadmap](#improvement-roadmap) |
| [Troubleshooting](#troubleshooting) | [Testing Strategy](#testing-strategy) | [Code Standards](#code-standards) |

## 📋 **Table of Contents**

- [Overview](#overview)
- [Current State Assessment](#current-state-assessment)
- [Architecture Overview](#architecture-overview)
- [Current Features](#current-features)
- [PPPC Editor](#pppc-editor)
- [MDM Integration](#mdm-integration)
- [Authentication Methods](#authentication-methods)
- [Profile Management](#profile-management)
- [User Interface](#user-interface)
- [Technical Architecture](#technical-architecture)
- [Development Guidelines](#development-guidelines)
- [Improvement Roadmap](#improvement-roadmap)
- [Getting Started](#getting-started)
- [Troubleshooting](#troubleshooting)

## Overview

MacForge is designed to simplify the creation of macOS configuration profiles, particularly focusing on Privacy Preferences Policy Control (PPPC) profiles that manage app permissions. It provides an intuitive wizard-based interface and seamless integration with major MDM platforms.

### Key Benefits
- **Drag & Drop Simplicity**: Drop any .app file to automatically extract bundle identifiers and code requirements
- **Visual Wizard Interface**: 3-step guided process for creating profiles
- **MDM Integration**: Direct submission to Jamf Pro with more MDMs coming soon
- **Professional UI**: Modern, themed interface inspired by LCARS design
- **Robust Error Handling**: Clear feedback and automatic retry mechanisms

## Current State Assessment

### ✅ **What's Working Well**

#### **Architecture & Code Quality**
- **Clean MVVM Architecture**: Well-separated concerns with Services, ViewModels, and Views
- **Simplified Authentication**: Focused JAMF Pro service without unnecessary abstraction
- **Consistent Documentation**: All files have clear, structured headers explaining purpose
- **Modern SwiftUI**: Uses latest SwiftUI patterns and best practices
- **Type Safety**: Good use of Swift's type system and enums
- **macOS-Focused**: Removed unnecessary cross-platform complexity

#### **Core Functionality**
- **Profile Builder**: Fully implemented with comprehensive PPPC support
- **JAMF Pro Integration**: Complete authentication and profile submission
- **PPPC Editor**: Robust permission management with visual interface
- **Package Smelting**: Basic but functional package management tool
- **Theme System**: Consistent LCARS-inspired design throughout

### ✅ **What's Been Improved**

#### **Completed Features**
- **Package Smelting**: Now functional with drag-and-drop package analysis
- **Simplified Architecture**: Removed unnecessary protocols and abstractions
- **State Management**: Simplified NotificationCenter usage with direct event handling
- **File Organization**: Better structured feature-based organization

#### **Removed Complexity**
- **iOS Support**: Eliminated cross-platform code and orientation handling
- **Over-Engineering**: Simplified authentication service to focus on JAMF Pro
- **Unused Protocols**: Removed generic authentication protocols and credentials

### 🗑️ **What's Been Removed**

- **Cross-Platform Orientation**: iOS-specific orientation handling eliminated
- **Mobile UI Patterns**: Touch interface support removed
- **Generic MDM Protocols**: Replaced with focused JAMF Pro implementation
- **Complex Notification System**: Simplified to direct event handling
- **Unused Authentication Protocols**: Removed unnecessary abstractions

## Architecture Overview

### **Current Architecture**
```
MacForge/
├── Core/                           # Core app functionality
│   ├── MacForgeApp.swift          # App entry point
│   ├── ContentView.swift          # Main navigation
│   └── GlobalSidebar.swift        # Navigation sidebar
├── Features/                       # Feature-specific modules
│   ├── ProfileBuilder/            # Profile building interface
│   │   ├── ProfileBuilderHostView.swift
│   │   ├── ProfileCenterPane.swift
│   │   ├── ProfileDetailPane.swift
│   │   ├── ProfileSidebar.swift
│   │   ├── ProfileTopToolbar.swift
│   │   └── StepContent.swift
│   ├── PPPC/                      # PPPC editor functionality
│   │   └── PPPCEditor.swift
│   └── Tools/                     # Development and debugging tools
│       ├── ToolHost.swift         # Tool hosting and Package Smelting
│       ├── PaylodEditors.swift    # Payload editing utilities
│       └── JamfDebugView.swift   # JAMF debugging interface
├── Services/                       # Business logic layer
│   ├── AuthenticationService.swift # JAMF Pro authentication
│   ├── JAMFService.swift          # JAMF operations
│   └── ProfileExportService.swift # Profile export
├── ViewModels/                     # UI state management
│   ├── AuthenticationViewModel.swift
│   └── ProfileBuilderViewModel.swift
├── Views/                          # UI components
│   ├── Components/                # Reusable UI components
│   │   ├── CommonUI.swift
│   │   ├── MissingComponents.swift
│   │   ├── SettingsHeader.swift
│   │   ├── ThemeSwitcher.swift   # Theme selection interface
│   │   └── WizardHeader.swift
│   ├── JamfAuthSheet.swift        # Authentication UI
│   └── LandingPage.swift          # Main landing page
├── Models/                         # Data models
│   └── BuilderModel.swift         # Core data model
└── Shared/                         # Utilities and shared components
    ├── Theme.swift                # Default LCARS design system
    ├── LCARSTheme.swift           # Star Trek-inspired theme system
    ├── ThemeManager.swift         # Theme switching and management
    ├── Helpers.swift              # Utility functions
    ├── ScalableContainer.swift    # UI scaling
    └── SampleData.swift           # Sample data for development
```

### **Architecture Principles**
- **MVVM Pattern**: Clear separation of concerns
- **Feature-Focused**: Organized by functionality, not technical layers
- **Simplified Communication**: Direct event handling for app-wide events
- **Reusable Components**: Shared UI components and utilities
- **macOS-Native**: Optimized for desktop use without mobile complexity
- **Clear Organization**: Logical grouping makes codebase easier to navigate and maintain
- **Theme System**: Dual-theme support with Default and LCARS (Star Trek-inspired) interfaces

### **Code Structure Details**
The codebase follows a clear, feature-based organization that makes it easy for developers to understand and contribute:

#### **Core Components**
- **MacForgeApp.swift**: Application entry point and lifecycle management
- **ContentView.swift**: Main navigation container and routing
- **GlobalSidebar.swift**: MDM selection and tool navigation

#### **Feature Modules**
- **ProfileBuilder/**: Complete profile creation workflow with 3-step wizard
- **PPPC/**: Privacy preferences management and configuration
- **Tools/**: Development utilities and debugging interfaces

#### **Service Layer**
- **AuthenticationService.swift**: JAMF Pro OAuth integration
- **JAMFService.swift**: MDM operations and profile submission
- **ProfileExportService.swift**: Profile generation and export

#### **Data Models**
- **BuilderModel.swift**: Core business logic for profile building
- **PPPCService.swift**: PPPC service definitions and configuration
- **PPPCConfiguration.swift**: Individual PPPC permission settings

#### **UI Components**
- **ViewModels/**: State management for UI components
- **Views/**: Reusable UI components and layouts
- **Shared/**: Common utilities, themes, and helpers

## Current Features

### ✅ **Implemented Features**

#### PPPC Profile Creation
- **App Target Configuration**
  - Drag and drop .app files for automatic bundle ID extraction
  - Automatic code requirement extraction using Security framework
  - Support for Bundle ID, Path, and Code Requirement identifier types
  - Visual drop zone with clear feedback

#### Privacy Permissions Management
- **Supported Services**:
  - 📷 Camera access
  - 🎤 Microphone access
  - 💾 Full Disk Access
  - 🖥️ Screen Recording (with type selection: All/Window Only)
  - 📁 Downloads Folder access
  - 📁 Desktop Folder access
  - 📁 Documents Folder access
  - 🔧 Accessibility permissions
  - ⚡ Apple Events (with receiver bundle ID configuration)

- **Permission States**:
  - **Allow**: Grant permission automatically
  - **Deny**: Block permission permanently
  - **Prompt**: Ask user for permission (default macOS behavior)

#### Profile Export & Management
- **Export Formats**:
  - `.mobileconfig` files for manual distribution
  - Direct MDM submission
  - XML plist format for programmatic use

- **Profile Settings**:
  - Custom profile names and descriptions
  - Organization branding
  - Unique identifiers
  - Version control

### 🚧 **Planned Features (Placeholder Status)**

#### **Package Smelting** 📦
- **Status**: ✅ Functional implementation
- **Purpose**: Upload and manage distribution packages
- **Features**: Drag-and-drop support, package analysis, MDM integration ready
- **Implementation**: Basic package info extraction and display

#### **Device Foundry** 🖥️
- **Status**: UI placeholder only
- **Purpose**: Smart & Static Group Creator for devices
- **Implementation**: Not started

#### **Blueprint Builder** 📐
- **Status**: UI placeholder only
- **Purpose**: Design reusable configuration blueprints
- **Implementation**: Not started

#### **Hammering Scripts** 🔨
- **Status**: UI placeholder with AI integration framework
- **Purpose**: AI-powered script builder
- **Implementation**: Basic AI service integration, no UI

### MDM Platform Support

#### Jamf Pro Integration ✅
- **Authentication Methods**:
  - OAuth (Client ID + Secret)
  - Basic Authentication (Username + Password)
- **Features**:
  - Automatic profile creation
  - Conflict resolution (updates existing profiles)
  - Error handling and retry logic
  - Connection validation

#### Planned MDM Integrations 🚧
- **Microsoft Intune** (UI ready, backend pending)
- **Kandji** (UI ready, backend pending)
- **Mosyle** (UI ready, backend pending)

### User Interface Features

#### **Dual Theme System** 🎨
- **Default Theme**: Clean, modern macOS interface with LCARS-inspired elements
  - Dark background with amber/orange accents
  - Rounded panels with subtle shadows
  - Professional, enterprise-ready appearance
- **LCARS Theme**: Full Star Trek-inspired futuristic interface
  - Deep blue-black backgrounds with vibrant orange, purple, and blue accents
  - Monospaced fonts and geometric panel designs
  - Interactive elements with hover effects and animations
- **Theme Switcher**: Easy switching between themes from the landing page
  - Persistent theme selection across app launches
  - Smooth transitions between themes
  - Visual preview of each theme option

#### 3-Step Wizard
1. **Select App & Configure Profile**
   - Profile metadata entry
   - App target selection via drag & drop
   - Identifier type configuration

2. **Configure Permissions**
   - Visual permission grid
   - Real-time validation
   - Progress indicators

3. **Review & Submit**
   - Profile summary
   - Export options
   - Direct MDM submission

## 🎯 **Development Guidelines**

### **Code Standards**
- **SwiftLint**: Enforce consistent code style
- **Documentation**: All files must have clear header comments
- **Architecture**: Follow MVVM pattern with clear separation of concerns
- **Testing**: Unit tests for business logic, UI tests for user flows

### **Swift Best Practices**
- Follow [Apple's Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftUI for all new UI components
- Implement proper error handling with custom error types
- Use async/await for asynchronous operations
- Maintain type safety and avoid force unwrapping
- Use descriptive naming conventions

### **Code Organization**
- **Group by Feature**: Organize files by functionality, not type
- **Clear Naming**: Descriptive file and function names
- **Consistent Structure**: Use MARK comments for logical sections
- **Shared Components**: Place reusable code in appropriate shared directories
- **Documentation**: Include usage examples and parameter descriptions

### **File Organization**
- **Group by Feature**: Organize files by functionality, not type
- **Clear Naming**: Descriptive file and function names
- **Consistent Structure**: Use MARK comments for logical sections
- **Shared Components**: Place reusable code in appropriate shared directories

### **Git Workflow**
- **Branch Strategy**: Feature branches for new development
- **Commit Messages**: Clear, descriptive commit messages
- **Code Reviews**: All changes require review before merge
- **Testing**: Ensure tests pass before submitting PRs

## 🧪 **Testing Strategy**

### **Test Coverage Goals**
- **Unit Tests**: >90% line coverage target
- **Integration Tests**: All major workflows covered
- **UI Tests**: Critical user journeys validated
- **Performance Tests**: Response time benchmarks

### **Test Categories**
1. **Model Tests**: Data model validation and business logic
2. **Service Tests**: Authentication, export, and MDM services
3. **UI Tests**: User interface functionality and accessibility
4. **Integration Tests**: End-to-end workflow validation
5. **Performance Tests**: Load handling and responsiveness

### **Running Tests**
```bash
# Run all tests
xcodebuild test -scheme MacForge -destination 'platform=macOS'

# Run specific test suite
xcodebuild test -scheme MacForge -destination 'platform=macOS' -only-testing:MacForgeTests

# Run UI tests
xcodebuild test -scheme MacForge -destination 'platform=macOS' -only-testing:MacForgeUITests
```

### **Test Documentation**
- **[Test Plan](MacForgeTests/TestPlan.md)**: Comprehensive testing strategy
- **[Test Files](MacForgeTests/)**: Unit test implementations
- **[UI Tests](MacForgeUITests/)**: User interface test suite

## Improvement Roadmap

### **Phase 1: Stabilization (COMPLETED ✅)**
1. **✅ Remove iOS Support**: Eliminated cross-platform complexity
2. **✅ Complete JAMF Integration**: Focused on JAMF Pro features
3. **✅ Implement One Additional Tool**: Package Smelting now functional
4. **✅ Simplify State Management**: Reduced NotificationCenter usage
5. **✅ Improve File Organization**: Complete feature-based structure implemented

### **Phase 2: Enhancement (Current Priority)**
1. **UI/UX Improvements**: Native macOS patterns and better accessibility
2. **Error Handling**: Comprehensive error messages and recovery
3. **Testing**: Unit and UI test coverage
4. **Performance**: Optimize memory usage and responsiveness
5. **Complete Package Smelting**: Add MDM upload functionality

### **Phase 3: Expansion**
1. **Additional MDM Support**: Implement Intune, Kandji, Mosyle
2. **Tool Completion**: Finish Package Smelting, Device Foundry, Blueprint Builder
3. **Advanced Features**: Template system, bulk operations
4. **Performance Optimization**: Advanced caching and optimization

### **Technical Debt Reduction**
- **Remove Unused Code**: Clean up placeholder implementations
- **Consolidate Services**: Reduce service layer complexity
- **Standardize UI**: Consistent spacing, sizing, and patterns
- **Documentation**: Complete API and architecture documentation

## Getting Started

### **Prerequisites**
- macOS 12.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### **Development Setup**
1. Clone the repository
2. Open `MacForge.xcodeproj` in Xcode
3. Build and run the project
4. Follow the setup guide for JAMF Pro integration

### **First Steps**
1. **Explore the Interface**: Familiarize yourself with the LCARS theme
2. **Try Profile Builder**: Create a simple PPPC profile
3. **Test JAMF Integration**: Connect to a JAMF Pro instance
4. **Review the Code**: Understand the MVVM architecture

### **For Contributors**
- **Check Contributor_WIKI.md**: Detailed current status, known issues, and development guidelines
- **Review TestPlan.md**: Comprehensive testing strategy and requirements
- **Follow Development Guidelines**: Code standards and architecture patterns

## Troubleshooting

### **Common Issues**
- **Build Errors**: Ensure Xcode and Swift versions are compatible
- **JAMF Connection**: Verify server URL and credentials
- **Profile Export**: Check file permissions and export location
- **UI Rendering**: Verify theme assets are properly included

### **Debug Tools**
- **JamfDebugView**: Built-in debugging interface for JAMF operations
- **Console Logs**: Check Xcode console for detailed error messages
- **Network Inspector**: Monitor API calls and responses

### **Getting Help**
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Check this wiki for detailed information
- **Community**: Join discussions in the project repository

---

**Last Updated**: August 26, 2025  
**Version**: 1.1.0 (Beta)  
**Status**: Phase 2 Active - Core Features Stable, Enhancement in Progress, Testing Infrastructure Complete
