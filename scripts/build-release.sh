#!/bin/bash

# MacForge Release Build Script
# This script builds a release version of MacForge for distribution

set -e  # Exit on any error

# Configuration
PROJECT_NAME="MacForge"
SCHEME_NAME="MacForge"
CONFIGURATION="Release"
BUNDLE_ID="com.aussienomad.MacForge"
VERSION="2.0.0"
BUILD_NUMBER="1"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../DesktopApp"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_DIR="$BUILD_DIR/archives"
EXPORT_DIR="$BUILD_DIR/exports"
DIST_DIR="$SCRIPT_DIR/../dist"

echo "🚀 Building MacForge Release v$VERSION"
echo "=================================="

# Create directories
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$EXPORT_DIR"
mkdir -p "$DIST_DIR"

# Navigate to project directory
cd "$PROJECT_DIR"

echo "📁 Project Directory: $PROJECT_DIR"
echo "📦 Bundle ID: $BUNDLE_ID"
echo "🏷️  Version: $VERSION (Build $BUILD_NUMBER)"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION"

# Update version numbers
echo "📝 Updating version numbers..."
# Note: For automated version updates, you might want to use agvtool
# agvtool new-marketing-version "$VERSION"
# agvtool new-version -all "$BUILD_NUMBER"

# Build the project
echo "🔨 Building project..."
xcodebuild build \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -derivedDataPath "$BUILD_DIR/derivedData" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Create archive
echo "📦 Creating archive..."
xcodebuild archive \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -archivePath "$ARCHIVE_DIR/$PROJECT_NAME.xcarchive" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Export the app
echo "📤 Exporting application..."
# Create export options plist
cat > "$EXPORT_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>destination</key>
    <string>export</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_DIR/$PROJECT_NAME.xcarchive" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_DIR/ExportOptions.plist" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Copy to distribution directory
echo "📋 Preparing distribution files..."
APP_PATH="$EXPORT_DIR/$PROJECT_NAME.app"
DIST_APP_PATH="$DIST_DIR/$PROJECT_NAME-v$VERSION.app"

if [ -d "$APP_PATH" ]; then
    cp -R "$APP_PATH" "$DIST_APP_PATH"
    echo "✅ Application copied to: $DIST_APP_PATH"
else
    echo "❌ Application not found at: $APP_PATH"
    exit 1
fi

# Create DMG (optional - requires create-dmg)
if command -v create-dmg &> /dev/null; then
    echo "💿 Creating DMG installer..."
    DMG_PATH="$DIST_DIR/$PROJECT_NAME-v$VERSION.dmg"
    create-dmg \
        --volname "$PROJECT_NAME v$VERSION" \
        --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "$PROJECT_NAME.app" 175 120 \
        --hide-extension "$PROJECT_NAME.app" \
        --app-drop-link 425 120 \
        "$DMG_PATH" \
        "$DIST_DIR/"
    echo "✅ DMG created: $DMG_PATH"
else
    echo "⚠️  create-dmg not found. Install with: brew install create-dmg"
fi

# Create ZIP archive
echo "🗜️  Creating ZIP archive..."
ZIP_PATH="$DIST_DIR/$PROJECT_NAME-v$VERSION.zip"
cd "$DIST_DIR"
zip -r "$(basename "$ZIP_PATH")" "$PROJECT_NAME-v$VERSION.app"
cd - > /dev/null
echo "✅ ZIP created: $ZIP_PATH"

# Generate checksums
echo "🔐 Generating checksums..."
if [ -f "$ZIP_PATH" ]; then
    shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"
    echo "✅ SHA256: $(cat "$ZIP_PATH.sha256")"
fi

if [ -f "$DMG_PATH" ]; then
    shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
    echo "✅ DMG SHA256: $(cat "$DMG_PATH.sha256")"
fi

# Display results
echo ""
echo "🎉 Release build completed successfully!"
echo "=================================="
echo "📁 Distribution files:"
echo "   App: $DIST_APP_PATH"
if [ -f "$ZIP_PATH" ]; then
    echo "   ZIP: $ZIP_PATH"
fi
if [ -f "$DMG_PATH" ]; then
    echo "   DMG: $DMG_PATH"
fi
echo ""
echo "📋 Next steps:"
echo "   1. Test the application thoroughly"
echo "   2. Create a GitHub release"
echo "   3. Upload the distribution files"
echo "   4. Update documentation"
echo ""
echo "🔗 GitHub Release URL:"
echo "   https://github.com/Aussie-Nomad/MacForge/releases/new"
