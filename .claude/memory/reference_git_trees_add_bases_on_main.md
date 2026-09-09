---
name: reference_git_trees_add_bases_on_main
description: "git trees add branches from main regardless of which worktree you run it in; reset onto the intended base immediately after"
metadata:
  node_type: memory
  type: reference
---

`git trees add <branch>` creates the new branch from **`main`**, not from the
branch of the worktree you invoke it in. It also pushes that `main`-based commit
to `origin/<branch>` right away (unless `--no-push`).

**Why:** Running `git trees add claude-docs-consolidation` from the
`v1.0.0-beta.5` worktree produced a tree at `main` (687b532) — 15 commits behind,
with 23 files of `.claude/` drift. The intended base was 3708e09. Nothing warns
about this; the output just says "Preparing worktree (new branch …)" and the
drift is silent until you diff.

**How to apply:** After `git trees add` from a non-`main` base, immediately
`git reset --hard origin/<intended-base>` and confirm with
`git log --oneline HEAD..origin/<intended-base> | wc -l` (want 0). Because the
stale commit is already on the remote, the first real push needs
`--force-with-lease`. Related: [[feedback_use_git_trees_not_git_worktree]],
[[project_beta4_worktree_layout]].
