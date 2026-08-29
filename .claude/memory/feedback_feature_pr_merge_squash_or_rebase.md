---
name: feedback_feature_pr_merge_squash_or_rebase
description: Feature-branch PRs merge via squash or rebase only — never merge commits; 1 commit → rebase, multiple → squash
metadata:
  type: feedback
---

When merging a **feature-branch PR** into its base (e.g. into `v1.0.0-beta.4` or `main`), **never** use a merge commit (`gh pr merge --merge` / the green "Create a merge commit" button).

**Rule:**
- **1 commit** on the PR → **rebase** (`gh pr merge --rebase`)
- **Multiple commits** → **squash** (`gh pr merge --squash`)

**Examples (2026-08-28):** #440 (3 commits) → squash; #442 (1 commit) → rebase; #443 (7 commits) → squash.

**Why:** Feature history should land as a linear tip on the base. Merge commits are for integrating long-lived / release branches, not feature PRs. Squash collapses WIP commit noise; rebase of a single commit preserves the author's message without a merge bubble.

**How to apply:** Before merging, count commits with `gh pr view <n> --json commits --jq '.commits|length'`. Pick `--rebase` or `--squash` from that count. Do not default to `--merge` because a sibling PR used it.

Related: [[feedback_check_merge_strategy_before_release_deletions]] (squash/rebase also means deleted-file preservation needs an archive tag).
