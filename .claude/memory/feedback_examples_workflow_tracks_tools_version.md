---
name: Examples workflow tracks subrepo tools-version
description: MistKit examples.yml must use a Swift container that can parse each example's Package.swift tools-version
type: feedback
---

`MistDemo`, `BushelCloud`, `CelestraCloud`, and `MistKitConfiguration` declare `swift-tools-version: 6.4`. Their CI runs on `swiftlang/swift:nightly-6.4.x-noble` (Linux) and `runs-on: xcode-27` (Apple). MistKit's parent `.github/workflows/examples.yml` must use a matching container for those matrix cells — a shared `swift:6.3` container fails immediately with "using Swift tools version 6.4.0 but the installed version is 6.3.x".

`.github/workflows/MistDemo.yml` likewise uses only the 6.4 nightly on Linux and Xcode 27 on macOS (Windows/Android lanes stay disabled until a 6.4 toolchain exists there). Prefer a per-example `matrix.include` with `container:` in `examples.yml` rather than one image for all four.

When bumping an example's tools-version (or adopting a nightly-only toolchain / a 6.4-only path dependency), update `examples.yml` and that example's dedicated workflow in the same pass.
