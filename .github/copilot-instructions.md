# MacForge - GitHub Copilot Instructions

## Project Overview
MacForge is a professional macOS application for creating and managing configuration profiles, with specialized support for Privacy Preferences Policy Control (PPPC) and MDM integration.

## Technology Stack
- **Language**: Swift 5.7+
- **Framework**: SwiftUI
- **Platform**: macOS 12.0+
- **Build System**: Xcode 14.0+
- **Dependencies**: Swift Package Manager

## Architecture Patterns
- Follow MVVM architecture with SwiftUI
- Use `@ObservedObject` and `@StateObject` for data binding
- Implement view models as `ObservableObject` classes
- Separate business logic from UI components

## Code Style Guidelines
- Use 4 spaces for indentation (no tabs)
- Follow Apple's Swift API Design Guidelines
- Use meaningful variable and function names
- Add `// MARK:` comments to organize code sections
- Prefer explicit types over type inference for public APIs

## SwiftUI Conventions
- Use descriptive view names ending in "View" (e.g., `PPPCEditorView`)
- Extract complex views into smaller, reusable components
- Use view modifiers for consistent styling
- Implement custom view modifiers for repeated styling patterns

## Project-Specific Context

### Core Models
- `BuilderModel`: Main application state management
- `PPPCService`: Individual privacy permission services
- `ProfileSettings`: Configuration profile metadata
- `Payload`: Configuration profile payload structure

### Key Features
- PPPC profile creation with drag-and-drop app targeting
- MDM integration (currently Jamf Pro, expanding to Intune/Kandji/Mosyle)
- Privacy permission management (Camera, Microphone, Full Disk Access, etc.)
- Configuration profile export in `.mobileconfig` format

### Security Framework Usage
- Use `SecStaticCode` APIs for code signature validation
- Extract designated requirements using Security framework
- Validate bundle identifiers and code requirements

### UI Design System
- Follow LCARS-inspired design language
- Use consistent color scheme: amber headers, orange accents, green success states
- Implement themed components with `LcarsHeader`, `ThemedField` patterns
- Maintain responsive design for different window sizes

## MDM Integration Patterns
- Implement async/await for network operations
- Use proper error handling with custom error types
- Follow OAuth and Basic authentication patterns
- Implement retry logic for network failures

## Testing Guidelines
- Write unit tests for business logic
- Test configuration profile generation
- Mock MDM API responses for testing
- Test error handling scenarios

## Documentation Standards
- Use Swift documentation comments (`///`) for public APIs
- Document complex algorithms and business logic
- Maintain README and WIKI documentation
- Include code examples in documentation

## Common Patterns to Suggest
- When creating new SwiftUI views, suggest MVVM structure
- For networking code, suggest async/await with proper error handling
- For configuration profiles, suggest validation before export
- For MDM operations, suggest progress feedback and cancellation support

## Avoid These Patterns
- Don't use force unwrapping (`!`) except in truly safe scenarios
- Avoid massive view controllers/models - break into smaller components
- Don't hardcode strings - use localization or constants
- Avoid blocking UI thread with synchronous operations

## File Organization
- Place view models in `ViewModels/` directory
- Place networking code in `Services/` directory
- Place UI components in `Views/` directory
- Place model objects in `Models/` directory
