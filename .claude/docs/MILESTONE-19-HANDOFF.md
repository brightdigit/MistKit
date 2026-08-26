# Milestone v1.0.0-beta.4 — Handoff

Context for continuing milestone 19 work locally. Written at the end of a Claude Code
web session that shipped 4 of the 14 issues.

- **Branch:** `claude/parallel-agents-work-trees-pbumvn`
- **PR:** [#424](https://github.com/brightdigit/MistKit/pull/424) (draft) → base `v1.0.0-beta.4` (**not** `main`)
- **Head at handoff:** `fb84e52`
- **Milestone:** https://github.com/brightdigit/MistKit/milestone/19

```bash
git fetch origin claude/parallel-agents-work-trees-pbumvn
git checkout claude/parallel-agents-work-trees-pbumvn
```

---

## 1. What shipped in #424

| Issue | State | Notes |
|---|---|---|
| #421 Remove deprecated public API | Done | 4 declarations removed. **Breaking.** |
| #378 FieldValue ↔ Components refactor | Done | Exhaustive dispatch; 5 `default:` branches removed |
| #358 CloudKitError per-serverErrorCode | Done | 14 codes + `.unknownServerError` fallback |
| #295 Cloud toolchain setup | Done | Two-tier swiftly setup + `.claude/settings.json` |
| #419 MistDemoApp initializers | **Already fixed** | Not a code change — see below |

### #419 is closable without code
Both initializers the issue proposes (`NoteEditView.init(mode:onSaved:)`,
`RecordDetailView.init(note:onChange:)`) shipped in `5a58120` (v1.0.0 beta.3), eight days
after the issue was filed. Verified they exist in the tree and that `5a58120` is an
ancestor of HEAD.

**To close it**, confirm on macOS with Swift 6.3.2:
```bash
cd Examples/MistDemo && swift build --target MistDemoApp
```
Linux cannot run this — the views are inside `#if canImport(SwiftUI)`.

---

## 2. Remaining milestone work (9 issues)

**Serialize these three — they all mutate `openapi.yaml`** and will collide if run in
parallel worktrees:

| Issue | Title |
|---|---|
| #41 | Fetching Record Information (`records/resolve`) |
| #42 | Accepting Share Records (`records/accept`) |
| #47 | Fetching Record Zone Changes (`changes/zone`) |
| #386 | Zone schemas only model `{ zoneID }` — enrich with sync/atomic metadata |
| #401 | Clarify change-tracking endpoint coverage (`changes/*` vs `records/changes`) |

**Safe to parallelize — independent, no spec changes:**

| Issue | Title |
|---|---|
| #399 | Fix Over-Extension Use With Protocol Extension Implementation Pattern |
| #407 | Create MistKitConfiguration package for shared CloudKit config glue |
| #146 | Add custom CloudKit zone support for queries |
| #398 | MistDemo web: add phone-number support to `/users/discover` |

---

## 3. Environment & tooling — hard-won details

### Swift versions differ across the repo
| Package | tools-version |
|---|---|
| root `Package.swift` | 6.1 |
| `Examples/MistDemo`, `BushelCloud`, `CelestraCloud` | **6.2** |
| `.swift-version` (new) | **6.3.2** |

Installing 6.1 makes every example package unbuildable
(`error: package is using Swift tools version 6.2.0 but the installed version is 6.1.0`).

### mise vs. cloud sessions
`mise.toml` pins swift-format, SwiftLint, periphery and swift-openapi-generator via
`spm:`/`aqua:` backends, which resolve through **`api.github.com`** — unreachable from
Claude Code web sessions. Locally mise works normally; **run the full lint locally**,
since web sessions skip SwiftLint and periphery:

```bash
./Scripts/lint.sh          # full pipeline — do this before merging #424
mise exec -- swiftlint
```

`Scripts/lint.sh` now gates SwiftLint/periphery on `CLAUDE_CODE_REMOTE`. That gating is
for web sessions only and should not affect local runs.

### Regenerating OpenAPI code
`Scripts/generate-openapi.sh` prefers the mise binary and falls back to
`Scripts/OpenAPITools/` — a standalone manifest that resolves the generator over plain
git. Either path produces byte-identical output (verified).

> **Keep the version in `Scripts/OpenAPITools/Package.swift` in sync with `mise.toml`'s
> `spm:apple/swift-openapi-generator` pin (currently `1.10.3`).** Nothing enforces this.

```bash
./Scripts/generate-openapi.sh
```

---

## 4. Lessons from the parallel-worktree run

Four agents ran on isolated worktrees. Worth repeating, and worth knowing the failure mode:

**Git merged cleanly and both branches were individually green — yet the merge was
broken.** #358's new tests called a query overload that #421 deleted. The branches
touched disjoint files, so there was no conflict, and neither agent could have seen it.
It surfaced only under `--build-tests`, because a plain `swift build` does not compile
test code.

```bash
# After merging any two parallel branches:
swift build --build-tests   # NOT just `swift build`
swift test
```

Also: don't pipe test output through `tail` when diagnosing — it reduced a real
compile error to a context-free `error: fatalError` that looked like a passing run.

Agents could not build the example packages (toolchain mismatch, above), so call-site
edits in `Examples/` were made by reading signatures. Those need a compile before trust.

---

## 5. Open follow-ups

### 5.1 Unverified 32-bit/WASI narrowing (#378)
The agent introduced, then caught and fixed, an `Int64` → `Int` conversion that would
**trap on wasm32** for large timestamps. There is no 32-bit test coverage. A green wasm
CI lane proves it compiles, not that the path is safe. **Wants a human review.**

### 5.2 `openapi.yaml` declares `serverErrorCode` as a closed enum
Two places:
- `OperationFailureServerErrorCode` (~line 1716)
- `ErrorResponse.serverErrorCode` (~line 1803)

The generator emits closed Swift enums, so an unrecognized code fails to decode as
`.decodingError` **before** MistKit's mapping runs — meaning `.unknownServerError` can
never fire from real traffic today.

Two concrete gaps found:
- The spec's own prose (~line 1795) documents `RECORD_NOT_FOUND` and `PARTIAL_FAILURE`,
  neither of which is in the `enum:` below it.
- Apple's CloudKit JS reference names `SERVICE_UNAVAILABLE`, `UNIQUE_FIELD_ERROR`,
  `INVALID_ARGUMENTS`, `UNKNOWN_ERROR` — all rejected by the enum. *Caveat: some
  CloudKit JS codes are client-side only and may never cross the REST wire. Unverified.*

Deliberately deferred — the design question (open the enum to plain `string`, vs. keep a
closed enum, vs. restructure `CloudKitError` around a nested `ServerErrorCode` enum with
`.unknown(String)`) was left open. `CloudKitError` is a 30-case public enum with library
evolution **disabled**, so adding cases post-1.0 is source-breaking for exhaustive
switches. Pre-1.0 is the free moment to decide.

### 5.3 `.claude/docs/webservices.md` is missing
`CLAUDE.md` documents it as present at 289 KB and calls it the primary REST API
reference. It is not in the repo. It is the doc you'd want for §5.2.

### 5.4 #421's acceptance-criteria grep is vacuous
The issue's verification grep cannot match multi-line `@available(...)` attributes, so it
returns clean whether or not the work was done. Worth fixing in the issue template.
(Confirmed: zero `@available(*, deprecated)` declarations remain in `Sources/MistKit`.)

---

## 6. Verification status of #424

Run on Linux x86-64 / Swift 6.2 against the fully merged tree:

| Check | Result |
|---|---|
| MistKit core | 552 tests / 176 suites passing |
| MistDemo | 970 tests / 289 suites passing |
| MistDemo, CelestraCloud, BushelCloud | all build against modified MistKit |
| swift-format lint + header + `--build-tests` | clean; formatting produced no changes |
| SwiftLint, periphery | **not run** — needs local mise |
| wasm32, Windows, Android, Apple platforms | **not run locally** — CI only |

Before merging: run `./Scripts/lint.sh` locally and check CI on #424.
