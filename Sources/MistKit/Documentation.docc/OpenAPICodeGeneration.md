# OpenAPI Code Generation Setup

A comprehensive guide to the swift-openapi-generator integration and code generation workflow in MistKit.

## Overview

MistKit uses [swift-openapi-generator](https://github.com/apple/swift-openapi-generator) to automatically generate type-safe Swift client code from the CloudKit Web Services OpenAPI specification. This approach ensures that the API client stays in sync with the OpenAPI schema while providing compile-time safety and excellent tooling support.

### Why Code Generation?

- **Type Safety**: Compile-time verification of API requests and responses
- **Maintainability**: Single source of truth (OpenAPI spec) for API definition
- **Documentation**: API structure documented directly in the OpenAPI spec
- **Consistency**: Automated generation eliminates manual coding errors
- **Updates**: Easy updates when CloudKit API changes

## Architecture Overview

```
openapi.yaml (OpenAPI Spec)
       ↓
swift-openapi-generator
       ↓
Generated Swift Code (10,476 lines)
  ├─ Client.swift (3,268 lines)
  │  ├─ APIProtocol (interface)
  │  ├─ Client (implementation)
  │  └─ Operations namespaces
  └─ Types.swift (7,208 lines)
     ├─ Components.Schemas
     ├─ Request/Response types
     └─ Servers enum
       ↓
MistKit Wrapper Layer
  ├─ MistKitClient.swift
  ├─ AuthenticationMiddleware.swift
  └─ CustomFieldValue.swift
```

## Installation and Setup

### Prerequisites

- **Swift 6.1+** (MistKit uses Swift 6.2 with experimental features)
- **Mint** package manager for managing command-line tools
- **macOS 10.15+** or **Linux** (Ubuntu 18.04+)

### Tool Versions

MistKit uses the following versions (defined in `Mintfile`):

```
swift-openapi-generator@1.10.0
swift-format@601.0.0
SwiftLint@0.59.1
periphery@3.2.0
```

### Installing Mint

**On macOS (via Homebrew):**
```bash
brew install mint
```

**On Linux:**
```bash
git clone https://github.com/yonaskolb/Mint.git
cd Mint
swift run mint bootstrap
```

### Installing swift-openapi-generator

The project uses Mint to manage swift-openapi-generator, so no manual installation is needed. The `Scripts/generate-openapi.sh` script automatically bootstraps all required tools:

```bash
./Scripts/generate-openapi.sh
```

This will:
1. Install Mint (if not present)
2. Bootstrap tools from `Mintfile` to `.mint` directory
3. Run swift-openapi-generator with the correct configuration
4. Generate Swift code to `Sources/MistKit/Generated/`

## Configuration Files

### openapi-generator-config.yaml

The configuration file controls how swift-openapi-generator produces Swift code:

```yaml
generate:
  - types      # Generate data types (schemas, enums, structs)
  - client     # Generate API client code

accessModifier: internal  # All generated code uses 'internal' access

typeOverrides:
  schemas:
    FieldValue: CustomFieldValue  # Override FieldValue with custom type

additionalFileComments:
  - periphery:ignore:all         # Ignore in dead code analysis
  - swift-format-ignore-file     # Skip auto-formatting
```

#### Configuration Options Explained

**`generate`**: Controls what code is generated
- `types`: Generates all schema types, request/response models
- `client`: Generates the API client protocol and implementation
- Other options: `server` (not used in MistKit as we're building a client)

**`accessModifier`**: Sets visibility for generated code
- `internal`: Code is accessible within the MistKit module but not to consumers (default for libraries)
- `public`: Would expose generated code to library users (not recommended)
- `package`: Swift 6+ package-level access

**`typeOverrides`**: Custom type mappings
- Used to replace generated types with custom implementations
- MistKit overrides `FieldValue` to provide custom CloudKit field value handling
- Allows integration with hand-written wrapper types

**`additionalFileComments`**: File-level pragmas
- `periphery:ignore:all`: Prevents false positives in dead code detection (generated code may have unused methods)
- `swift-format-ignore-file`: Preserves generated code formatting exactly as produced

### Package.swift Integration

MistKit uses swift-openapi-runtime dependencies but **does not use the build plugin**:

```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.0"),
    .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.1.0"),
]
```

**Why no build plugin?**

The build plugin approach can cause friction for library consumers because:
1. It requires consumers to have swift-openapi-generator installed
2. Build times increase for every consumer
3. Generated code appears in build artifacts
4. Harder to debug and inspect generated code

Instead, MistKit uses a **pre-generation approach**:
- Code is generated during development
- Generated files are committed to version control
- Consumers get pre-generated code without needing the generator
- Faster builds and better IDE support

### Swift Settings

MistKit leverages Swift 6.2's cutting-edge features (defined in `Package.swift`):

```swift
let swiftSettings: [SwiftSetting] = [
    // Upcoming Features
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("FullTypedThrows"),

    // Experimental Features
    .enableExperimentalFeature("IsolatedAny"),
    .enableExperimentalFeature("SendingArgsAndResults"),

    // Strict Concurrency
    .unsafeFlags(["-strict-concurrency=complete"])
]
```

These settings ensure:
- Complete Swift 6 concurrency safety
- Future-proof code with upcoming Swift features
- Type-safe async/await throughout

## Generation Script: Scripts/generate-openapi.sh

The shell script orchestrates the code generation process:

```bash
#!/bin/bash
set -e

echo "🔄 Generating OpenAPI code..."

# Detect OS and configure Mint paths
if [ "$(uname)" = "Darwin" ]; then
    DEFAULT_MINT_PATH="/opt/homebrew/bin/mint"
elif [ "$(uname)" = "Linux" ]; then
    DEFAULT_MINT_PATH="/usr/local/bin/mint"
fi

MINT_CMD=${MINT_CMD:-$DEFAULT_MINT_PATH}
export MINT_PATH="$PACKAGE_DIR/.mint"

# Bootstrap tools from Mintfile
$MINT_CMD bootstrap -m Mintfile

# Run generator
$MINT_CMD run swift-openapi-generator generate \
    --output-directory Sources/MistKit/Generated \
    --config openapi-generator-config.yaml \
    openapi.yaml

echo "✅ OpenAPI code generation complete!"
```

### Script Features

- **Cross-platform**: Supports both macOS and Linux
- **Environment variable support**: Can override Mint path via `MINT_CMD`
- **Local tool installation**: Installs to `.mint` directory to avoid global dependencies
- **Error handling**: Exits immediately on failure (`set -e`)
- **Clear feedback**: Progress messages for user awareness

### Running the Script

```bash
# From project root
./Scripts/generate-openapi.sh

# With custom Mint location
MINT_CMD=/custom/path/mint ./Scripts/generate-openapi.sh

# Make executable if needed
chmod +x Scripts/generate-openapi.sh
```

## Generated Code Structure

### File Organization

```
Sources/MistKit/Generated/
├── Client.swift (3,268 lines)
└── Types.swift (7,208 lines)
```

Both files include header comments:
```swift
// Generated by swift-openapi-generator, do not modify.
// periphery:ignore:all
// swift-format-ignore-file
```

### Client.swift Contents

**1. APIProtocol** - Protocol defining all API operations:

```swift
internal protocol APIProtocol: Sendable {
    func queryRecords(_ input: Operations.queryRecords.Input) async throws
        -> Operations.queryRecords.Output
    func modifyRecords(_ input: Operations.modifyRecords.Input) async throws
        -> Operations.modifyRecords.Output
    // ... 13 more operations
}
```

**2. Client Struct** - Implementation of APIProtocol:

```swift
internal struct Client: APIProtocol {
    private let client: UniversalClient

    internal init(
        serverURL: Foundation.URL,
        configuration: Configuration = .init(),
        transport: any ClientTransport,
        middlewares: [any ClientMiddleware] = []
    )
}
```

**3. Convenience Extensions** - Overloads for easier method calls:

```swift
extension APIProtocol {
    internal func queryRecords(
        path: Operations.queryRecords.Input.Path,
        headers: Operations.queryRecords.Input.Headers = .init(),
        body: Operations.queryRecords.Input.Body
    ) async throws -> Operations.queryRecords.Output
}
```

**4. Servers Enum** - Server URL definitions:

```swift
internal enum Servers {
    internal enum Server1 {
        internal static func url() throws -> Foundation.URL {
            try Foundation.URL(
                validatingOpenAPIServerURL: "https://api.apple-cloudkit.com",
                variables: []
            )
        }
    }
}
```

### Types.swift Contents

**1. Components.Schemas** - Data models from OpenAPI schemas:

```swift
internal enum Components {
    internal enum Schemas {
        internal struct ZoneID: Codable, Hashable, Sendable {
            internal var zoneName: Swift.String?
            internal var ownerName: Swift.String?
        }

        internal struct Filter: Codable, Hashable, Sendable {
            internal enum comparatorPayload: String, Codable, Sendable {
                case EQUALS = "EQUALS"
                case NOT_EQUALS = "NOT_EQUALS"
                // ... 14 more cases
            }
            internal var comparator: comparatorPayload?
            internal var fieldName: Swift.String?
            internal var fieldValue: CustomFieldValue?
        }
    }
}
```

**2. Operations Namespace** - Request/response types for each operation:

```swift
internal enum Operations {
    internal enum queryRecords {
        internal static let id: Swift.String = "queryRecords"

        internal struct Input: Sendable {
            internal struct Path: Sendable {
                internal var version: Swift.String
                internal var container: Swift.String
                internal var environment: Swift.String
                internal var database: Swift.String
            }
            internal var path: Operations.queryRecords.Input.Path
            internal var headers: Operations.queryRecords.Input.Headers
            internal var body: Operations.queryRecords.Input.Body
        }

        internal enum Output: Sendable {
            internal struct Ok: Sendable {
                internal var body: Body
            }
            case ok(Ok)
            case badRequest(BadRequest)
            // ... more response cases
        }
    }
}
```

### Key Features of Generated Code

1. **All types are Sendable**: Full Swift 6 concurrency compliance
2. **Async/await throughout**: Modern Swift concurrency patterns
3. **Type-safe enums for responses**: Each HTTP status code is a distinct case
4. **Nested namespacing**: Clean organization preventing naming conflicts
5. **Codable conformance**: Automatic JSON encoding/decoding
6. **Documentation comments**: Remark annotations with OpenAPI paths

## Integration with MistKit Wrapper Layer

MistKit wraps the generated client to provide:

### Custom Type Mappings

**CustomFieldValue** (overrides generated `FieldValue`):

```swift
// Custom implementation for CloudKit field values
internal struct CustomFieldValue: Codable, Hashable, Sendable {
    // Custom logic for CloudKit-specific field types
}
```

Located in: `Sources/MistKit/CustomFieldValue.swift`

### Authentication Middleware

**AuthenticationMiddleware**:
- Adds CloudKit authentication headers/query parameters
- Supports API Token, Web Auth, and Server-to-Server auth
- Implemented as OpenAPIRuntime middleware

Located in: `Sources/MistKit/AuthenticationMiddleware.swift`

### MistKitClient Wrapper

**MistKitClient**:
- High-level API wrapping generated `Client`
- Environment and database configuration
- Middleware injection (auth, logging, etc.)
- Convenience methods for common operations

Located in: `Sources/MistKit/MistKitClient.swift`

## Swift Language Features

### Conditional Compilation for Linux

Generated code handles platform differences:

```swift
#if os(Linux)
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.Data
#else
import struct Foundation.URL
import struct Foundation.Data
#endif
```

### SPI (System Programming Interface) Imports

```swift
@_spi(Generated) import OpenAPIRuntime
```

This imports internal OpenAPIRuntime APIs needed for generation but not exposed in the public API.

### Type Safety Benefits

**Before (manual HTTP client):**
```swift
// Easy to make mistakes - typos, wrong types, missing fields
let json = [
    "recordType": "User",
    "fields": ["name": ["value": name]]  // Nested dictionaries, no type checking
]
let data = try JSONSerialization.data(withJSONObject: json)
```

**After (generated client):**
```swift
// Compile-time safety - impossible to send invalid requests
let response = try await client.queryRecords(
    path: .init(
        version: "1",
        container: containerID,
        environment: "production",
        database: "public"
    ),
    body: .json(.init(
        query: .init(recordType: "User")
    ))
)
```

## Troubleshooting

### Common Issues

**Problem: "swift-openapi-generator not found"**

Solution:
```bash
# Bootstrap Mint tools
mint bootstrap -m Mintfile

# Or install directly
mint install apple/swift-openapi-generator@1.10.0
```

**Problem: "Generated code doesn't compile"**

Solution:
1. Ensure Swift 6.1+ is installed: `swift --version`
2. Check Package.swift dependencies are resolved: `swift package resolve`
3. Regenerate code: `./Scripts/generate-openapi.sh`
4. Clean build folder: `swift package clean`

**Problem: "Type 'FieldValue' not found"**

This is expected! The type override in configuration replaces `FieldValue` with `CustomFieldValue`. Check that:
- `CustomFieldValue.swift` exists and is properly implemented
- The override is specified in `openapi-generator-config.yaml`

**Problem: "Build plugin errors"**

MistKit doesn't use the build plugin. If you see plugin-related errors:
- Ensure you're not adding the plugin to Package.swift
- Generated code should be pre-committed to the repository
- Run generation script manually when updating OpenAPI spec

## Best Practices

### When to Regenerate Code

Regenerate generated code when:
- ✅ OpenAPI specification (`openapi.yaml`) changes
- ✅ Configuration (`openapi-generator-config.yaml`) changes
- ✅ Updating swift-openapi-generator version in Mintfile
- ❌ **NOT** on every build (use pre-generated approach)

### Version Control

**Always commit generated code:**
```bash
git add Sources/MistKit/Generated/
git commit -m "Update generated OpenAPI client code"
```

This ensures:
- Reviewable changes in pull requests
- No generation required for library consumers
- Faster CI/CD pipelines
- Consistent builds across environments

### Code Review Guidelines

When reviewing generated code changes:
1. Verify the OpenAPI spec change is intentional
2. Check that type safety is maintained
3. Ensure backward compatibility (or document breaking changes)
4. Review custom overrides still align with generated types

### Testing Generated Code

While generated code itself isn't tested (it's auto-generated), verify:
- Integration tests with MistKit wrapper layer
- Authentication middleware works with generated client
- Custom type overrides (CustomFieldValue) serialize correctly

## See Also

- [Swift OpenAPI Generator Documentation](https://swiftpackageindex.com/apple/swift-openapi-generator/1.10.3/documentation/swift-openapi-generator)
- [swift-openapi-generator Repository](https://github.com/apple/swift-openapi-generator)
- [OpenAPI Specification 3.0.3](https://spec.openapis.org/oas/v3.0.3)
- [CloudKit Web Services API](https://developer.apple.com/documentation/cloudkitwebservices)
- ``MistKitClient``
- ``AuthenticationMiddleware``
- ``CustomFieldValue``
