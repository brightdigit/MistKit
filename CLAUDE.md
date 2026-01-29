# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MistKit is a Swift Package for Server-Side and Command-Line Access to CloudKit Web Services. This is a fresh rewrite on the `claude` branch using modern Swift features and best practices.

## Key Project Context

- **Purpose**: Provides a Swift interface to CloudKit Web Services (REST API) rather than the CloudKit framework
- **Target Platforms**: Cross-platform including Linux, server-side Swift, and command-line tools
- **Current Branch**: `claude` - A modern rewrite leveraging latest Swift advancements
- **API Reference**: The `openapi.yaml` file contains the OpenAPI 3.0.3 specification for Apple's CloudKit Web Services
- **Repository State**: Fresh start with OpenAPI spec as the foundation for implementation

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

# Format code (requires swift-format installation)
swift-format -i -r Sources/ Tests/

# Lint code (requires swiftlint installation)
swiftlint

# Auto-fix linting issues
swiftlint --fix
```

## Architecture Considerations

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

### CloudKit Web Services Integration
- Base URL: `https://api.apple-cloudkit.com`
- Authentication: API Token + Web Auth Token or Server-to-Server Key Authentication
- All operations should reference the OpenAPI spec in `cloudkit-api-openapi.yaml`
- URL Pattern: `/database/{version}/{container}/{environment}/{database}/{operation}`
- Supported databases: `public`, `private`, `shared`
- Environments: `development`, `production`

### Testing Strategy
- Use Swift Testing framework (`@Test` macro) for all tests
- Unit tests for all public APIs
- Integration tests using mock URLSession
- Use `#expect()` and `#require()` for assertions
- Async test support with `async let` and `await`
- Parameterized tests for testing multiple scenarios
- See `testing-enablinganddisabling.md` for Swift Testing patterns

## Important Implementation Notes

1. **Async/Await First**: All network operations should use async/await, not completion handlers
2. **Codable Compliance**: All models should be Codable with custom CodingKeys when needed
3. **CloudKit Types**: Map CloudKit types (Asset, Reference, Location) to Swift types appropriately
4. **Error Context**: Include request/response details in error types for debugging
5. **Pagination**: Implement AsyncSequence for paginated results (queries, list operations)

## OpenAPI-Driven Development

The Swift package uses Apple's swift-openapi-generator to create type-safe client code from the OpenAPI specification. Generated code is placed in `Sources/MistKit/Generated/` and should not be committed to version control.

The `openapi.yaml` file serves as the source of truth for:
- All available endpoints and their HTTP methods
- Request/response schemas and models
- Authentication requirements
- Error response formats

Key endpoints documented in the OpenAPI spec:
- Records: `/records/query`, `/records/modify`, `/records/lookup`, `/records/changes`
- Zones: `/zones/list`, `/zones/lookup`, `/zones/modify`, `/zones/changes`
- Subscriptions: `/subscriptions/list`, `/subscriptions/lookup`, `/subscriptions/modify`
- Users: `/users/current`, `/users/discover`, `/users/lookup/contacts`
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

- **AI Schema Workflow** (`Examples/Celestra/AI_SCHEMA_WORKFLOW.md`) - Comprehensive guide for understanding, designing, modifying, and validating CloudKit schemas with text-based tools
- **Quick Reference** (`Examples/SCHEMA_QUICK_REFERENCE.md`) - One-page cheat sheet with syntax, patterns, cktool commands, and troubleshooting
- **Task Master Integration** (`.taskmaster/docs/schema-design-workflow.md`) - Integrate schema design into Task Master PRDs and task decomposition

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
- We are using explicit ACLs in the Swift code
- type order is based on the default in swiftlint: https://realm.github.io/SwiftLint/type_contents_order.html
- Anything inside [CONTENT] [/CONTENT] is written by me