#!/usr/bin/env python3
"""
Convert Claude Code conversation markdown files to timeline format.

Usage:
    ./Scripts/convert-conversations.py <file.md>              # Convert single file
    ./Scripts/convert-conversations.py --all                  # Convert all files
    ./Scripts/convert-conversations.py --all --output-dir timeline  # Custom output dir
"""

import argparse
import json
import re
import sys
from pathlib import Path
from datetime import datetime


def parse_conversation_file(filepath: Path) -> dict:
    """Parse a conversation markdown file into structured data."""
    content = filepath.read_text()

    # Extract header info
    session_id_match = re.search(r'\*\*Session ID:\*\* ([a-f0-9-]+)', content)
    exported_match = re.search(r'\*\*Exported:\*\* (.+)', content)

    session_id = session_id_match.group(1) if session_id_match else "unknown"
    exported = exported_match.group(1) if exported_match else "unknown"

    # Split into messages
    message_pattern = r'## (User|Assistant)\n\*(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\*\n\n(.*?)(?=\n## (?:User|Assistant)\n|\Z)'
    messages = re.findall(message_pattern, content, re.DOTALL)

    parsed_messages = []
    for role, timestamp, content in messages:
        parsed_messages.append({
            'role': role.upper(),
            'timestamp': timestamp,
            'content': content.strip()
        })

    return {
        'session_id': session_id,
        'exported': exported,
        'messages': parsed_messages
    }


def summarize_tool_call(tool_name: str, tool_input: dict) -> str:
    """Create a brief summary of a tool call."""
    if tool_name == "Read":
        path = tool_input.get("file_path", "unknown")
        return f"[Read: {Path(path).name}]"

    elif tool_name == "Grep":
        pattern = tool_input.get("pattern", "")[:30]
        path = tool_input.get("path", ".")
        return f'[Grep: "{pattern}" in {Path(path).name}]'

    elif tool_name == "Glob":
        pattern = tool_input.get("pattern", "")
        return f"[Glob: {pattern}]"

    elif tool_name == "Bash":
        cmd = tool_input.get("command", "")[:50]
        desc = tool_input.get("description", cmd)[:40]
        return f"[Bash: {desc}]"

    elif tool_name == "WebFetch":
        url = tool_input.get("url", "")
        from urllib.parse import urlparse
        domain = urlparse(url).netloc if url else "unknown"
        return f"[WebFetch: {domain}]"

    elif tool_name in ("Edit", "Write"):
        path = tool_input.get("file_path", "unknown")
        return f"[{tool_name}: {Path(path).name}]"

    elif tool_name == "TodoWrite":
        todos = tool_input.get("todos", [])
        count = len(todos)
        return f"[TodoWrite: {count} items]"

    elif tool_name == "Task":
        agent_type = tool_input.get("subagent_type", "unknown")
        return f"[Task: {agent_type} agent]"

    else:
        return f"[{tool_name}]"


def parse_json_content(content: str) -> list:
    """Parse JSON array from message content."""
    try:
        # Try to parse as JSON array
        content = content.strip()
        if content.startswith('['):
            return json.loads(content)
    except json.JSONDecodeError:
        pass

    # Return as plain text if not JSON
    return [{"type": "text", "text": content}]


def format_message_content(content: str) -> tuple[str, list]:
    """
    Format message content into readable text and tool summaries.
    Returns (text_content, tool_summaries)
    """
    items = parse_json_content(content)

    text_parts = []
    tool_summaries = []

    for item in items:
        if isinstance(item, dict):
            item_type = item.get("type", "")

            if item_type == "text":
                text = item.get("text", "").strip()
                if text:
                    text_parts.append(text)

            elif item_type == "tool_use":
                tool_name = item.get("name", "Unknown")
                tool_input = item.get("input", {})
                tool_summaries.append(summarize_tool_call(tool_name, tool_input))

            elif item_type == "tool_result":
                # Skip tool results in the timeline (they're implementation details)
                pass

    return "\n".join(text_parts), tool_summaries


def convert_to_timeline(parsed_data: dict) -> str:
    """Convert parsed conversation data to timeline markdown format."""
    lines = []

    # Header
    first_timestamp = parsed_data['messages'][0]['timestamp'] if parsed_data['messages'] else "unknown"
    lines.append(f"# Session Timeline: {first_timestamp.split()[0]}")
    lines.append(f"**Session ID:** {parsed_data['session_id']}")
    lines.append(f"**Exported:** {parsed_data['exported']}")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Messages
    prev_role = None
    prev_time = None
    pending_tools = []

    for msg in parsed_data['messages']:
        role = msg['role']
        timestamp = msg['timestamp']
        time_only = timestamp.split()[1] if ' ' in timestamp else timestamp

        text_content, tool_summaries = format_message_content(msg['content'])

        # Skip empty tool result messages from user
        if role == "USER" and not text_content and not tool_summaries:
            continue

        # Group consecutive assistant messages
        if role == "ASSISTANT" and prev_role == "ASSISTANT":
            # If this is just tool calls, append to pending
            if tool_summaries and not text_content:
                pending_tools.extend(tool_summaries)
                continue
            elif text_content:
                # Flush pending tools first
                if pending_tools:
                    lines.append(f"### {prev_time} - ASSISTANT")
                    for tool in pending_tools:
                        lines.append(tool)
                    lines.append("")
                    pending_tools = []
        else:
            # New speaker, flush pending tools
            if pending_tools:
                lines.append(f"### {prev_time} - ASSISTANT")
                for tool in pending_tools:
                    lines.append(tool)
                lines.append("")
                pending_tools = []

        # Handle current message
        if tool_summaries and not text_content:
            # Just tools, save for later grouping
            pending_tools.extend(tool_summaries)
            prev_time = time_only
        elif text_content:
            lines.append(f"### {time_only} - {role}")
            if tool_summaries:
                for tool in tool_summaries:
                    lines.append(tool)
                lines.append("")
            # Truncate long text
            if len(text_content) > 2000:
                text_content = text_content[:2000] + "\n\n... [truncated]"
            lines.append(text_content)
            lines.append("")

        prev_role = role
        prev_time = time_only

    # Flush any remaining pending tools
    if pending_tools:
        lines.append(f"### {prev_time} - ASSISTANT")
        for tool in pending_tools:
            lines.append(tool)
        lines.append("")

    return "\n".join(lines)


def convert_file(input_path: Path, output_dir: Path = None) -> Path:
    """Convert a single conversation file to timeline format."""
    if output_dir is None:
        output_dir = input_path.parent / "timeline"

    output_dir.mkdir(parents=True, exist_ok=True)

    parsed = parse_conversation_file(input_path)
    timeline = convert_to_timeline(parsed)

    output_path = output_dir / f"timeline_{input_path.name}"
    output_path.write_text(timeline)

    return output_path


def main():
    parser = argparse.ArgumentParser(description="Convert Claude Code conversations to timeline format")
    parser.add_argument("file", nargs="?", help="Single file to convert")
    parser.add_argument("--all", action="store_true", help="Convert all conversation files")
    parser.add_argument("--output-dir", default=None, help="Output directory (default: timeline/ in same dir)")
    parser.add_argument("--conversations-dir", default=".claude/conversations",
                        help="Directory containing conversation files")

    args = parser.parse_args()

    if args.all:
        conv_dir = Path(args.conversations_dir)
        if not conv_dir.exists():
            print(f"Error: Conversations directory not found: {conv_dir}")
            sys.exit(1)

        output_dir = Path(args.output_dir) if args.output_dir else conv_dir / "timeline"

        files = list(conv_dir.glob("*.md"))
        # Exclude already converted files and index files
        files = [f for f in files if not f.name.startswith("timeline_")
                 and f.name not in ("INDEX.md", "SUMMARY.md")]

        print(f"Converting {len(files)} conversation files...")

        for i, file in enumerate(files, 1):
            try:
                output_path = convert_file(file, output_dir)
                print(f"[{i}/{len(files)}] {file.name} -> {output_path.name}")
            except Exception as e:
                print(f"[{i}/{len(files)}] Error converting {file.name}: {e}")

        print(f"\nDone! Timeline files saved to: {output_dir}")

    elif args.file:
        input_path = Path(args.file)
        if not input_path.exists():
            print(f"Error: File not found: {input_path}")
            sys.exit(1)

        output_dir = Path(args.output_dir) if args.output_dir else None
        output_path = convert_file(input_path, output_dir)
        print(f"Converted: {input_path.name} -> {output_path}")

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
