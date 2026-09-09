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
public enum FieldValue: Codable, Equatable, Sendable {
  case string(String)
  case int64(Int)
  case double(Double)
  case bytes(Data)  // Binary data; base64-encoded on the wire
  case date(Date)  // Date/time value
  case location(Location)
  case reference(Reference)
  case asset(Asset)
  case list([FieldValue])
}
```

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
      enum: [STRING, INT64, DOUBLE, BYTES, REFERENCE, ASSET, ASSETID,
             LOCATION, TIMESTAMP, LIST]                                     # 10 values
```

| | Request | Response |
| --- | --- | --- |
| `type` values | 17 — scalars, complex, and eight `*_LIST` element tags | 10 — scalars, complex, and a single `LIST` |
| `type` required? | Optional on the wire, **mandatory** for `TIMESTAMP`, `BYTES`, `DOUBLE` | Optional — usually present, and the only way to recover ambiguous scalars |

Two generated types mean the compiler refuses to put a response value into a request slot. The conversions live in `OpenAPI/Components/Components.Schemas.FieldValueRequest.swift` (domain → request) and `Models/FieldValues/FieldValue+Components.swift` plus `FieldValue+Components+Scalar.swift` (response → domain).

## Writes: three scalars must be tagged

CloudKit infers a field's type from the JSON shape of `value`, so most values are sent without `type`. Three scalar types cannot be inferred, because their JSON is indistinguishable from another type:

| Domain case | Wire form | Inferred as, if untagged |
| --- | --- | --- |
| `.date` (`TIMESTAMP`) | millisecond number | `INT64` / `DOUBLE` |
| `.bytes` (`BYTES`) | base64 string | `STRING` |
| `.double` (`DOUBLE`) | whole-valued number (`3.0` serializes as `3`) | `INT64` |

Untagged, CloudKit infers the wrong type and rejects the write with [`BAD_REQUEST "Invalid value, expected type TIMESTAMP"`](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/ErrorCodes.html). The request conversion is a single `default`-free switch that tags exactly these three:

```swift
internal init(from fieldValue: FieldValue) {
  switch fieldValue {
  case .string(let value):
    self.init(value: .StringValue(value))
  case .int64(let value):
    self.init(value: .Int64Value(Int64(value)))
  case .double(let value):
    // Whole-valued doubles serialize without a fraction and would be read as INT64.
    self.init(value: .DoubleValue(value), _type: .DOUBLE)
  case .bytes(let value):
    // A base64 string is otherwise indistinguishable from a STRING.
    self.init(value: .BytesValue(value.base64EncodedString()), _type: .BYTES)
  case .date(let value):
    // Tag TIMESTAMP (else inferred as INT64/DOUBLE) and round to whole milliseconds:
    // CloudKit rejects a fractional TIMESTAMP value (e.g. 1747999812347.89) with
    // BAD_REQUEST "expected type TIMESTAMP", and Date carries sub-millisecond precision.
    self.init(
      value: .DateValue((value.timeIntervalSince1970 * 1_000).rounded()),
      _type: .TIMESTAMP
    )
  case .location(let location):
    self.init(location: location)
  case .reference(let reference):
    self.init(reference: reference)
  case .asset(let asset):
    self.init(asset: asset)
  case .list(let list):
    self.init(list: list)
  }
}
```

Object- and array-shaped values (`REFERENCE`, `ASSET`, `LOCATION`, `LIST`) and `STRING`/`INT64` are unambiguous and stay untagged. Because the switch has no `default`, a tenth `FieldValue` case is a compile error here rather than a silent fallback.

### Timestamps are whole milliseconds

CloudKit rejects a fractional `TIMESTAMP`, and Swift's `Date` carries sub-millisecond precision, so `.date` values are rounded on the way out. The same rule applies to the nested `Location.timestamp`, which has no `type` tag of its own to disambiguate it. Sub-millisecond precision is therefore destroyed on every write: a `Date` in is a different `Date` out. The list path (`ListValuePayload`) applies the same rounding to `[Date]` elements.

### IN / NOT_IN filters use the list tags

The eight `*_LIST` request tags exist for one caller: ``QueryFilter`` `IN`/`NOT_IN` comparators. Without an element-type tag CloudKit rejects every `.in()` query with `HTTP 400 BadRequestException: Unexpected input`, at any array size. The tag is derived from the first element, so a heterogeneous list is tagged by element zero and an empty list is sent untagged.

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
  return makeInferredScalar(from: value)
}
```

`makeTypedScalar` classifies the tag by the value category it demands and produces the typed value directly for the three ambiguous scalars: `TIMESTAMP` and `DOUBLE` from any numeric case, `BYTES` from any string case (decoded with `Data(base64Encoded:)`). `INT64` and `STRING` validate the category and then defer to inference, which already yields the right case and — for `INT64` — avoids truncating a fractional number.

### Contradictions fail loudly

A tag that contradicts the value's category — a numeric type over a string, a string type over a number — describes an internally inconsistent response. The conversion **throws** ``ConversionError/typeValueMismatch(fieldName:declaredType:value:)`` rather than coercing to whichever shape arrived. The same rule covers the complex tags: a declared `REFERENCE`, `ASSET`, `ASSETID`, `LOCATION`, or `LIST` whose decoded value is not the matching `oneOf` case throws instead of being silently reinterpreted. `ASSETID` shares `AssetValue` with `ASSET`; `LIST` is validated at the container level only — element types stay lenient.

Untagged responses are unaffected: they resolve purely from the value's self-describing structure, so a well-formed response never starts failing because a tag was absent. Every ``ConversionError`` surfaces to callers as ``CloudKitError/conversionFailed(_:)``.

### Inference is lossy by design

When `type` is absent the conversion falls back to first-match inference, which cannot recover the ambiguous scalars: a base64 `BYTES` reads back as `.string`, a whole-number `TIMESTAMP` as `.int64`. MistKit does **not** guess `.bytes` from an untagged string that happens to be valid base64 — ordinary strings such as `"Chen"` decode as valid base64, so that guess would corrupt real data. ``FieldValue/dataValue`` matches `.bytes` only; there is no `.string` fallback.

## Lists lose their element type

The request enum has eight `*_LIST` tags; the response enum collapses every list to a single `LIST`, and `ListValuePayload` carries no per-element tag. A `[Date]` written as `TIMESTAMP_LIST` therefore reads back as `[.int64]`. The element type is information you must *send* and can never *read back*; MistKit re-infers elements structurally, with the same lossiness as untagged scalars.

## Assets: one schema for both directions

Unlike `FieldValue`, the `AssetValue` schema is not split. One all-optional struct is referenced from both request and response, and the domain ``Asset`` mirrors it:

```swift
public struct Asset: Codable, Equatable, Sendable {
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
