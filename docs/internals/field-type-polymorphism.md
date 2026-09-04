# Field Type Polymorphism

MistKit models CloudKit field values through a three-layer type system that bridges Swift's type safety with the CloudKit REST API's loosely-typed JSON.

## Domain Layer: The `FieldValue` Enum

At the public API level, `FieldValue` is a discriminated union (Swift enum) with 9 cases:

```swift
public enum FieldValue: Codable, Equatable, Sendable {
  case string(String)
  case int64(Int)
  case double(Double)
  case bytes(Data)          // Binary data; base64-encoded on the wire
  case date(Date)             // Stored as milliseconds since epoch
  case location(Location)
  case reference(Reference)
  case asset(Asset)
  case list([FieldValue])     // Recursive — supports heterogeneous lists
}
```

This is the only type library consumers interact with. It hides all API serialization details.

## OpenAPI Layer: Request/Response Asymmetry

CloudKit's REST API treats field values differently in requests vs responses. The OpenAPI spec (`openapi.yaml`) models this with two separate schemas:

### FieldValueRequest

```yaml
FieldValueRequest:
  properties:
    value:
      oneOf: [StringValue, Int64Value, DoubleValue, BytesValue,
              DateValue, LocationValue, ReferenceValue, AssetValue, ListValue]
    type:
      enum: [STRING_LIST, INT64_LIST, DOUBLE_LIST, ...]  # List element types only
```

- The `type` field is **optional** and only used for list-typed filter expressions (IN/NOT_IN).
- For mutations, CloudKit **infers** the type from the value's JSON structure.

### FieldValueResponse

```yaml
FieldValueResponse:
  properties:
    value:
      oneOf: [StringValue, Int64Value, DoubleValue, BytesValue,
              DateValue, LocationValue, ReferenceValue, AssetValue, ListValue]
    type:
      enum: [STRING, INT64, DOUBLE, TIMESTAMP, ASSETID, ...]  # All field types
```

- The `type` field is **optional but present** — provides explicit type information.
- Critical for disambiguation: a `DoubleValue` with `type: TIMESTAMP` is a date, not a double.

### Why Two Types?

| Concern | Request | Response |
|---------|---------|----------|
| Type field purpose | Specifies list element type for filters | Disambiguates value semantics |
| Type field values | List types only (STRING_LIST, etc.) | All field types (STRING, TIMESTAMP, etc.) |
| Required? | No — CloudKit infers from structure | No — but aids parsing |

Modeling this asymmetry at the schema level means the Swift compiler prevents accidentally using a response type where a request is expected.

## Generated Code: `oneOf` Polymorphism

The Swift OpenAPI generator translates `oneOf` into nested enums with try-catch decoding:

```swift
internal struct FieldValueRequest: Codable {
    internal enum valuePayload: Codable {
        case StringValue(String)
        case Int64Value(Int64)
        case DoubleValue(Double)
        case DateValue(Double)
        case LocationValue(LocationValue)
        // ... all 9 cases

        internal init(from decoder: any Decoder) throws {
            // Tries each case sequentially — first successful decode wins
            if let v = try? container.decode(String.self) { self = .StringValue(v); return }
            if let v = try? container.decode(Int64.self) { self = .Int64Value(v); return }
            // ...
            throw DecodingError.failedToDecodeOneOfSchema(...)
        }
    }
}
```

No discriminator field is needed in the JSON — the generator relies on structural matching.

## Bidirectional Conversion

### Domain → Request (`Components.Schemas.FieldValueRequest+MistKit.swift`)

```swift
internal init(from fieldValue: FieldValue) {
    switch fieldValue {
    case .string(let value): self.init(value: .StringValue(value))
    // ... one case per FieldValue case, no `default`
    case .list(let list): self.init(list: list)
    }
}
```

A single `default`-free switch covers the simple cases (string, int64, double, bytes, date) and
the complex ones (location, reference, asset, list), so a new `FieldValue` case is a compile
error rather than a silent fallback. Date values are converted from `Date` to milliseconds:

```swift
case .date(let value):
    return Self(value: .DateValue(value.timeIntervalSince1970 * 1_000))
```

### Response → Domain (`FieldValue+Components.swift`)

```swift
private static func makeSimpleFieldValue(
    from value: Components.Schemas.FieldValueResponse.valuePayload,
    type fieldType: Components.Schemas.FieldValueResponse._typePayload?
) -> FieldValue? {
    if case .DoubleValue(let dblVal) = value {
        // The type field disambiguates double vs timestamp
        return fieldType == .TIMESTAMP
            ? .date(Date(timeIntervalSince1970: dblVal / 1_000))
            : .double(dblVal)
    }
    // ...
}
```

The response `type` field is essential here — without it, a timestamp would be indistinguishable from a plain double.

## Known Limitation: Asset Schema Is Not Split

Unlike `FieldValue`, the `AssetValue` schema is **not** split into request/response variants. A single `AssetValue` is referenced from both `FieldValueRequest` and `FieldValueResponse` (`openapi.yaml:1016`), and the domain-level `Asset` struct mirrors that — all fields are optional on a single type.

### What this means for callers

CloudKit's asset payload is semantically asymmetric, but the current schema doesn't enforce it:

| Field | Request side (write) | Response side (read) |
|-------|----------------------|----------------------|
| `receipt` | Required — token from prior CDN upload | Not returned |
| `wrappingKey`, `referenceChecksum` | Set by the upload step | Not returned |
| `downloadURL` | Ignored if sent | Required — where to fetch bytes |
| `fileChecksum`, `size` | Optional metadata | Returned by CloudKit |

Because `AssetValue` flattens both shapes into one all-optional struct, the compiler cannot prevent putting a `downloadURL` into a write payload or expecting a `receipt` on a read. A response asset and a request asset are the same Swift type, so callers can in principle round-trip the wrong shape.

### How the service layer compensates

Rather than splitting the schema, the asymmetry is handled at the service layer:

1. **Two-step upload flow** (`CloudKitService+WriteOperations.swift`) hides raw asset request construction from callers. `uploadAssets()` calls `requestAssetUploadURL()` → `uploadAssetData()` → produces an `Asset` populated with `receipt`/`wrappingKey`/`size` ready for a follow-up `modifyRecords` call. Callers don't hand-build write-side `Asset` values.
2. **Read-side `Asset` values** are constructed in `FieldValue+Components.swift` from `FieldValueResponse`, populated only with the fields CloudKit actually returns (`downloadURL`, `fileChecksum`, `size`).
3. **Convention over compilation:** when consuming code needs to act on a download URL, it pattern-matches `case .asset(let asset)` and reads `asset.downloadURL`. The unused write-side fields are simply `nil`.

In practice this is sufficient because callers never construct write-side asset values directly — the upload flow always hands them a fully-populated `Asset`.

### Why the asymmetry isn't pushed into types

A schema split (`AssetValueRequest` + `AssetValueResponse`, mirroring the `FieldValue` split) would move this asymmetry into the type system, but it would also require either two public domain types — breaking the 9-case enum symmetry on `FieldValue` — or a domain-level read/write distinction the public API deliberately doesn't make. The current design treats `Asset` as a single round-trippable value and contains the asymmetry inside the service layer instead.

## Recursive List Handling

Lists use `ListValuePayload` — structurally identical to `valuePayload` — enabling nested heterogeneous lists:

```swift
extension Components.Schemas.ListValuePayload {
    internal init(from fieldValue: FieldValue) {
        // Same scalar/complex split, recursively applied to each element
    }
}
```

## Summary

```
┌─────────────────────────────────────────────┐
│  Public API: FieldValue (9-case enum)       │
└──────────────────┬──────────────────────────┘
                   │ Bidirectional conversion
       ┌───────────┴───────────┐
       ▼                       ▼
┌──────────────┐      ┌───────────────┐
│ FieldValue   │      │ FieldValue    │
│ Request      │      │ Response      │
│ (no type)    │      │ (+ type hint) │
└──────────────┘      └───────────────┘
       │                       │
       └───────────┬───────────┘
                   ▼
        CloudKit REST API (JSON)
```
