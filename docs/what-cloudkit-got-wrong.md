# What CloudKit Got Wrong

Companion to [`what-the-ai-got-wrong.md`](what-the-ai-got-wrong.md). That document catalogues how
the *assistant* behaved while building MistKit. This one asks the orthogonal question: **which
parts of CloudKit Web Services were genuinely hard, and why?**

Sourced from `.claude/memory/`, `openapi.yaml` descriptions, source comments, and the issue
tracker — a corpus the earlier archaeology could not see. Its own PR-mining pass says so:

> "**NO CloudKit-API misconception corrections exist in the PR record.** The CloudKit facts
> Leo corrected (cloudkit.share casing, metaSyncToken, Zone Dictionary keys) were ALL discovered
> AFTER the memory convention began."

---

## The thesis: silence is the failure mode

> **Apple's documentation and Apple's live server disagree, and the server is not the one that
> gets corrected.**

Every significant finding below was settled by *running a request*, never by reading harder. And
the worst ones return **HTTP 200**. A wrong sync-token key is ignored rather than rejected. A
mis-cased record type blames a different record. An unmodeled `ownerRecordName` decodes to `nil`.
A stale auth token keeps working. Nothing throws.

Its corollary, learned on the `/device/` bug: **when the REST docs and observed behavior
disagree, CloudKit JS's source is a primary oracle.** `setApiModuleName("device")` is what
cracked #382 — and CloudKit JS beat the archived reference twice (see the casing bug too).

## Two kinds of hard

The doc-contradiction findings are the most *dramatic*, but each was hard **once** — one bad
afternoon, then a line in the spec and a memory file. Two subsystems were hard **continuously**,
and they shaped the library's architecture: **authentication** and **field value types**.

The tell is in the source tree. `Authentication/` is 32 files and 2,594 lines with no single
large file, because the difficulty is the *combinatorics between* them.

| Signal | Count |
|---|---|
| Distinct auth failure reasons across 8 enums (`InvalidCredentialReason` alone: 28) | **72** |
| `Authentication/` files / lines | 32 / 2,594 |
| `ConversionError` cases | 34 |
| `reportAndThrow()` call sites | 26 |
| Fail-loud guards per line of field-value code | ~1 per 48 |

Both subsystems refuse to collapse their failure modes into a generic error — because CloudKit
gives you no way to tell the cases apart afterward.

---

## 1. Authentication — the rules don't compose

**Start with two record names.** The same human writing the same public record produced two
different creators:

- `_904181d1d76652d1f53581aec11cf76e` — via CloudKit JS (web auth)
- `_aca0fa3547ae9f9cd1f7e25fed948a20` — via MistKit (server-to-server)

**Your choice of signing method silently changes the record's creator.** Apple documents neither
the behavior nor its consequence; it was found by writing the same record twice and noticing.
Every line of `PublicAuthPreference.swift`, `CredentialAvailability.swift`, and the five-row
resolution table exists because of that observation (#338).

The footgun is worse than the bug: a subscription created under S2S is **owned by the developer
key**, so pushes never usefully reach an end user's device.

### It is a 3 × 3 matrix with holes

Not "three auth methods." Per the project's own guide: *"There is no method that does both. Pick
the database first; the auth method falls out of that choice."* Auth and database scope are **not
orthogonal** — which is exactly why they resisted being modeled as two parameters.

| Mode | Private | Shared | Public |
|---|---|---|---|
| API token only | not supported | not supported | whatever `_world` grants |
| Web auth | all endpoints | all endpoints | all endpoints — **only** mode accepted for `/users/*` |
| Server-to-server | rejected | rejected | all endpoints **except** `/users/*` |

It isn't a clean product: public accepts two methods, private and shared accept exactly one, and
`/users/*` carves a hole *inside* the public column. `CloudKitService+UserOperations.swift` and
`+ShareOperations.swift` therefore hard-code `.public(.requires(.webAuth))` and expose **no**
`database:` parameter at all — the API surface encodes the irregularity.

### Five architectures, four abandoned

Each was killed for a *different* reason, which is the real evidence of difficulty:

1. **`DatabaseCredentials` enum** — baked in public⇒S2S / private⇒webAuth, making public+web-auth
   *unrepresentable* and locking MistKit out of five `/users/*` endpoints (#312).
2. **`AuthenticationCredentials` + `DatabaseConfiguration`** — moved the choice to *construction*
   when CloudKit makes it *per-call*.
3. **Service-carries-`database`** — combinatorial explosion. MistDemo had to thread an optional
   second service through `PhaseContext` just to reach public+web-auth. Two services for one
   container is the smell that killed it.
4. **Per-call with a defaulted `auth:` parameter** — abandoned *before merge*: a default would
   "recreate the silent-policy problem at a different layer." Now a standing rule.
5. **Survivor** — the auth payload lives *inside* `Database.public`, because the choice exists
   only in that scope.

Blast radius: PR #340 touched **73 files**; PR #315 touched **99**.

### Signing is undocumented, and every mistake looks identical

The payload is exactly `"<iso8601Date>:<bodyHash>:<subpath>"`. Three traps, none documented:

- **A bodyless request hashes to the empty string** — not `SHA256("")`. Both are defensible; one
  works (`HashFunction+CloudKitBodyHash.swift:34-36`).
- **The ISO8601 date is stored as a `String`, not a `Date`** — re-formatting on each header access
  risks a wire string differing from the one signed (`RequestSignature.swift:128-129`).
- **Web auth tokens need a 3-character percent-encoding map** (`+`, `/`, `=`) or CloudKit rejects
  them (`CharacterMapEncoder.swift:35-39`).

Every one of these produces the *same* generic 401. CloudKit will not tell you which of the five
fields was wrong, so the debug loop is "change one thing, redeploy, observe the same error."

There is also a protocol-level scar: `Authenticator.authenticate` takes `body: inout HTTPBody?`
because `HTTPBody` is single-pass and hashing it consumes the iterator. The other two
authenticators never mutate `body`; the signature exists for the one that must.

### The rotation gap

`TokenManager.swift:35` advertises the manager as owning "loading, validating, **rotating**,
persisting." Rotation is not implemented. `AuthenticationMiddleware.swift:53` returns `next(...)`
without inspecting the response, and the string `X-Apple-CloudKit-Web-Auth-Token` appears
**nowhere in `Sources/` or `Tests/`** — so the fresh token CloudKit returns on *every* response is
discarded.

Sharper still: five test files under `Tests/…/ConcurrentTokenRefresh/` test only that
`currentAuthenticator()` was called again. A directory named for rotation testing that never tests
rotation — a cautionary tale about naming tests after intent instead of behavior.

MistKit currently works only because the live server is **more lenient than Apple's spec** (§4).

---

## 2. Field value types — the wire is lossy by construction

Not "mapping dynamic JSON to Swift." The real problem:

> CloudKit tells you a field's type in an **optional** sibling key, next to a value drawn from a
> **9-way union with no discriminator**, where three of the five scalars are structurally
> identical to another scalar. Reads get a `LIST` tag; writes need `STRING_LIST`. Two wire tags
> collapse into one Swift case. Booleans don't exist.

Generated decoding is first-match-wins (`String → Int64 → Double → Bytes → Date`), so a
whole-millisecond `TIMESTAMP` arrives as `Int64Value` and base64 `BYTES` as `StringValue`.

**It hid for a long time because reads worked.** CloudKit *supplies* the type in responses, so
only writes broke — which is why #375 surfaced as a production failure rather than a unit test:

```
Batch 1 failed: CloudKit record operation failed (BAD_REQUEST)
Reason: Invalid value, expected type TIMESTAMP.
Batch complete: 0/7 (0.0%)
```

A library correctness bug found by a **downstream app's CI**. And the fix came from a **2015 Apple
Developer Forums thread**, not from Apple's documentation.

### Things a reader would not guess

**Some values cannot round-trip, and there is a test asserting it.** From
`FieldValueTests.swift:127`: *".date does not round-trip: the decoder has no date branch on
purpose."* `.bytes` decodes back as `.string`. Not bugs — the information isn't on the wire. The
library's own type cannot survive its own encode/decode.

**A date-decode branch that was dead from the moment it was written.**
`FieldValue+Codable.swift:89-93` documents a removed `.date` case: a bare millisecond number is
already claimed by `decodeBasicTypes` three calls earlier, so the recovery branch *never ran*.
Someone wrote timestamp recovery that could not execute — and the same bug resurfaced at the API
level as #375.

**Lists are strictly worse than scalars.** The request enum has **17** values including eight
`*_LIST` flavors; the response enum has **10**, collapsing every list to a single `LIST`. And
`ListValuePayload` carries **no per-element tag at all**. A `[Date]` written as `TIMESTAMP_LIST`
reads back as `[.int64]` — element type is information you *must send* and *can never get back*,
with no tag to rescue it.

**Sub-millisecond precision is destroyed on every write.** CloudKit rejects a fractional
`TIMESTAMP` (`1747999812347.89`) with `BAD_REQUEST`, and Swift's `Date` carries sub-millisecond
precision, so values are rounded. A `Date` in is a different `Date` out. The same constraint
independently bites `LocationValue.timestamp` — a *second*, nested millisecond field with no type
tag of its own, found only via a live CelestraCloud failure (PR #377).

**Schema strictness on one type is the only discriminator protecting another.**
`LocationValue.latitude`/`longitude` are `required` in the spec *only* because, while they were
optional, the undiscriminated `oneOf` greedily matched **assets as locations**. Loosen `Location`
and `Asset` breaks.

**`Bool` does not exist.** It's `INT64` 0/1, so `.int64(1)` and `FieldValue(booleanValue: true)`
are `==` with no way to recover the semantic intent — and `boolValue` *traps in DEBUG* on any
value that isn't 0 or 1.

**The obvious hypothesis about `IN` filters was wrong.** `QueryFilter.in()` returned
`400 BadRequestException: Unexpected input` at *every* array size — 97, 20, even 2, all ruled out
empirically. The natural guess (an undocumented size limit) was false; the cause was a stripped
list `type` tag (#192). While broken, CelestraCloud disabled GUID dedup entirely.

### Fail-loud was genuinely contested

34 `ConversionError` cases and 26 `reportAndThrow() -> Never` sites encode a bet: a loud failure
beats silently wrong data. But the boundary took three months to settle. #375 shipped strictness
for *scalars only*, explicitly deferring complex tags "to limit read-path regression risk"; #376
then argued the compromise was incoherent — *"`TIMESTAMP` over a non-number throws, while
`REFERENCE` over a non-object is silently coerced."*

There are still **three** policies for a contradicting tag: throw (category mismatch), ignore the
tag (fractional `INT64` → `.double`), and honor the tag (`TIMESTAMP`/`DOUBLE`/`BYTES`). A field
CloudKit declares `INT64` can hand you a `.double`, so a caller matching `.int64` silently misses
it.

**And the doctrine stops one layer up.** `FieldValue → YourType` is hand-written and
`Optional`-returning, and `RecordManaging+Generic.swift:126` `compactMap`s it — so a single
unconvertible field makes the **whole record silently vanish**.

---

## 3. Documentation inconsistency — a taxonomy

The thesis is only *one* of five ways the documentation failed. Each has a different remedy:

| Kind | Example | Remedy |
|---|---|---|
| **1. Docs vs. live server** | `metaSyncToken`; `/device/` routing; `cloudkit.share` casing; token rotation | Run a request. Nothing else works. |
| **2. Apple contradicting itself** | The `zones/changes` page names `metaSyncToken` in its field table, then its own `moreComing` prose cites "the included `syncToken` key" | Neither reading is authoritative — go to (1) |
| **3. Apple contradicting Apple across sources** | Archived reference vs. CloudKit JS vs. Developer Forums. The #375 fix came from a 2015 forum thread; `/device/` routing from CloudKit JS source | Know which source wins for which question |
| **4. Documentation that no longer exists** | `records/resolve`, `records/accept`, `assets/rereference` are documented **only** in the archive | Cite the archive; assume it won't be corrected |
| **5. Local doc copies being incomplete** | `.claude/docs/webservices.md` is 289 KB but contains **two** endpoint headings | Never treat a zero-hit grep as proof of absence |

**Kind 2 is the most corrosive, because it defeats careful reading.** The `zones/changes`
reversal happened *inside a single PR*: the first commit "fixed" the prose on the assumption the
docs were merely worded badly, and a later commit on the same branch reversed it after a live run:

> "This supersedes the description-only wording fix in the previous commit, **which assumed the
> mismatch was documentation rather than behavior**."

**Kind 5 deserves its own warning.** `.claude/docs/webservices.md` *looks* authoritative at
289 KB, but grepping it for `zones/changes`, `changes/database`, `records/changes`,
`assets/rereference`, `records/resolve`, `tokens/create`, `metaSyncToken`, `syncToken`,
`moreComing`, or `"Zone Dictionary"` returns **zero hits for every one**. Most of the bulk is
unrelated guide filler plus four literal `# The page you're looking for can't be found.` blocks.
Zero hits reads as proof of absence, and it isn't.

### The same failure recurred in MistKit's own docs

A project that spent a year cataloguing Apple's documentation drift produced its own. Fixed
alongside this document:

| Where | Was | Now |
|---|---|---|
| `docs/cloudkit-guide/README.md:327` | header `X-Apple-CloudKit-Request-SignedMessage` — **does not exist** | `SignatureV1`, matching the same file's line 117 |
| `AGENTS.md` (IN/NOT_IN) | "ensures the correct `value` key structure" — the `value` line never changed | the added **`type` tag** was the fix |
| `AGENTS.md` (endpoints) | token paths under `/database/…` | `/device/…`, plus 5 missing endpoints and deprecation marks |
| `docs/internals/field-type-polymorphism.md` | "`type` only used for list filters"; "CloudKit infers" | three scalars **must** be tagged; 17-vs-10 enum asymmetry |
| `openapi.yaml` (7 sites) + 5 Swift comments | `cloudKit.share` — the casing the server **rejects** | `cloudkit.share`, with the trap documented inline |
| `.claude/docs/SUMMARY.md` | a `DATE` / `DATE_LIST` type that **does not exist** | `TIMESTAMP`, with the tagging requirement noted |
| `.claude/docs/QUICK_REFERENCE.md` | API-token auth documented with **signing headers** | query parameters, with encoding requirement |

The first one is the sharpest: a header name that doesn't exist, in the talk's own signing
walkthrough, one line above *"getting any part wrong gives you a generic 401."*

---

## 4. Where Apple's docs are actively wrong

| # | Finding | Receipt |
|---|---|---|
| 1 | **`zones/changes` uses `metaSyncToken`, not `syncToken`.** The wrong key is *silently ignored* — page one replays forever, so pagination had **never** worked. Live proof: `syncToken` → 40 zones again; `metaSyncToken` → 0. Only this endpoint differs; its three siblings genuinely use `syncToken`. | `openapi.yaml:578-592`; #430 / PR #443 |
| 2 | **APNs tokens live under `/device/`, not `/database/`.** The documented path answers only `OPTIONS`, returning `405` on POST, with no `{database}` segment. Auth was ruled out *by elimination* across four passing endpoints; the answer came from CloudKit JS's source. Nearly written off as "browser-only or dead." | `openapi.yaml:1206,1256`; #382 / PR #415 |
| 3 | **`ownerRecordName` vs `ownerName` — zone owners never decoded.** Live `zones/list` returns `ownerRecordName`; the spec declared `ownerName`, so every zone read its owner back as `nil` — gutting the reason `ZoneID` replaced a bare `zoneName` for shared zones. | #444; request direction **still unproven** |
| 4 | **`cloudkit.share`, not `cloudKit.share`.** One letter's case. The error — *"Cannot share - no such record exists to share"* — blames the root record, not the type string. | `ShareInfo.swift:45-51`; #437 |
| 5 | **`GET users/discover` is broken server-side at Apple** — 100% reproducible 500. Proving it was *Apple's* bug took a five-rung ladder: `OPTIONS` returns 200; a typo'd path returns a clean 404; POST reaches body validation; and Apple's own CloudKit JS fails identically from a browser. | `@available(*, unavailable)`; #28 |

On #1: the AI had recommended closing #430 as `not planned` on a 2-versus-1 documentation count,
noting *"Plan mode blocks me from running it now."* Five words — **"Can we run a quick test for
this?"** — reversed it. [`what-the-ai-got-wrong.md`](what-the-ai-got-wrong.md) §8 tells the same
episode from the collaboration side.

### Case study: the `/device/` bug

The whole thesis in one arc. Docs wrong → `404` → "fix" applied per the docs → `405` → auth ruled
out by elimination across four endpoints that passed with identical credentials → answer found in
CloudKit JS's source → live verification via `mistdemo test-private` phase 16.

> "Apple's reference is archived and unlikely to be corrected, so the next person reading the docs
> will hit the same 405." — #382

---

## 5. Other traps worth knowing

- **`421 Misdirected Request` on asset upload.** The CDN and the API are different hosts; HTTP/2
  connection reuse breaks it. A transport-layer trap invisible at the REST layer, which forced an
  architectural compromise against the project's own inject-the-transport rule.
- **The query index is eventually consistent; `lookup` is not.** Create → immediate query returns
  **0 records**; +3s returns both; `lookup` by name returns both immediately (#445).
- **A read gives you an asset you cannot re-attach** — 3 of 6 fields. The writable ones come only
  from the upload step or `assets/rereference`, which is absent from the local docs entirely (#31).
- **Subscription uniqueness is keyed on `(recordType, firesOn)`, not `subscriptionID`.** The same
  ID twice *succeeds*; uniqueness is exact-set match, not overlap; and a duplicate surfaces as a
  generic `INTERNAL_ERROR` with no `CONFLICT` code. MistKit detects it by **exact-matching Apple's
  prose string**, which breaks silently if Apple rewords it (#387).
- **Per-zone partial failure.** `changes/database`, `changes/zone` and `zones/modify` return
  success-or-failure *per zone*, and the failure variant must be listed **first** in each `oneOf`
  or the permissive success schema swallows it.
- **`modifyRecords` never reports create-vs-update.** The only workable approach is a pre-fetch
  plus client-side classification — ~600ms extra per sync in BushelCloud's measured case (#194).

---

## Still unresolved

- **#462 (open)** — web auth token rotation contradicts Apple's written spec. Apple documents
  single-use tokens; the live server *"rotates but does not invalidate."* A 25-hour-old token
  returned 200; 8 sequential reuses and 6 concurrent shares all returned 200. **MistKit depends on
  undocumented leniency** — if Apple ever enforces the documented rule it is an immediate hard
  break for every private-database user.
- **#28** — Apple-side 500; Feedback Assistant report drafted but never confirmed filed.
- **`ownerName` on the request side** — the response direction is fixed; the request direction is
  unproven, because all four probe variants returned `BAD_REQUEST` from a malformed body.
- **`ASSETID` on re-referenced assets** — never live-confirmed, yet `openapi.yaml` was built on
  the guess.
- **`records/resolve` and `records/accept` shipped with no live call ever made.** Field names came
  from type dictionaries. `acceptShares` is *mutating*, so a wrong field name could silently fail
  to take effect rather than erroring.
- **`users/caller` routing** — one observation had it succeed on private+web-auth; another saw
  `421` against public. The spec description now hedges rather than asserting.
- Whether a `database` subscriptionType exists; the full `zoneType` enum; and the fact that
  subscriptions cannot configure alert/badge/sound at all (no `NotificationInfo` schema).

## Two defects found while writing this — both now fixed

Both were in `Components.Schemas.ListValuePayload.swift`, the list-element sibling of the
scalar conversion file. Both are the same underlying mistake: **a fix applied to one path and
never mirrored to the other.**

**1. `[Date]` writes were missing the `.rounded()` fix (live bug).** The scalar path rounds to
whole milliseconds; the list path did not. A `[Date]` element serialized as
`1747999812347.8923` — exactly the fractional shape CloudKit rejects with
`BAD_REQUEST "Invalid value, expected type TIMESTAMP"`. The nested `Location.timestamp` inside
a list element had the same gap. Neither had any test: no test in the repo wrote a list
containing dates, and `TIMESTAMP_LIST` appeared in no test file.

Fixed, with two regression tests (`FieldValueConversionTests+Lists.swift`) verified to fail
without the fix and pass with it.

**2. A `default:` catch-all that would silently write an empty list (latent bug).** The switch
ended in `default: assertionFailure(...)` returning `.ListValue([])`. `assertionFailure` fires
only in debug builds, so in release an unhandled case would write `[]` in place of the value —
data loss reported as success, in a conversion layer built entirely on failing loud. It was the
anti-pattern issue #353 banned, and the sibling file carries an explicit comment saying its own
switch is *"deliberately `default`-free… so a new `FieldValue` case breaks the build here
instead of silently falling into a catch-all."*

Unreachable today — all nine `FieldValue` cases are covered — so this was a trap for whoever
adds a tenth, and the `default:` was precisely what would have stopped the compiler from
warning them. Fixed by making the initializer one exhaustive `default`-free switch. Verified:
adding a tenth case now breaks the build in `ListValuePayload.swift` alongside its two
siblings, where before it compiled silently.

The pair is a small illustration of this document's own thesis. The scalar bug (#375) was found
by a downstream app's CI; its list twin survived because **nothing exercised it** — the same
reason `zones/changes` pagination was broken for months. Silence is the failure mode at every
level, including the test suite's.

## Limitations

- One container and environment (`iCloud.com.brightdigit.MistDemo`, development). Behavior may
  differ in production or on other containers.
- Several findings are one-shot live observations, not regression-tested. Where a claim rests only
  on the raw archaeology reports in `.claude/memory/_raw/`, those are **self-declared unverified**.
- Some facts predate the memory convention and survive only as source comments, so their discovery
  context is lost.
- The two defects above were found and fixed by reading the code and reproducing them in unit
  tests. Neither was reproduced against a live container, so the *CloudKit-side* claim (that a
  fractional TIMESTAMP inside a list is rejected exactly as a scalar one is) rests on the
  documented scalar behavior from #375, not on an observed rejection of the list form.
