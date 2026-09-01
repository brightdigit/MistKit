# Raw mining output: PR review threads — REMOTE PASS (pre-2026-08-26)

Captured 2026-09-01 from a remote (cloud) agent run in parallel with the local PR sweep in
`2026-09-01-pr-history-mining.md`. UNCURATED. Kept as a SECOND, INDEPENDENT read of the same
corpus — the two agree on the major directives, which raises confidence; this file records only
what it adds or states more precisely.

## Why this pass is worth keeping alongside the local one

METHOD WAS MORE EXHAUSTIVE: 191 closed PRs -> 180 merged -> 163 merged before 2026-08-26. It
harvested EVERY leogdion review comment, issue comment, and review body across all 163 via
`gh api` (12-way parallel) — total human corpus 39 KB across only 36 PRs, small enough to read
IN FULL rather than sample. It then verified each candidate against the current worktree
(.swiftlint.yml, Sources/MistKit/, Tests/) to judge live vs. mechanized vs. superseded.

Its characterization of the corpus: the corrections are TERSE — Leo reviews in short imperative
fragments ("remove this", "use Typed Throws", "why not an initializer"). THE SIGNAL IS IN
REPETITION ACROSS PRs, not in any single long comment.

## Findings NEW or SHARPER than the local pass

### A. The "fix the spec, not the wrapper" corollary has a stronger origin than local found
PR #205, on a hand-edit to `Sources/MistKit/Generated/Types.swift`, Leo verbatim:
  "we should not be manually editing Generated these files. Fix this and add a constitution rule
   to CLAUDE.md"
That is the ORIGIN of the CLAUDE.md rule. The #372 corollary ("why isn't this fixed in the
openapi.yaml?" on ZoneInfo — i.e. don't paper over a SCHEMA defect in the CURATED WRAPPER layer)
is the part still written down NOWHERE. Agent calls this the single most load-bearing item.

### B. Initializer-over-free-function has NINE independent hits, not the ~12-across-7 local count
At least nine distinct instances, with the intended SHAPE visible in the #293 resolution: a local
parsing helper became `MistKit.Environment.init?(caseInsensitive:)` ON THE TYPE ITSELF.
Stated rationale: conversion logic belongs on the DESTINATION type as `init(from:)`, not in a
utilities bag. THIS IS WHY `FieldConversionUtilities` WAS DELETED.
PRs #232 (x2), #293, #372, #134 (QueryFilter, QuerySort), #132.

### C. "Never assume the database" predates #315 — it starts at #204
PR #204: "never assume the `database` - maybe use a switch statement" — EARLIER than the #315
architectural push the local pass found. Verified in code: CloudKitService no longer stores a
database. Partially covered by feedback_no_silent_policy_defaults.md + CLAUDE.md's
PublicAuthPreference section, but the ORIGIN (#315 removed the stored database outright) is the
missing historical context.

### D. NEVER commit scratch/session/plan files; delete them in the PR  *** NEW — local missed this ***
Persistent cleanup demands across five PRs:
  "delete file" (x2) on a `2025-09-19-this-session-is-being-continued...txt` transcript;
  same on `test_signature.swift`, `.claude/PR105-FEEDBACK-TODO.md`,
  `.taskmaster/docs/cloudkit-asset-fix-plan.md`;
  "can we delete this file?" on `.claude/plans/mistdemo-improvements-271.md`;
  "we can delete this" on `WEB_COURIER_SPIKE.md`;
  "do we need this file?" on `test_asset.json`;
  "is this still needed?" on `TESTING_STATUS.md`, `swift-build-issue-proposal.md`.
PRs #105, #273, #381, #232, #204. Agent notes this is VERY current given the agent-generated-
artifact era. Undocumented.
[NOTE FOR REVIEW: this cuts against the `_raw/` holding-pen approach used for these very files.
 Worth deciding explicitly whether `_raw/` is exempt or should be curated-then-deleted.]

### E. NEVER make unrelated incidental changes; revert files the task did not require  *** NEW ***
A cluster of pure reverts in ONE review (#205): "Undo branch name"; "Undo the file change"
(schema.ckdb); "Undo change" (.env.example); "Why change this?" (configuration.md);
"I don't think this change was needed."
DISTINCT from feedback_findings_to_issues_not_code.md — that covers NEW out-of-scope fixes; this
covers INCIDENTAL DRIFT in files the change touched by accident.

### F. PREFER protocols + extensions over `#if os(...)` duplication  *** NEW ***
"use protocols and extensions to unify this"; "let's unify this with protocols and extensions";
"why can't we just make it universal?"; "can we use type aliases to reduce this?"  PR #371.
Undocumented.

### G. Deferred-refactor issues also apply at REVIEW time
"Add a GitHub issue to refactor the server"; "add an issue to refactor this"; "add GitHub issue to
MistKit to make this sharable from MistKit" (x2 — LITERALLY THE ORIGIN OF `setup-mistkit`);
"Let's refactor phases - maybe in the next PR?"; "this isn't working - let's fix in a separate
PR/issue". PRs #287, #205, #204.
feedback_findings_to_issues_not_code.md covers the principle; the recovered detail is that it
applies to REVIEW-TIME suggestions too, and that it produced feedback_setup_action_lives_in_owned_repo.md.

### H. The demo-code force-unwrap carve-out has a sharper scope than local recorded
"I don't think we need to do guard let etc... just force unwrap and try" — on a STATIC HTML
RESOURCE LOADER where failure is a PROGRAMMER ERROR, not a runtime condition. PR #332.
Agent flags: `force_unwrapping` is a SwiftLint OPT-IN rule, so this is an explicit, NARROW carve-out
for non-library code with genuinely-unfailable inputs. Record WITH the scope caveat, never as a
blanket rule. Confidence MEDIUM (in tension with lint config).

## Notable non-directive findings  *** BOTH NEW ***

- **`.claude/docs/mistdemo/operations-auth.md` is DECLARED THE SOURCE OF TRUTH for auth
  documentation** — "verify this is consistent throughout documentation. this is the source of
  truth." (PR #205). That designation appears NOWHERE in CLAUDE.md. The file still exists.
  Cheap, high-value addition to memory.

- **File-splitting guidance lives in an EXTERNAL GIST** — PR #228 review body: "Split files that are
  getting too large. See https://gist.github.com/leogdion/0806c2f41aeb2c77db6a4a846cf13c0f for
  guidance". That gist URL is referenced in NO repo file. If it still resolves it is an UNDOCUMENTED
  STANDARDS DEPENDENCY; if it does not, the guidance is effectively LOST. (The local pass surfaced
  the same gist independently — worth checking whether it still resolves.)

- **`one_declaration_per_file` is NOW LINT-ENFORCED**, so the very frequent "each type and extension
  in it's own file" corrections (#315, #232, #228, #132) are MECHANIZED, NOT LOST. Agent
  deliberately excluded them from its ranked list. Agrees with local pass item 11.

- **NO CloudKit-API misconception corrections exist in the PR record.** The CloudKit facts Leo
  corrected (cloudkit.share casing, metaSyncToken, Zone Dictionary keys) were ALL discovered AFTER
  the memory convention began and are already captured. Pre-2026-08-26 CloudKit discussion is
  DESIGN-shaped, not FACT-CORRECTION-shaped.
  ONE EXCEPTION, agreeing with the local pass: #377 "why does it need to be rounded?" — CloudKit
  rejects a fractional TIMESTAMP with BAD_REQUEST, INCLUDING `LocationValue.timestamp`. CLAUDE.md
  documents scalar .date tagging but NOT that the same rounding applies to the location timestamp.
  TWO INDEPENDENT AGENTS FOUND THIS — highest-confidence recovered API fact in the whole sweep.

## Agent's top recommendations

#3 initializer-over-free-function (nine hits, completely unrecorded), #2 typed throws,
#7 `if case let` / no flattening conveniences, #10 delete scratch files, #13 fix-don't-suppress.
Plus the `operations-auth.md` source-of-truth designation and the LocationValue.timestamp
constraint as cheap high-value memory additions.

## Cross-check against the local pass

Both agents independently converged on: typed throws; initializer-over-conversion-method; magic
strings/numbers to constants; fix openapi.yaml not the Swift; MistKitOpenAPI/Examples boundary
discipline; closure-over-protocol injection; `if case let` over flattening accessors; check-MistKit-
first for Example types; fix-don't-suppress warnings; the demo force-unwrap carve-out; and the
LocationValue.timestamp rounding fact. AGREEMENT ACROSS TWO INDEPENDENT SWEEPS = high confidence.
Only the local pass found: RetryPolicy deliberate removal (#148), client-side record-name generation
reversal (#153), test-suite nesting shape (#287), no-forging-state-in-tests (#296).
Only the remote pass found: items D, E, F above, and both non-directive findings.
