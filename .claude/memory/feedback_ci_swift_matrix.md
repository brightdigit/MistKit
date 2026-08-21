---
name: CI Swift matrix preferences
description: Keep Swift 6.1 in the full matrix; carry in-development Swift branches (6.4 snapshots) as a build-ubuntu matrix entry with an `image` override, never as a separate job
type: feedback
originSessionId: d667433a-6b44-41ff-a056-470ceb1a865e
---
When designing or updating MistKit CI Swift matrices: include all stable Swift versions
back to **6.1** in the full matrix where the code still compiles.

**In-development toolchains belong IN the `build-ubuntu` matrix, not in a job of their own.**
The user asked for Swift 6.4 (`release/6.4.x` snapshot) coverage in 2026-08 and pointed at
[ConfigKeyKit's workflow](https://github.com/brightdigit/ConfigKeyKit/blob/main/.github/workflows/ConfigKeyKit.yml)
as the reference shape. The pattern:

- Give the swift matrix entries an optional `image` key and let the snapshot entry carry it:
  `[{"version":"6.2"},{"version":"6.3"},{"version":"6.4","image":"swiftlang/swift:nightly-6.4.x"}]`
- Resolve the container with a fallback expression so stable and snapshot entries share one job:
  ```yaml
  container: ${{ matrix.swift.image && format('{0}-{1}', matrix.swift.image, matrix.os) || format('swift:{0}-{1}', matrix.swift.version, matrix.os) }}
  ```
- Exclude the snapshot entry from `wasm` / `wasm-embedded`: Swift nightly publishes no
  matching Wasm SDK snapshot.
- Only the **full** matrix carries the snapshot entry; the quick matrix stays on one stable version.

**Registry gotchas** (cost real time to discover):
- The official `swift` Docker image publishes **zero** nightly tags. Snapshots live only under
  the `swiftlang/swift` registry.
- The tag is `nightly-<branch>.x-<distro>` — `nightly-6.4.x-noble`. There is no
  `nightly-6.4-noble`; it 404s.

**Note on blocking:** ConfigKeyKit runs the snapshot entry as a normal, blocking matrix cell —
no `continue-on-error`. That is the house shape; match it. An earlier version of this note
proposed an advisory `continue-on-error` job instead, which the user rejected in favor of the
matrix entry.

**Supersedes:** the original form of this note said to add no nightly toolchains at all, and a
later revision said to add them as a separate advisory job. Both are wrong; the matrix-entry
pattern above is current.
