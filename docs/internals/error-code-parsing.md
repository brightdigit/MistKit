# Error Code Parsing

MistKit transforms CloudKit's HTTP error responses into strongly-typed Swift errors through a multi-stage pipeline that leverages the OpenAPI-generated types.

## CloudKit Error Response Format

CloudKit returns errors as JSON with a consistent structure:

```json
{
  "uuid": "a1b2c3d4-...",
  "serverErrorCode": "AUTHENTICATION_FAILED",
  "reason": "The request requires authentication."
}
```

The `serverErrorCode` is one of 14 defined values:

| Code | Meaning |
|------|---------|
| `ACCESS_DENIED` | User lacks permission |
| `ATOMIC_ERROR` | Atomic operation partially failed |
| `AUTHENTICATION_FAILED` | Invalid credentials |
| `AUTHENTICATION_REQUIRED` | No credentials provided |
| `BAD_REQUEST` | Malformed request |
| `CONFLICT` | Record version conflict |
| `EXISTS` | Record already exists |
| `INTERNAL_ERROR` | Server-side failure |
| `NOT_FOUND` | Record/zone not found |
| `QUOTA_EXCEEDED` | Storage/request quota hit |
| `THROTTLED` | Rate limited |
| `TRY_AGAIN_LATER` | Temporary server issue |
| `VALIDATING_REFERENCE_ERROR` | Reference integrity violation |
| `ZONE_NOT_FOUND` | Zone doesn't exist |

## OpenAPI Schema Definition

The `openapi.yaml` defines an `ErrorResponse` schema and maps it to HTTP status codes:

```yaml
ErrorResponse:
  properties:
    uuid: { type: string }
    serverErrorCode:
      type: string
      enum: [ACCESS_DENIED, ATOMIC_ERROR, AUTHENTICATION_FAILED, ...]
    reason: { type: string }
    redirectURL: { type: string }
```

Each HTTP status (400, 401, 403, 404, 409, 412, 413, 421, 429, 500, 503) gets its own response type referencing this schema.

## Generated Types

The Swift OpenAPI generator produces:

```swift
// The error code enum
internal enum serverErrorCodePayload: String, Codable, CaseIterable {
    case ACCESS_DENIED, ATOMIC_ERROR, AUTHENTICATION_FAILED, ...
}

// The error response struct
internal struct ErrorResponse: Codable {
    internal var uuid: String?
    internal var serverErrorCode: serverErrorCodePayload?
    internal var reason: String?
    internal var redirectURL: String?
}

// Per-status response wrappers
// Components.Responses.BadRequest, .Unauthorized, .Forbidden, etc.
```

Each operation's output is an enum with success and error cases:

```swift
enum Operations.queryRecords.Output {
    case ok(Operations.queryRecords.Output.Ok)
    case badRequest(Components.Responses.BadRequest)
    case unauthorized(Components.Responses.Unauthorized)
    case forbidden(Components.Responses.Forbidden)
    // ... all 11 error cases
    case undocumented(statusCode: Int, ...)
}
```

## CloudKitResponseType Protocol

A protocol provides unified error extraction across all operation outputs:

```swift
protocol CloudKitResponseType {
    var badRequestResponse: Components.Responses.BadRequest? { get }
    var unauthorizedResponse: Components.Responses.Unauthorized? { get }
    var forbiddenResponse: Components.Responses.Forbidden? { get }
    var notFoundResponse: Components.Responses.NotFound? { get }
    var conflictResponse: Components.Responses.Conflict? { get }
    // ... all 11 error statuses
    var isOk: Bool { get }
    var undocumentedStatusCode: Int? { get }
}
```

Each operation output implements this via pattern matching:

```swift
extension Operations.queryRecords.Output: CloudKitResponseType {
    var badRequestResponse: Components.Responses.BadRequest? {
        if case .badRequest(let response) = self { return response }
        return nil
    }
    // ... one property per error case
}
```

## The Public Error Type: `CloudKitError`

```swift
public enum CloudKitError: LocalizedError, Sendable {
    case httpError(statusCode: Int)
    // A CloudKit failure body that carried *no* serverErrorCode.
    case httpErrorWithDetails(statusCode: Int, reason: String?)
    case httpErrorWithRawResponse(statusCode: Int, rawResponse: String)

    // One case per documented serverErrorCode…
    case accessDenied(reason: String?)
    case atomicFailure(reason: String?)
    case authenticationFailed(reason: String?)
    case authenticationRequired(reason: String?)
    case badRequest(reason: String?)
    case conflict(reason: String?)
    case exists(reason: String?)
    case internalServerError(reason: String?)
    case notFound(reason: String?)
    case quotaExceeded(reason: String?, hint: QuotaHint?)
    case throttled(reason: String?)
    case tryAgainLater(reason: String?)
    case validatingReferenceError(reason: String?)
    case zoneNotFound(reason: String?)
    // …plus a forward-compatible catch-all for codes added later.
    case unknownServerError(code: String, statusCode: Int, reason: String?)

    case invalidResponse
    case underlyingError(any Error)
    case decodingError(DecodingError)
    case networkError(URLError)
}
```

Each of the 14 codes above gets its own case so callers pattern-match by intent
rather than string-matching a `serverErrorCode`. `unknownServerError` preserves
a code MistKit does not yet model, and `httpErrorWithDetails` is reserved for a
failure body that carried no code at all. `CloudKitError.serverErrorCode` reads
the raw string back off any of the coded cases for logging.

## The Parsing Pipeline

### Step 1: Extractor Array

`CloudKitError+OpenAPI.swift` defines an ordered list of extractors:

```swift
private static let errorExtractors: [(any CloudKitResponseType) -> CloudKitError?] = [
    { $0.badRequestResponse.map { CloudKitError(badRequest: $0) } },
    { $0.unauthorizedResponse.map { CloudKitError(unauthorized: $0) } },
    { $0.forbiddenResponse.map { CloudKitError(forbidden: $0) } },
    { $0.notFoundResponse.map { CloudKitError(notFound: $0) } },
    { $0.conflictResponse.map { CloudKitError(conflict: $0) } },
    // ... all 11 statuses
]
```

### Step 2: Generic Initializer

```swift
internal init?<T: CloudKitResponseType>(_ response: T) {
    if response.isOk { return nil }  // Not an error — return nil

    // Try each extractor until one matches
    for extractor in Self.errorExtractors {
        if let error = extractor(response) {
            self = error
            return
        }
    }

    // Undocumented status code fallback
    if let statusCode = response.undocumentedStatusCode {
        self = .httpError(statusCode: statusCode)
        return
    }

    self = .invalidResponse
}
```

### Step 3: Per-Status Initializers

Each status code has a private initializer that extracts the JSON body:

```swift
private init(badRequest response: Components.Responses.BadRequest) {
    if case .json(let errorResponse) = response.body {
        // Dispatches on the code: BAD_REQUEST → .badRequest, an unmodelled
        // code → .unknownServerError, no code → .httpErrorWithDetails.
        self.init(
            serverErrorCode: errorResponse.serverErrorCode?.rawValue,
            statusCode: 400,
            reason: errorResponse.reason
        )
    } else {
        self = .httpError(statusCode: 400)
    }
}
```

If the body isn't JSON (rare), it falls back to a plain `httpError` without details.

The code → case dispatch lives in one place,
`CloudKitError.init(serverErrorCode:statusCode:reason:)`
(`Sources/MistKit/CloudKitService/CloudKitError+ServerErrorCode.swift`), and its
inverse — case → code, documented HTTP status, and description summary — lives
next to it as `CloudKitError.serverErrorDetail`.

## Response Processing Pattern

`CloudKitResponseProcessor` applies the error-first pattern to every operation:

```swift
func processQueryResponse(_ response: Operations.queryRecords.Output)
    async throws(CloudKitError) -> [RecordInfo]
{
    // Error check FIRST
    if let error = CloudKitError(response) {
        throw error
    }

    // Only then extract the success payload
    switch response {
    case .ok(let okResponse):
        return try extractRecords(from: okResponse)
    default:
        throw CloudKitError.invalidResponse
    }
}
```

## Additional Error Mapping

`CloudKitService+ErrorHandling.swift` catches non-HTTP errors and wraps them:

```swift
func mapToCloudKitError(_ error: any Error) -> CloudKitError {
    switch error {
    case let cloudKitError as CloudKitError:
        return cloudKitError           // Already typed — pass through
    case let decodingError as DecodingError:
        return .decodingError(decodingError)
    case let urlError as URLError:
        return .networkError(urlError)
    default:
        return .underlyingError(error)
    }
}
```

## End-to-End Example

```
HTTP 400 Bad Request
{"serverErrorCode": "BAD_REQUEST", "reason": "Invalid filter"}
        │
        ▼
OpenAPI runtime deserializes to:
    Operations.queryRecords.Output.badRequest(Components.Responses.BadRequest)
        │
        ▼
CloudKitResponseProcessor calls: CloudKitError(response)
        │
        ▼
Generic initializer: response.isOk == false
    → tries errorExtractors[0]: badRequestResponse != nil ✓
        │
        ▼
Private init(badRequest:): extracts JSON body, dispatches on the code
    → .badRequest(reason: "Invalid filter")
        │
        ▼
Thrown as CloudKitError — caller can switch on case
    or display via .errorDescription:
    "CloudKit API error: HTTP 400\nServer Error Code: BAD_REQUEST\nReason: Invalid filter"
```
