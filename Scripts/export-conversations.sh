#!/bin/bash

# Export all Claude Code conversations to markdown format
# Usage: ./export-conversations.sh [output_directory]
# Default output: .claude/conversations

set -euo pipefail

# Configuration
CLAUDE_DIR="$HOME/.claude/projects"
OUTPUT_DIR="${1:-.claude/conversations}"
CURRENT_DIR="$(pwd)"
CURRENT_PROJECT_NAME="$(basename "$CURRENT_DIR")"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=== Claude Code Conversation Exporter ==="
echo "Exporting conversations to: $OUTPUT_DIR"
echo ""

# Function to convert JSONL to readable markdown
convert_conversation() {
    local jsonl_file="$1"
    local output_file="$2"
    local session_id="$(basename "$jsonl_file" .jsonl)"

    echo "# Claude Code Conversation" > "$output_file"
    echo "" >> "$output_file"
    echo "**Session ID:** $session_id" >> "$output_file"
    echo "**Exported:** $(date)" >> "$output_file"
    echo "" >> "$output_file"
    echo "---" >> "$output_file"
    echo "" >> "$output_file"

    # Parse JSONL and extract messages
    while IFS= read -r line; do
        # Check if line is valid JSON
        if ! echo "$line" | jq empty 2>/dev/null; then
            continue
        fi

        local msg_type=$(echo "$line" | jq -r '.type // empty')
        local role=$(echo "$line" | jq -r '.message.role // empty')
        local content=$(echo "$line" | jq -r '.message.content // empty')
        local timestamp=$(echo "$line" | jq -r '.timestamp // empty')
        local is_meta=$(echo "$line" | jq -r '.isMeta // false')

        # Skip meta messages
        if [ "$is_meta" = "true" ]; then
            continue
        fi

        # Format timestamp
        if [ -n "$timestamp" ] && [ "$timestamp" != "null" ]; then
            formatted_time=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${timestamp%.*}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
        else
            formatted_time=""
        fi

        # Output based on role
        if [ "$role" = "user" ]; then
            echo "## User" >> "$output_file"
            if [ -n "$formatted_time" ]; then
                echo "*$formatted_time*" >> "$output_file"
            fi
            echo "" >> "$output_file"
            echo "$content" >> "$output_file"
            echo "" >> "$output_file"
        elif [ "$role" = "assistant" ]; then
            echo "## Assistant" >> "$output_file"
            if [ -n "$formatted_time" ]; then
                echo "*$formatted_time*" >> "$output_file"
            fi
            echo "" >> "$output_file"
            echo "$content" >> "$output_file"
            echo "" >> "$output_file"
        fi

    done < "$jsonl_file"
}

# Find all project directories related to this git repository
# This includes the main project and all git worktrees
PROJECT_DIRS=()

# Get the base project name (e.g., "MistKit")
BASE_PROJECT_NAME="$CURRENT_PROJECT_NAME"

# Find all directories that contain this project name
while IFS= read -r dir; do
    PROJECT_DIRS+=("$dir")
done < <(find "$CLAUDE_DIR" -type d -name "*$BASE_PROJECT_NAME*" 2>/dev/null)

if [ ${#PROJECT_DIRS[@]} -eq 0 ]; then
    echo "Warning: Could not find any Claude project directories for: $BASE_PROJECT_NAME"
    echo "Falling back to searching all projects..."
    PROJECT_DIRS=("$CLAUDE_DIR")
fi

echo "Found ${#PROJECT_DIRS[@]} project directory(ies):"
for dir in "${PROJECT_DIRS[@]}"; do
    echo "  - $(basename "$dir")"
done
echo ""

# Counter
count=0

# Find and convert all JSONL files from all related project directories
for PROJECT_DIR in "${PROJECT_DIRS[@]}"; do
    echo "Searching in: $(basename "$PROJECT_DIR")"

    while IFS= read -r jsonl_file; do
        if [ ! -f "$jsonl_file" ]; then
            continue
        fi

        session_id="$(basename "$jsonl_file" .jsonl)"

        # Get first message timestamp for filename
        first_timestamp=$(head -1 "$jsonl_file" | jq -r '.timestamp // empty' 2>/dev/null || echo "")

        if [ -n "$first_timestamp" ] && [ "$first_timestamp" != "null" ]; then
            date_prefix=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${first_timestamp%.*}" "+%Y%m%d-%H%M%S" 2>/dev/null || echo "unknown")
        else
            date_prefix="unknown"
        fi

        output_file="$OUTPUT_DIR/${date_prefix}_${session_id}.md"

        echo "  Exporting: $session_id"
        convert_conversation "$jsonl_file" "$output_file"

        ((count++))
    done < <(find "$PROJECT_DIR" -name "*.jsonl" -type f 2>/dev/null | sort)
done

echo ""
echo "=== Export Complete ==="
echo "Exported $count conversation(s) to: $OUTPUT_DIR"
echo ""

# Create an index file
index_file="$OUTPUT_DIR/INDEX.md"
echo "# Claude Code Conversations Index" > "$index_file"
echo "" >> "$index_file"
echo "**Project:** $CURRENT_PROJECT_NAME" >> "$index_file"
echo "**Exported:** $(date)" >> "$index_file"
echo "**Total Conversations:** $count" >> "$index_file"
echo "" >> "$index_file"
echo "## Conversations" >> "$index_file"
echo "" >> "$index_file"

# List all exported files
for md_file in "$OUTPUT_DIR"/*.md; do
    if [ "$(basename "$md_file")" != "INDEX.md" ]; then
        filename=$(basename "$md_file")
        echo "- [$filename](./$filename)" >> "$index_file"
    fi
done

echo "Index created: $index_file"
