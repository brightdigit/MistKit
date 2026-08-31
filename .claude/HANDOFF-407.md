# Handoff — Issue #407 (MistKitConfiguration)

**Worktree:** `~/Documents/Projects/MistKit/407-mistkitconfiguration`
**Branch:** `407-mistkitconfiguration`, pushed, in sync with origin (0/0)
**Status:** Parts 0–2 + subrepo wiring done and pushed. **Parts 3–5 remain.**

## Open PRs

| Repo | PR | Base | State |
|---|---|---|---|
| MistKit | [#455](https://github.com/brightdigit/MistKit/pull/455) | `v1.0.0-beta.5` | **draft** |
| MistKitConfiguration | [#1](https://github.com/brightdigit/MistKitConfiguration/pull/1) | `main` | **draft** |
| ConfigKeyKit | [#8](https://github.com/brightdigit/ConfigKeyKit/pull/8) | `main` | ready for review |

**Neither draft can merge until ConfigKeyKit#8 merges and is tagged**, and that is by
design — both pin ConfigKeyKit by revision, and `dependency-policy.yml` rejects
non-tagged dependencies on PRs to `main`. Merge order is ConfigKeyKit → tag → swap both
pins → MistKitConfiguration#1 → tag → MistKit#455.

Full plan: `~/.claude/plans/continue-with-claude-handoff-407-md-proud-turing.md`

---

## Commits on the branch

```
fbb6d3a build(packages): wire MistKitConfiguration as a subrepo
92c45f7 git subrepo init … Packages/MistKitConfiguration
cc8743f build(packages): pin ConfigKeyKit to the boolean-resolution fix
8603e60 feat(packages): add MistKitConfiguration package
5338914 refactor(mistdemo): migrate configuration onto typed ConfigKeys
bf952c6 docs: add handoff for #407
88d9f0b docs(memory): record ConfigKeyKit findings from #407 verification   ┐
15329ff refactor(examples): unify credential model on Credentials API       ├ the original "PR 1"
914ac2e refactor(examples): adopt ConfigValueReading; fix Bushel CLI flags   ┘
```

`bf952c6` and earlier are the pre-existing unify work; everything above it is new.
**MistKit core is untouched** — `git diff origin/v1.0.0-beta.5...HEAD -- Sources/ Package.swift`
is empty.

---

## Decisions taken (all confirmed by the user)

| Decision | Value |
|---|---|
| Delivery | One draft PR onto `v1.0.0-beta.5`; the original PR 1 was never opened separately |
| New repo | `brightdigit/MistKitConfiguration`, public; dev branch `initial-extraction` → PR to `main` |
| Structure | **One** target / product |
| tools-version | **6.4** |
| MistDemo | **Full** key convergence, done first, folded into this branch |
| `output.format` | One key, default **`table`** everywhere |
| Errors | Generic identifiable enums, **no prose**, no `LocalizedError` |
| `ConfigurationError` struct | Kept in the package as a presentation convenience it never throws |

---

## Part 0 — MistDemo onto typed keys (`5338914`, 67 files)

MistDemo had **zero** typed keys (Bushel 32, Celestra 12) and read config through an
untyped façade at ~160 call sites. Keys now live in
`Sources/MistDemoKit/Configuration/Keys/` (13 files, `MistDemoKeys`).

**Naming rule.** `prefixKeys(with: "cloudkit")` turned out to be a blanket namespace over
the *entire* key space (`port` → `CLOUDKIT_PORT`), not a CloudKit qualifier. So the five
CloudKit credential keys took the package's `cloudkit.…` bases, and **every other key kept
its base and gained `envPrefix: "CLOUDKIT"`** — reproducing the old behaviour exactly. Net
effect: 4 env vars unchanged, 1 repaired, 0 broken; only 5 CLI flags renamed. CI passes
credentials by env, not flags, so no workflow needed editing.

### Bugs fixed here

1. **`CLOUDKIT_CONTAINER_ID` never worked.** `MistDemo-Integration.yml` sets it on all four
   jobs (L137/153/168/189) and `docs/cloudkit-guide/` documents it, but the code read
   `container.identifier` → `CLOUDKIT_CONTAINER_IDENTIFIER`. Every integration run silently
   fell back to the built-in default, masked only because that default equals the secret's
   value.
2. **`MistDemoConfig+Testing` seeded `private.key.file`**, which production never reads
   (`private.key.path`), so `privateKeyFile:` silently did nothing in every test using it.
3. Deleted the 30-constant dead `ConfigKeys` enum and `Defaults.database` (said `private`
   while the runtime default was `public`; never read).

### ⚠️ The boolean correction — read before touching `MistDemoConfiguration`

My first analysis said typed keys *fix* bare boolean flags. **That was wrong**, and the
correction is load-bearing. Measured against real providers:

```
string(forKey: "verbose")                  -> nil     (bare flag invisible)
bool(forKey: "verbose", default: false)    -> true
ConfigKeyKit read(ConfigKey<Bool>)         -> false   ← bug
ConfigKeyKit read(OptionalConfigKey<Bool>) -> nil     ← bug
```

ConfigKeyKit's `resolvedBool` probes `string(forKey:)`, so it has the same flaw. Only the
three `optionalBool` sites were broken; the ~12 `bool(forKey:default:)` sites **worked**.
A naive migration to ConfigKeyKit's `read` would have **regressed those twelve**.

So `MistDemoConfiguration` keeps its **own** Bool path over `ConfigReader.bool(forKey:)`
(`resolveBool`). Do not "simplify" it into ConfigKeyKit's `read(_:)` until ConfigKeyKit#8
is released — and even then, verify. `MistDemoConfigurationBoolTests` pins the behaviour.

---

## Parts 1–2 — the package (`8603e60`, 44 files)

`Packages/MistKitConfiguration/`, scaffolded from the ConfigKeyKit repo template.

- **Errors carry no prose.** `CloudKitConfigurationError` / `KeyIDValidationFailure` /
  `PEMValidationFailure` are `Equatable` enums, deliberately **not** `LocalizedError`.
  Errors name a `CloudKitConfigurationField`, not a key string, because the three
  consumers spell the same field differently. This **retires `CredentialValidationError`**.
- **`ValidatedCloudKitConfiguration.init` is throwing** and runs both validators, so no
  value of that type can exist whose credentials skipped format checking. Do not add a
  non-throwing initializer.
- **`secretCommandLineFlags` is derived** from `isSecret`, not hand-listed.
- **No shared `ConfigurationLoader`** — a cross-module extension cannot add stored
  properties, so a shared base could never gain a dependency. `ConfigurationSources`
  captures the genuinely shared part (provider order + redaction list).

### CI shape

Follows **CelestraCloud.yml, not ConfigKeyKit.yml**. `swift-tools-version: 6.4` has no
Linux/Windows release toolchain — verified on Docker Hub: 88 `swift:6.2` tags, 83
`swift:6.3`, **zero** `swift:6.4`. So Ubuntu runs the single `swiftlang/swift:nightly-6.4.x`
entry, Windows is commented out, Android is omitted, macOS is `runs-on: xcode-27` (tvOS
must use `"Apple TV 4K (3rd generation)"`). `swift-source-compat.yml` was dropped.

---

## ConfigKeyKit#8 — the boolean fix

Worktree: `~/Documents/Projects/ConfigKeyKit/wt-fix-bool-resolution`, branch
`fix-bool-resolution`, commit `90110faa06f7666a0d58d224c92da976fff5d930`.

`resolvedBool` read every source through `string(forKey:)`, so the
`if source == .commandLine { return true }` branch was unreachable for the very case its
comment described. The env path was wrong **independently**: truthiness was
`== "true" || "1" || "yes"`, so any unrecognized value collapsed to `false` rather than
`nil` — a typo'd `FLAG=ture` silently *disabled* a flag whose default was `true`.

| input | before | after |
|---|---|---|
| `--verbose` (bare) | `false` ❌ | `true` |
| `--verbose false` | `true` ❌ | `false` |
| `FLAG=banana` / `FLAG=on` | `false` ❌ | ignored → default |

Fix adds `bool(forKey:isSecret:fileID:line:)` as a fourth protocol primitive **with a
default implementation**, so existing conformers keep compiling. `ConfigReader.bool` has
the same signature shape as `ConfigReader.string`, so it witnesses automatically — the
retroactive conformance is unchanged.

**Why it escaped:** `MockConfigValueReader` modelled a bare flag as an empty *string*,
which the old code read as presence; the real provider returns `nil` there. Same failure
mode as `InMemoryProvider` in Bushel. Mock now has a native `bools` dict, plus a new
`StringOnlyConfigValueReader` for the parsing default.

**Blast radius:** BushelCloud has ~14 affected `ConfigKey<Bool>` values
(`sync.dry-run`, `sync.force`, `export.pretty`, …) — `--bushel-sync-dry-run` did not
enable dry-run, and `--bushel-sync-dry-run false` did.

---

## ⚠️ Two hazards that will bite silently

### 1. The subrepo overlay clobbers the published package

`Packages/MistKitConfiguration/Package.swift` **must** differ from the standalone repo on
one line:

| Where | MistKit dependency |
|---|---|
| Monorepo | `.package(name: "MistKit", path: "../..")` |
| Standalone | `.package(url: …MistKit.git, from: "1.0.0-beta.4")` |

Both are required — see hazard 2 for why `path:` is forced here, and a tag carrying
`path: "../.."` resolves nowhere. **`git subrepo push` copies the subdir verbatim and will
overwrite the standalone `url:` line.** `.gitrepo` also records an empty `commit =` (the
repo was seeded by hand, see below), so the first push believes nothing was ever pushed.
Re-apply the swap after every push. Documented at the site in `Package.swift` + `CLAUDE.md`
and in `.claude/memory/project_mistkitconfiguration_subrepo_overlay.md`.

**The repo was not seeded with `git subrepo push`.** It was empty, and GitHub refuses a PR
between unrelated histories, so `main` got a LICENSE-only initial commit (`86dd5cf`) to
give `initial-extraction` a merge base; the 44 files were then pushed as `04c0c4c`.

### 2. A `path:` MistKit and a `url:` MistKit cannot coexist

A `path:` package takes its identity from the **directory name**
(`407-mistkitconfiguration`), not from `name:`. Pair it with a sibling depending on MistKit
by `url:` and SwiftPM resolves two packages and fails:

```
error: multiple similar targets 'MistKit', 'MistKitOpenAPI' appear in package
'mistkit' and '407-mistkitconfiguration'
```

**`swift package resolve` still succeeds — only `swift build` catches it.** Every package
in this monorepo must reach MistKit the same way. See
`.claude/memory/project_path_package_identity_collision.md`.

**Useful corollary, verified:** a `revision:` pin on ConfigKeyKit *does* coexist with the
`from: "1.0.0-beta.2"` the three examples declare — SwiftPM resolves the revision for the
whole graph. So Parts 3–4 give all three the ConfigKeyKit fix **without editing their own
ConfigKeyKit lines**.

---

## Remaining work

### Part 3 — rewire CelestraCloud, then BushelCloud
Delete their `KeyIDValidator` / `PEMValidator` / `CredentialValidationError` /
`ConfigurationError` **and** the `@retroactive ConfigValueReading` conformance (two modules
declaring it is a duplicate-conformance error — must land in the same commit). Add a small
`map(_: CloudKitConfigurationError) -> ConfigurationError` carrying each app's own wording.
Replace `ConfigurationKeys.CloudKit` with `CloudKitConfigurationKeys(defaultContainerID:)`.
Expect a broad but mechanical wave of missing-import errors (`MemberImportVisibility`).

Bushel-specific: cut `ConfigurationError` out of `BushelConfiguration.swift`; cut the two
config types out of `CloudKitConfiguration.swift` and **rename that file to
`VirtualBuddyConfiguration.swift`** (`file_name` is severity *error*); collapse
`BushelCloudKitService.swift:85-105` onto `makeCloudKitService()`; update
`ListCommand.swift:43` / `StatusCommand.swift:43`.

### Part 4 — MistDemo adopts the package
Swap its five CloudKit keys for `CloudKitConfigurationKeys`, delete the local
`ConfigReader+ConfigValueReading.swift` (the package's wins), and map
`CloudKitConfigurationError` into MistDemo's **unchanged** `ConfigurationError` enum — no
rename needed, which is the payoff of the identifiable-error design. Move `examples.yml`'s
MistDemo container to `swiftlang/swift:nightly-6.4.x-noble`.

### Part 5 — close-out
`examples.yml` lane for `Packages/MistKitConfiguration`; `setup-mistkitconfiguration`
action in the new repo (needed after all — standalone example CI must rewrite *both* path
deps); amend `Sources/MistKit/Documentation.docc/ConfiguringMistKit.md:3`; close #407.

---

## Verification (all re-runnable; system Swift is 6.4 — no toolchain override)

```bash
cd ~/Documents/Projects/MistKit/407-mistkitconfiguration
(cd Examples/MistDemo            && swift test)   # 1010 tests / 299 suites  (baseline 1002)
(cd Packages/MistKitConfiguration && swift test)   # 35 tests / 6 suites, 0 lint warnings
(cd Examples/CelestraCloud       && swift test)   # 122 / 28  — untouched so far
(cd Examples/BushelCloud         && swift test)   # 213 / 39  — untouched so far
swift build && swift test                          # MistKit 631 — untouched
(cd ~/Documents/Projects/ConfigKeyKit/wt-fix-bool-resolution && swift test)   # 63 tests
```

The handoff's old claim that Swift 6.4 needed a snapshot toolchain is **obsolete** — the
system toolchain is 6.4 release and that snapshot is gone.

SwiftLint parity for MistDemo was established by diffing against a `git archive HEAD`
baseline with line numbers normalized: 2 pre-existing errors in files this work never
touches, 2 warnings resolved. Never bare `git stash` in this repo
(`feedback_never_git_stash_multiworktree`).

## Follow-up issues still worth filing

1. ConfigKeyKit could reject or normalize underscored key bases at build time.
2. Bushel `.env.example` documents a `CLOUDKIT_DATABASE` no Bushel code reads.
3. `PrivateKeyMaterial` isn't `Equatable` in MistKit.
4. Per-source key prefixing in ConfigKeyKit (env-only prefix), which MistDemo emulated
   with `prefixKeys`.
5. MistDemo's dead `MistDemoConstants.ConfigKeys.containerID = "container.id"` — resolved
   by Part 0, but the *class* of drift (constants declared and then duplicated inline)
   affected 10 constants.

## Memory written this session

- `project_path_package_identity_collision.md` — path identity vs `url:`; resolve succeeds, build fails.
- `project_mistkitconfiguration_subrepo_overlay.md` — the never-merged Package.swift line.
