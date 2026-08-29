---
name: reference_cloudkit_zone_dictionary
description: "CloudKit's Zone Dictionary has exactly three keys (zoneID, syncToken, atomic) — isEager and zone create options do not exist"
metadata:
  node_type: memory
  type: reference
---

Verified against Apple's archived CloudKit Web Services Reference during issue #386 / PR #427.

**Zone Dictionary documents exactly three keys** ([Types.html](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Types.html)):

| Key | Apple's wording |
|-----|-----------------|
| `zoneID` | "The dictionary that identifies a record zone in the database" |
| `syncToken` | "The current point in the zone's change history." |
| `atomic` | "A Boolean value indicating whether this zone supports atomic operations." |

All four zone endpoints (`zones/list`, `zones/lookup`, `zones/modify`, `zones/changes`) route their **success** payload through this dictionary, and their **failure** payload through the "Zone Fetch Error Dictionary" (`zoneID`, `reason`, `serverErrorCode`, `retryAfter`, `redirectURL`).

**Things that do NOT exist — do not add them speculatively:**

- **`isEager`** — appears in no primary Apple source, nor in `.claude/docs/webservices.md` or `.claude/docs/cloudkitjs.md`. It was proposed in issue #386 but is unsourced.
- **`atomic` on the `zones/modify` request** — the request body is `operations` only. `records/modify` *does* document `atomic`; the asymmetry is deliberate.
- **Zone create options on `ZoneOperation`** — the operation's `zone` is documented as having "a single `zoneID` key".

**Open discrepancies (unresolved, see issue #386 comment):**

- `zones/changes` documents its token key as **`metaSyncToken`** in both request and response; MistKit sends/reads `syncToken`. Apple's page contradicts itself (the `moreComing` description refers back to "the included `syncToken` key"), so this needs a live-response check before changing.
- `zones/changes` is documented as **deprecated** in favor of `changes/database`.

Note `ZoneID`'s owner key: Apple documents `ownerRecordName`, while MistKit's `ZoneID` domain type calls it `ownerName` and the wire schema uses `ownerName`. Related: [[reference_cloudkit_archived_endpoints]].
