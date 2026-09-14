---
name: reference_use_xcrun_for_swift
description: On macOS, when swiftly lacks the pinned toolchain, run Swift via xcrun — the swiftly-managed swift crashes swift-frontend
metadata:
  type: reference
---

**On macOS only, and only when swiftly has no toolchain matching the pinned `.swift-version`**,
invoke Swift through `xcrun` — `xcrun swift build`, `xcrun swift test` — rather than the bare
`swift` on PATH. When swiftly *does* have the pinned toolchain, use it; this is a fallback, not a
blanket rule.

`xcrun` is an Xcode tool and **does not exist on Linux**. Ubuntu CI and any Linux agent invoke
`swift` directly — applying this rule there breaks the build.

Observed 2026-09-14 on the `392-encrypted-fields` worktree: the swiftly-managed default
(`~/Library/Developer/Toolchains/swift-6.3.2-RELEASE.xctoolchain`, matching the root `.swift-version`
of `6.3.2`) **crashed swift-frontend** with a stack dump while building the root package. `xcrun`
resolves to `/Applications/Xcode.app/…/XcodeDefault.xctoolchain` (Swift 6.4) and builds and tests
cleanly: 689 root tests, 1020 MistDemo tests.

`xcrun` also sidesteps a second problem: `Examples/MistDemo/.swift-version` pins `6.4`, and swiftly has
only `6.4.x-snapshot-*` installed (no release 6.4), so swiftly refuses to run there at all
("uses toolchain version 6.4, but it doesn't match any of the installed toolchains").

**Why:** a swift-frontend crash reads like a code error but is a toolchain artifact. It also corrupts
the `Scripts/lint.sh` report, whose `swift-build` leg exits 1 for the same reason — see
[[reference_lint_needs_mise_trust]].

**How to apply:** prefix Swift commands with `xcrun`. When a script shells out to `swift` internally
(`Scripts/lint.sh` does), put the Xcode toolchain first on PATH for that invocation:
`export PATH="$(dirname "$(xcrun --find swift)"):$PATH"`. Beware that piping to `tail`/`grep` makes
`$?` the pipe's exit code, not the compiler's — capture `${PIPESTATUS[0]}` or echo an explicit
`EXIT=$?` marker before filtering, or a crashed build reads as success.
