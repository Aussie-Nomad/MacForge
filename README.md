# MacForge Wiki

**MacForge** is a macOS application for creating and managing configuration profiles, with specialized support for Privacy Preferences Policy Control (PPPC) and MDM integration.

## Table of Contents

- [Overview](#overview)
- [Current Features](#current-features)
- [PPPC Editor](#pppc-editor)
- [MDM Integration](#mdm-integration)
- [Authentication Methods](#authentication-methods)
- [Profile Management](#profile-management)
- [User Interface](#user-interface)
- [Technical Architecture](#technical-architecture)
- [Future Roadmap](#future-roadmap)
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

## Current Features

### ✅ Implemented Features

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
   - Configuration summary
   - Export options
   - MDM submission

#### Visual Design
- **Progress Indicators**: Step circles with completion checkmarks
- **Smart Navigation**: Auto-advance on completion
- **Error Feedback**: Inline error messages with clear guidance
- **Responsive Layout**: Adapts to different window sizes

## PPPC Editor

### App Target Drop Zone
The PPPC editor features a sophisticated drag-and-drop interface:

```swift
// Automatic extraction on app drop
func applyApp(at url: URL) {
    // Extract bundle identifier
    if let bundle = Bundle(url: url) {
        bundleID = bundle.bundleIdentifier ?? ""
    }
    
    // Extract code requirement
    if let req = designatedRequirement(for: url) {
        codeRequirement = req
    }
    
    // Auto-advance wizard
    model.wizardStep = max(model.wizardStep, 2)
}
```

### Permission Configuration
Each service can be configured with granular control:

- **Standard Permissions**: Camera, Microphone, Full Disk Access
- **Advanced Options**: 
  - Apple Events with receiver configuration
  - Screen Recording with capture type selection
  - Folder-specific permissions

### Code Requirements
MacForge automatically extracts designated requirements using the Security framework:

```swift
private func designatedRequirement(for url: URL) -> String? {
    var staticCode: SecStaticCode?
    let status = SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode)
    guard status == errSecSuccess, let code = staticCode else { return nil }
    
    var requirement: SecRequirement?
    let reqStatus = SecCodeCopyDesignatedRequirement(code, [], &requirement)
    guard reqStatus == errSecSuccess, let req = requirement else { return nil }
    
    var reqString: CFString?
    let stringStatus = SecRequirementCopyString(req, [], &reqString)
    guard stringStatus == errSecSuccess, let string = reqString else { return nil }
    
    return string as String
}
```

## MDM Integration

### Jamf Pro Implementation

#### Authentication Flow
```swift
// OAuth Authentication
public func authenticateClientID(clientID: String, clientSecret: String) async throws {
    let endpoints = ["api/oauth/token", "api/v1/oauth/token"]
    
    for endpoint in endpoints {
        // Try each endpoint with proper error handling
        // Fallback to next endpoint on failure
    }
}

// Basic Authentication
public func authenticatePassword(username: String, password: String) async throws {
    let endpoint = "api/v1/auth/token"
    // Convert Basic auth to Bearer token
}
```

#### Profile Management
```swift
// Automatic create or update
public func uploadOrUpdateComputerProfileXML(name: String, xmlPlist: Data) async throws {
    do {
        try await uploadComputerProfileXML(name: name, xmlPlist: xmlPlist)
    } catch JamfError.http(let code, _) where code == 409 {
        // Profile exists, update it
        try await updateComputerProfileXMLByName(name: name, xmlPlist: xmlPlist)
    }
}
```

### Connection Validation
Before submission, MacForge validates the connection:
- Network connectivity check
- Authentication validation
- Permission verification

## Authentication Methods

### Jamf Pro

#### Method 1: OAuth (Recommended)
- **Client ID**: Your Jamf Pro API client identifier
- **Client Secret**: Corresponding secret key
- **Endpoints**: Automatically tries both `api/oauth/token` and `api/v1/oauth/token`
- **Security**: Bearer token with automatic refresh

#### Method 2: Basic Authentication
- **Username**: Jamf Pro admin username
- **Password**: Corresponding password
- **Conversion**: Automatically converts to Bearer token
- **Scope**: Full API access based on user permissions

### Security Features
- **Network Entitlements**: Proper sandboxing with network client access
- **Token Management**: Secure token storage and automatic refresh
- **Error Recovery**: Graceful handling of authentication failures

## Profile Management

### Export Options

#### Local Export
```swift
func saveProfileToDownloads() {
    do {
        let data = try exportMobileConfig()
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let filename = "\(settings.name).mobileconfig"
        let fileURL = downloadsURL.appendingPathComponent(filename)
        try data.write(to: fileURL)
    } catch {
        // Handle export errors
    }
}
```

#### MDM Submission
Direct submission to MDM with:
- Automatic conflict resolution
- Progress feedback
- Error reporting
- Retry mechanisms

### Profile Structure
Generated profiles follow Apple's configuration profile format:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<os_x_configuration_profile>
  <general>
    <name>Profile Name</name>
    <distribution_method>Install Automatically</distribution_method>
    <payloads>BASE64_ENCODED_PLIST</payloads>
  </general>
</os_x_configuration_profile>
```

## User Interface

### Design Philosophy
MacForge's UI is inspired by the LCARS (Library Computer Access/Retrieval System) design language, featuring:

- **Geometric Shapes**: Rounded rectangles and pill-shaped elements
- **Color Hierarchy**: Amber for headers, orange for accents, green for success
- **Typography**: Clear, sans-serif fonts with appropriate weights
- **Spacing**: Generous whitespace for clarity

### Component Library

#### Core Components
- `LcarsHeader`: Styled headers with consistent theming
- `ThemedField`: Input fields with validation and placeholder support
- `WizardHeader`: Progress indicator with step circles
- `PermissionCard`: Individual permission configuration cards

#### Interactive Elements
- `AppTargetDropView`: Drag-and-drop zone for applications
- `PPPCServicesEditor`: Grid-based permission configuration
- `JamfAuthSheet`: Modal authentication interface

### Responsive Design
The interface adapts to different window sizes:
- **Minimum Width**: 800px for comfortable editing
- **Scalable Layout**: Components resize appropriately
- **Sidebar Behavior**: Collapsible on smaller screens

## Technical Architecture

### SwiftUI Framework
MacForge is built entirely in SwiftUI, leveraging:
- **Declarative UI**: Reactive interface updates
- **State Management**: `@ObservedObject` and `@State` for data binding
- **Navigation**: `NavigationStack` for structured flow
- **Modality**: Sheet presentations for authentication and settings

### Data Models

#### Core Models
```swift
// Main application state
class BuilderModel: ObservableObject {
    @Published var settings: ProfileSettings
    @Published var dropped: [Payload]
    @Published var pppcServices: [PPPCService]
    @Published var wizardStep: Int = 1
}

// Individual permission service
struct PPPCService {
    let id: String
    let name: String
    var decision: AuthDecision = .ask
    var receiverBundleID: String?
    var screenCaptureType: String?
}
```

#### Profile Generation
```swift
func exportMobileConfig() throws -> Data {
    let payloadDicts: [[String: Any]] = dropped.map { payload in
        // Convert payload to dictionary format
        // Handle PPPC-specific configurations
        // Generate proper XML structure
    }
    
    return try PropertyListSerialization.data(
        fromPropertyList: profile, 
        format: .xml, 
        options: 0
    )
}
```

### Security Framework Integration
MacForge uses Apple's Security framework for:
- Code signature validation
- Requirement extraction
- Bundle analysis

### Network Layer
Custom HTTP client with:
- Automatic retry logic
- Connection pooling
- Error categorization
- Debug logging

## Future Roadmap

### 🎯 High Priority Features

#### Enhanced MDM Support
- **Microsoft Intune Integration**
  - Graph API authentication
  - Policy assignment
  - Compliance reporting
  
- **Kandji API Integration**
  - Tenant-specific authentication
  - Blueprint integration
  - Device targeting

- **Mosyle Business Integration**
  - Access token authentication
  - Profile distribution
  - Device management

#### Advanced PPPC Features
- **Bulk Operations**
  - Multi-app configuration
  - Template-based permissions
  - Batch export/import

- **Permission Templates**
  - Pre-configured permission sets
  - Industry-specific templates
  - Custom template creation

#### Configuration Profile Types
- **WiFi Profiles**
  - Enterprise networks
  - Certificate-based authentication
  - Hidden network support

- **VPN Configurations**
  - Multiple VPN types
  - Per-app VPN
  - Always-on VPN

- **Certificate Management**
  - Root CA installation
  - User certificates
  - Device certificates

### 🔮 Medium Priority Features

#### User Experience Enhancements
- **Profile Validation**
  - Real-time syntax checking
  - Compatibility warnings
  - Best practice suggestions

- **Advanced Wizard**
  - Conditional steps
  - Smart recommendations
  - Context-aware help

- **Profile Comparison**
  - Diff visualization
  - Merge capabilities
  - Version history

#### Developer Tools
- **API Integration**
  - REST API for automation
  - Webhook support
  - CLI interface

- **Scripting Support**
  - JavaScript automation
  - Custom transformations
  - Bulk operations

#### Enterprise Features
- **Multi-tenant Support**
  - Organization isolation
  - Role-based access
  - Audit logging

- **Advanced Authentication**
  - SAML integration
  - Active Directory
  - Certificate-based auth

### 🌟 Long-term Vision

#### AI-Powered Features
- **Smart Recommendations**
  - App-specific permission suggestions
  - Security best practices
  - Compliance guidance

- **Automated Conflict Resolution**
  - Intelligent merging
  - Policy optimization
  - Risk assessment

#### Cross-Platform Support
- **iOS Profile Support**
  - Mobile device management
  - App-specific configurations
  - Device restrictions

- **Universal Profiles**
  - Multi-platform targeting
  - Conditional deployment
  - Platform-specific overrides

#### Advanced Analytics
- **Usage Tracking**
  - Profile deployment metrics
  - Success/failure rates
  - Performance monitoring

- **Security Insights**
  - Permission usage analysis
  - Risk assessment
  - Compliance reporting

## Getting Started

### Installation Requirements
- **macOS**: 15.5 or later
- **Xcode**: 16.0 or later (for development)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 2GB available space

### Building from Source
```bash
# Clone the repository
git clone <repository-url>
cd MacForge

# Open in Xcode
open MacForge.xcodeproj

# Build and run
# Select MacForge scheme and press Cmd+R
```

### First Run Setup
1. **Launch MacForge**
2. **Select Profile Builder** from the sidebar
3. **Configure MDM Connection** (optional)
4. **Start Creating Profiles** using the wizard

### Basic Workflow
1. **Add PPPC Payload**: Click "Add Privacy Permissions (PPPC)"
2. **Drop Application**: Drag .app file to the drop zone
3. **Configure Permissions**: Set Allow/Deny/Prompt for each service
4. **Review Configuration**: Check the summary
5. **Export or Submit**: Save locally or send to MDM

## Troubleshooting

### Common Issues

#### Authentication Problems
**Symptom**: "HTTP 401" or "Invalid Client" errors
**Solution**: 
- Verify MDM credentials are correct
- Check network connectivity
- Ensure proper API permissions in MDM
- Try both authentication methods (OAuth vs Basic)

#### App Drop Failures
**Symptom**: Bundle ID not extracted from dropped app
**Solution**:
- Ensure the file is a valid .app bundle
- Check app is properly signed
- Verify file system permissions
- Try manually entering bundle ID

#### Profile Export Issues
**Symptom**: Export fails or generates invalid profiles
**Solution**:
- Check all required fields are filled
- Validate profile name is unique
- Ensure proper permissions are configured
- Review error messages in detail

### Debug Information
Enable detailed logging by:
1. Building in Debug configuration
2. Monitoring Xcode console output
3. Checking system logs for Security framework errors

### Network Debugging
For MDM connection issues:
```bash
# Test connectivity
curl -v https://your-jamf-instance.com/api/v1/ping

# Verify certificates
openssl s_client -connect your-jamf-instance.com:443

# Check DNS resolution
nslookup your-jamf-instance.com
```

### Support Resources
- **Error Messages**: All errors include detailed descriptions
- **Debug Logs**: Console output provides detailed operation logs
- **Network Inspector**: Built-in request/response logging
- **Validation**: Real-time feedback on configuration issues

### Performance Optimization
- **Large App Bundles**: Code requirement extraction may take time
- **Network Timeouts**: Increase timeout for slow connections
- **Memory Usage**: Large profiles may require more RAM

---

## Contributing

### Development Setup
1. Fork the repository
2. Create feature branch
3. Make changes with proper testing
4. Submit pull request with detailed description

### Code Style
- Follow Swift naming conventions
- Use SwiftUI best practices
- Include documentation for public APIs
- Add unit tests for new features

### Testing
- Manual testing with real MDM instances
- Unit tests for core functionality
- UI tests for critical workflows
- Performance testing for large profiles

---

**Last Updated**: August 2025  
**Version**: 1.0.0  
**Platform**: macOS 15.5+
