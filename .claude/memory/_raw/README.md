# `_raw/` — uncurated mining output

These files are RAW subagent reports from a 2026-09-01 archaeology pass that reconstructed
corrections and API facts predating the `.claude/memory/` convention (which began 2026-08-26,
commit c7fc84e — the repo's first commit is 2020-09-03, so ~6 years went unrecorded).

They are NOT memory files and are NOT indexed in `MEMORY.md`. They are a holding pen so the
findings survive until a human reviews them and promotes the worthwhile ones into properly
named `feedback_*` / `reference_*` / `project_*` memory files.

Provenance: findings were produced by agents reading GitHub PR threads, closed issues, and git
history. Each item carries a source (PR/issue number or commit SHA) and the agent's own
confidence rating. TREAT THEM AS UNVERIFIED until spot-checked — they have not been confirmed
by a human.

## Files

- `2026-09-01-pr-history-mining.md` — 20 findings from ~191 closed PRs (review comments from
  leogdion). Strongest: typed throws, initializer-over-conversion-method, fix-the-spec-not-the-Swift,
  LocationValue.timestamp rounding, RetryPolicy deliberately removed.
- `2026-09-01-issue-history-mining.md` — 12 findings from ~229 closed issues. Strongest: the five
  live-API-verified CloudKit facts in Tier 1 (/device/ token routing, subscription uniqueness,
  users/discover being an Apple-side 500, database-scope routing, S2S attribution).
- `2026-09-01-git-history-mining.md` — 5 process/tooling lessons plus a BRANCH AUDIT recording which
  backup/archive branches hold real unsquashed history and which are dead ends. Useful for any future
  archaeology.

## Two loose ends flagged by the agents

1. Issue #387 cites a memory file `project_cloudkit_subscription_uniqueness.md` that was never
   created — a CONFIRMED loss, not a judgment call.
2. The CodeFactor GitHub App still auto-commits (00d74ba, 2026-09-01) even though `.codefactor.yml`
   was removed from HEAD. Removing the config did not disconnect the App.
