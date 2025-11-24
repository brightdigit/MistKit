# Documentation-to-OpenAPI Transformation Examples

## Overview

This document demonstrates how Apple's CloudKit Web Services prose documentation was transformed into structured, machine-readable OpenAPI 3.0.3 specifications. Through before/after comparisons, we show the translation process, decision-making rationale, and improvements achieved.

## Example 1: Record Structure

### Before: Apple's Prose Documentation

From Apple's CloudKit Web Services Reference:

> **Creating Records**
>
> To create a single record in the specified database, use the `create` operation type.
>
> 1. Create an operation dictionary with these key-value pairs:
>    1. Set the `operationType` key to `create`.
>    2. Set the `record` key to a record dictionary describing the new record.
> 2. Create a record dictionary with these key-value pairs:
>    1. Set the `recordType` key to the record's type.
>    2. Set the `recordName` key to the record's name. If you don't provide a record name, CloudKit assigns one for you.
>    3. Set the `fields` key to a dictionary of key-value pairs used to set the record's fields, as described in Record Field Dictionary.
>
> For example, this operation dictionary creates an `Artist` record with the first name "Mei" and last name "Chen":
>
> ```json
> {
>   "operationType": "create",
>   "record": {
>     "recordType": "Artist",
>     "fields": {
>       "firstName": {"value": "Mei"},
>       "lastName": {"value": "Chen"}
>     },
>     "recordName": "Mei Chen"
>   }
> }
> ```

### After: OpenAPI Specification

```yaml
components:
  schemas:
    Record:
      type: object
      properties:
        recordName:
          type: string
          description: The unique identifier for the record
        recordType:
          type: string
          description: The record type (schema name)
        recordChangeTag:
          type: string
          description: Change tag for optimistic concurrency control
        fields:
          type: object
          description: Record fields with their values and types
          additionalProperties:
            $ref: '#/components/schemas/FieldValue'

    RecordOperation:
      type: object
      properties:
        operationType:
          type: string
          enum: [create, update, forceUpdate, replace, forceReplace, delete, forceDelete]
        record:
          $ref: '#/components/schemas/Record'
```

### Translation Decisions

1. **From Prose to Structure**: Converted numbered steps into structured schema definitions
2. **Type Safety**: Added `enum` for operation types to prevent invalid values
3. **Reusability**: Created separate `Record` and `RecordOperation` schemas that can be referenced
4. **Documentation**: Preserved descriptions while making them machine-readable
5. **Dynamic Fields**: Used `additionalProperties` to allow any field name while maintaining type safety for field values

### Improvements Achieved

| Aspect | Apple's Documentation | OpenAPI Specification |
|--------|----------------------|----------------------|
| **Machine-Readable** | No - requires human interpretation | Yes - parseable by code generators |
| **Type Safety** | Implicit - examples only | Explicit - enums and schemas |
| **Validation** | Manual - developer must verify | Automatic - OpenAPI validators |
| **Code Generation** | Not possible | `swift-openapi-generator` creates Swift types |
| **Consistency** | Examples may vary | Schema enforces consistency |

## Example 2: Authentication

### Before: Apple's Prose Documentation

> **Accessing CloudKit Using an API Token**
>
> To access a container as a user, append this subpath to the end of the web service URL. Provide an API token you created using CloudKit Dashboard and optionally, a web token to authenticate the user.
>
> `?ckAPIToken=[API token]&ckWebAuthToken=[Web Auth Token]`
>
> **API token**: An API token allowing access to the container. The `ckAPIToken` key is required.
>
> **Web Auth Token**: The identifier of an authenticated user. The `ckWebAuthToken` key is optional, but if omitted and required, the request fails.
>
> **Accessing CloudKit Using a Server-to-Server Key**
>
> Use a server-to-server key to access the public database of a container as the developer who created the key. You pass the key ID as `X-Apple-CloudKit-Request-KeyID` header.

### After: OpenAPI Specification

```yaml
components:
  securitySchemes:
    ApiTokenAuth:
      type: apiKey
      in: query
      name: ckAPIToken
      description: API token created using CloudKit Dashboard
    ServerToServerAuth:
      type: apiKey
      in: header
      name: X-Apple-CloudKit-Request-KeyID
      description: Key ID for server-to-server authentication

security:
  - ApiTokenAuth: []
  - ServerToServerAuth: []
```

### Translation Decisions

1. **Standard Security Schemes**: Used OpenAPI's `securitySchemes` component
2. **Query vs Header**: Properly distinguished between query parameter and header-based auth
3. **Alternative Authentication**: Made both methods available at root level
4. **Clear Naming**: Mapped CloudKit's naming to OpenAPI conventions

### Improvements Achieved

- **Automatic Header Injection**: Code generators automatically add auth headers/params
- **Documentation Generation**: API docs show authentication requirements clearly
- **Client Configuration**: Generated clients include authentication setup
- **Validation**: OpenAPI tools verify authentication is properly configured

## Example 3: Field Values (Dynamic Typing)

### Before: Apple's Prose Documentation

> **Record Field Dictionary**
>
> A dictionary that represents a record field. The dictionary contains a single key-value pair. The key is `value`, and the value is the field value whose type depends on the field type. Fields can be strings, numbers, dates, locations, references, assets, or lists.
>
> Example field:
> ```json
> "firstName": {"value": "Mei"}
> ```

### After: OpenAPI Specification

```yaml
components:
  schemas:
    FieldValue:
      type: object
      description: A CloudKit field value with its type information
      properties:
        value:
          oneOf:
            - $ref: '#/components/schemas/StringValue'
            - $ref: '#/components/schemas/Int64Value'
            - $ref: '#/components/schemas/DoubleValue'
            - $ref: '#/components/schemas/BooleanValue'
            - $ref: '#/components/schemas/BytesValue'
            - $ref: '#/components/schemas/DateValue'
            - $ref: '#/components/schemas/LocationValue'
            - $ref: '#/components/schemas/ReferenceValue'
            - $ref: '#/components/schemas/AssetValue'
            - $ref: '#/components/schemas/ListValue'
        type:
          type: string
          enum: [STRING, INT64, DOUBLE, BYTES, REFERENCE, ASSET, ASSETID, LOCATION, TIMESTAMP, LIST]
          description: The CloudKit field type

    StringValue:
      type: string

    Int64Value:
      type: integer
      format: int64

    LocationValue:
      type: object
      properties:
        latitude:
          type: number
          format: double
        longitude:
          type: number
          format: double
        # ... additional properties
```

### Translation Decisions

1. **Discriminated Union**: Used `oneOf` to model CloudKit's dynamic typing
2. **Type Field**: Added explicit `type` enum for runtime type information
3. **Individual Schemas**: Created separate schema for each CloudKit type
4. **Format Hints**: Used OpenAPI `format` for precise type information (int64, double, uri)

### Challenge Solved

CloudKit fields are dynamically typed - the same `value` key can contain a string, number, location object, etc. OpenAPI is statically typed. The solution:

- Use `oneOf` for the value property to indicate "one of these types"
- Include a `type` discriminator field for runtime identification
- Define each possible type explicitly

This enables:
- **Type-safe code generation**: Swift generator creates appropriate enums/unions
- **Validation**: Request/response validation against expected types
- **Documentation**: Clear listing of all possible field types

### Improvements Achieved

```swift
// Generated Swift code example
enum FieldValue {
    case string(String)
    case int64(Int64)
    case double(Double)
    case location(LocationValue)
    case reference(ReferenceValue)
    case asset(AssetValue)
    // ... etc
}

// Usage is type-safe:
let field: FieldValue = .string("Mei")
```

## Example 4: Error Responses

### Before: Apple's Prose Documentation

> **Record Fetch Error Dictionary**
>
> The error dictionary describing a failed operation with the following keys:
>
> - `recordName`: The name of the record that the operation failed on.
> - `reason`: A string indicating the reason for the error.
> - `serverErrorCode`: A string containing the code for the error that occurred. For possible values, see Error Codes.
> - `retryAfter`: The suggested time to wait before trying this operation again.
> - `uuid`: A unique identifier for this error.
> - `redirectURL`: A redirect URL for the user to securely sign in.

### After: OpenAPI Specification

```yaml
components:
  schemas:
    ErrorResponse:
      type: object
      description: Error response object
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
        redirectURL:
          type: string

  responses:
    BadRequest:
      description: Bad request (400) - BAD_REQUEST, ATOMIC_ERROR
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    Unauthorized:
      description: Unauthorized (401) - AUTHENTICATION_FAILED
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    # ... additional error responses
```

### Translation Decisions

1. **Error Code Enum**: Converted prose list of error codes to explicit enum
2. **HTTP Status Mapping**: Created reusable response components for each HTTP status
3. **Consistent Schema**: All errors use same `ErrorResponse` schema
4. **Status Documentation**: Linked HTTP statuses to CloudKit error codes in descriptions

### Improvements Achieved

- **Type-Safe Error Handling**: Generated code includes all possible error codes
- **Automatic Deserialization**: Errors automatically parsed to correct type
- **Centralized Definitions**: Define once, reference everywhere
- **Clear Documentation**: HTTP status → CloudKit error code mapping explicit

## Example 5: URL Structure and Path Parameters

### Before: Apple's Prose Documentation

> **The Web Service URL**
>
> This is the path and common parameters used in all the CloudKit web service URLs:
>
> `[path]/database/[version]/[container]/[environment]/[operation-specific subpath]`
>
> - **path**: The URL to the CloudKit web service, which is `https://api.apple-cloudkit.com`.
> - **version**: The protocol version—currently, 1.
> - **container**: A unique identifier for the app's container. The container ID begins with `iCloud.`.
> - **environment**: The version of the app's container. Pass `development` to use the environment that is not accessible by apps available on the store. Pass `production` to use the environment that is accessible by development apps and apps available on the store.

### After: OpenAPI Specification

```yaml
servers:
  - url: https://api.apple-cloudkit.com
    description: CloudKit Web Services API

paths:
  /database/{version}/{container}/{environment}/{database}/records/query:
    post:
      parameters:
        - $ref: '#/components/parameters/version'
        - $ref: '#/components/parameters/container'
        - $ref: '#/components/parameters/environment'
        - $ref: '#/components/parameters/database'

components:
  parameters:
    version:
      name: version
      in: path
      required: true
      schema:
        type: string
        default: "1"
        description: Protocol version

    container:
      name: container
      in: path
      required: true
      schema:
        type: string
        description: Container ID (begins with "iCloud.")

    environment:
      name: environment
      in: path
      required: true
      schema:
        type: string
        enum: [development, production]
        description: Container environment

    database:
      name: database
      in: path
      required: true
      schema:
        type: string
        enum: [public, private, shared]
        description: Database scope
```

### Translation Decisions

1. **Reusable Parameters**: Defined once, referenced in all endpoints
2. **Enum Constraints**: Used enums for `environment` and `database`
3. **Default Value**: Set version default to "1"
4. **Required Flags**: Marked all path parameters as required
5. **Format Hints**: Kept "iCloud." prefix note in description

### Improvements Achieved

```swift
// Generated Swift code
struct Paths {
    static func queryRecords(
        version: String = "1",
        container: String,
        environment: Environment,  // enum: .development or .production
        database: Database        // enum: .public, .private, or .shared
    ) -> URL {
        // ...
    }
}
```

Benefits:
- **Type-Safe Enums**: Can't pass invalid environment or database values
- **Default Versioning**: Version defaults to "1" automatically
- **Compile-Time Validation**: Invalid paths caught at compile time
- **Self-Documenting**: Function signatures clearly show requirements

## Example 6: Pagination

### Before: Apple's Prose Documentation

> **Query Response**
>
> The response contains an array of records and optionally, a continuation marker:
>
> - `records`: An array of record dictionaries.
> - `continuationMarker`: If present, use this value in the next request to fetch more results.
>
> **Fetching Record Changes**
>
> The response contains:
> - `records`: Changed records since the sync token.
> - `syncToken`: A new token to use in the next request.
> - `moreComing`: A boolean indicating if more changes are available.

### After: OpenAPI Specification

```yaml
components:
  schemas:
    QueryResponse:
      type: object
      properties:
        records:
          type: array
          items:
            $ref: '#/components/schemas/Record'
        continuationMarker:
          type: string

    ChangesResponse:
      type: object
      properties:
        records:
          type: array
          items:
            $ref: '#/components/schemas/Record'
        syncToken:
          type: string
        moreComing:
          type: boolean

paths:
  /records/query:
    post:
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                continuationMarker:
                  type: string
                  description: Marker for pagination
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/QueryResponse'

  /records/changes:
    post:
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                syncToken:
                  type: string
                  description: Token from previous sync operation
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ChangesResponse'
```

### Translation Decisions

1. **Separate Response Schemas**: Different pagination patterns get different schemas
2. **Optional Markers**: Continuation/sync tokens are optional (not marked as required)
3. **Boolean Flag**: `moreComing` explicitly typed as boolean
4. **Bidirectional**: Both request and response include pagination fields

### Improvements Achieved

```swift
// Generated pagination code
var continuation: String? = nil
repeat {
    let response = try await client.queryRecords(
        continuationMarker: continuation
    )
    process(response.records)
    continuation = response.continuationMarker
} while continuation != nil

// Sync with explicit moreComing
var syncToken: String? = loadToken()
repeat {
    let response = try await client.fetchChanges(syncToken: syncToken)
    process(response.records)
    syncToken = response.syncToken
} while response.moreComing
```

Benefits:
- **Type-Safe Pagination**: Compiler ensures correct token types
- **Clear Patterns**: Different pagination styles have different APIs
- **Null Safety**: Optional types prevent crashes on missing tokens

## Translation Philosophy Summary

### Key Principles

1. **Explicit over Implicit**
   - Where docs say "fields object contains values", OpenAPI defines exact structure
   - Examples become schemas with validation rules

2. **Type Safety First**
   - Prose constraints become enums
   - Optional fields clearly marked
   - Format specifications for numbers, dates, URIs

3. **Reusability Through Components**
   - Define schemas once, reference everywhere
   - Parameters shared across endpoints
   - Error responses consistent

4. **Machine-Readable Structure**
   - Prose → YAML schemas
   - Examples → Schema definitions
   - Narratives → Structured descriptions

5. **Validation-Ready**
   - Required fields explicit
   - Type constraints enforced
   - Enum values exhaustive

### Overall Transformation Benefits

| Benefit | Impact |
|---------|--------|
| **Code Generation** | `swift-openapi-generator` creates complete, type-safe Swift client |
| **Automatic Validation** | Requests/responses validated against schema |
| **Living Documentation** | Spec serves as both docs and implementation guide |
| **Consistency** | All endpoints follow same patterns |
| **Tooling Support** | Works with any OpenAPI-compatible tool |
| **Versioning** | Clear API version management |
| **Testing** | Schema enables contract testing |

### Challenges Overcome

1. **Dynamic Typing → Static Types**
   - Solution: Discriminated unions with `oneOf` and type fields

2. **Prose Examples → Precise Schemas**
   - Solution: Extract constraints, model structure explicitly

3. **Informal Constraints → Formal Validation**
   - Solution: Enums, required fields, format specifications

4. **Scattered Information → Centralized Definitions**
   - Solution: Components with `$ref` references

5. **Human-Only Docs → Machine + Human Readable**
   - Solution: Structured YAML with descriptions

## Conclusion

The transformation from Apple's prose CloudKit Web Services documentation to structured OpenAPI 3.0.3 specifications represents a significant improvement in:

- **Precision**: Ambiguity eliminated through explicit schemas
- **Usability**: Code generation enables immediate adoption
- **Maintenance**: Single source of truth for API structure
- **Quality**: Automatic validation prevents errors
- **Documentation**: Self-documenting, always up-to-date

The OpenAPI specification retains all the information from Apple's documentation while adding machine-readability, type safety, and code generation capabilities. This foundation enables MistKit to provide a modern, type-safe Swift interface to CloudKit Web Services.
