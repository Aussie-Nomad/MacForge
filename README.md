# MacForge 🚀

[![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Beta-orange.svg)](https://github.com/Aussie-Nomad/MacForge)

**MacForge** is a professional macOS application for creating and managing configuration profiles, with specialized support for **Privacy Preferences Policy Control (PPPC)** and **MDM integration**. Built with SwiftUI and following Apple's design guidelines, it provides an intuitive wizard-based interface for enterprise administrators and developers.

## 🎯 **What is MacForge?**

MacForge simplifies the creation of macOS configuration profiles, particularly focusing on PPPC profiles that manage app permissions. It provides:

- **🔐 Comprehensive PPPC Management**: 50+ privacy services across 7 categories
- **🏢 MDM Integration**: Direct submission to JAMF Pro and other MDMs
- **🎨 Modern UI**: Dual theme system (Default + LCARS Star Trek-inspired)
- **🛠️ Developer Tools**: Package analysis, device management, and automation
- **📱 Drag & Drop**: Simply drop any .app file for automatic configuration

<img width="3360" height="2226" alt="Screenshot 2025-08-28 at 21 37 20" src="https://github.com/user-attachments/assets/656e66a7-2f47-41ab-9527-a8bb3c36381f" />

## 🚀 **Quick Start**

### **For End Users**
1. **Download**: Get the latest release from [Releases](https://github.com/Aussie-Nomad/MacForge/releases)
2. **Install**: Drag MacForge to your Applications folder
3. **Launch**: Start building profiles with the intuitive wizard interface

### **For Developers**
1. **Clone**: `git clone https://github.com/Aussie-Nomad/MacForge.git`
2. **Open**: `open MacForge/DesktopApp/MacForge.xcodeproj`
3. **Build**: `xcodebuild -scheme MacForge build`
4. **Run**: Launch from Xcode or build the app

### **For Contributors**
1. **Fork** the repository
2. **Check** [Contributor WIKI](DesktopApp/MacForge/Contributor_WIKI.md) for current status
3. **Review** [Development Guidelines](DesktopApp/MacForge/WIKI.md#development-guidelines)
4. **Submit** pull requests with tests and documentation

## 📁 **Project Structure**

```
MacForge/
├── DesktopApp/              # macOS application
│   ├── MacForge/           # Main application code
│   ├── MacForgeTests/      # Unit tests
│   ├── MacForgeUITests/    # UI tests
│   └── README.md           # Desktop app documentation
├── docs/                    # Additional documentation
├── scripts/                 # Build and deployment scripts
└── README.md               # This file
```

## 📚 **Documentation**

| **Document** | **Purpose** | **Audience** |
|--------------|-------------|--------------|
| **[DesktopApp README](DesktopApp/README.md)** | Detailed app documentation | Users & Developers |
| **[Contributor WIKI](DesktopApp/MacForge/Contributor_WIKI.md)** | Development status & guidelines | Contributors |
| **[Project WIKI](DesktopApp/MacForge/WIKI.md)** | Comprehensive project docs | All users |
| **[Test Plan](DesktopApp/MacForgeTests/TestPlan.md)** | Testing strategy | Developers |

## 🏗️ **Architecture**

MacForge follows the **MVVM (Model-View-ViewModel)** architecture pattern:

- **Models**: Data structures for PPPC services and configurations
- **Views**: SwiftUI interfaces with dual theme support
- **ViewModels**: State management and business logic
- **Services**: MDM integration and profile export
- **Shared**: Common utilities and theme management

## 🧪 **Testing**

Comprehensive testing infrastructure with >90% coverage goals:

```bash
# Run all tests
xcodebuild test -scheme MacForge -destination 'platform=macOS'

# Run specific test suites
xcodebuild test -scheme MacForge -destination 'platform=macOS' -only-testing:MacForgeTests
xcodebuild test -scheme MacForge -destination 'platform=macOS' -only-testing:MacForgeUITests
```

## 📊 **Current Status**

**Version**: 1.2.0 (Beta)  
**Status**: ✅ **BUILD SUCCESSFUL** - All compilation errors resolved  
**Last Updated**: August 29, 2025  
**Build Status**: 🟢 **PASSING** - CI/CD ready  

### **✅ Working Features**
- Application launch and navigation
- PPPC Profile Creator with comprehensive PPPC support
- Application drop zone and bundle ID extraction
- Template system (Security Baseline, Network, Antivirus, Development Tools)
- Theme switching (Default + LCARS) with enhanced accessibility
- Profile validation and export services
- PPPC configuration persistence and template application
- Enhanced payload configuration (FileVault, Gatekeeper, WiFi, VPN)
- MDM integration framework (JAMF Pro, Intune, Kandji, Mosyle)

### **🔧 Recent Fixes (v1.2.0)**
- **Compilation Issues**: All duplicate type declarations resolved
- **PPPC Services**: Fixed property access patterns and persistence
- **Type System**: Added missing protocol conformance and properties
- **Build System**: Clean compilation with no errors or warnings
- **Documentation**: Enhanced inline code documentation and test coverage
- Profile export to .mobileconfig
- JAMF Pro authentication
- Comprehensive testing infrastructure
- **NEW**: Fixed theme system and component architecture
- **NEW**: Resolved all build-blocking issues

### **✨ New Features (v1.2.0)**
- **Account Settings Quick Access**: Added quick link to Account Settings from context menu
- **Keyboard Shortcuts**: New ⇧⌘A shortcut for Account Settings
- **Toolbar Integration**: Account Settings button added to main toolbar
- **Navigation Improvements**: Better access to account management features

### **🚧 In Progress**
- Enhanced PPPC configuration interface
- Advanced template service configuration
- Profile validation and preview improvements
- Complete MDM integration features
- Performance optimizations and UI refinements

### **🔧 Recently Fixed**
- ✅ **Theme System**: Resolved LCARS theme access issues
- ✅ **Component Architecture**: Fixed missing ThemeSwitcher and component imports
- ✅ **Build System**: All critical compilation errors resolved
- ✅ **CI/CD**: GitHub Actions workflow now functional

## 🔗 **Related Projects**

- **[Apple Device Management](https://github.com/apple/device-management)**: Apple's device management reference
- **[NanoMDM](https://github.com/micromdm/nanomdm)**: Minimalist Apple MDM server
- **[Jamf Pro SDK Python](https://github.com/macadmins/jamf-pro-sdk-python)**: Python client for Jamf Pro
- **[PPPC Utility](https://github.com/jamf/PPPC-Utility)**: Jamf's PPPC management tool

## 🤝 **Contributing**

We welcome contributions! See our [Contributor WIKI](DesktopApp/MacForge/Contributor_WIKI.md) for:

- Current development status and known issues
- Areas needing help and contribution guidelines
- Code standards and architecture patterns
- Testing requirements and quality metrics

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 **Support & Community**

- **GitHub Issues**: [Report bugs](https://github.com/Aussie-Nomad/MacForge/issues) and [request features](https://github.com/Aussie-Nomad/MacForge/issues/new)
- **GitHub Discussions**: [Join the conversation](https://github.com/Aussie-Nomad/MacForge/discussions)
- **Documentation**: Check our [WIKI](DesktopApp/MacForge/WIKI.md) for detailed information

---

**Made for the macOS community**

[![GitHub stars](https://img.shields.io/github/stars/Aussie-Nomad/MacForge?style=social)](https://github.com/Aussie-Nomad/MacForge/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/Aussie-Nomad/MacForge?style=social)](https://github.com/Aussie-Nomad/MacForge/network)
[![GitHub issues](https://img.shields.io/github/issues/Aussie-Nomad/MacForge)](https://github.com/Aussie-Nomad/MacForge/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/Aussie-Nomad/MacForge)](https://github.com/Aussie-Nomad/MacForge/pulls)
