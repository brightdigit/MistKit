# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MistKit is a Swift Package for Server-Side and Command-Line Access to CloudKit Web Services. It targets cross-platform Swift (including Linux, WASI, and Windows) using modern Swift concurrency and code generated from Apple's CloudKit Web Services OpenAPI specification.

## Key Project Context

- **Purpose**: Provides a Swift interface to CloudKit Web Services (REST API) rather than the CloudKit framework
- **Target Platforms**: Cross-platform including macOS, iOS, tvOS, watchOS, visionOS, Linux, WASI, and Windows
- **Default Branch**: `main`
- **API Reference**: The `openapi.yaml` file contains the OpenAPI 3.0.3 specification for Apple's CloudKit Web Services
- **Code Generation**: Generated client code lives in `Sources/MistKit/Generated/` and is not committed

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
    --output-directory Sources/MistKit/Generated \
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

# Run with specific configuration
swift run mistdemo --config-file ~/.mistdemo/config.json query
```

## Architecture Considerations

### FieldValue Type Architecture

MistKit uses separate types for requests and responses at the OpenAPI schema level to accurately model CloudKit's asymmetric API behavior:

**Type Layers:**
1. **Domain Layer**: `FieldValue` enum - Pure Swift types, no API metadata (Sources/MistKit/FieldValue.swift)
2. **API Request Layer**: `FieldValueRequest` - No type field, CloudKit infers type from value structure
3. **API Response Layer**: `FieldValueResponse` - Optional type field for explicit type information

**Why Separate Request/Response Types?**
- CloudKit API has asymmetric behavior: requests omit type field, responses may include it
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
- Request conversion: `Extensions/OpenAPI/Components+FieldValue.swift` converts domain `FieldValue` → `FieldValueRequest`
- Response conversion: `Service/FieldValue+Components.swift` converts `FieldValueResponse` → domain `FieldValue`

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
│   └── MistKit/
│       ├── Generated/      # Auto-generated OpenAPI client code (not committed)
│       └── MistKitClient.swift  # Main client wrapper
├── Tests/
│   └── MistKitTests/
├── Scripts/
│   └── generate-openapi.sh # Script to generate OpenAPI code
├── openapi.yaml           # CloudKit Web Services OpenAPI specification
└── openapi-generator-config.yaml # Configuration for code generation
```

### CloudKitService Operations

`CloudKitService` operations are split across focused extension files:

| File | Operations |
|------|-----------|
| `CloudKitService+Initialization.swift` | initializer overloads (API token, web auth token, server-to-server) |
| `CloudKitService+Operations.swift` | `queryRecords`, `queryAllRecords`, `lookupRecords` |
| `CloudKitService+WriteOperations.swift` | `modifyRecords`, `createRecord`, `updateRecord`, `deleteRecord` |
| `CloudKitService+ZoneOperations.swift` | `listZones`, `lookupZones(zoneIDs:)`, `fetchZoneChanges(syncToken:)` |
| `CloudKitService+ModifyZones.swift` | `modifyZones(_:database:)` |
| `CloudKitService+SyncOperations.swift` | `fetchRecordChanges(recordType:syncToken:)`, `fetchAllRecordChanges(recordType:syncToken:)` |
| `CloudKitService+UserOperations.swift` | `fetchCaller()`, `discoverUserIdentities(lookupInfos:)`, `discoverAllUserIdentities()` *(unavailable — pending #28)*, `lookupUsersByEmail(_:)`, `lookupUsersByRecordName(_:)`, `fetchCurrentUser()` (deprecated, forwards to `fetchCaller`) |
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

In MistDemo, integration runs targeting these endpoints use `PhaseContext.userContextService` (a public+web-auth `CloudKitService`) which is built from `CLOUDKIT_API_TOKEN` + `CLOUDKIT_WEB_AUTH_TOKEN` regardless of the primary `--database` selection. The `DatabaseConfiguration` / `AuthenticationCredentials` types in `Examples/MistDemo/Sources/MistDemoKit/Configuration/` enforce valid database+auth combinations at construction time.

**Result Types (Sources/MistKit/Service/):**
- `QueryResult` — `records: [RecordInfo]`, `continuationMarker: String?`
- `RecordChangesResult` — `records: [RecordInfo]`, `syncToken: String?`, `moreComing: Bool`
- `ZoneChangesResult` — `zones: [ZoneInfo]`, `syncToken: String?`, `moreComing: Bool`
- `UserIdentity` — `userRecordName: String?`, `nameComponents: NameComponents?`, `lookupInfo: UserIdentityLookupInfo?`
- `UserIdentityLookupInfo` — `emailAddress: String?`, `phoneNumber: String?`, `userRecordName: String?`
- `NameComponents` — full personal name parts (givenName, familyName, nickname, etc.)

**Protocols:**
- `RecordTypeIterating` (`Sources/MistKit/Protocols/RecordTypeIterating.swift`) — `forEach(_ action:)` to iterate over CloudKit record types; used by `fetchAllRecordChanges`

### Key Design Principles
1. **Protocol-Oriented**: Define protocols for all major components (TokenManager, NetworkClient, etc.)
2. **Dependency Injection**: Use initializer injection for testability
3. **Error Handling**: Use typed errors conforming to LocalizedError
4. **Sendable Compliance**: Ensure all types are Sendable for concurrency safety

### Logging
MistKit uses [swift-log](https://github.com/apple/swift-log) for cross-platform logging support, enabling usage on macOS, Linux, Windows, and other platforms.

**Key Logging Components:**
- `MistKitLogger` - Centralized logging infrastructure with subsystems for `api`, `auth`, and `network`
- Environment-based privacy control via `MISTKIT_DISABLE_LOG_REDACTION` environment variable
- `SecureLogging` utilities for token masking and safe message formatting
- Structured logging in `LoggingMiddleware` for HTTP request/response debugging (DEBUG builds only)

**Logging Subsystems:**
```swift
MistKitLogger.api      // CloudKit API operations
MistKitLogger.auth     // Authentication and token management
MistKitLogger.network  // Network operations
```

**Helper Methods:**
```swift
MistKitLogger.logError(_:logger:shouldRedact:)    // Error level
MistKitLogger.logWarning(_:logger:shouldRedact:)  // Warning level
MistKitLogger.logInfo(_:logger:shouldRedact:)     // Info level
MistKitLogger.logDebug(_:logger:shouldRedact:)    // Debug level
```

**Privacy Controls:**
- By default, logs use `SecureLogging.safeLogMessage()` to redact sensitive information
- Set `MISTKIT_DISABLE_LOG_REDACTION=1` to disable redaction for debugging
- Tokens, keys, and secrets are automatically masked in logged messages

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
- Defined in: `Sources/MistKit/Core/AssetUploader.swift`
- URLSession extension: `Sources/MistKit/Extensions/URLSession+AssetUpload.swift`
- Upload orchestration:
  - `uploadAssets()` - Complete two-step upload workflow → `Sources/MistKit/Service/CloudKitService+AssetOperations.swift`
  - `requestAssetUploadURL()` - Step 1: Get CDN upload URL → `Sources/MistKit/Service/CloudKitService+AssetOperations.swift`
  - `uploadAssetData()` - Step 2: Upload binary data to CDN → `Sources/MistKit/Service/CloudKitService+AssetUpload.swift`

**Future Consideration:**
A `ClientTransport` extension could provide a generic upload method, but would need to:
- Handle connection pooling separately for different hosts
- Provide platform-specific implementations (URLSession, custom transports)
- Maintain the same testability via dependency injection

### FilterBuilder Extensions

`FilterBuilder` is split across extension files for maintainability:

- `Sources/MistKit/Helpers/FilterBuilder.swift` — core comparators (EQUALS, NOT_EQUALS, LESS_THAN, etc.) and IN/NOT_IN
- `Sources/MistKit/Helpers/FilterBuilder+StringFilters.swift` — string-specific: `beginsWith`, `notBeginsWith`, `containsAllTokens`
- `Sources/MistKit/Helpers/FilterBuilder+ListMemberFilters.swift` — list-specific: `listContains`, etc.

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

There is **no default** on the operation `database:` parameter — every call must pick explicitly. The `requiresUserContext` flag on the dispatcher is gone; user-context routes (`users/*`) pass `.public(.requires(.webAuth))` directly. See `Sources/MistKit/Authentication/PublicAuthPreference.swift` and `Sources/MistKit/Authentication/Credentials/Credentials+TokenManager.swift`.

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
- `Tests/MistKitTests/Service/CloudKitServiceUpload/CloudKitServiceTests.Upload+*.swift`
- `Tests/MistKitTests/Service/AssetUploadTokenTests.swift`

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

The Swift package uses Apple's swift-openapi-generator to create type-safe client code from the OpenAPI specification. Generated code is placed in `Sources/MistKit/Generated/` and should not be committed to version control.

> **IMPORTANT: Never manually edit files in `Sources/MistKit/Generated/`.** These files are auto-generated from `openapi.yaml`. Any manual edits will be lost when code is regenerated. Instead, modify `openapi.yaml` and regenerate using `./Scripts/generate-openapi.sh`.

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

## Additional Notes
- We are using explicit ACLs in the Swift code
- type order is based on the default in swiftlint: https://realm.github.io/SwiftLint/type_contents_order.html
- Anything inside [CONTENT] [/CONTENT] is written by me