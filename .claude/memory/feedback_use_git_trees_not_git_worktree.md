---
name: feedback_use_git_trees_not_git_worktree
description: Create and remove worktrees in this repo with `git trees add/rm`, never raw `git worktree`
metadata:
  type: feedback
---

Always manage worktrees in this repo with **`git trees`** (brightdigit's tool, installed
at `~/.local/bin/git-trees`) — never raw `git worktree add` / `git worktree remove`.

**Why:** On 2026-09-01, while planning the release runbook, I proposed
`git worktree add ../release-tooling -b release-tooling main`. Leo corrected me: "use git
trees instead of git worktree." The project is a bare-repo + sibling-worktree layout
(`MistKit.git/` alongside `main/`, `v1.0.0-beta.5/`, …) that `git trees` created and
maintains; raw `git worktree` skips the upstream/push wiring and the layout metadata.

**How to apply** (`git trees --help` for the full list):

| Task | Command |
|---|---|
| New branch + worktree off a base | `git trees add <branch> [base]` |
| Without pushing to origin | `git trees add <branch> [base] --no-push` |
| Print path (to `cd`) | `git trees add <branch> --print-path` |
| List worktrees | `git trees list [--json]` |
| Remove worktree + branch | `git trees rm <branch\|path> --apply` |
| Sweep merged/gone branches | `git trees clean --merged \| --gone [--apply]` |
| Fetch / update worktrees | `git trees sync [worktree] [--pull]` |

`add` creates the branch on origin via `git push -u origin HEAD` unless `--no-push` (or
`TREES_NO_PUSH`) is set, and prints the worktree path but cannot `cd` your shell.
Related: [[feedback_never_git_stash_multiworktree]], [[project_beta4_worktree_layout]].
