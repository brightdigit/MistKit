# Testing Strategy

Comprehensive testing approach for MistDemo using Swift Testing framework.

## Testing Levels

### 1. Unit Tests
- Individual command parsing
- Configuration loading and merging
- Output formatting
- Error handling
- Validation logic

### 2. Integration Tests
- Commands with mock MistKit client
- Configuration sources integration
- Output formatter integration
- Error propagation

### 3. End-to-End Tests
- Real CloudKit operations (CI only)
- Full command execution
- Authentication flows
- Multi-command workflows

## Test Organization

```
Tests/
└── MistDemoTests/
    ├── Commands/
    │   ├── QueryCommandTests.swift
    │   ├── CreateCommandTests.swift
    │   ├── UpdateCommandTests.swift
    │   └── ...
    ├── Configuration/
    │   ├── ConfigurationManagerTests.swift
    │   ├── ProfileMergingTests.swift
    │   └── PriorityResolutionTests.swift
    ├── Output/
    │   ├── JSONFormatterTests.swift
    │   ├── TableFormatterTests.swift
    │   ├── CSVFormatterTests.swift
    │   └── YAMLFormatterTests.swift
    ├── Integration/
    │   ├── QueryIntegrationTests.swift
    │   ├── AuthenticationFlowTests.swift
    │   └── ErrorHandlingTests.swift
    └── EndToEnd/
        ├── RealCloudKitTests.swift
        └── WorkflowTests.swift
```

## Swift Testing Framework

MistDemo uses Swift Testing (`@Test` macro) exclusively.

### Basic Test Structure

```swift
import Testing
@testable import MistDemo

struct QueryCommandTests {
    @Test("Query command parses basic options")
    func testBasicParsing() async throws {
        let args = ["query", "--limit", "50", "--zone", "CustomZone"]
        let command = try QueryCommand.parseAsRoot(args)

        #expect(command.limit == 50)
        #expect(command.zone == "CustomZone")
    }

    @Test("Query command loads configuration")
    func testConfigurationLoading() async throws {
        let config = """
        {
            "container_id": "iCloud.com.example.Test",
            "api_token": "test-token",
            "query": {
                "limit": 100,
                "zone": "_defaultZone"
            }
        }
        """

        // Create temp config file
        let configFile = try createTempFile(content: config, extension: "json")
        defer { try? FileManager.default.removeItem(at: configFile) }

        let args = ["query", "--config-file", configFile.path]
        let command = try QueryCommand.parseAsRoot(args)
        let queryConfig = try command.loadConfig()

        #expect(queryConfig.limit == 100)
        #expect(queryConfig.zone == "_defaultZone")
    }
}
```

### Parameterized Tests

```swift
import Testing

struct OutputFormatterTests {
    @Test("Format query results", arguments: [
        (OutputFormat.json, "json"),
        (OutputFormat.table, "table"),
        (OutputFormat.csv, "csv"),
        (OutputFormat.yaml, "yaml")
    ])
    func testOutputFormatting(
        format: OutputFormat,
        expectedPrefix: String
    ) async throws {
        let records = createTestRecords()
        let formatter = OutputFormatter(format: format)
        let output = try formatter.format(records)

        #expect(output.contains(expectedPrefix))
    }

    @Test("Validate field types", arguments: [
        ("string", FieldType.string),
        ("int64", FieldType.int64),
        ("timestamp", FieldType.timestamp),
        ("asset", FieldType.asset)
    ])
    func testFieldTypeValidation(
        input: String,
        expectedType: FieldType
    ) throws {
        let type = try FieldType(rawValue: input)
        #expect(type == expectedType)
    }
}
```

### Async Tests

```swift
import Testing
@testable import MistDemo

struct AuthenticationTests {
    @Test("Obtain web auth token")
    func testObtainAuthToken() async throws {
        // Mock CloudKit auth server
        let mockServer = MockAuthServer()
        try await mockServer.start(port: 8080)
        defer { mockServer.stop() }

        let command = AuthTokenCommand(
            apiToken: "test-token",
            port: 8080,
            noBrowser: true
        )

        // Simulate auth callback
        Task {
            try await Task.sleep(for: .milliseconds(100))
            await mockServer.sendAuthCallback(token: "mock-web-auth-token")
        }

        let token = try await command.execute()
        #expect(token == "mock-web-auth-token")
    }

    @Test("Handle auth timeout")
    func testAuthTimeout() async throws {
        let mockServer = MockAuthServer()
        try await mockServer.start(port: 8081)
        defer { mockServer.stop() }

        let command = AuthTokenCommand(
            apiToken: "test-token",
            port: 8081,
            timeout: 0.5,
            noBrowser: true
        )

        await #expect(throws: AuthError.timeout) {
            try await command.execute()
        }
    }
}
```

## Mock Infrastructure

### Mock MistKit Client

```swift
import MistKit

actor MockMistKitClient: MistKitClientProtocol {
    var queryResponses: [String: [CloudKitRecord]] = [:]
    var createResponses: [String: CloudKitRecord] = [:]
    var queryCallCount = 0
    var createCallCount = 0

    func queryRecords(
        recordType: String,
        database: CloudKitDatabase,
        zone: String?,
        filters: [String],
        limit: Int
    ) async throws -> [CloudKitRecord] {
        queryCallCount += 1

        let key = "\(recordType):\(database):\(zone ?? "_defaultZone")"
        return queryResponses[key] ?? []
    }

    func createRecord(
        recordType: String,
        database: CloudKitDatabase,
        zone: String?,
        fields: [String: Any]
    ) async throws -> CloudKitRecord {
        createCallCount += 1

        let key = "\(recordType):\(database)"
        if let response = createResponses[key] {
            return response
        }

        // Generate mock response
        return CloudKitRecord(
            recordName: "mock_\(UUID().uuidString)",
            recordType: recordType,
            fields: fields
        )
    }

    func reset() {
        queryResponses.removeAll()
        createResponses.removeAll()
        queryCallCount = 0
        createCallCount = 0
    }
}
```

### Mock Auth Server

```swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

actor MockAuthServer {
    private var server: HTTPServer?

    func start(port: Int) async throws {
        server = HTTPServer(port: port)
        try await server?.start()
    }

    func stop() {
        server?.stop()
    }

    func sendAuthCallback(token: String) async {
        let url = URL(string: "http://127.0.0.1:\(server?.port ?? 8080)/auth-callback")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "ckWebAuthToken": token
        ])

        _ = try? await URLSession.shared.data(for: request)
    }
}
```

## Test Data Helpers

```swift
import MistKit

extension CloudKitRecord {
    static func mockNote(
        recordName: String = "test_note",
        title: String = "Test Note",
        index: Int = 1,
        modified: Int = 0
    ) -> CloudKitRecord {
        CloudKitRecord(
            recordName: recordName,
            recordType: "Note",
            fields: [
                "title": ["value": title],
                "index": ["value": index],
                "modified": ["value": modified],
                "createdAt": ["value": Date().timeIntervalSince1970 * 1000]
            ]
        )
    }

    static func mockNotes(count: Int) -> [CloudKitRecord] {
        (0..<count).map { i in
            mockNote(
                recordName: "note_\(i)",
                title: "Note \(i)",
                index: i
            )
        }
    }
}

func createTempFile(content: String, extension ext: String) throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    let fileName = "\(UUID().uuidString).\(ext)"
    let fileURL = tempDir.appendingPathComponent(fileName)

    try content.write(to: fileURL, atomically: true, encoding: .utf8)

    return fileURL
}

func createTempConfigFile(
    containerID: String = "iCloud.com.example.Test",
    apiToken: String = "test-token",
    customValues: [String: Any] = [:]
) throws -> URL {
    var config: [String: Any] = [
        "container_id": containerID,
        "api_token": apiToken,
        "environment": "development",
        "database": "public"
    ]

    config.merge(customValues) { _, new in new }

    let data = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted])
    let content = String(data: data, encoding: .utf8)!

    return try createTempFile(content: content, extension: "json")
}
```

## Test Suites by Command

### Query Command Tests

```swift
import Testing
@testable import MistDemo

struct QueryCommandTests {
    @Test("Parse filter expressions")
    func testFilterParsing() throws {
        let args = [
            "query",
            "--filter", "title CONTAINS 'test'",
            "--filter", "index > 10"
        ]
        let command = try QueryCommand.parseAsRoot(args)

        #expect(command.filter.count == 2)
        #expect(command.filter[0] == "title CONTAINS 'test'")
        #expect(command.filter[1] == "index > 10")
    }

    @Test("Parse sort options")
    func testSortParsing() throws {
        let args = ["query", "--sort", "createdAt:desc"]
        let command = try QueryCommand.parseAsRoot(args)

        #expect(command.sort == "createdAt:desc")
    }

    @Test("Validate limit bounds", arguments: [
        (0, false),
        (1, true),
        (100, true),
        (200, true),
        (201, false)
    ])
    func testLimitValidation(limit: Int, shouldSucceed: Bool) throws {
        if shouldSucceed {
            let validator = LimitValidator()
            #expect(throws: Never.self) {
                try validator.validate(limit: limit)
            }
        } else {
            let validator = LimitValidator()
            #expect(throws: ValidationError.self) {
                try validator.validate(limit: limit)
            }
        }
    }

    @Test("Execute query with mock client")
    func testQueryExecution() async throws {
        let mockClient = MockMistKitClient()
        await mockClient.queryResponses["Note:public:_defaultZone"] = [
            .mockNote(recordName: "note_1", title: "Test 1"),
            .mockNote(recordName: "note_2", title: "Test 2")
        ]

        let command = QueryCommand(
            containerID: "iCloud.com.example.Test",
            apiToken: "test-token",
            limit: 10
        )

        let results = try await command.execute(client: mockClient)

        #expect(results.count == 2)
        #expect(await mockClient.queryCallCount == 1)
    }
}
```

### Create Command Tests

```swift
import Testing
@testable import MistDemo

struct CreateCommandTests {
    @Test("Parse field definitions", arguments: [
        ("title:string:My Note", "title", FieldType.string, "My Note"),
        ("index:int64:42", "index", FieldType.int64, "42"),
        ("createdAt:timestamp:2024-01-01T00:00:00Z", "createdAt", FieldType.timestamp, "2024-01-01T00:00:00Z")
    ])
    func testFieldParsing(
        input: String,
        expectedName: String,
        expectedType: FieldType,
        expectedValue: String
    ) throws {
        let field = try Field.parse(input)

        #expect(field.name == expectedName)
        #expect(field.type == expectedType)
        #expect(field.value == expectedValue)
    }

    @Test("Create record with fields")
    func testCreateRecord() async throws {
        let mockClient = MockMistKitClient()

        let command = CreateCommand(
            containerID: "iCloud.com.example.Test",
            apiToken: "test-token",
            fields: [
                "title:string:New Note",
                "index:int64:1"
            ]
        )

        let record = try await command.execute(client: mockClient)

        #expect(record.recordType == "Note")
        #expect(await mockClient.createCallCount == 1)
    }

    @Test("Create from JSON file")
    func testCreateFromJSON() async throws {
        let json = """
        {
            "recordType": "Note",
            "fields": {
                "title": {"value": "From JSON"},
                "index": {"value": 10}
            }
        }
        """

        let jsonFile = try createTempFile(content: json, extension: "json")
        defer { try? FileManager.default.removeItem(at: jsonFile) }

        let mockClient = MockMistKitClient()
        let command = CreateCommand(
            containerID: "iCloud.com.example.Test",
            apiToken: "test-token",
            jsonFile: jsonFile.path
        )

        let record = try await command.execute(client: mockClient)
        #expect(await mockClient.createCallCount == 1)
    }
}
```

### Authentication Tests

```swift
import Testing
@testable import MistDemo

struct AuthenticationTests {
    @Test("Validate credentials present")
    func testValidateCredentials() throws {
        let validator = CredentialValidator()

        #expect(throws: ValidationError.self) {
            try validator.validate(containerID: "", apiToken: "token")
        }

        #expect(throws: ValidationError.self) {
            try validator.validate(containerID: "container", apiToken: "")
        }

        #expect(throws: Never.self) {
            try validator.validate(containerID: "container", apiToken: "token")
        }
    }

    @Test("Auth token command execution")
    func testAuthTokenCommand() async throws {
        let mockServer = MockAuthServer()
        try await mockServer.start(port: 9000)
        defer { mockServer.stop() }

        let command = AuthTokenCommand(
            apiToken: "test-api-token",
            port: 9000,
            noBrowser: true
        )

        Task {
            try await Task.sleep(for: .milliseconds(200))
            await mockServer.sendAuthCallback(token: "test-web-auth-token")
        }

        let token = try await command.execute()
        #expect(token == "test-web-auth-token")
    }
}
```

## Integration Tests

```swift
import Testing
@testable import MistDemo

struct IntegrationTests {
    @Test("Complete query workflow")
    func testQueryWorkflow() async throws {
        // Setup configuration
        let configFile = try createTempConfigFile(
            customValues: ["query": ["limit": 50]]
        )
        defer { try? FileManager.default.removeItem(at: configFile) }

        // Setup mock client
        let mockClient = MockMistKitClient()
        await mockClient.queryResponses["Note:public:_defaultZone"] = CloudKitRecord.mockNotes(count: 10)

        // Parse command
        let args = ["query", "--config-file", configFile.path, "--output", "json"]
        let command = try QueryCommand.parseAsRoot(args)

        // Execute
        let config = try command.loadConfig()
        let results = try await command.execute(client: mockClient, config: config)

        // Verify
        #expect(results.count == 10)
        #expect(config.limit == 50)
    }

    @Test("Error handling workflow")
    func testErrorHandling() async throws {
        let mockClient = MockMistKitClient()
        // Don't set up any responses - will error

        let command = QueryCommand(
            containerID: "iCloud.com.example.Test",
            apiToken: "test-token"
        )

        await #expect(throws: CloudKitError.self) {
            try await command.execute(client: mockClient)
        }
    }
}
```

## End-to-End Tests (CI Only)

```swift
import Testing
@testable import MistDemo

@Suite(.tags(.endToEnd))
struct EndToEndTests {
    @Test("Real CloudKit query", .enabled(if: ProcessInfo.processInfo.environment["CI_E2E_TESTS"] == "true"))
    func testRealQuery() async throws {
        let containerID = try #require(ProcessInfo.processInfo.environment["TEST_CONTAINER_ID"])
        let apiToken = try #require(ProcessInfo.processInfo.environment["TEST_API_TOKEN"])

        let command = QueryCommand(
            containerID: containerID,
            apiToken: apiToken,
            database: "public",
            limit: 5
        )

        let results = try await command.execute()

        // Just verify it doesn't crash
        #expect(results.count >= 0)
    }
}

extension Tag {
    @Tag static var endToEnd: Self
}
```

## CI Configuration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run unit tests
        run: swift test

  integration-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run integration tests
        run: swift test --filter IntegrationTests

  e2e-tests:
    runs-on: macos-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Run E2E tests
        env:
          CI_E2E_TESTS: "true"
          TEST_CONTAINER_ID: ${{ secrets.TEST_CONTAINER_ID }}
          TEST_API_TOKEN: ${{ secrets.TEST_API_TOKEN }}
        run: swift test --filter EndToEndTests
```

## Test Coverage

Target coverage goals:
- **Unit tests**: 90%+ coverage
- **Integration tests**: Cover all command workflows
- **E2E tests**: Cover critical paths only

## Related Documentation

- **[Swift Testing](../testing-enablinganddisabling.md)** - Swift Testing framework reference
- **[Error Handling](error-handling.md)** - Error scenarios to test
- **[ConfigKeyKit Strategy](configkeykit-strategy.md)** - Configuration testing patterns
