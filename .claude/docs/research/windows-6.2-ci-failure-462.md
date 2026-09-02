# Windows Swift 6.2 CI failure — `462-web-auth-token-rotation`

**Date:** 2026-09-02  
**Branch HEAD investigated:** `a6c5023`  
**Failing job:** `Build on Windows (windows-2022, swift-6.2-release, 6.2-RELEASE)`  
**Primary log:** `/Users/leo/Downloads/windows-fialure.txt` (run `33640879394`)

## Verdict

**Swift 6.2 Windows toolchain silently aborts while emitting `MistKitTests`.** Library targets succeed. Same commit is green on Windows 6.1 and 6.3. Trigger landed in `4ccaa62` (web-auth token rotation), which converted `WebAuthTokenManager` from a `Sendable` class to an `actor` and added rotation tests. Closest match in-repo is the wasm “silent exit-1 / no diagnostic” signature (OOM/frontend death), but here it is **toolchain-version-specific** rather than platform-wide.

## Evidence

### Same failure from first branch run

| Run | SHA | Windows 6.2 | Windows 6.1 / 6.3 |
|-----|-----|-------------|-------------------|
| `33523875168` | `4ccaa624` | fail (job `99909670558`) | success |
| `33640879394` | `a6c50236` | fail (job `100285122571`) | success |

First-run and latest-run both die after `[1177/1186] Compiling MistKitTests TestConstants.swift` with `exit code 1` and **no** `error:` / stack dump / OOM text. The `#require(info.atomic)` ambiguity on the first run was a red herring — fixed in `e303e6f`, failure unchanged.

### Missing emit on 6.2 only (same commit `a6c5023`)

After `Wrapping AST for MistKit`, successful toolchains print emit then compile:

- **Windows 6.3** (job on run `33640879394`): `[929/1013] Emitting module MistKitTests` → compiles → `Wrapping AST for MistKitTests` → link
- **Windows 6.1** (same run): `[954/1013] Emitting module MistKitTests` → …
- **Windows 6.2** (user log): ~22s **silence**, then `[929/1037] Compiling MistKitTests …` with **zero** `Emitting module MistKitTests` lines, then death at TestConstants / pre-wrap

On **main** Windows 6.2 (run `33399165875`, job `99510977543`): emit **does** appear (`[1000/1081] Emitting module MistKitTests`) and the job succeeds. So 6.2 Windows can emit this target — the branch tip-over is real.

### What `4ccaa62` changed

Sources: `git show 4ccaa62 --stat`

- `WebAuthTokenManager`: `final class … Sendable` → `actor` (mutable `webAuthToken` for rotation)
- New `TokenManager.didReceiveRotatedWebAuthToken`, middleware header consumption, `RotatedWebAuthTokenFailureReporter` (`@TaskLocal`)
- New tests: `AuthenticationMiddlewareTests+TokenRotation.swift`, rotation mocks

## Fix applied (this worktree)

1. **Restore `WebAuthTokenManager` as a locked `Sendable` class** — `NSLock` + sync `replaceWebAuthToken` helper (lock unavailable directly from `async` on current SDKs). Documents why not an actor.
2. **Restructure** `middlewareReturnsResponseWhenRotationFails` so `@TaskLocal.withValue` returns a single `HTTPResponse.Status` instead of destructuring a tuple from the async operation.
3. **Remove redundant** `catch let error as CloudKitError` on typed-throws call sites that flooded the Windows log with `'as' test is always true`.

## Reproducibility

Reran failed job without code changes (`gh run rerun 33640879394 --job 100285122571` → new attempt job `100317077991`): **failed again** the same way — last line `[1152/1186] Compiling MistKitTests TestConstants.swift`, no `Emitting module MistKitTests`, exit 1. **Not a flake.**

## Open questions

- Whether TaskLocal restructuring alone would have been enough was not isolated; actor→class is the higher-confidence tip-over undo.
- Dropping Windows 6.2 from the matrix was considered and rejected in favor of the source workaround.
