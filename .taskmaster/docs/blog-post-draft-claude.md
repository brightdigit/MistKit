# Rebuilding MistKit: An OpenAPI-Driven Journey to Modern Swift

**Bringing CloudKit Web Services to Every Swift Platform**

> **TL;DR**: This is the story of completely rewriting MistKit from the ground up using OpenAPI specifications and modern Swift 6. In three months, we went from a stale 2021 codebase to a type-safe, cross-platform CloudKit client powered by code generation, strict concurrency, and thoughtful abstraction.

---

## Introduction: Why Rebuild?

Sometimes the hardest decision in software development isn't whether to add a new feature—it's whether to start over. In October 2021, MistKit v0.2 was released as a Swift package for accessing CloudKit Web Services. It worked, shipped, and solved real problems. But by mid-2024, the codebase told a different story.

### The State of MistKit v0.2

MistKit v0.2 was showing its age:

- **Last substantial update: October 2021** — Nearly three years of Swift evolution had passed it by
- **Pre-concurrency Swift** — Built in a world before `async/await`, using completion handlers and `@escaping` closures
- **Manual REST implementation** — Every HTTP request hand-coded, every JSON response manually parsed
- **Maintenance burden** — Each CloudKit API change required manual updates across multiple files
- **Limited test coverage** — Only 15% code coverage, making changes risky
- **SwiftLint violations** — 437 violations across the codebase

For a library meant to make CloudKit easier, it had become difficult to maintain and evolve.

### The Need for Change

Meanwhile, Swift had transformed:

**Swift 6 arrived** with strict concurrency checking, making data races a compile-time error rather than a runtime mystery. The new concurrency model wasn't just about async/await—it was about actor isolation, Sendable protocols, and a fundamentally safer approach to concurrent code.

**Server-side Swift matured** with projects like Vapor 4, swift-nio, and AWS Lambda Runtime for Swift gaining production adoption. CloudKit Web Services became increasingly relevant for server applications, CLI tools, and cross-platform use cases where the CloudKit framework wasn't available.

**The Swift ecosystem standardized on modern patterns**: Result types, typed throws, property wrappers, result builders, and AsyncSequence became expected features, not experimental additions.

MistKit v0.2, frozen in 2021, couldn't take advantage of any of this. Every modern Swift project that added MistKit as a dependency pulled in old patterns and outdated code.

### The Bold Decision with a Twist

In July 2024, I made the call: complete rewrite, not incremental updates.

**But here's what made it different**: Instead of manually hand-coding every API endpoint like MistKit v0.2, I'd use **OpenAPI specifications** to generate the entire client. And instead of building it alone, I'd use **Claude Code** as my development partner—not to write the code for me, but to accelerate the tedious parts while I focused on architecture and design.

The vision was ambitious:
- **OpenAPI-first architecture** — Generate the entire client from a specification, not hand-written code
- **Claude as co-pilot** — Let AI handle boilerplate, tests, and refactoring while I focus on design
- **Type safety everywhere** — If it compiles, it's valid CloudKit API usage
- **Modern Swift throughout** — Swift 6, async/await, actors, Sendable compliance
- **Three-layer design** — OpenAPI spec → Generated code → Friendly abstraction

**The timeline**: Three months from concept to v1.0 Alpha.

**The approach**: OpenAPI handles API accuracy through code generation. Claude accelerates development by handling the tedious parts. I focus on architecture, security, and the developer experience.

**The result**: 10,476 lines of generated type-safe code, 161 tests (most written with Claude's help), and a maintainable codebase that's easy to evolve.

> **Note**: I'd learned this pattern from my previous [SyntaxKit project](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/)—code generation + thoughtful abstraction—but this time with OpenAPI and Claude working together.

### Why This Matters

This isn't just a story about one library. It's about what becomes possible when you combine the right tools:

**OpenAPI** provides the foundation—a machine-readable API specification that generates perfect, type-safe client code.

**Claude** accelerates the tedious parts—writing tests, refactoring code, catching edge cases, and generating boilerplate.

**You** provide the vision—architecture decisions, security patterns, developer experience, and the parts that require human judgment.

Together, these three elements made a three-month complete rewrite not only possible, but maintainable and extensible.

Sometimes a rewrite isn't technical debt—it's an investment in sustainable development.

Let's explore how OpenAPI and Claude worked together to make this happen.

---

## The OpenAPI Epiphany

The breakthrough insight came early: **What if we didn't hand-write the CloudKit client at all?**

### What is OpenAPI?

For those unfamiliar, [OpenAPI](https://www.openapis.org/) (formerly Swagger) is a specification format for describing REST APIs. Think of it as a blueprint that precisely defines:

- Every endpoint and its HTTP method
- Request parameters and their types
- Request/response body schemas
- Authentication requirements
- Error response formats

Here's a taste of what CloudKit Web Services looks like in OpenAPI:

```yaml
paths:
  /database/{version}/{container}/{environment}/{database}/records/query:
    post:
      summary: Query Records
      description: Fetch records using a query with filters and sorting options
      operationId: queryRecords
      parameters:
        - $ref: '#/components/parameters/version'
        - $ref: '#/components/parameters/container'
        - $ref: '#/components/parameters/environment'
        - $ref: '#/components/parameters/database'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/QueryRecordRequest'
      responses:
        '200':
          description: Successful query
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/QueryResponse'
        '401':
          $ref: '#/components/responses/Unauthorized'
```

From this single YAML definition, we can generate:
- Type-safe Swift structs for requests and responses
- Async functions with proper error handling
- Sendable-compliant types for concurrency safety
- Complete API coverage with zero manual coding

### The "Aha" Moment

The realization was simple but profound: **CloudKit Web Services is already a well-defined REST API**. Apple's documentation describes every endpoint, parameter, and response format. Instead of manually translating that documentation into Swift code (and keeping it in sync), we could:

1. Create an OpenAPI specification from Apple's documentation
2. Use Apple's `swift-openapi-generator` to create type-safe Swift code
3. Build a friendly abstraction layer on top

**Benefits of this approach**:

✅ **Type safety** — If the request compiles, it matches the OpenAPI spec
✅ **Completeness** — Every endpoint defined in the spec is available
✅ **Maintainability** — Spec changes regenerate code automatically
✅ **Accuracy** — Generated code exactly matches API requirements
✅ **No manual JSON** — Codable types handle serialization

### Creating the CloudKit OpenAPI Specification (with Claude's Help)

The first major task was translating Apple's CloudKit Web Services documentation into OpenAPI 3.0.3 format. This wasn't trivial—CloudKit has unique characteristics that required careful modeling.

**How Claude helped here**: I'd start by sketching out the structure, then Claude would help me expand it into complete OpenAPI schemas, catch inconsistencies, and suggest edge cases I'd missed. For repetitive endpoint definitions, Claude could generate the boilerplate while I focused on the tricky CloudKit-specific types.

The back-and-forth looked like this:
1. **Me**: "Here's the CloudKit field value structure from Apple's docs"
2. **Claude**: "Here's an OpenAPI schema with `oneOf` for the polymorphism"
3. **Me**: "Add the ASSETID type and validation rules"
4. **Claude**: "Updated, and I noticed you might want constraints on these fields"

This iterative refinement was far faster than writing everything from scratch.

#### Challenge 1: CloudKit's Polymorphic Field Values

CloudKit records store field values that can be strings, numbers, dates, locations, references, or assets. In JSON, this polymorphism looks like:

```json
{
  "recordType": "User",
  "fields": {
    "name": {
      "value": "John Doe",
      "type": "STRING"
    },
    "age": {
      "value": 30,
      "type": "INT64"
    },
    "location": {
      "value": {
        "latitude": 37.7749,
        "longitude": -122.4194
      },
      "type": "LOCATION"
    }
  }
}
```

In OpenAPI, we model this as:

```yaml
FieldValue:
  type: object
  required:
    - value
  properties:
    value:
      oneOf:
        - type: string
        - type: integer
        - type: number
        - type: object
    type:
      type: string
      enum:
        - STRING
        - INT64
        - DOUBLE
        - TIMESTAMP
        - BYTES
        - REFERENCE
        - ASSET
        - LOCATION
        - LIST
```

#### Challenge 2: CloudKit's Unique Types

CloudKit introduces types that don't map directly to JSON primitives:

**CKAsset** — References to binary data stored separately:
```yaml
AssetValue:
  type: object
  properties:
    fileChecksum:
      type: string
    size:
      type: integer
      format: int64
    downloadURL:
      type: string
      format: uri
```

**CKReference** — Links between records:
```yaml
ReferenceValue:
  type: object
  properties:
    recordName:
      type: string
    action:
      type: string
      enum: [NONE, DELETE_SELF, VALIDATE]
```

**CKLocation** — Geographic coordinates:
```yaml
LocationValue:
  type: object
  properties:
    latitude:
      type: number
      format: double
    longitude:
      type: number
      format: double
    altitude:
      type: number
      format: double
    horizontalAccuracy:
      type: number
      format: double
```

Each required careful modeling to ensure the generated Swift code would handle these types correctly.

#### Challenge 3: Authentication Methods

CloudKit supports two authentication methods:

1. **Web Auth Token** — User-specific access that requires first obtaining an API Token, then exchanging it for a Web Auth Token (both sent as query parameters)
2. **Server-to-Server** — Enterprise access using ECDSA P-256 signatures

In OpenAPI, these become security schemes:

```yaml
components:
  securitySchemes:
    ApiTokenAuth:
      type: apiKey
      in: query
      name: ckAPIToken
      description: API token authentication

    WebAuthToken:
      type: apiKey
      in: query
      name: ckWebAuthToken
      description: Web authentication token

    ServerToServerAuth:
      type: http
      scheme: bearer
      description: Server-to-server authentication using ECDSA signatures
```

### Modeling CloudKit Endpoints

CloudKit's URL structure follows a consistent pattern:

```
https://api.apple-cloudkit.com/database/{version}/{container}/{environment}/{database}/{operation}
```

Where:
- `version`: Protocol version (currently "1")
- `container`: Container identifier (e.g., "iCloud.com.example.app")
- `environment`: "development" or "production"
- `database`: "public", "private", or "shared"
- `operation`: The CloudKit operation (e.g., "records/query")

Each operation becomes an OpenAPI path with path parameters:

```yaml
paths:
  /database/{version}/{container}/{environment}/{database}/records/modify:
    post:
      summary: Modify Records
      description: Create, update, or delete records (supports bulk operations)
      operationId: modifyRecords
      parameters:
        - name: version
          in: path
          required: true
          schema:
            type: string
            default: "1"
        - name: container
          in: path
          required: true
          schema:
            type: string
          description: Container ID (begins with "iCloud.")
        - name: environment
          in: path
          required: true
          schema:
            type: string
            enum: [development, production]
        - name: database
          in: path
          required: true
          schema:
            type: string
            enum: [public, private, shared]
```

### Error Response Modeling

CloudKit returns structured error responses with specific error codes:

```yaml
ErrorResponse:
  type: object
  properties:
    uuid:
      type: string
      format: uuid
    serverErrorCode:
      type: string
      enum:
        - ACCESS_DENIED
        - AUTHENTICATION_FAILED
        - BAD_REQUEST
        - CONFLICT
        - INTERNAL_ERROR
        - NOT_FOUND
        - QUOTA_EXCEEDED
        - THROTTLED
        - ZONE_NOT_FOUND
    reason:
      type: string
    redirectURL:
      type: string
      format: uri
```

Every endpoint response includes these error cases:

```yaml
responses:
  '400':
    description: Bad Request
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/ErrorResponse'
  '401':
    description: Unauthorized
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/ErrorResponse'
  # ... more error responses
```

### Before and After: Documentation to Specification

**Before**: Apple's CloudKit Web Services documentation described the query endpoint as:

> **Fetching Records Using a Query**
>
> `POST https://api.apple-cloudkit.com/database/1/[container]/[environment]/[database]/records/query`
>
> **Request Body**:
> - `query` (object): The query to execute
> - `zoneID` (object, optional): The zone containing the records
> - `resultsLimit` (integer, optional): Maximum records to return
>
> **Response**: Returns a `QueryResponse` object containing matching records.

**After**: Our OpenAPI specification precisely defines this as:

```yaml
/database/{version}/{container}/{environment}/{database}/records/query:
  post:
    operationId: queryRecords
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              query:
                type: object
                required:
                  - recordType
                properties:
                  recordType:
                    type: string
                  filterBy:
                    type: array
                    items:
                      $ref: '#/components/schemas/Filter'
                  sortBy:
                    type: array
                    items:
                      $ref: '#/components/schemas/Sort'
              zoneID:
                $ref: '#/components/schemas/ZoneID'
              resultsLimit:
                type: integer
                minimum: 1
                maximum: 200
    responses:
      '200':
        description: Successful query
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/QueryResponse'
```

The difference? **Machine-readable, type-safe, and complete**.

### The Foundation is Set

With a comprehensive OpenAPI specification for CloudKit Web Services, we had:

- ✅ All 15 CloudKit operations modeled
- ✅ Complete request/response schemas
- ✅ Both authentication methods defined (Web Auth Token, Server-to-Server)
- ✅ Error responses documented
- ✅ CloudKit-specific types (Asset, Reference, Location) properly represented

**Key takeaway**: A well-designed OpenAPI specification is the foundation of everything that follows. Taking the time to model the API correctly pays dividends in generated code quality, type safety, and maintainability.

Next, we'll explore how `swift-openapi-generator` transforms this specification into production-ready Swift code.

---

## Part 3: From Specification to Swift Code

With our CloudKit OpenAPI specification complete, [swift-openapi-generator](https://github.com/apple/swift-openapi-generator) transforms it into production-ready Swift code. Apple's official tool generates async/await methods, Sendable types, and typed error handling—exactly what we need for modern Swift.

**One command, 10,476 lines of type-safe code**:

```bash
./Scripts/generate-openapi.sh
```

We use [Mint](https://github.com/yonaskolb/Mint) to manage tool versions, ensuring consistent code generation across environments.

**Output**:
```
Sources/MistKit/Generated/
├── Client.swift  (3,268 lines)  # API client with 15 operations
└── Types.swift   (7,208 lines)  # All CloudKit schemas and models
```

We chose **pre-generation** (committing generated code) over the build plugin approach. This means faster builds for library consumers, reviewable code in PRs, and no tool dependencies.

The key configuration decision: **all generated code is `internal`**. Users never see `Operations.queryRecords.Input` or `Components.Schemas.Record`—they use MistKit's friendly public API instead. This separation is crucial for the abstraction layer we'll build next.

**Resources**:
- [WWDC23: Meet Swift OpenAPI Generator](https://developer.apple.com/videos/play/wwdc2023/10171/) - Official introduction
- [swift-openapi-generator Documentation](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation) - Complete API reference
- [GitHub Repository](https://github.com/apple/swift-openapi-generator) - Examples and advanced configuration

---

## Part 4: Building the Friendly Abstraction Layer

Generated code is powerful, but it's not always pleasant to use directly. More importantly, the generated client has no concept of CloudKit's authentication requirements—it's just HTTP requests. This is where MistKit's abstraction layer comes in.

### Why We Need an Abstraction Layer

The raw generated code has several problems:

**1. No Authentication Support**

The generated client knows nothing about CloudKit's auth methods:
- Web Auth Token (API Token + User Token as query parameters)
- Server-to-Server (ECDSA P-256 request signatures)

Every request would need manual auth handling.

**2. Cross-Platform Crypto Challenges**

Server-to-Server auth requires ECDSA signatures, but:
- macOS/iOS: Use `CryptoKit` (Apple framework)
- Linux: Use `swift-crypto` (SPM package)
- Same APIs, different imports

**3. Verbose API Surface**

```swift
// Too much boilerplate for simple operations
let input = Operations.queryRecords.Input(
    path: .init(
        version: "1",
        container: "iCloud.com.example.MyApp",
        environment: Components.Parameters.environment.production,
        database: Components.Parameters.database._private
    ),
    // ... more nesting
)
```

### The Solution: Middleware + TokenManagers

MistKit's abstraction layer solves these problems through a layered architecture:

```
┌─────────────────────────────────────────┐
│  User Code (Public API)                 │
│  • Simple, intuitive methods            │
│  • CloudKitService wrapper              │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  MistKit Abstraction Layer (Internal)   │
│  • TokenManager implementations         │
│  • Middleware (Auth, Logging)           │
│  • Cross-platform crypto handling       │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  Generated OpenAPI Client (Internal)    │
│  • Client.swift (API implementation)    │
│  • Types.swift (data models)            │
└─────────────────────────────────────────┘
```

### Authentication via Middleware

Rather than scattering auth logic, we use OpenAPI Runtime's middleware system:

```swift
internal struct AuthenticationMiddleware: ClientMiddleware {
    internal let tokenManager: any TokenManager

    internal func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        guard let credentials = try await tokenManager.getCurrentCredentials() else {
            throw TokenManagerError.invalidCredentials(.noCredentialsAvailable)
        }

        var modifiedRequest = request

        switch credentials.method {
        case .webAuthToken(let apiToken, let webToken):
            // Add both tokens to query parameters
            modifiedRequest.addQueryParameter("ckAPIToken", value: apiToken)
            modifiedRequest.addQueryParameter("ckWebAuthToken", value: webToken)

        case .serverToServer(let keyID, let privateKey):
            // Sign request with ECDSA P-256
            let signature = try signRequest(request, body: body, with: privateKey)
            modifiedRequest.headerFields[.authorization] = "..."
        }

        return try await next(modifiedRequest, body, baseURL)
    }
}
```

**Middleware chain**:
```
Request → AuthMiddleware → LoggingMiddleware → Transport → Network
```

Every request automatically gets proper authentication without user intervention.

### Cross-Platform Crypto Solution

For Server-to-Server auth, we use conditional compilation:

```swift
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto  // swift-crypto package
#endif

// Now P256, SHA256, etc. work on all platforms
func signRequest(_ request: HTTPRequest, body: HTTPBody?, with key: P256.Signing.PrivateKey) throws -> String {
    // Same code works on macOS, iOS, and Linux
    let signature = try key.signature(for: dataToSign)
    return signature.rawRepresentation.base64EncodedString()
}
```

### TokenManager Protocol Hierarchy

The `TokenManager` protocol provides flexibility:

```swift
public protocol TokenManager: Sendable {
    var hasCredentials: Bool { get async }
    func validateCredentials() async throws(TokenManagerError) -> Bool
    func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials?
}

// Implementations for each auth method
public struct WebAuthTokenManager: TokenManager { ... }
public struct ServerToServerAuthManager: TokenManager { ... }
```

Benefits:
- ✅ Dependency injection for testing
- ✅ Runtime switching between auth methods
- ✅ Type safety with Swift 6's typed throws

### Handling CloudKit-Specific Quirks

The generated code handles most cases, but CloudKit has some quirks. The OpenAPI generator's `typeOverrides` feature lets us swap in custom implementations:

```yaml
# openapi-generator-config.yaml
generate:
  - types
  - client
accessModifier: internal
typeOverrides:
  schemas:
    FieldValue: CustomFieldValue  # Use our implementation
```

This single line tells the generator: "Whenever you would use the generated `FieldValue`, use `CustomFieldValue` instead."

**Why custom?** CloudKit's `ASSETID` type needs special handling. The API returns both `ASSET` and `ASSETID` as separate type discriminators, but they decode to the same structure. A generated enum-based approach can't handle this without custom logic:

```swift
/// Custom FieldValue with ASSETID handling
internal struct CustomFieldValue: Codable, Hashable, Sendable {
  public enum FieldTypePayload: String, Codable, Sendable {
    case asset = "ASSET"
    case assetid = "ASSETID"  // CloudKit quirk - both decode to AssetValue
    case string = "STRING"
    case int64 = "INT64"
    // ... more types
  }

  // Lookup table for type-based decoding
  private static let fieldTypeDecoders:
    [FieldTypePayload: (KeyedDecodingContainer<CodingKeys>) throws -> CustomFieldValuePayload] = [
      .asset: { .assetValue(try $0.decode(Components.Schemas.AssetValue.self, forKey: .value)) },
      .assetid: { .assetValue(try $0.decode(Components.Schemas.AssetValue.self, forKey: .value)) },
      // Both ASSET and ASSETID decode to the same AssetValue type
      // ... other type handlers
    ]
}
```

The custom implementation seamlessly integrates with the generated code while handling CloudKit's idiosyncrasies.

### Before and After: Real Usage Comparison

**Generated Code** (internal):
```swift
// What you'd write with raw generated code
let response = try await client.queryRecords(Operations.queryRecords.Input(
    path: .init(
        version: "1",
        container: "iCloud.com.example.MyApp",
        environment: .production,
        database: ._private
    ),
    body: .json(.init(
        query: .init(recordType: "User")
    ))
))

switch response {
case .ok(let ok):
    let records = try ok.body.json.records ?? []
    // Process records...
default:
    // Handle errors...
}
```

**MistKit Abstraction** (what users actually write):
```swift
// Clean, idiomatic Swift
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!
)

// Future API (planned):
let records = try await service.queryRecords(
    recordType: "User",
    in: .defaultZone,
    environment: .production,
    database: .private
)
```

**Code reduction**: ~70% fewer lines for common operations.

### Future Enhancements

While MistKit's current abstraction is powerful, several modern Swift features are planned for future releases:

#### 1. AsyncSequence for Pagination

```swift
// Planned feature
for try await record in service.records(matching: query) {
    process(record)
    // Automatically fetches next page when needed
}
```

#### 2. Result Builders for Query Construction

```swift
// Planned feature
let query = Query {
    RecordType("User")
    Filter(\.age > 18)
    Filter(\.status == "active")
    Sort(\.lastName, ascending: true)
}
```

#### 3. Property Wrappers for Field Mapping

```swift
// Planned feature
struct User {
    @CloudKitField("firstName") var firstName: String
    @CloudKitField("lastName") var lastName: String
    @CloudKitField("age") var age: Int
}
```

### Dependency Injection for Testability

MistKit uses constructor injection throughout:

```swift
// Production
let client = try MistKitClient(
    configuration: prodConfig,
    tokenManager: prodTokenManager,
    transport: URLSessionTransport()
)

// Testing
let mockTransport = MockTransport(cannedResponse: testResponse)
let mockTokenManager = MockTokenManager(testCredentials)

let testClient = try MistKitClient(
    configuration: testConfig,
    tokenManager: mockTokenManager,
    transport: mockTransport  // Injected mock
)

// Test without hitting real network
let response = try await testClient.queryRecords(...)
```

### The Result: Best of Both Worlds

MistKit's abstraction layer achieves:

1. ✅ **Type safety from generated code** - Compile-time guarantees
2. ✅ **Ergonomics from abstraction** - Pleasant to use
3. ✅ **Modern Swift throughout** - async/await, Sendable, actors
4. ✅ **Security built-in** - Automatic credential masking
5. ✅ **Testability** - Dependency injection everywhere
6. ✅ **Cross-platform** - Works anywhere Swift runs

**Key takeaway**: Great abstraction layers don't hide functionality—they hide complexity. MistKit's three-layer architecture (OpenAPI spec → Generated code → Abstraction) provides the perfect balance of safety, power, and usability.

---

## Part 5: Lessons Learned from Building Real Applications

The real test of any library isn't toy examples—it's production use cases. We built two command-line tools with MistKit: **Bushel** (macOS installer metadata tracker) and **Celestra** (RSS feed aggregator). These applications exposed gaps in the library, revealed Claude Code's limitations, and taught us valuable lessons about AI-assisted development.

### The Development Journey: A Two-Week Intensive

**Phase 1: Data Source Investigation (Days 1-2)**

Before writing any code, we needed to validate our schema designs against actual data sources.

For **Bushel**, we investigated various data sources for restore image metadata and signing status information.

**The First Lesson**: External APIs don't always provide the data you expect. **Always fetch and parse actual data before designing schemas.**

For **Celestra**, we evaluated:
- FeedKit for RSS/Atom parsing
- SyndicationKit as an alternative
- Designed `PublicFeed` and `PublicArticle` CloudKit record types

**Phase 2: API Surface Discovery (Days 3-4)**

**CRITICAL TURNING POINT**: We discovered MistKit's public API was incomplete.

```
CloudKitService only exposed 3 public methods:
- fetchCurrentUser()
- listZones()
- queryRecords()

NO public methods for:
- createRecords()
- modifyRecords()
- lookupRecords()
- deleteRecords()
```

We had to access internal OpenAPI types directly:
```swift
// Workaround - accessing internal types
service.mistKitClient.client.modifyRecords(...)
```

**Phase 3: Record Operation Type Issues (Days 5-6)**

The code was using `.create` operations exclusively:

```swift
// PROBLEM: Always tries to CREATE new records
return RecordOperation.create(...)
```

**Issue**: No deduplication logic. Second sync would fail with CONFLICT errors because records already exist.

**Solution**: Implement `.forceReplace` for upsert behavior or lookup-before-create logic.

**Phase 4: Build Failures and Missing Methods (Days 7-8)**

Build error revealed:
```
error: value of type 'CloudKitResponseProcessor' has no member 'processLookupRecordsResponse'
```

CloudKitResponseProcessor had processors for:
- `processCurrentUserResponse`
- `processListZonesResponse`
- `processQueryRecordsResponse`
- `processModifyRecordsResponse`

But NOT `processLookupRecordsResponse`—we were using a method that didn't exist yet.

**Phase 5: Schema and Permission Issues (Days 9-10)**

Discovered QUERYABLE index requirements:
- Fields used in queries MUST be marked QUERYABLE in schema
- Forgot to add QUERYABLE to `buildNumber` field initially
- Queries silently returned no results

**Phase 6: Test Availability Issues (Days 11-12)**

GitHub Actions failures on iOS/tvOS:
```swift
// WRONG: @available inside test body
@Test func testCrypto() {
    guard #available(macOS 10.15, iOS 13.0, *) else { return }
    // Test code...
}

// RIGHT: Use Swift Testing traits
@Test(.enabled(if: Platform.isCryptoAvailable))
func testCrypto() {
    // Test code...
}
```

### Claude Code Mistakes: What Went Wrong

**Mistake 1: Using Internal OpenAPI Types**

Claude generated code that referenced `Components.Schemas.RecordOperation` directly—an internal type, not part of the public API.

```swift
// WRONG: Internal type reference
let operation = Components.Schemas.RecordOperation(
    recordType: "RestoreImage",
    fields: fields
)
```

**Why this happened**: Claude saw the type existed and used it without checking if it was `public` or `internal`.

**Lesson**: **Always verify access modifiers before generating usage code.**

---

**Mistake 2: Hardcoded Create Operations**

```swift
// WRONG: Always create, never update
func createRecordOperation() -> RecordOperation {
    return RecordOperation.create(
        recordType: Self.recordType,
        recordName: self.recordName,
        fields: self.toFields()
    )
}
```

**Why this happened**: Claude didn't consider idempotency. CloudKit's `.create` fails if record already exists.

**Better approach**:
```swift
// RIGHT: Use forceReplace for upsert behavior
func upsertRecordOperation() -> RecordOperation {
    return RecordOperation.forceReplace(
        recordType: Self.recordType,
        recordName: self.recordName,
        fields: self.toFields()
    )
}
```

**Lesson**: **CloudKit distinguishes between create and update. For sync scenarios, use `.forceReplace`.**

---

**Mistake 3: Calling Non-Existent Methods**

Claude generated code that called `processLookupRecordsResponse()` when only 4 processor methods existed.

```swift
// WRONG: Method doesn't exist
let records = try processor.processLookupRecordsResponse(response)
```

**Why this happened**: Claude assumed if `processQueryRecordsResponse()` exists, similar methods must exist.

**Lesson**: **Don't assume patterns extend. Verify methods exist before using them.**

---

**Mistake 4: Incorrect Platform Availability Handling**

```swift
// WRONG: Guard inside test body
@Test func testECDSASigning() {
    guard #available(macOS 10.15, *) else {
        return  // Swift Testing doesn't see this as "skipped"
    }
    // ...
}

// RIGHT: Swift Testing trait
@Test(.enabled(if: Platform.isCryptoAvailable))
func testECDSASigning() {
    // ...
}
```

**Why this happened**: Claude used XCTest patterns, not Swift Testing patterns.

**Lesson**: **Swift Testing requires `.enabled(if:)` traits for conditional execution.**

---

**Mistake 5: Designing Schemas Based on Assumed Data**

Claude designed the schema assuming external APIs would contain:
- SHA256 hashes (some sources only provide SHA1)
- File sizes (not always provided despite documentation)

**Lesson**: **Fetch and parse actual data sources before finalizing schema designs.**

### Context Management and Knowledge Limitations

One of the biggest challenges working with Claude Code is managing its knowledge cutoffs and lack of familiarity with newer or niche APIs.

**Problem 1: Swift Testing vs XCTest**

Claude's training predates widespread Swift Testing adoption. It defaults to XCTest patterns:

```swift
// Claude's instinct: XCTest patterns
XCTAssertEqual(result, expected)
XCTAssertThrowsError(try badCall())

// What we need: Swift Testing patterns
#expect(result == expected)
#expect(throws: MyError.self) { try badCall() }
```

**Solution**: Provide documentation upfront. We added `.claude/docs/testing-enablinganddisabling.md` (126KB) that Claude reads on demand.

---

**Problem 2: CloudKit Web Services Documentation**

Apple's CloudKit Web Services REST API isn't well-documented online. Claude hallucinates endpoint structures and authentication flows.

**Solution**: We downloaded and included comprehensive documentation:
- `webservices.md` (289KB) - Complete REST API reference
- `cloudkitjs.md` (188KB) - Operation patterns and data types

Claude can `Read` these files when needed, giving it accurate information about authentication, endpoints, and error codes.

---

**Problem 3: swift-openapi-generator Specifics**

This is a relatively new tool with limited training data. Claude doesn't know about:
- `typeOverrides` in config files
- Middleware patterns
- The transport layer architecture

**Solution**: We added `swift-openapi-generator.md` (235KB) with full documentation. When Claude needs to configure code generation or implement middleware, it has authoritative reference material.

---

**Key Insight: CLAUDE.md as a Knowledge Router**

Our `CLAUDE.md` file acts as a table of contents:

```markdown
## Reference Documentation

**webservices.md** (289 KB) - CloudKit Web Services REST API
- **Primary use**: Implementing REST API endpoints
- **Consult when**: Writing API client code, handling authentication

**testing-enablinganddisabling.md** (126 KB) - Swift Testing
- **Primary use**: Writing modern Swift tests
- **Consult when**: Writing tests, testing async code
```

Claude doesn't need to memorize everything—it needs to know **where to look**. The CLAUDE.md file provides this map.

---

**Practical Context Management Strategies**

1. **Pre-load critical documentation** in `.claude/docs/`
2. **Use CLAUDE.md** to describe what each doc contains and when to consult it
3. **Fetch current information** with WebFetch for APIs that change (Apple's software update feeds)
4. **Reference actual code** - when Claude hallucinates an API, show it the real implementation
5. **Correct patterns immediately** - don't let wrong patterns propagate through the codebase

**Result**: With proper context, Claude goes from "guessing at Swift Testing syntax" to "correctly using `@Test(.enabled(if:))` traits" because it has the authoritative source.

### User Behaviors That Elevated Issues

**Behavior 1: Not Defining Complete API Requirements Upfront**

I started building demos without specifying what MistKit's public API should provide. This led to discovering API gaps mid-development.

**What I should have done**: Define a contract first—"Bushel needs: queryRecords, modifyRecords (with upsert), lookupRecords." Then ensure MistKit provides these before writing demo code.

---

**Behavior 2: Accepting Workarounds Too Quickly**

I allowed Claude to use internal types (`Components.Schemas.*`) as a workaround rather than extending the public API first.

```swift
// I accepted this workaround
service.mistKitClient.client.modifyRecords(...)
// Instead of requiring
service.modifyRecords(...)
```

**What I should have done**: Stop and add public methods to MistKit first. The demo should only use the public API—if it can't, that's a sign the library is incomplete.

---

**Behavior 3: Not Testing Against Real CloudKit Early Enough**

The record operation type issues (create vs update) would have been discovered immediately with a real CloudKit sync test.

**What I should have done**: Test with actual CloudKit containers on day 2, not day 8. Real API calls surface issues that unit tests miss.

---

**Behavior 4: Building Examples in Isolation**

Bushel and Celestra were developed somewhat independently. Result: code duplication and inconsistent patterns.

```swift
// Bushel's approach
struct BushelCloudKitService { ... }

// Celestra's approach
struct CelestraCloudKitService { ... }
// Both doing the same things differently
```

**What I should have done**: After Bushel worked, immediately extract common patterns into MistKit core before starting Celestra.

### Successful Patterns and Techniques

**Pattern 1: Schema-First Design with Data Validation**

```bash
# Step 1: Fetch actual data
curl https://mesu.apple.com/assets/... > actual_data.xml

# Step 2: Parse and analyze
swift run XMLAnalyzer actual_data.xml

# Step 3: Design schema based on actual fields
RECORD TYPE RestoreImage (
    version STRING QUERYABLE,
    buildNumber STRING QUERYABLE,  # Verified this field exists
    sha1Digest STRING,              # NOT sha256—verified from actual data
    ...
)
```

**Why it works**: Real data prevents schema mismatches that cause runtime failures.

---

**Pattern 2: Deterministic Record Naming**

```swift
struct RestoreImageRecord {
    var recordName: String {
        "restore-\(version)-\(buildNumber)"
    }
}
```

**Benefits**:
- Idempotent operations—same input produces same record name
- No duplicate records
- Enables `.forceReplace` for true upsert behavior
- Easy debugging—record names are human-readable

---

**Pattern 3: Protocol-Oriented Abstraction**

```swift
protocol CloudKitRecord {
    static var recordType: String { get }
    var recordName: String { get }
    func toFields() -> [String: FieldValue]
}

extension CloudKitRecord {
    func upsertOperation() -> RecordOperation {
        .forceReplace(
            recordType: Self.recordType,
            recordName: recordName,
            fields: toFields()
        )
    }
}
```

**Why it works**: Common behavior in protocol extension, type-specific logic in conformances. DRY and testable.

---

**Pattern 4: Comprehensive Error Handling**

```swift
switch response {
case .ok(let okResponse):
    let records = try okResponse.body.json.records ?? []
    return records

case .badRequest(let badResponse):
    let errorBody = try badResponse.body.json
    if let serverError = errorBody.serverErrorCode {
        switch serverError {
        case .CONFLICT:
            throw SyncError.recordAlreadyExists(recordName)
        case .NOT_FOUND:
            throw SyncError.recordNotFound(recordName)
        default:
            throw SyncError.cloudKitError(serverError, errorBody.reason)
        }
    }
    throw SyncError.unknownBadRequest(errorBody.reason)

case .unauthorized(let unauthResponse):
    throw SyncError.authenticationFailed

case .undocumented(let statusCode, _):
    throw SyncError.unexpectedStatusCode(statusCode)
}
```

**Why it works**: Preserves CloudKit's specific error information for debugging. Each error case handled explicitly.

---

**Pattern 5: Swift Testing Traits for Platform Availability**

```swift
enum Platform {
    static var isCryptoAvailable: Bool {
        #if canImport(CryptoKit)
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
            return true
        }
        #endif
        return false
    }
}

@Test(.enabled(if: Platform.isCryptoAvailable))
func testServerToServerAuth() async throws {
    // Test runs only where crypto is available
}
```

**Why it works**: Swift Testing framework properly marks tests as "skipped" rather than "passed" on unsupported platforms.

### The Value of Code Reviews: AI and Human Perspectives

Code generated or assisted by AI needs extra scrutiny. We found that combining automated AI reviews with human expertise catches different classes of issues.

**Automated AI Reviews (CodeRabbit)**

Tools like CodeRabbit provide consistent, pattern-based feedback:

```
✅ Detected: Unused import in ServerToServerAuthManager.swift
✅ Detected: Force unwrap on line 47 could cause crash
✅ Detected: Missing documentation for public method
⚠️ Suggestion: Consider extracting repeated JSON parsing into helper
```

**Strengths**:
- Catches style violations consistently
- Identifies potential nil crashes
- Enforces documentation standards
- Never gets tired or misses obvious issues

**Limitations**:
- Doesn't understand CloudKit-specific semantics
- Can't evaluate architectural decisions
- Misses subtle logic errors that compile fine
- Suggests "improvements" that break functionality

---

**Human Code Reviews**

Human reviewers catch what AI misses:

```swift
// AI generated this, automated review passed
func syncRecords(_ records: [CloudKitRecord]) async throws {
    for record in records {
        try await service.modifyRecords([record.upsertOperation()])
    }
}
```

**Human reviewer**: "Why are we making N network calls? CloudKit supports batch operations. This should be:

```swift
let operations = records.map { $0.upsertOperation() }
try await service.modifyRecords(operations)  // Single network call
```

**Human review catches**:
- Performance anti-patterns (N+1 queries)
- CloudKit API misuse (create vs forceReplace semantics)
- Security concerns (token exposure in logs)
- Architecture violations (using internal types)
- Missing error cases (what if batch partially fails?)

---

**Our Review Process**

1. **Claude generates code** → Initial implementation
2. **Automated linting** (`swiftlint`, `swift-format`) → Style consistency
3. **Claude self-review** → "Review this code for potential issues"
4. **CodeRabbit/automated AI** → Pattern-based analysis
5. **Human expert review** → Architecture, semantics, CloudKit-specific knowledge

**Example catch from human review**:

```swift
// Claude generated
public func queryRecords(recordType: String) async throws -> [RecordInfo] {
    let response = try await client.queryRecords(...)
    switch response {
    case .ok(let ok):
        return try ok.body.json.records ?? []
    default:
        throw CloudKitError.unknown  // Human: "This loses error information!"
    }
}
```

Human reviewer: "The `default` case discards CloudKit's error codes. We need specific handling for `.badRequest`, `.unauthorized`, `.forbidden` to provide actionable error messages."

---

**Best Practices for AI-Assisted Code Review**

1. **Don't skip review just because "AI wrote it"** - AI code needs *more* review, not less
2. **Use multiple review layers** - Automated catches syntax, human catches semantics
3. **Ask Claude to review its own code** - It often spots issues when prompted to look again
4. **Focus human review on domain logic** - Let automation handle formatting
5. **Document review feedback** - Patterns in reviews become future CLAUDE.md guidance

**Result**: Our codebase quality improved significantly when we treated AI-generated code as a first draft requiring thorough review, not a finished product.

### Key Takeaways for Claude Code Users

**1. Verify Public API Before Generating Usage Code**

Claude will use any type it sees. Check access modifiers (`public` vs `internal`) before accepting generated code.

```swift
// Ask: Is this type public?
Components.Schemas.RecordOperation  // Internal - don't use directly
```

---

**2. Don't Assume Patterns Extend**

If `queryRecords` exists, Claude assumes `lookupRecords`, `modifyRecords`, etc. follow the same pattern. **Verify each method exists.**

---

**3. Test Real Operations Early**

Unit tests validate types. Integration tests validate behavior. Test against actual CloudKit within the first few days.

---

**4. Extract Common Patterns After First Working Example**

Don't build multiple demos with duplicate code. After Bushel works:
1. Extract `CloudKitRecord` protocol
2. Extract common sync logic
3. Then build Celestra using those patterns

---

**5. Validate Data Sources Before Schema Design**

Fetch actual XML/JSON from APIs. Parse it. **Then** design schemas based on what actually exists, not what documentation says should exist.

---

**6. Provide Complete Requirements Upfront**

Before generating demo code:
- List all CloudKit operations needed
- Verify library provides them
- If not, add to library first

---

**7. Reject Workarounds That Use Internal Types**

When Claude suggests accessing internal types as a workaround, **stop**. Add the capability to the public API first.

---

**8. Use Swift Testing Patterns, Not XCTest Patterns**

Claude's knowledge may be dated. Swift Testing uses `.enabled(if:)` traits, not `guard #available` statements.

---

**9. CloudKit Operations Have Semantic Meaning**

`.create` fails if exists. `.update` fails if doesn't exist. `.forceReplace` is true upsert. Use the right operation for your use case.

---

**10. Iterate on Individual Endpoints Until Complete**

Don't move to the next endpoint until the current one passes:
- ✅ Unit tests pass
- ✅ Integration test passes
- ✅ Real CloudKit call succeeds
- ✅ Error handling is comprehensive

### The Bigger Lesson: AI Accelerates, Doesn't Replace

Claude Code made the development faster—what would have taken 2 weeks solo took 2-4 days per endpoint with AI assistance. But Claude made mistakes that required human correction:

- **Claude provided**: Fast boilerplate, comprehensive tests, pattern consistency
- **I provided**: Domain knowledge (CloudKit quirks), architectural decisions (public vs internal), quality gates (must test with real CloudKit)

The collaboration worked when I:
1. Set clear boundaries (use only public API)
2. Validated assumptions early (test real CloudKit quickly)
3. Extracted patterns immediately (don't let duplication spread)
4. Rejected workarounds (internal types are not acceptable)

Without these guardrails, the demos would have "worked" locally but failed in production. Claude accelerated the mechanical work; human judgment ensured correctness.

---

## Conclusion: Modern Swift, Modern Architecture

The complete rewrite of MistKit from scratch taught invaluable lessons about modern Swift development:

### What Worked Exceptionally Well

**1. OpenAPI-First Approach**
- Type safety exceeded expectations
- Complete API coverage guaranteed
- Maintenance reduced to spec updates
- Generated code quality was production-ready

**2. Three-Layer Architecture**
- Clear separation of concerns
- Internal generated code protected
- Public API stays stable
- Easy to test at each layer

**3. Swift 6 & Strict Concurrency**
- Caught concurrency bugs at compile-time
- Sendable compliance prevented data races
- Actor isolation simplified thread safety
- Modern async/await throughout

**4. Pre-Generation Strategy**
- Faster builds for library consumers
- Reviewable generated code in PRs
- No tool dependencies for users
- Better IDE autocomplete experience

### AI-Assisted Development: Lessons from SyntaxKit Applied

Like [SyntaxKit before it](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/), MistKit's development leveraged AI tools strategically—not for entire architectures, but for targeted acceleration:

**What AI Tools Excelled At**:
- ✅ **Test generation**: 161 comprehensive tests created with AI assistance
- ✅ **OpenAPI schema validation**: Catching inconsistencies in the specification
- ✅ **Documentation drafting**: API documentation and code comments
- ✅ **Refactoring suggestions**: Identifying opportunities to reduce complexity
- ✅ **Error handling patterns**: Suggesting comprehensive error cases

**What Required Human Judgment**:
- ❌ Overall architecture decisions (three-layer design)
- ❌ Authentication strategy selection
- ❌ API abstraction patterns
- ❌ Security implementation details
- ❌ Performance optimization trade-offs

**Tools Used**:
- **Claude Code**: Architecture planning, code reviews, documentation
- **Task Master**: Breaking complex tasks into manageable pieces (161 tests, 47 test files)
- **GitHub Copilot**: Speeding up repetitive code patterns
- **Continuous iteration**: AI-assisted refactoring across multiple development cycles

**The SyntaxKit Lesson Reinforced**: AI excels at unit tests, boilerplate, and specific tasks when given clear boundaries. Human developers provide the vision, architecture, and judgment. Together, they accelerate development without compromising quality.

The three-month rewrite timeline (July-September 2024) was only achievable by combining AI assistance with strong architectural foundations and modern tooling.

### Key Takeaways

1. **OpenAPI for REST Clients** - Excellent foundation for type-safe API clients
2. **Code Generation Works** - When done right, generates better code than hand-written
3. **Abstraction Matters** - Generated code + friendly API = great developer experience
4. **Modern Swift is Ready** - Swift 6 concurrency is production-ready
5. **Security from Day One** - Build in credential masking and secure logging early

### What's Next for MistKit

**v1.0 Alpha Delivers**:
- ✅ Both authentication methods (Web Auth Token, Server-to-Server)
- ✅ Type-safe CloudKit operations
- ✅ Cross-platform support
- ✅ Modern Swift throughout
- ✅ Production-ready security
- ✅ Comprehensive tests (161 tests, significant coverage)

**Future Roadmap** (Beta → v1.0):
- AsyncSequence for pagination
- Result builders for declarative queries
- Property wrappers for field mapping
- Additional CloudKit operations
- Performance optimizations
- Migration guides

> **Note**: The planned features (result builders, property wrappers, AsyncSequence) continue the evolution from [SyntaxKit](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/). Each Swift project teaches us new patterns—SyntaxKit showed us result builders for syntax trees, MistKit will apply them to CloudKit queries.

### Try It Yourself

MistKit v1.0 Alpha is available now:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/brightdigit/MistKit.git", from: "1.0.0-alpha.1")
]
```

**Resources**:
- 📚 [Documentation](https://swiftpackageindex.com/brightdigit/MistKit/documentation)
- 🐙 [GitHub Repository](https://github.com/brightdigit/MistKit)
- 💬 [Discussions](https://github.com/brightdigit/MistKit/discussions)

### The Bigger Picture: Sustainable Development with OpenAPI + Claude

Three months. 10,476 lines of generated code. 161 tests. Zero maintenance burden for API changes.

**That's the power of OpenAPI + Claude.**

Here's what this approach actually delivers:

**1. OpenAPI eliminates manual API maintenance**
- CloudKit adds a new endpoint? Update the spec, regenerate. Done.
- Apple changes a response format? Update the spec, regenerate. Done.
- No hunting through hand-written code trying to remember where you handle errors.

**2. Claude eliminates development tedium**
- 161 tests? Claude wrote drafts for most of them based on my patterns.
- Repetitive refactoring when I changed architecture? Claude handled the mechanical parts.
- Edge cases I might miss? Claude suggests them during code review.

**3. You provide the irreplaceable human judgment**
- Security patterns (credential masking, token storage)
- Architecture decisions (three-layer design, middleware chain)
- Developer experience (what should the public API feel like?)
- Trade-offs and priorities

**The key insight**: None of these three elements works alone. OpenAPI without abstraction is too low-level. Claude without direction produces generic code. Human-only development is too slow.

But **together**? You get:
- ✅ Type-safe code that matches the API perfectly (OpenAPI)
- ✅ Tests and boilerplate written quickly (Claude)
- ✅ Thoughtful architecture and security (You)
- ✅ A maintainable codebase that's easy to evolve

CloudKit Web Services is now accessible from any Swift platform, with a type-safe, modern API that feels natural to use. MistKit v1.0 Alpha is the result of this collaboration—between specification, AI, and human expertise.

> **Note**: I learned the "code generation + abstraction" pattern from my previous [SyntaxKit project](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/), but adding Claude as a development partner took it to another level.

### What's Next

**Want to build your own CloudKit tools?** Check out the upcoming articles where we'll build real command-line applications using MistKit:
- **Building Bushel**: Version history tracker
- **Creating Celestra**: RSS aggregator
- **Serverless Swift**: Deploying to AWS Lambda

Each will show how MistKit + OpenAPI make CloudKit Web Services accessible and maintainable.

---

**Series**: Modern Swift Patterns (Part 2 of 4)
**Part 1**: [Building SyntaxKit with AI](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/) - Code generation with SwiftSyntax
**Published**: [Date TBD]
**Author**: Leo Dion (BrightDigit)
**Tags**: Swift, CloudKit, OpenAPI, Code Generation, Swift 6, Server-Side Swift, Series
**Reading Time**: ~28 minutes

---

**In this series**:
1. [Building SyntaxKit with AI](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/) - Wrapping SwiftSyntax for elegant code generation
2. **Rebuilding MistKit: OpenAPI-Driven Development** ← You are here
3. Coming soon: Building Bushel - Version history tracker with MistKit
4. Coming soon: Creating Celestra - RSS aggregator with MistKit + SyndiKit

---

*MistKit: Bringing CloudKit to every Swift platform* 🌟
