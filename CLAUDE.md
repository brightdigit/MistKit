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

### CloudKit Web Services Integration
- Base URL: `https://api.apple-cloudkit.com`
- Authentication: API Token + Web Auth Token or Server-to-Server Key Authentication
- All operations should reference the OpenAPI spec in `cloudkit-api-openapi.yaml`
- URL Pattern: `/database/{version}/{container}/{environment}/{database}/{operation}`
- Supported databases: `public`, `private`, `shared`
- Environments: `development`, `production`

### Testing Strategy
- Unit tests for all public APIs
- Integration tests using mock URLSession
- Use `XCTAssertThrowsError` for error path testing
- Async test support with `async let` and `await`

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

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
- We are using explicit ACLs in the Swift code
- type order is based on the default in swiftlint: https://realm.github.io/SwiftLint/type_contents_order.html