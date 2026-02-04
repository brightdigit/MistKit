#!/bin/bash
#
# create-record.sh
# Create records example for MistDemo
#
# This script demonstrates various record creation methods:
# 1. Inline field definitions
# 2. JSON file input
# 3. stdin input
# 4. Different field types
# 5. Different output formats
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
API_TOKEN="${CLOUDKIT_API_TOKEN}"
WEB_AUTH_TOKEN="${CLOUDKIT_WEB_AUTH_TOKEN}"
CONFIG_FILE="$HOME/.mistdemo/config.json"

echo -e "${GREEN}📝 MistDemo Create Record Examples${NC}"
echo "=================================="

# Load configuration if tokens not provided
if [ -z "$API_TOKEN" ] || [ -z "$WEB_AUTH_TOKEN" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}📋 Loading configuration from $CONFIG_FILE${NC}"
        API_TOKEN=$(cat "$CONFIG_FILE" | jq -r '.api_token')
        WEB_AUTH_TOKEN=$(cat "$CONFIG_FILE" | jq -r '.web_auth_token')
    else
        echo "❌ No authentication tokens found."
        echo "Run ./examples/auth-flow.sh first or set environment variables:"
        echo "   export CLOUDKIT_API_TOKEN=your_api_token"
        echo "   export CLOUDKIT_WEB_AUTH_TOKEN=your_web_auth_token"
        exit 1
    fi
fi

# Common create parameters
COMMON_ARGS="--api-token $API_TOKEN --web-auth-token $WEB_AUTH_TOKEN"

echo ""
echo -e "${GREEN}Example 1: Simple text note${NC}"
echo "Command: swift run mistdemo create $COMMON_ARGS --field \"title:string:My First Note\""
swift run mistdemo create $COMMON_ARGS \
    --field "title:string:My First Note" \
    --output-format table

echo ""
echo -e "${GREEN}Example 2: Note with multiple fields${NC}"
echo "Command: Multiple field types in one record"
swift run mistdemo create $COMMON_ARGS \
    --field "title:string:Task Planning, priority:int64:8, progress:double:0.25, dueDate:timestamp:2026-12-31T23:59:59Z" \
    --output-format table

echo ""
echo -e "${GREEN}Example 3: Note with custom record name${NC}"
echo "Command: swift run mistdemo create $COMMON_ARGS --record-name \"important-task-001\""
swift run mistdemo create $COMMON_ARGS \
    --record-name "important-task-001" \
    --field "title:string:Important Task, description:string:This task has a custom record name" \
    --output-format table

echo ""
echo -e "${GREEN}Example 4: Create from JSON file${NC}"
# Create a temporary JSON file
TEMP_JSON=$(mktemp /tmp/mistdemo-example.XXXXXX.json)
cat > "$TEMP_JSON" << EOF
{
    "title": "Project Proposal",
    "category": "work",
    "priority": 9,
    "estimatedHours": 40.5,
    "startDate": "2026-02-01T09:00:00Z",
    "tags": ["project", "proposal", "client"]
}
EOF

echo "Created JSON file: $TEMP_JSON"
echo -e "${BLUE}$(cat "$TEMP_JSON")${NC}"
echo ""
echo "Command: swift run mistdemo create $COMMON_ARGS --json-file \"$TEMP_JSON\""
swift run mistdemo create $COMMON_ARGS \
    --json-file "$TEMP_JSON" \
    --output-format table

# Clean up
rm "$TEMP_JSON"

echo ""
echo -e "${GREEN}Example 5: Create from stdin${NC}"
echo "Command: echo '{\"title\":\"Quick Note\", \"content\":\"Created via stdin\"}' | swift run mistdemo create $COMMON_ARGS --stdin"
echo '{"title":"Quick Note", "content":"Created via stdin", "urgent": true}' | \
    swift run mistdemo create $COMMON_ARGS --stdin --output-format table

echo ""
echo -e "${GREEN}Example 6: Different field types demonstration${NC}"
echo "Creating record with all supported field types..."
swift run mistdemo create $COMMON_ARGS \
    --field "textField:string:Sample text with spaces, numberField:int64:42, decimalField:double:3.14159, timeField:timestamp:2026-01-29T12:00:00Z" \
    --output-format table

echo ""
echo -e "${GREEN}Example 7: Custom zone${NC}"
echo "Command: swift run mistdemo create $COMMON_ARGS --zone \"projectZone\""
swift run mistdemo create $COMMON_ARGS \
    --zone "projectZone" \
    --field "title:string:Project Zone Record, zone:string:projectZone" \
    --output-format table

echo ""
echo -e "${GREEN}Example 8: JSON output for integration${NC}"
echo "Command: Create record and capture JSON for further processing"
CREATED_RECORD=$(swift run mistdemo create $COMMON_ARGS \
    --field "title:string:API Integration Test, type:string:integration" \
    --output-format json)

echo "Created record JSON:"
echo "$CREATED_RECORD" | jq '.'

# Extract the record name for verification
RECORD_NAME=$(echo "$CREATED_RECORD" | jq -r '.recordName // empty')
if [ -n "$RECORD_NAME" ]; then
    echo ""
    echo -e "${GREEN}✅ Successfully created record: $RECORD_NAME${NC}"
fi

echo ""
echo -e "${GREEN}🎯 Field Type Reference${NC}"
echo "string      - Text values (any string)"
echo "int64       - Integer numbers (-9223372036854775808 to 9223372036854775807)"
echo "double      - Decimal numbers (64-bit floating point)"
echo "timestamp   - Dates in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)"

echo ""
echo -e "${GREEN}📋 Field Definition Format${NC}"
echo "Format: name:type:value"
echo "Examples:"
echo "  title:string:My Note Title"
echo "  count:int64:42"
echo "  rating:double:4.5"
echo "  deadline:timestamp:2026-12-31T23:59:59Z"

echo ""
echo -e "${GREEN}💡 Tips${NC}"
echo "• Record names are auto-generated if not specified"
echo "• Use quotes around field values containing spaces or special characters"
echo "• JSON files automatically detect field types from values"
echo "• Multiple fields can be comma-separated in one --field argument"

echo ""
echo -e "${GREEN}🎉 Create examples completed!${NC}"