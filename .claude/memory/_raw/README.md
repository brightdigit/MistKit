# `_raw/` — uncurated mining output

These files are RAW subagent reports from a 2026-09-01 archaeology pass that reconstructed
corrections and API facts predating the `.claude/memory/` convention (which began 2026-08-26,
commit c7fc84e — the repo's first commit is 2020-09-03, so ~6 years went unrecorded).

They are NOT memory files and are NOT indexed in `MEMORY.md`. They are a holding pen so the
findings survive until a human reviews them and promotes the worthwhile ones into properly
named `feedback_*` / `reference_*` / `project_*` memory files.

Provenance: findings were produced by agents reading GitHub PR threads, closed issues, git
history, and — added 2026-09-01 in a second wave — **conversation transcripts**. Each item carries
a source (PR/issue number, commit SHA, or session id + timestamp) and the agent's own confidence
rating. TREAT THEM AS UNVERIFIED until spot-checked — they have not been confirmed by a human.

## Files

NINE reports across TWO waves.

**Wave 1 — artifact slices (git / issues / PRs).** Six reports: each of three slices mined TWICE,
once locally and once by a remote (cloud) agent, independently. Where the two agree, confidence is
high. Where they disagree, the `-remote` file records the discrepancy — resolve those before
promoting anything.

**Wave 2 — conversation slices (added 2026-09-01).** Three reports mining what none of wave 1 could
see: the exchange itself, and what the AI had just done to earn a correction. Wave 1's own remote
issue pass diagnosed the gap — *"leogdion correcting a proposed approach IN COMMENTS: almost none…
THE SUBSTANTIVE CORRECTIONS LIVE IN ISSUE BODIES HE AUTHORED"* — the corrections happened in chat.
These are mined ONCE each, not paired, so they carry less corroboration weight than wave 1.

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

### Wave 2 — conversation transcripts

- `2026-09-01-cursor-transcript-history-mining.md` — **the richest of the three.** 46 Cursor
  composers / 142 human-turn bundles, 2025-07-08 → 2025-12-02, the OpenAPI-rewrite era, with BOTH
  voices. 17 failure modes. Headline: 57% of AI turns immediately preceding a human message claimed
  success, and 46% of human messages were corrections. Corrects an earlier survey that over-counted
  this store as "72 composers, 5,970 bubbles, 44.7 MB, from 2025-01-27."
- `2026-09-01-claude-transcript-history-mining.md` — 8 days (2026-08-25 → 09-01), 67 signal records.
  **Scope-limited by construction: 53 Edit/Write calls, 47 into plan files and 6 into Swift.** It
  can speak to planning and shell usage, NOT to Swift authorship. Partly self-observing.
- `2026-09-01-prompt-tail-history-mining.md` — 956 prompts, 2025-10-20 → 2026-09-01, from
  `~/.claude/history.jsonl`. **ONE VOICE ONLY** — no assistant side, so no causes. All findings cap
  at SPECULATIVE.
- `recovered/` — four memory files the wave-1 archaeology declared lost. See below.

## Two loose ends flagged by the agents

1. Issue #387 cites a memory file `project_cloudkit_subscription_uniqueness.md` that was never
   created — a CONFIRMED loss, not a judgment call.
2. The CodeFactor GitHub App still auto-commits (00d74ba, 2026-09-01) even though `.codefactor.yml`
   was removed from HEAD. Removing the config did not disconnect the App.
3. 76 commits live only on this laptop, on four unpushed branches:
   `backup/v1.0.0-beta.4-pre-history-cleanup` (53), `-pre-align` (14), `-pre-squash` (8),
   `docs/talk-prep-archive` (1). Push them or they are one disk failure from gone.

## Discrepancies between the paired passes — resolve before promoting

- ~~Issue #192 root cause: local pass says it was NOT recorded in the thread; remote says it WAS.~~
  *** RESOLVED 2026-09-01 from PR #205's diff. BOTH PASSES WERE HALF RIGHT. ***
  The issue THREAD records no root cause — leogdion's only comment is "Completed and verified in
  codebase" (local pass correct). The issue BODY lists "MistKit Serialization Issue" as candidate
  #2 of 3 under "Analysis", as a hypothesis, never a conclusion (the remote pass's basis). The local
  pass's own note was exactly right: "The wire-format detail lives in the PR, not the issue."
  ACTUAL ROOT CAUSE (PR #205, merged 2026-04-15): IN/NOT_IN serialized list values with NO `type`
  tag, so CloudKit could not determine the element type. The fix adds
  `_type: cloudKitListType(for: values)` → STRING_LIST / INT64_LIST / …, plus the `type` enum on
  `FieldValueRequest` in openapi.yaml. `ListValuePayload` was ALREADY in use and was never the
  problem. Live at `Sources/MistKit/Models/Queries/FilterBuilder/FilterBuilder.swift:144` today.
  *** AND IT EXPOSES A DOC BUG: `AGENTS.md:375` claims the alpha.5 fix "ensures the correct `value`
  key structure is used". The diff shows the `value` line is UNCHANGED. That sentence is wrong and
  contradicts the same file's correct line 133. Fix before it outlives everyone who remembers. ***
  Confirms the remote issue pass's separate finding that "CloudKit caps .in()" IS A FALSE LEAD —
  the issue body led with that wrong hypothesis, and size was ruled out empirically at 97/20/2.
- `users/caller` routing: local reports success on private+web-auth; remote reports HTTP 421 on
  public needing fresh auth. Reconcile against a live container.
- The `ASSETID` tagging for re-referenced assets was never live-confirmed, yet `openapi.yaml`
  appears to have been built on that guess.

### Wave 2's attempt on these

- **#192 is NOT resolvable from any surviving conversation record.** Searched the full Cursor corpus
  for `ListValuePayload|Unexpected input|QueryFilter\.in|BadRequestException` (0 matching turns) and
  the 956-prompt tail (2 matches, neither related). The debugging happened in Claude Code around
  v1.0.0-alpha.5 (Nov 2025), whose transcripts were rotated away. Only a PR/live-container check can
  settle it.
- `users/caller` and `ASSETID` are unchanged — both need a live container, not an archive.
