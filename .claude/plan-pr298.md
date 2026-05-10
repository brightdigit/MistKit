# Plan — Fix CI failures + reviewable issues on PR #298 (v1.0.0-beta.1)

## Context

PR [#298](https://github.com/brightdigit/MistKit/pull/298) (`v1.0.0-beta.1` → `main`) currently has six failing checks: BushelCloud Ubuntu (compile errors), CelestraCloud Ubuntu (deprecation-as-error), watchOS Platforms (test flake), CodeQL (2 alerts), CodeFactor (transient + lint debt), and codecov/patch (15.61% < 25.58% target). A separate Claude Code review surfaced eight code-level comments. The full breakdown is in `.claude/ci-failures-pr298.md`.

User decisions (see Q&A this turn):

- **One big PR** containing every fix.
- **Skip Periphery cleanups** (file follow-up issue instead).
- **Include all four bug-fix review comments**: BushelCloudKitService logging field, UpdateReport computed-property + status-enum, MockCloudKitRecordOperator thread-safety, fetchExistingRecordNames overfetching.
- **Leave `actions/checkout@v6` alone** — deliberate.

CodeQL alerts will be **dismissed via `gh api`** (no code change), and a follow-up issue will track Periphery + remaining nits.

Branch off `v1.0.0-beta.1`. Final PR target: `v1.0.0-beta.1` (so the changes ride on the same release branch).

---

## Approach

One feature branch — name `v1.0.0-beta.1-ci-fixes` — with commits grouped by concern so reviewers can read it section-by-section even though it's a single PR. Order matters because compile errors must land before lint runs and tests can pass.

Commit groups (in order):

1. **Compile blockers** — BushelCloud + CelestraCloud + UpdateReport.
2. **watchOS test flake** — `withKnownIssue(isIntermittent: true)` wrap.
3. **Code-review bug fixes** — BushelCloudKitService logging + overfetch, MockCloudKitRecordOperator thread-safety.
4. **Lint sweep** — SwiftLint structural violations + compiler warnings (no Periphery).
5. **Coverage tests** — MistDemo Configuration + small targets.

After branch is ready: dismiss CodeQL alerts, file follow-up issue.

---

## Changes by file

### 1. Compile blockers (PR1 commit)

#### `Examples/BushelCloud/Sources/BushelCloudKit/CloudKit/BushelCloudKitService.swift`

- **Lines 113 and 151** — drop the `database: .public` argument. `CloudKitService.init` no longer takes `database`; database is supplied per-call (defaults to `.public` on the operations that accept it). Resulting init call:
  ```swift
  return CloudKitService(
    containerIdentifier: containerIdentifier,
    tokenManager: tokenManager,
    environment: environment
  )
  ```
- **Line 247 (review bug)** — replace `reason=\(result.recordType)` with the actual error reason. `RecordInfo`'s error reason field is on the failure path; verify the field name when implementing (likely `result.serverErrorCode` or similar — check the `RecordInfo` struct in `Sources/MistKit/Service/RecordInfo.swift` first). If no reason field exists on `RecordInfo`, fall back to `result.recordName` only and remove the misleading `reason=...` segment entirely.
- **Line 169 `fetchExistingRecordNames` (review overfetch)** — change to `try await queryAllRecords(recordType: recordType, desiredKeys: [])`.

#### `Examples/CelestraCloud/Sources/CelestraCloudKit/Services/CloudKitService+Celestra.swift`

- **Line 92 (`queryFeeds`-style single-page caller)** — switch to `queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:database:)` with `pageSize: limit`. Auto-paginates and stays non-deprecated.
- **Lines 113-141 (`while true` loop reading `feeds`)** — refactor to use new `queryRecords(...) -> QueryResult`:
  ```swift
  var continuationMarker: String? = nil
  repeat {
    let result = try await queryRecords(
      recordType: "Feed",
      limit: 200,
      desiredKeys: ["___recordID"],
      continuationMarker: continuationMarker
    )
    let feeds = result.records
    // ... existing per-batch processing ...
    continuationMarker = result.continuationMarker
  } while continuationMarker != nil
  ```
- **Line 32** — demote `public import Logging` to `internal import` (it's not used in public/inlinable code).

#### `Examples/CelestraCloud/Sources/CelestraCloudKit/Services/FeedMetadataBuilder.swift`

- **Line 31** — demote `public import Foundation` to `internal import`.

#### `Examples/CelestraCloud/Sources/CelestraCloudKit/Models/UpdateReport.swift`

Two fixes for the review comments:

- **Computed properties not serialized** (`Summary.successRate` at line 56, `UpdateReport.duration` at line 170): convert both to **stored** properties set at init time. This keeps Codable synthesized and produces the JSON consumers expect. Update `Summary.init` and `UpdateReport.init` to compute and store the values.
- **`FeedResult.status: String` (line 131)** — replace with a nested `Codable` enum:
  ```swift
  public enum Status: String, Codable, Sendable {
    case success, error, skipped, notModified
  }
  public let status: Status
  ```
  Update all call sites that construct `FeedResult` (search `Examples/CelestraCloud/Sources` for `FeedResult(`) to pass the enum.

#### `Examples/BushelCloud/Sources/BushelCloudKit/Extensions/SwiftVersionRecord+CloudKit.swift` (lines 30-32) and `XcodeVersionRecord+CloudKit.swift` (lines 31-32)

- Demote `public import` of `BushelFoundation`, `BushelUtilities`, `Foundation` to `internal import` where flagged unused publicly.

---

### 2. watchOS test flake (commit 2)

#### `Examples/MistDemo/Tests/MistDemoTests/Utilities/AsyncHelpers/AsyncHelpersTests+ConcurrentTimeout.swift:45-52`

Wrap the body in `withKnownIssue(isIntermittent: true)`, mirroring the existing pattern at `AsyncHelpersTests+Timeout.swift:58, :83`:

```swift
internal func cancelsOtherTasks() async throws {
  // Intermittent: simulator cooperative executors (watchOS in particular) can
  // let the operation's single long Task.sleep complete before the polling
  // timeout's many short sleeps detect the deadline — same root cause as the
  // wasm32 gate above and the throwsOnTimeout / returnsAsyncValue tests in
  // AsyncHelpersTests+Timeout.swift.
  await withKnownIssue(isIntermittent: true) {
    await #expect(throws: AsyncTimeoutError.self) {
      try await withTimeout(seconds: 0.1) {
        try await Task.sleep(nanoseconds: 500_000_000)
        return "done"
      }
    }
  }
}
```

`multipleConcurrentTimeouts()` is left alone unless it starts flaking on watchOS too — its inner branches use `Issue.record(...)` directly and would need refactoring to be wrapped.

---

### 3. Review-comment bug fixes (commit 3)

#### `Examples/CelestraCloud/Tests/CelestraCloudTests/Mocks/MockCloudKitRecordOperator.swift`

Mock currently uses `nonisolated(unsafe)` on shared mutable state with a comment claiming "single-threaded test use only" — but Swift Testing parallelizes by default. Convert to an `actor` or apply `@Suite(.serialized)` to every consumer. **Plan: convert to `actor`** so the mock is intrinsically safe regardless of suite configuration. This means call sites become `await` calls (already inside `async` test bodies, so cheap).

The `BushelCloudKitService.swift:247` and `:169` fixes are in commit 1 above (grouped with the BushelCloud compile-error edits since they touch the same file).

---

### 4. Lint sweep (commit 4)

#### MistKit core

**`Sources/MistKit/Service/CloudKitService.swift` (file_length 244 > 225):** Move the entire "Path builders" extension (lines 85-244 — 13 trivial path builders) into a new file:

- New file: `Sources/MistKit/Service/CloudKitService+Paths.swift`
- Move the `extension CloudKitService { ... }` block verbatim, with the standard project file header.
- Reduces `CloudKitService.swift` to ~85 lines, well under cap.

**`Sources/MistKit/Authentication/Credentials+TokenManager.swift:54` (cyclomatic 9 > 6, body 55 > 50):** Extract three private helpers from `makeTokenManager(for:requiresUserContext:)`:

- `private func makeUserContextTokenManager(database:) throws -> any TokenManager`
- `private func makePublicTokenManager() throws -> any TokenManager`
- `private func makePrivateSharedTokenManager(_ database: Database) throws -> any TokenManager`

Outer function becomes a thin dispatcher (~10 lines, complexity ≤ 3).

**`Tests/MistKitTests/Protocols/MockRecordManagingService.swift:35`:** Add an explicit `queryAllRecords(recordType:)` override on the mock so it doesn't fall through the deprecated default impl on `RecordManaging`. Body returns `recordsToReturn` directly.

#### MistDemo

**`Examples/MistDemo/Sources/MistDemoKit/CloudKit/MistKitClientFactory.swift:75, :105`:** Drop the `try` keyword from both `CloudKitService(...)` calls — verified via Read: the called inits are not throwing. The wrapping `create(...)` functions remain `throws` because of `try config.toPrimaryCredentials()` (line 74) and `throw ConfigurationError.unsupportedPlatform(...)` (WASI branch).

**`Examples/MistDemo/Sources/MistDemoKit/Commands/DemoErrorsRunner.swift:96`:** Replace `try await service.queryRecords(recordType: Self.bogusRecordType)` with `try await service.queryAllRecords(recordType: Self.bogusRecordType)`. Demo intentionally targets a non-existent record type to exercise error paths; result set is empty either way.

**ExistentialAny** — verified by Read:

- `Examples/MistDemo/Sources/MistDemoKit/Output/Escapers/OutputEscaperFactory.swift:37` — return type `OutputEscaper` → `any OutputEscaper`.
- `Examples/MistDemo/Sources/MistDemoKit/Output/Formatters/OutputFormatterFactory.swift:39` — return type `OutputFormatter` → `any OutputFormatter`.
- `Examples/MistDemo/Sources/MistDemoKit/Types/AnyCodable.swift:36` — `from decoder: Decoder` → `from decoder: any Decoder`.
- `Examples/MistDemo/Sources/MistDemoKit/Types/AnyCodable.swift:59` — `to encoder: Encoder` → `to encoder: any Encoder`.
- `Examples/MistDemo/Sources/MistDemoKit/Types/FieldsInput.swift:37, :61` — same `Decoder`/`Encoder` → `any Decoder`/`any Encoder` substitutions.

**Periphery findings — out of scope for this PR.** Capture them in a follow-up issue (see "Follow-ups" section).

---

### 5. Coverage tests (commit 5)

Goal: lift patch coverage from 15.61% → ≥ 25.58% (≈ 144 more covered lines). Cheapest path is `Examples/MistDemo/Tests/MistDemoTests/Configuration/`. Each new test file follows the existing pattern: `@Suite("...")` internal struct, `@Test("...")` async throws methods, `#expect(...)` assertions, no mocks for pure Config decoders. Reference patterns: `LookupConfigTests.swift`, `DeleteConfigTests.swift`.

New / expanded test files (highest LOC-per-test ratio first):

| New file | Targets | ~tests | LOC reachable |
|---|---|---|---|
| `Tests/MistDemoTests/Configuration/FetchChangesConfigTests.swift` | `FetchChangesConfig` | 4-5 | 35 |
| `Tests/MistDemoTests/Configuration/LookupZonesConfigTests.swift` | `LookupZonesConfig` | 3 | 29 |
| `Tests/MistDemoTests/Configuration/DemoErrorsConfigTests.swift` | `DemoErrorsConfig` + `DemoErrorsError` | 3-4 | 24 (18+6) |
| `Tests/MistDemoTests/Configuration/CurrentUserConfigTests.swift` (expand) | fields parsing branches | +4 | ~24 |
| `Tests/MistDemoTests/Configuration/DeleteConfigTests.swift` (expand) | param combos | +4 | ~46 |
| `Tests/MistDemoTests/Configuration/AuthTokenConfigTests.swift` (expand) | port/host overrides, missing apiToken | +4 | ~32 |
| `Tests/MistDemoTests/Configuration/CreateConfigTests.swift` (expand) | CSV/JSON/stdin parse paths | +6 | ~90 |
| `Tests/MistDemoTests/Configuration/LookupConfigTests.swift` (expand) | recordNames empty error, comma split | +3 | ~46 |
| `Tests/MistDemoTests/ConfigKeyKit/CommandLineParserTests.swift` | `CommandLineParser` parseCommandName / commandArguments / isHelpRequested | 5 | 23 |
| `Tests/MistDemoTests/Commands/DemoErrorsRunnerOutputTests.swift` | `DemoErrorsRunner+Output` (capture stdout via Pipe or refactor to return `String`) | 4 | 28 |

Total new/expanded tests: **~40-45**. LOC reachable: **>300**, comfortably above the 144-line threshold.

If `DemoErrorsRunner+Output` proves expensive to test (its methods print directly to stdout), skip it and rely on the Configuration tests alone — that path already exceeds the target.

---

## Files modified — summary

**Production:**
- `Examples/BushelCloud/Sources/BushelCloudKit/CloudKit/BushelCloudKitService.swift`
- `Examples/BushelCloud/Sources/BushelCloudKit/Extensions/SwiftVersionRecord+CloudKit.swift`
- `Examples/BushelCloud/Sources/BushelCloudKit/Extensions/XcodeVersionRecord+CloudKit.swift`
- `Examples/CelestraCloud/Sources/CelestraCloudKit/Services/CloudKitService+Celestra.swift`
- `Examples/CelestraCloud/Sources/CelestraCloudKit/Services/FeedMetadataBuilder.swift`
- `Examples/CelestraCloud/Sources/CelestraCloudKit/Models/UpdateReport.swift` (+ all `FeedResult(` call sites)
- `Examples/MistDemo/Sources/MistDemoKit/CloudKit/MistKitClientFactory.swift`
- `Examples/MistDemo/Sources/MistDemoKit/Commands/DemoErrorsRunner.swift`
- `Examples/MistDemo/Sources/MistDemoKit/Output/Escapers/OutputEscaperFactory.swift`
- `Examples/MistDemo/Sources/MistDemoKit/Output/Formatters/OutputFormatterFactory.swift`
- `Examples/MistDemo/Sources/MistDemoKit/Types/AnyCodable.swift`
- `Examples/MistDemo/Sources/MistDemoKit/Types/FieldsInput.swift`
- `Sources/MistKit/Service/CloudKitService.swift` (shrink)
- `Sources/MistKit/Service/CloudKitService+Paths.swift` (new)
- `Sources/MistKit/Authentication/Credentials+TokenManager.swift` (extract helpers)

**Tests:**
- `Examples/MistDemo/Tests/MistDemoTests/Utilities/AsyncHelpers/AsyncHelpersTests+ConcurrentTimeout.swift`
- `Examples/CelestraCloud/Tests/CelestraCloudTests/Mocks/MockCloudKitRecordOperator.swift` (struct → actor)
- `Tests/MistKitTests/Protocols/MockRecordManagingService.swift`
- 8-10 new/expanded test files under `Examples/MistDemo/Tests/MistDemoTests/Configuration/` and `ConfigKeyKit/` and `Commands/`

---

## Out of band (no PR)

- **CodeQL alerts** — dismiss both via `gh api -X PATCH /repos/brightdigit/MistKit/code-scanning/alerts/<id>` with `state=dismissed reason="won't fix"` and a brief comment explaining the email is caller-supplied debug input redacted by `SecureLogging` unless `MISTKIT_DISABLE_LOG_REDACTION=1`. Get IDs from `gh api repos/brightdigit/MistKit/code-scanning/alerts`.

## Follow-up issue (file after PR opens)

Title: *"v1.0.0-beta.1 follow-ups: Periphery cleanups + nits"*. Include:

- All Periphery findings from §5a/5b of `.claude/ci-failures-pr298.md` (~30 unused symbols across MistKit + MistDemo).
- `updateFeedMetadata` partial-success semantics (`FeedUpdateProcessor+Fetch.swift:103`).
- `ExitError` refactor (use `ExitCode` from swift-argument-parser, or add `message: String`).
- Copyright year alignment for `CelestraErrorTests+Description.swift` and `CelestraErrorTests+RecoverySuggestion.swift` (`© 2025` → `© 2026`).
- CodeQL Action v3 → v4 upgrade before December 2026 deprecation.

---

## Verification

Per memory `feedback_test_lint_before_commit`: run all of the following locally **before** push.

From repo root:

```bash
# 1. MistKit core
swift build
swift test
./Scripts/lint.sh

# 2. MistDemo
cd Examples/MistDemo
swift build
swift test
./Scripts/lint.sh
cd -

# 3. BushelCloud (the failing job's exact target)
cd Examples/BushelCloud
swift build
swift test
cd -

# 4. CelestraCloud
cd Examples/CelestraCloud
swift build
swift test
cd -
```

Expected after fixes:

- All four `swift build` invocations succeed (no `database: .public` errors, no `queryRecords` deprecation errors under `-warnings-as-errors`).
- All four `swift test` runs pass on the local platform (macOS — won't reproduce the watchOS-specific flake, but the `withKnownIssue(isIntermittent: true)` wrap is non-load-bearing on success).
- Both `./Scripts/lint.sh` runs print `Linting completed successfully` with exit 0 (already true; the cleanups just reduce warning noise).
- Coverage gain locally verifiable via `swift test --enable-code-coverage` then `xcrun llvm-cov report` on the MistDemo target — should report ≥ 25.58% on the patch lines.

After push, watch the PR checks list:

- Test BushelCloud on Ubuntu — green.
- Test CelestraCloud on Ubuntu — green.
- Build on macOS (Platforms) (watchos, …) — green (or red with the wrap demonstrably catching the failure as a "known issue").
- codecov/patch — ≥ 25.58%.
- CodeQL — still red until alerts are dismissed via `gh api` (run dismissal commands after PR opens).
- CodeFactor — likely green now that the underlying lint is cleaner; if still red, it's the upstream service issue and can be re-run.
