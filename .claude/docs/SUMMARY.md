# Documentation Summary

## Overview

This directory contains three comprehensive Apple documentation files for MistKit development:

1. **webservices.md** (289 KB) - CloudKit Web Services REST API Reference
2. **cloudkitjs.md** (188 KB) - CloudKit JS Framework Documentation
3. **testing-enablinganddisabling.md** (126 KB) - Swift Testing Framework Guide

---

## webservices.md - CloudKit Web Services REST API

**Source**: Apple's CloudKit Web Services Reference (Archived Documentation)

### What It Covers

#### Authentication & Security
- **API Token Authentication**: For web/client apps requiring user authentication
  - Creating API tokens in CloudKit Dashboard
  - Generating web authentication tokens
  - Token lifecycle and refresh patterns
  - Request signing with HMAC-SHA256

- **Server-to-Server Keys**: For backend/admin operations
  - Certificate generation and key management
  - Request authentication flow
  - Signature computation

#### Request Composition
- Base URL structure: `https://api.apple-cloudkit.com/database/1/{container}/{env}/{db}/{operation}`
- HTTP methods and headers
- Request body formats
- Response structures
- Error handling

#### Core Endpoints

**Records API**
- `POST /records/query` - Query records with filters and sorting
- `POST /records/modify` - Create, update, replace, delete records (batch)
- `POST /records/lookup` - Fetch specific records by ID
- `POST /records/changes` - Fetch incremental changes

**Zones API**
- `POST /zones/list` - List all zones
- `POST /zones/lookup` - Fetch specific zones
- `POST /zones/modify` - Create, update, delete zones
- `POST /zones/changes` - Fetch zone changes

**Subscriptions API**
- `POST /subscriptions/list` - List all subscriptions
- `POST /subscriptions/lookup` - Fetch specific subscriptions
- `POST /subscriptions/modify` - Create, update, delete subscriptions

**Users API**
- `GET /users/current` - Get current authenticated user
- `POST /users/discover` - Discover users by email/phone
- `POST /users/lookup/contacts` - Lookup users from contacts
- `POST /users/lookup/email` - Lookup by email address
- `POST /users/lookup/phone` - Lookup by phone number

**Assets API**
- `POST /assets/upload` - Upload binary assets
- Asset download URLs in record responses

**Tokens API**
- `POST /tokens/create` - Create web auth token
- `POST /tokens/register` - Register for push notifications

#### Data Types & Field Types

**Basic Types**
- `STRING`, `INT64`, `DOUBLE`, `BYTES`, `DATE`

**Complex Types**
- `LOCATION` - Latitude/longitude coordinates
- `REFERENCE` - References to other records (with delete actions)
- `ASSET` - File attachments with metadata

**List Types**
- `STRING_LIST`, `INT64_LIST`, `DOUBLE_LIST`, `DATE_LIST`
- `LOCATION_LIST`, `REFERENCE_LIST`

#### Error Handling
- Error response format
- Common error codes:
  - `AUTHENTICATION_REQUIRED`
  - `INVALID_ARGUMENTS`
  - `NOT_FOUND`
  - `CONFLICT` (for record changes)
  - `ATOMIC_ERROR` (for batch operations)
  - `ZONE_NOT_FOUND`
  - `THROTTLED`
  - `INTERNAL_ERROR`

### Key Implementation Patterns

1. **Batch Operations**: All modify operations support atomic batches
2. **Change Tracking**: Server sync tokens for incremental updates
3. **Conflict Resolution**: Record change tags (ETags) for optimistic locking
4. **Pagination**: Continuation markers for large result sets

---

## cloudkitjs.md - CloudKit JS Framework

**Source**: Apple's CloudKit JS Documentation (Current)

### What It Covers

#### Configuration & Setup
- Embedding CloudKit JS in web pages
- Container configuration with API tokens
- Environment selection (development/production)
- Authentication flows

#### Core Classes

**CloudKit Namespace**
- Configuration methods
- Global constants and enumerations
- Container access

**CloudKit.Container**
- `publicCloudDatabase` - Access public database
- `privateCloudDatabase` - Access private database (requires auth)
- `sharedCloudDatabase` - Access shared database
- User authentication methods
- User discovery operations
- Share acceptance

**CloudKit.Database**
- **Record Operations**:
  - `saveRecords()` - Save/update records
  - `fetchRecords()` - Fetch by record IDs
  - `deleteRecords()` - Delete records
  - `performQuery()` - Query with filters
  - `newRecordsBatch()` - Batch builder

- **Zone Operations**:
  - `fetchAllRecordZones()` - List all zones
  - `fetchRecordZones()` - Fetch specific zones
  - `saveRecordZones()` - Create/update zones
  - `deleteRecordZones()` - Delete zones

- **Subscription Operations**:
  - `fetchAllSubscriptions()` - List subscriptions
  - `fetchSubscriptions()` - Fetch specific subscriptions
  - `saveSubscriptions()` - Create/update subscriptions
  - `deleteSubscriptions()` - Delete subscriptions

- **Change Tracking**:
  - `fetchDatabaseChanges()` - Database-level changes
  - `fetchRecordZoneChanges()` - Zone-level changes

#### Query System

**Filter Comparators**
- Equality: `EQUALS`, `NOT_EQUALS`
- Comparison: `LESS_THAN`, `GREATER_THAN`, etc.
- String: `BEGINS_WITH`, `CONTAINS_ALL_TOKENS`
- List: `IN`, `LIST_CONTAINS`

**Sort Descriptors**
- Field name
- Ascending/descending order

**Pagination**
- `resultsLimit` for page size
- `continuationMarker` for next page

#### Response Objects

**CloudKit.Response** (base class)
- `isSuccess` - Operation status
- `hasErrors` - Error indication

**CloudKit.RecordsResponse**
- `records` - Array of fetched records
- `errors` - Array of errors (by record)

**CloudKit.QueryResponse**
- `records` - Query results
- `moreComing` - Has more pages
- `continuationMarker` - Token for next page

**CloudKit.RecordsBatchBuilder**
- Fluent API for batch operations
- `create()`, `update()`, `replace()`, `delete()`
- `commit()` to execute

**CloudKit.DatabaseChangesResponse**
- Changed zones since sync token
- New sync token

**CloudKit.RecordZoneChangesResponse**
- Changed records in zones
- Deleted record IDs
- New sync tokens per zone

#### Notification Types

**CloudKit.Notification** (base)
- Notification ID and type
- Subscription ID

**CloudKit.QueryNotification**
- Record change details
- Query subscription results

**CloudKit.RecordZoneNotification**
- Zone change notifications

#### Error Handling

**CloudKit.CKError**
- `ckErrorCode` - CloudKit error code
- `isServerError` - Server vs client error
- `serverErrorCode` - Detailed server error
- Retry suggestions

### Key Concepts

1. **Databases**: Public (unauthenticated), Private (user), Shared (shared with user)
2. **Zones**: Logical groupings in private/shared databases (default zone always exists)
3. **Subscriptions**: Push notifications for record/zone changes
4. **Change Tracking**: Sync tokens for efficient synchronization
5. **Sharing**: Records can be shared between users

---

## testing-enablinganddisabling.md - Swift Testing Framework

**Source**: Apple's Swift Testing Documentation (Swift 6.0+)

### What It Covers

#### Test Definition

**@Test Macro**
```swift
@Test("Display name")
func testFunction() async throws { }
```
- No naming conventions required
- Can be defined anywhere (not just in classes)
- Supports async/await and throwing
- Can have custom display names

**@Suite Macro**
```swift
@Suite("Feature Tests")
struct FeatureTests {
    @Test func testA() { }
    @Test func testB() { }
}
```
- Groups related tests
- Uses Swift's type system
- Can nest suites
- Shares setup/teardown

#### Test Traits

**Conditional Execution**
- `.enabled(if: condition)` - Run only if true
- `.disabled()` - Never run
- `.disabled(if: condition)` - Skip if true
- `.disabled("Reason")` - Skip with explanation

**Time Limits**
- `.timeLimit(.seconds(10))` - Fail if exceeds duration
- `.timeLimit(.minutes(1))`

**Tags**
- `.tags(.critical)` - Categorize tests
- `.tags(.slow, .integration)` - Multiple tags
- Run specific tags from command line

**Bug Tracking**
- `.bug("URL")` - Link to bug report
- `.bug(id: "12345")` - Bug number
- Associates tests with known issues

**Parallelization**
- `.serialized` - Force serial execution
- Default is parallel in-process

#### Test Parameterization

**Single Collection**
```swift
@Test(arguments: [1, 2, 3, 4, 5])
func validate(value: Int) { }
```

**Multiple Collections**
```swift
@Test(arguments: ["a", "b"], [1, 2])
func combine(letter: String, number: Int) { }
```

**Zipped Collections**
```swift
@Test(arguments: zip(["a", "b"], [1, 2]))
func paired(letter: String, number: Int) { }
```

**Custom Arguments**
```swift
struct TestCase: CustomTestStringConvertible {
    let input: String
    let expected: Int
}

@Test(arguments: [
    TestCase(input: "hello", expected: 5),
    TestCase(input: "world", expected: 5)
])
func validate(testCase: TestCase) { }
```

#### Expectations

**#expect() - Continue on failure**
```swift
#expect(value == expected)
#expect(array.count > 0)
#expect(string.contains("test"))
```

**#require() - Stop on failure**
```swift
let value = try #require(optionalValue)  // Stops if nil
#expect(value.isValid)
```

**Error Checking**
```swift
#expect(throws: MyError.invalid) {
    try someOperation()
}
```

**Async Expectations**
```swift
await #expect {
    try await asyncOperation()
    return true
}
```

#### Migration from XCTest

| XCTest | Swift Testing |
|--------|---------------|
| `class XCTestCase` | `@Suite struct` or `@Test func` |
| `func testFoo()` | `@Test func foo()` |
| `setUp()` | `init()` |
| `tearDown()` | `deinit` |
| `setUpWithError()` | `init() throws` |
| `tearDownWithError()` | N/A (use defer) |
| `XCTAssertEqual` | `#expect(a == b)` |
| `XCTAssertTrue` | `#expect(value)` |
| `XCTAssertNil` | `#expect(value == nil)` |
| `XCTUnwrap` | `try #require(value)` |
| `XCTAssertThrowsError` | `#expect(throws:)` |
| `addTeardownBlock` | `defer { }` |
| `continueAfterFailure` | `#expect()` (always continues) |

#### Running Tests

**Swift Package Manager**
```bash
swift test                      # Run all
swift test --filter TestName    # Run specific
swift test --parallel           # Parallel execution
```

**Xcode**
- Test navigator shows all `@Test` functions
- Run button next to each test
- Test report shows parameterized cases

---

## How to Use These Docs Together

### Implementing a Feature

1. **Design Phase**
   - Read `cloudkitjs.md` to understand operation semantics
   - Check `webservices.md` for exact REST endpoint details
   - Plan Swift API surface

2. **Implementation Phase**
   - Use `webservices.md` for request/response formats
   - Map CloudKit types to Swift types
   - Implement async/await patterns
   - Add error handling

3. **Testing Phase**
   - Use `testing-enablinganddisabling.md` for test patterns
   - Write parameterized tests for edge cases
   - Test async operations
   - Handle error paths

### Example: Implementing Record Query

1. **cloudkitjs.md** → Understand `Database.performQuery()` operation
2. **webservices.md** → Get exact POST `/records/query` format
3. Implement Swift async function
4. **testing-enablinganddisabling.md** → Write parameterized tests

---

## Quick Navigation

- **Need endpoint details?** → `webservices.md`
- **Need CloudKit concepts?** → `cloudkitjs.md`
- **Need test patterns?** → `testing-enablinganddisabling.md`
- **Need quick reference?** → `QUICK_REFERENCE.md`
- **Need integration guide?** → `README.md`
