# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MistKit is a Swift Package for Server-Side and Command-Line Access to CloudKit Web Services. It targets cross-platform Swift (including Linux, WASI, and Windows) using modern Swift concurrency and code generated from Apple's CloudKit Web Services OpenAPI specification.

## Key Project Context

- **Purpose**: Provides a Swift interface to CloudKit Web Services (REST API) rather than the CloudKit framework
- **Target Platforms**: Cross-platform including macOS, iOS, tvOS, watchOS, visionOS, Linux, WASI, and Windows
- **Default Branch**: `main`
- **API Reference**: The `openapi.yaml` file contains the OpenAPI 3.0.3 specification for Apple's CloudKit Web Services
- **Code Generation**: Generated client code lives in `Sources/MistKitOpenAPI/` (its own target/product) and is committed
- **Targets/products**: `MistKit` (curated wrapper) and `MistKitOpenAPI` (raw generated client + types, `public`). `import MistKit` for the curated API; add `import MistKitOpenAPI` only to reach raw generated types

## Development Commands

### Swift Package Commands
```bash
# Build the package
swift build

# Run tests
swift test

# Run tests with coverage
swift test --enable-code-coverage

# Build for release
swift build -c release

# Clean build artifacts
swift package clean

# Update dependencies
swift package update

# Resolve package dependencies
swift package resolve

# Generate Xcode project (if needed)
swift package generate-xcodeproj
```

### OpenAPI Code Generation
```bash
# Generate OpenAPI client code (run this after modifying openapi.yaml)
./Scripts/generate-openapi.sh

# Or manually with swift-openapi-generator
swift run swift-openapi-generator generate \
    --output-directory Sources/MistKitOpenAPI \
    --config openapi-generator-config.yaml \
    openapi.yaml
```

### Development Workflow
```bash
# Run specific test
swift test --filter TestClassName.testMethodName

# Run tests in parallel
swift test --parallel

# Show test output
swift test --verbose

# Format + lint
# swift-format, swiftlint, periphery, and swift-openapi-generator are pinned
# in mise.toml — do NOT invoke them from PATH directly. Run them THROUGH mise:
mise exec -- swift-format -i -r Sources/ Tests/
mise exec -- swiftlint              # lint
mise exec -- swiftlint --fix        # auto-fix

# Or run the full lint pipeline (build + swiftlint + header.sh + periphery):
./Scripts/lint.sh
```

### MistDemo Commands
```bash
# MistDemo is located in Examples/MistDemo and must be run from there
cd Examples/MistDemo

# Build MistDemo
swift build

# Run MistDemo commands
swift run mistdemo --help
swift run mistdemo auth-token
swift run mistdemo current-user
swift run mistdemo query
swift run mistdemo lookup
swift run mistdemo create
swift run mistdemo update
swift run mistdemo modify
swift run mistdemo delete
swift run mistdemo upload-asset
swift run mistdemo lookup-zones
swift run mistdemo fetch-changes
swift run mistdemo demo-in-filter
swift run mistdemo demo-errors
swift run mistdemo test-public
swift run mistdemo test-private

# Configuration (no config-file flag — MistDemo uses Swift Configuration):
# highest priority first — (1) CLI args, (2) CLOUDKIT_-prefixed env vars,
# (3) a .env file in the working dir (Examples/MistDemo/.env, CLOUDKIT_-prefixed),
# (4) in-memory defaults. Provide credentials via env vars or .env, e.g.:
#   CLOUDKIT_CONTAINER_ID=iCloud.com.yourorg.yourapp
#   CLOUDKIT_ENVIRONMENT=development
#   CLOUDKIT_API_TOKEN=…  CLOUDKIT_WEB_AUTH_TOKEN=…           # web-auth scopes
#   CLOUDKIT_KEY_ID=…     CLOUDKIT_PRIVATE_KEY[_PATH]=…       # server-to-server
# Recognized keys: CLOUDKIT_CONTAINER_ID, CLOUDKIT_DATABASE, CLOUDKIT_ENVIRONMENT,
# CLOUDKIT_API_TOKEN, CLOUDKIT_WEB_AUTH_TOKEN, CLOUDKIT_KEY_ID, CLOUDKIT_PRIVATE_KEY,
# CLOUDKIT_PRIVATE_KEY_PATH, CLOUDKIT_LOOKUP_EMAIL, CLOUDKIT_ERROR.
swift run mistdemo query
```

## Architecture Considerations

### FieldValue Type Architecture

MistKit uses separate types for requests and responses at the OpenAPI schema level to accurately model CloudKit's asymmetric API behavior:

**Type Layers:**
1. **Domain Layer**: `FieldValue` enum - Pure Swift types, no API metadata (`Sources/MistKit/Models/FieldValues/FieldValue.swift`)
2. **API Request Layer**: `FieldValueRequest` - Optional type field; CloudKit infers type from value structure, except for ambiguous scalars (see below) and IN/NOT_IN list filters, which are tagged explicitly
3. **API Response Layer**: `FieldValueResponse` - Optional type field for explicit type information

**Request type tagging (issue #375):** Most request values omit `type` and let CloudKit infer it from the value structure. Three scalar types are ambiguous on the wire and **must** carry an explicit `type`, otherwise CloudKit infers the wrong type and rejects the write with `BAD_REQUEST`:
- `TIMESTAMP` (`.date`) — a millisecond number, otherwise read as `INT64`/`DOUBLE`
- `BYTES` (`.bytes`) — a base64 string, otherwise read as `STRING`
- `DOUBLE` (`.double`) — a whole-valued double serializes without a fraction, otherwise read as `INT64`

Object/array-shaped values (`REFERENCE`, `ASSET`, `LOCATION`, `LIST`) and `STRING`/`INT64` are unambiguous and stay untagged. Tagging happens in `makeScalarRequest` (`Components.Schemas.FieldValueRequest.swift`). `type` is *not* required globally because CloudKit documents it as optional.

**Response type recovery (issue #375):** The generated `value` `oneOf` is *undiscriminated* — the decoder tries cases first-match-wins (`String → Int64 → Double → Bytes → Date`), so a whole-millisecond `TIMESTAMP` decodes as `Int64Value` and a base64 `BYTES` string decodes as `StringValue`. The response conversion therefore honors an explicit `type` *over* the decoded case (`makeTypedScalar` in `FieldValue+Components+Scalar.swift`). For the genuinely-ambiguous scalars whose correct interpretation differs from inference it produces the typed value directly: `TIMESTAMP`/`DOUBLE` from any numeric case, `BYTES` from any string case. `INT64`/`STRING` validate the category then defer to inference (which already yields them, and for `INT64` avoids truncating a fractional number). When `type` is absent it falls back to first-match-wins inference (`makeInferredScalar`), which is lossy for the ambiguous scalars (BYTES→`.string`, whole-number TIMESTAMP→`.int64`).

When a scalar `type` *contradicts* the value's category — a numeric type (`TIMESTAMP`/`DOUBLE`/`INT64`) over a non-number, or a string type (`STRING`/`BYTES`) over a non-string — the response is internally inconsistent and the conversion **throws** `ConversionError.typeValueMismatch` (via `requireNumeric`/`requireString`) rather than coercing to the value's shape. This matches the codebase's existing fail-loud `unmappableFieldValue` philosophy.

**Complex/list contradiction validation (issue #376):** the same fail-loud check now extends to the complex/list response `type` tags. A declared `REFERENCE`/`ASSET`/`ASSETID`/`LOCATION`/`LIST` whose decoded value isn't the matching `oneOf` case (`ReferenceValue`/`AssetValue`/`LocationValue`/`ListValue`) **throws** `ConversionError.typeValueMismatch` instead of silently coercing to the value's shape (`makeTypedComplex` in `FieldValue+Components.swift`, gated by the `ExpectedComplexValue` mapping). `ASSETID` shares `AssetValue` with `ASSET`; the `LIST` tag is validated only at the container level (element types stay lenient). Untagged responses are unaffected — they still resolve purely from the value's self-describing structure via `makeComplexFieldValue`, so well-formed responses never start failing.

**Why Separate Request/Response Types?**
- CloudKit API has asymmetric behavior: requests tag type only when ambiguous, responses may always include it
- OpenAPI schema accurately models this asymmetry (openapi.yaml:867-920)
- Swift code generation produces type-safe request/response types
- Compiler prevents accidentally using response types in requests
- Cleaner architecture without nil type values in conversion code

**Generated Types:**
- `Components.Schemas.FieldValueRequest` - Used for modify, create, filter operations
- `Components.Schemas.FieldValueResponse` - Used for query, lookup, changes responses
- `Components.Schemas.RecordRequest` - Records in request bodies
- `Components.Schemas.RecordResponse` - Records in response bodies

**Conversion:**
- Request conversion: `Sources/MistKit/OpenAPI/Components/Components.Schemas.FieldValueRequest.swift` converts domain `FieldValue` → `FieldValueRequest`
- Response conversion: `Sources/MistKit/Models/FieldValues/FieldValue+Components.swift` (entry point + complex types) and `FieldValue+Components+Scalar.swift` (scalar type recovery) convert `FieldValueResponse` → domain `FieldValue`

### Modern Swift Features to Utilize
- Swift Concurrency (async/await) for all network operations
- Structured concurrency with TaskGroup for parallel operations
- Actors for thread-safe state management
- Result builders for query construction
- Property wrappers for CloudKit field mapping

### Package Structure
```
MistKit/
├── Sources/
│   ├── MistKit/           # Curated wrapper (CloudKitService, domain types, auth)
│   └── MistKitOpenAPI/    # Generated OpenAPI client + types (public, committed)
├── Tests/
│   └── MistKitTests/
├── Scripts/
│   └── generate-openapi.sh # Script to generate OpenAPI code → Sources/MistKitOpenAPI/
├── openapi.yaml           # CloudKit Web Services OpenAPI specification
└── openapi-generator-config.yaml # Configuration for code generation
```

### CloudKitService Operations

`CloudKitService` operations are split across focused extension files (all paths relative to `Sources/MistKit/CloudKitService/`):

| File | Operations |
|------|-----------|
| `CloudKitService+Initialization.swift` | initializer overloads (API token, web auth token, server-to-server) |
| `CloudKitService+Operations.swift` | `queryRecords`, `queryAllRecords`, `lookupRecords` |
| `CloudKitService+WriteOperations.swift` | `modifyRecords`, `createRecord`, `updateRecord`, `deleteRecord` |
| `CloudKitService+ZoneOperations.swift` | `listZones`, `lookupZones(zoneIDs:)`, `fetchZoneChanges(syncToken:)` |
| `CloudKitService+ModifyZones.swift` | `modifyZones(_:database:)` |
| `CloudKitService+SyncOperations.swift` | `fetchRecordChanges(recordType:syncToken:)`, `fetchAllRecordChanges(recordType:syncToken:)` |
| `CloudKitService+UserOperations.swift` | `fetchCaller()`, `discoverUserIdentities(lookupInfos:)`, `discoverAllUserIdentities()` *(no-arg address-book form — unavailable, pending #28; distinct from the available `discoverAllUserIdentities(lookupInfos:batchSize:)` chunking overload below)*, `lookupUsersByEmail(_:)`, `lookupUsersByRecordName(_:)`, `fetchCurrentUser()` (deprecated, forwards to `fetchCaller`) |
| `CloudKitService+LookupAllRecords.swift` | `lookupAllRecords(recordNames:desiredKeys:database:batchSize:)` — auto-chunking convenience over `lookupRecords` |
| `CloudKitService+UserIdentityChunking.swift` | `discoverAllUserIdentities(lookupInfos:batchSize:)` — auto-chunking convenience over `discoverUserIdentities` |
| `CloudKitService+BatchChunking.swift` | internal `chunkedBatches` helper backing the auto-chunking conveniences |
| `CloudKitService+ShareOperations.swift` | `resolveShares(_:)`, `acceptShares(_:)` *(public DB + web-auth, fixed — no `database:` parameter)* |
| `CloudKitService+CreateShare.swift` | `createShare(...)` *(private custom zone + web-auth; returns ``CreatedShare``)* |
| `CloudKitService+AssetOperations.swift` | `uploadAssets`, `requestAssetUploadURL` |
| `CloudKitService+AssetUpload.swift` | `uploadAssetData` |
| `CloudKitService+RecordManaging.swift` | record-managing convenience surface |
| `CloudKitService+Classification.swift` | operation classification (batch sync result tracking) |
| `CloudKitService+ErrorHandling.swift` | error mapping helpers |

**Sync/Change Operations:**
- `fetchRecordChanges(recordType:syncToken:)` → `/records/changes` — returns `RecordChangesResult` with `records`, `syncToken`, `moreComing`
- `fetchAllRecordChanges(recordType:syncToken:)` — convenience wrapper that auto-paginates using `moreComing`
- `fetchZoneChanges(syncToken:)` → `/zones/changes` — returns `ZoneChangesResult`
- `lookupZones(zoneIDs:)` → `/zones/lookup` — returns `[ZoneInfo]`
- `discoverUserIdentities(lookupInfos:)` → POST `/users/discover` — takes `[UserIdentityLookupInfo]`, returns `[UserIdentity]`

**User-Identity Operations (public DB + web-auth required):**
- `fetchCaller()` → `/users/caller` — returns `UserInfo`. Replaces deprecated `fetchCurrentUser()` / `users/current`. Only valid against the public database with web-auth credentials.
- `discoverAllUserIdentities()` → GET `/users/discover` — returns `[UserIdentity]` for every discoverable user in the caller's address book.
- `lookupUsersByEmail(_:)` → POST `/users/lookup/email` — returns `[UserIdentity]`.
- `lookupUsersByRecordName(_:)` → POST `/users/lookup/id` — returns `[UserIdentity]`.

**Share Operations (issues #41 / #42 / #437 — create needs private custom zone + web-auth; resolve/accept are public DB + web-auth):**
- `createShare(...)` → `records/modify` — creates a root (`createShortGUID`) plus `cloudkit.share`, returns ``CreatedShare`` (`shortGUID`, share URL, ``ShareInfo``, root ``RecordInfo``).
- `resolveShares(_:)` → POST `/records/resolve` — resolves `[ShortGUID]` into `[ShareRecordInfo]` (root record, `cloudkit.share` record, owner identity, the caller's participation).
- `acceptShares(_:)` → POST `/records/accept` — accepts `[ShortGUID]` on behalf of the current user; returns the same `[ShareRecordInfo]` shape reporting the caller's resulting participation.

`createShare` writes against the caller's `database:` (typically `.private`) in a custom `zoneID`. Resolve/accept are documented **only** in Apple's archived CloudKit Web Services Reference (`FetchingRecordInformation` / `AcceptingShareRecords`), which fixes the path's database scope to `public`; they act on behalf of the *current* user, so — like `fetchCaller()` — they hard-code `.public(.requires(.webAuth))` and expose **no** `database:` parameter. Both validate the request as a whole: a bad short GUID fails the entire call rather than producing a per-item failure, so there is no `RecordResult`-style failure variant.

Set `ShortGUID.shouldFetchRootRecord` to have CloudKit include the shared root record, optionally narrowed by `rootRecordDesiredKeys`. When CloudKit cannot match the caller to exactly one invited participant, `ShareRecordInfo.potentialMatchList` is non-empty and the user must choose which invitation they are claiming. Domain models live in `Sources/MistKit/Models/Sharing/`.

**Batch chunking (issue #307):** the two non-deprecated operations capped at CloudKit's 200-item-per-request limit (`CloudKitService.maxRecordsPerRequest`) each pair a single-request primitive with an auto-chunking convenience that splits the input into ≤`batchSize` batches, calls the primitive per batch, and concatenates results in input order. This mirrors the `queryRecords`/`queryAllRecords` page-primitive + auto-paginating-extension pattern. Because chunk count is `ceil(input.count / batchSize)` — deterministic and finite — there is **no** `maxPages`-style throwing ceiling; `batchSize` (default `maxRecordsPerRequest`, clamped to `1...maxRecordsPerRequest`) is the only knob. The shared engine is `chunkedBatches` (`CloudKitService+BatchChunking.swift`).

| Primitive (single request) | Auto-chunking convenience |
|----------------------------|---------------------------|
| `lookupRecords(recordNames:desiredKeys:database:)` | `lookupAllRecords(recordNames:desiredKeys:database:batchSize:)` |
| `discoverUserIdentities(lookupInfos:)` | `discoverAllUserIdentities(lookupInfos:batchSize:)` *(overloads the no-arg address-book form)* |

The `users/lookup/email` and `users/lookup/id` primitives (`lookupUsersByEmail` / `lookupUsersByRecordName`) are **deprecated by Apple** in favor of POST `users/discover` (verified against Apple's archived CloudKit Web Services reference), so they intentionally get **no** chunking convenience — callers needing >200 should use `discoverAllUserIdentities(lookupInfos:)`. `users/lookup/contacts` is likewise deprecated and unwrapped.

`listZones` is **not** a pagination candidate — `zones/list` (GET) returns every zone in one response with no continuation marker. `modifyRecords`/`sync<T>` already chunk by 200 internally. The `fetchAllRecordChanges` / `fetchAllZoneChanges` paginators already implement the page-primitive pattern with `maxPages` + stuck-token detection.

In MistDemo, integration runs targeting these endpoints use `PhaseContext.userContextService` (a public+web-auth `CloudKitService`) which is built from `CLOUDKIT_API_TOKEN` + `CLOUDKIT_WEB_AUTH_TOKEN` regardless of the primary `--database` selection. The `DatabaseConfiguration` / `AuthenticationCredentials` types in `Examples/MistDemo/Sources/MistDemoKit/Configuration/` enforce valid database+auth combinations at construction time.

**Result Types (Sources/MistKit/Models/ and Sources/MistKit/Models/Zones/):**
- `QueryResult` — `records: [RecordInfo]`, `continuationMarker: String?`
- `RecordChangesResult` — `records: [RecordInfo]`, `syncToken: String?`, `moreComing: Bool`
- `ZoneChangesResult` — `zones: [ZoneInfo]`, `syncToken: String?`, `moreComing: Bool`
- `UserIdentity` — `userRecordName: String?`, `nameComponents: NameComponents?`, `lookupInfo: UserIdentityLookupInfo?`
- `UserIdentityLookupInfo` — `emailAddress: String?`, `phoneNumber: String?`, `userRecordName: String?`
- `NameComponents` — full personal name parts (givenName, familyName, nickname, etc.)

**Protocols:**
- `RecordTypeIterating` (`Sources/MistKit/RecordManagement/RecordTypeIterating.swift`) — `forEach(_ action:)` to iterate over CloudKit record types; used by `fetchAllRecordChanges`

### Key Design Principles
1. **Protocol-Oriented**: Define protocols for all major components (TokenManager, NetworkClient, etc.)
2. **Dependency Injection**: Use initializer injection for testability
3. **Error Handling**: Use typed errors conforming to LocalizedError
4. **Sendable Compliance**: Ensure all types are Sendable for concurrency safety

### Logging
MistKit uses [swift-log](https://github.com/apple/swift-log) for cross-platform logging. The package emits to four labeled subsystems; consumers install a `LogHandler` and choose verbosity via `logLevel`.

**Subsystems** (declared in `Sources/MistKit/Extensions/Logger+Subsystem.swift`):

| Label | Use |
|-------|-----|
| `com.brightdigit.MistKit.api`        | CloudKit API operations |
| `com.brightdigit.MistKit.auth`       | Authentication and token management |
| `com.brightdigit.MistKit.network`    | Network errors |
| `com.brightdigit.MistKit.middleware` | HTTP request/response traces (debug-level) |

**Internal usage** (inside MistKit):
```swift
let logger = Logger(subsystem: .api)
logger.debug("…")    // protocol detail
logger.warning("…")
logger.error("…")
```

**For consumers:** install a `LogHandler` (e.g. `StreamLogHandler.standardOutput`) via `LoggingSystem.bootstrap` and set the level per-subsystem. Protocol traces — request/response bodies, headers, query params — are emitted at `.debug`. The middleware guards expensive work (1 MiB body collection, query-param parsing) behind `logger.logLevel <= .debug`, so the default `.info` level pays no overhead.

There is no built-in redaction. Sensitive data (tokens, raw bodies) appears only at `.debug`; control exposure via `logLevel`.

### Asset Upload Transport Design

**⚠️ CRITICAL WARNING: Transport Separation**

When providing a custom `AssetUploader` implementation:
- **NEVER** use the CloudKit API transport (`ClientTransport`) for asset uploads
- **MUST** use a separate URLSession instance, NOT shared with api.apple-cloudkit.com
- **MUST NOT** share HTTP/2 connections between CloudKit API and CDN hosts
- Custom uploaders should **ONLY** be used for testing or specialized CDN configurations
- Production code should use the default implementation (`URLSession.shared`)

**Why URLSession instead of ClientTransport?**

Asset uploads use `URLSession.shared` directly rather than the injected `ClientTransport` to avoid HTTP/2 connection reuse issues:

1. **Problem:** CloudKit API (api.apple-cloudkit.com) and CDN (cvws.icloud-content.com) are different hosts
2. **HTTP/2 Issue:** Reusing the same HTTP/2 connection for both hosts causes 421 Misdirected Request errors
3. **Solution:** Use separate URLSession for CDN uploads, maintaining distinct connection pools

**Design:**
- `AssetUploader` closure type allows dependency injection for testing
- Default implementation uses `URLSession.shared.upload(_:to:)` with separate connection pool
- Tests provide mock uploader closures without network calls
- Platform-specific: WASI compilation excludes URLSession code via `#if !os(WASI)`
- **CRITICAL:** Custom uploaders must maintain connection pool separation from CloudKit API

**Implementation Details:**
- AssetUploader type: `(Data, URL) async throws -> (statusCode: Int?, data: Data)`
- Defined in: `Sources/MistKit/Models/AssetUploading/AssetUploader.swift`
- URLSession extension: `Sources/MistKit/Models/AssetUploading/URLSession+AssetUpload.swift`
- Upload orchestration:
  - `uploadAssets()` - Complete two-step upload workflow → `Sources/MistKit/CloudKitService/CloudKitService+AssetOperations.swift`
  - `requestAssetUploadURL()` - Step 1: Get CDN upload URL → `Sources/MistKit/CloudKitService/CloudKitService+AssetOperations.swift`
  - `uploadAssetData()` - Step 2: Upload binary data to CDN → `Sources/MistKit/CloudKitService/CloudKitService+AssetUpload.swift`

**Future Consideration:**
A `ClientTransport` extension could provide a generic upload method, but would need to:
- Handle connection pooling separately for different hosts
- Provide platform-specific implementations (URLSession, custom transports)
- Maintain the same testability via dependency injection

### FilterBuilder Extensions

`FilterBuilder` is split across extension files for maintainability:

- `Sources/MistKit/Models/Queries/FilterBuilder/FilterBuilder.swift` — core comparators (EQUALS, NOT_EQUALS, LESS_THAN, etc.) and IN/NOT_IN
- `Sources/MistKit/Models/Queries/FilterBuilder/FilterBuilder+StringFilters.swift` — string-specific: `beginsWith`, `notBeginsWith`, `containsAllTokens`
- `Sources/MistKit/Models/Queries/FilterBuilder/FilterBuilder+ListMemberFilters.swift` — list-specific: `listContains`, etc.

**IN/NOT_IN serialization:** Uses `ListValuePayload` (`Components.Schemas.ListValuePayload`) to wrap array values. The fix in v1.0.0-alpha.5 ensures the correct `value` key structure is used when serializing list comparators.

### CloudKit Web Services Integration
- Base URL: `https://api.apple-cloudkit.com`
- Authentication:
  - **Public database**: caller picks per-call via `PublicAuthPreference` carried on `Database.public(_:)`. Either `.requires(.serverToServer)` (key-pair signing — needs `CLOUDKIT_KEY_ID` + `CLOUDKIT_PRIVATE_KEY` or `CLOUDKIT_PRIVATE_KEY_PATH`) or `.requires(.webAuth)` (user-attributed — needs `CLOUDKIT_API_TOKEN` + `CLOUDKIT_WEB_AUTH_TOKEN`). Use `.prefers(_:)` to fall back to whichever cred is configured.
  - **Private / Shared database**: always `CLOUDKIT_API_TOKEN` + `CLOUDKIT_WEB_AUTH_TOKEN` → web-auth (CloudKit rejects S2S on these scopes).
- All operations should reference the OpenAPI spec in `openapi.yaml`
- URL Pattern: `/database/{version}/{container}/{environment}/{database}/{operation}`
- Supported databases: `Database.public(PublicAuthPreference)`, `Database.private`, `Database.shared`
- Environments: `development`, `production`

### Per-call attribution for `.public`

`Database` carries the signing choice when targeting public:

```swift
public enum Database {
  case `public`(PublicAuthPreference)
  case `private`
  case shared
}
```

`PublicAuthPreference` is constructed via two factories — never via the (internal) memberwise init:

- `.prefers(.serverToServer)` — try S2S, fall back to web-auth/API-token if S2S isn't configured.
- `.prefers(.webAuth)` — try web-auth, fall back to S2S if web-auth isn't configured.
- `.requires(.serverToServer)` — must use S2S; throw `missingCredentials(.preferenceRequired)` otherwise.
- `.requires(.webAuth)` — must use web-auth; throw `missingCredentials(.preferenceRequired)` otherwise.

There is **no default** on the operation `database:` parameter — every call must pick explicitly. The `requiresUserContext` flag on the dispatcher is gone; user-context routes (`users/*`) pass `.public(.requires(.webAuth))` directly. See `Sources/MistKit/Authentication/PublicAuthPreference.swift` and `Sources/MistKit/Authentication/Credentials+TokenManager.swift`.

### Testing Strategy
- Use Swift Testing framework (`@Test` macro) for all tests
- Unit tests for all public APIs
- Integration tests using mock URLSession
- Use `#expect()` and `#require()` for assertions
- Async test support with `async let` and `await`
- Parameterized tests for testing multiple scenarios
- See `testing-enablinganddisabling.md` for Swift Testing patterns

### Asset Upload Testing

**Integration Test Requirements:**
- Verify connection pool separation between CloudKit API and CDN
- Test HTTP/2 connection reuse prevention
- Validate 421 Misdirected Request error handling
- Mock uploaders should simulate realistic HTTP responses

**Test Files:**
- `Tests/MistKitTests/CloudKitService/Upload/CloudKitServiceTests.Upload+*.swift`
- `Tests/MistKitTests/Models/AssetUploading/AssetUploadTokenTests.swift`

### MistDemo Integration Test Runner

`Examples/MistDemo/Sources/MistDemoKit/Integration/` provides a live end-to-end test suite that runs against a real CloudKit container:

- `IntegrationTestRunner.swift` — orchestrates all operations (query, create, update, lookup, upload, fetchChanges, lookupZones, discoverUserIdentities)
- `IntegrationTestData.swift` — seed data for integration tests
- `IntegrationTestError.swift` — typed errors for test failures
- `IntegrationTest.swift`, `PhasedIntegrationTest.swift`, and `Tests/` subdirectory — protocol-based phase pipeline introduced in #283

Run via `swift run mistdemo test-public` or `swift run mistdemo test-private` (private database variant). Both commands require valid CloudKit credentials in the config file.

## Important Implementation Notes

1. **Async/Await First**: All network operations should use async/await, not completion handlers
2. **Codable Compliance**: All models should be Codable with custom CodingKeys when needed
3. **CloudKit Types**: Map CloudKit types (Asset, Reference, Location) to Swift types appropriately
4. **Error Context**: Include request/response details in error types for debugging
5. **Pagination**: Implement AsyncSequence for paginated results (queries, list operations)

## OpenAPI-Driven Development

The Swift package uses Apple's swift-openapi-generator to create type-safe client code from the OpenAPI specification. Generated code is placed in the standalone `MistKitOpenAPI` target at `Sources/MistKitOpenAPI/` (`accessModifier: public` so downstream code can `import MistKitOpenAPI` as an escape hatch). It is committed.

> **IMPORTANT: Never manually edit files in `Sources/MistKitOpenAPI/`.** These files are auto-generated from `openapi.yaml`. Any manual edits will be lost when code is regenerated. Instead, modify `openapi.yaml` and regenerate using `./Scripts/generate-openapi.sh`.

The `openapi.yaml` file serves as the source of truth for:
- All available endpoints and their HTTP methods
- Request/response schemas and models
- Authentication requirements
- Error response formats

Key endpoints documented in the OpenAPI spec:
- Records: `/records/query`, `/records/modify`, `/records/lookup`, `/records/changes`
- Zones: `/zones/list`, `/zones/lookup`, `/zones/modify`, `/zones/changes`
- Subscriptions: `/subscriptions/list`, `/subscriptions/lookup`, `/subscriptions/modify`
- Users: `/users/caller`, `/users/discover` (POST + GET), `/users/lookup/email`, `/users/lookup/id`
- Assets: `/assets/upload`
- Tokens: `/tokens/create`, `/tokens/register`

## Reference Documentation

Apple's official CloudKit documentation is available in `.claude/docs/` for offline reference during development:

### When to Consult Each Document

**webservices.md** (289 KB) - CloudKit Web Services REST API
- **Primary use**: Implementing REST API endpoints
- **Contains**: Authentication, request formats, all endpoints, data types, error codes
- **Consult when**: Writing API client code, handling authentication, debugging responses

**cloudkitjs.md** (188 KB) - CloudKit JS Framework
- **Primary use**: Understanding CloudKit concepts and operation flows
- **Contains**: Container/database patterns, operations, response objects, error handling
- **Consult when**: Designing Swift types, implementing queries, working with subscriptions

**testing-enablinganddisabling.md** (126 KB) - Swift Testing Framework
- **Primary use**: Writing modern Swift tests
- **Contains**: `@Test` macros, async testing, parameterization, migration from XCTest
- **Consult when**: Writing or organizing tests, testing async code

**swift-openapi-generator.md** (235 KB) - Swift OpenAPI Generator Documentation
- **Primary use**: Understanding code generation configuration and features
- **Contains**: Generator configuration, type overrides, middleware system, transport protocols, API stability
- **Consult when**: Configuring openapi-generator-config.yaml, implementing middleware, troubleshooting generated code

See `.claude/docs/README.md` for detailed topic breakdowns and integration guidance.

### MistDemo Documentation

- **Swift Configuration Reference** (`.claude/docs/mistdemo/swift-configuration-reference.md`) - Guide for using Swift Configuration in MistDemo
- **Official Swift Configuration Docs** (`.claude/docs/https_-swiftpackageindex.com-apple-swift-configuration-1.0.0-documentation-configuration.md`) - Full API reference

### CloudKit Schema Language

**cloudkit-schema-reference.md** - CloudKit Schema Language Quick Reference
- **Primary use**: Working with text-based .ckdb schema files
- **Contains**: Complete grammar, field options, data types, permissions, common patterns, MistKit-specific notes
- **Consult when**: Reading/modifying schemas, understanding indexing, designing record types

**sosumi-cloudkit-schema-source.md** - Apple's Official Schema Language Documentation
- **Primary use**: Authoritative reference for CloudKit Schema Language
- **Contains**: Full grammar specification, identifier rules, system fields, permission model
- **Consult when**: Understanding schema fundamentals, resolving syntax questions

### Comprehensive Schema Guides

For detailed schema workflows and integration:

- **AI Schema Workflow** (`Examples/CelestraCloud/.claude/AI_SCHEMA_WORKFLOW.md`) - Comprehensive guide for understanding, designing, modifying, and validating CloudKit schemas with text-based tools
- **Quick Reference** (`Examples/SCHEMA_QUICK_REFERENCE.md`) - One-page cheat sheet with syntax, patterns, cktool commands, and troubleshooting

## Examples

The `Examples/` directory contains working applications that dogfood MistKit-under-development (see also the README "Examples" list). These are MistKit-dev test beds, not end-user deployment templates.

### BushelCloud — the canonical MistKit pattern demonstration

`Examples/BushelCloud/` is the most complete reference implementation of MistKit's core patterns — the backend that syncs macOS restore images, Xcode, and Swift versions for the [Bushel app](https://getbushel.app):

- **Server-to-Server authentication** — loading an ECDSA `.pem` key and wiring `ServerToServerAuthManager` into `CloudKitService` (`Sources/BushelCloudKit/CloudKit/BushelCloudKitService.swift`, `PEMValidator.swift`).
- **Batch / chunked record operations** — working within CloudKit's 200-operations-per-request limit and aggregating results across batches (`CloudKit/SyncEngine.swift`, `CloudKit/BushelCloudKitService.swift`).
- **Multi-source data integration** — fetching and deduplicating from many upstream APIs (`DataSources/` — IPSW, MESU, AppleDB, XcodeReleases, SwiftVersion, …; `DataSourcePipeline+Deduplication.swift`).
- **CloudKit reference usage** — creating and resolving reference fields between record types (`DataSources/DataSourcePipeline+ReferenceResolution.swift`, `Extensions/XcodeVersionRecord+CloudKit.swift`).
- **Cross-platform logging** — swift-log with MistKit's subsystem organization (`Configuration/BushelConfiguration.swift`).

### CelestraCloud — query filtering, sorting & web etiquette

`Examples/CelestraCloud/` is a command-line RSS reader (backend for the [Celestra app](https://celestr.app)) demonstrating MistKit's `QueryFilter`/`QuerySort` APIs, GUID-based duplicate detection, and respectful HTTP client patterns. See its own `CLAUDE.md`.

### MistDemo — interactive auth & endpoint demo

`Examples/MistDemo/` is a CLI + App + Web demo exercising the beta.2 endpoint surface with web-auth token capture. See the project-level "MistDemo Commands" section above.

## Import Conventions

Every `import` statement must carry an explicit access modifier — `internal import X` or `public import X`. Bare `import X` is forbidden. Default to `internal`; use `public import` only when the module's types appear in this file's `public` API (e.g. `public import HTTPTypes` where `HTTPRequest` is part of a `public` signature).

Exceptions:
- `@testable import …` is its own modifier — no `internal`/`public` prefix.
- `Sources/MistKitOpenAPI/` is generated by swift-openapi-generator and currently emits a single bare `import HTTPTypes` in `Client.swift`. The generator doesn't expose an `accessModifierOnImports` setting yet, so that one line is a documented carve-out (SwiftLint already excludes this directory).

The convention is not lint-enforced (SwiftLint has no rule for import visibility), so it's a reviewer responsibility plus the precedent set by the codebase after #159.

## Additional Notes
- We are using explicit ACLs in the Swift code
- type order is based on the default in swiftlint: https://realm.github.io/SwiftLint/type_contents_order.html
- Anything inside [CONTENT] [/CONTENT] is written by me

## Memory & Corrections Convention

Versioned, in-repo agent memory is the source of truth for how to work in this repo. Read both stores at the start of every session before doing work:

| Store | Path | Purpose |
|-------|------|---------|
| Corrections log | `.claude/agent-notes.md` | Append-only standing always/never directives and human corrections (one line per entry; newest at bottom; supersede by editing/removing the stale line) |
| Project memory | `.claude/memory/` (+ `MEMORY.md` index) | One markdown file per project-scoped fact (decisions, constraints, gotchas, context not in code/git history); keep the index in sync; update/delete wrong entries |

**Proactive maintenance:** when the human corrects you or gives an always/never instruction, append to `.claude/agent-notes.md` without being asked. When you learn a durable project fact, write a memory file under `.claude/memory/` and add a one-line index entry in `MEMORY.md`.

**No native/global project memory:** `.claude/memory/` replaces Claude Code's `~/.claude/projects/<project>/memory/`, Cursor memories, and similar stores for this project. Do not save project-scoped memories there. The only allowed native-store entry is a pointer that memories live in-repo at `.claude/memory/`.