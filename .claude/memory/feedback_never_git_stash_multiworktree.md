---
name: feedback_never_git_stash_multiworktree
description: Never use git stash in this multi-worktree repo — the stash stack is shared across worktrees and silently cross-contaminates branches
metadata:
  type: feedback
---

**Never** run bare `git stash`, `git stash pop`, or `git stash drop` in the MistKit repo. Commit to your own branch instead (amend or fixup later if the commit was provisional).

**Why:** MistKit is developed as multiple worktrees off one bare repo at `/Users/leo/Documents/Projects/MistKit/MistKit.git` (see [[project_beta4_worktree_layout]]). The stash stack is **repo-global, not per-worktree**. So `git stash pop` in worktree A pops whatever is on top of the shared stack — which may be a *different branch's* WIP saved from worktree B. This actually happened on 2026-08-20: an agent in `wt-41-42-records-resolve-accept` popped the `47-401-change-tracking-endpoints` agent's ~2700-line WIP into its own tree, burying its own work, while the change-tracking worktree was left polluted with sharing files it didn't own. Nothing was lost, but recovery needed `git fsck` to find an unreachable commit.

The failure is silent — `git stash pop` reports success — and it corrupts a *sibling agent's* work, so the agent that caused it may never see the damage.

**How to apply:** set changes aside with a commit on your own branch. To test whether a lint/test failure is pre-existing, check out the base commit in a *separate* throwaway worktree rather than stashing. If you find a stash that isn't yours, do not drop it — tag it (`git tag -m … backup/<branch>-stash <sha>`) so it survives, and tell its owner.
