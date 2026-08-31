# Handoff — Issue #407 (MistKitConfiguration)

**Worktree:** `~/Documents/Projects/MistKit/407-mistkitconfiguration`
**Branch:** `407-mistkitconfiguration` → `origin/407-mistkitconfiguration` (3 ahead, 0 behind — clean fast-forward)
**PR base:** `v1.0.0-beta.5` (not `main` — milestone base, per `project_beta4_worktree_layout`)
**Status:** PR 1 (unify) complete and committed locally, **nothing pushed**. PR 2 (extract) not started.

---

## TL;DR — what to do next

1. Push the branch and open PR 1 (commands in [Commit & push](#commit--push)).
2. Push the two subrepos (`git subrepo push` — outward-facing, deliberately left to you).
3. When ready for PR 2: create the `brightdigit/MistKitConfiguration` repo, then see [PR 2](#pr-2--extraction-not-started).

Nothing is blocked on me. The working tree is clean and all tests pass.

---

## Why the issue changed shape

#407 as written proposes extracting five things into a new package. Verifying each against the code showed most no longer hold:

| #407 claim | Reality |
|---|---|
| Blocked by ConfigKeyKit#1 shipping a `ConfigKeyKitConfiguration` package | Closed 2026-06-20 — the bridge shipped **in dep-free core** as `ConfigValueReading` (tag `1.0.0-beta.2`). That package never existed. |
| `Environment` parsing duplicated in all three examples | MistKit already ships `Environment.init?(caseInsensitive:)`; MistDemo already used it. The three differed on **policy** (Celestra degraded silently; the others threw), not spelling. |
| `Database` parsing to extract "from MistDemo" | Exists in exactly one place, and encodes *MistDemo's* credential policy (`"public"` → `.prefers(.serverToServer)`). Sharing it would violate `feedback_no_silent_policy_defaults`. |
| Credential types to "generalize from MistDemo" | `ServerToServerCredentials`, `APICredentials`, `PrivateKeyMaterial` are **already public MistKit types**. |
| A `CloudKitService`-from-config factory | MistKit already ships `CloudKitService(containerIdentifier:credentials:environment:)`. Both examples were just on the legacy path. |

**So the order was inverted:** delete what already exists upstream and converge the survivors *first* (PR 1), then extract what's genuinely identical (PR 2). Extracting first would have packaged the code PR 1 deletes.

**Decisions you made along the way:** separate `brightdigit/MistKitConfiguration` repo (not a MistKit product); 2 stacked PRs; 64-hex `KeyIDValidator` is authoritative; dash-case key bases.

> ⚠️ I reversed one of my own findings mid-flight. I first reported Celestra's env vars as broken, reasoning from `StandardNamingStyle` without testing the provider consuming it. Testing showed the opposite — **Bushel** was broken. Your original "match Bushel exactly" answer was based on my incorrect report, which is why I re-asked before coding. The final direction is dash-case.

---

## PR 1 — unify (done, unpushed)

Three commits:

```
88d9f0b docs(memory): record ConfigKeyKit findings from #407 verification
15329ff refactor(examples): unify credential model on MistKit's Credentials API
914ac2e refactor(examples): adopt ConfigKeyKit ConfigValueReading; fix Bushel CLI flags
```

40 files, +842 / −623 (CelestraCloud 13, BushelCloud 23, `.claude/` 4).

### What changed

- **~180 lines of duplicated `read(_:)` glue deleted** from both loaders, replaced by ConfigKeyKit's `ConfigValueReading` + a 3-line retroactive conformance. Four overloads were character-for-character identical between the two examples.
- **`CloudKitAuthMethod` deleted** — it re-declared MistKit's `PrivateKeyMaterial`. Its two-branch resolution was duplicated across **five** Bushel command sites (`Sync`/`Export`/`Clear`/`List`/`Status`); now resolved once at load time.
- **`CelestraConfig` deleted** — both examples moved off the legacy `ServerToServerAuthManager` path onto `CloudKitService(containerIdentifier:credentials:environment:)`. Construction no longer does file IO (MistKit defers reading `.file(path:)` keys).
- **`ValidatedCloudKitConfiguration`** now carries one `privateKey: PrivateKeyMaterial` instead of `privateKeyPath` + optional `privateKey` + an empty-string sentinel. **Breaking** for both subrepos, as agreed.
- **Validators shared with Celestra** (it had none), throwing a new app-neutral `CredentialValidationError`.
- **`ConfigurationError` unified** on one `LocalizedError` shape (Bushel's was a bare `Error`, so its messages never reached users). Celestra's `EnhancedConfigurationError` renamed to match.
- **Celestra fails closed** on an unparseable `CLOUDKIT_ENVIRONMENT` instead of silently using `.development`.
- **Loader test seam** exposed unconditionally in both (Celestra had none; Bushel's was `#if DEBUG`).

### Two real bugs fixed

1. **Bushel's documented CLI flags never worked.** `CLIKeyEncoder` joins key components verbatim, so snake_case bases generated `--cloudkit-key_id`, while its own error text, `secretsSpecifier` and docs all advertise `--cloudkit-key-id`. Consequence beyond the flags: **secret redaction never matched**, so a private key passed by flag was logged unredacted. Fixed by moving Bushel to dash-case bases.
   **ENV names are byte-identical before and after** (the env provider normalizes `-` and `.` to `_`), so there is no deployment or CI impact — verified programmatically.
2. **Stale docs:** `.env.example`, `SECRETS_SETUP.md`, `CLOUDKIT_SYNC_SETUP.md` claimed a 32-char key ID; the validator requires 64. Corrected per your ruling.

### Test-double rebuild — read this before reviewing

Bushel's `createLoader` helper used `InMemoryProvider`, which matches keys **literally** and serves **only the stored type**. It diverged from production on key normalization and numeric coercion, and it was **masking a real gap**: a bare `--flag` (no value) never resolves through the real CLI provider, because ConfigKeyKit detects flag presence via `string(forKey:)` and `CommandLineArgumentsProvider` reports a valueless flag only through `bool(forKey:)`.

**That gap predates this work** — the hand-rolled `read(ConfigKey<Bool>)` these tests previously exercised used the same string-based check. The old double hid it by storing flags as `.string("true")`.

I rebuilt the double on the real providers (`CommandLineArgumentsProvider` / `EnvironmentVariablesProvider` with injected inputs) and the harness now passes `--flag true` explicitly. **The valueless-flag gap is now visible and unfixed** — it deserves its own issue rather than scope creep here (`feedback_findings_to_issues_not_code`).

### Verification (all green, re-runnable)

Celestra and Bushel need **Swift 6.4** (`swift-tools-version: 6.4`); the system toolchain is 6.3.2. `TOOLCHAINS=` is not honored in this shell — invoke the binary directly:

```bash
SWIFT64=~/Library/Developer/Toolchains/swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-06-15-a.xctoolchain/usr/bin/swift

(cd Examples/CelestraCloud && $SWIFT64 test)   # 122 tests, 28 suites — passing
(cd Examples/BushelCloud   && $SWIFT64 test)   # 213 tests, 39 suites — passing
swift build && swift test                       # MistKit: 631 tests — passing, untouched
```

Lint: `mise` configs in this worktree needed `mise trust` (checked-in configs, this worktree only). Remaining warnings in both examples are pre-existing — verified by diffing against a stashed baseline with line numbers normalized. The one genuinely new entry is an **improvement**: `BushelCloudKitService.swift` went 314 → 268 lines, downgrading a `file_length` **error** (>300) to a warning.

MistKit itself is untouched — confirmed via `git status`; its `Package.swift` gains no dependencies.

---

## Commit & push

Working tree is clean; the three commits are ready.

```bash
cd ~/Documents/Projects/MistKit/407-mistkitconfiguration

# 1. Push the branch (fast-forward, no force needed)
git push origin 407-mistkitconfiguration

# 2. Open PR 1 against the milestone base
gh pr create --base v1.0.0-beta.5 --head 407-mistkitconfiguration \
  --title "Unify BushelCloud + CelestraCloud CloudKit configuration" \
  --body "See .claude/HANDOFF-407.md. Breaking for both subrepos, as agreed on #407."
```

**Merging** (per `.claude/agent-notes.md`): count commits first — 1 commit → `gh pr merge --rebase`; 2+ → `gh pr merge --squash`. This PR has 3, so **squash**. Never `--merge`.

### Subrepo pushes — yours to run

Both examples are subrepos on branch `mistkit`:

| Subrepo | Remote |
|---|---|
| `Examples/CelestraCloud` | `git@github.com:brightdigit/CelestraCloud.git` |
| `Examples/BushelCloud` | `git@github.com:brightdigit/BushelCloud.git` |

```bash
git subrepo push Examples/CelestraCloud    # git-subrepo 0.4.9 is installed
git subrepo push Examples/BushelCloud
```

I left these to you deliberately — they publish to two external repos. Note the changes are **breaking** for both (`ValidatedCloudKitConfiguration.privateKey` is now `PrivateKeyMaterial`; `CloudKitAuthMethod` is gone), so downstream consumers of those repos need a heads-up.

---

## PR 2 — extraction (not started)

Stacked on PR 1's branch, so its diff shows only the extraction.

### Blocked on you

**Create the `brightdigit/MistKitConfiguration` GitHub repo.** It doesn't exist yet (verified). I won't create it unattended.

### What ships in the package

After PR 1 these are **byte-identical** across both examples (app name aside) — verified by diff:

| File | Lines |
|---|---|
| `KeyIDValidator.swift` | 89 |
| `PEMValidator.swift` | 99 |
| `CredentialValidationError.swift` | 70 |
| `ConfigReader+ConfigValueReading.swift` | 44 |

Plus these, now sharing one shape but needing a parameter to absorb per-app differences:

- `ConfigurationError` (58) — identical.
- `ValidatedCloudKitConfiguration` (80) + `makeCloudKitService()` — identical shape.
- `CloudKitConfiguration` (115) — needs the default container ID as a parameter.
- `ConfigurationLoader` (120) — needs the `secretsSpecifier` list as a parameter (Bushel 4 entries, Celestra 2).
- CloudKit `ConfigurationKeys` — needs `envPrefix` as a parameter (Bushel prefixes non-CloudKit keys with `BUSHEL`; Celestra prefixes nothing).

### Stays in each app

Root config structs (`CelestraConfiguration`, `BushelConfiguration`) and their differing validation layering; per-command configs; app-specific key groups (`VirtualBuddy`, `Fetch`, `Sync`, …); `BushelCloudKitService` and its protocol conformances; domain errors.

### Package setup

- **Platform floor:** `.macOS(.v15) .iOS(.v18) .tvOS(.v18) .watchOS(.v11) .visionOS(.v2)` — matches ConfigKeyKit exactly (forced by that dependency) and matches Bushel *and* MistDemo. Celestra's `.v26` consumes fine.
- **Dependencies:** `MistKit`, `ConfigKeyKit` (`from: "1.0.0-beta.2"`), `swift-configuration` with trait `["CommandLineArguments"]`.
- Add as `Packages/MistKitConfiguration/` via `git subrepo` (no `Packages/` dir exists yet; mirror the `.gitrepo` shape from `Examples/CelestraCloud/.gitrepo`).
- Clean copy is fine — no subtree split or filter-repo (`feedback_skip_history_on_repo_extraction`).
- `setup-mistkitconfiguration` composite action belongs **in the new repo**, not MistKit (`feedback_setup_action_lives_in_owned_repo`), referenced remotely like `brightdigit/MistKit/.github/actions/setup-mistkit@main`.
- Follow ConfigKeyKit for CI workflow shape (`.claude/agent-notes.md`).

### Known costs of the separate-repo choice

- Both subrepos gain a **second** remote dependency line and a `MISTKITCONFIGURATION_BRANCH` pin alongside `MISTKIT_BRANCH` (3 call sites each in `BushelCloud.yml` / `CelestraCloud.yml`).
- Bushel's `Package.swift:94-98` documents the MistKit `path: "../.."` line as a one-line overlay reapplied on branch recreation and never merged. It becomes a **two-line** overlay — update that comment.
- The new repo must be **tagged** before either subrepo's `main` can pin a release; until then both consume it by branch pin.
- `project_mistkit_branch_pin_resolves_tags`: `git ls-remote` matches tags too, so a tag value silently pins a release instead of the branch. The new action should pin by resolved revision, like `setup-mistkit` does.

### Also in PR 2

- Amend `Sources/MistKit/Documentation.docc/ConfiguringMistKit.md:3`, which currently states *"There is no single `MistKitConfiguration` type"* — still true of MistKit itself, but worth a pointer to the new package.
- Close out #407: comment the verification table, retitle to reflect what was built, close.

---

## Follow-up issues worth filing

1. **Valueless CLI flags don't resolve** through `CommandLineArgumentsProvider` + ConfigKeyKit's bool path (details above). Affects both examples; pre-existing. Possibly a ConfigKeyKit fix: resolve booleans via `bool(forKey:)` rather than `string(forKey:)`.
2. **ConfigKeyKit could reject or normalize underscored key bases** — a snake_case base silently yields an unusable CLI flag and breaks `secretsSpecifier` matching, with no build-time signal. Root cause of the Bushel bug.
3. **Bushel `.env.example` documents `CLOUDKIT_DATABASE`** that no Bushel code reads.
4. **`PrivateKeyMaterial` isn't `Equatable`** in MistKit — tests must assert via `.filePath` or a `case` pattern. Cheap to add if wanted.

## Memory written

- `.claude/memory/reference_configkey_cli_flag_dash_case.md` — the dash-case rule and why ENV hides the bug.
- `.claude/memory/reference_configkeykit_configvaluereading.md` — ConfigKeyKit#1 shipped in-core; no `ConfigKeyKitConfiguration` package exists.
- `.claude/memory/project_beta4_worktree_layout.md` — corrected; it recorded #407 as blocked on a now-resolved blocker.

Full plan: `~/.claude/plans/verify-the-choices-in-rosy-bubble.md`
