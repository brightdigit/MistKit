# Field Type Polymorphism

How MistKit maps CloudKit's nine dynamically-typed field values onto one Swift enum, and why the wire format makes that harder than it looks.

## Overview

A CloudKit [field value](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Types.html) is a JSON object with a `value` and an optional `type`:

```json
{ "value": 1747999812347, "type": "TIMESTAMP" }
```

`value` can be a string, a number, or one of four object shapes, and `type` is one of nine tags — but `type` is optional, three of the scalar types are structurally identical to another scalar, and the tags CloudKit accepts on a write are not the tags it returns on a read. MistKit models this with three layers:

| Layer | Type | Where |
| --- | --- | --- |
| Domain | ``FieldValue`` — the only type callers see | `Models/FieldValues/FieldValue.swift` |
| Request | `Components.Schemas.FieldValueRequest` — generated | `Sources/MistKitOpenAPI/Types.swift` |
| Response | `Components.Schemas.FieldValueResponse` — generated | `Sources/MistKitOpenAPI/Types.swift` |

The generated types are described in <doc:GeneratedCodeAnalysis>; how to read and write fields day to day is in <doc:WorkingWithRecords>. This article explains the conversion between the layers and the rules it enforces.

## The domain enum

```swift
public enum FieldValue: Codable, Hashable, Sendable {
  case string(Arity<String>)
  case int64(Arity<Int>)
  case double(Arity<Double>)
  case bytes(Arity<Data>)  // Binary data; base64-encoded on the wire
  case date(Arity<Date>)  // Date/time value
  case location(Arity<Location>)
  case reference(Arity<Reference>)
  case asset(Arity<Asset>)
}

extension FieldValue {
  public enum Arity<T: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    case value(T)
    case list([T])
  }
}

extension FieldValue.Arity: Hashable where T: Hashable {}
```

Each kind carries an ``FieldValue/Arity``: a single `.value` or a `.list` of that kind. A list is therefore homogeneous by construction, nested lists are unrepresentable, and an empty list still knows its element type (`.string(.list([]))`). This matches CloudKit's `LIST<primitive-type>` schema grammar.

``Location``, ``Reference``, and ``Asset`` are MistKit's own value types, so the package has no dependency on [Core Location](https://developer.apple.com/documentation/corelocation) or the [CloudKit framework](https://developer.apple.com/documentation/cloudkit). There is no boolean case: CloudKit stores booleans as `INT64` `0`/`1`, and ``FieldValue/init(booleanValue:)`` / ``FieldValue/boolValue`` bridge that convention.

## Request and response are different schemas

`openapi.yaml` deliberately declares two schemas rather than one:

```yaml
FieldValueRequest:
  properties:
    value:
      oneOf: [StringValue, Int64Value, DoubleValue, BytesValue,
              DateValue, LocationValue, ReferenceValue, AssetValue, ListValue]
    type:
      enum: [STRING, INT64, DOUBLE, BYTES, TIMESTAMP, REFERENCE, ASSET, ASSETID,
             LOCATION, STRING_LIST, INT64_LIST, DOUBLE_LIST, BYTES_LIST,
             TIMESTAMP_LIST, REFERENCE_LIST, LOCATION_LIST, ASSET_LIST]   # 17 values

FieldValueResponse:
  properties:
    value:
      oneOf: [StringValue, Int64Value, DoubleValue, BytesValue,
              DateValue, LocationValue, ReferenceValue, AssetValue, ListValue]
    type:
      enum: [STRING, INT64, DOUBLE, BYTES, TIMESTAMP, REFERENCE, ASSET, ASSETID,
             LOCATION, STRING_LIST, INT64_LIST, DOUBLE_LIST, BYTES_LIST,
             TIMESTAMP_LIST, REFERENCE_LIST, LOCATION_LIST, ASSET_LIST]   # 17 values
    isEncrypted:
      type: boolean
```

| | Request | Response |
| --- | --- | --- |
| `type` values | 17 — scalars, complex, and eight `*_LIST` element tags | The same 17 (live responses tag lists `STRING_LIST`, `INT64_LIST`, …, never a flat `LIST`) |
| `type` required? | Optional on the wire, **mandatory** for `TIMESTAMP`, `BYTES`, `DOUBLE` | Optional — usually present, and the only way to recover ambiguous scalars |

Two generated types mean the compiler refuses to put a response value into a request slot. The conversions live in `OpenAPI/Components/Components.Schemas.FieldValueRequest.swift` (domain → request) and `Models/FieldValues/FieldValue+Components.swift` plus `FieldValue+Components+Scalar.swift` (response → domain).

## Writes: three scalars must be tagged

CloudKit infers a field's type from the JSON shape of `value`, so most values are sent without `type`. Three scalar types cannot be inferred, because their JSON is indistinguishable from another type:

| Domain case | Wire form | Inferred as, if untagged |
| --- | --- | --- |
| `.date` (`TIMESTAMP`) | millisecond number | `INT64` / `DOUBLE` |
| `.bytes` (`BYTES`) | base64 string | `STRING` |
| `.double` (`DOUBLE`) | whole-valued number (`3.0` serializes as `3`) | `INT64` |

Untagged, CloudKit infers the wrong type and rejects the write with [`BAD_REQUEST "Invalid value, expected type TIMESTAMP"`](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/ErrorCodes.html). The request conversion is a single `default`-free switch over kind and arity. It tags these three scalars, and every list with its `*_LIST` element tag:

```swift
internal init(from fieldValue: FieldValue) {
  switch fieldValue {
  case .string(.value(let value)):
    self.init(value: .StringValue(value))
  case .string(.list(let values)):
    self.init(
      value: .ListValue(values.map { .StringValue($0) }),
      _type: .STRING_LIST
    )
  case .int64(.value(let value)):
    self.init(value: .Int64Value(Int64(value)))
  case .int64(.list(let values)):
    self.init(
      value: .ListValue(values.map { .Int64Value(Int64($0)) }),
      _type: .INT64_LIST
    )
  case .double(.value(let value)):
    // Whole-valued doubles serialize without a fraction and would be read as INT64.
    self.init(value: .DoubleValue(value), _type: .DOUBLE)
  case .double(.list(let values)):
    self.init(
      value: .ListValue(values.map { .DoubleValue($0) }),
      _type: .DOUBLE_LIST
    )
  case .bytes(.value(let value)):
    // A base64 string is otherwise indistinguishable from a STRING.
    self.init(value: .BytesValue(value.base64EncodedString()), _type: .BYTES)
  case .bytes(.list(let values)):
    self.init(
      value: .ListValue(values.map { .BytesValue($0.base64EncodedString()) }),
      _type: .BYTES_LIST
    )
  case .date(.value(let value)):
    // Tag TIMESTAMP (else inferred as INT64/DOUBLE) and round to whole milliseconds:
    // CloudKit rejects a fractional TIMESTAMP value (e.g. 1747999812347.89) with
    // BAD_REQUEST "expected type TIMESTAMP", and Date carries sub-millisecond precision.
    self.init(
      value: .DateValue((value.timeIntervalSince1970 * 1_000).rounded()),
      _type: .TIMESTAMP
    )
  case .date(.list(let values)):
    self.init(
      value: .ListValue(
        values.map { .DateValue(($0.timeIntervalSince1970 * 1_000).rounded()) }
      ),
      _type: .TIMESTAMP_LIST
    )
  case .location(.value(let location)):
    self.init(location: location)
  case .location(.list(let locations)):
    self.init(
      value: .ListValue(locations.map { Self.makeLocationPayload($0) }),
      _type: .LOCATION_LIST
    )
  case .reference(.value(let reference)):
    self.init(reference: reference)
  case .reference(.list(let references)):
    self.init(
      value: .ListValue(references.map { Self.makeReferencePayload($0) }),
      _type: .REFERENCE_LIST
    )
  case .asset(.value(let asset)):
    self.init(asset: asset)
  case .asset(.list(let assets)):
    self.init(
      value: .ListValue(assets.map { Self.makeAssetPayload($0) }),
      _type: .ASSET_LIST
    )
  }
}```

Object-shaped scalars (`REFERENCE`, `ASSET`, `LOCATION`) and scalar `STRING`/`INT64` are unambiguous and stay untagged. Because the switch has no `default`, a new kind is a compile error here rather than a silent fallback.

A field named in `RecordOperation.encryptedFields` is the exception: CloudKit will not infer the type of an encrypted value, so MistKit fills in `STRING`, `INT64` or `LOCATION` for those untagged scalars too.

### Timestamps are whole milliseconds

CloudKit rejects a fractional `TIMESTAMP`, and Swift's `Date` carries sub-millisecond precision, so `.date` values are rounded on the way out. The same rule applies to the nested `Location.timestamp`, which has no `type` tag of its own to disambiguate it. Sub-millisecond precision is therefore destroyed on every write: a `Date` in is a different `Date` out. The `.date(.list(_:))` path applies the same rounding to every element.

### Lists always carry their element tag

Every `.list` arity is sent with its `*_LIST` tag, for record fields as well as for ``QueryFilter`` `IN`/`NOT_IN` values. The `IN` case is where the tag was first found to matter: without it CloudKit rejects every `.in()` query with `HTTP 400 BadRequestException: Unexpected input`, at any array size. `IN` elements are scalar `.value`s, and the filter's tag comes from their kind; an empty `IN` array is sent untagged.

## Reads: recovering the type from an undiscriminated oneOf

The response `value` is an undiscriminated `oneOf`. [swift-openapi-generator](https://github.com/apple/swift-openapi-generator) decodes such a union by trying each case in declaration order and keeping the first that succeeds:

```
String → Int64 → Double → Bytes → Date → Location → Reference → Asset → List
```

So a whole-millisecond `TIMESTAMP` decodes as `Int64Value`, a fractional one as `DoubleValue`, and a base64 `BYTES` string as `StringValue`. The decoded case alone cannot tell you what CloudKit meant; the sibling `type` tag can. The response conversion therefore runs three stages in order:

```
FieldValueResponse (value, type)
        │
        ├─ 1. makeTypedComplex   — complex/list tag? check the value's shape matches
        ├─ 2. makeSimpleFieldValue
        │        ├─ makeTypedScalar   — explicit scalar tag wins over the decoded case
        │        └─ makeInferredScalar — no tag: first-match inference (lossy)
        ├─ 3. makeComplexFieldValue — untagged object/array shapes
        └─ otherwise: ConversionError.unmappableFieldValue
```

### Explicit scalar tags win

```swift
internal static func makeSimpleFieldValue(
  from value: Components.Schemas.FieldValueResponse.valuePayload,
  type fieldType: Components.Schemas.FieldValueResponse._typePayload?,
  fieldName: String
) throws(ConversionError) -> FieldValue? {
  if let typed = try makeTypedScalar(from: value, type: fieldType, fieldName: fieldName) {
    return typed
  }
  return try makeInferredScalar(from: value, fieldName: fieldName)
}
```

`makeTypedScalar` classifies the tag by the value category it demands and produces the typed value directly for the three ambiguous scalars: `TIMESTAMP` and `DOUBLE` from any numeric case, `BYTES` from any string case (decoded with `Data(base64Encoded:)`). `INT64` and `STRING` validate the category and then defer to inference, which already yields the right case and — for `INT64` — avoids truncating a fractional number.

### Contradictions fail loudly

A tag that contradicts the value's category — a numeric type over a string, a string type over a number — describes an internally inconsistent response. The conversion **throws** ``ConversionError/typeValueMismatch(fieldName:declaredType:value:)`` rather than coercing to whichever shape arrived. The same rule covers the complex tags: a declared `REFERENCE`, `ASSET`, `ASSETID` or `LOCATION` whose decoded value is not the matching `oneOf` case, or a `*_LIST` tag over a value that is not a list, throws instead of being silently reinterpreted. `ASSETID` shares `AssetValue` with `ASSET`.

Untagged responses are unaffected: they resolve purely from the value's self-describing structure, so a well-formed response never starts failing because a tag was absent. Every ``ConversionError`` surfaces to callers as ``CloudKitError/conversionFailed(_:)``.

### Inference is lossy by design

When `type` is absent the conversion falls back to first-match inference, which cannot recover the ambiguous scalars: a base64 `BYTES` reads back as `.string`, a whole-number `TIMESTAMP` as `.int64`. MistKit does **not** guess `.bytes` from an untagged string that happens to be valid base64 — ordinary strings such as `"Chen"` decode as valid base64, so that guess would corrupt real data. ``FieldValue/dataValue`` matches `.bytes` only; there is no `.string` fallback.

## Lists keep their element type

Live CloudKit tags list responses with the same granular `*_LIST` values the request uses, including empty lists (`STRING_LIST` with `[]`). A tagged list decodes straight to the matching kind, so a `[Date]` written as `TIMESTAMP_LIST` reads back as `.date(.list(_:))`, and an empty list keeps its kind.

An *untagged* list response falls back to inference: MistKit infers one element kind from the elements, with the same lossiness as untagged scalars. An untagged empty list has no elements to infer from and can't be recovered; CloudKit does not send one in practice. When decoding caller-supplied JSON, the same case throws ``ConversionError/ambiguousEmptyList(fieldName:)`` unless a schema type is supplied (see <doc:EncodingRecordsAsJSON>).

## Assets: one schema for both directions

Unlike `FieldValue`, the `AssetValue` schema is not split. One all-optional struct is referenced from both request and response, and the domain ``Asset`` mirrors it:

```swift
public struct Asset: Codable, Hashable, Sendable {
  public let fileChecksum: String?
  public let size: Int64?
  public let referenceChecksum: String?
  public let wrappingKey: String?
  public let receipt: String?
  public let downloadURL: String?
}
```

The payload is semantically asymmetric even though the type is not:

| Field | Write (request) | Read (response) |
| --- | --- | --- |
| `receipt`, `wrappingKey`, `referenceChecksum` | Produced by the CDN upload step | Not returned |
| `downloadURL` | Ignored if sent | Where to fetch the bytes |
| `fileChecksum`, `size` | Optional metadata | Returned by CloudKit |

The service layer contains the asymmetry instead of the type system: ``CloudKitService/uploadAssets(data:recordType:fieldName:recordName:zoneID:using:database:)`` returns an ``AssetUploadReceipt`` after the [two-step upload](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/UploadAssets.html), from which the write-side `Asset` is built, and reads construct an `Asset` from only what CloudKit returned. Splitting the schema would either break the nine-case symmetry of ``FieldValue`` or force a read/write distinction into the public API that nothing else needs.

`fileChecksum` is an opaque, server-minted identity token — a version byte plus a 20-byte digest — not a SHA-256 of the plaintext. It cannot be recomputed client-side to verify a download; use ``Asset/size`` as a guard against truncation.

## Summary

```
┌─────────────────────────────────────────────┐
│  Public API: FieldValue (9-case enum)       │
└──────────────────┬──────────────────────────┘
                   │
       ┌───────────┴───────────┐
       ▼                       ▼
┌──────────────────┐   ┌────────────────────┐
│ FieldValueRequest│   │ FieldValueResponse │
│ tag TIMESTAMP /  │   │ honor `type` over  │
│ BYTES / DOUBLE;  │   │ decoded case; throw│
│ round to ms      │   │ on contradiction   │
└──────────────────┘   └────────────────────┘
       │                       │
       └───────────┬───────────┘
                   ▼
        CloudKit Web Services (JSON)
```

## Topics

### Domain types

- ``FieldValue``
- ``Location``
- ``Reference``
- ``Asset``

### Errors

- ``ConversionError``
- ``CloudKitError/conversionFailed(_:)``
