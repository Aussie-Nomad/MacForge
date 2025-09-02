#!/bin/bash

# MacForge Release Creation Script
# This script creates a GitHub release manually

set -e

# Configuration
PROJECT_DIR="../DesktopApp"
BUILD_DIR="${PROJECT_DIR}/build"
DERIVED_DATA_PATH="${BUILD_DIR}/derivedData"
DIST_DIR="dist"
SCHEME="MacForge"
CONFIGURATION="Release"
BUNDLE_IDENTIFIER="com.aussienomad.MacForge"
VERSION="2.0.0"
BUILD_NUMBER="1"

echo "🚀 Creating MacForge Release v${VERSION}"
echo "=================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check if we have uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "❌ Error: You have uncommitted changes. Please commit or stash them first."
    exit 1
fi

# Check if tag already exists
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo "❌ Error: Tag v${VERSION} already exists"
    exit 1
fi

# Clean previous builds
echo ""
echo "🧹 Cleaning previous builds..."
xcodebuild clean -project "${PROJECT_DIR}/${SCHEME}.xcodeproj" -scheme "${SCHEME}" -configuration "${CONFIGURATION}" || exit 1

# Build the project
echo ""
echo "🔨 Building project..."
xcodebuild build \
  -project "${PROJECT_DIR}/${SCHEME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination 'platform=macOS' \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  CURRENT_PROJECT_VERSION="${BUILD_NUMBER}" \
  MARKETING_VERSION="${VERSION}" \
  PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER}" \
  || exit 1

# Create distribution directory
echo ""
echo "📦 Creating distribution package..."
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

# Find the built application
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${SCHEME}.app"

if [ ! -d "${APP_PATH}" ]; then
  echo "❌ Error: Application not found at ${APP_PATH}"
  exit 1
fi

# Copy the app to the distribution directory
cp -R "${APP_PATH}" "${DIST_DIR}/${SCHEME}-v${VERSION}.app"

# Create a zip archive
cd "${DIST_DIR}"
zip -r "${SCHEME}-v${VERSION}.zip" "${SCHEME}-v${VERSION}.app"

# Generate SHA256 checksum
shasum -a 256 "${SCHEME}-v${VERSION}.zip" > "${SCHEME}-v${VERSION}.zip.sha256"

echo ""
echo "✅ Release build and package created successfully!"
echo "Output files are in the '$(pwd)' directory:"
ls -lh

echo ""
echo "SHA256 Checksum:"
cat "${SCHEME}-v${VERSION}.zip.sha256"

# Create git tag
echo ""
echo "🏷️  Creating git tag..."
cd ..
git tag -a "v${VERSION}" -m "Release v${VERSION}"

echo ""
echo "📤 Pushing to GitHub..."
git push origin main
git push origin "v${VERSION}"

echo ""
echo "🎉 Release v${VERSION} created successfully!"
echo ""
echo "Next steps:"
echo "1. Go to https://github.com/Aussie-Nomad/MacForge/releases"
echo "2. Edit the release v${VERSION}"
echo "3. Upload the following files:"
echo "   - ${DIST_DIR}/${SCHEME}-v${VERSION}.zip"
echo "   - ${DIST_DIR}/${SCHEME}-v${VERSION}.zip.sha256"
echo "4. Add release notes from RELEASE_NOTES.md"
echo "5. Publish the release"
echo ""
echo "🔗 GitHub Release URL:"
echo "   https://github.com/Aussie-Nomad/MacForge/releases/tag/v${VERSION}"
