# Working with Records

CRUD, batch, and lookup against CloudKit records — the operations you'll reach for most often, with idiomatic ``CloudKitService`` snippets.

## Overview

``CloudKitService`` exposes the CloudKit record lifecycle as a handful of focused async methods. This article walks the full surface so you can pick the right one without reading every operation file. For per-method examples, see the inline DocC on each method; for sync-via-change-tokens, see the linked sync section at the end; for limits and performance, see <doc:CloudKitLimitsAndPerformance>.

## Querying

Use ``CloudKitService/queryRecords(_:limit:desiredKeys:continuationMarker:zoneID:zoneWide:numbersAsStrings:database:)`` for a single page of results. Filters are built with ``QueryFilter`` factories, sorts with ``QuerySort/ascending(_:)`` / ``QuerySort/descending(_:)``:

```swift
let result = try await service.queryRecords(
  Query(
    recordType: "Article",
    filters: [
      .greaterThan("publishedDate", .date(oneWeekAgo)),
      .equals("status", .string("published"))
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

Use ``CloudKitService/createRecord(recordType:recordName:fields:database:)`` for a single create. Fields are a `[String: FieldValue]` dictionary — every CloudKit scalar plus references, locations, assets, and lists are modeled in ``FieldValue``:

```swift
let article = try await service.createRecord(
  recordType: "Article",
  fields: [
    "title": .string("Hello, CloudKit"),
    "body": .string("First post."),
    "wordCount": .int64(2),
    "publishedDate": .date(Date())
  ],
  database: .private
)
```

Omit `recordName` to let CloudKit generate one; pass an explicit string when you need a stable identifier you can lookup later.

## Updating

Use ``CloudKitService/updateRecord(recordType:recordName:fields:recordChangeTag:database:)``. Pass `recordChangeTag` to opt into optimistic concurrency — CloudKit rejects the write if the record has been modified since you read it:

```swift
let updated = try await service.updateRecord(
  recordType: "Article",
  recordName: existing.recordName,
  fields: ["title": .string("Hello, CloudKit (revised)")],
  recordChangeTag: existing.recordChangeTag,
  database: .private
)
```

> Tip: Omitting `recordChangeTag` lets the write win unconditionally (last-writer-wins). Pass the tag whenever the user's intent depends on seeing the current state — collaborative editing, counters, anything where a stale read produces wrong results.

## Deleting

Use ``CloudKitService/deleteRecord(recordType:recordName:recordChangeTag:database:)``:

```swift
try await service.deleteRecord(
  recordType: "Article",
  recordName: stale.recordName,
  database: .private
)
```

Pass `recordChangeTag` to refuse the delete if the record changed since you read it.

## Batching

When you need to create, update, and delete in one round-trip, use ``CloudKitService/modifyRecords(_:atomic:database:)`` with an array of ``RecordOperation`` values. The convenience factories ``RecordOperation/create(recordType:recordName:fields:)``, ``RecordOperation/update(recordType:recordName:fields:recordChangeTag:)``, and ``RecordOperation/delete(recordType:recordName:recordChangeTag:)`` keep call sites readable:

```swift
let results = try await service.modifyRecords(
  [
    .create(
      recordType: "Article",
      fields: ["title": .string("New")]
    ),
    .update(
      recordType: "Article",
      recordName: "existing-id",
      fields: ["title": .string("Renamed")],
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

> Note: CloudKit caps batch size around 200 operations per request. See <doc:CloudKitLimitsAndPerformance> for batching guidance.

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

For incremental sync — pulling only what changed since the last fetch — use ``CloudKitService/fetchRecordChanges(zoneID:syncToken:resultsLimit:database:)`` (single page) or ``CloudKitService/fetchAllRecordChanges(recordType:syncToken:)`` (auto-paginated). The returned ``RecordChangesResult`` carries a fresh `syncToken` to persist for the next call:

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

- ``CloudKitService/createRecord(recordType:recordName:fields:database:)``
- ``CloudKitService/updateRecord(recordType:recordName:fields:recordChangeTag:database:)``
- ``CloudKitService/deleteRecord(recordType:recordName:recordChangeTag:database:)``
- ``CloudKitService/modifyRecords(_:atomic:database:)``

### Sync

- ``CloudKitService/fetchRecordChanges(zoneID:syncToken:resultsLimit:database:)``
- ``CloudKitService/fetchAllRecordChanges(recordType:syncToken:)``
- ``RecordChangesResult``

### Building filters and sorts

- ``QueryFilter``
- ``QuerySort``
- ``FieldValue``
- ``RecordOperation``
- ``RecordInfo``

### See Also

- <doc:CloudKitLimitsAndPerformance>
- <doc:HandlingErrors>
- <doc:AuthenticationAndDatabases>
