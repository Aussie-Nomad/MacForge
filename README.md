# MacForge

[![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Beta-orange.svg)](https://github.com/Aussie-Nomad/MacForge)

A comprehensive macOS MDM toolkit for enterprise administrators. Create configuration profiles, analyze packages, manage devices, and automate Mac administration tasks.

## What is MacForge?

MacForge is a modern macOS application that provides essential tools for Mac administrators:

- **Profile Workbench (PPPC)** - Create and manage configuration profiles with 50+ privacy services
- **Package Casting** 📦 - JAMF Composer-inspired package management and repackaging
- **Log Burner** 🔥 - AI-powered log analysis with smart pattern recognition
- **Device Foundry** - Device lookup and management tools
- **Script Smelter** 🤖 - AI-assisted script generation with OpenAI, Anthropic, and Ollama support
- **MDM Integration** - Direct submission to JAMF Pro, Intune, Kandji, and Mosyle
- **AI Tool Accounts** - Secure credential management for AI providers

<img width="3360" height="2226" alt="Screenshot 2025-08-28 at 21 37 20" src="https://github.com/user-attachments/assets/656e66a7-2f47-41ab-9527-a8bb3c36381f" />

## Quick Start

### For End Users
1. Download the latest release from [Releases](https://github.com/Aussie-Nomad/MacForge/releases)
2. Drag MacForge to your Applications folder
3. Launch and start building profiles

### For Developers
1. Clone: `git clone https://github.com/Aussie-Nomad/MacForge.git`
2. Open: `open MacForge/DesktopApp/MacForge.xcodeproj`
3. Build: `xcodebuild -scheme MacForge build`
4. Run from Xcode

### For Contributors
1. Fork the repository
2. Check [Contributor WIKI](Contributor_WIKI.md) for current status
3. Review [Feature WIKI](FEATURE_WIKI.md) for detailed information
4. Submit pull requests with tests

## AI Tool Accounts Setup

MacForge supports multiple AI providers for script generation and log analysis. Configure your AI accounts in **Settings > AI Tool Accounts**.

### Supported Providers

- **OpenAI** - GPT models (requires API key)
- **Anthropic** - Claude models (requires API key)
- **Ollama** - Local models (no API key required)
- **Custom** - Any OpenAI-compatible endpoint

### Ollama Setup (Recommended for Testing)

Ollama provides free, local AI models perfect for testing and development:

#### Install Ollama
1. **Download**: Go to [ollama.com/download](https://ollama.com/download)
2. **Install**: Download the macOS .dmg and drag the Ollama app into Applications
3. **Launch**: Launch the app once to start the background service

#### Install Models
```bash
# Install via Homebrew (alternative)
brew install ollama

# Pull recommended models
ollama pull mistral:7b-instruct
ollama pull codellama:7b-instruct

# Verify installation
curl http://localhost:11434/v1/models
```

#### Configure in MacForge
1. Open **Settings > AI Tool Accounts**
2. Click **Add Account**
3. Select **Ollama** as provider
4. Set URL to: `http://localhost:11434`
5. Choose model: `codellama:7b-instruct` or `mistral:7b-instruct`
6. Set as default for testing

### API Key Setup (OpenAI/Anthropic)

1. Get API keys from [OpenAI](https://platform.openai.com/api-keys) or [Anthropic](https://console.anthropic.com/)
2. Add account in **Settings > AI Tool Accounts**
3. Enter API key and preferred model
4. Test connectivity before setting as default

## Documentation

- **[Contributor WIKI](Contributor_WIKI.md)** - Development status, roadmap, and contributor guidelines
- **[Feature WIKI](FEATURE_WIKI.md)** - Detailed feature documentation and rationale

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/Aussie-Nomad/MacForge/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Aussie-Nomad/MacForge/discussions)