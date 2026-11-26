# Sharing and Users

Identify the signed-in user, discover other users, and share records between iCloud accounts.

## Overview

Two groups of CloudKit endpoints act on behalf of a specific iCloud user rather than the container:

- **User identities** — `users/caller` and `users/discover` tell you who the signed-in user is and which other users are discoverable.
- **Sharing** — `records/modify` creates a share; `records/resolve` and `records/accept` let the invited user inspect and join it.

Every method in this article needs a web-auth token, because each one acts on behalf of a signed-in user. Most of them fix the database themselves and take no `database:` parameter:

| Method | Endpoint | Database |
| --- | --- | --- |
| ``CloudKitService/fetchCaller()`` | `users/caller` | Fixed: `.public(.requires(.webAuth))` |
| ``CloudKitService/discoverUserIdentities(lookupInfos:)`` | `users/discover` (POST) | Fixed: `.public(.requires(.webAuth))` |
| ``CloudKitService/discoverAllUserIdentities(lookupInfos:batchSize:)`` | `users/discover` (POST, chunked) | Fixed: `.public(.requires(.webAuth))` |
| ``CloudKitService/createShare(rootRecordType:rootRecordName:rootFields:zoneID:publicPermission:participants:database:)`` | `records/modify` (twice) | Yours: a custom zone, usually `.private` |
| ``CloudKitService/resolveShares(_:)`` | `records/resolve` | Fixed: `.public(.requires(.webAuth))` |
| ``CloudKitService/acceptShares(_:)`` | `records/accept` | Fixed: `.public(.requires(.webAuth))` |

The fixed methods throw ``CloudKitError/missingCredentials(database:availability:reason:)`` when the service's ``Credentials`` have no ``APICredentials/webAuthToken``. Server-to-server credentials can't stand in: CloudKit rejects them on these routes. See <doc:AuthenticationAndDatabases> for building credentials and obtaining a web-auth token. An iCloud account with Advanced Data Protection turned on can't obtain one at all; see <doc:AuthenticationAndDatabases#Web-auth-token-via-browser-redirect>.

All of these flows are exercised end to end by MistDemo's `test-private` integration run, which signs in as two different Apple IDs: a sharer that creates the share and a sharee that resolves, accepts and edits it.

## Identifying the signed-in user

``CloudKitService/fetchCaller()`` returns a ``UserInfo`` for the user whose web-auth token the service carries. It calls `users/caller`, which replaces Apple's deprecated `users/current`:

```swift
let me = try await service.fetchCaller()
print("Signed in as \(me.userRecordName)")
if let firstName = me.firstName, let lastName = me.lastName {
  print("Name: \(firstName) \(lastName)")
}
```

``UserInfo/userRecordName`` is the user's record name in the container's Users zone. It differs between containers, so it identifies a user within your app only. Before it shares anything, MistDemo compares the two users' record names to make sure the sharer and the sharee really are different accounts:

```swift
let sharer = try await sharerService.fetchCaller()
let sharee = try await shareeService.fetchCaller()
if sharer.userRecordName == sharee.userRecordName {
  // Same Apple ID on both sides: sign the sharee in with a different account.
}
```

## Discovering other users

``CloudKitService/discoverUserIdentities(lookupInfos:)`` sends one POST `users/discover` request. Each ``UserIdentityLookupInfo`` names a user by email address, phone number, or user record name:

```swift
let identities = try await service.discoverUserIdentities(
  lookupInfos: [
    UserIdentityLookupInfo(emailAddress: "ana@example.com"),
    UserIdentityLookupInfo(phoneNumber: "+15555550123"),
    UserIdentityLookupInfo(userRecordName: knownRecordName),
  ]
)

for identity in identities {
  switch identity.userRecordName {
  case .recordName(let recordName):
    let given = identity.nameComponents?.givenName ?? "?"
    print("\(given) is discoverable as \(recordName)")
  case .nonDiscoverable:
    print("\(identity.lookupInfo?.emailAddress ?? "?") is not discoverable")
  }
}
```

A user who hasn't made themselves discoverable in your container comes back without a record name. MistKit reports that as ``UserRecordName/nonDiscoverable`` rather than failing the call, and the identity still carries the ``UserIdentity/lookupInfo`` it was matched from. ``UserIdentity/nameComponents`` holds a ``NameComponents`` value (given name, family name, nickname and so on) when CloudKit returns one.

CloudKit caps a single `users/discover` request at ``CloudKitService/maxRecordsPerRequest`` lookup infos. ``CloudKitService/discoverAllUserIdentities(lookupInfos:batchSize:)`` takes any number, splits them into batches, and concatenates the results in input order:

```swift
let identities = try await service.discoverAllUserIdentities(
  lookupInfos: emails.map { UserIdentityLookupInfo(emailAddress: $0) }
)
```

<doc:BatchingAndPagination> covers how the chunking behaves when a batch fails.

``CloudKitService/lookupUsersByEmail(_:)`` and ``CloudKitService/lookupUsersByRecordName(_:)`` wrap `users/lookup/email` and `users/lookup/id`, which Apple deprecated in favor of `users/discover`. They have no chunking convenience. Use `discoverUserIdentities(lookupInfos:)` or `discoverAllUserIdentities(lookupInfos:batchSize:)` instead.

## Creating a share

A share is a `cloudkit.share` record that points at a root record and lists who may access it. ``CloudKitService/createShare(rootRecordType:rootRecordName:rootFields:zoneID:publicPermission:participants:database:)`` creates both records in two `records/modify` requests:

1. It creates the root record with `createShortGUID: true`, so CloudKit assigns it a short GUID and a stable URL.
2. It creates the `cloudkit.share` record in an atomic request, with `forRecord` naming the root record and its change tag, plus the public permission and the participants.

Sharing needs a custom zone. Apple's reference shares from a custom zone in the private database, and that is the path MistDemo verifies live. Create the zone first, then invite participants by lookup info:

```swift
let zoneID = ZoneID(zoneName: "SharedNotes")
_ = try await service.createZone(zoneName: zoneID.zoneName, database: .private)

let created = try await service.createShare(
  rootRecordType: "Note",
  rootFields: [
    "title": .string(.value("Trip planning"))
  ],
  zoneID: zoneID,
  publicPermission: .none,
  participants: [
    ShareParticipant(
      userIdentity: UserIdentity(
        lookupInfo: UserIdentityLookupInfo(emailAddress: "ana@example.com")
      ),
      permission: .readWrite,
      type: .user,
      acceptanceStatus: .invited
    )
  ],
  database: .private
)

print("Invite link: \(created.shareURL)")
```

When you leave out `rootRecordName`, MistKit generates one. The returned ``CreatedShare`` carries:

- ``CreatedShare/shortGUID`` — the ``ShortGUID`` the sharee needs to resolve and accept the share.
- ``CreatedShare/shareURL`` — the iCloud invite link, `https://www.icloud.com/share/{shortGUID}`.
- ``CreatedShare/share`` — a ``ShareInfo`` with the public permission, the participants, the owner, and the caller's own participation.
- ``CreatedShare/rootRecord`` and ``CreatedShare/shareRecordName`` — the two records that were written, which you need later to delete the share.

``SharePermission`` sets read and write access for the public and for each participant. ``ShareParticipantType`` and ``ShareAcceptanceStatus`` describe each participant's role and where they are in the invitation.

> Important: The share record type is `cloudkit.share`, with a lowercase `k`. Apple's archived CloudKit Web Services reference spells it `cloudKit.share`, and the live API rejects that spelling with `Cannot share - no such record exists to share`, even when the root record exists. MistKit uses ``ShareInfo/recordType``; use the same constant when you write a share record yourself, for example to delete it.

## Resolving and accepting a share

The sharee works from the short GUID, which you can pass along directly or take from the last path component of the invite URL. The sharee's own service, built with the sharee's web-auth token, resolves the share to see what it is, then accepts it:

```swift
let shortGUID = ShortGUIDDictionary(
  value: created.shortGUID,
  shouldFetchRootRecord: true,
  rootRecordDesiredKeys: ["title"]
)

let resolved = try await shareeService.resolveShares([shortGUID])
if let info = resolved.first {
  print("Owner: \(info.ownerIdentity?.nameComponents?.givenName ?? "?")")
  print("Status: \(info.participantStatus?.rawValue ?? "-")")
}

let accepted = try await shareeService.acceptShares([shortGUID])
if let info = accepted.first, info.participantStatus == .accepted {
  print("Joined \(info.rootRecordName ?? "?") in \(info.zoneID?.zoneName ?? "?")")
}
```

Both methods return one ``ShareRecordInfo`` per ``ShortGUIDDictionary``, in request order. ``ShortGUIDDictionary/shouldFetchRootRecord`` has CloudKit include the shared root record as ``ShareRecordInfo/rootRecord``, and ``ShortGUIDDictionary/rootRecordDesiredKeys`` limits which of its fields come back. Alongside the root, a result carries the `cloudkit.share` record (``ShareRecordInfo/share``, with its share keys lifted out into ``ShareRecordInfo/shareInfo``), the owner's ``ShareRecordInfo/ownerIdentity``, and the caller's own ``ShareRecordInfo/participantStatus``, ``ShareRecordInfo/participantPermission`` and ``ShareRecordInfo/participantType``.

Neither method takes a `database:` parameter. Apple's reference fixes both endpoints to the public database scope, and both act on behalf of the current user, so they always run as `.public(.requires(.webAuth))`.

CloudKit validates the request as a whole. A malformed or unknown short GUID, or one the caller has already accepted, fails the entire call with a ``CloudKitError``. There is no per-item failure entry like the ones ``RecordResult`` carries for `records/modify`, so send short GUIDs you can afford to fail together, or one per call.

### When the caller matches more than one invitation

CloudKit matches the caller to an invited participant by their contact details. When it can't match the caller to exactly one invitation, ``ShareRecordInfo/potentialMatchList`` is non-empty. Each ``SharePotentialMatch`` has a ``SharePotentialMatch/participantId`` and the ``ContactInformation`` CloudKit holds for it, so the user can choose which invitation they are claiming:

```swift
for match in info.potentialMatchList {
  let contact = match.contactInformation?.emailAddress ?? match.participantId
  print("Did you mean \(contact)?")
}
```

## Working in the shared zone

After accepting, the shared records appear in the sharee's **shared** database, in a zone owned by the sharer. Address it with a ``ZoneID`` that carries the owner's record name. The accept response's ``ShareRecordInfo/zoneID`` may omit the owner, so MistDemo falls back to the sharer's `users/caller` record name:

```swift
guard let acceptedZone = info.zoneID, let sharedRoot = info.rootRecord else {
  return
}
let sharedZoneID = ZoneID(
  zoneName: acceptedZone.zoneName,
  ownerName: acceptedZone.ownerName ?? sharerRecordName
)

let updated = try await shareeService.updateRecord(
  recordType: "Note",
  recordName: sharedRoot.recordName,
  fields: ["title": .string(.value("Trip planning (edited)"))],
  recordChangeTag: sharedRoot.recordChangeTag,
  zoneID: sharedZoneID,
  database: .shared
)
```

A sharee with `.readWrite` permission can modify the records in the share. Creating new top-level records in the sharer's zone fails with `ACCESS_DENIED`. Change tracking on the shared zone works the same way as on a private one: pass the same zone ID to ``CloudKitService/fetchRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:database:)`` with `database: .shared`.

## Topics

### User identities

- ``CloudKitService/fetchCaller()``
- ``CloudKitService/discoverUserIdentities(lookupInfos:)``
- ``CloudKitService/discoverAllUserIdentities(lookupInfos:batchSize:)``
- ``UserInfo``
- ``UserIdentity``
- ``UserIdentityLookupInfo``
- ``UserRecordName``
- ``NameComponents``
- ``ContactInformation``

### Creating shares

- ``CloudKitService/createShare(rootRecordType:rootRecordName:rootFields:zoneID:publicPermission:participants:database:)``
- ``CreatedShare``
- ``ShareInfo``
- ``ShareParticipant``
- ``SharePermission``
- ``ShareParticipantType``
- ``ShareAcceptanceStatus``

### Resolving and accepting shares

- ``CloudKitService/resolveShares(_:)``
- ``CloudKitService/acceptShares(_:)``
- ``ShortGUID``
- ``ShortGUIDDictionary``
- ``ShareRecordInfo``
- ``SharePotentialMatch``
- ``ShareDatabaseScope``

## See Also

- <doc:AuthenticationAndDatabases>
- <doc:BatchingAndPagination>
- <doc:WorkingWithRecords>
