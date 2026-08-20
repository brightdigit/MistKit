# Agent Notes

Standing always/never directives and corrections from the human. Agents must read this file at the start of every session before doing work.

## How to maintain

- Append one line per directive **proactively** (without being asked) whenever the human makes a correction or gives an always/never instruction.
- Newest lines at the bottom.
- One line per entry.
- When a directive supersedes an earlier one, update or remove the stale line rather than leaving both.

## Directives

- ALWAYS read `.claude/agent-notes.md` and `.claude/memory/MEMORY.md` at the start of every session before doing work.
- ALWAYS append corrections and always/never directives to `.claude/agent-notes.md` proactively; ALWAYS write project-scoped facts to `.claude/memory/` (with an index line in `MEMORY.md`).
- NEVER store project-scoped memories in a native or global memory system (Claude Code `~/.claude/projects/*/memory/`, Cursor memories, etc.) — use `.claude/memory/` in this repo instead.
