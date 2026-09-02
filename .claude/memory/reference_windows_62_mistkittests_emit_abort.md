---
name: windows-6.2-mistkittests-emit-abort
description: Swift 6.2 Windows silently aborts emitting MistKitTests; gate tip-over suites with #if Windows×6.2
metadata:
  node_type: memory
  type: reference
---

On Windows + Swift **6.2 only**, `swift build --build-tests` can die with exit 1 and **no** `error:`/stack dump after compiling `MistKitTests` — and **never** print `Emitting module MistKitTests`. Same commit is green on Windows 6.1/6.3; main’s Windows 6.2 emits successfully. Reproducible.

Tip-over is MistKitTests size/complexity — converting `WebAuthTokenManager` actor→class did **not** fix it. Mitigation: omit tip-over suites at compile time with `#if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))` (and `Platform.isWindowsSwift62`). Do not use `.disabled(if:)` alone — that still compiles. See `.claude/docs/research/windows-6.2-ci-failure-462.md`.
