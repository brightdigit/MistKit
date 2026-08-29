---
name: feedback-conditional-known-issue-overload
description: "For conditional withKnownIssue wrapping, prefer a `withKnownIssue(when:isIntermittent:_:)` overload that takes a Bool, not an if/else that duplicates the body"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ded31425-8f17-4a10-8ba7-7567c5299eb1
---

When a test body should be wrapped in `withKnownIssue(isIntermittent:)` only on certain platforms / environments, **add an overload** of `withKnownIssue` that takes a `when: Bool` and conditionally wraps internally. Don't write `if condition { withKnownIssue { body } } else { body }` at every call site.

**Why:** Body duplication is bug-prone (the two copies drift), bloats the diff, and makes the test less readable. An overload concentrates the conditional logic in one place and the call site reads identically to a plain `withKnownIssue` except for the added `when:` parameter.

**How to apply:** The overload shape (Examples/MistDemo/Tests/MistDemoTests/Utilities/TestingHelpers/WithKnownIssueWhen.swift in MistKit):

```swift
internal func withKnownIssue(
  _ comment: Comment? = nil,
  isIntermittent: Bool = false,
  when condition: Bool,
  sourceLocation: SourceLocation = #_sourceLocation,
  _ body: () async throws -> Void
) async {
  if condition {
    await withKnownIssue(comment, isIntermittent: isIntermittent, sourceLocation: sourceLocation, body)
  } else {
    do { try await body() }
    catch { Issue.record(error, sourceLocation: sourceLocation) }
  }
}
```

Take `() async throws -> Void` to cover both throwing and non-throwing bodies. The strict (false) path must `Issue.record` thrown errors so a thrown error is a visible failure (not silent), preserving the previous "must throw X" semantics.

Related: [[feedback-ci-only-flake-gate]] — the `when:` boolean usually comes from a `TestPlatform.*` predicate that AND-s platform with `CI` env.
