#!/bin/bash
#
# query-records.sh
# Query records example for MistDemo
#
# This script demonstrates various query operations:
# 1. Basic queries
# 2. Filtering
# 3. Sorting
# 4. Pagination
# 5. Field selection
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
API_TOKEN="${CLOUDKIT_API_TOKEN}"
WEB_AUTH_TOKEN="${CLOUDKIT_WEBAUTH_TOKEN}"
CONFIG_FILE="$HOME/.mistdemo/config.json"

echo -e "${GREEN}🔍 MistDemo Query Examples${NC}"
echo "=========================="

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
        echo "   export CLOUDKIT_WEBAUTH_TOKEN=your_web_auth_token"
        exit 1
    fi
fi

# Common query parameters
COMMON_ARGS="--api-token $API_TOKEN --web-auth-token $WEB_AUTH_TOKEN"

echo ""
echo -e "${GREEN}Example 1: Basic query (all Note records)${NC}"
echo "Command: swift run mistdemo query $COMMON_ARGS --record-type Note --limit 10"
swift run mistdemo query $COMMON_ARGS --record-type Note --limit 10 --output-format table

echo ""
echo -e "${GREEN}Example 2: Query with title filter${NC}"
echo "Command: swift run mistdemo query $COMMON_ARGS --filter \"title:contains:test\""
swift run mistdemo query $COMMON_ARGS --record-type Note --filter "title:contains:test" --output-format table

echo ""
echo -e "${GREEN}Example 3: Query with multiple filters${NC}"
echo "Command: swift run mistdemo query $COMMON_ARGS --filter \"title:contains:important\" --filter \"priority:gt:5\""
swift run mistdemo query $COMMON_ARGS --record-type Note \
    --filter "title:contains:important" \
    --filter "priority:gt:5" \
    --output-format table

echo ""
echo -e "${GREEN}Example 4: Query with sorting (newest first)${NC}"
echo "Command: swift run mistdemo query $COMMON_ARGS --sort \"createdAt:desc\""
swift run mistdemo query $COMMON_ARGS --record-type Note \
    --sort "createdAt:desc" \
    --limit 5 \
    --output-format table

echo ""
echo -e "${GREEN}Example 5: Query with field selection${NC}"
echo "Command: swift run mistdemo query $COMMON_ARGS --fields \"title,createdAt,priority\""
swift run mistdemo query $COMMON_ARGS --record-type Note \
    --fields "title,createdAt,priority" \
    --limit 5 \
    --output-format table

echo ""
echo -e "${GREEN}Example 6: Query with custom zone${NC}"
echo "Command: swift run mistdemo query $COMMON_ARGS --zone \"customZone\""
swift run mistdemo query $COMMON_ARGS --record-type Note \
    --zone "customZone" \
    --limit 5 \
    --output-format table

echo ""
echo -e "${GREEN}Example 7: JSON output for processing${NC}"
echo "Command: swift run mistdemo query $COMMON_ARGS --output-format json | jq"
RESULT=$(swift run mistdemo query $COMMON_ARGS --record-type Note --limit 3 --output-format json)
echo "$RESULT" | jq '.'

echo ""
echo -e "${GREEN}Example 8: CSV output for spreadsheets${NC}"
echo "Command: swift run mistdemo query $COMMON_ARGS --output-format csv"
swift run mistdemo query $COMMON_ARGS --record-type Note --limit 5 --output-format csv

echo ""
echo -e "${GREEN}📊 Query Statistics${NC}"
TOTAL_RECORDS=$(swift run mistdemo query $COMMON_ARGS --record-type Note --output-format json | jq '.records | length')
echo "Total Note records found: $TOTAL_RECORDS"

echo ""
echo -e "${GREEN}🎯 Available Filter Operators${NC}"
echo "eq          - equals"
echo "ne          - not equals"
echo "lt          - less than"
echo "lte         - less than or equal"
echo "gt          - greater than"
echo "gte         - greater than or equal"
echo "in          - in list"
echo "contains    - contains text"
echo "beginsWith  - begins with text"

echo ""
echo -e "${GREEN}📋 Sort Orders${NC}"
echo "asc         - ascending"
echo "desc        - descending"

echo ""
echo -e "${GREEN}🎉 Query examples completed!${NC}"