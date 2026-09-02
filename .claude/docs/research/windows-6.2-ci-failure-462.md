# Windows Swift 6.2 CI failure — `462-web-auth-token-rotation`

**Date:** 2026-09-02  
**Branch HEAD investigated:** `a6c5023` → fix attempts `a36fddd`, `4605cf7`  
**Failing job:** `Build on Windows (windows-2022, swift-6.2-release, 6.2-RELEASE)`  
**Primary log:** `/Users/leo/Downloads/windows-fialure.txt` (run `33640879394`)

## Verdict

**Swift 6.2 Windows toolchain silently aborts while emitting `MistKitTests`.** Library targets succeed. Same commit is green on Windows 6.1 and 6.3. Tip-over is MistKitTests size/complexity on this branch relative to `main` (not a single construct). Closest match in-repo is the wasm “silent exit-1 / no diagnostic” signature, but here it is **toolchain-version-specific** and **reproducible**.

## Evidence

### Same failure from first branch run

| Run | SHA | Windows 6.2 | Windows 6.1 / 6.3 |
|-----|-----|-------------|-------------------|
| `33523875168` | `4ccaa624` | fail (job `99909670558`) | success |
| `33640879394` | `a6c50236` | fail (job `100285122571`) | success |
| rerun of above | `a6c50236` | fail (job `100317077991`) | — |
| `33656677094` | `a36fddd` (class workaround) | fail (job `100336869940`) | 6.1 success |

Dies after `[1177/1186] Compiling MistKitTests TestConstants.swift` with `exit code 1` and **no** `error:` / stack dump / OOM text. No `Emitting module MistKitTests` line.

### Missing emit on 6.2 only

After `Wrapping AST for MistKit`, successful toolchains print emit then compile; 6.2 Windows has ~22s silence then Compiling with zero emit lines. On **main** Windows 6.2 (run `33399165875`), emit **does** appear and succeeds.

## Fixes tried

1. **`WebAuthTokenManager` actor → locked `Sendable` class** (`a36fddd`) — did **not** fix emit abort.
2. **TaskLocal test restructure** + typed-throws `catch as` cleanup — log quieter; emit still aborts.
3. **`Package.swift` `#if os(Windows)` exclude** of the seven `main...HEAD` added MistKitTests sources (`4605cf7`) — keeps Windows 6.2 in the matrix; coverage of those files remains on Ubuntu/macOS.

## Alternative (not applied)

Drop `swift-6.2-release` from the Windows matrix. Cleaner canary removal, but loses the Windows×6.2 job entirely. Prefer the exclude list unless it becomes untenable.

## Open questions

- Whether excluding only the three rotation files (without zone/write additions) would be enough was not isolated.
