# Windows Swift 6.2 CI failure — `462-web-auth-token-rotation`

**Date:** 2026-09-02  
**Failing job:** `Build on Windows (windows-2022, swift-6.2-release, 6.2-RELEASE)`  
**Primary log:** `/Users/leo/Downloads/windows-fialure.txt` (run `33640879394`)

## Verdict

**Swift 6.2 Windows toolchain silently aborts while emitting `MistKitTests`.** Library targets succeed. Same commit is green on Windows 6.1 and 6.3. Tip-over is MistKitTests size/complexity on this branch relative to `main`. Reproducible (not a flake). Closest match: wasm silent exit-1 signature, but toolchain-version-specific.

## Evidence

| Run | SHA | Windows 6.2 |
|-----|-----|-------------|
| `33523875168` | `4ccaa624` | fail |
| `33640879394` | `a6c50236` | fail |
| rerun | `a6c50236` | fail (not flake) |
| `33656677094` | `a36fddd` (actor→class) | fail — class workaround did **not** help |
| `33657978639` | `4605cf7`/`77d707a` (Package.swift Windows exclude) | success |

Dies after compiling MistKitTests sources with exit 1, **no** `error:` / stack dump, and **no** `Emitting module MistKitTests`. On success paths, emit appears then wrap/link.

## Mitigation (current)

Keep `@Suite` / `@Test` / mocks always compiled. Omit only each tip-over **test body** on **Windows × Swift 6.2**, with `Issue.record` in the `#else` (Swift Testing `#if canImport(…)` style), plus `.disabled(if: Platform.isWindowsSwift62)` on the `@Suite` so CI does not fail if tests run:

```swift
@Suite("…", .disabled(if: Platform.isWindowsSwift62))
internal struct Example {
  @Test("…")
  internal func example() async throws {
    #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
      // real body
    #else
      Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
    #endif
  }
}
```

`Platform.isWindowsSwift62` lives in `Tests/MistKitTests/Helpers/Platform.swift`. Traits alone cannot fix emit-module — the `#if` is load-bearing.

Windows 6.1/6.3 and all non-Windows platforms still compile and run the real bodies.

## Dead ends

- Restoring `WebAuthTokenManager` as a locked class (vs actor) — red herring.
- `Package.swift` `#if os(Windows)` `exclude:` — worked but was broader than needed (all Windows).
- Swift Testing `.disabled(if:)` alone — execution-only; does not shrink emit-module.
- Wrapping whole `@Suite` / files in `#if` — works but coarser than body gates.
