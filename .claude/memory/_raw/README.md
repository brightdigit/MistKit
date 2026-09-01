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

SIX reports: each of three slices was mined TWICE, once locally and once by a remote (cloud) agent,
independently. Where the two agree, confidence is high. Where they disagree, the `-remote` file
records the discrepancy — resolve those before promoting anything.

- `2026-09-01-pr-history-mining.md` — 20 findings from ~191 closed PRs (leogdion review comments).
  Strongest: typed throws, initializer-over-conversion-method, fix-the-spec-not-the-Swift,
  LocationValue.timestamp rounding, RetryPolicy deliberately removed.
- `2026-09-01-pr-history-mining-remote.md` — exhaustive re-read of all 163 pre-cutoff merged PRs
  (39KB of comments, read in full rather than sampled). Adds: never commit scratch/session/plan
  files; revert incidental drift; protocols over `#if os()`; the operations-auth.md source-of-truth
  designation; the external file-splitting gist no repo file references.
- `2026-09-01-issue-history-mining.md` — 12 findings from ~229 closed issues. Strongest: five
  live-API-verified CloudKit facts (/device/ token routing, subscription uniqueness, users/discover
  Apple-side 500, database-scope routing, S2S attribution).
- `2026-09-01-issue-history-mining-remote.md` — confirms all four Tier-1 facts independently. Adds:
  the subscription-delete bare-`{subscriptionID}` response shape; "CloudKit caps `.in()`" is a FALSE
  LEAD; the brittle exact-string duplicate detection; a list of never-resolved open questions.
- `2026-09-01-git-history-mining.md` — 5 process/tooling lessons plus a branch audit.
  *** ITS BRANCH AUDIT IS SUPERSEDED — see the remote file. ***
- `2026-09-01-git-history-mining-remote.md` — READ THIS ONE FIRST. Corrects the branch audit: the
  valuable backup branches are LOCAL-ONLY and unpushed (76 commits on one machine); the remote
  `backup/*` and `archive/*` refs are dead ends holding nothing unique. Also: release squashes have
  EMPTY bodies — the surviving seam is the individual PR-squash commits between releases.

## Two loose ends flagged by the agents

1. Issue #387 cites a memory file `project_cloudkit_subscription_uniqueness.md` that was never
   created — a CONFIRMED loss, not a judgment call.
2. The CodeFactor GitHub App still auto-commits (00d74ba, 2026-09-01) even though `.codefactor.yml`
   was removed from HEAD. Removing the config did not disconnect the App.
3. 76 commits live only on this laptop, on four unpushed branches:
   `backup/v1.0.0-beta.4-pre-history-cleanup` (53), `-pre-align` (14), `-pre-squash` (8),
   `docs/talk-prep-archive` (1). Push them or they are one disk failure from gone.

## Discrepancies between the paired passes — resolve before promoting

- Issue #192 root cause: local pass says it was NOT recorded in the thread; remote says it WAS.
- `users/caller` routing: local reports success on private+web-auth; remote reports HTTP 421 on
  public needing fresh auth. Reconcile against a live container.
- The `ASSETID` tagging for re-referenced assets was never live-confirmed, yet `openapi.yaml`
  appears to have been built on that guess.
