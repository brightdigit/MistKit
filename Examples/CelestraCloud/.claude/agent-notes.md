# Agent Notes

Append-only running log of Leo's corrections and standing always/never directives for this repository.

**How to use this file:**

- **Read it at the start of every session, before doing any work.** It is versioned in git alongside `.claude/memory/MEMORY.md`; together they are the source of truth for how to work in this repo.
- **Append proactively — without being asked.** Whenever Leo corrects something, or gives an "always do X" / "never do Y" instruction, add a line here immediately. Do not wait to be told to remember it.
- **Newest lines at the bottom.** The log reads chronologically, top to bottom.
- **One line per entry.** Keep each directive to a single line: date the entry, state the directive imperatively, and add the reason inline if it is not obvious.
- **Supersede, don't stack.** When a new directive replaces or contradicts an earlier one, edit or delete the stale line rather than leaving both — this file should never contain two rules that disagree.

Format: `- YYYY-MM-DD — <directive> (<why, if not obvious>)`

---

<!-- Append new directives below this line, newest at the bottom. -->
- 2026-08-21 — Never add `.claude/` to `.gitignore` in my repos; the in-repo agent stores (`agent-notes.md`, `memory/`) must stay versioned and visible to teammates. Narrow local-only exceptions like `.claude/settings.local.json` are fine.
