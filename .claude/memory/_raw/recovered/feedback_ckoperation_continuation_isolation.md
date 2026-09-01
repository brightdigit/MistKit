---
name: CK*Operation continuation bridges must be nonisolated
description: Wrapping a CKDatabaseOperation (e.g. CKFetchWebAuthTokenOperation) in withCheckedThrowingContinuation crashes with _dispatch_assert_queue_fail on com.apple.cloudkit.callback when the enclosing method inherits @MainActor — mark the bridge `nonisolated`.
type: feedback
originSessionId: d06f97e2-cf78-4383-b253-9afb6c36fa96
---
When wrapping a `CK*Operation` (e.g. `CKFetchWebAuthTokenOperation`) in `withCheckedThrowingContinuation`, the bridging method must be `nonisolated` if the enclosing type is `@MainActor`. Without it, CloudKit's callback queue (`com.apple.cloudkit.callback`) asserts via `dispatch_assert_queue` and crashes with `EXC_BREAKPOINT` in `_dispatch_assert_queue_fail`.

**Why:** The continuation body inherits the caller's actor isolation. Running the operation enqueue + result-block setup on MainActor puts CloudKit's internal callback dispatch on a queue it doesn't expect, tripping its queue-identity assertion. `nonisolated` lets the continuation body run off the main actor, satisfying CloudKit's expectations.

**How to apply:** Any `CK*Operation` → async/await bridge inside a `@MainActor` class (e.g. `@Observable @MainActor` view models / stores) must be `nonisolated func`. Confirmed against `CKFetchWebAuthTokenOperation` on macOS 26.5 in `Examples/MistDemo/Sources/MistDemoApp/Services/CloudKitStore.swift`. Reverting `fetchWebAuthTokenResultBlock` → `fetchWebAuthTokenCompletionBlock` is NOT the fix — the Swift overlay is fine; the isolation context is the bug.
