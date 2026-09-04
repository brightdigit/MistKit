# MistKit Reference Documentation

Offline copies of external documentation, kept here so agents can consult them
without network access. Each file carries its source URL and download date in a
header comment.

This file is the **only** router for this directory: if you add a doc, add a row
below, and if a doc is not listed here, it is unreachable in practice.

## Dependency documentation

Docs for packages MistKit actually depends on (see `Package.swift`).

| Doc | Size | Consult when |
|-----|------|--------------|
| [swift-openapi-generator.md](swift-openapi-generator.md) | 235 KB | Configuring `openapi-generator-config.yaml`, type overrides, naming strategies, filtering the spec, troubleshooting generated code |
| [swift-openapi-runtime.md](swift-openapi-runtime.md) | 125 KB | Working with `Client`/`Types` in `Sources/MistKitOpenAPI/`, middleware, transports, `@_spi(Generated)` APIs, content types and streaming |
| [swift-configuration.md](swift-configuration.md) | 304 KB | MistDemo configuration — providers, precedence, key resolution. See also `mistdemo/swift-configuration-reference.md` for the MistKit-specific guide |
| [swift-log.md](swift-log.md) | 97 KB | Logger setup, metadata, log levels, handler behavior. See also AGENTS.md § Logging for MistKit's conventions |

## CloudKit API references

| Doc | Size | Consult when |
|-----|------|--------------|
| [webservices.md](webservices.md) | 282 KB | **Authoritative REST reference.** Implementing any endpoint, authentication, request/response formats, data types, error codes |
| [cloudkitjs.md](cloudkitjs.md) | 183 KB | Understanding CloudKit concepts and operation flows; designing Swift types that mirror CloudKit structures |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | 9 KB | Fast lookup — endpoint shapes, field types, query filters, error codes, type mapping, known endpoint discrepancies |

Archived Apple docs are not always complete. Verify endpoint details against
Apple's live/archived reference when something looks wrong — see
`.claude/memory/reference_cloudkit_archived_endpoints.md`.

## Schema

| Doc | Size | Consult when |
|-----|------|--------------|
| [cloudkit-schema-reference.md](cloudkit-schema-reference.md) | 9 KB | Reading/modifying `.ckdb` files — grammar, field options, permissions, MistKit-specific notes |
| [sosumi-cloudkit-schema-source.md](sosumi-cloudkit-schema-source.md) | 8 KB | Authoritative schema-language grammar, identifier rules, system fields |
| [schema-design-workflow.md](schema-design-workflow.md) | 15 KB | End-to-end schema design and validation workflow |

## Tooling

| Doc | Size | Consult when |
|-----|------|--------------|
| [cktool.md](cktool.md) / [cktool-full.md](cktool-full.md) | 6 / 4 KB | Native CLI for schema export/import, token management, seeding test data |
| [cktooljs.md](cktooljs.md) / [cktooljs-full.md](cktooljs-full.md) | 6 / 10 KB | JS library for programmatic schema deployment and CI automation |

## Testing

| Doc | Size | Consult when |
|-----|------|--------------|
| [testing-enablinganddisabling.md](testing-enablinganddisabling.md) | 123 KB | Swift Testing — `@Test`/`@Suite`, traits, parameterization, async, XCTest migration |
| [test-organization-guide.md](test-organization-guide.md) | 41 KB | How this repo organizes test files and parent types |

## MistDemo

`mistdemo/` holds the MistDemo design docs — start at
[mistdemo/README.md](mistdemo/README.md). `mistdemo/phases/` tracks
implementation phases.

## Research

`research/` holds dated investigations into specific failures, kept for the
reasoning rather than as current reference. Each is a point-in-time record.

## Related

Example-specific domain docs live with their examples, not here:

- `Examples/BushelCloud/.claude/` — firmware/MobileAsset wikis, data-source research
- `Examples/CelestraCloud/.claude/` — public-database architecture, schema setup
