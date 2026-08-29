---
name: "@available semantics: deprecated vs unavailable"
description: Use @available(*, unavailable) for not-yet-ready APIs; @available(*, deprecated) is reserved for symbols that have been replaced or should no longer be used
type: feedback
originSessionId: 696588e8-c0af-4abc-9190-8d2890f3b3fd
---
When marking a Swift API with `@available` to signal a state, pick the right keyword:

- `@available(*, deprecated, message: ...)` — the symbol is being phased out and there is a replacement (or callers should stop using it). Implies "use something else."
- `@available(*, unavailable, message: ...)` — the symbol exists in the source but is not callable. Use this for "not ready yet" / "implemented but not verified" / "removed and we want a custom error."
- `@available(*, deprecated, renamed: "...")` — explicit redirect to a renamed symbol; produces a Fix-It.

**Why:** During the #312 work I shipped `discoverAllUserIdentities()` with `@available(*, deprecated, message: "Not verified...")`. Leo flagged "deprecated is a misnomer" — the method isn't deprecated, it just isn't ready (live testing returned HTTP 500 from Apple). `unavailable` is the accurate semantic. `deprecated` carries baggage about replacement that doesn't apply here.

**How to apply:**

- "Use something else / will be removed" → `deprecated`
- "Renamed to X" → `deprecated, renamed:`
- "Implemented but not yet usable" / "removed; we want a custom error" → `unavailable`
- Default: read the message you're writing. If it doesn't suggest a replacement, `deprecated` is probably wrong.

Note that the Swift Testing `@Suite` and `@Test` macros forbid being placed on declarations marked `@available(*, deprecated)` or `@available(*, unavailable)`. If you mark a public method `unavailable`, its existing unit tests must be removed (they can't compile against an unavailable symbol). The codegen alone is verified by build; lose-of-coverage is the tradeoff.
