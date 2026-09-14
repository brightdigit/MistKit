# Working with Records

CRUD, batch, and lookup against CloudKit records — the operations you'll reach for most often, with idiomatic ``CloudKitService`` snippets.

## Overview

``CloudKitService`` exposes the CloudKit record lifecycle as a handful of focused async methods. This article walks the full surface so you can pick the right one without reading every operation file. For per-method examples, see the inline DocC on each method; for sync-via-change-tokens, see the linked sync section at the end; for limits and performance, see <doc:CloudKitLimitsAndPerformance>.

## Querying

Use ``CloudKitService/queryRecords(_:limit:desiredKeys:continuationMarker:zoneID:zoneWide:numbersAsStrings:database:)`` for a single page of results. [Filters](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/QueryingRecords.html) are built with ``QueryFilter`` factories, sorts with ``QuerySort/ascending(_:)`` / ``QuerySort/descending(_:)``:

```swift
let result = try await service.queryRecords(
  Query(
    recordType: "Article",
    filters: [
      .greaterThan("publishedDate", .date(oneWeekAgo)),
      .equals("status", .string(.value("published")))
    ],
    sortBy: [.descending("publishedDate")]
  ),
  limit: 50,
  database: .private
)
for record in result.records {
  print(record.recordName)
}
```

For unbounded iteration, ``CloudKitService/queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:zoneID:database:)`` walks the continuation marker for you with a safety guard at `maxPages` (default `1_000`):

```swift
let allArticles = try await service.queryAllRecords(
  recordType: "Article",
  pageSize: 200,
  database: .private
)
```

> Warning: If `queryAllRecords` hits its page cap, it throws ``CloudKitError/paginationLimitExceeded(maxPages:records:)`` with the records collected so far. See <doc:HandlingErrors> for the recovery pattern.

### Querying a custom or shared zone

Both query methods accept an optional `zoneID`. When you omit it, the `zoneID` key is left out of the request entirely and CloudKit resolves the database's default zone (`_defaultZone`) — which is the only zone the public database has.

To read from a custom zone in the private database, pass a ``ZoneID``:

```swift
let notes = try await service.queryAllRecords(
  recordType: "Note",
  zoneID: ZoneID(zoneName: "NotesZone"),
  database: .private
)
```

A shared zone additionally needs the owner's record name, because the zone lives in *their* database:

```swift
let shared = try await service.queryRecords(
  Query(recordType: "Note"),
  zoneID: ZoneID(zoneName: "NotesZone", ownerName: "_abc123…"),
  database: .shared
)
```

Use ``CloudKitService/listZones(database:)`` to discover which zones a database has, and ``ZoneID/defaultZone`` when you want to name the default zone explicitly.

> Note: `zoneID` and `zoneWide` pull in opposite directions — `zoneWide: true` queries across *every* zone in the database, which makes `zoneID` moot. `zoneWide` is only valid against the private and shared databases.

## Creating

Use ``CloudKitService/createRecord(recordType:recordName:fields:encryptedFields:zoneID:database:)`` for a single create. Fields are a `[String: FieldValue]` dictionary — every CloudKit scalar plus references, locations, assets, and lists are modeled in ``FieldValue``:

```swift
let article = try await service.createRecord(
  recordType: "Article",
  fields: [
    "title": .string(.value("Hello, CloudKit")),
    "body": .string(.value("First post.")),
    "wordCount": .int64(2),
    "publishedDate": .date(Date())
  ],
  database: .private
)
```

Omit `recordName` to let CloudKit generate one; pass an explicit string when you need a stable identifier you can lookup later.

### Encrypted fields

A field declared `ENCRYPTED` in the container schema (for example `"secret" ENCRYPTED STRING`) is stored under the user's CloudKit service key and can only be written or read on the **private** and **shared** databases with **web-auth** credentials. Name such fields in `encryptedFields:` and MistKit sends the field dictionary with `isEncrypted: true` — and an explicit `type`, which CloudKit requires for encrypted values even where a plain write could leave it out:

```swift
let note = try await service.createRecord(
  recordType: "Note",
  fields: [
    "title": .string(.value("Grocery list")),
    "secret": .string(.value("door code 4471"))
  ],
  encryptedFields: ["secret"],
  database: .private
)
```

Nothing is encrypted on the client. The value travels as plaintext over TLS and Apple's servers encrypt it; on every read (`records/lookup`, `records/query`, `records/changes`) it comes back decrypted, and the names CloudKit flagged are in ``RecordInfo/encryptedFields``. What the flag buys is encryption at rest under a per-user key, and interoperability with a native app whose schema already marks the field `ENCRYPTED`; it does not hide the value from Apple.

Rules CloudKit enforces, and how they surface:

- **No filtering.** Encrypted fields have no index. A `filterBy` on one fails the whole query with ``CloudKitError/badRequest(reason:)`` — the reason reads `Field 'secret' has a value type of ENCRYPTED_STRING and cannot be queried using filter type EQUALS`. A `sortBy` on an encrypted field is accepted but has no meaningful order.
- **Not on the public database, not on references or assets.** MistKit rejects these before the request is sent, as ``CloudKitError/badRequest(reason:)``, because CloudKit only encrypts scalar and list values and the public database has no per-user keys. Assets are always encrypted in transit and at rest on their own.
- **Existing fields cannot be converted.** Only a new schema field can be declared `ENCRYPTED`. The schema declaration governs, and the request flag has to agree with it in both directions: writing `isEncrypted` to a field the schema declares plain fails with `Attempt to save encrypted data in non encrypted field type`, and omitting it on a field the schema declares `ENCRYPTED` fails with `invalid attempt to set value type ENCRYPTED_BYTES for field 'secret' for type 'Note', defined to be: ENCRYPTED_STRING`. Both arrive as a per-record ``CloudKitError/badRequest(reason:)``.
- **Advanced Data Protection.** A user who has turned on Advanced Data Protection cannot obtain a web-auth token at all, so none of this is reachable for them — see the note in <doc:AuthenticationAndDatabases>.

## Updating

Use ``CloudKitService/updateRecord(recordType:recordName:fields:recordChangeTag:encryptedFields:zoneID:database:)``. Pass `recordChangeTag` to opt into optimistic concurrency — CloudKit rejects the write if the record has been modified since you read it:

```swift
let updated = try await service.updateRecord(
  recordType: "Article",
  recordName: existing.recordName,
  fields: ["title": .string(.value("Hello, CloudKit (revised)"))],
  recordChangeTag: existing.recordChangeTag,
  database: .private
)
```

> Tip: Omitting `recordChangeTag` lets the write win unconditionally (last-writer-wins). Pass the tag whenever the user's intent depends on seeing the current state — collaborative editing, counters, anything where a stale read produces wrong results.

## Deleting

Use ``CloudKitService/deleteRecord(recordType:recordName:recordChangeTag:zoneID:database:)``:

```swift
try await service.deleteRecord(
  recordType: "Article",
  recordName: stale.recordName,
  database: .private
)
```

Pass `recordChangeTag` to refuse the delete if the record changed since you read it.

## Batching

When you need to create, update, and delete in one round-trip, use ``CloudKitService/modifyRecords(_:atomic:zoneID:desiredKeys:numbersAsStrings:database:)`` with an array of ``RecordOperation`` values. The convenience factories ``RecordOperation/create(recordType:recordName:fields:)``, ``RecordOperation/update(recordType:recordName:fields:recordChangeTag:)``, and ``RecordOperation/delete(recordType:recordName:recordChangeTag:)`` keep call sites readable:

```swift
let results = try await service.modifyRecords(
  [
    .create(
      recordType: "Article",
      fields: ["title": .string(.value("New"))]
    ),
    .update(
      recordType: "Article",
      recordName: "existing-id",
      fields: ["title": .string(.value("Renamed"))],
      recordChangeTag: existing.recordChangeTag
    ),
    .delete(
      recordType: "Article",
      recordName: "old-id"
    )
  ],
  atomic: true,
  database: .private
)
```

`modifyRecords` returns a ``RecordResult`` per operation — switch over each to handle per-record outcomes:

```swift
for result in results {
  switch result {
  case .success(let record): print("saved \(record.recordName)")
  case .failure(let error):  print("failed \(error.recordName): \(error.serverErrorCode.rawValue)")
  }
}
```

| `atomic:` | Behavior |
| --- | --- |
| `false` (default) | Per-operation success/failure. Successful ops commit; failed ops surface in the response. |
| `true` | All-or-nothing. If any op fails, none commit. |

Choose `atomic: true` when the operations are semantically linked (paired updates, a transactional rename) and `false` when independent operations are batched purely for throughput.

> Note: CloudKit caps batch size [around 200 operations per request](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/ModifyRecords.html). See <doc:CloudKitLimitsAndPerformance> for batching guidance.

## Looking up

Use ``CloudKitService/lookupRecords(recordNames:desiredKeys:database:)`` to fetch known records by name:

```swift
let results = try await service.lookupRecords(
  recordNames: ["article-001", "article-002", "article-003"],
  desiredKeys: ["title", "publishedDate"],
  database: .private
)
// Each entry is a `RecordResult`; a not-found name comes back as `.failure`.
let articles = results.compactMap(\.record)
```

Pass `desiredKeys` to limit which fields come back — useful for list views that only need a subset.

## Syncing via change tokens

For incremental sync — pulling only what changed since the last fetch — use ``CloudKitService/fetchRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:database:)`` (single page) or ``CloudKitService/fetchAllRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:maxPages:database:)`` (auto-paginated). The returned ``RecordChangesResult`` carries a fresh `syncToken` to persist for the next call:

```swift
var token: String? = loadStoredToken()
repeat {
  let result = try await service.fetchRecordChanges(
    syncToken: token,
    database: .private
  )
  process(result.records)
  token = result.syncToken
} while result.moreComing
saveToken(token)
```

The inline DocC on these methods carries fuller examples for initial-vs-incremental sync.

## Topics

### Read operations

- ``CloudKitService/queryRecords(_:limit:desiredKeys:continuationMarker:zoneID:zoneWide:numbersAsStrings:database:)``
- ``CloudKitService/queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:zoneID:database:)``
- ``CloudKitService/lookupRecords(recordNames:desiredKeys:database:)``

### Write operations

- ``CloudKitService/createRecord(recordType:recordName:fields:encryptedFields:zoneID:database:)``
- ``CloudKitService/updateRecord(recordType:recordName:fields:recordChangeTag:encryptedFields:zoneID:database:)``
- ``CloudKitService/deleteRecord(recordType:recordName:recordChangeTag:zoneID:database:)``
- ``CloudKitService/modifyRecords(_:atomic:zoneID:desiredKeys:numbersAsStrings:database:)``

### Sync

- ``CloudKitService/fetchRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:database:)``
- ``CloudKitService/fetchAllRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:maxPages:database:)``
- ``RecordChangesResult``

### Building filters and sorts

- ``QueryFilter``
- ``QuerySort``
- ``FieldValue``
- ``RecordOperation``
- ``RecordInfo``

## See Also

- <doc:FieldTypePolymorphism>
- <doc:CloudKitLimitsAndPerformance>
- <doc:HandlingErrors>
- <doc:AuthenticationAndDatabases>
