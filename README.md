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

**Version**: 1.1.0 (Beta)  
**Status**: Partially Operational - Core features working, enhancement in progress  
**Last Updated**: August 26, 2025  

### **✅ Working Features**
- Application launch and navigation
- Profile Builder with PPPC support
- Application drop zone and bundle ID extraction
- Template system (Security Baseline, Network, Antivirus)
- Theme switching (Default + LCARS)
- Profile export to .mobileconfig
- JAMF Pro authentication
- Comprehensive testing infrastructure

### **🚧 In Progress**
- Detailed PPPC configuration interface
- Template service configuration
- Profile validation and preview
- Complete MDM integration

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
