---
name: reference_cloudkit_zone_dictionary
description: "CloudKit Zone Dictionary keys — archived docs plus live-confirmed extensions (issue #444)"
metadata:
  node_type: memory
  type: reference
---

Verified against Apple's archived CloudKit Web Services Reference during issue #386 / PR #427, with live-response confirmation for additional keys in issue #444.

**Zone Dictionary — archived docs** ([Types.html](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Types.html)):

| Key | Apple's wording |
|-----|-----------------|
| `zoneID` | "The dictionary that identifies a record zone in the database" |
| `syncToken` | "The current point in the zone's change history." |
| `atomic` | "A Boolean value indicating whether this zone supports atomic operations." |

**Live-confirmed additions (issue #444)** — present on change feeds (`zones/changes`, `changes/database`) but absent from the archived Zone Dictionary page:

| Key | Location | Notes |
|-----|----------|-------|
| `deleted` | Zone object (not inside `zoneID`) | `true` = tombstone; sync clients must observe this |
| `zoneType` | Inside `zoneID` | Observed values: `REGULAR_CUSTOM_ZONE`, `DEFAULT_ZONE` |

**Zone ID Dictionary** — wire key is `ownerRecordName`, **not** `ownerName`:

| Key | Description |
|-----|-------------|
| `zoneName` | Required. Default `_defaultZone`. |
| `ownerRecordName` | Zone owner's user record name (shared zones). |
| `zoneType` | Optional. `REGULAR_CUSTOM_ZONE` or `DEFAULT_ZONE` on live responses. |

MistKit's domain `ZoneID` keeps the Swift property name `ownerName`; only the wire key is `ownerRecordName`.

All four zone endpoints (`zones/list`, `zones/lookup`, `zones/modify`, `zones/changes`) route their **success** payload through the Zone dictionary, and their **failure** payload through the "Zone Fetch Error Dictionary" (`zoneID`, `reason`, `serverErrorCode`, `retryAfter`, `redirectURL`).

**Things that do NOT exist — do not add them speculatively:**

- **`isEager`** — appears in no primary Apple source, nor in `.claude/docs/webservices.md` or `.claude/docs/cloudkitjs.md`. It was proposed in issue #386 but is unsourced.
- **`atomic` on the `zones/modify` request** — the request body is `operations` only. `records/modify` *does* document `atomic`; the asymmetry is deliberate.
- **Zone create options on `ZoneOperation`** — the operation's `zone` is documented as having "a single `zoneID` key".

**Resolved discrepancies:**

- `zones/changes` token key is `metaSyncToken` on the wire (issue #430); Swift-facing names unchanged.
- `ownerRecordName` is the wire key for the zone owner (issue #444); the mistaken `ownerName` key never decoded live responses.

Note `zones/changes` is documented as **deprecated** in favor of `changes/database`. Related: [[reference_cloudkit_archived_endpoints]].
