#!/bin/bash
#
# auth-flow.sh
# Complete authentication workflow example for MistDemo
#
# This script demonstrates the complete authentication flow:
# 1. Get authentication token via browser
# 2. Verify authentication with current-user
# 3. Store token for future use
#

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
API_TOKEN="${CLOUDKIT_API_TOKEN}"
CONFIG_DIR="$HOME/.mistdemo"
CONFIG_FILE="$CONFIG_DIR/config.json"

echo -e "${GREEN}🚀 MistDemo Authentication Flow${NC}"
echo "================================"

# Check if API token is provided
if [ -z "$API_TOKEN" ]; then
    echo -e "${RED}❌ Error: CLOUDKIT_API_TOKEN environment variable not set${NC}"
    echo "   Please set your CloudKit API token:"
    echo "   export CLOUDKIT_API_TOKEN=your_api_token_here"
    exit 1
fi

echo -e "${YELLOW}📋 Using API Token: ${API_TOKEN:0:10}...${NC}"

# Step 1: Get web authentication token
echo ""
echo -e "${GREEN}Step 1: Getting web authentication token...${NC}"
echo "This will open your browser for CloudKit authentication."
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Authentication cancelled."
    exit 0
fi

# Run auth-token command and capture the token
echo "Starting authentication server..."
WEB_AUTH_TOKEN=$(swift run mistdemo auth-token --api-token "$API_TOKEN" 2>/dev/null | tail -n 1)

if [ -z "$WEB_AUTH_TOKEN" ]; then
    echo -e "${RED}❌ Failed to get authentication token${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Got web authentication token: ${WEB_AUTH_TOKEN:0:20}...${NC}"

# Step 2: Verify authentication
echo ""
echo -e "${GREEN}Step 2: Verifying authentication...${NC}"
USER_INFO=$(swift run mistdemo current-user \
    --api-token "$API_TOKEN" \
    --web-auth-token "$WEB_AUTH_TOKEN" \
    --output-format json 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Authentication verified!${NC}"
    echo "User info:"
    echo "$USER_INFO" | jq '.'
else
    echo -e "${RED}❌ Authentication verification failed${NC}"
    exit 1
fi

# Step 3: Save configuration
echo ""
echo -e "${GREEN}Step 3: Saving configuration...${NC}"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Create configuration file
cat > "$CONFIG_FILE" << EOF
{
    "api_token": "$API_TOKEN",
    "web_auth_token": "$WEB_AUTH_TOKEN",
    "container_id": "iCloud.com.brightdigit.MistDemo",
    "environment": "development",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo -e "${GREEN}✅ Configuration saved to: $CONFIG_FILE${NC}"

# Step 4: Test with a simple query
echo ""
echo -e "${GREEN}Step 4: Testing with a simple query...${NC}"
echo "Querying for Note records..."

QUERY_RESULT=$(swift run mistdemo query \
    --api-token "$API_TOKEN" \
    --web-auth-token "$WEB_AUTH_TOKEN" \
    --record-type Note \
    --limit 5 \
    --output-format json 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Query successful!${NC}"
    RECORD_COUNT=$(echo "$QUERY_RESULT" | jq '.records | length' 2>/dev/null || echo "0")
    echo "Found $RECORD_COUNT records"
else
    echo -e "${YELLOW}⚠️  Query failed (this is normal if no records exist yet)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Authentication flow completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Use the saved configuration: swift run mistdemo --config-file $CONFIG_FILE <command>"
echo "2. Or set environment variables:"
echo "   export CLOUDKIT_API_TOKEN=$API_TOKEN"
echo "   export CLOUDKIT_WEBAUTH_TOKEN=$WEB_AUTH_TOKEN"
echo "3. Create your first record: ./examples/create-record.sh"
echo "4. Query records: ./examples/query-records.sh"