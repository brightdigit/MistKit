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
- NEVER run bare `git stash`/`git stash pop`/`git stash drop` in this repo — the stash stack is shared across ALL worktrees, so a pop in one worktree can bury or restore another branch's WIP; commit to your own branch instead.
- CI: in-development Swift branches (e.g. 6.4 snapshots) belong IN the `build-ubuntu` matrix as a swift entry carrying an `image` override (ConfigKeyKit pattern: `{"version":"6.4","image":"swiftlang/swift:nightly-6.4.x"}` plus a `container:` fallback expression) — NEVER as a separate job. Supersedes the earlier "no nightly toolchains" directive.
- Repo-wide CI version bumps (Xcode/simulator/toolchain) DO extend into the `Examples/` subrepos — update BushelCloud and CelestraCloud in the same pass rather than deferring them to their own repos.
- Follow sibling brightdigit repos (e.g. ConfigKeyKit) for current CI workflow shape before inventing a new one.
- Feature-branch PRs: NEVER merge-commit. ALWAYS rebase if the PR has exactly 1 commit (`gh pr merge --rebase`); ALWAYS squash if it has 2+ commits (`gh pr merge --squash`). Count commits before merging.
- ConfigKeyKit#8 is merged to main but not tagged: MistKitConfiguration may pin `branch: "main"` for draft integration only. NEVER mark MistKitConfiguration#1 or MistKit#455 merge-ready until ConfigKeyKit is tagged and MistKitConfiguration's published Package.swift uses only `from:` tags (no branch/revision/path).
- MistDemo keeps its own `resolveBool` over `ConfigReader.bool` until ConfigKeyKit's boolean fix is tagged *and* re-verified — do not "simplify" it into ConfigKeyKit `read(_:)`.
