---
name: windows-6.2-mistkittests-emit-abort
description: Swift 6.2 Windows silently aborts emitting MistKitTests; gate tip-over test bodies with #if + Issue.record
metadata:
  node_type: memory
  type: reference
---

On Windows + Swift **6.2 only**, `swift build --build-tests` can die with exit 1 and **no** `error:`/stack dump after compiling `MistKitTests` — and **never** print `Emitting module MistKitTests`. Same commit is green on Windows 6.1/6.3; main’s Windows 6.2 emits successfully. Reproducible.

Tip-over is MistKitTests size/complexity — converting `WebAuthTokenManager` actor→class did **not** fix it. Mitigation: omit tip-over **test bodies** at compile time with `#if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))` / `#else Issue.record`, keep `@Test`/`@Suite`/mocks compiled, and `.disabled(if: Platform.isWindowsSwift62)` for runtime. Do not use `.disabled(if:)` alone — that still compiles. See `.claude/docs/research/windows-6.2-ci-failure-462.md`.

`Issue.record` stubs must pass a **string literal** (→ `Comment`), not a `String` variable — on Windows Swift 6.2 `Issue.record(someString)` fails with `argument type 'String' does not conform to expected type 'Error'` (#484).

**Recurred 2026-09-14 on #392 / PR #485 (issue #488).** The threshold is bracketed by measured
`Tests/MistKitTests` totals: **24,858 lines / 258 files was green** (`eea8824`); **25,612 / 261
failed** (`a70f007`, after rebasing onto `v1.0.0-beta.6`). Body-gating 8 more tests did *not*
recover it (25,649 lines — gating adds source lines even as it removes emitted IR), so once the
module is over, shaving a few suites is not enough.

Note `v1.0.0-beta.6` has **never run the MistKit matrix** (its pushes only trigger MistDemo
Integration and CodeQL), so whether beta.6 alone crosses the threshold is untested — do not assume
it is inherited.

Windows 6.2 is now `continue-on-error: ${{ matrix.swift.version == 'swift-6.2-release' }}` on the
`build-windows` job in `.github/workflows/MistKit.yml`, which also unblocks the `lint` job (its
`if: !failure()` + `needs: [... build-windows ...]` made it report `skipping`). That **masks** the
symptom; #488 tracks the real fix, whose durable options are splitting `MistKitTests` into two
targets or dropping the 6.2 toolchain.
