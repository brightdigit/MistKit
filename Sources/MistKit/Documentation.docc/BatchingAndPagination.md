# Batching and Pagination

Work past CloudKit's 200-item-per-request limit and page through large result sets with MistKit's chunking and auto-paginating methods.

## Overview

CloudKit Web Services caps most batch endpoints at 200 items per request, exposed as ``CloudKitService/maxRecordsPerRequest``. MistKit pairs each capped single-request primitive with a convenience that does the splitting or the paging for you:

| Primitive (one request) | Convenience | Kind |
| --- | --- | --- |
| ``CloudKitService/modifyRecords(_:atomic:zoneID:desiredKeys:numbersAsStrings:database:)`` | ``CloudKitService/modifyAllRecords(_:atomicZones:database:batchSize:)`` | Client-side chunking, grouped by zone |
| ``CloudKitService/lookupRecords(recordNames:desiredKeys:zoneID:database:)`` | ``CloudKitService/lookupAllRecords(recordNames:desiredKeys:zoneID:database:batchSize:)`` | Client-side chunking |
| ``CloudKitService/discoverUserIdentities(lookupInfos:)`` | ``CloudKitService/discoverAllUserIdentities(lookupInfos:batchSize:)`` | Client-side chunking |
| ``CloudKitService/queryRecords(_:limit:desiredKeys:continuationMarker:zoneID:zoneWide:numbersAsStrings:database:)`` | ``CloudKitService/queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:zoneID:database:)``, ``CloudKitService/queryRecordPages(_:limit:desiredKeys:continuationMarker:zoneID:database:)`` | Server-driven pagination (`continuationMarker`) |
| ``CloudKitService/fetchRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:database:)`` | ``CloudKitService/fetchAllRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:maxPages:database:)`` | Server-driven pagination (`moreComing`) |
| ``CloudKitService/fetchDatabaseChanges(syncToken:resultsLimit:database:)`` | ``CloudKitService/fetchAllDatabaseChanges(syncToken:resultsLimit:maxPages:database:)`` | Server-driven pagination (`moreComing`) |
| ``CloudKitService/fetchRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:database:)`` | ``CloudKitService/fetchAllRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:maxPages:database:)`` | Server-driven pagination, per zone |

The two kinds differ in how they stop. Chunking splits an input you already hold, so the number of requests is `ceil(count / batchSize)`, fixed before the first one is sent; there is nothing to run away and no `maxPages`. Pagination follows a marker or token the server hands back, so every auto-paginator carries a `maxPages` ceiling (default `1_000`) and a stuck-marker or stuck-token guard.

All of these send requests one at a time, check for task cancellation before each request, and never retry. For the per-request limits themselves, see <doc:CloudKitLimitsAndPerformance>; for the basic record operations these build on, see <doc:WorkingWithRecords>.

## Writing more than 200 records

``CloudKitService/modifyRecords(_:atomic:zoneID:desiredKeys:numbersAsStrings:database:)`` sends one `records/modify` request against one zone, and CloudKit rejects more than 200 operations in it. ``CloudKitService/modifyAllRecords(_:atomicZones:database:batchSize:)`` takes any number of operations, across any number of zones.

Each operation is wrapped in a ``ZonedRecordOperation`` that names its zone; omit the zone for the default zone:

```swift
let notesZone = ZoneID(zoneName: "NotesZone")

let operations: [ZonedRecordOperation] = drafts.map { draft in
  ZonedRecordOperation(
    .create(
      recordType: "Note",
      recordName: draft.id,
      fields: [
        "title": .string(.value(draft.title)),
        "tags": .string(.list(draft.tags))
      ]
    ),
    in: notesZone
  )
} + staleNames.map { name in
  ZonedRecordOperation(.delete(recordType: "Note", recordName: name))
}

let results = try await service.modifyAllRecords(
  operations,
  atomicZones: [notesZone],
  database: .private
)
print("saved \(results.records.count), failed \(results.failures.count)")
```

How the call is split:

- **Grouped by zone.** Zones are sent in the order they first appear in `operations`; within a zone, operations keep their input order. Zones are compared by ``ZoneID/normalized``, so a zone CloudKit reported back (carrying its type) matches one built from its name and owner.
- **Chunked per zone.** Each zone's operations are split into requests of at most `batchSize`, which defaults to ``CloudKitService/maxRecordsPerRequest`` and is clamped to `1...maxRecordsPerRequest`.
- **Results in send order.** The returned ``RecordResult`` array is grouped by zone in that same order, not in the input order. Per-record failures (`CONFLICT`, `NOT_FOUND`, …) come back as `.failure` entries and do not throw.

### Atomicity is per request, not per call

A zone listed in `atomicZones` has each of its requests sent with `atomic: true`. That makes each *request* all-or-nothing — not the zone as a whole, and never the whole call. A zone with 450 operations at the default batch size commits in three independent atomic steps; if the third fails, the first two stay committed. Only custom zones in a private database support atomic commits; the default zone ignores the flag.

If a set of operations must commit together, keep it in one zone and at or under `batchSize` operations.

### Nothing is sent if any request fails a client-side check

Before sending the first request, `modifyAllRecords` runs the same client-side checks ``CloudKitService/modifyRecords(_:atomic:zoneID:desiredKeys:numbersAsStrings:database:)`` runs, on *every* planned request. It finds a non-finite number without encoding, so each request is still encoded only once, when it is sent. If any operation fails, nothing is sent and nothing is saved. The failures caught this way are:

- a field holding a `NaN` or infinite `Double`, reported as ``CloudKitError/invalidFieldValue(recordName:fieldName:underlying:)`` naming the record and field;
- an encrypted field the target database can't take (for example any `encryptedFields` on the public database);
- an operation that can't be converted to the wire format.

The error is thrown wrapped in ``CloudKitError/modifyIncomplete(completed:unsent:underlying:)`` with `completed` empty and every operation in `unsent`. ``CloudKitError/recordName`` and ``CloudKitError/fieldName`` read through the wrapper to the offending record and field:

```swift
do {
  _ = try await service.modifyAllRecords(operations, database: .private)
} catch {
  if let record = error.recordName, let field = error.fieldName {
    logger.error("Rejected before sending: \(record).\(field)")
  }
}
```

### Resuming after a failure or cancellation

Once requests are going out, they are sent one at a time. When one throws — a network error, an HTTP error, a throttle — or the task is cancelled between requests, no later request is sent and the method throws ``CloudKitError/modifyIncomplete(completed:unsent:underlying:)``:

- `completed` — the ``RecordResult``s of every request that came back, in send order, including per-record failures.
- `unsent` — the failed request's operations followed by every later request's, as the ``ZonedRecordOperation``s you passed in.
- `underlying` — the error the failed request threw (a cancellation error when the task was cancelled).

Because `unsent` has the same type as the input, resuming is a second call with it:

```swift
var pending = operations
var saved: [RecordResult] = []

while !pending.isEmpty {
  do {
    saved += try await service.modifyAllRecords(
      pending,
      atomicZones: [notesZone],
      database: .private
    )
    pending = []
  } catch CloudKitError.modifyIncomplete(let completed, let unsent, let underlying)
    where underlying.isRetryable
  {
    saved += completed
    pending = unsent
    try await Task.sleep(for: .seconds(underlying.retryAfter ?? 5))
  }
}
```

`isRetryable`, `retryAfter`, `reason`, `httpStatusCode` and `serverErrorCode` on the wrapper read through to `underlying`, so the `where` clause above can also be written against the outer error. `isRetryable` is `true` only for `THROTTLED` and `TRY_AGAIN_LATER`; a network error or a cancellation falls through and is rethrown. MistKit itself never retries; bound the loop for production use.

> Important: The failed request's operations are reported as unsent, but CloudKit may have applied some or all of them — for example when the connection drops after the request was sent. When you re-send them, expect `CONFLICT` (or `EXISTS` for a create) for a record that was in fact saved, and re-fetch it to find out.

See <doc:HandlingErrors> for the error cases in more detail.

## Looking up more than 200 records or users

``CloudKitService/lookupRecords(recordNames:desiredKeys:zoneID:database:)`` sends every name in one request, and CloudKit rejects more than 200 with `BAD_REQUEST`. ``CloudKitService/lookupAllRecords(recordNames:desiredKeys:zoneID:database:batchSize:)`` splits the names into batches and concatenates the results in input order:

```swift
let results = try await service.lookupAllRecords(
  recordNames: articleNames,  // any length
  desiredKeys: ["title", "publishedDate"],
  database: .public(.requires(.serverToServer))
)
let found = results.records    // `.success` entries
let missing = results.failures // e.g. NOT_FOUND
```

``CloudKitService/discoverAllUserIdentities(lookupInfos:batchSize:)`` does the same for `users/discover`. Like ``CloudKitService/discoverUserIdentities(lookupInfos:)``, it always runs against the public database with web-auth credentials and takes no `database:` parameter:

```swift
let identities = try await service.discoverAllUserIdentities(
  lookupInfos: emails.map { UserIdentityLookupInfo(emailAddress: $0) }
)
```

In both, `batchSize` defaults to ``CloudKitService/maxRecordsPerRequest`` and is clamped to `1...maxRecordsPerRequest`; an empty input sends no requests. A failing batch throws its ``CloudKitError`` and later batches are not sent; unlike `modifyAllRecords`, the error carries no partial results, since a lookup is safe to repeat.

The deprecated `users/lookup/email` and `users/lookup/id` wrappers have no chunking convenience — use `discoverAllUserIdentities(lookupInfos:batchSize:)` instead.

## Paging through query results

A `records/query` response holds at most 200 records and a `continuationMarker` for the next page. MistKit offers three ways to consume it.

**Everything at once.** ``CloudKitService/queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:zoneID:database:)`` follows the marker until it is `nil` and returns every record. The SwoopMistKit example uses it with `desiredKeys: []` to fetch just the names of the records that already exist before a sync:

```swift
let records = try await service.queryAllRecords(
  recordType: recordType,
  desiredKeys: [],
  database: .public(.prefers(.serverToServer))
)
let recordNames = Set(records.map(\.recordName))
```

When it reaches `maxPages` it throws ``CloudKitError/paginationLimitExceeded(maxPages:records:)`` carrying the records collected so far; <doc:CloudKitLimitsAndPerformance> covers how to respond.

**A page at a time, as a stream.** ``CloudKitService/queryRecordPages(_:limit:desiredKeys:continuationMarker:zoneID:database:)`` returns an `AsyncThrowingStream` of ``QueryResult`` pages. Use it to show progress, stream records into a table, or stop early without holding every record in memory:

```swift
var seen = 0
for try await page in service.queryRecordPages(
  Query(recordType: "AuditEvent", sortBy: [.descending("timestamp")]),
  limit: 200,
  database: .private
) {
  seen += page.records.count
  try await store(page.records)
  if seen >= 10_000 { break }
}
```

The stream has no `maxPages` ceiling. Breaking out of the loop, dropping the stream, or cancelling the consuming task cancels the request in flight and sends no more. An error ends the stream with a ``CloudKitError`` (the stream's failure type is `any Error` only because `AsyncThrowingStream` can't carry a typed failure). To resume after an error, start a new stream with `continuationMarker:` set to the last page's ``QueryResult/continuationMarker``.

**By hand.** Call ``CloudKitService/queryRecords(_:limit:desiredKeys:continuationMarker:zoneID:zoneWide:numbersAsStrings:database:)`` yourself and pass each page's `continuationMarker` into the next call. This is the only way to use `zoneWide` or `numbersAsStrings` across pages.

### The stuck-marker guard

If CloudKit answers with the same continuation marker it was sent, the next request would be identical and the loop would never end. Both auto-paginators stop instead of spinning: `queryAllRecords` stops at an empty page carrying the repeated marker, and `queryRecordPages` stops before such a page if it is empty, or yields it once and then finishes if it has records.

## Paging through changes

The change-feed endpoints paginate with a sync token and a `moreComing` flag rather than a continuation marker. Each auto-paginator has a `maxPages` ceiling (default `1_000`) and stops early on a stuck token — `moreComing: true` with nothing returned and an unchanged token.

| Method | Endpoint | Returns | At `maxPages` |
| --- | --- | --- | --- |
| ``CloudKitService/fetchAllRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:maxPages:database:)`` | `records/changes` | `(records:syncToken:)` | ``CloudKitError/paginationLimitExceeded(maxPages:records:)`` |
| ``CloudKitService/fetchAllDatabaseChanges(syncToken:resultsLimit:maxPages:database:)`` | `changes/database` | `(zones:syncToken:)` | ``CloudKitError/zonePaginationLimitExceeded(maxPages:zones:)`` |
| ``CloudKitService/fetchAllRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:maxPages:database:)`` | `changes/zone` | ``RecordZoneChangesResult`` | ``CloudKitError/paginationLimitExceeded(maxPages:records:)`` |

A response that reports `moreComing: true` with no sync token throws ``CloudKitError/invalidResponse`` from `fetchAllRecordChanges` and `fetchAllDatabaseChanges`, since there is no token to continue from.

### Which zones changed, then what changed in them

`changes/database` reports *which* zones changed; `changes/zone` reports the record changes inside them. A typical incremental sync of a private database chains the two:

```swift
let (zones, databaseToken) = try await service.fetchAllDatabaseChanges(
  syncToken: storedDatabaseToken,
  database: .private
)
for failure in zones.failures {
  logger.warning("zone \(failure.zoneName) failed: \(failure.serverErrorCode.rawValue)")
}

let changes = try await service.fetchAllRecordZoneChanges(
  zones: zones.zones.map { zone in
    ZoneChangesRequest(
      zoneID: zone.id,
      syncToken: storedZoneTokens[zone.zoneName]
    )
  },
  database: .private
)
for zone in changes.changes {
  apply(zone.records)
  storedZoneTokens[zone.zone.zoneName] = zone.syncToken
}
storedDatabaseToken = databaseToken
```

A failure on one zone is reported as a `.failure` entry rather than thrown, so it never discards the zones that succeeded.

### Per-zone pagination

`changes/zone` paginates each zone separately: every zone in a response carries its own sync token and `moreComing`. ``CloudKitService/fetchAllRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:maxPages:database:)`` therefore re-requests only the zones still reporting `moreComing`, each with its own latest token, and merges each zone's records across rounds into a single ``ZoneRecordChanges`` carrying that zone's final token. The result has one entry per requested zone, in input order. `maxPages` counts rounds, not zones, and a zone whose token gets stuck is dropped from the next round rather than looping.

## See Also

- <doc:WorkingWithRecords>
- <doc:CloudKitLimitsAndPerformance>
- <doc:HandlingErrors>
