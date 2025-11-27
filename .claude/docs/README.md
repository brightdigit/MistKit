# CloudKit Documentation Reference

This directory contains Apple's official documentation for CloudKit Web Services, CloudKit JS, and Swift Testing, downloaded for offline reference during MistKit development.

## File Overview

### webservices.md (289 KB)
**Source**: https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/

**Primary Use**: REST API implementation reference for MistKit's core functionality

**Key Topics**:
- **Authentication**: API tokens, server-to-server keys, web auth tokens
- **Request Composition**: URL structure, headers, request/response formats
- **Endpoints**:
  - Records: `/records/query`, `/records/modify`, `/records/lookup`, `/records/changes`
  - Zones: `/zones/list`, `/zones/lookup`, `/zones/modify`, `/zones/changes`
  - Subscriptions: `/subscriptions/*`
  - Users: `/users/current`, `/users/discover`, `/users/lookup/contacts`
  - Assets: `/assets/upload`
  - Tokens: `/tokens/create`, `/tokens/register`
- **Data Types**: Record dictionaries, field types, references, assets, locations
- **Error Handling**: Error response formats and codes

**When to Consult**:
- Implementing any CloudKit REST API endpoint
- Understanding request/response formats
- Implementing authentication mechanisms
- Working with CloudKit-specific data types
- Debugging API responses and errors

---

### cloudkitjs.md (188 KB)
**Source**: https://developer.apple.com/documentation/cloudkitjs

**Primary Use**: Understanding CloudKit concepts and data structures (adapted to Swift)

**Key Topics**:
- **Configuration**: Container setup, authentication flows
- **Core Classes**:
  - `CloudKit.Container`: Container access, authentication
  - `CloudKit.Database`: Database operations (public/private/shared)
  - `CloudKit.Record*`: Record operations and responses
  - `CloudKit.RecordZone*`: Zone management
  - `CloudKit.Subscription*`: Subscription handling
  - `CloudKit.Notification*`: Push notification types
- **Operations**:
  - Query operations with filters and sorting
  - Batch operations for records
  - Zone management
  - Subscription management
  - User discovery
  - Sharing records
- **Response Objects**: All response types and their properties
- **Error Handling**: `CKError` structure and error types

**When to Consult**:
- Designing Swift types that mirror CloudKit structures
- Understanding CloudKit operation flows
- Implementing query builders
- Working with subscriptions and notifications
- Understanding CloudKit error handling patterns
- Comparing JS API patterns to REST API

---

### testing-enablinganddisabling.md (126 KB)
**Source**: https://developer.apple.com/documentation/testing/enablinganddisabling

**Primary Use**: Writing modern Swift tests for MistKit

**Key Topics**:
- **Test Definition**: `@Test` macro for test functions
- **Test Organization**: `@Suite` for grouping tests
- **Conditional Testing**: `.enabled(if:)`, `.disabled()` traits
- **Parameterization**: Testing with collections of inputs
- **Async Testing**: `async`/`await` test support
- **Expectations**: `#expect()`, `#require()` macros
- **Migration**: Converting from XCTest to Swift Testing
- **Tags**: Categorizing tests with tags
- **Known Issues**: `.bug()` trait for tracking known failures
- **Parallelization**: Serial vs parallel execution

**When to Consult**:
- Writing new test functions
- Setting up test suites
- Implementing parameterized tests
- Testing async/await code
- Migrating from XCTest
- Organizing test execution

---

### swift-openapi-generator.md (235 KB)
**Source**: https://swiftpackageindex.com/apple/swift-openapi-generator/1.10.3/documentation/swift-openapi-generator

**Primary Use**: Code generation configuration and troubleshooting

**Key Topics**:
- **Generator Configuration**: YAML config options, naming strategies (defensive vs idiomatic), access modifiers
- **Type Overrides**: Replacing generated types with custom implementations (e.g., Foundation.UUID)
- **Document Filtering**: Generating subsets by operations, paths, or tags
- **Middleware System**: ClientMiddleware for auth, logging, retry logic
- **Transport Protocols**: ClientTransport abstraction, URLSession integration
- **Content Types**: JSON, multipart, URL-encoded, plain text, binary, streaming
- **Event Streams**: JSON Lines, JSON Sequence, Server-sent Events helpers
- **API Stability**: Understanding breaking vs non-breaking changes
- **Naming Strategies**: Defensive (safe) vs idiomatic (Swift-style) identifier mapping
- **Code Generation Modes**: Build plugin vs manual CLI invocation

**When to Consult**:
- Configuring `openapi-generator-config.yaml` settings
- Setting up custom type overrides for CloudKit types
- Implementing authentication or logging middleware
- Understanding generated code structure and evolution
- Troubleshooting "Decl has a package access level" errors
- Filtering large OpenAPI specs for specific operations
- Working with streaming responses or multipart uploads

---

### cktool.md / cktool-full.md
**Source**: https://developer.apple.com/icloud/ck-tool/

**Primary Use**: CloudKit command-line tool for schema and data management

**Files**:
- `cktool.md` - Curated summary with command examples
- `cktool-full.md` - Complete Apple documentation

**Key Topics**:
- **Authentication**: Management tokens, user tokens, Keychain storage
- **Schema Management**:
  - Reset development schema to production
  - Export schema to `.ckdb` files
  - Import schema from files to development
- **Data Commands**:
  - Query records with filters
  - Create records with JSON field definitions
- **Automation**: CI/CD integration, test data seeding
- **Token Management**: Saving and managing CloudKit tokens

**When to Consult**:
- Setting up development environments with CloudKit schemas
- Exporting/importing schemas for version control
- Automating schema deployment in CI/CD pipelines
- Seeding test data for MistKit integration tests
- Resetting development databases
- Understanding CloudKit Management API workflows

---

### cktooljs.md / cktooljs-full.md
**Source**: https://developer.apple.com/documentation/cktooljs/
**Version**: CKTool JS 1.2.15+

**Primary Use**: JavaScript library for CloudKit management operations

**Files**:
- `cktooljs.md` - Curated summary with key information
- `cktooljs-full.md` - Complete Apple documentation (41 pages)

**Key Topics**:
- **Core Modules**:
  - `@apple/cktool.database` - CloudKit types and operations
  - `@apple/cktool.target.nodejs` - Node.js configuration
  - `@apple/cktool.target.browser` - Browser configuration
- **Capabilities**:
  - Deploy schemas to Sandbox databases
  - Seed databases with test data
  - Restore Sandbox to production settings
  - Create automated integration test scripts
- **API Components**:
  - PromisesApi and CancellablePromise
  - Configuration for server communication
  - Container and ContainersResponse structures
  - Error handling framework

**When to Consult**:
- Building JavaScript-based CloudKit automation tools
- Creating CI/CD pipelines with Node.js
- Understanding CloudKit Management API from JS perspective
- Automating schema deployment programmatically
- Building developer tooling for CloudKit workflows
- Comparing management API patterns across platforms

---

## Quick Reference: When to Use Each Doc

### Implementing Core API Functionality
→ **webservices.md**: Authoritative source for all REST endpoints

### Designing Type Systems
→ **cloudkitjs.md**: Model CloudKit's data structures in Swift

### Configuring Code Generation
→ **swift-openapi-generator.md**: OpenAPI generator setup and troubleshooting

### Writing Tests
→ **testing-enablinganddisabling.md**: Modern Swift Testing patterns

### Schema Management & Automation
→ **cktool.md**: Native command-line tool for schema and data operations
→ **cktooljs.md**: JavaScript library for programmatic management

---

## Integration with MistKit Development

### Architecture Decisions
When designing MistKit's API surface:
1. Start with **webservices.md** for REST API capabilities
2. Reference **cloudkitjs.md** for ergonomic API design patterns
3. Adapt CloudKit JS patterns to Swift idioms (async/await, Result builders, etc.)

### Implementation Workflow
1. **Plan**: Review endpoint in `webservices.md`
2. **Design**: Check `cloudkitjs.md` for conceptual patterns
3. **Implement**: Write Swift code with async/await
4. **Test**: Use patterns from `testing-enablinganddisabling.md`

### Data Type Mapping
- CloudKit types → Swift types
- Reference **webservices.md** for wire format
- Reference **cloudkitjs.md** for semantic meaning

---

## Common Patterns

### Authentication Flow
1. **webservices.md** → Request signing, token formats
2. **cloudkitjs.md** → Authentication state management
3. **cktool.md** → Management token setup and storage

### Record Operations
1. **webservices.md** → `/records/modify` endpoint structure
2. **cloudkitjs.md** → `Database.saveRecords()` operation flow
3. **cktool.md** → Creating test records via CLI

### Query Operations
1. **webservices.md** → `/records/query` request format
2. **cloudkitjs.md** → Query filters, sort descriptors, pagination
3. **cktool.md** → Query filters via command-line

### Error Handling
1. **webservices.md** → HTTP status codes, error response format
2. **cloudkitjs.md** → `CKError` codes and retry logic
3. **cktooljs.md** → Error handling in management operations

### Development Workflows
1. **cktool.md** → Export/import schemas for version control
2. **cktooljs.md** → Programmatic schema deployment and automation
3. **webservices.md** → Understanding underlying API operations

---

## Documentation Ecosystem Map

```
CloudKit Development & Operations
├── Runtime APIs (Application Level)
│   ├── webservices.md ────────── REST API reference
│   ├── cloudkitjs.md ─────────── JS SDK for web apps
│   └── MistKit ───────────────── Swift implementation
│
├── Management APIs (Development Level)
│   ├── cktool.md ─────────────── Native CLI tool (Xcode)
│   └── cktooljs.md ───────────── JS library for automation
│
├── Code Generation
│   └── swift-openapi-generator.md ─ Generate Swift from OpenAPI
│
└── Testing
    └── testing-enablinganddisabling.md ─ Swift Testing framework
```

## Notes

- These docs are from Apple's official documentation and community sources
- Most content downloaded via llm.codes and filtered for relevance
- Last updated: November 4, 2025
- Corresponds to:
  - CloudKit Web Services (archived)
  - CloudKit JS 1.0+
  - Swift Testing (Swift 6.0+)
  - cktool (Xcode 13+)
  - CKTool JS (latest)
