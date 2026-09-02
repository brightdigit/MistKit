---
name: windows-6.2-mistkittests-emit-abort
description: Swift 6.2 Windows silently aborts emitting MistKitTests (no error:); tip-over from WebAuthTokenManager-as-actor in #462
metadata:
  node_type: memory
  type: reference
---

On Windows + Swift **6.2 only**, `swift build --build-tests` can die with exit 1 and **no** `error:`/stack dump after compiling `MistKitTests` sources — and **never** print `Emitting module MistKitTests`. Same commit is green on Windows 6.1/6.3; main’s Windows 6.2 emits successfully. Reproducible (not a flake).

Signature matches wasm silent-exit (frontend abort / likely OOM) but is toolchain-version-specific. Tip-over is MistKitTests size/complexity on this branch — converting `WebAuthTokenManager` back from `actor` to a locked class did **not** fix it. Workaround: `Package.swift` excludes the branch-added test sources under `#if os(Windows)` so the 6.2 matrix entry stays. See `.claude/docs/research/windows-6.2-ci-failure-462.md`.
