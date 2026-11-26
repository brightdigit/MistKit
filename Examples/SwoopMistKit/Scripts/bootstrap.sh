#!/bin/bash

# BushelCloud Bootstrap Script
# This script sets up the development environment for BushelCloud

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================"
echo "BushelCloud Development Setup"
echo "========================================"
echo ""

# Check Swift version
echo "Checking Swift version..."
if ! command -v swift &> /dev/null; then
    echo -e "${RED}ERROR: Swift is not installed.${NC}"
    echo "Please install Swift 6.4 or later from https://swift.org"
    exit 1
fi

SWIFT_VERSION=$(swift --version | head -n 1)
echo -e "${GREEN}✓${NC} Swift is installed: $SWIFT_VERSION"

# Check for minimum Swift 6.0
if ! swift --version | grep -qE "Swift version (6\.[0-9]+|[7-9]\.|[1-9][0-9]+\.)"; then
    echo -e "${YELLOW}WARNING: This project requires Swift 6.0 or later.${NC}"
    echo "You may encounter compatibility issues with your current Swift version."
fi

echo ""

# Check if mise is installed
echo "Checking for mise (polyglot tool version manager)..."
if ! command -v mise &> /dev/null; then
    echo -e "${YELLOW}mise is not installed.${NC}"
    echo ""
    read -p "Would you like to install mise? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing mise..."
        if command -v brew &> /dev/null; then
            brew install mise
            echo -e "${GREEN}✓${NC} mise installed via Homebrew"
        else
            echo -e "${YELLOW}Homebrew not found. Installing mise via official installer...${NC}"
            curl https://mise.run | sh
            echo -e "${GREEN}✓${NC} mise installed"
            echo -e "${YELLOW}Add ~/.local/bin to your PATH and run \`mise activate\` per the mise docs.${NC}"
        fi
    else
        echo -e "${YELLOW}Skipping mise installation. Some tools may not be available.${NC}"
    fi
else
    echo -e "${GREEN}✓${NC} mise is installed"
fi

echo ""

# Install development tools via mise
if command -v mise &> /dev/null && [ -f "mise.toml" ]; then
    echo "Installing development tools from mise.toml..."
    echo "This may take a few minutes on first run..."
    echo ""

    if mise install; then
        echo -e "${GREEN}✓${NC} Development tools installed"
        echo "  - SwiftLint (code linting)"
        echo "  - swift-format (code formatting)"
        echo "  - periphery (unused code detection)"
    else
        echo -e "${YELLOW}WARNING: Failed to install some development tools.${NC}"
        echo "You can install them manually later with: mise install"
    fi
else
    echo -e "${YELLOW}Skipping development tools installation (mise not available or mise.toml not found)${NC}"
fi

echo ""

# Check for XcodeGen
echo "Checking for XcodeGen..."
if command -v xcodegen &> /dev/null; then
    echo -e "${GREEN}✓${NC} XcodeGen is installed"

    # Generate Xcode project if project.yml exists
    if [ -f "project.yml" ]; then
        echo ""
        read -p "Generate Xcode project? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Generating Xcode project..."
            if xcodegen generate; then
                echo -e "${GREEN}✓${NC} Xcode project generated"
                echo "  You can now open BushelCloud.xcodeproj"
            else
                echo -e "${RED}ERROR: Failed to generate Xcode project${NC}"
            fi
        fi
    fi
else
    echo -e "${YELLOW}XcodeGen is not installed.${NC}"
    echo "XcodeGen is optional but recommended for Xcode development."
    echo ""
    read -p "Would you like to install XcodeGen via Homebrew? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v brew &> /dev/null; then
            brew install xcodegen
            echo -e "${GREEN}✓${NC} XcodeGen installed"

            # Generate project after installation
            if [ -f "project.yml" ]; then
                echo "Generating Xcode project..."
                xcodegen generate
                echo -e "${GREEN}✓${NC} Xcode project generated"
            fi
        else
            echo -e "${YELLOW}Homebrew not found. Please install XcodeGen manually:${NC}"
            echo "  https://github.com/yonaskolb/XcodeGen"
        fi
    fi
fi

echo ""

# Build the project
echo "Building the project..."
if swift build; then
    echo -e "${GREEN}✓${NC} Project built successfully"
    echo ""
    echo "Executable location: .build/debug/bushel-cloud"
else
    echo -e "${RED}ERROR: Build failed${NC}"
    echo "Please check the error messages above and resolve any issues."
    exit 1
fi

echo ""

# Run tests
echo "Running tests..."
if swift test; then
    echo -e "${GREEN}✓${NC} All tests passed"
else
    echo -e "${YELLOW}WARNING: Some tests failed${NC}"
    echo "You can continue development, but please fix failing tests before committing."
fi

echo ""
echo "========================================"
echo -e "${GREEN}✓✓✓ Bootstrap complete! ✓✓✓${NC}"
echo "========================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Set up CloudKit credentials (see .env.example):"
echo "     cp .env.example .env"
echo "     # Edit .env with your CloudKit credentials"
echo ""
echo "  2. Import CloudKit schema:"
echo "     ./Scripts/setup-cloudkit-schema.sh"
echo ""
echo "  3. Run the CLI tool:"
echo "     .build/debug/bushel-cloud --help"
echo "     .build/debug/bushel-cloud sync --verbose"
echo ""
echo "  4. For Xcode development:"
echo "     open BushelCloud.xcodeproj"
echo ""
echo "Documentation: See README.md and CLAUDE.md for detailed guides"
echo ""
