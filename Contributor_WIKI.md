# MacForge Contributor WIKI

## 🚀 **Project Overview**

MacForge is a comprehensive macOS MDM toolkit for enterprise administrators. This document focuses on development status, known issues, and contributor guidelines. For detailed feature information, see [FEATURE_WIKI.md](FEATURE_WIKI.md).

## 📋 **Current Status: FULLY OPERATIONAL ✅**

**Version**: 2.1.1 (Beta) - "Meet the Blacksmith"  
**Build Date**: January 15, 2025  
**Platform**: macOS 12+ (Sonoma, Ventura, Monterey)  
**Swift Version**: Swift 6 compatible  
**Build Status**: 🟢 **SUCCESSFUL** - All compilation errors resolved

### **Development Phases**

#### **Phase 1: Foundation & Core Features** ✅ COMPLETE
- Profile Workbench (PPPC) with comprehensive PPPC support
- Application drop zone and bundle ID extraction
- Template system (Security Baseline, Network, Antivirus, Development Tools)
- Theme switching (Default + LCARS) with accessibility
- Profile validation and export services
- PPPC configuration persistence and template application
- Enhanced payload configuration (FileVault, Gatekeeper, WiFi, VPN)
- MDM integration framework (JAMF Pro, Intune, Kandji, Mosyle)
- Account settings and MDM account management
- Downloads folder system with organized structure
- **NEW: Log Burner Tool** - AI-powered log analysis with drag & drop interface
- **NEW: Smart Pattern Recognition** - Automatic error, warning, and security event detection
- **NEW: Split-view Results** - Raw log sidebar with interactive line highlighting
- **NEW: Professional UI** - Color-coded statistics and visual feedback
- **NEW: Package Casting Tool** - JAMF Composer-inspired package management and repackaging
- **NEW: Script Injection** - Add custom scripts to fix poorly built applications
- **NEW: Code Signing** - Apple Developer ID certificate integration
- **NEW: PPPC Auto-Generation** - Automatic privacy profile creation for MDM deployment
- **NEW: AI Tool Accounts** - Secure credential management for AI providers (OpenAI, Anthropic, Ollama, Custom)
- **NEW: Script Smelter Enhancement** - AI-assisted script generation with CLI tools and automation features
- **NEW: Ollama Integration** - Local AI model support for testing and development
- **NEW: The Blacksmith Tool** - Conversational AI wizard for MDM setup and management with Yorkshire personality
- **NEW: Package Management Tools** - Six specialized tools for comprehensive package lifecycle management
- **NEW: AI-Powered Package Analysis** - Intelligent package analysis with security assessment and deployment recommendations
- **NEW: Template Systems** - Pre-built package templates and configurations for rapid deployment
- **NEW: Advanced Repackaging** - Enhanced package modification with script injection and code signing
- **NEW: Blacksmith Package Wizard** - Complete package creation workflow with spinning hammer animation

#### **Phase 2: Improvements & Security Hardening** ✅ COMPLETE
**Recently Completed:**
- **Package Management Tools Suite** - All six specialized tools fully functional
- **Template Systems Implementation** - Pre-built package templates and configurations
- **Advanced Repackaging Tool** - Enhanced package modification with script injection and code signing
- **Blacksmith Package Wizard** - Complete package creation workflow with spinning hammer animation
- **AI-Powered Package Analysis** - Intelligent package analysis with security assessment
- **Yorkshire Personality Integration** - Authentic regional dialect and MDM expertise
- **Documentation Updates** - Complete changelog and feature documentation

**Next Focus:**
- **Performance Optimization** - Large file handling and UI responsiveness improvements
- **Enhanced Error Handling** - Better user feedback and error recovery
- **Log Burner Export Reports** - PDF/HTML report generation
- **Log Burner File Picker** - Browse files functionality

**Planned Improvements:**
- Complete MDM integration features
- Enhanced PPPC configuration interface
- Advanced template service configuration
- **Log Burner AI Integration** - Use saved AI accounts for enhanced log analysis
- **Script Builder Integration** - Seamless use of saved AI accounts
- Profile validation and preview improvements
- UI layout refinements and accessibility
- Comprehensive testing coverage

#### **Phase 3: MDM Integration Expansion** 📋 PLANNED
- **Microsoft Intune**: Full configuration profile support
- **Kandji**: Device management and policy deployment
- **Mosyle**: Business and education features
- **VMware Workspace ONE**: Enterprise integration
- **Fleetsmith**: Apple-focused management
- **Custom MDM**: Plugin architecture for custom solutions

#### **Phase 4: Web-Based Version** 🌐 FUTURE
- Browser-based profile builder
- Cross-platform accessibility
- Team collaboration features
- Cloud-based template sharing
- API for third-party integrations
- Mobile-responsive design

#### **Phase 5: Open Source MDM Platform** 🚀 LONG TERM
- Full-featured, open-source MDM solution
- Competitive with commercial platforms
- Community-driven development
- Enterprise-grade features
- Cross-platform device support  

## ✅ **What's Working**

### **Core Application**
- ✅ Application launches successfully
- ✅ Main window and navigation work
- ✅ Theme system (Default + LCARS) functional
- ✅ Theme switching and persistence working
- ✅ Basic UI layout and responsiveness

### **Core Tools Status**
- ✅ **Profile Workbench (PPPC)** - Complete with wizard interface and MDM integration
- ✅ **Package Casting** - Complete with JAMF Composer-inspired workflow
- ✅ **Log Burner** - Complete with AI-powered analysis and split-view results
- ✅ **Device Foundry** - Complete with serial number lookup and device database
- ✅ **Script Smelter** - Complete with AI provider integration and CLI tools
- ✅ **The Blacksmith** - Complete with conversational AI wizard and MDM setup
- ✅ **DDM Blueprints** - Complete with comprehensive device configuration and system management

### **Infrastructure**
- ✅ **Authentication & MDM Integration** - JAMF Pro, Intune, Kandji, Mosyle support
- ✅ **Theme System** - Default + LCARS themes with accessibility
- ✅ **Testing Framework** - Unit and UI tests with comprehensive coverage

## ❌ **What's NOT Working**

### **Minor Issues (Non-Critical)**
- ⚠️ **Log Burner Export Reports**: PDF/HTML report generation needs implementation
- ⚠️ **Log Burner File Picker**: Browse files functionality needs implementation
- ⚠️ **Performance Optimization**: Large file handling could be improved
- ⚠️ **Enhanced Error Handling**: Some error messages could be more specific

### **Future Enhancements**
- 📋 **Advanced MDM Integration**: Additional MDM platforms beyond current four
- 📋 **Profile Validation**: Enhanced validation before export
- 📋 **Accessibility**: Additional accessibility features for screen readers
- 📋 **Performance**: Background processing for large operations

### **Resolved Issues (v2.1.1)**
- ✅ **Package Management Tools**: All six specialized tools fully functional
- ✅ **Template Systems**: Complete implementation with categorized templates
- ✅ **Advanced Repackaging**: Full script injection and code signing capabilities
- ✅ **Blacksmith Package Wizard**: Complete workflow with spinning hammer animation
- ✅ **Compilation Errors**: All duplicate struct declarations and type conflicts resolved
- ✅ **UI Layout Issues**: All major layout and navigation problems fixed

## 🐛 **Known Bugs & Issues**

### **✅ RESOLVED (v1.2.0)**
1. **PPPC Configuration Not Saving**: ✅ Fixed - PPPC configurations now persist between steps
2. **Template System Incomplete**: ✅ Fixed - Templates now properly configure services
3. **Step Navigation Issues**: ✅ Fixed - Wizard step progression logic improved
4. **Profile Export Validation**: ✅ Fixed - Comprehensive validation system implemented
5. **Compilation Errors**: ✅ Fixed - All duplicate types and property access issues resolved

### **🔄 In Progress**
1. **Log Burner Export Functionality**: Implementing report export features
2. **File Picker Integration**: Adding browse files functionality to Log Burner
3. **Performance Optimization**: Large log file handling improvements
4. **Accessibility Enhancement**: Adding keyboard navigation and screen reader support

### **Medium Priority**
1. **Log Burner File Picker**: Browse files functionality needs implementation
2. **Log Burner Export Reports**: PDF/HTML report generation
3. **UI Layout Cramping**: Some sections feel too dense
4. **Theme Switching**: LCARS theme needs refinement for better contrast
5. **Error Messages**: Generic error messages without specific guidance

### **Low Priority**
1. **Accessibility Labels**: Some UI elements missing proper labels
2. **Keyboard Navigation**: Limited keyboard-only operation support
3. **Documentation**: Inline code documentation needs expansion
4. **Logging**: Limited debugging and logging capabilities

## 🔧 **Technical Debt & Architecture Issues**

### **Code Structure**
- **BuilderModel Complexity**: ✅ Improved - PPPC configuration management separated and organized
- **Service Dependencies**: ✅ Improved - Type system consolidated and dependencies clarified
- **Error Handling**: ✅ Improved - Consistent error types and validation patterns implemented
- **Type System**: ✅ Improved - Centralized type definitions with proper protocol conformance
- **Async/Await**: Some async operations not properly handled

### **Data Models**
- **PPPC Service Management**: Services are scattered across multiple files
- **Profile Validation**: Validation logic is incomplete and scattered
- **Template System**: Template application logic needs refactoring
- **State Management**: Some state updates not properly synchronized

### **Testing**
- **Test Coverage**: Some critical paths lack test coverage
- **Mock Services**: Mock implementations need improvement
- **Integration Tests**: Limited end-to-end workflow testing
- **Performance Tests**: No performance benchmarking

## 🚧 **In Progress / Next Steps**

### **Recently Completed (v2.1.1)**
1. ✅ **Package Management Tools Suite**: All six specialized tools fully functional
2. ✅ **Template Systems Implementation**: Pre-built package templates and configurations
3. ✅ **Advanced Repackaging Tool**: Enhanced package modification with script injection and code signing
4. ✅ **Blacksmith Package Wizard**: Complete package creation workflow with spinning hammer animation
5. ✅ **AI-Powered Package Analysis**: Intelligent package analysis with security assessment
6. ✅ **Yorkshire Personality Integration**: Authentic regional dialect and MDM expertise
7. ✅ **Documentation Updates**: Complete changelog and feature documentation

### **Immediate (Next Week)**
1. **Performance Optimization**: Large file handling and UI responsiveness improvements
2. **Enhanced Error Handling**: Better user feedback and error recovery
3. **Log Burner Export Reports**: Implement PDF/HTML report generation
4. **Log Burner File Picker**: Add browse files functionality

### **Short Term (Next 2 Weeks)**
1. **Advanced MDM Integration**: Additional MDM platforms beyond current four
2. **Profile Validation**: Enhanced validation before export
3. **Accessibility**: Additional accessibility features for screen readers
4. **Testing**: Expand test coverage and fix failing tests

### **Medium Term (Next Month)**
1. **Background Processing**: Optimize large operations with background processing
2. **Advanced Template System**: More sophisticated template management
3. **Code Refactoring**: Split BuilderModel into smaller, focused classes
4. **Plugin Architecture**: Extensible system for custom integrations

## 🏗️ **Architecture Overview**

### **Current Architecture**
```
MacForgeApp (Entry Point)
├── ContentView (Main Container)
├── GlobalSidebar (MDM Selection)
├── ToolHost (Tool Router)
    └── Features/
        ├── ProfileBuilder/
        │   ├── ProfileBuilderHostView
        │   ├── ProfileSidebar
        │   ├── ProfileCenterPane
        │   └── ProfileDetailPane
        ├── PPPC/
        │   └── PPPCEditor
        └── Tools/
            ├── PackageSmelting
            ├── DeviceFoundry
            ├── LogBurner (NEW)
            └── BlueprintBuilder
```

### **Data Flow**
1. **User selects MDM** → Authentication service initialized
2. **User chooses tool** → Tool-specific interface loads
3. **PPPC Profile Creator workflow**:
   - Step 1: Select payloads and target application
   - Step 2: Configure PPPC permissions
   - Step 3: Review and export profile
4. **Log Burner workflow**:
   - Drag & drop log file → Visual feedback and file processing
   - AI analysis → Pattern recognition and categorization
   - Split-view results → Raw log sidebar + analysis main area
   - Interactive exploration → Click errors/warnings to highlight lines
5. **Profile submission** → MDM authentication and upload

### **Key Components**
- **BuilderModel**: Core data model and business logic
- **ProfileBuilderViewModel**: UI state management
- **JAMFAuthenticationService**: MDM authentication
- **ProfileExportService**: Profile generation and export
- **LogAnalysisService**: AI-powered log analysis engine
- **ThemeManager**: UI theme management

## 🧪 **Testing Strategy**

### **Test Coverage Goals**
- **Unit Tests**: >90% line coverage
- **Integration Tests**: All major workflows
- **UI Tests**: Critical user journeys
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

## 🎯 **Development Guidelines**

### **Code Style**
- Follow Apple's Swift API Design Guidelines
- Use SwiftUI for all new UI components
- Implement proper error handling with custom error types
- Use async/await for asynchronous operations
- Follow MVVM architecture pattern

### **Testing Requirements**
- Write tests for all new functionality
- Maintain test coverage above 90%
- Use descriptive test names and assertions
- Mock external dependencies appropriately
- Test both success and failure scenarios

### **Documentation Standards**
- Document all public APIs and methods
- Include usage examples in documentation
- Update this WIKI when adding new features
- Maintain inline code comments for complex logic
- Document configuration requirements and dependencies

### **Performance Requirements**
- App launch time: <2 seconds
- PPPC Profile Creator load: <1 second
- Theme switching: <100ms
- PPPC configuration: <500ms
- Large profile handling: <5 seconds

## 🚨 **Critical Paths & Dependencies**

### **Must Work for Basic Functionality**
1. **Application Launch**: Basic app startup and navigation
2. **PPPC Profile Creator**: Core profile creation workflow
3. **PPPC Configuration**: Basic permission setting
4. **Profile Export**: .mobileconfig file generation
5. **MDM Authentication**: Basic connection and auth

### **Dependencies**
- **macOS 12+**: Minimum supported platform
- **Xcode 15+**: Development environment
- **Swift 6**: Language compatibility
- **JAMF Pro**: Primary MDM target (others planned)

### **External References**
- [Apple Device Management](https://github.com/apple/device-management)
- [NanoMDM](https://github.com/micromdm/nanomdm)
- [Jamf Pro SDK Python](https://github.com/macadmins/jamf-pro-sdk-python)
- [PPPC Utility](https://github.com/jamf/PPPC-Utility)

## 📊 **Quality Metrics**

### **Code Quality**
- **Compilation**: ✅ No compilation errors
- **Linting**: ⚠️ Some warnings to address
- **Documentation**: ⚠️ Partial coverage
- **Test Coverage**: ⚠️ Incomplete

### **User Experience**
- **Functionality**: ⚠️ Core features working, details incomplete
- **Performance**: ✅ Meets basic requirements
- **Accessibility**: ⚠️ Needs improvement
- **Error Handling**: ❌ Limited user feedback

### **Stability**
- **Crash Rate**: ✅ No known crashes
- **Memory Usage**: ✅ Stable
- **Network Handling**: ⚠️ Basic error handling
- **Data Persistence**: ✅ Working

## 🔮 **Roadmap & Future Plans**

### **Phase 1: Stabilization (Current)**
- Fix critical PPPC configuration issues
- Complete template system implementation
- Improve error handling and user feedback
- Expand test coverage

### **Phase 2: Enhancement (Next Month)**
- Complete MDM integration
- Add profile validation and preview
- Implement advanced PPPC features
- Improve accessibility compliance

### **Phase 3: Expansion (Next Quarter)**
- Add support for other MDM platforms
- Implement advanced profile templates
- Add bulk operations and automation
- Create plugin system for extensions

### **Phase 4: Enterprise Features (Next 6 Months)**
- Multi-tenant support
- Advanced reporting and analytics
- Integration with enterprise tools
- Compliance and audit features

## 🤝 **Contributing**

### **Getting Started**
1. Fork the repository
2. Create a feature branch
3. Follow the development guidelines
4. Write tests for new functionality
5. Submit a pull request with detailed description

### **Areas Needing Help**
1. **PPPC Configuration UI**: Make the detailed interface functional
2. **Template System**: Complete the template application logic
3. **Error Handling**: Improve user feedback and recovery
4. **Testing**: Expand test coverage and fix failing tests
5. **Documentation**: Complete inline code documentation

### **Communication**
- **Issues**: Use GitHub issues for bug reports and feature requests
- **Discussions**: Use GitHub discussions for questions and ideas
- **Pull Requests**: Include detailed descriptions and testing notes
- **Code Review**: All changes require review before merging

## 📝 **Changelog**

### **Version 2.1.1 (Beta) - "Meet the Blacksmith" - January 15, 2025**
- ✅ **NEW: Template Systems Tool** - Pre-built package templates and configurations
- ✅ **NEW: Advanced Repackaging Tool** - Enhanced package modification with script injection and code signing
- ✅ **NEW: Blacksmith Package Wizard** - Complete package creation workflow with spinning hammer animation
- ✅ **NEW: Package Template Library** - Comprehensive template management system
- ✅ **NEW: Multi-Step Repackaging** - 4-tab interface for comprehensive package modification
- ✅ **NEW: Script Management** - Add, edit, and delete pre-install, post-install, and uninstall scripts
- ✅ **NEW: Code Signing Options** - Re-sign packages with different certificate types
- ✅ **NEW: Template Categories** - Applications, Frameworks, System Extensions, Preference Panes, Kernel Extensions, Custom
- ✅ **NEW: Package Creation Service** - Template-based package creation with proper error handling
- ✅ **NEW: Yorkshire Personality** - Authentic regional dialect and MDM expertise in The Blacksmith
- ✅ **COMPLETE: All Package Management Tools** - Six specialized tools fully functional
- ✅ **COMPLETE: Package Casting Enhancement** - Superior alternative to JAMF Admin's Composer and MUT

### **Version 1.3.0 (Beta) - January 15, 2025**
- ✅ **NEW: Log Burner Tool** - AI-powered log analysis with drag & drop interface
- ✅ **NEW: Split-view Results** - Raw log sidebar with interactive line highlighting
- ✅ **NEW: Smart Pattern Recognition** - Automatic error, warning, and security event detection
- ✅ **NEW: Professional UI** - Color-coded statistics, syntax highlighting, and visual feedback
- ✅ **NEW: Interactive Analysis** - Click errors/warnings to highlight corresponding log lines
- ✅ **NEW: Haptic Feedback** - Tactile confirmation for file uploads
- ✅ **NEW: Export Functionality** - Report generation capabilities
- ⚠️ Log Burner file picker needs implementation
- ⚠️ Log Burner export reports need PDF/HTML generation

### **Version 1.2.0 (Beta) - August 29, 2025**
- ✅ Fixed main actor isolation issues in ThemeManager
- ✅ Implemented comprehensive PPPC data models
- ✅ Added application drop zone for PPPC configuration
- ✅ Created comprehensive testing infrastructure
- ✅ Fixed sidebar width proportions
- ✅ Implemented functional template system
- ✅ Added working download functionality
- ⚠️ PPPC configuration UI needs completion
- ⚠️ Template service configuration incomplete

### **Version 1.0.0 (Alpha) - August 14, 2025**
- ✅ Basic application structure
- ✅ PPPC Profile Creator tool framework
- ✅ Basic PPPC payload support
- ✅ Theme system foundation
- ❌ Limited functionality
- ❌ No testing infrastructure

## 🏗️ **Technical Architecture**

### **Current Stack**
- **Frontend**: SwiftUI (macOS native)
- **Architecture**: MVVM with ObservableObject
- **Storage**: UserDefaults + File system
- **Networking**: URLSession with async/await
- **Themes**: LCARS + Default with accessibility

### **Planned Enhancements**
- **Database**: Core Data for complex data models
- **Networking**: Advanced caching and offline support
- **Security**: Keychain integration and encryption
- **Performance**: Background processing and optimization

### **AI Tool Accounts Implementation**

#### **Core Components**
- **AIAccount Model** (`Types.swift`) - Codable struct with provider-specific configuration
- **UserSettings Integration** - Secure keychain storage with GDPR compliance
- **AIService** - Unified interface for OpenAI, Anthropic, Ollama, and custom endpoints

### **Package Management Tools Implementation**

#### **Core Architecture**
- **PackageCastingView** - Main container with drag-and-drop interface
- **ToolSummaryButton** - Reusable component for tool navigation
- **Six Specialized Tools**:
  - **New Package Creation** - Create packages from apps, DMGs, or archives
  - **Package Analysis** - Enhanced analysis with AI integration
  - **Simple Package Builder** - Template-based package creation
  - **System Lifecycle Management** - Software version management
  - **Template Systems** - Pre-built package templates
  - **Advanced Repackaging** - Enhanced repackaging features

#### **AI Integration**
- **PackageAISummaryCard** - AI-powered package analysis with security assessment
- **Intelligent Recommendations** - Deployment readiness and risk assessment
- **Security Analysis** - Code signing validation and vulnerability detection

### **The Blacksmith Tool Implementation**

#### **Core Components**
- **BlacksmithView** - Main conversational interface with AI account selection
- **BlacksmithChatModel** - Chat management with Yorkshire MDM specialist personality
- **MDMSetupWizard** - 7-step guided setup process for any MDM platform
- **AI Personality System** - Custom system prompts for Yorkshire MDM expertise

#### **Features**
- **Conversational Interface** - Natural language MDM setup guidance
- **Multi-Step Wizard** - Guided setup for JAMF, Intune, Kandji, Mosyle, and custom MDMs
- **AI Account Integration** - Uses saved AI accounts for intelligent responses
- **Yorkshire Personality** - Authentic regional dialect and MDM expertise
- **Settings UI** - Tab-based account management with provider-specific forms

#### **Security Features**
- **Keychain Storage** - API keys stored securely using macOS Keychain Services
- **Account Activation** - Enable/disable accounts without deletion
- **Default Management** - Single default account with proper state handling
- **GDPR Compliance** - Full export/delete functionality for user data

#### **Provider Support**
- **OpenAI** - GPT models with API key authentication
- **Anthropic** - Claude models with API key authentication  
- **Ollama** - Local models with no authentication required
- **Custom** - Flexible endpoint configuration for any OpenAI-compatible service

#### **Testing with Ollama**
```bash
# Install Ollama
brew install ollama

# Pull recommended models
ollama pull codellama:7b-instruct
ollama pull mistral:7b-instruct

# Verify service
curl http://localhost:11434/v1/models
```

## 📝 **Development Guidelines**

### **Code Quality**
- Clean, readable code
- Comprehensive error handling
- Unit and integration tests
- Documentation for complex logic
- Performance monitoring

### **User Experience**
- Intuitive workflows
- Clear error messages
- Consistent design patterns
- Accessibility compliance
- Performance optimization

### **Testing Strategy**
- Unit tests for core logic
- Integration tests for services
- UI tests for critical workflows
- Performance testing for large profiles
- Security testing for MDM operations

### **Getting Started**

#### **Prerequisites**
- macOS 12.0+
- Xcode 15.0+
- JAMF Pro account (for testing)

#### **Setup**
1. Clone the repository
2. Open `MacForge.xcodeproj` in Xcode
3. Build and run the project
4. Configure MDM account in settings

#### **Contributing**
- Fork the repository
- Create feature branch
- Implement changes with tests
- Submit pull request
- Follow code review process

## 🔍 **Troubleshooting**

### **Common Issues**
1. **Build Failures**: Check Swift version compatibility
2. **Test Failures**: Ensure all dependencies are properly mocked
3. **UI Issues**: Verify theme system is working correctly
4. **Authentication Errors**: Check JAMF Pro server configuration

### **Debug Mode**
- Enable debug logging in development builds
- Use Xcode's debugging tools for UI issues
- Check console output for error messages
- Verify network connectivity for MDM operations

### **Performance Issues**
- Profile large applications in Instruments
- Check memory usage in Activity Monitor
- Verify file I/O operations aren't blocking
- Monitor network request performance

---

**Last Updated**: January 15, 2025  
**Maintainer**: Development Team  
**Status**: Active Development - Beta Release
