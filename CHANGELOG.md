# Changelog

All notable changes to MacForge will be documented in this file.

## [1.2.0] - 2025-08-29

### 🐛 **Bug Fixes**
- **Fixed duplicate type declarations** causing compilation errors
  - Resolved JamfAuthResult conflicts between Types.swift and JamfAuthSheet.swift
  - Resolved MDMAccount conflicts between Types.swift and UserSettings.swift
- **Fixed PPPC service property access** in BuilderModel
  - Corrected `$0.service.id` to `$0.id` for pppcServices array
- **Fixed missing protocol conformance**
  - Added Codable conformance to MDMAccount for UserDefaults persistence
  - Added missing properties (authToken, tokenExpiry, lastUsed) to MDMAccount
- **Fixed enum parameter labels**
  - Updated JamfAuthResult usage with correct labels (baseURL:, clientID:, clientSecret:)
- **Fixed ComplianceError structure**
  - Added missing `missingRequiredFields` property and updated initializer

### 🔧 **System Improvements**
- **Type system consolidation**
  - Centralized all type definitions in Types.swift
  - Eliminated duplicate declarations across multiple files
  - Improved protocol conformance and property organization
- **Build system stability**
  - All compilation errors resolved
  - Clean build with no warnings or errors
  - Project ready for CI/CD deployment

### 📚 **Documentation Updates**
- Enhanced inline code documentation
- Updated development phase summaries
- Improved contributor guidelines
- Added comprehensive changelog

### 🧪 **Testing & Quality**
- Enhanced test coverage for PPPC configurations
- Improved validation system testing
- Better error handling test scenarios

---

## [1.1.0] - 2025-08-26

### ✨ **New Features**
- Enhanced payload configuration interfaces
- Comprehensive profile validation system
- Template management system
- LCARS theme with accessibility improvements

### 🔧 **Improvements**
- FileVault, Gatekeeper, WiFi, and VPN configuration enhancements
- Profile export and validation services
- MDM integration framework
- UI/UX refinements

---

## [1.0.0] - 2025-08-21

### 🎉 **Initial Release**
- Core PPPC profile creation functionality
- Basic MDM integration
- Dual theme system (Default + LCARS)
- Application drop zone and bundle ID extraction
- Template system foundation
