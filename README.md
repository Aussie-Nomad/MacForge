# MacForge

A professional macOS application for creating and managing configuration profiles, with specialized support for Privacy Preferences Policy Control (PPPC) and MDM integration.

## Features

- **Configuration Profile Creation**: Build custom macOS configuration profiles
- **PPPC Management**: Specialized support for Privacy Preferences Policy Control
- **MDM Integration**: Seamless integration with Mobile Device Management systems
- **User-Friendly Interface**: Intuitive macOS-native interface
- **Security Focused**: Built with macOS security best practices

## Documentation

For comprehensive documentation including features, architecture, and development guides, see our [Wiki](WIKI.md) or visit the [GitHub Wiki](../../wiki).

### Quick Links
- [Features Overview](WIKI.md#current-features)
- [PPPC Editor Guide](WIKI.md#pppc-editor)
- [MDM Integration](WIKI.md#mdm-integration)
- [Getting Started](WIKI.md#getting-started)
- [Technical Architecture](WIKI.md#technical-architecture)
- [Future Roadmap](WIKI.md#future-roadmap)

## Requirements

- **macOS**: 12.0 (Monterey) or later
- **Xcode**: 14.0 or later (for building from source)
- **Swift**: 5.7 or later

## Installation

### For Users
1. Download the latest release from [Releases](../../releases)
2. Open the `.dmg` file
3. Drag MacForge to your Applications folder
4. Launch MacForge from Applications

### For Developers
1. Clone this repository:
   ```bash
   git clone https://github.com/Aussie-Nomad/MacForge.git
   ```
2. Open `MacForge.xcodeproj` in Xcode
3. Build and run (⌘+R)

## Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Quick Start for Contributors
1. Fork this repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and test thoroughly
4. Submit a pull request

## Development

### Project Structure
```
MacForge/
├── MacForge/           # Main application code
├── MacForgeTests/      # Unit tests
├── MacForgeUITests/    # UI tests
└── Resources/          # App resources
```

### Building
The project uses standard Xcode build processes. All dependencies are managed through Swift Package Manager.

## Bug Reports

Found a bug? Please [create an issue](../../issues/new/choose) using our bug report template.

## Feature Requests

Have an idea? We'd love to hear it! [Create a feature request](../../issues/new/choose).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for the macOS admin community
- Inspired by the need for better PPPC management tools

---

**If you find MacForge helpful, I'd love to hear from you, Dan**
