#!/bin/bash

# CloudKit Schema Setup Script
# This script imports the Celestra schema into your CloudKit container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "CloudKit Schema Setup for Celestra"
echo "========================================"
echo ""

# Check if cktool is available
if ! command -v xcrun &> /dev/null || ! xcrun cktool --version &> /dev/null; then
    echo -e "${RED}ERROR: cktool is not available.${NC}"
    echo "cktool is distributed with Xcode 13+ and is required for schema import."
    echo "Please install Xcode 13 or later."
    exit 1
fi

echo -e "${GREEN}✓${NC} cktool is available"
echo ""

# Check for required parameters
if [ -z "$CLOUDKIT_CONTAINER_ID" ]; then
    echo -e "${YELLOW}CLOUDKIT_CONTAINER_ID not set.${NC}"
    read -p "Enter your CloudKit Container ID (e.g., iCloud.com.yourcompany.Celestra): " CLOUDKIT_CONTAINER_ID
fi

if [ -z "$CLOUDKIT_TEAM_ID" ]; then
    echo -e "${YELLOW}CLOUDKIT_TEAM_ID not set.${NC}"
    read -p "Enter your Apple Developer Team ID (10-character ID): " CLOUDKIT_TEAM_ID
fi

# Default to development environment
ENVIRONMENT=${CLOUDKIT_ENVIRONMENT:-development}

echo ""
echo "Configuration:"
echo "  Container ID: $CLOUDKIT_CONTAINER_ID"
echo "  Team ID: $CLOUDKIT_TEAM_ID"
echo "  Environment: $ENVIRONMENT"
echo ""

# Check if schema file exists
SCHEMA_FILE="$(dirname "$0")/../schema.ckdb"
if [ ! -f "$SCHEMA_FILE" ]; then
    echo -e "${RED}ERROR: Schema file not found at $SCHEMA_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Schema file found: $SCHEMA_FILE"
echo ""

# Validate schema
echo "Validating schema..."
if xcrun cktool validate-schema \
    --team-id "$CLOUDKIT_TEAM_ID" \
    --container-id "$CLOUDKIT_CONTAINER_ID" \
    --environment "$ENVIRONMENT" \
    "$SCHEMA_FILE" 2>&1; then
    echo -e "${GREEN}✓${NC} Schema validation passed"
else
    echo -e "${RED}✗${NC} Schema validation failed"
    exit 1
fi

echo ""

# Confirm before import
echo -e "${YELLOW}Warning: This will import the schema into your CloudKit container.${NC}"
echo "This operation will create/modify record types in the $ENVIRONMENT environment."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Import cancelled."
    exit 0
fi

# Import schema
echo ""
echo "Importing schema to CloudKit..."
if xcrun cktool import-schema \
    --team-id "$CLOUDKIT_TEAM_ID" \
    --container-id "$CLOUDKIT_CONTAINER_ID" \
    --environment "$ENVIRONMENT" \
    "$SCHEMA_FILE" 2>&1; then
    echo ""
    echo -e "${GREEN}✓✓✓ Schema import successful! ✓✓✓${NC}"
    echo ""
    echo "Your CloudKit container now has the following record types:"
    echo "  • PublicFeed"
    echo "  • PublicArticle"
    echo ""
    echo "Next steps:"
    echo "  1. Configure your .env file with CloudKit credentials"
    echo "  2. Run 'swift run celestra add-feed <url>' to add an RSS feed"
    echo "  3. Run 'swift run celestra update' to fetch and sync articles"
    echo "  4. Verify data in CloudKit Dashboard: https://icloud.developer.apple.com/"
    echo ""
else
    echo ""
    echo -e "${RED}✗✗✗ Schema import failed ✗✗✗${NC}"
    echo ""
    echo "Common issues:"
    echo "  • Authentication token not saved (run: xcrun cktool save-token)"
    echo "  • Incorrect container ID or team ID"
    echo "  • Missing permissions in CloudKit Dashboard"
    echo ""
    echo "For help, see: https://developer.apple.com/documentation/cloudkit"
    exit 1
fi
