# Project Memory Index

This directory is **this project's memory store**, versioned in git so that Leo, teammates, and every agent working in this repo see the same facts.

## Convention

- **One markdown file per fact.** Each project-scoped fact worth remembering — a decision and its rationale, a constraint, a gotcha, context that is not derivable from the code or git history — gets its own file in `.claude/memory/`, named in kebab-case (e.g. `cloudkit-dev-environment-only.md`).
- **One index line per file.** Every memory file gets exactly one entry in the list below: `- [Title](file.md) — short hook`. Never put memory content in this index.
- **Read this index before doing work**, then open the memory files whose hooks look relevant to the task.
- **Write proactively.** When something worth remembering surfaces during a session, save it here without being asked.
- **Keep it true.** If a memory turns out to be wrong or outdated, update or delete that file (and its index line) rather than leaving a stale one alongside a correct one. Before adding a new memory, check whether an existing file already covers it and update that instead of duplicating.
- **Don't record what the repo already says.** Code structure, past fixes, git history, and anything already documented in `AGENTS.md` do not belong here. This store is for the non-obvious.

## Where memories must live

**This directory replaces the agent's built-in memory for this project.** If an agent has a native or global memory feature — Claude Code's `~/.claude/projects/<project>/memory/`, Cursor "memories", a hosted knowledge store, or anything similar — project-scoped memories must **not** be saved there. They go here, in the repo, so they are versioned and visible to everyone.

The only thing that belongs in a native store is a single pointer memory saying that this project's memories live in-repo at `.claude/memory/`, and that future sessions must read and write them here.

Corrections and standing always/never directives go in a separate file: [`.claude/agent-notes.md`](../agent-notes.md).

## Memories

<!-- One line per memory file: - [Title](file.md) — hook -->

_(none yet)_
