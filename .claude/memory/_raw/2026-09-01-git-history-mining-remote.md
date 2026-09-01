# Raw mining output: git history — REMOTE PASS (2020 -> 2026-08-25)

Captured 2026-09-01 from a remote agent, run in parallel with the local git sweep in
`2026-09-01-git-history-mining.md`. UNCURATED.

*** THIS PASS CORRECTS THE LOCAL PASS'S BRANCH AUDIT. Read this section first. ***

## CRITICAL: the backup branches are LOCAL-ONLY and were never pushed

The remote agent cloned from origin and got 305 commits across all refs, 24 tags — and found that
NONE of the backup/* branches named in the brief exist on the remote. It could only see what was
pushed. Verified independently in the local worktree on 2026-09-01:

  backup/v1.0.0-beta.4-pre-align            5cae86f   LOCAL ONLY   14 commits not on main
  backup/v1.0.0-beta.4-pre-history-cleanup  29e40b4   LOCAL ONLY   53 commits not on main
  backup/v1.0.0-beta.4-pre-squash           e55cc67   LOCAL ONLY    8 commits not on main
  docs/talk-prep-archive                    aa9e36d   LOCAL ONLY    1 commit  not on main

76 commits exist on ONE MACHINE ONLY. Per feedback_check_merge_strategy_before_release_deletions.md,
with squash merges the archive branch is load-bearing — this is exactly that case.
=> PUSH THESE, or they are one disk failure from gone.

## The local pass's branch audit was WRONG about what is on the remote

Local pass called origin/v1.0.0-beta.4-backup and archive/talk-prep-2026-05-17 "the single richest
source." The remote agent, reading the actual remote, found:
  - archive/talk-prep-2026-05-17 : 121 commits, but `git log --not main` shows EVERY ONE is already
    on main. It is a POINTER, not preserved unsquashed history. DEAD END.
  - origin/v1.0.0-beta.4-backup  : nothing unique vs main. DEAD END.
  - origin/code-review-fixes     : exists; nothing unique of substance.
  - origin/v1.0.0-beta.5, 407-mistkitconfiguration, 454-zone-aware-writes,
    462-web-auth-token-rotation : live, unsquashed, genuinely rich — but ALL post-2026-08-26,
    out of scope for this archaeology.
The two agents were looking at different ref sets (local worktree vs remote), which is why they
disagree. The LOCAL branches are the ones with unique history; the REMOTE backup branches are empty.

## Also corrects the brief's premise about squashed bodies

The RELEASE squashes preserved NOTHING: d11c6c5 (beta.1), 38f0d77 (alpha.5), 5a58120 (beta.3),
7fe8090 (beta.2), bce1f23 all have COMPLETELY EMPTY BODIES — subject line only. 705e461 (alpha.4)
and 0375d09 (beta.4) carry only a bulleted PR list.
THE REAL DETAIL SURVIVES IN THE INDIVIDUAL PR-SQUASH COMMITS BETWEEN RELEASES. That is the seam
for any future archaeology.

## Durable lessons (those not already in the local pass)

### 1. Treat a spec/behavior mismatch as BEHAVIOR until a live run says otherwise. HIGH confidence.
Best-evidenced lesson in the repo, because the reversal happens INSIDE ONE PR. In 91f04f3/9c5b292
(#443) the first commit rewords the zones/changes syncToken description, explicitly asserting
"The key stays `syncToken` (#430); only the prose is corrected." A LATER COMMIT ON THE SAME BRANCH
runs a live container round-trip and reverses it: sending `syncToken` returned all 40 zones again
(silently ignored); `metaSyncToken` returned 0 (honored). Its own words: "This supersedes the
description-only wording fix in the previous commit, WHICH ASSUMED THE MISMATCH WAS DOCUMENTATION
RATHER THAN BEHAVIOR." Pagination had never worked.
Same pattern in b3626c0: discoverAllUserIdentities() implemented from CloudKitJS, then live
verification on 2026-05-08 returned HTTP 500 -> marked @available(*, unavailable) pending #28.
Still unavailable; grep finds no trace in current Sources/, i.e. it never came back.
CLAUDE.md's metaSyncToken paragraph covers the FACT; the GENERALIZABLE RULE is written nowhere.

### 2. Guard generated output with a reproducibility CI check — don't trust a bot to stay out.
Same CodeFactor revert war the local pass documented, but with the durable OUTCOME named: a
`check-generated-openapi.yml` CI job that regenerates and runs `git diff --exit-code`. That job,
not the config exclusion, is the actual fix. Recurrence is the tell: "[CodeFactor] Apply fixes"
commits appear in 2020 (7c61782, 0fa344e) and 2026 (16b0d83) alike.

### 3. A config key that resolves to NOTHING fails OPEN and looks green. HIGH confidence, hit twice.
1e9f15e: CelestraCloud pinned MISTKIT_BRANCH to `1.0.0-beta.3` — a TAG, not a branch — and since
git ls-remote matches tags, it resolved to already-released MistKit on main. "Its builds passed
without ever compiling against the beta.4 code they are meant to validate." BushelCloud was missing
setup-mistkit entirely, so all 17 build jobs failed.
SAME FAILURE CLASS in 5338914: container.identifier resolved to CLOUDKIT_CONTAINER_IDENTIFIER, which
NOTHING EVER SET — "the value CI passed was silently ignored and every run fell back to the built-in
default. It only went unnoticed because that default equals the secret's value."
project_mistkit_branch_pin_resolves_tags.md records the ONE INSTANCE; the GENERAL lesson is broader.

### 4. Stop guessing at toolchain-version incompatibilities; bisect or document defeat. HIGH conf.
The most spectacular churn in the repo. On ONE DAY (2025-12-16), ~20 sequential commits attacked
Android coverage by guessing Swift snapshots: 2424ea1 (November snapshot) -> 1131bda ("only
available dev snapshot" Aug 28) -> 97a79a2 ("correct latest" Aug 14) -> 0176585 (nightly-6.2 format)
-> 0bbd0ef ("stable 6.2 for guaranteed LLVM v9") -> 93d3cdd (6.1.1). Interleaved: path guesses
(a967aa7, e740bce, a428978), tool-source guesses (53afa4e NDK llvm-cov -> d5aa0ca Swift toolchain
llvm-cov -> 6dbea03 let Codecov auto-discover -> back again), and 8731f71 "debug: add file listing".
Ends in 5fd3751 "document Android coverage limitation" + b487645 cataloguing "7 different Swift
version attempts". .github/workflows/ on main HAS NO ANDROID WORKFLOW TODAY — the line was abandoned.
NOTE: 0121ab2 is the ONE commit that broke the pattern by doing research first ("Research showed we
were missing the llvm-profdata merge step") AND IT PRODUCED THE ONLY REAL INSIGHT.
Nothing about this is in memory.

### 5. Auth/database coupling was designed wrong THREE times before per-call resolution landed.
b3626c0 (#315) shows four successive architectures in its own commit list:
  (a) DatabaseCredentials enum baking in a public=>S2S / private=>webAuth assumption
  (b) replaced by orthogonal AuthenticationCredentials + DatabaseConfiguration
  (c) review feedback removes DatabaseConfiguration entirely; service keeps a `database` property
      with per-call override
  (d) "CloudKitService no longer carries `database`" — fully per-call via
      makeTokenManager(for:requiresUserContext:); MistKitClient.swift deleted as obsolete
A FIFTH adjustment in the same PR: zone ops default to .private because "the public database only
contains _defaultZone, making .public a degenerate default."
Casualty recorded in the body: CredentialsValidationTests DELETED because it "asserted init-time
validation that no longer exists."
CLAUDE.md documents the endpoint (PublicAuthPreference, no default on database:) but not that three
coupled designs were tried and each failed the same way — which IS the argument for
feedback_no_silent_policy_defaults.md.

### 6. Same-day fix-after-feature on CI/manifest files is the dominant churn signature.
95d4942 concatenates FIVE sequential self-corrections to one workflow (plugin_marketplaces short
format -> full git URL -> back; additional_permissions -> claude_args --allowedTools; add Swift build
permissions -> remove them because "the Ubuntu runner doesn't have Swift installed").
And cb27cef "Disable enhanced compiler checking flags" -> 2d620fc "Add Unsafe Flags Check (#188)" ->
98b8e6e (2026-09-01) trims manifests to InternalImportsByDefault only.
Through-line: WORKFLOW AND MANIFEST CHANGES WERE CONSISTENTLY LANDED UNVERIFIED AND CORRECTED IN THE
NEXT COMMIT. Observation is HIGH confidence; actionable lesson MODERATE.

## Honest assessment from the agent

"The history is thinner than the brief assumed, in a specific way: the squash-merge damage is worse
than described, because the RELEASE squashes preserved nothing at all (empty bodies), while the
intermediate PR squashes preserved a great deal. So the archaeology worked, but via a different seam
than expected."
2020-2021 (0.x) era yielded NOTHING. The 2023 gap (a915669, e05c9f7) is two orphan commits with no
substance. REAL SIGNAL STARTS AT 2025-07 WITH THE OPENAPI REWRITE.
