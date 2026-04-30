# MistDemo Improvements (Issue #271) — Multi-Phase Plan

## Context

GitHub issue [#271 "MistDemo Improvements"](https://github.com/brightdigit/MistKit/issues/271) is an empty parent tracking 4 sub-issues that together make MistDemo presentation-ready:

- **#260** — `swift test` is broken in `Examples/MistDemo` because `MistDemo` is an `executableTarget` and its 39 tests use `@testable import MistDemo`. This blocks new tests from being written.
- **#214 (Phase 3 CRUD)** — `UpdateCommand` is partially built; `Delete`, `Lookup`, `Modify` are entirely missing. Backend support already exists in `CloudKitService`.
- **#255** — `index.html` token capture has a substring URL check that's not a real domain match, and the reviewer noted capture itself "isn't working."
- **#272** — A SwiftUI macOS+iOS demo app for an upcoming presentation. The presentation compares **MistKit (used by the existing web/CLI MistDemo)** vs **Apple's CloudKit framework (used by the new native app)** against the same CloudKit container.

Goal: deliver these in an order that unblocks subsequent work, so the presentation has a working CLI/web tool, complete CRUD, reliable auth, and a polished native app.

---

## Phase 1 — Unblock the test target (Issue #260)

**Why first:** Phase 2 needs to add many new tests; running them requires `@testable import MistDemo` to actually link.

### Target restructure in `Examples/MistDemo/Package.swift`

- Convert current `.executableTarget(name: "MistDemo", ...)` into `.target(name: "MistDemo", ...)` (library).
- Add new `.executableTarget(name: "MistDemoEntry", dependencies: ["MistDemo"])` containing only the `@main` entry point.
- Update product: `.executable(name: "mistdemo", targets: ["MistDemoEntry"])`.
- `MistDemoTests` continues to depend on `MistDemo` — no test-file changes needed.

### File moves

- Move `Examples/MistDemo/Sources/MistDemo/MistDemo.swift` (the `@main` struct) → `Examples/MistDemo/Sources/MistDemoEntry/MistDemoEntry.swift`.
- Keep all other 13 subdirs (`Commands/`, `Configuration/`, `CloudKit/`, `Models/`, `Protocols/`, `Types/`, `Utilities/`, `Output/`, `Extensions/`, `Integration/`, `Errors/`, `Constants/`, `Resources/`) under `Sources/MistDemo/` as the library.
- The `resources: [.copy("Resources")]` declaration stays on the `MistDemo` library target so `index.html` ships with the library.

### Verification

- `cd Examples/MistDemo && swift build` — confirms split compiles.
- `cd Examples/MistDemo && swift test` — confirms 39 tests now resolve `MistDemo` as a module.
- `cd Examples/MistDemo && swift run mistdemo --help` — confirms executable wiring.

---

## Phase 2 — Complete Phase 3 CRUD commands (Issue #214)

Follow the existing `CreateCommand` / `UpdateCommand` patterns. Each new command needs four artifacts: `Commands/<X>Command.swift`, `Configuration/<X>Config.swift`, `Errors/<X>Error.swift`, registry entry in `MistDemoEntry.swift` (post-Phase 1) or `MistDemo.swift`, and `Tests/MistDemoTests/...` files.

### 2a — Fill UpdateCommand gaps

Files: `Commands/UpdateCommand.swift`, `Configuration/UpdateConfig.swift`, `Errors/UpdateError.swift`.
- Add `--force` flag to `UpdateConfig` (when set, omits `recordChangeTag` so the server overwrites).
- Add explicit conflict-error mapping: catch `CloudKitError` cases corresponding to 409/`ATOMIC_ERROR`/`SERVER_RECORD_CHANGED` and surface as `UpdateError.conflict(...)` with a hint about `--force`.
- Add `Tests/MistDemoTests/Configuration/UpdateConfigTests.swift` mirroring `CreateConfigTests.swift`.

### 2b — DeleteCommand

Backend: `CloudKitService.deleteRecord(recordType:recordName:recordChangeTag:)` (already in `Sources/MistKit/Service/CloudKitService+WriteOperations.swift`).
- `DeleteConfig`: required `recordName`, optional `recordType`, optional `recordChangeTag`, `--force`, output format.
- `DeleteCommand`: calls `deleteRecord`, formats `{recordName, deleted: true}` output, conflict handling per 2a.
- Tests: `DeleteConfigTests`, command-level test with mock service.

### 2c — LookupCommand

Backend: `CloudKitService.lookupRecords(recordNames:desiredKeys:)`.
- `LookupConfig`: variadic `recordNames`, optional `--fields` for `desiredKeys`, output format.
- `LookupCommand`: handles partial-not-found gracefully (skip nils, report missing names in stderr).
- Tests: config tests + command test with mock returning a mix of found and missing records.

### 2d — ModifyCommand

Backend: `CloudKitService.modifyRecords(_:)`.
- Define a JSON operations format (array of `{op: "create"|"update"|"delete", recordType, recordName, fields, recordChangeTag}`).
- `ModifyConfig`: `--operations-file <path>` or stdin, `--atomic` flag, output format.
- `ModifyCommand`: parse → validate op types → build `[RecordOperation]` → call `modifyRecords` → emit per-op result rows. Handle partial-failure response.
- Tests: parsing tests (valid/invalid JSON, unknown op), atomic-vs-non-atomic with mock service.

### Verification

- `swift test` runs and passes for all four commands' new tests.
- Live smoke against the demo container:
  - `swift run mistdemo create ... && swift run mistdemo lookup <name>`
  - `swift run mistdemo update <name> ...` then `update` again with stale tag → expect conflict → re-run with `--force`.
  - `swift run mistdemo delete <name>`.
  - `swift run mistdemo modify --operations-file ops.json --atomic`.

---

## Phase 3 — Auth token reliability (Issue #255)

Files: `Examples/MistDemo/Sources/MistDemo/Resources/index.html` (lines ~146–290), and possibly `Commands/AuthTokenCommand.swift`.

### 3a — URL hostname fix (quick)

Replace the substring checks at lines 156 and 190:
```javascript
function isCloudKitUrl(url) {
  try { return new URL(url).hostname.endsWith('.apple-cloudkit.com'); }
  catch { return false; }
}
```
Apply to both the `fetch` override and the XHR override.

### 3b — Capture-mechanism investigation + fix

The reviewer's "this isn't working" signal means the fetch/XHR override likely runs in a context that doesn't see the iCloud auth iframe's network calls (cross-origin sandboxing). Investigate, in this order:
1. **`postMessage` from iframe** — already partially implemented (lines 229–291). Check whether iCloud's auth flow actually posts the token; if so, make this the primary path and demote the network overrides to a backup.
2. **Cookie inspection (`ckSession`)** — poll `document.cookie` from same-origin parent for the session cookie if iCloud sets one; not viable cross-origin so likely a dead end, but document the finding.
3. **Manual-paste fallback** — the existing fallback (lines 344–349) becomes the always-available path. Promote it to a visible UI element so the demo never fully fails.

Implement the winning mechanism, manually verify against a real iCloud sign-in once, and update inline comments documenting the chosen approach + why others were rejected.

### Verification

- Manually run `swift run mistdemo auth-token`, sign in via the served page, confirm the token reaches `AuthRequest` on `/api/authenticate` and the CLI prints it.

---

## Phase 4 — Native CloudKit demo app (Issue #272)

**Twist clarified:** the existing web/CLI MistDemo represents the **MistKit** half. This new app represents the **Apple-platforms / CloudKit-framework** half. They both target the same CloudKit container so the presentation can flip between them showing identical data.

### Scope

- New project at `Examples/MistDemoApp/` — SwiftUI multiplatform (macOS + iOS), macOS-first focus.
- Choose project layout: SPM-only (`Package.swift` with `.iOSApplication`/`.macOS` won't work for app bundles) → use an Xcode project (`MistDemoApp.xcodeproj`) with macOS and iOS targets sharing a `MistDemoApp` SwiftUI target.
- **Does NOT depend on MistKit.** Uses Apple's `CloudKit` framework (`CKContainer`, `CKDatabase`, `CKQueryOperation`, `CKRecord`).
- Container identifier: same as the demo's (sourced from existing config, e.g. `iCloud.com.brightdigit.MistDemo` — confirm from `MistDemoConfig`).

### Feature parity (presentation-driven)

Mirror what the MistDemo web/CLI shows so the comparison is apples-to-apples:
- **Sign in** — `CKContainer.default().accountStatus()` / native iCloud account.
- **List zones** — `CKDatabase.allRecordZones()`.
- **Query records** — `CKQueryOperation` over the same record types `mistdemo query` exercises.
- **Record detail view** — display `CKRecord` fields in a form view.

Leave create/update/delete out of the first cut; the goal is parity with the read-side demo of MistDemo for the presentation. Add a follow-up issue if write parity is wanted.

### Files (new)

- `Examples/MistDemoApp/MistDemoApp.xcodeproj`
- `Examples/MistDemoApp/Shared/MistDemoApp.swift` (`@main`, `WindowGroup`)
- `Examples/MistDemoApp/Shared/Views/SignInView.swift`
- `Examples/MistDemoApp/Shared/Views/ZoneListView.swift`
- `Examples/MistDemoApp/Shared/Views/QueryView.swift`
- `Examples/MistDemoApp/Shared/Views/RecordDetailView.swift`
- `Examples/MistDemoApp/Shared/Services/CloudKitService.swift` — thin wrapper around `CKContainer` (note: name clash with MistKit's `CloudKitService` — keep this one app-internal and namespaced by the target).
- macOS target capabilities: enable iCloud + CloudKit in `MistDemoApp.entitlements`.
- iOS target shares `Shared/` sources, has its own entitlements file.

### Verification

- macOS: build and run from Xcode, sign in to iCloud, list zones populated by the existing MistDemo run, drill into a record.
- iOS: same flow on simulator with a signed-in iCloud account.
- Side-by-side check: run `swift run mistdemo query` for the same record type and confirm both surfaces show identical data.

---

## Critical files to modify or create (summary)

**Phase 1**
- `Examples/MistDemo/Package.swift`
- `Examples/MistDemo/Sources/MistDemoEntry/MistDemoEntry.swift` (new; moved from `MistDemo.swift`)

**Phase 2**
- `Examples/MistDemo/Sources/MistDemo/Commands/{Update,Delete,Lookup,Modify}Command.swift`
- `Examples/MistDemo/Sources/MistDemo/Configuration/{Update,Delete,Lookup,Modify}Config.swift`
- `Examples/MistDemo/Sources/MistDemo/Errors/{Update,Delete,Lookup,Modify}Error.swift`
- `Examples/MistDemo/Tests/MistDemoTests/Configuration/{Update,Delete,Lookup,Modify}ConfigTests.swift`
- Reuse: `CloudKitService.{deleteRecord,lookupRecords,modifyRecords,updateRecord}` and `RecordOperation` (Sources/MistKit/Service/)

**Phase 3**
- `Examples/MistDemo/Sources/MistDemo/Resources/index.html`
- Possibly `Examples/MistDemo/Sources/MistDemo/Commands/AuthTokenCommand.swift`

**Phase 4**
- New tree under `Examples/MistDemoApp/` (Xcode project + SwiftUI sources + entitlements)

---

## Sequencing

1. Phase 1 first — unblocks every test we add later.
2. Phase 2 next — completes the CLI/web demo's CRUD story.
3. Phases 3 and 4 can run in parallel after Phase 2; both are independent of each other. If presentation date is tight, prioritize Phase 4 (most visible) and ship Phase 3a (URL fix) without 3b.
