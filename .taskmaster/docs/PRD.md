# Product Requirements Document: MistKit

## Executive Summary

### Product Vision
MistKit is a modern, cross-platform Swift package that provides seamless server-side and command-line access to Apple's CloudKit Web Services. It empowers Swift developers to build robust, cloud-integrated applications beyond Apple's ecosystem while maintaining the familiar CloudKit data model through an intuitive abstraction layer.

### Mission Statement
To democratize CloudKit access for server-side Swift applications, enabling developers to build cross-platform solutions that leverage Apple's cloud infrastructure without being limited to Apple platforms, while providing a developer-friendly API that feels native to Swift and CloudKit.

### Key Value Proposition
- **Cross-Platform CloudKit**: Access CloudKit from Linux servers, command-line tools, and non-Apple platforms
- **Native Swift Experience**: High-level abstraction layer that feels like using CloudKit framework
- **Type-Safe API**: Strongly-typed field values with OpenAPI-driven foundation
- **Production Ready**: Designed for server-side applications with proper authentication, error handling, and performance optimization
- **Developer Tooling**: Comprehensive CLI for testing, validation, and development

### Target Audience
- **Server-Side Swift Developers**: Building web applications, APIs, and microservices
- **DevOps Engineers**: Creating automation tools and deployment scripts
- **Cross-Platform Developers**: Building applications that need CloudKit data synchronization across non-Apple platforms
- **Enterprise Developers**: Integrating CloudKit into existing server infrastructure

## Technical Architecture

### Layered Architecture Design

```
┌─────────────────────────────────────┐
│        User Application             │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│     MistKit Public API              │
│   (High-Level Abstraction Layer)    │
│                                     │
│  • CloudKitService Protocol        │
│  • Strongly-Typed Records          │
│  • FieldValue Enum                 │
│  • Query Builders                  │
│  • Error Handling                  │
│  • Caching & Optimization          │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│   Generated OpenAPI Client          │
│                                     │
│  • Type-Safe HTTP Client           │
│  • Request/Response Models          │
│  • Serialization/Deserialization   │
│  • Basic Error Handling            │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│    CloudKit Web Services            │
│   (Apple's REST API)                │
└─────────────────────────────────────┘
```

### Strongly-Typed Record Design

#### Core Record Structure
```swift
public struct CloudKitRecord: Codable, Sendable {
    public let recordName: String?
    public let recordType: String
    public let recordChangeTag: String?
    public let fields: [String: FieldValue]
    
    public init(
        recordName: String? = nil,
        recordType: String,
        recordChangeTag: String? = nil,
        fields: [String: FieldValue] = [:]
    )
}
```

#### Strongly-Typed Field Values
```swift
public enum FieldValue: Codable, Equatable, Sendable {
    // Primitive types
    case string(String)
    case int64(Int64)
    case double(Double)
    case boolean(Bool)
    case bytes(Data)
    case date(Date)
    
    // CloudKit-specific types
    case location(CLLocation)
    case reference(RecordReference)
    case asset(Asset)
    
    // List types
    case stringList([String])
    case int64List([Int64])
    case doubleList([Double])
    case dateList([Date])
    case locationList([CLLocation])
    case referenceList([RecordReference])
    case assetList([Asset])
    
    // Convenience accessors
    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
    
    public var int64Value: Int64? {
        if case .int64(let value) = self { return value }
        return nil
    }
    
    // ... additional accessors for other types
}
```

#### Supporting Types
```swift
public struct RecordReference: Codable, Equatable, Sendable {
    public let recordName: String
    public let action: ReferenceAction?
    
    public enum ReferenceAction: String, Codable {
        case deleteSelf = "DELETE_SELF"
    }
}

public struct Asset: Codable, Equatable, Sendable {
    public let fileChecksum: String?
    public let size: Int64?
    public let referenceChecksum: String?
    public let downloadURL: URL?
    
    // Convenience initializer for uploads
    public init(fileURL: URL) throws {
        // Implementation for creating asset from local file
    }
}

public struct CLLocation: Codable, Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let horizontalAccuracy: Double?
    public let verticalAccuracy: Double?
    public let altitude: Double?
    public let speed: Double?
    public let course: Double?
    public let timestamp: Date?
}
```

### High-Level API Design

#### Service Protocol
```swift
public protocol CloudKitServiceProtocol: Sendable {
    func queryRecords(
        _ query: RecordQuery,
        from database: Database
    ) async throws -> QueryResult
    
    func saveRecord(
        _ record: CloudKitRecord, 
        to database: Database
    ) async throws -> CloudKitRecord
    
    func saveRecords(
        _ records: [CloudKitRecord],
        to database: Database,
        atomic: Bool
    ) async throws -> [CloudKitRecord]
    
    func deleteRecord(
        recordName: String, 
        recordType: String, 
        from database: Database
    ) async throws
    
    func lookupRecord(
        recordName: String,
        from database: Database,
        desiredKeys: [String]?
    ) async throws -> CloudKitRecord?
}

public enum Database: String, CaseIterable {
    case `public` = "public"
    case `private` = "private"
    case shared = "shared"
}
```

## Features & Requirements

### Core CloudKit Operations

#### Record Management
- **Query Records**: Advanced filtering, sorting, and pagination with strongly-typed field values
- **Modify Records**: Create, update, delete operations with type-safe field handling
- **Lookup Records**: Efficient batch retrieval with field type preservation
- **Record Changes**: Incremental sync with strongly-typed change detection

#### Database Support
- **Public Database**: Read-only access to publicly shared records
- **Private Database**: Full CRUD operations for user-specific data
- **Shared Database**: Collaborative records shared between users

#### Field Type Support
- **Primitive Types**: String, Int64, Double, Boolean, Bytes, Date
- **CloudKit Types**: Location, Reference, Asset with proper Swift representations
- **List Types**: Arrays of all supported primitive and CloudKit types
- **Type Conversion**: Automatic conversion between Swift types and CloudKit field formats

#### Query Capabilities
- **Type-Safe Filtering**: Strongly-typed field comparisons and operations
- **Complex Queries**: Multiple filter conditions with proper type validation
- **Location Queries**: Geospatial searches with CLLocation integration
- **List Operations**: Queries on list fields with contains/member operations

### CLI Testing Tool: `mistk`

#### Purpose
A comprehensive command-line interface for testing MistKit's API robustness, validating CloudKit operations, and providing developer tooling for CloudKit integration.

#### Core Commands

##### Database-Specific Testing
```bash
# Test public database operations (read-only)
mistk records query --database public --container "iCloud.com.example.app" --api-token "..."

# Test private database operations (requires authentication)
mistk records crud --database private --container "iCloud.com.example.app" --api-token "..." --web-auth-token "..."

# Test operations across all databases
mistk records test --database all --container "iCloud.com.example.app" --api-token "..." --web-auth-token "..."
```

##### Field Type Validation
```bash
# Test all CloudKit field types
mistk field-types validate --database private --test-all-types

# Test specific field type combinations
mistk field-types test --types string,int64,location,asset --database private

# Stress test field type serialization
mistk field-types stress --operations 1000 --all-types
```

##### Performance Testing
```bash
# Stress test with concurrent operations
mistk stress --database private --operations 1000 --concurrency 50 --duration 60s

# Benchmark query performance
mistk benchmark query --database public --record-type "Article" --query-variations 20

# Test batch operations
mistk benchmark batch --database private --batch-sizes 10,50,100 --operations create,update,delete
```

##### Authentication Testing
```bash
# Test API token authentication
mistk auth test --api-token "..." --container "iCloud.com.example.app"

# Test server-to-server authentication
mistk auth test --server-to-server --key-file private.p8 --key-id ABC123

# Validate authentication across databases
mistk auth validate --database all --container "iCloud.com.example.app"
```

##### Zone Management Testing
```bash
# Test zone operations (private database only)
mistk zones test --database private --create-test-zones 5

# Test zone changes and sync
mistk zones sync --database private --test-change-tokens
```

##### Asset Testing
```bash
# Test asset upload/download
mistk assets test --database private --file-sizes 1KB,1MB,10MB

# Test asset reference handling
mistk assets references --database private --test-record-integration
```

#### Command Structure
```
mistk
├── records
│   ├── query     # Test record querying
│   ├── crud      # Test create, update, delete operations
│   ├── lookup    # Test record lookup operations
│   └── changes   # Test change tracking
├── zones
│   ├── list      # Test zone listing
│   ├── create    # Test zone creation (private only)
│   ├── delete    # Test zone deletion (private only)
│   └── sync      # Test zone change tracking
├── subscriptions
│   ├── list      # Test subscription listing
│   ├── create    # Test subscription creation
│   └── modify    # Test subscription updates
├── users
│   ├── current   # Test current user lookup
│   └── discover  # Test user discovery
├── assets
│   ├── upload    # Test asset uploads
│   └── test      # Test asset handling in records
├── field-types
│   ├── validate  # Test all field type handling
│   ├── test      # Test specific field types
│   └── stress    # Stress test type conversion
├── auth
│   ├── test      # Test authentication methods
│   └── validate  # Validate auth across databases
├── stress        # Load testing
├── benchmark     # Performance benchmarking
└── config        # Configuration management
```

#### Configuration & Environment
```bash
# Save configuration for repeated use
mistk config set --container "iCloud.com.example.app" --api-token "..."

# Use environment-specific configs
mistk config use development
mistk config use production

# Export test results
mistk stress --database private --output-format json --export results.json
```

### OpenAPI Specification Validation

#### Critical Importance
Since MistKit's `openapi.yaml` file is human-authored based on Apple's CloudKit Web Services documentation rather than being an official specification from Apple, comprehensive validation is essential to ensure accuracy and completeness.

#### Validation Strategy

##### 1. Live API Contract Testing
- **Response Schema Validation**: Test actual CloudKit API responses against our OpenAPI schemas
- **Request Format Verification**: Ensure our request models produce valid CloudKit API calls
- **Error Response Matching**: Validate that our error schemas match actual CloudKit error responses
- **Field Type Accuracy**: Confirm CloudKit field types behave as documented in our spec

##### 2. Coverage Analysis
- **Operation Completeness**: Verify all CloudKit Web Services operations are included
- **Parameter Coverage**: Ensure all request parameters and options are captured
- **Response Model Completeness**: Validate all response fields and nested objects
- **Edge Case Documentation**: Test boundary conditions and optional parameters

##### 3. Integration Testing Pipeline
```bash
# CI/CD integration testing
swift test --filter OpenAPIValidationTests

# Live API validation (requires test credentials)
./Scripts/validate-openapi.sh --environment development --live-test

# Generated code verification
swift run swift-openapi-generator generate --verify-only
```

##### 4. Continuous Validation
- **Automated Testing**: Regular validation against live CloudKit services
- **Schema Drift Detection**: Monitor for changes in CloudKit API behavior
- **Documentation Updates**: Track Apple's documentation changes for API updates
- **Breaking Change Detection**: Identify when CloudKit responses no longer match our spec

##### 5. Validation Test Suite
- **Comprehensive Operation Testing**: Every OpenAPI operation tested against live CloudKit
- **Error Scenario Testing**: Trigger and validate all documented error conditions
- **Authentication Testing**: Verify auth flows match OpenAPI security schemes
- **Database-Specific Testing**: Validate operations across public/private/shared databases

#### Maintenance Process
1. **Regular API Testing**: Weekly automated validation against CloudKit staging/production
2. **Apple Documentation Monitoring**: Track changes to CloudKit Web Services documentation
3. **Community Feedback**: Incorporate real-world usage findings into spec updates
4. **Version Control**: Semantic versioning for OpenAPI spec changes with impact analysis

### Platform Support

#### Minimum Requirements
- **Swift 5.9+**: Modern Swift language features and concurrency support
- **Platform Versions**:
  - macOS 10.15+ (Catalina)
  - iOS 13.0+
  - tvOS 13.0+
  - watchOS 6.0+
  - visionOS 1.0+
  - Linux (Ubuntu 18.04+, Amazon Linux 2+)

#### Dependencies
- **Swift OpenAPI Generator**: Automatic client code generation
- **Swift OpenAPI Runtime**: HTTP transport and middleware support
- **URLSession Transport**: Cross-platform HTTP client implementation
- **Swift ArgumentParser**: CLI argument handling for `mistk` tool

### Authentication & Security

#### Supported Authentication Methods
1. **API Token Authentication**
   - CloudKit Dashboard-generated API tokens
   - Query parameter-based authentication
   - Suitable for development and testing

2. **Server-to-Server Authentication**
   - Private key-based authentication
   - Header-based key ID transmission
   - Production-ready security model

#### Security Features
- **TLS/HTTPS Only**: All communications encrypted in transit
- **Token Management**: Secure storage and rotation handling
- **Error Context**: Detailed security error reporting without exposure
- **Rate Limiting**: Built-in respect for CloudKit API limits
- **Database Access Control**: Proper enforcement of public/private database permissions

## User Experience

### Developer Experience Priorities

#### Intuitive Record Creation
```swift
// Natural, type-safe field assignment
let blogPost = CloudKitRecord(
    recordType: "BlogPost",
    fields: [
        "title": .string("Getting Started with MistKit"),
        "content": .string("CloudKit for everyone..."),
        "publishedAt": .date(Date()),
        "wordCount": .int64(1200),
        "published": .boolean(true),
        "rating": .double(4.7),
        "tags": .stringList(["swift", "cloudkit", "tutorial"]),
        "author": .reference(RecordReference(recordName: "author123")),
        "featuredImage": .asset(try Asset(fileURL: imageURL)),
        "lastEditLocation": .location(CLLocation(
            latitude: 37.7749, 
            longitude: -122.4194
        ))
    ]
)

// Save to appropriate database
let savedPost = try await client.saveRecord(blogPost, to: .private)
```

#### Database-Aware Operations
```swift
// Query public database (no authentication required for reads)
let publicArticles = try await client.queryRecords(
    .where("featured", .equals, .boolean(true)),
    from: .public
)

// Query private database (requires authentication)
let userDrafts = try await client.queryRecords(
    .where("published", .equals, .boolean(false)),
    from: .private
)

// Database validation at compile time
// This would be a compiler error since zones can only be managed in private database:
// try await client.createZone(zoneID, in: .public) // ❌ Compile error
```

#### CLI Testing Integration
```swift
// Developers can validate their CloudKit setup before coding
// Terminal: mistk auth validate --database all --container "iCloud.com.example.app"

// Test API robustness during development
// Terminal: mistk field-types validate --database private --record-type "BlogPost"

// Performance testing for production readiness
// Terminal: mistk stress --database private --operations 1000 --concurrency 20
```

### Documentation Strategy

#### Multi-Level Documentation
1. **Quick Start Guide**: Basic setup and common operations
2. **Database Guide**: Understanding public vs private database capabilities
3. **CLI Reference**: Complete `mistk` command documentation
4. **Migration Guide**: Moving from CloudKit framework to MistKit
5. **API Reference**: Complete documentation for abstraction layer
6. **Performance Guide**: Optimization techniques and best practices

#### Example Applications

##### 1. MistDemo
Web-based authentication and basic operations demonstration, focusing on CloudKit authentication flows and simple API calls.

##### 2. Server-Side Web Application Demo
A comprehensive demonstration of MistKit's primary use case - building server-side Swift web applications that use CloudKit as their backend database.

**Architecture:**
- **Backend**: Hummingbird server application using MistKit for all CloudKit operations
- **Frontend**: Modern web interface (HTML/CSS/JavaScript) consuming REST APIs
- **Database**: CloudKit (public and private databases) accessed through MistKit abstraction layer

**Demonstrated Features:**
```swift
// Example server endpoints using MistKit
app.group("api") { api in
    // User management
    api.get("user/profile") { request async throws -> UserProfile in
        let userInfo = try await cloudKit.getCurrentUser()
        return UserProfile(from: userInfo)
    }
    
    // Article CRUD operations
    api.post("articles") { request async throws -> Article in
        let article = try await request.decode(as: CreateArticleRequest.self)
        let record = CloudKitRecord(
            recordType: "Article",
            fields: [
                "title": .string(article.title),
                "content": .string(article.content),
                "publishedAt": .date(Date()),
                "author": .reference(RecordReference(recordName: article.authorID))
            ]
        )
        let saved = try await cloudKit.saveRecord(record, to: .public)
        return Article(from: saved)
    }
    
    // Query with complex filtering
    api.get("articles") { request async throws -> [Article] in
        let query = RecordQuery
            .where("publishedAt", .greaterThan, .date(lastWeek))
            .and("featured", .equals, .boolean(true))
            .sorted(by: "publishedAt", ascending: false)
            .limit(20)
        
        let result = try await cloudKit.queryRecords(query, from: .public)
        return result.records.map(Article.init)
    }
}
```

**Key Demonstrations:**
- **REST API Development**: Building web APIs with CloudKit as the data store
- **Authentication Integration**: Server-to-server CloudKit auth in web applications  
- **Database Scoping**: Proper use of public vs private databases for different data types
- **Real-time Features**: WebSocket integration with CloudKit subscriptions for live updates
- **File Handling**: Asset upload/download through web interfaces using CloudKit assets
- **Performance Patterns**: Efficient querying, caching, and batch operations
- **Error Handling**: Graceful error handling and user-friendly error responses

**Web Interface Features:**
- **Article Management**: Create, edit, and publish articles stored in CloudKit
- **User Profiles**: User registration and profile management
- **Real-time Updates**: Live article updates using CloudKit subscriptions
- **File Uploads**: Image and document uploads using CloudKit assets
- **Advanced Search**: Complex query interface demonstrating MistKit's query capabilities
- **Performance Dashboard**: Real-time metrics showing CloudKit operation performance

**Technical Implementation:**
- **Strongly-Typed Models**: Demonstrates FieldValue enum usage for type-safe record handling
- **Database Strategy**: Shows when to use public vs private databases
- **Caching Layer**: Intelligent caching strategies for improved performance
- **Concurrent Operations**: Proper use of Swift concurrency with CloudKit operations
- **Error Recovery**: Robust error handling and retry logic

##### 3. CLI Tool (`mistk`)
Command-line utility for CloudKit administration, testing, and validation as detailed in the CLI section above.

##### 4. Sync Service
Background service for data synchronization between CloudKit and other data sources, demonstrating long-running server processes.

##### 5. Migration Tool
Example bulk data migration utility showing how to efficiently transfer large datasets to/from CloudKit using MistKit's batch operations.

## Success Metrics

### Technical Performance Indicators
- **Type Safety**: Zero runtime type errors in field value operations
- **API Coverage**: 100% of CloudKit Web Services operations with strongly-typed interfaces
- **Database Coverage**: Complete support for public, private, and shared database operations
- **CLI Robustness**: Comprehensive test coverage through `mistk` tool validation
- **Serialization Performance**: Efficient conversion between Swift types and CloudKit formats

### Developer Satisfaction Measures
- **Type Safety Appreciation**: Feedback on compile-time error prevention
- **Database Understanding**: Clear separation of public/private database capabilities
- **CLI Tool Utility**: Usage and feedback on `mistk` for development and testing
- **API Intuitiveness**: Ease of learning for CloudKit and server-side Swift developers
- **Migration Experience**: Smoothness of transition from manual CloudKit HTTP clients

### Quality Assurance Targets
- **Test Coverage**: >90% code coverage for abstraction layer and core functionality
- **CLI Test Coverage**: Comprehensive validation of all CloudKit operations through `mistk`
- **Platform Compatibility**: Successful builds on all supported platforms
- **Database Operation Validation**: Thorough testing of public/private database access patterns
- **Performance Benchmarks**: Consistent performance across abstraction and generated layers

## Timeline & Milestones

### Phase 1: Strongly-Typed Foundation (Current)
- ✅ OpenAPI specification integration
- 🔄 FieldValue enum with all CloudKit types
- 🔄 CloudKitRecord with strongly-typed fields
- 🔄 Database enum and access control
- 🔄 Type-safe serialization/deserialization
- 🔄 Basic query builder with type validation

### Phase 2: Complete Type System & CLI (Next 2-3 months)
- **Full Field Type Support**: All CloudKit field types with proper Swift representations
- **Database-Aware API**: Complete public/private database operation support
- **CLI Tool Implementation**: `mistk` command with all testing capabilities
- **Advanced Query Builder**: Complete type-safe query construction
- **Error Type Mapping**: Comprehensive error handling with field type and database context
- **Performance Optimization**: Efficient type conversion and validation

### Phase 3: Production Ready (3-6 months)
- **API Stabilization**: Stable public API with semantic versioning
- **CLI Tool Maturity**: Production-ready `mistk` with comprehensive test suites
- **Performance Benchmarks**: Type system and database operation performance validation
- **Security Audit**: Review of type safety, database access, and serialization security
- **Documentation**: Complete guides for strongly-typed CloudKit development
- **1.0 Release**: Production-ready release with stable type system and CLI

### Phase 4: Ecosystem Growth (6+ months)
- **Community**: Active open-source community development
- **Framework Integrations**: Vapor and Hummingbird-specific convenience APIs
- **Advanced CLI Features**: Enhanced `mistk` capabilities and reporting
- **Enterprise Features**: Advanced database management and monitoring tools
- **Performance Monitoring**: Built-in telemetry and performance tracking

## Conclusion

MistKit's strongly-typed abstraction layer with comprehensive database support and robust CLI tooling represents a significant advancement in CloudKit accessibility and developer experience. By providing compile-time type safety for CloudKit field values, clear database operation boundaries, and comprehensive testing tools through the `mistk` CLI, MistKit enables developers to build robust, cross-platform applications with confidence.

The FieldValue enum system ensures that field type errors are caught at compile time rather than runtime, while the database-aware API prevents incorrect operations on public databases. The `mistk` CLI provides developers with immediate validation and testing capabilities, dramatically improving development productivity and application reliability.

Combined with the layered architecture and modern Swift features, MistKit provides an optimal balance of type safety, database correctness, comprehensive testing, and ease of use for server-side Swift applications accessing CloudKit Web Services.