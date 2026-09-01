# Raw mining output: git history + backup branches (2020 -> 2026-08-25)

Captured 2026-09-01. Source: subagent sweep of git history, squashed release-commit bodies, and all
backup/archive branches. UNCURATED — raw agent report, kept so findings survive.

AGENT'S TOP-LINE CAVEAT: the history is THINNER than hoped for API-design reversals. Most CloudKit
wire-format lore (metaSyncToken, FieldValue asymmetry, HTTP/2 421, zone dictionary, /device/ token
routing, subscription uniqueness) was ALREADY harvested into CLAUDE.md, .claude/memory/, and
.claude/docs/QUICK_REFERENCE.md. What git history UNIQUELY adds is PROCESS/TOOLING churn, not
protocol knowledge.

## 1. Never let the CodeFactor bot auto-commit into generated OpenAPI sources — it breaks
   regeneration reproducibility. Confidence HIGH — best-evidenced arc in the repo.

Bot commits (61235b5, 18af6a6, bf63ad2, ffcd934 "[CodeFactor] Apply fixes") reordered imports in
Sources/MistKitOpenAPI/, whose output must match ./Scripts/generate-openapi.sh byte-for-byte.
FOUR hand reverts in ~24h: abaa69b, d9fa5cb, a974331, plus fc85a83 ("Reverts CodeFactor bot commit
18af6a6 which broke OpenAPI reproducibility CI") and 25fe6ad ("Revert ffcd934 so OpenAPI output
matches ./Scripts/generate-openapi.sh").
The exclusion took THREE attempts: 5cae86f (2026-07-01) tried a glob; fc85a83 found the non-working
`Sources/MistKitOpenAPI/**` glob needed EXPLICIT FILE PATHS, plus a new .cfduplication.yml because
duplication analysis graded Types.swift F with 1,680 issues. Legitimate findings split off
separately (faab150, 2d570f4), then the tool was dropped: 39ae6f4 "Remove CodeFactor config, badge,
and bot allowlist."

*** LIVE CAVEAT FOR THE HUMAN: .codefactor.yml is gone from HEAD, but THE BOT STILL COMMITS.
    00d74ba (2026-09-01, "[CodeFactor] Apply fixes", deletes a Package.swift line) sits on
    v1.0.0-beta.5, 462-web-auth-token-rotation, and code-review-fixes. Removing the config did NOT
    disconnect the GitHub App. ***

## 2. Rewriting history (squash, force-push, re-tag) silently breaks git-subrepo parents and
   MISTKIT_BRANCH pins — plan the repair INTO the rewrite. Confidence HIGH — recurred 3x, same cause.

- 01dcfd1 "repoint subrepo parents to post-squash commits" — "After squashing the subrepo history,
  the recorded .gitrepo parents referenced dead pre-squash SHAs."
- 0203ac5 + 9bfc079 "fix {Bushel,Celestra}Cloud subrepo parent to a live ancestor (recovery)" —
  "no longer reachable after the upstream mistkit branch was force-pushed and beta.4 was realigned
  onto main."
- bdc0dbf — "The history rewrite that re-staged docs/ for beta.3 replaced the MistKit v1.0.0-beta.2
  tag with 1.0.0-beta.2 (no v-prefix). setup-mistkit's git ls-remote then resolves nothing and falls
  back to a branch: pin, so SwiftPM fails."

Adjacent to existing memories feedback_check_merge_strategy_before_release_deletions and
project_mistkit_branch_pin_resolves_tags, but NEITHER covers the subrepo-parent breakage — that is
the new, thrice-repeated part.

## 3. CI infra bumps must be validated INSIDE the Linux Swift container, not just on the runner —
   newest-version-is-better reverses. Confidence HIGH — clean bump -> revert -> re-fix -> stick cycle.

eaf26e3/#252 bumped actions/checkout to @v6. 0de629a ("CI fixups round 2: revert checkout to v4") —
"@v6 fails inside Linux Swift Docker containers with 'The following required dependencies are
missing: curl' — the swift:6.x images are minimal... This walks back part of #252 but the bump wasn't
load-bearing." Then 194ae80 "Restore checkout@v6, install curl in containers" found the REAL fix:
install curl+ca-certificates as the first step. Durable — HEAD runs checkout@v6 and both
MistKit.yml/MistDemo.yml still carry the curl install.

SAME COMMITS, visionOS version: pin dropped (47beae9), re-enabled with download-platform: true
(194ae80), then commented out (0de629a) — "-downloadPlatform visionOS does not reliably populate it."
STILL commented out on HEAD, i.e. the optimistic re-enable was wrong TWICE.
Related-but-distinct from feedback_ci_swift_matrix.

## 4. Strict/experimental compiler flags in Package.swift are a recurring boomerang — enable only
   flags the whole matrix sustains. Confidence MEDIUM-HIGH.

e05c9f7 (2023) added Swift 6 flags -> 9db8fa0/cb3527e (2025) expanded unsafeFlags + experimental
features -> cb27cef (2025-12-08) "Disable enhanced compiler checking flags" commented them out ->
they RETURNED -> 98b8e6e (2026-09-01) "Trim Package.swift swift settings to InternalImportsByDefault
only... Remove experimental features and unsafeFlags from all manifests."
Mid-cycle collateral in e96c33f's body: "11 unused `public import` lines demoted to `internal` (the
warnings-as-errors regression flagged in the review)".
NOTE: unsafeFlags also blocks a package from being depended on BY TAG.

## 5. Test doubles built on InMemoryProvider-style fakes hid real config bugs for months — build
   doubles on the REAL provider stack. Confidence MEDIUM-HIGH.

914ac2e: "Rebuild the Bushel test double on the real providers instead of InMemoryProvider. The
double matched keys literally and served only the stored case, so it diverged from production on key
normalization and numeric coercion. It also stored bare flags as .string("true"), MASKING THAT
VALUELESS FLAGS NEVER RESOLVED through the real CLI provider — a gap that predates this change."

The masked bugs were substantial:
- --zone-wide, --numbers-as-strings, --fetch-root-record only worked as `--flag true` (5338914)
- --cloudkit-key_id vs --cloudkit-key-id meant documented flags never resolved AND SECRET REDACTION
  NEVER MATCHED, so a private key passed by flag was NOT MARKED SECRET
- CLOUDKIT_CONTAINER_IDENTIFIER was read while CI set CLOUDKIT_CONTAINER_ID — "the value CI passed
  was silently ignored... It only went unnoticed because that default equals the secret's value."

Caveat: these commits are 2026-08-31, just past the cutoff, but they diagnose bugs latent for months.

## Branch/tag audit — where unsquashed history actually lives

USEFUL:
- origin/v1.0.0-beta.4-backup AND backup/v1.0.0-beta.4-pre-history-cleanup (identical, 53 commits off
  main) — THE SINGLE RICHEST SOURCE. Sole preserve of the CodeFactor revert war and the beta.4
  fine-grained endpoint commits that 0375d09 squashed away.
- archive/talk-prep-2026-05-17 (30 off main) — best for the beta.1 era: the database: per-call
  refactor, CI revert cycle, doc-sync commits.
- backup/mistkit-20260821 (54 off main) — ConfigKeyKit adoption and the MistKit-pin/tag failure (bdc0dbf).
- backup/v1.0.0-beta.4-pre-squash (8 off main) — small but holds the subrepo-parent recovery commits.
- origin/code-review-fixes (14 off main) — post-cutoff, but confirms which lessons stuck.

DEAD ENDS:
- backup/47-401-stash — literally a git stash (index on.../untracked files on...); 10 commits, all
  duplicated elsewhere. No messages.
- backup/v1.0.0-alpha.1-20260821 / -post-merge- (8-9 commits) — CelestraCloud-side README/RSS-workflow
  commits, unrelated to MistKit lessons.
- backup/mistkit-pre-phase4-20260821 — IDENTICAL to backup/mistkit-20260821; no unique content.
- backup/v1.0.0-beta.4-pre-align — subset of the beta.4 backup.
- ALL 2020-2021 history (0.0.1-0.2.4, ~60 commits) — pre-OpenAPI MKDatabase architecture, entirely
  superseded by the 2025 rewrite. One-liner messages. NO DURABLE LESSONS; DON'T SPEND TIME HERE.

ON SQUASHED BODIES: less productive than expected. d0803e9 (alpha.1) and 705e461 (alpha.4) yield only
bare PR title lists; 5a58120, 7fe8090, 38f0d77 have EMPTY bodies. Only bff0382 and 705e461 carry
detail. THE BACKUP BRANCHES, NOT THE SQUASH BODIES, are where beta-era history survived.
