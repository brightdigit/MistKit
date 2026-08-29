---
name: reference_wasm_ci_signatures
description: How to read the two distinct wasm CI failure signatures in MistKit/MistDemo (swift-build@v1)
metadata: 
  node_type: memory
  type: reference
  originSessionId: 5df7555c-4d67-469f-a0bb-5206537544a7
---

Two unrelated wasm CI failure modes seen via `brightdigit/swift-build@v1` (both surface only under `gh run view --job <id> --log-failed`, since the interesting output is mid-log, not the tail which is git/container cleanup):

1. **Silent swiftc death, no diagnostic** — build reaches `[NNNN/NNNN] Compiling <BigTestTarget> X.swift` then `##[error]Process completed with exit code 1` with NO `error:`/stack-dump. This is the OOM-killer SIGKILLing the frontend on the memory-constrained wasm cross-compile. Correlates with a large, type-check-heavy test target (watch for many `took NNNms to type-check (limit: 100ms)` warnings from the `-warn-long-expression-type-checking=100` swiftSettings). All identical GitHub runners cross the memory threshold together, so it looks all-pass→all-fail on a small addition.

2. **curl: (7) Couldn't connect to server → exit code 7** — fast (~48s) failure in the SDK-install step downloading `download.swift.org/.../*_wasm.artifactbundle.tar.gz`. Transient network flake; just re-run. Hardening the download (retries) belongs in the swift-build action repo, not MistKit. Swift.org publishes no checksums for -RELEASE wasm SDKs.

Note: wasm builds still `--build-tests` but can't execute xctest (action warns "Found .xctest bundles in Wasm build (unexpected)"), so wasm's only value is compile-checking. `build-only: true` (gated on `startsWith(matrix.type,'wasm')`) skips the test target on wasm. The ubuntu build job's matrix `type: ["","wasm","wasm-embedded"]` reuses one job for native Linux (runs tests) + wasm, so any build-only toggle must be conditional on matrix.type.
