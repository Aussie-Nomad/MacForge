# MacForge Contributor WIKI

## 🚀 **Project Overview**

MacForge is a macOS application for creating and managing configuration profiles with a focus on Privacy Preferences Policy Control (PPPC) and MDM integration. The application follows Apple's design guidelines and best practices from device management repositories like [Apple's device management](https://github.com/apple/device-management) and [NanoMDM](https://github.com/micromdm/nanomdm).

## 📋 **Current Status: PARTIALLY OPERATIONAL**

**Version**: 1.1.0 (Beta)  
**Build Date**: August 26, 2025  
**Platform**: macOS 12+ (Sonoma, Ventura, Monterey)  
**Swift Version**: Swift 6 compatible  

## ✅ **What's Working**

### **Core Application**
- ✅ Application launches successfully
- ✅ Main window and navigation work
- ✅ Theme system (Default + LCARS) functional
- ✅ Theme switching and persistence working
- ✅ Basic UI layout and responsiveness

### **PPPC Profile Creator Tool**
- ✅ Tool selection and navigation
- ✅ Step-by-step wizard interface (3 steps)
- ✅ Payload selection and management
- ✅ Application drop zone for PPPC configuration
- ✅ Bundle ID extraction from dropped apps
- ✅ Template system (Security Baseline, Network, Antivirus Setup)
- ✅ PPPC payload addition and configuration
- ✅ Profile export to .mobileconfig format
- ✅ Download functionality working

### **PPPC (Privacy Preferences Policy Control)**
- ✅ Comprehensive PPPC service catalog
- ✅ Service categorization (System, Accessibility, Automation, etc.)
- ✅ PPPC configuration model with allow/deny settings
- ✅ User override and comment support
- ✅ Identifier type support (Bundle ID, Path, Code Requirement)
- ✅ PPPC configuration export and validation

### **Authentication & MDM Integration**
- ✅ JAMF Pro authentication service
- ✅ OAuth client credentials flow
- ✅ Connection validation and error handling
- ✅ Authentication state management
- ✅ Profile submission to MDM (triggered on "Submit to MDM")

### **Testing Infrastructure**
- ✅ Unit test framework setup
- ✅ UI test framework setup
- ✅ Comprehensive test coverage for core models
- ✅ Mock services for testing
- ✅ Test plan and documentation

## ❌ **What's NOT Working**

### **Critical Issues**
- ❌ **PPPC Configuration UI**: The detailed PPPC configuration interface in Step 2 is not fully functional
- ❌ **Service Configuration**: Individual PPPC service configuration (allow/deny toggles) not working
- ❌ **Template Application**: Templates add payloads but don't configure specific services
- ❌ **Profile Validation**: Profile validation before export is incomplete

### **UI/UX Issues**
- ❌ **Layout Proportions**: Some UI elements feel cramped despite recent adjustments
- ❌ **Navigation Flow**: Step progression logic needs refinement
- ❌ **Error Handling**: Limited user feedback for configuration errors
- ❌ **Accessibility**: Some accessibility features need improvement

### **MDM Integration Issues**
- ❌ **Profile Submission**: Actual MDM upload functionality incomplete
- ❌ **Error Recovery**: Limited error handling for network/MDM failures
- ❌ **Status Tracking**: No progress indication for MDM operations

## 🐛 **Known Bugs & Issues**

### **High Priority**
1. **PPPC Configuration Not Saving**: Changes to PPPC settings don't persist between steps
2. **Template System Incomplete**: Templates add payloads but don't configure services
3. **Step Navigation Issues**: Some edge cases in wizard step progression
4. **Profile Export Validation**: Missing validation for incomplete configurations

### **Medium Priority**
1. **UI Layout Cramping**: Some sections feel too dense
2. **Theme Switching**: LCARS theme needs refinement for better contrast
3. **Error Messages**: Generic error messages without specific guidance
4. **Performance**: Large profile handling could be optimized

### **Low Priority**
1. **Accessibility Labels**: Some UI elements missing proper labels
2. **Keyboard Navigation**: Limited keyboard-only operation support
3. **Documentation**: Inline code documentation needs expansion
4. **Logging**: Limited debugging and logging capabilities

## 🔧 **Technical Debt & Architecture Issues**

### **Code Structure**
- **BuilderModel Complexity**: The main model class is handling too many responsibilities
- **Service Dependencies**: Tight coupling between services and models
- **Error Handling**: Inconsistent error handling patterns across the codebase
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

### **Immediate (This Week)**
1. **Fix PPPC Configuration UI**: Make the detailed configuration interface functional
2. **Complete Template System**: Implement proper service configuration in templates
3. **Fix Step Navigation**: Resolve wizard step progression issues
4. **Profile Validation**: Implement comprehensive profile validation

### **Short Term (Next 2 Weeks)**
1. **MDM Integration**: Complete profile submission functionality
2. **Error Handling**: Improve user feedback and error recovery
3. **UI Polish**: Refine layout proportions and visual hierarchy
4. **Testing**: Expand test coverage and fix failing tests

### **Medium Term (Next Month)**
1. **Performance Optimization**: Optimize large profile handling
2. **Accessibility**: Improve accessibility compliance
3. **Documentation**: Complete inline code documentation
4. **Code Refactoring**: Split BuilderModel into smaller, focused classes

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
        └── BlueprintBuilder
```

### **Data Flow**
1. **User selects MDM** → Authentication service initialized
2. **User chooses tool** → Tool-specific interface loads
3. **PPPC Profile Creator workflow**:
   - Step 1: Select payloads and target application
   - Step 2: Configure PPPC permissions
   - Step 3: Review and export profile
4. **Profile submission** → MDM authentication and upload

### **Key Components**
- **BuilderModel**: Core data model and business logic
- **ProfileBuilderViewModel**: UI state management
- **JAMFAuthenticationService**: MDM authentication
- **ProfileExportService**: Profile generation and export
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

### **Version 1.1.0 (Beta) - August 26, 2025**
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

**Last Updated**: August 26, 2025  
**Maintainer**: Development Team  
**Status**: Active Development - Beta Release
