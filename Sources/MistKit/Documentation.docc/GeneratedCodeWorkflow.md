# Development Workflow for Generated Code

When to regenerate, what to commit, and how to review changes when `openapi.yaml` moves.

## Overview

MistKit commits its generated OpenAPI client code (`Sources/MistKitOpenAPI/Client.swift`, `Types.swift`) so that consumers don't need any generation tooling. The trade-off is that contributors take on a small discipline: regenerate after editing `openapi.yaml`, commit the spec change and the regenerated files together, and review the diff like any other code.

This article walks the workflow. For the toolchain itself see <doc:OpenAPICodeGeneration>; for what the generated code looks like see <doc:GeneratedCodeAnalysis>.

## Pre-generation vs. build plugin

MistKit pre-generates. The alternative — wiring the generator in as a SwiftPM build plugin — was considered and rejected:

| | Pre-generation (MistKit) | Build plugin |
| --- | --- | --- |
| Consumer needs `swift-openapi-generator` | No | Yes |
| Consumer build time | Fast | Adds generation step |
| Generated diffs visible in PRs | Yes | No |
| IDE indexes generated code | Immediately | After plugin runs |
| Contributor discipline | Regenerate after spec edits | None |

The discipline cost is small (one script, one commit) and is well-suited to a small core team. The consumer-side cost of a build plugin is paid by every downstream user.

## Initial setup

```bash
git clone https://github.com/brightdigit/MistKit.git
cd MistKit

# Install the pinned tools (mise reads mise.toml)
mise install

# Build to verify the committed generated code compiles in your environment
swift build

# Run tests
swift test
```

You shouldn't need to regenerate on a fresh clone — the generated files are already there.

## Editing the OpenAPI spec

### 1. Edit openapi.yaml

Common edits:

- A new path or operation.
- A schema property added, removed, or retyped.
- A new enum case on an existing string enum (filter comparator, server error code, …).
- A documentation string.

### 2. Regenerate

```bash
./Scripts/generate-openapi.sh
```

The script puts mise-managed binaries on `$PATH`, then runs `swift-openapi-generator generate` with `openapi-generator-config.yaml`. Both `Sources/MistKitOpenAPI/Client.swift` and `Sources/MistKitOpenAPI/Types.swift` are overwritten.

### 3. Update the wrapper

The hand-written layer often needs to follow. Common follow-ups:

- New operation → add a method on ``CloudKitService`` (typically a new file under `Sources/MistKit/CloudKitService/CloudKitService+*.swift`).
- New schema → add a domain model under `Sources/MistKit/Models/` and the conversion under `Sources/MistKit/Models/FieldValues/` (response → domain) or `Sources/MistKit/OpenAPI/Components/` (domain → request).
- Renamed enum case → fix any switch statements that referenced the old name. The compiler will list every site.
- Removed schema → remove any wrapper code that referenced it.

### 4. Tests + lint

```bash
swift build
swift test

mise exec -- swift-format -i -r Sources/ Tests/
mise exec -- swiftlint
```

Or the full pipeline:

```bash
./Scripts/lint.sh
```

### 5. Commit

Both the spec change and the regenerated files should land in the same commit (or back-to-back commits) so `git bisect` and code review can tell what produced the change:

```bash
git add openapi.yaml Sources/MistKitOpenAPI/ Sources/MistKit/…  # wrapper updates
git commit -m "feat(records): add /records/lookupChanges endpoint"
```

## Commit message style

MistKit follows the conventional-commits flavour visible in `git log`:

```
<type>(<scope>): <subject>

<body>
```

Common types and how they map to OpenAPI work:

| Type | When to use |
| --- | --- |
| `feat` | New endpoint or new schema property exposed via the wrapper |
| `fix` | Spec correction (wrong type, missing required field, …) |
| `refactor` | Spec restructuring with no functional change |
| `docs` | Documentation-only change in `openapi.yaml` |
| `chore` | Generator version bump or pure regeneration without spec changes |

Examples:

```
feat(zones): add lookupZones operation
fix(schemas): correct asset upload response shape
chore(deps): bump swift-openapi-generator to 1.10.3 in mise.toml
```

## Code review

When reviewing a PR that touches `openapi.yaml`:

1. **Start with the spec.** Is the change correct? Are required fields actually required? Are the response status codes complete?
2. **Check that generated code matches the spec.** A regenerated `Client.swift` / `Types.swift` should follow mechanically from the spec change. If the diff looks larger than the spec change explains, suspect either an unintended spec edit or a stale generator version.
3. **Review the wrapper.** This is where reviewer effort pays off: ergonomic API shape, error mapping, conversion correctness, test coverage.

Avoid review comments that target generated code style — that's the generator's output, not the author's choice. If the generated shape is genuinely problematic, file an issue against `swift-openapi-generator` or change the spec.

## Breaking changes

A change is "breaking" when it requires consumers of MistKit to update their code. The most common sources:

| Cause | Example |
| --- | --- |
| Required field added to a request | New mandatory `zoneID` on `RecordQuery` |
| Required field removed from a response | Wrapper code may decode-fail on responses from older deployments |
| Enum case removed or renamed | Switches in consumer code stop compiling |
| Parameter type changed | Existing call sites break |

For MistKit-API breaking changes, prefer the `feat!` / `BREAKING CHANGE:` convention in the commit body, and document the migration in `CHANGELOG.md`. While the package is pre-1.0 (currently 1.0.0-alpha/beta), some flexibility is acceptable — but the wrapper team has been careful to flag user-visible breakage explicitly.

If only the generated layer changes and the wrapper preserves its public shape, the change is *not* breaking for consumers — they never see the generated types.

## Updating the generator

```bash
# 1. Bump the pin in mise.toml
$EDITOR mise.toml
# "spm:apple/swift-openapi-generator" = "1.10.3"  →  e.g. "1.11.0"

# 2. Install the new version
mise install

# 3. Regenerate
./Scripts/generate-openapi.sh

# 4. Review the diff
git diff Sources/MistKitOpenAPI/

# 5. Build + test
swift build && swift test
```

Possible outcomes:

- **No diff** — generator improvements don't affect output for our spec. Commit only `mise.toml`.
- **Formatting / comment diff** — semantic equivalence, cosmetic change. Commit both.
- **Structural diff** — the generator produces different shapes for some construct. Update the wrapper to match before committing.

Commit message style:

```
chore(deps): bump swift-openapi-generator to 1.11.0 in mise.toml

Regenerated Sources/MistKitOpenAPI/. Tests pass; wrapper layer
unaffected.
```

## CI verification

A typical CI job to verify generated code is up to date:

```yaml
- name: Setup tools
  run: |
    curl https://mise.run | sh
    eval "$(~/.local/bin/mise activate bash)"
    mise install

- name: Regenerate
  run: ./Scripts/generate-openapi.sh

- name: Fail if generated code drifts from spec
  run: |
    if ! git diff --exit-code Sources/MistKitOpenAPI/; then
      echo "::error::Generated code is out of date. Run ./Scripts/generate-openapi.sh and commit."
      exit 1
    fi

- name: Build + test
  run: swift build && swift test
```

This catches the "edited `openapi.yaml`, forgot to commit the regenerated files" mistake before it lands.

## Troubleshooting

### Generated code refers to a symbol that doesn't exist

The committed files under `Sources/MistKitOpenAPI/` were produced from an earlier `openapi.yaml`. Regenerate:

```bash
./Scripts/generate-openapi.sh
swift build
```

### Generator version mismatch

`swift-openapi-generator --version` doesn't match the pin in `mise.toml`. Re-install:

```bash
mise install
mise exec -- swift-openapi-generator --version
```

### Merge conflict in generated files

Don't resolve by hand. Take one side arbitrarily, then regenerate from the merged `openapi.yaml`:

```bash
# Accept either side of the generated diff (doesn't matter which)
git checkout --theirs Sources/MistKitOpenAPI/

# Resolve the openapi.yaml conflict normally
$EDITOR openapi.yaml

# Regenerate from the merged spec
./Scripts/generate-openapi.sh

# Stage the now-correct generated files
git add openapi.yaml Sources/MistKitOpenAPI/
```

### Wrapper test fails after regeneration

A schema change rippled into the wrapper's conversion layer. Look at:

- `Sources/MistKit/Models/FieldValues/FieldValue+Components.swift` — response → domain
- `Sources/MistKit/OpenAPI/Components/Components.Schemas.FieldValueRequest.swift` — domain → request
- `Sources/MistKit/CloudKitService/CloudKitResponseProcessor*.swift` plus `Sources/MistKit/OpenAPI/Operations/Operations.*.Output.swift` — generated error → ``CloudKitError`` mapping
- `Sources/MistKit/Models/` — domain models that mirror schema fields

Fix the conversion, re-run `swift test`.

## What never to do

- **Don't edit `Sources/MistKitOpenAPI/` by hand.** Any change is silently lost the next time someone regenerates.
- **Don't commit `openapi.yaml` without the matching regenerated files.** The next CI run (and the next contributor) will surface drift.
- **Don't `--no-verify` past pre-commit hooks** to bypass linting on regenerated code. The `additionalFileComments` in `openapi-generator-config.yaml` emit `swift-format-ignore-file` and `periphery:ignore:all` so the linters already skip these files; if something complains, investigate before bypassing.
- **Don't ignore drift warnings in CI.** They almost always mean either an upstream generator update or someone forgot to commit a regeneration.

## See Also

- <doc:OpenAPICodeGeneration>
- <doc:GeneratedCodeAnalysis>
- <doc:AbstractionLayerArchitecture>
- [swift-openapi-generator releases](https://github.com/apple/swift-openapi-generator/releases)
- [mise documentation](https://mise.jdx.dev)
- [Conventional Commits](https://www.conventionalcommits.org/)
