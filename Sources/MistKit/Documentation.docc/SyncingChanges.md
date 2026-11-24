# Syncing Changes

Manage record zones and keep a local copy of a database current by fetching only what changed since your last sync.

## Overview

CloudKit tracks changes per *record zone*. Each zone keeps its own change history, and a sync token marks a point in it: hand the token back and CloudKit returns only what happened after that point. An incremental sync is therefore a matter of remembering tokens, not of re-querying every record.

The workflow has two levels:

1. **Which zones changed?** ``CloudKitService/fetchDatabaseChanges(syncToken:resultsLimit:database:)`` (`changes/database`) takes one database-wide token and reports the zones that changed or were deleted.
2. **What changed in them?** ``CloudKitService/fetchRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:database:)`` (`changes/zone`) takes one token *per zone* and reports the records that were created, updated or deleted.

This article covers that workflow and the zone management underneath it. For how the auto-paginating variants of these calls page, stop and report `maxPages`, see <doc:BatchingAndPagination>.

> Important: CloudKit only tracks changes in custom zones. `changes/zone` and `records/changes` are rejected for `_defaultZone`, so data you want to sync incrementally belongs in a zone you created.

## Zones

A zone is identified by a ``ZoneID``: a zone name plus an optional ``ZoneID/ownerName``. Where zones live depends on the database:

| Database | Zones |
| --- | --- |
| `.public(_:)` | Only `_defaultZone` (``ZoneID/defaultZone``). Zones can't be created or deleted. |
| `.private` | `_defaultZone` plus the custom zones the signed-in user creates. |
| `.shared` | Zones other users have shared with the signed-in user. Each one's `ownerName` is the sharing user's record name. |

Leave `ownerName` `nil` for your own zones. For a zone in the shared database, keep the owner CloudKit reports — the same zone name can belong to more than one user. A zone ID that CloudKit returns also carries a ``ZoneID/zoneType``, which one you build from a name doesn't, so compare zones by ``ZoneID/normalized`` (or ``ZoneInfo/id``) rather than with `==` on raw zone IDs.

### Listing and looking up zones

``CloudKitService/listZones(database:)`` returns every zone in a database in one response; `zones/list` has no pagination. ``CloudKitService/lookupZones(zoneIDs:database:)`` fetches specific zones by ID:

```swift
let allZones = try await service.listZones(database: .private)
for zone in allZones {
  print(zone.zoneName, zone.isAtomic ? "atomic" : "non-atomic")
}

let zones = try await service.lookupZones(
  zoneIDs: [ZoneID(zoneName: "Notes"), ZoneID(zoneName: "Attachments")],
  database: .private
)
```

Each result is a ``ZoneInfo``. Alongside the name and owner it carries the zone metadata CloudKit documents in its zone dictionary:

- ``ZoneInfo/syncToken`` — the zone's current point in its change history.
- ``ZoneInfo/atomic`` — whether commits to the zone are all-or-nothing. It is `nil` when the response leaves the key out; MistKit deliberately does not default it to `false`, so "absent" and "explicitly not atomic" stay distinguishable. ``ZoneInfo/isAtomic`` gives the safe reading (`atomic ?? false`).
- ``ZoneInfo/deleted`` — `true` on a tombstone from the change feed (see below). Like `atomic`, it stays `nil` when the key is absent rather than defaulting to `false`.

Both metadata fields are optional and are `nil` on `changes/database` entries, which carry only the zone ID and the `deleted` flag. MistKit doesn't model zone capabilities: ``ZoneInfo/capabilities`` is always empty.

### Creating and deleting zones

``CloudKitService/modifyZones(_:database:)`` creates and deletes zones in one `zones/modify` request. A ``ZoneOperation`` is either `.create` or `.delete` with a zone ID; there are no other per-zone options. Because the public database has only `_defaultZone`, MistKit rejects a `.public` target before sending anything.

A batch can partly fail — say, one delete names a zone that doesn't exist. CloudKit reports that inline, so the result is one ``ZoneChangeResult`` per zone, in response order: `.success` with the ``ZoneInfo`` CloudKit returned, or `.failure` with a ``ZoneOperationFailure`` carrying the zone name, `serverErrorCode` and `reason`. The array's `zones` and `failures` properties split the two:

```swift
let results = try await service.modifyZones(
  [
    .create(ZoneID(zoneName: "Notes")),
    .create(ZoneID(zoneName: "Attachments")),
    .delete(ZoneID(zoneName: "Scratch"))
  ],
  database: .private
)
for zone in results.zones {
  print("ok: \(zone.zoneName)")
}
for failure in results.failures {
  print("\(failure.zoneName): \(failure.serverErrorCode) \(failure.reason ?? "")")
}
```

For a single zone, ``CloudKitService/createZone(zoneName:ownerRecordName:database:)`` and ``CloudKitService/deleteZone(zoneName:ownerRecordName:database:)`` call ``OperationResult/get()`` on the entry, so a rejected operation throws ``CloudKitError/zoneOperationFailed(_:)`` carrying the same failure:

```swift
let notes = try await service.createZone(zoneName: "Notes", database: .private)

do {
  try await service.deleteZone(zoneName: "Scratch", database: .private)
} catch .zoneOperationFailed(let failure) where failure.serverErrorCode == .zoneNotFound {
  // Already gone — nothing to do.
}
```

Deleting a zone deletes every record in it.

## The sync workflow

### 1. Find the zones that changed

Pass the database token you stored last time — `nil` on the very first sync, which reports every zone — to ``CloudKitService/fetchAllDatabaseChanges(syncToken:resultsLimit:maxPages:database:)`` (or page by hand with ``CloudKitService/fetchDatabaseChanges(syncToken:resultsLimit:database:)``). Each entry is a ``ZoneChangeResult``:

- `.success` with ``ZoneInfo/deleted`` `true` — a tombstone: the zone was deleted. Drop its local data and its stored zone token.
- `.success` otherwise — the zone has changes to fetch.
- `.failure` — CloudKit couldn't report on that zone. The other entries are still delivered.

### 2. Fetch the records that changed in them

Send one ``ZoneChangesRequest`` per changed zone, each carrying *that zone's* stored token (`nil` for a zone you haven't synced before). ``CloudKitService/fetchAllRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:maxPages:database:)`` returns a ``RecordZoneChangesResult`` with one entry per zone. Each success is a ``ZoneRecordChanges``: the zone's changed records and its new ``ZoneRecordChanges/syncToken``.

A changed record arrives as a ``RecordInfo``. A deleted one arrives as a tombstone: ``RecordInfo/deleted`` is `true` and ``RecordInfo/recordType`` is `nil`, so key your local delete on the record name and zone.

### 3. Save tokens only after the changes are stored

A token says "everything up to here has been applied". Save it only once the changes it covers are committed locally; if the process dies in between, the next sync re-fetches them, and applying a change twice is harmless when your store upserts by record name.

The same reasoning orders the two token levels. Save a zone's token as soon as that zone's records are stored, but advance the *database* token only when every changed zone succeeded. If a zone failed and the database token moved past it, the next `changes/database` call would no longer report it, and its changes would be stranded. Keeping the old database token makes the next sync list the zone again — and the zones that did succeed only cost a cheap, already-current fetch.

### A complete sync loop

The following keeps the tokens in a `Codable` value saved next to the local data, and runs one incremental pass:

```swift
struct SyncState: Codable {
  var databaseToken: String?
  var zoneTokens: [ZoneID: String] = [:]
}

protocol LocalStore {
  func upsert(_ record: RecordInfo, in zone: ZoneID) async throws
  func deleteRecord(named recordName: String, in zone: ZoneID) async throws
  func deleteZone(_ zone: ZoneID) async throws
}

func sync(
  _ service: CloudKitService,
  database: Database,
  state: inout SyncState,
  store: some LocalStore
) async throws {
  // 1. Which zones changed since the stored database token?
  let (zoneResults, databaseToken) = try await service.fetchAllDatabaseChanges(
    syncToken: state.databaseToken,
    database: database
  )

  var changedZones: [ZoneID] = []
  var allZonesSucceeded = true
  for result in zoneResults {
    switch result {
    case .success(let zone) where zone.deleted == true:
      try await store.deleteZone(zone.id)
      state.zoneTokens[zone.id] = nil
    case .success(let zone):
      if !changedZones.contains(zone.id) {
        changedZones.append(zone.id)
      }
    case .failure(let failure):
      print("zone \(failure.zoneName) not reported: \(failure.serverErrorCode)")
      allZonesSucceeded = false
    }
  }

  // 2. What changed inside them, each zone from its own token?
  if !changedZones.isEmpty {
    let changes = try await service.fetchAllRecordZoneChanges(
      zones: changedZones.map { zoneID in
        ZoneChangesRequest(zoneID: zoneID, syncToken: state.zoneTokens[zoneID])
      },
      database: database
    )
    for result in changes.zones {
      switch result {
      case .success(let zoneChanges):
        let zoneID = zoneChanges.zone.id
        for record in zoneChanges.records {
          if record.deleted {
            try await store.deleteRecord(named: record.recordName, in: zoneID)
          } else {
            try await store.upsert(record, in: zoneID)
          }
        }
        // 3a. This zone is stored; its token can move.
        state.zoneTokens[zoneID] = zoneChanges.syncToken
      case .failure(let failure):
        print("zone \(failure.zoneName) failed: \(failure.serverErrorCode)")
        allZonesSucceeded = false
      }
    }
  }

  // 3b. Advance the database token only when no zone was left behind.
  if allZonesSucceeded {
    state.databaseToken = databaseToken
  }
}
```

Load the state, run a pass, and write the state back only when the pass returns:

```swift
var state =
  (try? JSONDecoder().decode(SyncState.self, from: Data(contentsOf: stateURL)))
  ?? SyncState()

try await sync(service, database: .private, state: &state, store: store)
try JSONEncoder().encode(state).write(to: stateURL, options: .atomic)
```

If anything throws — a network error, a throttle, a failure in your store — the state on disk is untouched and the next run starts from the last completed pass. MistKit never retries; to retry `THROTTLED` or `TRY_AGAIN_LATER`, check ``CloudKitError/isRetryable`` and ``CloudKitError/retryAfter`` as described in <doc:HandlingErrors>.

The same loop should sync the zones other users have shared with you when run with `database: .shared` (MistDemo has confirmed `changes/zone` there; `changes/database` on `.shared` is not yet live-verified); the zone IDs it stores then carry the owner's name. Zones only appear there after the user accepts the share, for example with ``CloudKitService/acceptShares(_:)``.

### Saving progress page by page

``CloudKitService/fetchAllRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:maxPages:database:)`` collects every page before returning, which is a lot to hold — and to lose — on a first sync of a large zone. To store and checkpoint as you go, call ``CloudKitService/fetchRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:database:)`` yourself and save the zone's token after each page:

```swift
var token = state.zoneTokens[zoneID]
while true {
  let page = try await service.fetchRecordZoneChanges(
    zones: [ZoneChangesRequest(zoneID: zoneID, syncToken: token)],
    resultsLimit: 200,
    database: .private
  )
  guard let entry = page.zones.first else { break }
  let zoneChanges = try entry.get()  // throws CloudKitError.zoneOperationFailed

  for record in zoneChanges.records {
    if record.deleted {
      try await store.deleteRecord(named: record.recordName, in: zoneID)
    } else {
      try await store.upsert(record, in: zoneID)
    }
  }

  let madeProgress = !zoneChanges.records.isEmpty || zoneChanges.syncToken != token
  token = zoneChanges.syncToken
  state.zoneTokens[zoneID] = token
  try JSONEncoder().encode(state).write(to: stateURL, options: .atomic)

  guard zoneChanges.moreComing, madeProgress else { break }
}
```

The `madeProgress` check is the same stuck-token guard the auto-paginators apply.

## Syncing a single zone with records/changes

When you already know which zone to follow, ``CloudKitService/fetchRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:database:)`` (`records/changes`) skips the database level: one zone, one token, and a ``RecordChangesResult`` of records (tombstones included), a new `syncToken`, and `moreComing`. ``CloudKitService/fetchAllRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:maxPages:database:)`` follows `moreComing` for you. MistDemo's `fetch-changes` command is built on this pair:

```swift
let (records, newToken) = try await service.fetchAllRecordChanges(
  zoneID: ZoneID(zoneName: "Notes"),
  syncToken: storedToken,
  desiredRecordTypes: ["Note"],
  database: .private
)
```

`zoneID` defaults to `_defaultZone`, which CloudKit doesn't track — always pass a custom zone. `desiredKeys` and `desiredRecordTypes` narrow what each fetch returns.

## The deprecated zones/changes endpoint

``CloudKitService/fetchZoneChanges(syncToken:database:)`` wraps `zones/changes`, which Apple deprecated in favor of `changes/database`. It answers the same "which zones changed" question but returns a ``ZoneChangesResult`` with no per-zone failures and no `resultsLimit`. Its token travels on the wire as `metaSyncToken` rather than `syncToken`; MistKit handles the rename, and the Swift name stays `syncToken`. Use ``CloudKitService/fetchDatabaseChanges(syncToken:resultsLimit:database:)`` instead.

## Topics

### Zones

- ``ZoneID``
- ``ZoneInfo``
- ``ZoneType``
- ``ZoneOperation``
- ``ZoneChangeResult``
- ``ZoneOperationFailure``

### Zone operations

- ``CloudKitService/listZones(database:)``
- ``CloudKitService/lookupZones(zoneIDs:database:)``
- ``CloudKitService/modifyZones(_:database:)``
- ``CloudKitService/createZone(zoneName:ownerRecordName:database:)``
- ``CloudKitService/deleteZone(zoneName:ownerRecordName:database:)``

### Change feeds

- ``CloudKitService/fetchDatabaseChanges(syncToken:resultsLimit:database:)``
- ``CloudKitService/fetchAllDatabaseChanges(syncToken:resultsLimit:maxPages:database:)``
- ``CloudKitService/fetchRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:database:)``
- ``CloudKitService/fetchAllRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:maxPages:database:)``
- ``CloudKitService/fetchRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:database:)``
- ``CloudKitService/fetchAllRecordChanges(zoneID:syncToken:resultsLimit:desiredKeys:desiredRecordTypes:maxPages:database:)``
- ``CloudKitService/fetchZoneChanges(syncToken:database:)``

### Change results

- ``DatabaseChangesResult``
- ``ZoneChangesRequest``
- ``RecordZoneChangesResult``
- ``ZoneRecordChanges``
- ``ZoneRecordChangesResult``
- ``RecordChangesResult``
- ``ZoneChangesResult``
- ``OperationResult``

## See Also

- <doc:BatchingAndPagination>
- <doc:WorkingWithRecords>
- <doc:HandlingErrors>
