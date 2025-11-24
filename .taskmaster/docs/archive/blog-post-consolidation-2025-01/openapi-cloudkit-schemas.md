# CloudKit-Specific Schema Definitions in OpenAPI

## Overview

This document analyzes how CloudKit's unique data structures were translated into OpenAPI 3.0.3 schema definitions in the MistKit project. The analysis focuses on the core CloudKit types and how they're represented in a standard OpenAPI format.

## Authentication Patterns

### 1. API Token Authentication (`ApiTokenAuth`)

**Location:** `openapi.yaml:743-747`

```yaml
ApiTokenAuth:
  type: apiKey
  in: query
  name: ckAPIToken
  description: API token created using CloudKit Dashboard
```

**Design Decision:** Uses query parameter authentication, which aligns with CloudKit's web services pattern. Requires both `ckAPIToken` and `ckWebAuthToken` parameters in the actual request.

**Usage:** Suitable for web-based applications where tokens can be generated through the CloudKit Dashboard.

### 2. Server-to-Server Authentication (`ServerToServerAuth`)

**Location:** `openapi.yaml:748-752`

```yaml
ServerToServerAuth:
  type: apiKey
  in: header
  name: X-Apple-CloudKit-Request-KeyID
  description: Key ID for server-to-server authentication
```

**Design Decision:** Uses header-based authentication with a key ID, following standard API authentication practices. More secure for server-side applications.

**Usage:** Designed for server-to-server communication where API keys can be securely stored.

### Authentication Security Scheme Application

**Location:** `openapi.yaml:29-31`

```yaml
security:
  - ApiTokenAuth: []
  - ServerToServerAuth: []
```

Both methods are specified at the root level, allowing either authentication method for all endpoints. This provides flexibility in how clients authenticate.

## Core CloudKit Data Structures

### 1. Record Schema

**Location:** `openapi.yaml:824-840`

```yaml
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
```

**Key Design Decisions:**

1. **Dynamic Fields:** The `fields` property uses `additionalProperties` to allow any field name, matching CloudKit's schema-less design
2. **Optimistic Concurrency:** The `recordChangeTag` enables conflict detection for updates
3. **Type Safety:** Each field references `FieldValue`, ensuring proper type information

**CloudKit Mapping:**
- CloudKit's `CKRecord` → OpenAPI `Record` object
- CloudKit's record fields → OpenAPI `fields` object with dynamic keys
- CloudKit's change tags → OpenAPI `recordChangeTag` string

### 2. FieldValue Schema (Discriminated Union)

**Location:** `openapi.yaml:842-861`

```yaml
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
```

**Key Design Decisions:**

1. **Type Discrimination:** Uses `oneOf` to model CloudKit's dynamic typing system
2. **Explicit Type Field:** The `type` enum provides runtime type information, matching CloudKit's wire format
3. **Comprehensive Coverage:** Includes all CloudKit field types including complex types (Asset, Reference, Location)

**Challenge Solved:** CloudKit fields are dynamically typed at runtime. OpenAPI's static typing is accommodated through discriminated unions, allowing code generators to create type-safe Swift code while preserving CloudKit's flexibility.

### 3. AssetValue Schema

**Location:** `openapi.yaml:939-962`

```yaml
AssetValue:
  type: object
  description: Asset dictionary as defined in CloudKit Web Services
  properties:
    fileChecksum:
      type: string
      description: Checksum of the asset file
    size:
      type: integer
      format: int64
      description: Size of the asset in bytes
    referenceChecksum:
      type: string
      description: Checksum of the asset reference
    wrappingKey:
      type: string
      description: Wrapping key for the asset
    receipt:
      type: string
      description: Receipt for the asset
    downloadURL:
      type: string
      format: uri
      description: URL for downloading the asset
```

**Key Design Decisions:**

1. **Checksum Integrity:** Multiple checksum fields ensure data integrity during upload/download
2. **Encryption Support:** `wrappingKey` property supports CloudKit's encryption features
3. **Receipt Pattern:** The `receipt` field follows CloudKit's asset upload/download workflow
4. **Direct URL Access:** `downloadURL` provides the actual download location

**CloudKit Mapping:**
- CloudKit's `CKAsset` → OpenAPI `AssetValue` object
- CloudKit's asset tokens → OpenAPI `receipt` and URL properties
- CloudKit's encryption → OpenAPI `wrappingKey`

### 4. ReferenceValue Schema

**Location:** `openapi.yaml:927-937`

```yaml
ReferenceValue:
  type: object
  description: Reference dictionary as defined in CloudKit Web Services
  properties:
    recordName:
      type: string
      description: The record name being referenced
    action:
      type: string
      enum: [DELETE_SELF]
      description: Action to perform on the referenced record
```

**Key Design Decisions:**

1. **Simple Reference Model:** Only requires the referenced record's name
2. **Cascade Delete:** The `action` enum supports CloudKit's `DELETE_SELF` cascade behavior
3. **Type Safety:** Using an enum prevents invalid action values

**CloudKit Mapping:**
- CloudKit's `CKRecord.Reference` → OpenAPI `ReferenceValue` object
- CloudKit's reference actions → OpenAPI `action` enum

### 5. LocationValue Schema

**Location:** `openapi.yaml:890-925`

```yaml
LocationValue:
  type: object
  description: Location dictionary as defined in CloudKit Web Services
  properties:
    latitude:
      type: number
      format: double
      description: Latitude in degrees
    longitude:
      type: number
      format: double
      description: Longitude in degrees
    horizontalAccuracy:
      type: number
      format: double
      description: Horizontal accuracy in meters
    verticalAccuracy:
      type: number
      format: double
      description: Vertical accuracy in meters
    altitude:
      type: number
      format: double
      description: Altitude in meters
    speed:
      type: number
      format: double
      description: Speed in meters per second
    course:
      type: number
      format: double
      description: Course in degrees
    timestamp:
      type: number
      format: double
      description: Timestamp in milliseconds since epoch
```

**Key Design Decisions:**

1. **Complete CLLocation Mapping:** Includes all properties from Apple's `CLLocation` class
2. **Accuracy Information:** Both horizontal and vertical accuracy for precision requirements
3. **Motion Data:** Speed and course support location tracking scenarios
4. **Timestamp:** Epoch milliseconds for cross-platform compatibility

**CloudKit Mapping:**
- CloudKit's location type → OpenAPI `LocationValue` object
- Core Location properties → OpenAPI double-precision numbers
- All accuracy, altitude, and motion properties preserved

## Primitive Type Mappings

### String, Int64, Double, Boolean

**Location:** `openapi.yaml:863-879`

Simple scalar types that map directly to OpenAPI primitive types:

```yaml
StringValue:
  type: string

Int64Value:
  type: integer
  format: int64

DoubleValue:
  type: number
  format: double

BooleanValue:
  type: boolean
```

### BytesValue and DateValue

**Location:** `openapi.yaml:881-888`

```yaml
BytesValue:
  type: string
  description: Base64-encoded string representing binary data

DateValue:
  type: number
  format: double
  description: Number representing milliseconds since epoch
```

**Key Design Decisions:**

1. **Base64 for Binary:** Standard OpenAPI practice for binary data in JSON
2. **Numeric Timestamps:** Milliseconds since epoch for maximum precision and cross-platform compatibility

### ListValue (Arrays)

**Location:** `openapi.yaml:964-978`

```yaml
ListValue:
  type: array
  description: Array containing any of the above field types
  items:
    oneOf:
      - $ref: '#/components/schemas/StringValue'
      - $ref: '#/components/schemas/Int64Value'
      - ... (all field types)
```

**Key Design Decisions:**

1. **Heterogeneous Arrays:** CloudKit supports mixed-type arrays, modeled with `oneOf`
2. **Recursive Support:** Lists can contain other lists (nested arrays)
3. **Type Preservation:** Each element maintains its type information

## Path Parameters and URL Structure

**Location:** `openapi.yaml:754-785`

```yaml
parameters:
  version:
    name: version
    in: path
    required: true
    schema:
      type: string
      default: "1"
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
  database:
    name: database
    in: path
    required: true
    schema:
      type: string
      enum: [public, private, shared]
```

**Key Design Decisions:**

1. **Reusable Parameters:** Defined once, referenced everywhere with `$ref`
2. **Enum Constraints:** `environment` and `database` use enums for type safety
3. **Default Version:** Version defaults to "1" for current API version
4. **Container Format Hint:** Description notes "iCloud." prefix requirement

**URL Pattern:**
```
https://api.apple-cloudkit.com/database/{version}/{container}/{environment}/{database}/{operation}
```

## Translation Philosophy: Documentation to Specification

### From Apple's Prose Documentation to Structured OpenAPI

**Challenge:** Apple's CloudKit Web Services documentation is comprehensive but prose-heavy, making it difficult to generate type-safe client code.

**Solution:** Extract precise data structures and constraints from documentation, represent them in machine-readable OpenAPI format.

### Key Translation Principles

1. **Explicit over Implicit:** Where Apple's docs say "fields object contains field values", the OpenAPI spec defines exactly what a FieldValue is
2. **Type Safety:** Use enums for constrained values (environments, database types, error codes)
3. **Reusability:** Component schemas and parameters reduce duplication
4. **Comprehensive Error Modeling:** Map all HTTP status codes to specific CloudKit error scenarios

### Benefits of OpenAPI Translation

1. **Code Generation:** `swift-openapi-generator` can produce type-safe Swift client code
2. **API Discovery:** Developers can explore the API structure programmatically
3. **Validation:** Both requests and responses can be validated against the schema
4. **Documentation:** OpenAPI spec serves as both documentation and implementation guide
5. **Cross-Platform:** Standard format works with any OpenAPI-compatible tooling

## Comparison: Before and After

### Before (Apple's Documentation Style)

> "A dictionary that represents a record. The fields property is a dictionary where keys are field names and values are field value dictionaries containing value and type properties."

### After (OpenAPI Schema)

```yaml
Record:
  type: object
  properties:
    recordName:
      type: string
    recordType:
      type: string
    fields:
      type: object
      additionalProperties:
        $ref: '#/components/schemas/FieldValue'

FieldValue:
  type: object
  properties:
    value:
      oneOf: [...]
    type:
      type: string
      enum: [STRING, INT64, ...]
```

The OpenAPI version is:
- Machine-readable
- Type-safe
- Precise about structure
- Suitable for code generation
- Self-documenting

## Summary

The OpenAPI specification successfully translates CloudKit's unique data model into a standard REST API format. Key achievements:

1. **Authentication Flexibility:** Two authentication methods properly modeled
2. **Dynamic Typing Support:** Discriminated unions handle CloudKit's runtime typing
3. **Complex Type Mapping:** Assets, References, and Locations fully represented
4. **Error Handling:** Comprehensive error response schemas
5. **Type Safety:** Enums and constraints prevent invalid values
6. **Code Generation Ready:** Structure enables `swift-openapi-generator` to create usable Swift code

The specification serves as the foundation for MistKit's type-safe Swift implementation while remaining true to CloudKit's flexible, dynamic data model.
