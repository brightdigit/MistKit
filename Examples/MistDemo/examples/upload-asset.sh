#!/bin/bash
#
# upload-asset.sh
# Asset upload example for MistDemo
#
# This script demonstrates various asset upload workflows:
# 1. Upload an image asset
# 2. Upload with custom record type
# 3. Complete workflow: upload then create record
# 4. Complete workflow: upload then update existing record
# 5. Error handling scenarios
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
API_TOKEN="${CLOUDKIT_API_TOKEN}"
WEB_AUTH_TOKEN="${CLOUDKIT_WEB_AUTH_TOKEN}"
CONFIG_FILE="$HOME/.mistdemo/config.json"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MistDemo Asset Upload Examples${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Load configuration if tokens not provided
if [ -z "$API_TOKEN" ] || [ -z "$WEB_AUTH_TOKEN" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}📋 Loading configuration from $CONFIG_FILE${NC}"
        API_TOKEN=$(cat "$CONFIG_FILE" | jq -r '.api_token')
        WEB_AUTH_TOKEN=$(cat "$CONFIG_FILE" | jq -r '.web_auth_token')
    else
        echo -e "${RED}❌ No authentication tokens found.${NC}"
        echo "Run ./examples/auth-flow.sh first or set environment variables:"
        echo "   export CLOUDKIT_API_TOKEN=your_api_token"
        echo "   export CLOUDKIT_WEB_AUTH_TOKEN=your_web_auth_token"
        exit 1
    fi
fi

# Common parameters
COMMON_ARGS="--api-token $API_TOKEN --web-auth-token $WEB_AUTH_TOKEN"

# Create temporary test files
TEMP_DIR=$(mktemp -d)
TEST_IMAGE="$TEMP_DIR/test-image.png"
TEST_LARGE="$TEMP_DIR/test-large.bin"

echo -e "${YELLOW}📁 Creating test files in $TEMP_DIR${NC}\n"

# Create a small test image (1x1 PNG - 67 bytes)
echo -n "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > "$TEST_IMAGE"

echo ""
echo -e "${GREEN}Example 1: Upload image to default Note.image field${NC}"
echo "Command: swift run mistdemo upload-asset $COMMON_ARGS --file-path \"$TEST_IMAGE\""
echo ""
swift run mistdemo upload-asset $COMMON_ARGS --file-path "$TEST_IMAGE"

echo ""
echo -e "${GREEN}Example 2: Upload to custom record type and field${NC}"
echo "Command: swift run mistdemo upload-asset $COMMON_ARGS --file-path \"$TEST_IMAGE\" --record-type Photo --field-name thumbnail"
echo ""
swift run mistdemo upload-asset $COMMON_ARGS --file-path "$TEST_IMAGE" --record-type Photo --field-name thumbnail

echo ""
echo -e "${GREEN}Example 3: Complete workflow - Upload asset then create record${NC}"
echo -e "${YELLOW}Step 1: Upload asset and capture output${NC}"
echo "Command: swift run mistdemo upload-asset $COMMON_ARGS --file-path \"$TEST_IMAGE\" --output json"
echo ""

UPLOAD_OUTPUT=$(swift run mistdemo upload-asset $COMMON_ARGS --file-path "$TEST_IMAGE" --output json)
echo "$UPLOAD_OUTPUT" | jq .

# Extract asset data from upload result
ASSET_RECEIPT=$(echo "$UPLOAD_OUTPUT" | jq -r '.asset.receipt')
ASSET_CHECKSUM=$(echo "$UPLOAD_OUTPUT" | jq -r '.asset.fileChecksum')

echo ""
echo -e "${YELLOW}Step 2: Create record with asset field${NC}"
echo "Note: The upload-asset command returns an AssetUploadReceipt containing the complete asset dictionary"
echo "      Use this asset data when creating or updating records with asset fields"
echo ""

# For demonstration purposes, show how you would use the asset in a record creation
echo "Example create command (requires asset field support in create command):"
echo "swift run mistdemo create $COMMON_ARGS \\"
echo "  --record-type Note \\"
echo "  --field \"title:string:Photo Note\" \\"
echo "  --asset-field \"image:asset:receipt=$ASSET_RECEIPT,checksum=$ASSET_CHECKSUM\""

echo ""
echo -e "${GREEN}Example 4: Update existing record with asset${NC}"
echo -e "${YELLOW}Step 1: Create a record first${NC}"
echo ""

CREATE_OUTPUT=$(swift run mistdemo create $COMMON_ARGS --field "title:string:Asset Test" --output json)
RECORD_NAME=$(echo "$CREATE_OUTPUT" | jq -r '.recordName')
RECORD_CHANGE_TAG=$(echo "$CREATE_OUTPUT" | jq -r '.recordChangeTag')

echo "Created record: $RECORD_NAME"
echo "Change tag: $RECORD_CHANGE_TAG"

echo ""
echo -e "${YELLOW}Step 2: Upload asset for this record${NC}"
echo ""
swift run mistdemo upload-asset $COMMON_ARGS --file-path "$TEST_IMAGE" --record-name "$RECORD_NAME"

echo ""
echo -e "${YELLOW}Step 3: Update record with asset field${NC}"
echo "Note: Similar to create, you would use the asset data from the upload result"
echo ""

echo ""
echo -e "${GREEN}Example 5: Error handling scenarios${NC}"
echo ""

# Test file size validation
echo -e "${YELLOW}Testing file size validation (create 300MB file - should fail)...${NC}"
echo "CloudKit asset upload has size limits. Large files will be rejected."
echo ""

# Create a 1KB file instead of 300MB for demo purposes (300MB would take too long)
dd if=/dev/zero of="$TEST_LARGE" bs=1024 count=1 2>/dev/null
echo "Created 1KB test file (would be 300MB in real scenario)"
echo ""

echo "Command: swift run mistdemo upload-asset $COMMON_ARGS --file-path \"$TEST_LARGE\""
swift run mistdemo upload-asset $COMMON_ARGS --file-path "$TEST_LARGE" || echo -e "${RED}Expected: Large file upload might fail with CloudKit limits${NC}"

echo ""
echo -e "${YELLOW}Testing invalid file path...${NC}"
swift run mistdemo upload-asset $COMMON_ARGS --file-path "/nonexistent/file.png" 2>&1 || echo -e "${RED}Expected: File not found error${NC}"

echo ""
echo -e "\n${BLUE}Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR"
echo -e "${GREEN}✓ Cleanup complete${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Asset Upload Examples Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}💡 Key Takeaways:${NC}"
echo "  • upload-asset returns AssetUploadReceipt with complete asset metadata"
echo "  • Asset includes receipt, checksums, and download URL"
echo "  • Use this asset data when creating/updating records with asset fields"
echo "  • CloudKit enforces file size limits on uploads"
echo "  • Assets must be associated with record fields via subsequent operations"
echo ""
