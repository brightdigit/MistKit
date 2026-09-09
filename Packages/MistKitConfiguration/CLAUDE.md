# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`MistKitConfiguration` is a small Swift 6.4 library (single `MistKitConfiguration` product) holding the CloudKit credential configuration glue shared by MistKit's server-side applications: read → validate → build a `CloudKitService`. It depends on **MistKit**, **ConfigKeyKit** and **apple/swift-configuration**. MistKit must never depend on it — the arrow points one way, which is the whole reason this is a separate repository rather than a MistKit product.

## Commands

- `make build` / `swift build`
- `make test` / `swift test` (Swift Testing, not XCTest)
- Run one suite: `swift test --filter KeyIDValidator`
- `make lint` — `Scripts/lint.sh`: swift-format, SwiftLint, license-header check, periphery
- `make clean`

Lint tooling is pinned via **mise** (`mise.toml`): swift-format 602.0.0, SwiftLint 0.62.2, periphery 3.7.4. Run `mise install` once so `Scripts/lint.sh` finds them outside CI.

## Architecture

Three layers, deliberately separated so that *reading* configuration cannot fail:

1. **`CloudKitConfiguration`** — raw, every field `String?`, no validation. `environment` stays a string so "unspecified" is distinguishable from "explicitly development" and an unrecognized value fails at validation rather than at read time.
2. **`validated()`** — checks presence *before* format, resolves inline PEM over a file path, parses the environment, and returns…
3. **`ValidatedCloudKitConfiguration`** — whose initializer is throwing and runs `KeyIDValidator` (and `PEMValidator` for an inline key). There is therefore **no way to hold this type with credentials that skipped format validation**; that property is what lets callers delete their own hand-rolled checks. Do not add a non-throwing initializer.

Supporting pieces: `CloudKitConfigurationKeys` (a value type, not a `static` enum, because the container default and env prefix are per-application), `readCloudKitConfiguration(keys:)` on the `ConfigValueReading` protocol, and `ConfigurationSources` for the provider stack.

## Conventions

- **Errors carry no prose.** `CloudKitConfigurationError`, `KeyIDValidationFailure` and `PEMValidationFailure` are `Equatable` enums and deliberately do **not** conform to `LocalizedError`. Every consumer already owns an error type with its own wording, remediation advice and key names; package-authored text would contradict all three. `ConfigurationError` is a presentation convenience this package never throws. Keep it that way.
- **`CloudKitConfigurationField`, not key strings.** Consumers spell the same field differently, so errors name a field and `CloudKitConfigurationKeys.subscript(_:)` maps it back to whatever key that application uses.
- **Key bases are dash-case** (`cloudkit.key-id`, never `cloudkit.key_id`). `CLIKeyEncoder` joins components verbatim, so an underscore produces an unusable flag *and* silently defeats secret redaction, since the redaction list matches the generated flag. `secretCommandLineFlags` is derived from `isSecret` so it cannot drift.
- **Swift 6.4** with `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility`, `FullTypedThrows` enabled. Mark every import `internal import` / `public import`; never bare `import`.
- Everything is `Sendable`. Typed throws (`throws(CloudKitConfigurationError)`) are used where the error set is closed.
- SwiftLint runs with `explicit_acl`, `explicit_top_level_acl`, `missing_docs`, `one_declaration_per_file` and `file_name` (severity **error** — the primary type's name must match the filename; extensions use `Type+Feature.swift`). No `!`.
- Every source file carries the MIT header; `Scripts/header.sh` enforces it.

## The MistKit dependency

`Package.swift` in the **monorepo** uses `.package(name: "MistKit", path: "../..")`. This is not a preference: a `path:` package takes its identity from the directory name, so mixing it with a sibling that depends on MistKit by `url:` makes SwiftPM resolve two distinct packages and fail with *"multiple similar targets 'MistKit', 'MistKitOpenAPI'"*. Every package in that monorepo must reach MistKit the same way.

The standalone repository carries the `url:` form instead — and **`git subrepo push` does not know that**. It would copy the `path:` line over and break the standalone repo, so the swap has to be re-applied after every push. That is the same never-merged-overlay discipline `Examples/BushelCloud/Package.swift` documents for its own MistKit line. CI swaps it with `brightdigit/MistKit/.github/actions/setup-mistkit@main`, pinned by `MISTKIT_BRANCH`. **That value must be a branch name, not a tag** — `git ls-remote` matches tags too, and a tag would silently pin an old release. Before cutting a release, the dependency must be a tagged `url:`, or the tag is unusable downstream; `dependency-policy.yml` gates PRs to `main` on exactly that.

## CI

Swift 6.4 has no Linux or Windows release toolchain, so `build-ubuntu` runs the single `swiftlang/swift:nightly-6.4.x` matrix entry, `build-windows` is commented out, there is no Android job, and macOS runs on `runs-on: xcode-27`. On that image tvOS must use `"Apple TV 4K (3rd generation)"` — there is no plain `"Apple TV"`. Restore the release lanes once Swift 6.4 ships them.
