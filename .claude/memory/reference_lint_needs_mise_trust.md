---
name: reference_lint_needs_mise_trust
description: An untrusted mise.toml makes Scripts/lint.sh silently use the wrong SwiftLint and skip Periphery, producing phantom findings
metadata:
  type: reference
---

`Scripts/lint.sh` puts mise-managed tools on PATH via `eval "$(mise -C "$PACKAGE_DIR" env -s bash)"`.
If `mise.toml` is **untrusted** in this worktree, that `eval` silently produces nothing — mise exits
with `error parsing config file … are not trusted` on stderr and the script keeps going. The run then
uses whatever is on the bare PATH instead of the pinned versions.

Observed 2026-09-14 in the `392-encrypted-fields` worktree:

- SwiftLint fell back to bare **0.65.1** instead of the pinned **0.62.2**, inventing two
  `superfluous_disable_command` errors against `force_unwrapping` disable blocks in
  `CloudKitService.swift` and `Sharing/CreatedShare.swift`. Both files are untouched by the branch and
  carry the same blocks on `main`; the pinned version does not flag them. Acting on those would have
  deleted disable blocks that `.claude/agent-notes.md` explicitly endorses.
- **Periphery exited 127** (not installed on the bare PATH), so that leg never ran while still being
  reported as `"skipped": false`.

**Why:** a lint report that looks complete but silently ran the wrong tools is worse than no report —
the phantom findings point at correct, deliberate code.

**How to apply:** run `mise trust` once per worktree (each `git trees add` worktree needs its own),
then confirm `mise exec -- swiftlint version` reports the pinned version and
`mise exec -- periphery version` resolves before believing a lint run. In the JSON report, treat
`periphery.exitCode == 127` or a surprise SwiftLint rule as "the tools were wrong", not "the code is
wrong". Verify with `swift-format`/`swiftlint`/`swift-build`/`periphery` all at `exitCode` 0.

Note `Scripts/lint.sh` also shells out to `swift build`; see [[reference_use_xcrun_for_swift]] — under
the swiftly-managed toolchain that leg crashes swift-frontend and reports `exitCode: 1`, which is
likewise a toolchain artifact rather than a code error.
