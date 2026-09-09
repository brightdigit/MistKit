# What CloudKit Got Wrong

Where CloudKit Web Services itself was hard: the places Apple's documentation and Apple's server disagree, and the two subsystems whose difficulty shaped MistKit's architecture.

## Overview

This is a field guide to the parts of [CloudKit Web Services](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html) that cost real time, written from MistKit's issue tracker, its [`openapi.yaml`](https://github.com/brightdigit/MistKit/blob/main/openapi.yaml) annotations, and live runs against a development container. Its companion, <doc:WhatTheAIGotWrong>, asks the orthogonal question of how the *assistant* behaved while the library was being built; the two barely overlap.

The thesis, stated once:

> **Apple's documentation and Apple's live server disagree, and the server is not the one that gets corrected.**

Every significant finding below was settled by *running a request*, never by reading harder. The worst ones return **HTTP 200**: a wrong sync-token key is ignored rather than rejected, a mis-cased record type blames a different record, an unmodeled response key decodes to `nil`, a stale auth token keeps working. Nothing throws.

Its corollary: **when the archived REST reference and observed behavior disagree, [CloudKit JS](https://developer.apple.com/documentation/cloudkitjs)'s source is a primary oracle.** Reading `setApiModuleName("device")` in CloudKit JS is what cracked the APNs-token routing bug below, and CloudKit JS beat the archived reference more than once.

## Two kinds of hard

The documentation contradictions are the most dramatic findings, but each was hard **once** — a bad afternoon, then a line in the spec. Two subsystems were hard **continuously**, and they shaped the library: **authentication** and **field value types**. Both refuse to collapse their failure modes into a generic error, because CloudKit gives you no way to tell the cases apart afterwards.

## Authentication: the rules don't compose

Start with two record names. The same person writing the same public record produced two different creators:

- `_904181d1d76652d1f53581aec11cf76e` — written through CloudKit JS (web auth)
- `_aca0fa3547ae9f9cd1f7e25fed948a20` — written through MistKit (server-to-server)

**Your choice of signing method silently changes the record's creator.** Apple documents neither the behavior nor its consequence; it was found by writing the same record twice and noticing. Every line of ``PublicAuthPreference`` exists because of that observation.

The footgun is worse than the bug: a subscription created under server-to-server is **owned by the developer key**, so its pushes never usefully reach an end user's device.

### It is a 3 × 3 matrix with holes

Not "three auth methods". Auth and database scope are **not orthogonal**, which is exactly why they resisted being modeled as two independent parameters:

| Mode | Private | Shared | Public |
| --- | --- | --- | --- |
| API token only | not supported | not supported | whatever `_world` grants |
| Web auth | all endpoints | all endpoints | all endpoints — **only** mode accepted for `/users/*` |
| Server-to-server | rejected | rejected | all endpoints **except** `/users/*` |

Public accepts two methods, private and shared accept exactly one, and `/users/*` carves a hole *inside* the public column. MistKit's user-identity and sharing operations therefore hard-code `.public(.requires(.webAuth))` and expose **no** `database:` parameter — the API surface encodes the irregularity. Several earlier designs (a `DatabaseCredentials` enum baking in public ⇒ server-to-server, a service that carried its database, a defaulted `auth:` parameter) were each abandoned for a different reason before the payload ended up *inside* ``Database/public(_:)``, where the choice actually exists. See <doc:AuthenticationAndDatabases>.

### Signing is undocumented, and every mistake looks identical

The payload is exactly `"<iso8601Date>:<bodyHash>:<subpath>"`. Three traps, none documented:

- **A bodyless request hashes to the empty string** — not `SHA256("")`. Both are defensible; one works.
- **The ISO 8601 date must be stored as the string that was signed.** Re-formatting a `Date` on each header access risks a wire string that differs from the signed one.
- **Web auth tokens need a three-character percent-encoding map** (`+`, `/`, `=`) or CloudKit rejects them.

Every one of these produces the *same* generic `401`. CloudKit will not tell you which of the five inputs was wrong, so the debug loop is "change one thing, redeploy, observe the same error". <doc:RequestSigning> shows how each is handled.

There is also a protocol-level scar: ``Authenticator/authenticate(request:body:)`` takes `body: inout HTTPBody?` because `HTTPBody` is single-pass and hashing it consumes the iterator. The other two authenticators never mutate `body`; the signature exists for the one that must.

### The rotation gap

Apple documents web auth tokens as single-use: every response carries a new one and the previous one is invalid. The live server *rotates but does not invalidate* — a 25-hour-old token returned 200, and eight sequential reuses and six concurrent shares all returned 200. MistKit historically depended on that undocumented leniency.

The client-side gap is now closed: `AuthenticationMiddleware` reads `X-Apple-CloudKit-Web-Auth-Token` from each response and hands it to ``TokenManager/didReceiveRotatedWebAuthToken(_:)``. What remains is the doc-versus-server mismatch itself. Adopting the rotated token is defensive correctness, not something the live service currently forces — but if Apple ever enforces the written rule, clients that ignored the header would break immediately.

## Field value types: the wire is lossy by construction

Not "mapping dynamic JSON to Swift". The real problem:

> CloudKit tells you a field's type in an **optional** sibling key, next to a value drawn from a **nine-way union with no discriminator**, where three of the five scalars are structurally identical to another scalar. Reads get a `LIST` tag; writes need `STRING_LIST`. Booleans don't exist.

Generated decoding is first-match-wins (`String → Int64 → Double → Bytes → Date`), so a whole-millisecond `TIMESTAMP` arrives as `Int64Value` and a base64 `BYTES` as `StringValue`.

**It hid for a long time because reads worked.** CloudKit *supplies* the type in responses, so only writes broke — which is why the tagging bug surfaced as a production failure in a downstream app's CI rather than in a unit test:

```
Batch 1 failed: CloudKit record operation failed (BAD_REQUEST)
Reason: Invalid value, expected type TIMESTAMP.
Batch complete: 0/7 (0.0%)
```

And the fix came from a **2015 Apple Developer Forums thread**, not from Apple's documentation.

### Things a reader would not guess

- **Some values cannot round-trip.** `.date` and `.bytes` do not survive an untagged encode/decode; the information is not on the wire.
- **Lists are strictly worse than scalars.** The request enum has 17 values including eight `*_LIST` flavors; the response enum has 10, collapsing every list to a single `LIST`, and list elements carry no tag at all. A `[Date]` written as `TIMESTAMP_LIST` reads back as `[.int64]`.
- **Sub-millisecond precision is destroyed on every write.** CloudKit rejects a fractional `TIMESTAMP`, so values are rounded — including the nested `Location.timestamp`, a second millisecond field with no tag of its own, found only via a live CelestraCloud failure.
- **Schema strictness on one type is the only discriminator protecting another.** `LocationValue.latitude`/`longitude` are `required` in the spec *only* because, while they were optional, the undiscriminated `oneOf` greedily matched **assets as locations**. Loosen `Location` and `Asset` breaks.
- **`Bool` does not exist.** It is `INT64` `0`/`1`, so `.int64(1)` and `FieldValue(booleanValue: true)` are `==` with no way to recover the intent.
- **The obvious hypothesis about `IN` filters was wrong.** ``QueryFilter`` `IN` returned `400 BadRequestException: Unexpected input` at *every* array size — 97, 20, even 2. The natural guess (an undocumented size limit) was false; the cause was a missing list `type` tag.

### Fail-loud was genuinely contested

The conversion layer bets that a loud failure beats silently wrong data, but the boundary took months to settle: strictness first shipped for *scalars only*, deferring complex tags "to limit read-path regression risk", and a later issue argued the compromise was incoherent — *`TIMESTAMP` over a non-number throws, while `REFERENCE` over a non-object is silently coerced.* Complex tags are validated now. There are still three policies for a contradicting tag: throw (category mismatch), ignore the tag (a fractional `INT64` yields `.double`), and honor the tag (`TIMESTAMP`/`DOUBLE`/`BYTES`). <doc:FieldTypePolymorphism> has the rules.

## Documentation inconsistency: a taxonomy

"Docs versus server" is only one of five ways the documentation failed. Each has a different remedy:

| Kind | Example | Remedy |
| --- | --- | --- |
| **1. Docs vs. live server** | `metaSyncToken`; `/device/` routing; `cloudkit.share` casing; token rotation | Run a request. Nothing else works. |
| **2. Apple contradicting itself on one page** | The `zones/changes` page names `metaSyncToken` in its field table, then its own `moreComing` prose cites "the included `syncToken` key" | Neither reading is authoritative — go to (1) |
| **3. Apple contradicting Apple across sources** | Archived reference vs. CloudKit JS vs. Developer Forums | Know which source wins for which question |
| **4. Documentation that no longer exists** | `records/resolve`, `records/accept`, `assets/rereference` are documented **only** in the archive | Cite the archive; assume it won't be corrected |
| **5. Local copies being incomplete** | A saved export of the reference can look authoritative at hundreds of KB and still be missing whole endpoints | Never treat a zero-hit search as proof of absence |

**Kind 2 is the most corrosive, because it defeats careful reading.** The `zones/changes` reversal happened inside a single pull request: the first commit "fixed" the prose on the assumption the docs were merely worded badly, and a later commit on the same branch reversed it after a live run — *"this supersedes the description-only wording fix, which assumed the mismatch was documentation rather than behavior."*

## Where Apple's docs are actively wrong

| # | Finding | Receipt |
| --- | --- | --- |
| 1 | **`zones/changes` uses `metaSyncToken`, not `syncToken`.** The wrong key is *silently ignored* — page one replays forever, so pagination had **never** worked. Live proof: `syncToken` → 40 zones again; `metaSyncToken` → 0. Only this endpoint differs; `changes/database`, `changes/zone`, and `records/changes` genuinely use `syncToken`. | [#430](https://github.com/brightdigit/MistKit/issues/430) |
| 2 | **APNs tokens live under `/device/`, not `/database/`.** The documented path answers only `OPTIONS` and returns `405` on POST, with no `{database}` segment. Auth was ruled out by elimination across four passing endpoints; the answer came from [CloudKit JS](https://developer.apple.com/documentation/cloudkitjs)'s source. | [#382](https://github.com/brightdigit/MistKit/issues/382) |
| 3 | **`ownerRecordName` vs `ownerName` — zone owners never decoded.** Live `zones/list` returns `ownerRecordName`; the spec declared `ownerName`, so every zone read its owner back as `nil`. | [#444](https://github.com/brightdigit/MistKit/issues/444) |
| 4 | **`cloudkit.share`, not `cloudKit.share`.** One letter's case. The error — *"Cannot share - no such record exists to share"* — blames the root record, not the type string. | [#437](https://github.com/brightdigit/MistKit/issues/437) |
| 5 | **[`GET users/discover`](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/DiscoveringAllUserIdentities.html) is broken server-side at Apple** — a 100% reproducible `500`. Proving it was Apple's bug took a five-rung ladder: `OPTIONS` returns 200; a typo'd path returns a clean 404; `POST` reaches body validation; and Apple's own CloudKit JS fails identically from a browser. Filed as [Feedback FB22754466](https://feedbackassistant.apple.com/). | [#28](https://github.com/brightdigit/MistKit/issues/28) |

On #1: the recommendation *from documents alone* had been to close the issue as not planned, on a two-versus-one documentation count. Five words — "Can we run a quick test for this?" — reversed it. <doc:WhatTheAIGotWrong> tells the same episode from the collaboration side.

### Case study: the `/device/` bug

The whole thesis in one arc. Docs wrong → `404` → "fix" applied per the docs → `405` → auth ruled out by elimination across four endpoints that passed with identical credentials → answer found in CloudKit JS's source → live verification via `mistdemo test-private`. Apple's reference is archived and unlikely to be corrected, so the next person reading the docs will hit the same `405`; the OpenAPI document now carries the working path.

## Other traps worth knowing

- **`421 Misdirected Request` on asset upload.** The CDN and the API are different hosts; HTTP/2 connection reuse breaks it. A transport-layer trap invisible at the REST layer, which forced asset uploads onto a separate `URLSession` — see <doc:CloudKitLimitsAndPerformance>.
- **The query index is eventually consistent; `lookup` is not.** Create → immediate query returns **0 records**; three seconds later it returns them; `lookup` by name returns them immediately.
- **A read gives you an asset you cannot re-attach.** Three of six fields come back; the writable ones come only from the upload step or `assets/rereference`, which is absent from the current documentation entirely.
- **Subscription uniqueness is keyed on `(recordType, firesOn)`, not `subscriptionID`.** The same ID twice *succeeds*; uniqueness is exact-set match, not overlap; and a duplicate surfaces as a generic `INTERNAL_ERROR` with no `CONFLICT` code. MistKit detects it by matching Apple's prose string, which breaks silently if Apple rewords it — see <doc:HandlingErrors>.
- **Per-zone partial failure.** `changes/database`, `changes/zone`, and [`zones/modify`](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/ModifyZones.html) return success-or-failure *per zone*, and the failure variant must be listed **first** in each `oneOf` or the permissive success schema swallows it.
- **`modifyRecords` never reports create-versus-update.** The only workable approach is a pre-fetch plus client-side classification — roughly 600 ms extra per sync in BushelCloud's measured case.

## Still open

Live-verified through MistDemo (the web UI plus `test-public` / `test-private`) and therefore no longer open: token rotation handling, `records/resolve` / `records/accept` / share creation, `ASSETID` / `assets/rereference`, `users/caller` routing, `ownerRecordName` on responses and `ownerName` in shared-zone requests.

Still open on Apple's side, or as research gaps:

- `GET users/discover` still returns `500`. The MistKit issue is closed as a [Feedback Assistant](https://feedbackassistant.apple.com/) filing; the operation is generated from the spec but not surfaced by ``CloudKitService``.
- Whether a `database` subscription type exists; the full `zoneType` enum; and the fact that subscriptions cannot configure alert, badge, or sound at all (no `NotificationInfo` schema in the reference).

## Limitations

- All observations come from one container and environment (`iCloud.com.brightdigit.MistDemo`, development). Behavior may differ in production or on other containers.
- Several findings are one-shot live observations rather than regression-tested facts.
- Some facts predate the project's memory conventions and survive only as source comments, so their discovery context is lost.

## See Also

- <doc:AuthenticationAndDatabases>
- <doc:RequestSigning>
- <doc:FieldTypePolymorphism>
- <doc:HandlingErrors>
- <doc:WhatTheAIGotWrong>
