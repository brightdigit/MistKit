# MistKit Abstraction Layer Architecture

A comprehensive guide to MistKit's Swift abstraction layer built on top of the swift-openapi-generator client, showcasing modern Swift patterns and concurrency features.

## Overview

MistKit provides a friendly Swift abstraction layer that wraps the generated OpenAPI client code, offering improved ergonomics, type safety, and developer experience while leveraging modern Swift 6 concurrency features. This article explores the architectural patterns, design decisions, and implementation details of this abstraction layer.

## Architecture Philosophy

### Design Goals

1. **Hide complexity** without sacrificing functionality
2. **Leverage modern Swift features** (async/await, Sendable, typed throws)
3. **Maintain type safety** throughout the stack
4. **Enable testability** through protocol-oriented design
5. **Support cross-platform** development (macOS, iOS, Linux)
6. **Provide excellent ergonomics** for common operations

### Layered Architecture

```
┌─────────────────────────────────────────────────────────┐
│  User Code (Application/Library Consumer)               │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  MistKit Abstraction Layer                              │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ MistKitClient │  │ TokenManager │  │ Middleware   │ │
│  │ Configuration │  │ Hierarchy    │  │ Pipeline     │ │
│  └───────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Generated OpenAPI Client (Client.swift, Types.swift)   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  OpenAPI Runtime (HTTP transport, serialization)        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  URLSession / Network Layer                             │
└─────────────────────────────────────────────────────────┘
```

## Modern Swift Concurrency Integration

### Async/Await Throughout

MistKit embraces Swift's structured concurrency with async/await patterns across the entire API surface.

#### TokenManager Protocol

```swift
/// Protocol for managing authentication tokens
public protocol TokenManager: Sendable {
    /// Checks if credentials are currently available
    var hasCredentials: Bool { get async }

    /// Validates the current authentication credentials
    func validateCredentials() async throws(TokenManagerError) -> Bool

    /// Retrieves the current token credentials
    func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials?
}
```

**Key features:**

- ✅ **Async properties**: `hasCredentials` is computed asynchronously
- ✅ **Typed throws**: Uses `throws(TokenManagerError)` for specific error types (Swift 6)
- ✅ **Sendable protocol**: Safe to use across actor boundaries
- ✅ **No completion handlers**: Clean, modern API surface

**Comparison with completion handler pattern:**

```swift
// Old pattern (completion handlers)
protocol OldTokenManager {
    func hasCredentials(completion: @escaping (Bool) -> Void)
    func validateCredentials(completion: @escaping (Result<Bool, Error>) -> Void)
    func getCurrentCredentials(completion: @escaping (Result<TokenCredentials?, Error>) -> Void)
}

// Modern pattern (async/await)
protocol TokenManager: Sendable {
    var hasCredentials: Bool { get async }
    func validateCredentials() async throws(TokenManagerError) -> Bool
    func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials?
}
```

**Benefits:**

- ✅ No callback hell or nesting
- ✅ Automatic error propagation
- ✅ Task cancellation support
- ✅ Better IDE autocomplete
- ✅ Easier testing

### Middleware with Async/Await

MistKit implements the middleware pattern using OpenAPIRuntime's `ClientMiddleware` protocol:

```swift
/// Authentication middleware for CloudKit requests
internal struct AuthenticationMiddleware: ClientMiddleware {
    internal let tokenManager: any TokenManager

    internal func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        // Get credentials asynchronously
        guard let credentials = try await tokenManager.getCurrentCredentials() else {
            throw TokenManagerError.invalidCredentials(.noCredentialsAvailable)
        }

        var modifiedRequest = request
        // Add authentication based on method type
        switch credentials.method {
        case .apiToken(let apiToken):
            // Add API token to query parameters
            addAPITokenAuthentication(apiToken: apiToken, to: &modifiedRequest)

        case .webAuthToken(let apiToken, let webToken):
            // Add both API and web auth tokens
            addWebAuthTokenAuthentication(
                apiToken: apiToken,
                webToken: webToken,
                to: &modifiedRequest
            )

        case .serverToServer:
            // Sign request with ECDSA P-256 signature
            modifiedRequest = try await addServerToServerAuthentication(
                to: modifiedRequest,
                body: body
            )
        }

        // Call next middleware in chain
        return try await next(modifiedRequest, body, baseURL)
    }
}
```

**Middleware chain pattern:**

```
Request
   ↓
AuthenticationMiddleware.intercept()
   ├─ Get credentials (async)
   ├─ Modify request (add auth)
   └─ next() → LoggingMiddleware.intercept()
                  ├─ Log request
                  └─ next() → Transport.send()
                                 ↓
                              Network
                                 ↓
Response ← ← ← ← ← ← ← ← ← ← ←
```

**Benefits of async middleware:**

- ✅ Can perform async operations (fetch credentials, sign requests)
- ✅ Clean error propagation through the chain
- ✅ Composable and testable
- ✅ No blocking operations

## Sendable Compliance and Concurrency Safety

All types in MistKit's abstraction layer are `Sendable`, ensuring thread-safety for Swift 6's strict concurrency checking.

### Configuration as Sendable Struct

```swift
/// Configuration for MistKit client
internal struct MistKitConfiguration: Sendable {
    internal let container: String
    internal let environment: Environment
    internal let database: Database
    internal let apiToken: String
    internal let webAuthToken: String?
    internal let keyID: String?
    internal let privateKeyData: Data?
    internal let serverURL: URL

    // All properties are immutable (let), making the struct inherently thread-safe
}
```

**Why Sendable matters:**

```swift
// Safe to use across tasks
func authenticateUser() async throws {
    let config = MistKitConfiguration(
        container: "iCloud.com.example",
        environment: .production,
        database: .private,
        apiToken: ProcessInfo.processInfo.environment["API_TOKEN"]!
    )

    // Can safely pass config to another task
    async let client1 = MistKitClient(configuration: config)
    async let client2 = MistKitClient(configuration: config)

    // No data races - config is Sendable
    let (c1, c2) = try await (client1, c2)
}
```

### Sendable Middleware

```swift
// Middleware structs are Sendable
internal struct AuthenticationMiddleware: ClientMiddleware { ... }
internal struct LoggingMiddleware: ClientMiddleware { ... }

// Can be safely shared across actors
actor RequestManager {
    let authMiddleware: AuthenticationMiddleware  // Safe!

    func makeRequest() async throws {
        // Use middleware safely within actor
    }
}
```

## Protocol-Oriented Design

MistKit uses protocols extensively to enable flexibility, testability, and clean architecture.

### TokenManager Hierarchy

```
                     TokenManager
                    (protocol)
                         ↑
        ┌────────────────┼────────────────┐
        │                │                │
  APITokenManager  WebAuthTokenManager  ServerToServerAuthManager
     (struct)           (struct)              (struct)
                                                  │
                                           AdaptiveTokenManager
                                              (actor)
```

#### 1. APITokenManager

```swift
/// Manages API token authentication
public struct APITokenManager: TokenManager {
    public let token: String

    public var hasCredentials: Bool {
        get async { !token.isEmpty }
    }

    public func validateCredentials() async throws(TokenManagerError) -> Bool {
        try Self.validateAPITokenFormat(token)
        return true
    }

    public func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
        try await validateCredentials()
        return TokenCredentials(method: .apiToken(token))
    }
}
```

**Use case:** Container-level access, read-only operations on public database

#### 2. WebAuthTokenManager

```swift
/// Manages web authentication with both API and web auth tokens
public struct WebAuthTokenManager: TokenManager {
    public let apiToken: String
    public let webAuthToken: String

    public var hasCredentials: Bool {
        get async { !apiToken.isEmpty && !webAuthToken.isEmpty }
    }

    public func validateCredentials() async throws(TokenManagerError) -> Bool {
        try Self.validateAPITokenFormat(apiToken)
        try Self.validateWebAuthTokenFormat(webAuthToken)
        return true
    }

    public func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
        try await validateCredentials()
        return TokenCredentials(method: .webAuthToken(apiToken, webAuthToken))
    }
}
```

**Use case:** User-specific operations, private/shared database access

#### 3. ServerToServerAuthManager

```swift
/// Manages server-to-server authentication using ECDSA P-256 signatures
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct ServerToServerAuthManager: TokenManager {
    public let keyIdentifier: String
    public let privateKeyData: Data
    private let privateKey: P256.Signing.PrivateKey

    public init(keyID: String, privateKeyData: Data) throws {
        self.keyIdentifier = keyID
        self.privateKeyData = privateKeyData
        self.privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
    }

    public func signRequest(
        requestBody: Data?,
        webServiceURL: String
    ) throws -> RequestSignature {
        let currentDate = Date()
        let iso8601Date = ISO8601DateFormatter().string(from: currentDate)

        // Create signature payload
        let payload = "\(iso8601Date):\(requestBody?.base64EncodedString() ?? ""):\(webServiceURL)"
        let payloadData = Data(payload.utf8)

        // Sign with ECDSA P-256
        let signature = try privateKey.signature(for: SHA256.hash(data: payloadData))
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()

        return RequestSignature(
            keyID: keyIdentifier,
            date: iso8601Date,
            signature: signatureBase64
        )
    }
}
```

**Use case:** Enterprise/server applications, public database only, no user context

### Benefits of Protocol-Oriented Design

**1. Easy testing with mocks:**

```swift
struct MockTokenManager: TokenManager {
    var mockCredentials: TokenCredentials?
    var shouldThrow: Bool = false

    var hasCredentials: Bool {
        get async { mockCredentials != nil }
    }

    func validateCredentials() async throws(TokenManagerError) -> Bool {
        if shouldThrow {
            throw TokenManagerError.invalidCredentials(.apiTokenEmpty)
        }
        return mockCredentials != nil
    }

    func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
        mockCredentials
    }
}

// Use in tests
let mockManager = MockTokenManager(mockCredentials: .apiToken("test-token"))
let client = try MistKitClient(
    configuration: testConfig,
    tokenManager: mockManager,
    transport: mockTransport
)
```

**2. Flexible implementation swapping:**

```swift
// Development: Use API token
let devTokenManager = APITokenManager(token: devAPIToken)

// Production: Use server-to-server auth
let prodTokenManager = try ServerToServerAuthManager(
    keyID: prodKeyID,
    privateKeyData: prodPrivateKey
)

// Same client code works with either
let client = try MistKitClient(
    configuration: config,
    tokenManager: prodTokenManager  // or devTokenManager
)
```

**3. Protocol extensions for shared logic:**

```swift
extension TokenManager {
    /// Shared validation logic for all token managers
    internal static func validateAPITokenFormat(_ apiToken: String) throws(TokenManagerError) {
        guard !apiToken.isEmpty else {
            throw TokenManagerError.invalidCredentials(.apiTokenEmpty)
        }

        let regex = NSRegularExpression.apiTokenRegex
        let matches = regex.matches(in: apiToken)

        guard !matches.isEmpty else {
            throw TokenManagerError.invalidCredentials(.apiTokenInvalidFormat)
        }
    }
}
```

## Dependency Injection Pattern

MistKit uses constructor injection to promote testability and flexibility.

### MistKitClient Initialization

```swift
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
internal struct MistKitClient {
    internal let client: Client

    /// Initialize with explicit dependencies
    internal init(
        configuration: MistKitConfiguration,
        tokenManager: any TokenManager,
        transport: any ClientTransport
    ) throws {
        // Validate configuration
        try Self.validateServerToServerConfiguration(
            configuration: configuration,
            tokenManager: tokenManager
        )

        // Create client with injected dependencies
        self.client = Client(
            serverURL: configuration.serverURL,
            transport: transport,
            middlewares: [
                AuthenticationMiddleware(tokenManager: tokenManager),
                LoggingMiddleware()
            ]
        )
    }

    /// Convenience initializer with defaults
    internal init(configuration: MistKitConfiguration) throws {
        let tokenManager = try configuration.createTokenManager()
        try self.init(
            configuration: configuration,
            tokenManager: tokenManager,
            transport: URLSessionTransport()  // Default transport
        )
    }
}
```

**Benefits:**

1. **Testability**: Inject mock transport and token managers
2. **Flexibility**: Swap implementations without changing client code
3. **Clear dependencies**: Explicit about what the client needs
4. **Defaults available**: Convenience initializers for common cases

### Testing with Dependency Injection

```swift
// Production code
let client = try MistKitClient(configuration: prodConfig)

// Test code - inject mocks
let mockTransport = MockTransport(cannedResponse: mockQueryResponse)
let mockTokenManager = MockTokenManager(mockCredentials: testCredentials)

let testClient = try MistKitClient(
    configuration: testConfig,
    tokenManager: mockTokenManager,
    transport: mockTransport
)

// Test without hitting real network
let response = try await testClient.queryRecords(...)
```

## Custom Type Mapping: CustomFieldValue

MistKit overrides the generated `FieldValue` type with a custom implementation that provides better handling of CloudKit field types.

### Type Override Configuration

```yaml
# openapi-generator-config.yaml
typeOverrides:
  schemas:
    FieldValue: CustomFieldValue
```

### Implementation

```swift
/// Custom implementation of FieldValue with proper ASSETID handling
internal struct CustomFieldValue: Codable, Hashable, Sendable {
    /// Field type payload for CloudKit fields
    public enum FieldTypePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case string = "STRING"
        case int64 = "INT64"
        case double = "DOUBLE"
        case bytes = "BYTES"
        case reference = "REFERENCE"
        case asset = "ASSET"
        case assetid = "ASSETID"  // Special handling for asset IDs
        case location = "LOCATION"
        case timestamp = "TIMESTAMP"
        case list = "LIST"
    }

    /// Custom field value payload supporting various CloudKit types
    public enum CustomFieldValuePayload: Codable, Hashable, Sendable {
        case stringValue(String)
        case int64Value(Int)
        case doubleValue(Double)
        case booleanValue(Bool)
        case bytesValue(String)
        case dateValue(Double)
        case locationValue(Components.Schemas.LocationValue)
        case referenceValue(Components.Schemas.ReferenceValue)
        case assetValue(Components.Schemas.AssetValue)
        case listValue([CustomFieldValuePayload])
    }

    internal let value: CustomFieldValuePayload
    internal let type: FieldTypePayload?

    // Custom Codable implementation with type-specific decoders
    private static let fieldTypeDecoders:
        [FieldTypePayload: @Sendable (KeyedDecodingContainer<CodingKeys>) throws
            -> CustomFieldValuePayload] = [
            .string: { .stringValue(try $0.decode(String.self, forKey: .value)) },
            .int64: { .int64Value(try $0.decode(Int.self, forKey: .value)) },
            .asset: { .assetValue(try $0.decode(Components.Schemas.AssetValue.self, forKey: .value)) },
            .assetid: { .assetValue(try $0.decode(Components.Schemas.AssetValue.self, forKey: .value)) },
            // ... more decoders
        ]
}
```

**Why custom implementation?**

1. **CloudKit-specific handling**: ASSETID type requires special treatment
2. **Better ergonomics**: Enum-based value access instead of dictionaries
3. **Type safety**: Compile-time checking for field value types
4. **Proper encoding**: Handles CloudKit's JSON format correctly

### Usage Comparison

**Before (generated FieldValue):**

```swift
// Hypothetical generated code (generic, not CloudKit-specific)
let fieldValue = FieldValue(value: ["someKey": someValue])
// Type: Any? - no compile-time safety
```

**After (CustomFieldValue):**

```swift
// Type-safe, CloudKit-aware
let fieldValue = CustomFieldValue(
    value: .stringValue("John Doe"),
    type: .string
)

// Pattern matching for safe access
switch fieldValue.value {
case .stringValue(let name):
    print("Name: \(name)")
case .int64Value(let age):
    print("Age: \(age)")
case .assetValue(let asset):
    print("Asset URL: \(asset.downloadURL)")
default:
    break
}
```

## Error Handling with Typed Throws

MistKit leverages Swift 6's typed throws for precise error handling.

### TokenManagerError

```swift
/// Errors that can occur during token management
public enum TokenManagerError: Error, Sendable {
    case invalidCredentials(InvalidCredentialReason)
    case internalError(InternalErrorReason)
}

/// Specific reasons for invalid credentials
public enum InvalidCredentialReason: Sendable {
    case apiTokenEmpty
    case apiTokenInvalidFormat
    case webAuthTokenEmpty
    case webAuthTokenTooShort
    case noCredentialsAvailable
    case serverToServerOnlySupportsPublicDatabase(String)
}
```

### Usage with Typed Throws

```swift
// Function signature with typed throws
func validateCredentials() async throws(TokenManagerError) -> Bool

// Caller knows exactly what error type to expect
do {
    let isValid = try await tokenManager.validateCredentials()
} catch let error as TokenManagerError {
    // Can switch on specific error cases
    switch error {
    case .invalidCredentials(.apiTokenEmpty):
        print("API token is empty")
    case .invalidCredentials(.apiTokenInvalidFormat):
        print("API token format is invalid")
    case .internalError(let reason):
        print("Internal error: \(reason)")
    }
}
```

**Comparison with untyped throws:**

```swift
// Untyped throws - unclear what errors can occur
func validateCredentials() async throws -> Bool

// Typed throws - explicit error type
func validateCredentials() async throws(TokenManagerError) -> Bool
```

## Security and Logging

### Secure Logging

MistKit implements secure logging that automatically masks sensitive information:

```swift
internal enum SecureLogging {
    /// Masks tokens and sensitive data in log messages
    internal static func maskToken(_ token: String) -> String {
        guard token.count > 8 else {
            return "***"
        }
        let prefix = token.prefix(4)
        let suffix = token.suffix(4)
        return "\(prefix)***\(suffix)"
    }

    /// Safely log messages with automatic token masking
    internal static func safeLogMessage(_ message: String) -> String {
        var safe = message

        // Mask API tokens
        safe = safe.replacingOccurrences(
            of: #"ckAPIToken=[^&\s]+"#,
            with: "ckAPIToken=***",
            options: .regularExpression
        )

        // Mask web auth tokens
        safe = safe.replacingOccurrences(
            of: #"ckWebAuthToken=[^&\s]+"#,
            with: "ckWebAuthToken=***",
            options: .regularExpression
        )

        return safe
    }
}
```

### LoggingMiddleware with Security

```swift
internal struct LoggingMiddleware: ClientMiddleware {
    #if DEBUG
    private func logRequest(_ request: HTTPRequest, baseURL: URL) {
        print("🌐 CloudKit Request: \(request.method.rawValue) \(fullPath)")

        // Log query parameters with masking
        for item in queryItems {
            let value = formatQueryValue(for: item)  // Masks sensitive values
            print("  \(item.name): \(value)")
        }
    }

    private func formatQueryValue(for item: URLQueryItem) -> String {
        guard let value = item.value else { return "nil" }

        // Mask sensitive query parameters
        if item.name.lowercased().contains("token") ||
           item.name.lowercased().contains("key") {
            return SecureLogging.maskToken(value)
        }

        return value
    }
    #endif
}
```

**Output example:**

```
🌐 CloudKit Request: POST https://api.apple-cloudkit.com/database/1/iCloud.com.example/production/private/records/query
  ckAPIToken: c34a***7d9f
  ckWebAuthToken: 9f2e***4b1a
```

## Future Architecture Enhancements

While MistKit's current architecture is robust, several modern Swift features could further enhance the abstraction layer:

### Potential: Actor-Based Token Management

```swift
// Future: Actor for thread-safe token caching
actor TokenCacheManager: TokenManager {
    private var cachedCredentials: TokenCredentials?
    private var lastValidation: Date?
    private let validationInterval: TimeInterval = 300 // 5 minutes

    func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
        // Check cache
        if let cached = cachedCredentials,
           let lastValidation = lastValidation,
           Date().timeIntervalSince(lastValidation) < validationInterval {
            return cached
        }

        // Fetch and cache new credentials
        let credentials = try await fetchCredentials()
        self.cachedCredentials = credentials
        self.lastValidation = Date()
        return credentials
    }
}
```

**Benefits:**
- ✅ Thread-safe token caching
- ✅ Automatic invalidation
- ✅ No data races

### Potential: AsyncSequence for Pagination

```swift
// Future: AsyncSequence for paginated queries
struct RecordQuerySequence: AsyncSequence {
    typealias Element = CloudKitRecord

    let query: RecordQuery
    let client: MistKitClient

    func makeAsyncIterator() -> Iterator {
        Iterator(query: query, client: client)
    }

    struct Iterator: AsyncIteratorProtocol {
        var continuationMarker: String?
        let query: RecordQuery
        let client: MistKitClient

        mutating func next() async throws -> CloudKitRecord? {
            let response = try await client.queryRecords(
                query: query,
                continuationMarker: continuationMarker
            )

            continuationMarker = response.continuationMarker

            return response.records.first
        }
    }
}

// Usage
for try await record in client.queryRecords(type: "User") {
    print(record.name)
    // Automatically fetches next page when needed
}
```

### Potential: Result Builders for Query Construction

```swift
// Future: Result builder for declarative queries
@resultBuilder
enum QueryBuilder {
    static func buildBlock(_ components: QueryFilter...) -> [QueryFilter] {
        components
    }
}

func query(@QueryBuilder _ filters: () -> [QueryFilter]) -> RecordQuery {
    RecordQuery(filters: filters())
}

// Usage
let userQuery = query {
    Filter(field: "age", comparator: .greaterThan, value: 18)
    Filter(field: "status", comparator: .equals, value: "active")
    Sort(field: "lastName", ascending: true)
}

// vs. current approach
let userQuery = RecordQuery(
    filters: [
        Filter(field: "age", comparator: .greaterThan, value: 18),
        Filter(field: "status", comparator: .equals, value: "active")
    ],
    sorts: [
        Sort(field: "lastName", ascending: true)
    ]
)
```

### Potential: Property Wrappers for Field Mapping

```swift
// Future: Property wrappers for model mapping
@propertyWrapper
struct CloudKitField<Value: Codable> {
    let key: String
    var wrappedValue: Value

    init(wrappedValue: Value, _ key: String) {
        self.key = key
        self.wrappedValue = wrappedValue
    }
}

struct User {
    @CloudKitField("firstName") var firstName: String
    @CloudKitField("lastName") var lastName: String
    @CloudKitField("age") var age: Int
    @CloudKitField("email") var email: String

    // Automatic mapping to/from CloudKit records
}

// vs. current approach (manual field mapping)
let record = CloudKitRecord(
    fields: [
        "firstName": .stringValue(user.firstName),
        "lastName": .stringValue(user.lastName),
        "age": .int64Value(user.age),
        "email": .stringValue(user.email)
    ]
)
```

## Summary

MistKit's abstraction layer provides:

### Current Implementation

- ✅ **Async/await integration** throughout the API
- ✅ **Sendable compliance** for Swift 6 concurrency safety
- ✅ **Protocol-oriented design** enabling flexibility and testability
- ✅ **Dependency injection** for loose coupling
- ✅ **Middleware pattern** for cross-cutting concerns
- ✅ **Custom type mapping** for CloudKit-specific needs
- ✅ **Typed throws** for precise error handling
- ✅ **Secure logging** with automatic credential masking

### Architectural Benefits

- 🎯 **Type safety** from the generated code through to the API surface
- 🎯 **Testability** through protocol abstractions and dependency injection
- 🎯 **Maintainability** with clear separation of concerns
- 🎯 **Ergonomics** hiding complexity without losing functionality
- 🎯 **Cross-platform** support (macOS, iOS, tvOS, watchOS, Linux)
- 🎯 **Future-proof** leveraging latest Swift features

### Future Enhancements

- 🔮 Actor-based token caching for improved concurrency
- 🔮 AsyncSequence for elegant pagination
- 🔮 Result builders for declarative query construction
- 🔮 Property wrappers for simplified model mapping

## See Also

- <doc:OpenAPICodeGeneration>
- <doc:GeneratedCodeAnalysis>
- <doc:GeneratedCodeWorkflow>
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Protocol-Oriented Programming in Swift](https://developer.apple.com/videos/play/wwdc2015/408/)
