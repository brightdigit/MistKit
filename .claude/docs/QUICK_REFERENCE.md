# CloudKit Quick Reference for MistKit Development

## REST API Endpoints (webservices.md)

### Base URL Structure
```
https://api.apple-cloudkit.com/database/{version}/{container}/{environment}/{database}/{operation}
```

### Authentication

**API Token (User-based)**
```
Headers:
  X-Apple-CloudKit-Request-KeyID: [api-token]
  X-Apple-CloudKit-Request-ISO8601Date: [timestamp]
  X-Apple-CloudKit-Request-SignatureV1: [signature]
```

**Server-to-Server Key**
```
Headers:
  X-Apple-CloudKit-Request-KeyID: [key-id]
  X-Apple-CloudKit-Request-ISO8601Date: [timestamp]
  X-Apple-CloudKit-Request-SignatureV1: [signature]
Body: Included in signature
```

### Common Endpoints

| Operation | Path | Method |
|-----------|------|--------|
| Query Records | `/records/query` | POST |
| Modify Records | `/records/modify` | POST |
| Lookup Records | `/records/lookup` | POST |
| Record Changes | `/records/changes` | POST |
| List Zones | `/zones/list` | POST |
| Modify Zones | `/zones/modify` | POST |
| Current User | `/users/current` | GET |
| Upload Asset | `/assets/upload` | POST |

### Request Format (POST endpoints)
```json
{
  "operations": [
    {
      "operationType": "create",
      "record": {
        "recordType": "Article",
        "fields": {
          "title": {
            "value": "Hello World"
          }
        }
      }
    }
  ]
}
```

### Response Format
```json
{
  "records": [
    {
      "recordName": "unique-id",
      "recordType": "Article",
      "fields": {
        "title": {
          "value": "Hello World"
        }
      },
      "created": {
        "timestamp": 1234567890,
        "userRecordName": "_user-id"
      },
      "modified": {
        "timestamp": 1234567890,
        "userRecordName": "_user-id"
      },
      "recordChangeTag": "etag-value"
    }
  ]
}
```

### Error Response
```json
{
  "serverErrorCode": "INVALID_ARGUMENTS",
  "reason": "Detailed error message",
  "uuid": "request-id"
}
```

---

## CloudKit Field Types (webservices.md)

| Type | Description | Example |
|------|-------------|---------|
| `STRING` | Text string | `{"value": "Hello"}` |
| `INT64` | Integer | `{"value": 42}` |
| `DOUBLE` | Floating point | `{"value": 3.14}` |
| `BYTES` | Binary data | `{"value": "base64..."}` |
| `DATE` | Timestamp | `{"value": 1234567890000}` |
| `LOCATION` | Coordinates | `{"value": {"latitude": 37.7, "longitude": -122.4}}` |
| `REFERENCE` | Record ref | `{"value": {"recordName": "id", "action": "NONE"}}` |
| `ASSET` | File reference | `{"value": {"fileChecksum": "...", "size": 1024, "downloadURL": "..."}}` |
| `STRING_LIST` | Array of strings | `{"value": ["a", "b"]}` |
| `INT64_LIST` | Array of ints | `{"value": [1, 2, 3]}` |
| `DOUBLE_LIST` | Array of doubles | `{"value": [1.1, 2.2]}` |
| `DATE_LIST` | Array of dates | `{"value": [123, 456]}` |
| `LOCATION_LIST` | Array of locations | `{"value": [{"latitude": ...}, ...]}` |
| `REFERENCE_LIST` | Array of refs | `{"value": [{"recordName": "id1"}, ...]}` |

---

## Query Filters (cloudkitjs.md adapted)

### Filter Comparators
- `EQUALS`, `NOT_EQUALS`
- `LESS_THAN`, `LESS_THAN_OR_EQUALS`
- `GREATER_THAN`, `GREATER_THAN_OR_EQUALS`
- `IN`, `NOT_IN`
- `BEGINS_WITH`, `NOT_BEGINS_WITH`
- `CONTAINS_ALL_TOKENS`
- `LIST_CONTAINS`, `NOT_LIST_CONTAINS`

### Query Structure
```json
{
  "query": {
    "recordType": "Article",
    "filterBy": [
      {
        "comparator": "EQUALS",
        "fieldName": "status",
        "fieldValue": {"value": "published"}
      }
    ],
    "sortBy": [
      {
        "fieldName": "createdAt",
        "ascending": false
      }
    ]
  },
  "zoneID": {
    "zoneName": "_defaultZone"
  },
  "resultsLimit": 100
}
```

---

## Swift Testing Patterns (testing-enablinganddisabling.md)

### Basic Test
```swift
@Test("Description of what is tested")
func testFeature() async throws {
    let result = await someAsyncOperation()
    #expect(result == expectedValue)
}
```

### Parameterized Test
```swift
@Test("Validate multiple inputs", arguments: [1, 2, 3, 4, 5])
func testWithParameter(value: Int) {
    #expect(value > 0)
}
```

### Conditional Tests
```swift
@Test("Only run on macOS", .enabled(if: Platform.current == .macOS))
func macOSTest() { }

@Test("Skip when feature disabled", .disabled("Feature not ready"))
func disabledTest() { }
```

### Async Expectations
```swift
@Test func testAsync() async throws {
    let result = try await apiCall()
    #expect(result.status == .success)
    #expect(result.data != nil)
}
```

### Required Values (halts on nil)
```swift
@Test func testRequired() throws {
    let value = try #require(optionalValue)  // Stops if nil
    #expect(value.count > 0)
}
```

### Known Issues
```swift
@Test("Test with known bug", .bug(id: "12345"))
func testWithBug() {
    // Test that tracks a known issue
}
```

### Test Suites
```swift
@Suite("Feature X Tests")
struct FeatureXTests {
    @Test func testA() { }
    @Test func testB() { }
}
```

---

## MistKit Type Mapping

### CloudKit → Swift

| CloudKit Type | Swift Type |
|---------------|------------|
| `STRING` | `String` |
| `INT64` | `Int` |
| `DOUBLE` | `Double` |
| `BYTES` | `Data` |
| `DATE` | `Date` (milliseconds since epoch) |
| `LOCATION` | `CLLocationCoordinate2D` or custom struct |
| `REFERENCE` | Custom `CKReference` struct |
| `ASSET` | Custom `CKAsset` struct with URL |
| `*_LIST` | `[T]` arrays |

### Swift API Design Patterns

**Container Access**
```swift
let container = CloudKitService.container(identifier: "...")
let database = container.publicDatabase
```

**Record Operations**
```swift
// Create
let record = CKRecord(type: "Article")
record["title"] = "Hello"
try await database.save(record)

// Query
let query = CKQuery(recordType: "Article", predicate: ...)
let results = try await database.perform(query)

// Modify
record["title"] = "Updated"
try await database.save(record)
```

**Async Sequences for Pagination**
```swift
for try await record in database.records(matching: query) {
    process(record)
}
```

---

## Common Error Codes (webservices.md)

| Code | Meaning | Action |
|------|---------|--------|
| `AUTHENTICATION_REQUIRED` | Not authenticated | Obtain web auth token |
| `INVALID_ARGUMENTS` | Bad request data | Check request format |
| `NOT_FOUND` | Record doesn't exist | Handle gracefully |
| `CONFLICT` | Record changed | Resolve conflict |
| `ATOMIC_ERROR` | Batch partially failed | Check individual results |
| `ZONE_NOT_FOUND` | Zone doesn't exist | Create zone first |
| `THROTTLED` | Rate limited | Implement backoff |
| `INTERNAL_ERROR` | Server error | Retry with backoff |

---

## Authentication Flow

### User Authentication (API Token)
1. Call `/tokens/create` with API token
2. Receive `webAuthToken`
3. Include in subsequent requests
4. Token expires after 1 hour
5. Refresh before expiry

### Server-to-Server
1. Generate key pair
2. Upload public key to CloudKit Dashboard
3. Sign requests with private key
4. Include signature in headers

---

## Development Checklist

### Before implementing an endpoint:
- [ ] Check `webservices.md` for exact endpoint path and parameters
- [ ] Review `cloudkitjs.md` for operation semantics
- [ ] Design Swift types matching CloudKit structures
- [ ] Plan async/await API surface
- [ ] Consider error handling paths

### Before writing tests:
- [ ] Review `testing-enablinganddisabling.md` for patterns
- [ ] Use `@Test` macro, not XCTest
- [ ] Use `#expect()` and `#require()` for assertions
- [ ] Test async code with `async throws`
- [ ] Consider parameterized tests for multiple cases

### Code review:
- [ ] All types are `Sendable`
- [ ] All network calls use `async/await`
- [ ] Errors conform to `LocalizedError`
- [ ] Public APIs have tests
- [ ] Swift Testing patterns used correctly
