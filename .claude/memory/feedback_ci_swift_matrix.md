---
name: CI Swift matrix preferences
description: For MistKit CI matrices, keep Swift 6.1 in the full matrix where it still compiles; do not include nightly Swift toolchains
type: feedback
originSessionId: d667433a-6b44-41ff-a056-470ceb1a865e
---
When designing or updating MistKit CI Swift matrices: include all stable Swift versions back to **6.1** in the full matrix where the code still compiles; do **not** add nightly toolchain entries (`swiftlang/swift:nightly-*` or `nightly: true` matrix flags).

**Why:** The user wants concrete, reproducible CI signal. Nightly toolchains break unpredictably and create flake noise without protecting any actual user. Keeping 6.1 in the full matrix preserves the support window for downstream consumers still on older toolchains.

**How to apply:** When editing `.github/workflows/MistKit.yml`, `swift-source-compat.yml`, MistDemo's workflow, or any subrepo workflow, default to a stable-only Swift matrix `[6.1, 6.2, 6.3, …]`. Drop any `nightly: true` matrix entries and any `swiftlang/swift:nightly-*` containers. Only re-introduce nightly if the user explicitly asks. If a specific Swift version genuinely doesn't compile, prefer documenting and fixing rather than silently dropping it from the matrix.
