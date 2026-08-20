---
name: feedback-sendable-api-fallback
description: "When a newer Sendable API would cascade an @available bump, prefer a dual-path with"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 830e9979-fc74-46ff-8944-82bc0d8d87bf
---

When a Sendable replacement API (e.g. `Date.ISO8601FormatStyle` vs `ISO8601DateFormatter`) would require bumping `@available` on existing code that already has a wide cascade of callers, do NOT bump availability. Use a dual-path helper:

```swift
nonisolated(unsafe) fileprivate static let legacyFormatter: ISO8601DateFormatter = { ... }()

fileprivate static func format(_ date: Date) -> String {
  if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
    return Self.modernFormatStyle.format(date)
  }
  return Self.legacyFormatter.string(from: date)
}
```

The modern Sendable type lives in a separately-gated `@available(macOS 12+, ...) extension` so its static storage is allowed to reference the newer type.

**Why:** Bumping `@available` on a type at the auth/service layer can cascade through `*AuthManager`, storage types, the `Authenticator` protocol references, and many call sites — invasive for what's effectively a small formatter optimization. The dual-path approach contains the change to one helper and respects the package's `platforms:` minimums (currently macOS 10.15 / iOS 13 driven by swift-crypto).

**How to apply:** When tempted to bump `@available` to pull in a Sendable API:
1. First check the cascade — how many call sites would need the bump?
2. If more than the file you're editing, prefer the dual-path helper with `nonisolated(unsafe)` on the legacy cached instance.
3. Document thread-safety of the legacy type in a comment (e.g. `ISO8601DateFormatter.string(from:)` is documented thread-safe).
4. Only bump `platforms:` in Package.swift on explicit user direction.

Related: [[feedback-explicit-import-access]] for the import-access style that pairs with this kind of low-level extension work.
