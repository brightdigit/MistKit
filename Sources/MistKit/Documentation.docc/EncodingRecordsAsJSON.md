# Encoding Records as JSON

Store, cache, and exchange records in CloudKit's own JSON shape with MistKit's public wire codecs.

## Overview

``CloudKitService`` converts records to and from CloudKit Web Services JSON for you, so most code never sees the wire format. When you keep records outside CloudKit — a cache file, a web API between your server and a browser, a fixture pasted from the CloudKit Console — you need that JSON yourself. MistKit exposes the same field and record dictionaries CloudKit uses as `Codable` types:

| Type | JSON | Direction |
| --- | --- | --- |
| ``WireFieldValue`` | One field dictionary, `{"value": …, "type": …}` | Encode and decode |
| ``WireRecord`` | One record dictionary, as a query or lookup returns it | Encode and decode |
| ``WireRecordDocument`` | An array of records, one record, a query response, or a `records/modify` body | Decode only |
| ``WireRecordOperation`` | One entry of a `records/modify` body's `operations` | Encode and decode |
| ``ModifyRecordsRequestBody`` | A whole `records/modify` body | Encode and decode |

``FieldTypeTagging`` controls when field dictionaries carry `type`. Why the tag matters, and how MistKit converts it on requests and responses, is covered in <doc:FieldTypePolymorphism>.

## Field dictionaries

A ``WireFieldValue`` wraps an optional ``FieldValue``. A `nil` value is a cleared field and encodes as `{"value": null}`:

```swift
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]

try encoder.encode(WireFieldValue(.string(.value("a"))))
// {"value":"a"}
try encoder.encode(WireFieldValue(.string(.value("a")), typeTagging: .always))
// {"type":"STRING","value":"a"}
try encoder.encode(WireFieldValue(.double(.value(2))))
// {"type":"DOUBLE","value":2}
try encoder.encode(WireFieldValue(.int64(.list([1, 2])), typeTagging: .always))
// {"type":"INT64_LIST","value":[1,2]}
try encoder.encode(WireFieldValue(nil))
// {"value":null}
```

### Choosing a tagging

| ``FieldTypeTagging`` | Writes `type` on | Matches |
| --- | --- | --- |
| ``FieldTypeTagging/whenRequired`` | Only the values CloudKit can't infer: `TIMESTAMP`, `BYTES`, `DOUBLE`, and every list (`STRING_LIST`, `INT64_LIST`, …) | What MistKit sends to CloudKit |
| ``FieldTypeTagging/always`` | Every value | What CloudKit returns in responses |

Use ``FieldTypeTagging/always`` for anything you will read back later. Without a tag, JSON can't tell a millisecond `TIMESTAMP` from an `INT64`, a base64 `BYTES` string from a `STRING`, or a whole-valued `DOUBLE` (`2`) from an `INT64`, and an empty list `[]` has no element type at all. With the tag, every kind round-trips: `.date` stays a date, `.bytes` stays `Data`, `.double(.value(2))` stays a double, and `.string(.list([]))` stays an empty list of strings.

`.date` values are written as whole milliseconds since 1970, because CloudKit rejects a fractional `TIMESTAMP`. A `Date` with sub-millisecond precision therefore reads back rounded. See <doc:FieldTypePolymorphism> for the full rules.

### Decoding untagged values

Decoding takes the type from the dictionary's own `type` when present. Otherwise it uses the decoder's `CodingUserInfoKey.cloudKitFieldTypes` entry for that field name, then the JSON shape: a string reads as `STRING`, a whole number as `INT64`, any other number as `DOUBLE`, an object as `LOCATION`, `REFERENCE`, or `ASSET` by its keys, and a list by its first element. `JSONDecoder` doesn't keep the difference between `5` and `5.0`, so both read as `INT64`.

For hand-written or pasted JSON whose values are ambiguous, supply the schema types:

```swift
let decoder = JSONDecoder()
decoder.userInfo[.cloudKitFieldTypes] = ["seenAt": SchemaFieldType(.timestamp)]
let record = try decoder.decode(WireRecord.self, from: data)
```

`CodingUserInfoKey.cloudKitFieldTypes` takes a `[String: SchemaFieldType]` keyed by field name. A tag in the JSON always wins over the schema type. An untagged empty list with no schema type fails with ``ConversionError/ambiguousEmptyList(fieldName:)``, and a value that contradicts its type (`{"value":"x","type":"TIMESTAMP"}`) fails with the same ``ConversionError`` a CloudKit response would. Both arrive as `DecodingError.dataCorrupted` with the ``ConversionError`` as its `underlyingError` and the field in its coding path.

After decoding, ``WireFieldValue/typeTagging`` is ``FieldTypeTagging/always`` when the dictionary had a `type`.

## Records

``WireRecord`` is a record dictionary: `recordName`, `recordType`, `recordChangeTag`, `zoneID`, `fields`, `created`, `modified`, and `deleted`. Build one from a ``RecordInfo`` with ``WireRecord/init(_:typeTagging:)``, which tags every field by default, and pair it with `JSONEncoder.cloudKitReadable`, which pretty-prints and sorts keys so the output is byte-for-byte stable across platforms:

```swift
let data = try JSONEncoder.cloudKitReadable.encode(records.map { WireRecord($0) })
```

A single record encodes as:

```json
{
  "fields" : {
    "count" : {
      "type" : "INT64",
      "value" : -7
    },
    "title" : {
      "type" : "STRING",
      "value" : "Plain"
    }
  },
  "recordChangeTag" : "tag-2",
  "recordName" : "specimen-2",
  "recordType" : "Specimen",
  "zoneID" : {
    "zoneName" : "_defaultZone"
  }
}
```

`created` and `modified` are written as whole-millisecond timestamps, and `deleted` only when it is `true`. ``WireRecord/clearedFields`` names fields written as `{"value": null}`; ``WireRecord/encryptedFields`` names fields written with `"isEncrypted": true`.

Convert back with ``RecordInfo/init(_:)``. It throws ``ConversionError/recordMissingRecordName`` when the wire record has no name, and drops ``WireRecord/clearedFields``, because a ``RecordInfo`` has only the fields it has.

> Note: ``RecordInfo`` is itself `Codable`, and its fields use the tagged ``FieldValue`` encoding described below. Its JSON is MistKit's shape, not CloudKit's record dictionary. Use ``WireRecord`` when the JSON has to match what CloudKit sends.

### Reading records from any shape

``WireRecordDocument`` decodes records from whichever JSON you were given and records which one it was in ``WireRecordDocument/shape``:

| ``WireRecordDocument/Shape`` | JSON |
| --- | --- |
| ``WireRecordDocument/Shape/records`` | `[ {record}, … ]` |
| ``WireRecordDocument/Shape/record`` | `{record}` |
| ``WireRecordDocument/Shape/queryResponse`` | `{"records": [ … ], …}` |
| ``WireRecordDocument/Shape/modifyBody`` | `{"operations": [ … ], "zoneID": …}` |

```swift
let document = try JSONDecoder().decode(WireRecordDocument.self, from: data)
let records = try document.recordInfos()
```

For a modify body, delete operations are skipped and each record without its own `zoneID` takes the body's ``WireRecordDocument/zoneID``. A decoding failure inside an array carries the record's index, `fields`, and the field name in its coding path.

## Modify operations

``WireRecordOperation`` encodes one ``RecordOperation``; ``ModifyRecordsRequestBody`` encodes a whole `records/modify` body with optional `zoneID` and `atomic`. Both default to ``FieldTypeTagging/whenRequired``, the tagging ``CloudKitService`` sends. Cleared fields are written as `{"value": null}`, and a delete writes only `recordName` and `recordChangeTag`:

```swift
let body = ModifyRecordsRequestBody(
  operations: [
    .create(recordType: "Note", recordName: "n1", fields: ["title": .string(.value("A"))]),
    .update(
      recordType: "Note",
      recordName: "n2",
      fields: ["title": .string(.value("B"))],
      clearedFields: ["body"],
      recordChangeTag: "t2"
    ),
    .delete(recordType: "Note", recordName: "n3", recordChangeTag: "t3"),
  ],
  zoneID: ZoneID(zoneName: "Teams"),
  atomic: true,
  typeTagging: .always
)
```

With sorted keys this encodes as (line breaks added):

```json
{"atomic":true,"operations":[
  {"operationType":"create","record":{"fields":{"title":{"type":"STRING","value":"A"}},
    "recordName":"n1","recordType":"Note"}},
  {"operationType":"update","record":{"fields":{"body":{"value":null},
    "title":{"type":"STRING","value":"B"}},"recordChangeTag":"t2",
    "recordName":"n2","recordType":"Note"}},
  {"operationType":"delete","record":{"recordChangeTag":"t3","recordName":"n3"}}],
 "zoneID":{"zoneName":"Teams"}}
```

Decoding the same JSON gives back an equal body. An unknown `operationType` is a decoding error.

### Encrypted fields

A field named in a record's or operation's `encryptedFields` is written with `"isEncrypted": true` and always carries `type`, whatever the tagging, because CloudKit won't infer the type of an encrypted value:

```swift
let operation = WireRecordOperation(
  RecordOperation(
    operationType: .create,
    recordType: "Note",
    recordName: "n1",
    fields: ["secret": .string(.value("s"))],
    encryptedFields: ["secret"]
  )
)
// …"secret":{"isEncrypted":true,"type":"STRING","value":"s"}…
```

Decoding reads `"isEncrypted": true` back into `encryptedFields`. A standalone ``WireFieldValue`` has no encryption flag; it lives on the record.

## FieldValue's own Codable

``FieldValue`` is `Codable` through ``WireFieldValue`` with ``FieldTypeTagging/always``. It encodes and decodes **only** a tagged field dictionary:

```json
{ "value": 1790000000500, "type": "TIMESTAMP" }
```

Decoding fails with `DecodingError.dataCorrupted` for an untagged dictionary (`{"value": "Hi"}`) and for a cleared field (`{"value": null}`), because a cleared field isn't a ``FieldValue``. Bare JSON values such as `"Hi"`, `5`, or `[…]` are also errors.

CloudKit requests and responses don't use this `Codable`; they go through their own request and response conversions.

### In practice: MistDemo's web API

MistDemo's local web server (`Examples/MistDemo/Sources/MistDemoKit/Server/`) decodes request bodies straight into ``FieldValue``, with no custom request type:

```swift
internal struct Create: Decodable {
  internal let recordType: String
  internal let recordName: String?
  internal let fields: [String: FieldValue]
  // …
}
```

The browser therefore tags every field before posting to `/api/records/create` or `/api/records/update`:

```json
{"title": {"value": "Hi", "type": "STRING"}, "index": {"value": 5, "type": "INT64"}}
```

A field without `type` is rejected as a bad request instead of being guessed at.

## Naming the record behind an encoding error

`JSONEncoder` refuses a `NaN` or infinite number — a `DOUBLE`, or a location's latitude, longitude, or altitude — with `EncodingError.invalidValue`. Its coding path holds the record's index, `fields`, and the field name. ``CloudKitError/init(encodingError:recordNames:)`` turns that into ``CloudKitError/invalidFieldValue(recordName:fieldName:underlying:)``:

```swift
do {
  let data = try JSONEncoder.cloudKitReadable.encode(records.map { WireRecord($0) })
  try data.write(to: cacheURL)
} catch {
  if let fieldError = CloudKitError(
    encodingError: error,
    recordNames: records.map(\.recordName)
  ) {
    print("Can't encode \(fieldError.fieldName ?? "?") on \(fieldError.recordName ?? "?")")
  }
  throw error
}
```

Pass the record names in encoding order. It works for `[WireRecord]`, a payload holding one, a single ``WireRecord``, and ``ModifyRecordsRequestBody``, and returns `nil` for an error that isn't about a record's field. ``CloudKitService`` does the same check before sending, so `modifyRecords` throws ``CloudKitError/invalidFieldValue(recordName:fieldName:underlying:)`` with nothing sent.

``RecordFieldErrorContext`` reads `recordName` and `fieldName` uniformly off ``CloudKitError`` and ``ConversionError``; a ``ConversionError`` names only the field. See <doc:HandlingErrors>.

## Topics

### Wire codecs

- ``WireFieldValue``
- ``WireRecord``
- ``WireRecordDocument``
- ``WireRecordOperation``
- ``ModifyRecordsRequestBody``
- ``FieldTypeTagging``

### Errors

- ``RecordFieldErrorContext``
- ``CloudKitError/init(encodingError:recordNames:)``
- ``CloudKitError/invalidFieldValue(recordName:fieldName:underlying:)``
- ``ConversionError``
