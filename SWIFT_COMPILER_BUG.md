# Swift 6.3 SIL miscompile: `MandatoryAllocBoxToStack` crashes on destructured-enum `catch` pattern with a literal

## Summary

Swift 6.3 (`swiftlang-6.3.0.123.5`) crashes in the `MandatoryAllocBoxToStack`
SIL pass (`StackNesting::fixNesting`, signal 11) while compiling a module that
contains a `catch` clause whose destructured-enum pattern matches **any
literal value** in **any associated-value position**, in combination with a
specific `RecordManaging` protocol shape that includes a default-argumented
`async throws` extension method built on top of a primitive protocol
requirement.

The crash is deterministic. Plain `catch`, all-wildcard destructured catch,
and the equivalent pattern moved into a `guard case` all build without issue —
only a `catch` with at least one literal in the pattern triggers the
miscompile.

## Environment

- **Compiler**: Apple Swift version 6.3 (`swiftlang-6.3.0.123.5 clang-2100.0.123.102`)
- **swift-driver**: 1.148.6
- **Target**: `arm64-apple-macosx26.0`
- **Host**: macOS 26.0 (Darwin 25.4.0), Apple Silicon
- **Tools-version (failing)**: any of 6.1 / 6.2 / 6.3 — independent of the package's `swift-tools-version`

## Reproducer

```bash
git clone git@github.com:brightdigit/MistKit.git
cd MistKit
git checkout 302-redesign-recordmanaging-experiment
# Commit: d2178f3ba69217ee59d887be011e71e6e3d9d79e
cd Examples/MistDemo
swift build
```

The crash occurs during compilation of the `MistDemoKit` module while the
mandatory diagnostic SIL pipeline runs `MandatoryAllocBoxToStack`.

## Crash output (abridged)

```
4. While evaluating request ExecuteSILPipelineRequest(Run pipelines
   { Mandatory Diagnostic Passes + Enabling Optimization Passes } on SIL
   for MistDemoKit)
5. While running pass #54 SILModuleTransform "MandatoryAllocBoxToStack".

Stack:
4  swift-frontend  swift::StackNesting::fixNesting(swift::SILFunction*)        + 4508
5  swift-frontend  BridgedPassContext::fixStackNesting(BridgedFunction) const  +   32
6  swift-frontend  Optimizer.tryConvertBoxesToStack                            + 10940
7  swift-frontend  Optimizer.mandatoryAllocBoxToStack closure                  +  388
8  swift-frontend  swift::SILPassManager::executePassPipelinePlan              + 14624
9  swift-frontend  swift::SimpleRequest<…ExecuteSILPipelineRequest…>            +   48
…
11 swift-frontend  swift::runSILDiagnosticPasses(swift::SILModule&)            +  432
12 swift-frontend  swift::CompilerInstance::performSILProcessing               +  656
```

The crashing pass is the new Swift-implemented optimizer module's
`mandatoryAllocBoxToStack` calling its `tryConvertBoxesToStack` helper, which
calls back into C++ via `BridgedPassContext::fixStackNesting`, where
`StackNesting::fixNesting` segfaults.

## Trigger

The crashing site is the `catch` clause at
`Examples/MistDemo/Sources/MistDemoKit/Integration/Phases/QueryRecordsPhase.swift:55`:

```swift
internal func run(
  input: CreatedRecordNames, context: PhaseContext
) async throws -> NoState {
  do {
    let records = try await context.service.queryRecords(
      recordType: IntegrationTestData.recordType
    )
    // ... uses `records` ...
  } catch CloudKitError.httpErrorWithDetails(statusCode: 404, serverErrorCode: _, reason: _) {
    // <-- this catch crashes the SIL pass
    print("…")
  }
  return NoState()
}
```

`context.service` is typed as a `RecordManaging` existential / generic. The
relevant protocol shape (introduced in commit `d2178f3` on this branch) is:

```swift
public protocol RecordManaging {
  func executeBatchOperations(_ operations: [RecordOperation], recordType: String) async throws

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func queryRecords(
    recordType: String,
    filters: [QueryFilter]?,
    sortBy: [QuerySort]?,
    limit: Int?,
    desiredKeys: [String]?,
    continuationMarker: String?
  ) async throws -> QueryResult
}

extension RecordManaging {
  @available(*, deprecated, message: "…")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public func queryRecords(recordType: String) async throws -> [RecordInfo] {
    let result = try await queryRecords(
      recordType: recordType,
      filters: nil, sortBy: nil, limit: nil,
      desiredKeys: nil, continuationMarker: nil
    )
    return result.records
  }
  // also: queryAllRecords with default-argumented overloads, see
  // Sources/MistKit/Protocols/RecordManaging.swift
}
```

`CloudKitError` is defined in MistKit and includes the
`httpErrorWithDetails(statusCode: Int, serverErrorCode: String, reason: String?)`
case.

## Bisection ladder

I narrowed the crash with successive edits to the body of
`QueryRecordsPhase.run`, clean-rebuilding between each change:

| `run` body content                                                                                       | Result    |
| -------------------------------------------------------------------------------------------------------- | --------- |
| empty (`return NoState()`)                                                                               | builds    |
| + `queryRecords` call + plain `print`                                                                    | builds    |
| + `if context.verbose { records.filter { input.names.contains($0.recordName) } }`                        | builds    |
| + plain `} catch { print("error") }` (no pattern)                                                        | builds    |
| + `} catch CloudKitError.httpErrorWithDetails(statusCode: _, serverErrorCode: _, reason: _) { … }`        | builds    |
| + `} catch CloudKitError.httpErrorWithDetails(statusCode: 404, serverErrorCode: _, reason: _) { … }`      | **crash** |
| + `} catch CloudKitError.httpErrorWithDetails(statusCode: _, serverErrorCode: "X", reason: _) { … }`      | **crash** |

The minimum sufficient ingredient is a **non-wildcard literal at any
associated-value position** in the destructured `catch` pattern. The literal's
type (`Int` vs `String`) and its position do not matter; presence of any
literal does.

## What was ruled out

These hypotheses were tested and falsified during bisection:

- **Tools-version language mode**: crash reproduces with all four combinations
  of `swift-tools-version` 6.1/6.2/6.3 across MistKit and MistDemo
  `Package.swift`.
- **Multi-arg overload ambiguity at call sites**: the deprecated
  `CloudKitService.queryRecords(...) -> [RecordInfo]` overload was removed and
  call sites updated; the SIL crash still reproduces with only one
  `queryRecords` overload visible to overload resolution.
- **Typed vs untyped throws on the protocol primitive**: per the original
  branch experiment commit message, both forms reproduce.
- **`Sendable` conformance on `QueryFilter`/`QuerySort`**: per the same
  commit message, toggling did not affect the crash.
- **The body of `queryAllRecords`**: per the same commit message, replacing
  the body did not affect the crash.
- **Direct calls to the new generic `queryAllRecords` extension method**:
  MistDemo never calls it; bisection of `QueryRecordsPhase.run`'s body shows
  the trigger is the `catch` clause itself, not anything traversing the
  generic protocol extension.

## Why MistDemo and not BushelCloud (the sibling example)

`Examples/BushelCloud` builds cleanly against the same branch. It implements
the new `RecordManaging` primitive but never uses a `catch` clause that
destructures `CloudKitError` with a literal in the pattern. Removing or
softening that single `catch` in MistDemo's `QueryRecordsPhase.run` makes
MistDemo build cleanly as well.

## Workaround

Replace the typed-pattern `catch` with a plain `catch` followed by a
`guard case`/`if case` that performs the same destructuring + literal match.
Identical runtime behavior; the SIL the compiler emits is different enough to
sidestep the bug.

```swift
} catch {
  guard case CloudKitError.httpErrorWithDetails(statusCode: 404, _, _) = error else {
    throw error
  }
  print("…")
}
```

This workaround is applied in
`Examples/MistDemo/Sources/MistDemoKit/Integration/Phases/QueryRecordsPhase.swift`
on this branch.

## Suggested investigation in the compiler

The crash is in the C++ `StackNesting::fixNesting` invoked from the
Swift-implemented optimizer's `tryConvertBoxesToStack`. Likely areas to look:

- SIL emitted for a `catch` clause that produces a `try_apply` whose
  unwind/error block performs a `switch_enum_addr` (or equivalent) destructure
  of an indirect enum case with at least one literal-pattern match,
  particularly when one of the boxes the pass attempts to promote is the
  caught error value.
- The combination with the `RecordManaging` protocol witness call (an `async
  throws` requirement satisfied by a typed-throws concrete witness) which
  produces a witness-thunk in the same function body.

A minimal isolated reproducer outside MistKit was not produced — the bug
needs both the protocol shape and the typed-pattern catch in scope. The full
project repro is small enough (one branch, ~10 second clean build to crash)
to use directly.
