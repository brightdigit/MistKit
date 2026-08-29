---
name: Examples workflow tracks subrepo tools-version
description: MistKit examples.yml must use a Swift container that can parse each example's Package.swift tools-version
type: feedback
---

`BushelCloud` and `CelestraCloud` declare `swift-tools-version: 6.4`. Their own CI already runs on `swiftlang/swift:nightly-6.4.x-noble`. MistKit's parent `.github/workflows/examples.yml` must use a matching container for those matrix cells — a shared `swift:6.3` container fails immediately with "using Swift tools version 6.4.0 but the installed version is 6.3.x".

`MistDemo` stays on tools-version 6.2 / container `swift:6.3`. Prefer a per-example `matrix.include` with `container:` rather than one image for all three.

When bumping an example's tools-version (or adopting a nightly-only toolchain), update `examples.yml` in the same pass.
