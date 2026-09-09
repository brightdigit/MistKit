# OpenAPI Code Generation Setup

How MistKit turns `openapi.yaml` into a type-safe Swift client at development time, and why that pipeline is set up the way it is.

## Overview

MistKit ships a hand-written wrapper layer on top of code generated from Apple's CloudKit Web Services OpenAPI specification by [`swift-openapi-generator`](https://github.com/apple/swift-openapi-generator). The generator runs at development time — not at consumer build time — so library users get a working package without having to install any generation tooling.

This article documents the toolchain (mise + the generator), the configuration file, and the request/response asymmetry that drives MistKit's custom type setup.

## Why generate code at all

Generating from the OpenAPI spec gives:

- **A single source of truth.** The schema is `openapi.yaml`; the Swift types track it.
- **Compile-time safety.** Every request path, parameter, header, and response status is typed.
- **Free Codable.** Request and response bodies decode without hand-written model definitions.
- **A cheap-to-rerun pipeline.** When CloudKit's API changes, regenerating is one command.

What the wrapper layer adds on top — typed records, async iteration, structured errors, three auth schemes — is described in <doc:AbstractionLayerArchitecture>.

## Architecture

```
openapi.yaml
     │
     ▼
swift-openapi-generator  (provisioned by mise)
     │
     ├── Sources/MistKitOpenAPI/Client.swift   (~5,000 lines, committed)
     └── Sources/MistKitOpenAPI/Types.swift    (~14,200 lines, committed)
     │
     ▼
Hand-written wrapper (Sources/MistKit/, committed)
     │
     ├── CloudKitService + extensions
     ├── Authenticator family + AuthenticationMiddleware
     ├── FieldValue / RecordInfo / QueryFilter / …
     └── FieldValueRequest/Response conversions
```

## Toolchain: mise

MistKit pins build-time tools in `mise.toml`:

```toml
[tools]
"spm:swiftlang/swift-format"            = "602.0.0"
"aqua:realm/SwiftLint"                  = "0.62.2"
"spm:peripheryapp/periphery"            = "3.7.4"
"spm:apple/swift-openapi-generator"     = "1.10.3"
```

Tools are run through `mise exec` to keep the project pin authoritative regardless of what's on `$PATH`:

```bash
mise exec -- swift-format -i -r Sources/ Tests/
mise exec -- swiftlint --fix
mise exec -- swift-openapi-generator --version
```

`./Scripts/generate-openapi.sh` puts mise's `$PATH` shims in front of the user's shell and calls `swift-openapi-generator generate`. When the generator is not on `$PATH` (CI containers, remote sessions) it falls back to `swift run --package-path Scripts/OpenAPITools swift-openapi-generator`, a tiny package that pins the same generator version, so regeneration works without mise. There is no Mintfile; references in older documentation to `mint`/`Mintfile` are out of date.

## Generation script

```bash
#!/bin/bash
set -e

echo "🔄 Generating OpenAPI code..."

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PACKAGE_DIR="${SCRIPT_DIR}/.."

# Put mise-managed tools on PATH
if command -v mise >/dev/null 2>&1 && [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  eval "$(mise -C "$PACKAGE_DIR" env -s bash)"
fi

pushd "$PACKAGE_DIR" || exit

if command -v swift-openapi-generator >/dev/null 2>&1; then
  GENERATOR=(swift-openapi-generator)
else
  echo "ℹ️  swift-openapi-generator not on PATH; building it from Scripts/OpenAPITools."
  GENERATOR=(swift run --package-path Scripts/OpenAPITools swift-openapi-generator)
fi

"${GENERATOR[@]}" generate \
    --output-directory Sources/MistKitOpenAPI \
    --config openapi-generator-config.yaml \
    openapi.yaml

popd

echo "✅ OpenAPI code generation complete!"
```

Run it whenever `openapi.yaml` or `openapi-generator-config.yaml` changes:

```bash
./Scripts/generate-openapi.sh
```

## Configuration

`openapi-generator-config.yaml`:

```yaml
generate:
  - types
  - client
accessModifier: public
additionalFileComments:
  - periphery:ignore:all
  - swift-format-ignore-file
```

| Key | Effect |
| --- | --- |
| `generate` | Emit `Types.swift` (schemas) and `Client.swift` (operations + transport plumbing). No server stubs — MistKit is a client. |
| `accessModifier: internal` | Generated symbols are module-internal; the public surface is the hand-written wrapper. |
| `additionalFileComments` | Inserts `periphery:ignore:all` so the dead-code linter skips the file, and `swift-format-ignore-file` so the formatter leaves it alone. |

There is intentionally no `typeOverrides` block. The asymmetry between request and response field values is handled at the schema level instead — see "Request/response asymmetry" below.

## Package.swift integration

Generated code lives in its own target and product, `MistKitOpenAPI`, which the `MistKit` target depends on with `internal import MistKitOpenAPI`. Consumers who need the raw client can `import MistKitOpenAPI` directly. The generator is **not** used as a SwiftPM build plugin. Library consumers don't need mise or `swift-openapi-generator`; they just compile the committed sources.

The runtime dependencies pulled in by the generated client:

```swift
.package(url: "https://github.com/apple/swift-openapi-runtime",  from: "1.8.0"),
.package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.2.0"),
```

Plus MistKit's other dependencies: `swift-crypto` (server-to-server signing) and `swift-log`. `HTTPTypes` arrives transitively through `swift-openapi-runtime`.

## Swift language settings

MistKit declares `swift-tools-version: 6.1`. The `MistKit` target compiles with the Swift 6 language mode plus the upcoming features that `Package.swift` enables in its shared `swiftSettings` — including `InternalImportsByDefault`, which is why every import in the hand-written sources carries an explicit access modifier (`internal import Foundation`, `public import HTTPTypes`, …). The generated `MistKitOpenAPI` target is compiled without those settings so the generator's output never has to be post-processed; its single bare `import HTTPTypes` in `Client.swift` is the documented exception to the import convention.

## Request/response asymmetry

The CloudKit API treats field values differently in requests and responses:

- **Request bodies** omit the `type` field; CloudKit infers the type from the value's structure.
- **Response bodies** sometimes include the `type` field explicitly.

`openapi.yaml` reflects this with two schemas (around lines 867–920):

| Schema | Used in | Has `type` field |
| --- | --- | --- |
| `FieldValueRequest` | `RecordRequest` | No |
| `FieldValueResponse` | `RecordResponse` | Optional |

That asymmetry flows through code generation:

- `Components.Schemas.FieldValueRequest`
- `Components.Schemas.FieldValueResponse`
- `Components.Schemas.RecordRequest`
- `Components.Schemas.RecordResponse`

The compiler refuses to slot a response value into a request, and vice versa. Conversions to and from the single domain ``FieldValue`` enum live in:

- `Sources/MistKit/OpenAPI/Components/Components.Schemas.FieldValueRequest.swift` — domain → `FieldValueRequest`.
- `Sources/MistKit/Models/FieldValues/FieldValue+Components.swift` — `FieldValueResponse` → domain.

## Files produced

```
Sources/MistKitOpenAPI/
├── Client.swift   (~5,000 lines, committed)
└── Types.swift    (~14,200 lines, committed)
```

Both files lead with:

```swift
// Generated by swift-openapi-generator, do not modify.
// periphery:ignore:all
// swift-format-ignore-file
@_spi(Generated) import OpenAPIRuntime
```

The anatomy of these files — `APIProtocol`, `Components.Schemas.*`, `Operations.*`, `Servers.Server1` — is covered in detail in <doc:GeneratedCodeAnalysis>.

## Version control

`Sources/MistKitOpenAPI/` is **committed**. Library consumers get a working package without installing mise or `swift-openapi-generator`. Two consequences:

1. Pull requests touching `openapi.yaml` should also include the regenerated `Client.swift` / `Types.swift` so reviewers see the API change.
2. CI verifies that committed generated code matches what the current `openapi.yaml` would produce (re-run the generator, diff the output) — drift fails the build.

`./Scripts/generate-openapi.sh` is idempotent — run it after editing `openapi.yaml` or bumping the generator version in `mise.toml`, then commit both the spec change and the regenerated files in the same commit.

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `swift-openapi-generator: command not found` | mise tools not on `$PATH` | `mise install` then `eval "$(mise env -s bash)"` (or use `./Scripts/generate-openapi.sh`, which does this for you) |
| Generated code doesn't compile | Wrapper extensions reference a renamed/removed symbol | Re-run the generator; then update the affected extension in `Sources/MistKit/CloudKitService/` or `Sources/MistKit/OpenAPI/Components/` |
| `Sources/MistKitOpenAPI/` is unexpectedly empty | Accidental deletion or merge issue | `./Scripts/generate-openapi.sh`, then commit the result |
| Linter complains about generated files | The header comments were stripped | Regenerate; do not hand-edit. `additionalFileComments` re-emits the linter pragmas |

Never edit anything under `Sources/MistKitOpenAPI/` by hand — change `openapi.yaml` and regenerate.

## See Also

- <doc:FieldTypePolymorphism>

- <doc:GeneratedCodeAnalysis>
- <doc:GeneratedCodeWorkflow>
- <doc:AbstractionLayerArchitecture>
- [`swift-openapi-generator` documentation](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator)
- [OpenAPI Specification 3.0.3](https://spec.openapis.org/oas/v3.0.3)
- [CloudKit Web Services API](https://developer.apple.com/documentation/cloudkitwebservices)
