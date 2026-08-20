---
name: Swift Testing availability — keep guard #available in test methods
description: Never use @available on test suite types; use guard #available or @available on individual @Test functions instead
type: feedback
originSessionId: a40492dc-c16a-4cbb-b8fb-cd8f1fae5df2
---
Do NOT use `@available` on test suite types (`@Suite struct`) or their containing extensions. Swift Testing docs explicitly forbid it:

> "Although `@available` can be applied to a test function to limit its availability at runtime, a test suite type (and any types that contain it) must _not_ be annotated with the `@available` attribute."

**Why:** Swift Testing enforces that suite types are always available; annotating them with `@available` is a compiler error.

**How to apply:** Keep `guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { ... return }` inside individual `@Test` functions, or apply `@available` to individual `@Test` functions — never to the suite struct or its extension.
