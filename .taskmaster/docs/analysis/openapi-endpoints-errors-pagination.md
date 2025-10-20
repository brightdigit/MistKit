# OpenAPI Endpoint Modeling, Error Responses, and Pagination Patterns

## Overview

This document analyzes the endpoint structure, error handling, and pagination patterns in the MistKit OpenAPI specification. It demonstrates how CloudKit's REST API operations were organized and modeled using OpenAPI 3.0.3 conventions.

## Endpoint Organization and Structure

### Endpoint Grouping by Resource Type

The API is organized into logical resource groups using OpenAPI tags:

1. **Records** - Core data operations
2. **Zones** - Custom zone management
3. **Subscriptions** - Push notification subscriptions
4. **Users** - User identity and discovery
5. **Assets** - Binary file handling
6. **Tokens** - APNs token management

### URL Structure Pattern

All endpoints follow CloudKit's consistent URL pattern:

```
https://api.apple-cloudkit.com/database/{version}/{container}/{environment}/{database}/{operation}
```

**Path Parameters:**
- `version`: API version (currently "1")
- `container`: Container identifier (e.g., "iCloud.com.example.app")
- `environment`: "development" or "production"
- `database`: "public", "private", or "shared"
- `operation`: Specific operation endpoint

**Design Rationale:**
- Path-based routing enables clear resource hierarchy
- Environment and database scoping at the URL level
- Version parameter supports future API evolution
- Container isolation for multi-tenant architecture

## Records Endpoints

### 1. Query Records

**Location:** `openapi.yaml:34-108`

```yaml
/database/{version}/{container}/{environment}/{database}/records/query:
  post:
    operationId: queryRecords
    tags: [Records]
```

**Request Body Structure:**
```yaml
zoneID: ZoneID           # Optional zone scoping
resultsLimit: integer    # Max records to return
query:
  recordType: string     # Required record type
  filterBy: [Filter]     # Optional filters
  sortBy: [Sort]         # Optional sorting
desiredKeys: [string]    # Optional field selection
continuationMarker: string  # Pagination support
```

**Key Design Decisions:**

1. **POST for Query:** Uses POST instead of GET to support complex query bodies
2. **Flexible Filtering:** Array of Filter objects enables complex queries
3. **Field Selection:** `desiredKeys` allows clients to request specific fields
4. **Zone Scoping:** Optional `zoneID` for custom zone queries
5. **Pagination:** Built-in continuation marker support

**Rationale:** POST method appropriate for complex query parameters that exceed URL length limits. JSON body provides better structure than query strings.

### 2. Modify Records

**Location:** `openapi.yaml:110-164`

```yaml
/database/{version}/{container}/{environment}/{database}/records/modify:
  post:
    operationId: modifyRecords
```

**Request Body Structure:**
```yaml
operations: [RecordOperation]  # Array of operations
atomic: boolean                # Transaction mode
```

**RecordOperation Schema:**
```yaml
operationType: enum
  - create
  - update
  - forceUpdate
  - replace
  - forceReplace
  - delete
  - forceDelete
record: Record
```

**Key Design Decisions:**

1. **Batch Operations:** Single endpoint handles create/update/delete operations
2. **Operation Types:** Explicit operation type enum for different behaviors
   - `update` vs `forceUpdate`: Optimistic concurrency vs forced write
   - `replace` vs `forceReplace`: Full replacement semantics
3. **Atomic Transactions:** `atomic` flag for all-or-nothing behavior
4. **Bulk Support:** Array of operations enables efficient batch processing

**Benefits:**
- Reduces network round-trips
- Supports transactional updates
- Consistent error handling for all operation types

### 3. Lookup Records

**Location:** `openapi.yaml:166-224`

```yaml
/database/{version}/{container}/{environment}/{database}/records/lookup:
  post:
    operationId: lookupRecords
```

**Request Body Structure:**
```yaml
records: array
  - recordName: string
    desiredKeys: [string]
```

**Key Design Decisions:**

1. **Batch Lookup:** Fetch multiple records by ID in single request
2. **Per-Record Field Selection:** Each record can specify different desired keys
3. **POST Method:** Allows unlimited record IDs (vs GET URL length limits)

### 4. Fetch Record Changes

**Location:** `openapi.yaml:226-280`

```yaml
/database/{version}/{container}/{environment}/{database}/records/changes:
  post:
    operationId: fetchRecordChanges
```

**Request Body Structure:**
```yaml
zoneID: ZoneID
syncToken: string        # Token from previous sync
resultsLimit: integer
```

**Response Structure:**
```yaml
records: [Record]
syncToken: string        # New token for next sync
moreComing: boolean      # More results available
```

**Key Design Decisions:**

1. **Sync Token Pattern:** Enables incremental syncing
2. **Zone-Scoped:** Changes tracked per zone
3. **More Coming Flag:** Indicates pagination state
4. **New Sync Token:** Always returned for next iteration

**Sync Workflow:**
1. Initial call with no sync token gets all records
2. Response includes new sync token
3. Subsequent calls use that token to get only changes
4. Process continues until `moreComing` is false

## Zones Endpoints

### Zone Operations Pattern

All zone endpoints follow consistent CRUD patterns:

1. **List Zones** (GET) - Retrieve all zones
2. **Lookup Zones** (POST) - Fetch specific zones by ID
3. **Modify Zones** (POST) - Create/delete zones
4. **Fetch Zone Changes** (POST) - Incremental zone sync

**Key Differences from Records:**

- **List Operation:** Zones have a list endpoint (GET), records use query (POST)
- **No Update:** Zones can only be created or deleted, not updated
- **Private Database Only:** Zone modification only works in private database

**Location:** `openapi.yaml:282-427`

### Meta-Sync Pattern for Zones

**Location:** `openapi.yaml:394-427`

```yaml
/zones/changes:
  request:
    syncToken: string    # Meta-sync token
  response:
    zones: [Zone]
    syncToken: string    # New meta-sync token
```

**Design Rationale:**

- **Meta-Sync vs Record-Sync:** Tracks zone metadata changes separately
- **Two-Level Sync:** First sync zones, then sync records within each zone
- **Efficient Updates:** Only fetch record changes for modified zones

## Subscriptions Endpoints

**Location:** `openapi.yaml:428-523`

Subscriptions follow the same CRUD pattern as zones:
- List (GET)
- Lookup (POST)
- Modify (POST)

**Subscription Schema:**
```yaml
subscriptionID: string
subscriptionType: enum [query, zone]
query: object           # For query subscriptions
zoneID: ZoneID         # For zone subscriptions
firesOn: enum          # [create, update, delete]
```

**Key Design Decisions:**

1. **Two Subscription Types:** Query-based and zone-based subscriptions
2. **Event Filtering:** `firesOn` array controls which operations trigger notifications
3. **Flexible Matching:** Query subscriptions use same filter syntax as record queries

## Users Endpoints

**Location:** `openapi.yaml:525-641`

### 1. Get Current User (GET)

Simple authenticated endpoint returning current user info.

### 2. Discover User Identities (POST)

```yaml
request:
  users: array
    - emailAddress: string
    - userRecordName: string
```

**Design Rationale:**

- **Privacy-Aware:** Discovery requires opt-in from target users
- **Batch Discovery:** Array input for efficient lookups
- **Flexible Matching:** Email or record name based lookup

### 3. Lookup Contacts (POST) - Deprecated

Marked as deprecated in the spec using OpenAPI's `deprecated: true` property.

## Assets Endpoint

**Location:** `openapi.yaml:643-675`

```yaml
/database/{version}/{container}/{environment}/{database}/assets/upload:
  post:
    requestBody:
      content:
        multipart/form-data:
          schema:
            properties:
              file:
                type: string
                format: binary
```

**Key Design Decisions:**

1. **Multipart Form Data:** Standard for binary file uploads
2. **Binary Format:** OpenAPI `format: binary` indicates file content
3. **Separate from Records:** Asset upload separate from record modification
4. **Token-Based Flow:** Response contains tokens to link assets to records

**Asset Upload Workflow:**
1. Upload asset file to `/assets/upload`
2. Receive asset token in response
3. Include token in record field when creating/modifying record

## Tokens Endpoints

**Location:** `openapi.yaml:677-739`

### 1. Create APNs Token

```yaml
request:
  apnsEnvironment: enum [development, production]
response:
  apnsToken: string
  webcAuthToken: string
```

### 2. Register Token

```yaml
request:
  apnsToken: string
```

**Design Rationale:**

- **Separate Creation/Registration:** Two-step process for push notifications
- **Environment Awareness:** Different tokens for dev vs production
- **Web Auth Token:** Additional token for web-based clients

## Comprehensive Error Response Modeling

### Error Response Schema

**Location:** `openapi.yaml:1187-1230`

```yaml
ErrorResponse:
  type: object
  properties:
    uuid:
      type: string
      description: Unique error identifier for support
    serverErrorCode:
      type: string
      enum:
        - ACCESS_DENIED
        - ATOMIC_ERROR
        - AUTHENTICATION_FAILED
        - AUTHENTICATION_REQUIRED
        - BAD_REQUEST
        - CONFLICT
        - EXISTS
        - INTERNAL_ERROR
        - NOT_FOUND
        - QUOTA_EXCEEDED
        - THROTTLED
        - TRY_AGAIN_LATER
        - VALIDATING_REFERENCE_ERROR
        - ZONE_NOT_FOUND
    reason:
      type: string
      description: Human-readable error description
    redirectURL:
      type: string
      description: Redirect location for authentication
```

**Key Design Elements:**

1. **UUID for Tracking:** Unique identifier enables support ticket correlation
2. **Structured Error Codes:** Enum of CloudKit-specific error codes
3. **Human-Readable Reason:** Descriptive message for debugging
4. **Redirect Support:** Authentication flows can redirect

### HTTP Status Code Mapping

**Location:** `openapi.yaml:1232-1298`

Comprehensive mapping of HTTP status codes to CloudKit errors:

#### 400 Bad Request

**Location:** `openapi.yaml:1233-1238`

```yaml
BadRequest:
  description: Bad request (400) - BAD_REQUEST, ATOMIC_ERROR
  content:
    application/json:
      schema:
        $ref: '#/components/schemas/ErrorResponse'
```

**CloudKit Error Codes:**
- `BAD_REQUEST`: Invalid request parameters
- `ATOMIC_ERROR`: Atomic transaction failed

**Client Action:** Fix request parameters or retry non-atomically

#### 401 Unauthorized

**Location:** `openapi.yaml:1239-1244`

```yaml
Unauthorized:
  description: Unauthorized (401) - AUTHENTICATION_FAILED
```

**CloudKit Error Code:** `AUTHENTICATION_FAILED`

**Client Action:** Re-authenticate or check credentials

#### 403 Forbidden

**Location:** `openapi.yaml:1245-1250`

```yaml
Forbidden:
  description: Forbidden (403) - ACCESS_DENIED
```

**CloudKit Error Code:** `ACCESS_DENIED`

**Client Action:** User lacks permissions for this operation

#### 404 Not Found

**Location:** `openapi.yaml:1251-1256`

```yaml
NotFound:
  description: Not found (404) - NOT_FOUND, ZONE_NOT_FOUND
```

**CloudKit Error Codes:**
- `NOT_FOUND`: Record or resource doesn't exist
- `ZONE_NOT_FOUND`: Specified zone doesn't exist

**Client Action:** Verify resource exists before accessing

#### 409 Conflict

**Location:** `openapi.yaml:1257-1262`

```yaml
Conflict:
  description: Conflict (409) - CONFLICT, EXISTS
```

**CloudKit Error Codes:**
- `CONFLICT`: Record change tag mismatch (optimistic locking)
- `EXISTS`: Resource already exists

**Client Action:** Fetch latest version and retry, or use force operations

#### 412 Precondition Failed

**Location:** `openapi.yaml:1263-1268`

```yaml
PreconditionFailed:
  description: Precondition failed (412) - VALIDATING_REFERENCE_ERROR
```

**CloudKit Error Code:** `VALIDATING_REFERENCE_ERROR`

**Client Action:** Referenced record doesn't exist or is invalid

#### 413 Request Entity Too Large

**Location:** `openapi.yaml:1269-1274`

```yaml
RequestEntityTooLarge:
  description: Request entity too large (413) - QUOTA_EXCEEDED
```

**CloudKit Error Code:** `QUOTA_EXCEEDED`

**Client Action:** Reduce request size or upgrade storage quota

#### 429 Too Many Requests

**Location:** `openapi.yaml:1275-1280`

```yaml
TooManyRequests:
  description: Too many requests (429) - THROTTLED
```

**CloudKit Error Code:** `THROTTLED`

**Client Action:** Implement exponential backoff retry

#### 421 Unprocessable Entity

**Location:** `openapi.yaml:1281-1286`

```yaml
UnprocessableEntity:
  description: Unprocessable entity (421) - AUTHENTICATION_REQUIRED
```

**CloudKit Error Code:** `AUTHENTICATION_REQUIRED`

**Client Action:** Additional authentication steps needed

#### 500 Internal Server Error

**Location:** `openapi.yaml:1287-1292`

```yaml
InternalServerError:
  description: Internal server error (500) - INTERNAL_ERROR
```

**CloudKit Error Code:** `INTERNAL_ERROR`

**Client Action:** Retry with exponential backoff

#### 503 Service Unavailable

**Location:** `openapi.yaml:1293-1298`

```yaml
ServiceUnavailable:
  description: Service unavailable (503) - TRY_AGAIN_LATER
```

**CloudKit Error Code:** `TRY_AGAIN_LATER`

**Client Action:** Temporary service issue, retry later

### Error Response Reusability

All error responses are defined once in `components/responses` and referenced throughout:

```yaml
responses:
  '400':
    $ref: '#/components/responses/BadRequest'
  '401':
    $ref: '#/components/responses/Unauthorized'
  # ... etc
```

**Benefits:**
1. **DRY Principle:** Define once, reference everywhere
2. **Consistency:** All endpoints use same error format
3. **Maintainability:** Update error responses in one place
4. **Documentation:** Self-documenting error scenarios

## Pagination Patterns

CloudKit uses two distinct pagination patterns depending on the operation type:

### Pattern 1: Continuation Marker (Query Operations)

**Location:** `openapi.yaml:1019-1027`

Used for: Records Query

```yaml
# Request
POST /records/query
{
  "query": { ... },
  "resultsLimit": 100,
  "continuationMarker": "optional-token-from-previous-response"
}

# Response
{
  "records": [...],
  "continuationMarker": "token-for-next-page"
}
```

**Design Characteristics:**

1. **Opaque Token:** Continuation marker is an opaque string
2. **Stateful Server:** Server maintains query cursor
3. **Optional Limit:** Client controls page size
4. **Presence Indicates More:** If present in response, more results available

**Implementation Pattern:**
```swift
var allRecords: [Record] = []
var continuationMarker: String? = nil

repeat {
    let response = try await queryRecords(
        query: query,
        continuationMarker: continuationMarker
    )
    allRecords.append(contentsOf: response.records)
    continuationMarker = response.continuationMarker
} while continuationMarker != nil
```

### Pattern 2: Sync Token (Change Operations)

**Location:** `openapi.yaml:1045-1055`

Used for: Record Changes, Zone Changes

```yaml
# Request
POST /records/changes
{
  "zoneID": { ... },
  "syncToken": "token-from-previous-sync",
  "resultsLimit": 100
}

# Response
{
  "records": [...],
  "syncToken": "new-token-for-next-sync",
  "moreComing": false
}
```

**Design Characteristics:**

1. **Incremental Sync:** Token represents "changes since this point"
2. **Persistent Token:** Client stores token between sessions
3. **moreComing Flag:** Explicit indicator of pagination state
4. **Always Returns Token:** New token even if no changes

**Two-Phase Pagination:**

1. **Catch-up Phase:** `moreComing: true` means more historical changes available
2. **Caught-up Phase:** `moreComing: false` means current with all changes

**Implementation Pattern:**
```swift
var syncToken: String? = loadPersistedToken()
var allChanges: [Record] = []

repeat {
    let response = try await fetchRecordChanges(
        zoneID: zoneID,
        syncToken: syncToken
    )
    allChanges.append(contentsOf: response.records)
    syncToken = response.syncToken

    // Persist token for next app launch
    persistToken(syncToken)
} while response.moreComing

// Now caught up with all changes
```

### Pagination Design Rationale

**Why Two Patterns?**

1. **Query Operations (Continuation Marker):**
   - Results may change between pages
   - Query can be re-executed differently
   - Marker is temporary, session-bound

2. **Sync Operations (Sync Token):**
   - Results are historical, immutable
   - Token represents timeline position
   - Token is persistent, long-lived
   - Enables offline-first sync

**Benefits:**

- **Efficient Syncing:** Only fetch changes since last sync
- **Reliable Queries:** Stable pagination cursors
- **Client Control:** Results limit lets client manage memory
- **Clear State:** `moreComing` flag removes ambiguity

## REST API Modeling Benefits

### Simplification Through Standard Patterns

**Before:** CloudKit's operations were documented as RPC-style endpoints

**After:** RESTful resource-oriented operations with standard HTTP methods

**Improvements:**

1. **Predictable URLs:** Resource hierarchy clear from URL structure
2. **HTTP Semantics:** GET for reads, POST for modifications
3. **Batch Operations:** Array-based payloads for efficiency
4. **Standard Error Codes:** HTTP status codes + CloudKit error codes

### Endpoint Naming Conventions

Consistent verb-noun patterns:
- `query` → Search/filter operations
- `lookup` → Fetch by ID
- `modify` → Create/update/delete
- `list` → Retrieve all
- `changes` → Incremental updates

## Summary

The OpenAPI specification successfully models CloudKit's REST API with:

### Endpoint Organization
- Logical resource grouping (Records, Zones, Users, etc.)
- Consistent URL patterns with path parameters
- RESTful HTTP method usage
- Batch operation support

### Error Handling
- Comprehensive HTTP status code mapping
- CloudKit-specific error code enums
- Structured error response with UUID tracking
- Reusable error response components

### Pagination
- Continuation marker for query operations
- Sync token for change tracking
- Clear pagination state indicators
- Client-controlled page sizes

### Design Benefits
- Type-safe code generation
- Self-documenting API structure
- Consistent patterns across all endpoints
- Efficient batch and sync operations

The specification provides everything needed for `swift-openapi-generator` to create a robust, type-safe Swift client for CloudKit Web Services.
