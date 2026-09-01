# Raw mining output: closed issues (pre-2026-08-26)

Captured 2026-09-01. Source: subagent sweep of ~229 closed issues on brightdigit/MistKit,
hunting CloudKit API facts and corrections predating the `.claude/memory/` convention
(began 2026-08-26). UNCURATED — raw agent report, kept so findings survive; promote to real
memory files after human review.

## Tier 1 — expensive CloudKit API facts, LIVE-VERIFIED, not in CLAUDE.md or .claude/memory/

1. **APNs token endpoints route under `/device/`, not `/database/` — Apple's own docs are WRONG.**
   `tokens/create` and `tokens/register` live at
   `POST /device/{version}/{container}/{environment}/tokens/{create|register}`
   — container-scoped, NO `{database}` segment. Apple's archived CreateTokens/RegisterTokens pages
   document them under `/database/.../{database}/tokens/...`, which the live service routes only
   OPTIONS for, returning 405 Method Not Allowed (`Allow: OPTIONS`) on POST.
   Live-verified end-to-end: `mistdemo test-private` phase 16 returns 200 where it previously 405'd.
   Corroborated by CloudKit JS calling `setApiModuleName("device")`.
   TWO BONUS DOC BUGS in the same reference: `tokens/register` genuinely requires BOTH
   `apnsEnvironment` and `apnsToken` (easy to omit apnsEnvironment); and `tokens/create` returns
   `{ apnsEnvironment, apnsToken, webcourierURL }` — earlier guesses at a `webcAuthToken` field are wrong.
   Issue #382 (closed via PR #415, 1.0.0-beta.3). Type: CLOUDKIT API FACT.
   Confidence HIGH — openapi.yaml:804/854 already encodes the working path; Apple's docs are archived
   and will not be corrected.

2. **Subscription uniqueness is content-based on `(recordType, firesOn)`, NOT on `subscriptionID`.**
   A duplicate (recordType, firesOn) pair fails with generic `INTERNAL_ERROR` and the misleading
   reason "could not find subscription we just created" — there is no CONFLICT/EXISTS code.
   Two counterintuitive corollaries:
     (a) creating the SAME `subscriptionID` twice SUCCEEDS silently — CloudKit is idempotent on the ID
         and returns the existing record. The "IDs must be unique on create" mental model is WRONG.
     (b) uniqueness on `firesOn` is EXACT-SET MATCH, not overlap — `[.create]` and `[.create,.update]`
         coexist fine.
   Implied directive: clean up subscriptions by (recordType, firesOn) identity via `listSubscriptions`,
   NOT by subscriptionID — an old subscription under a different ID still collides.
   Evidence: five-variation probe matrix run 2026-05-25 against a real container's public DB via a
   purpose-built `mistdemo probe-duplicate-subscription`. Reproducible.
   Issue #387 (closed via PR #416, 1.0.0-beta.3). Type: CLOUDKIT API FACT. Confidence HIGH.
   *** NOTE: the issue references a memory file `project_cloudkit_subscription_uniqueness.md` that
   DOES NOT EXIST in .claude/memory/. This is a CONFIRMED LOSS, not a judgment call. ***

3. **`GET /users/discover` (discoverAllUserIdentities) is broken SERVER-SIDE at Apple — 500
   INTERNAL_ERROR, 100% reproducible.** Auth succeeds (every 500 carries a refreshed
   `X-Apple-CloudKit-Web-Auth-Token`), then Apple's handler crashes.
   Diagnostics ruling out a client wire-shape problem: OPTIONS on the same URL returns 200 with
   `Allow: GET, POST, PUT, DELETE`; a typo'd sibling path returns a clean 404 "could not find handler
   for endpoint"; POST to the identical URL with identical auth reaches body validation.
   Apple's own CloudKit JS `container.discoverAllUserIdentities()` fails identically from an
   authenticated browser.
   Issue #28 — contains a ready-to-submit Feedback Assistant draft with four correlation UUIDs.
   Type: CLOUDKIT API FACT + open Apple bug. Confidence HIGH.
   CLAUDE.md says "unavailable, pending #28" but records NONE of the evidence — so the next agent
   cannot tell it is Apple's bug rather than ours. The `@available(*, unavailable)` marker is a
   one-line removal if Apple ever fixes it.

4. **Database-scope routing facts for the user-identity family (live-verified in the #28 investigation).**
   - `POST users/discover` on private -> 400 BAD_REQUEST "endpoint not applicable in the database
     type 'privatedb'" (same for sharedb). The public segment is MANDATORY.
   - `POST users/discover` on public + S2S -> 401 AUTHENTICATION_FAILED. User-context (web-auth) is
     genuinely REQUIRED, not merely preferred.
   - EXCEPTION WORTH KNOWING: `users/current` / `users/caller` is documented by Apple under
     `public/users/current` but RAN SUCCESSFULLY on private + web-auth — routing for the caller
     endpoint is more lenient than for users/discover.
   Issues #28, #312. Type: CLOUDKIT API FACT. Confidence HIGH.
   CLAUDE.md states the public+web-auth requirement as policy but not the observed error strings, and
   does not record the users/caller leniency exception at all.

5. **S2S-signed public writes are attributed to the KEY's identity, not to any iCloud user.**
   The same logical "you" writing a public record produces different `created.userRecordName` values
   depending on signing method — CloudKit JS (web-auth) records the iCloud user; MistKit signing with
   S2S records a fixed identity tied to the server-to-server key. CloudKit reads an S2S signature as
   "from the server-as-a-service, not from a user."
   Why it matters beyond the demo: any server holding both credential sets that wants user-attributed
   public writes (e.g. "submitted by user" records) MUST force web-auth per call. THIS IS THE ENTIRE
   ORIGIN OF `PublicAuthPreference`.
   BONUS FOOTGUN from the same thread: `subscriptions/modify` signed with S2S registers a subscription
   OWNED BY THE DEVELOPER KEY, so pushes don't usefully reach an end user's device.
   Evidence: observed empirically with concrete differing record names (_904181d1... vs _aca0fa35...).
   Issue #338 (resolved by #340). Type: CLOUDKIT API FACT. Confidence HIGH.
   CLAUDE.md documents the PublicAuthPreference API thoroughly but never states the attribution
   behavior that motivates it, nor the subscription footgun.

## Tier 2 — solid facts, moderate rediscovery cost

6. **A normal record read returns only a PARTIAL asset descriptor; `assets/rereference` is the only
   supported way to get a reusable one.** On a record read CloudKit returns just `downloadURL` /
   `fileChecksum` / `size`. The WRITABLE descriptor fields (`receipt`, `referenceChecksum`,
   `wrappingKey`, `fileChecksum`, `size`) come only from the CDN upload step or from
   `POST /database/1/{container}/{env}/{database}/assets/rereference`.
   So you CANNOT attach an existing asset to a second record by copying what a read gave you — you
   must re-reference. Apple: "Assets are deleted only when all references to it are removed."
   The endpoint is absent from BOTH openapi.yaml and .claude/docs/webservices.md — archive only.
   Issue #31. Type: CLOUDKIT API FACT. Confidence MEDIUM-HIGH.
   Partly overlaps `reference_cloudkit_archived_endpoints.md`, but that memory captures the LESSON
   ("check the archive"), not this descriptor-asymmetry FACT.

7. **`users/lookup/contacts` deprecated by Apple; closed won't-do.** Ships `deprecated: true`;
   implementing a wrapper adds maintenance surface for an endpoint that may stop responding.
   Replacements: `users/lookup/email` (#34), `users/lookup/id` (#35).
   Issue #33 — explicit "Closing as not-planned" with reasoning. Type: PROJECT CONTEXT.
   MOSTLY COVERED by CLAUDE.md already. Only NEW content is the REOPENING CONDITION: "re-open with
   the use case if a flow specifically requires Address Book integration."

8. **CloudKit does not report create-vs-update in `modifyRecords` responses.** With `.forceReplace`,
   the response gives NO signal whether a record was created or updated. Only workable approach is a
   pre-fetch of existing record names plus client-side classification — costing ~600ms extra per sync
   for 3 record types in BushelCloud's measured case.
   Issue #194. Type: CLOUDKIT API FACT (a NEGATIVE capability — valuable precisely because you cannot
   prove it from docs). Confidence MEDIUM-HIGH.
   CLAUDE.md references CloudKitService+Classification.swift for "operation classification" but never
   says WHY client-side classification is necessary.

## Tier 3 — design-philosophy directives with recurring applicability

9. **Never normalize a malformed CloudKit response into a plausible-but-wrong value — fail closed or
   drop the entry.** `ZoneInfo(zoneName: zoneID.zoneName ?? "Unknown")` made a missing name
   indistinguishable from a real zone named "Unknown", with no signal to the caller that data was
   lost — "the worst of both worlds." Fix extends the existing compactMap guard to drop the entry.
   Issue #349. Type: HOW-TO-WORK-HERE. Confidence HIGH.
   Same fail-loud philosophy CLAUDE.md describes for unmappableFieldValue/typeValueMismatch, but
   stated as a GENERAL principle and applied to a different subsystem.

10. **Never report client-side validation failures as synthetic HTTP status codes.**
    Throwing `httpErrorWithRawResponse(statusCode: 400, ...)` for a caller-side argument check means
    no request was ever made, yet callers reading httpStatusCode see 400, retry middleware cannot tell
    "server rejected" from "we didn't try," and metrics conflate real and synthetic 400s.
    Fix: a dedicated `invalidArgument(parameter:reason:)` case.
    Reusable audit command: `grep -rn 'httpErrorWithRawResponse(statusCode: 4' Sources/`
    Issue #352. Type: HOW-TO-WORK-HERE. Confidence HIGH.

11. **Switch exhaustively over generated-code enums — no `default:` clause.**
    `default: assertionFailure(...)` in CloudKitResponseProcessor fires only in debug; in release a new
    OpenAPI-generated response variant silently degrades to `.invalidResponse`, losing whatever
    CloudKit was signaling. Exhaustive switching converts this to a compile-time break pointing at the
    exact file — "pulls the failure mode from silent runtime degradation to loud compile-time error."
    Applies broadly because the codebase regenerates from openapi.yaml.
    Issue #353. Type: HOW-TO-WORK-HERE. Confidence HIGH.

12. **Never silently drop credentials behind an `#available` check.** When S2S credentials were
    supplied but the runtime was below macOS 11 / iOS 14 / tvOS 14 / watchOS 7, the #available branch
    fell through and the caller got a misleading `missingCredentials: "expected serverToServer or
    apiAuth credentials"` — despite having provided exactly those. Wants an explicit
    `platformUnsupported(method:minPlatform:)` error, or removal of the dead branch if Package.swift's
    floor already covers it.
    Issue #348. Type: HOW-TO-WORK-HERE. Confidence MEDIUM — the platform floor may since have risen,
    making the branch dead. The principle stands regardless.

## Honest negatives

- **2020-2021 slice (issues #2-#123) essentially empty.** CodeFactor lint bots, pre-rewrite
  MKDatabase/MKQueryResult issues from the abandoned architecture, CI matrix chores. #100 is a raw
  crash dump with no diagnosis; #102 is user Q&A long since superseded.
- **Issue #192 (`QueryFilter.in()` -> HTTP 400 "Unexpected input") DISAPPOINTED.** Well-written report
  ruling out array size across 2/20/97 elements, but closed with only "Completed and verified in
  codebase" — ROOT CAUSE NOT RECORDED in the thread. CLAUDE.md's ListValuePayload note is the surviving
  record. The wire-format detail lives in the PR, not the issue.
- **Issues #366 ("Make FieldValue Decode Fail Less Gracefully") and #38 ("Handle Data Size Limits")
  have empty bodies and no comments.** Nothing recoverable.
- **The #199 "Complete CloudKit API Coverage" family (#25,#26,#30,#40,#43-#53) is almost entirely
  routine** — identical template, implemented as specified. Exceptions: #33 (item 7) and #31 (item 6).
- **Several threads contain "confirm against a live container before adding X" notes NEVER RESOLVED** —
  #51 (does CloudKit support a `database` subscription type beyond documented query/zone enum?) and
  #52 (which database scopes actually accept tokens/create?). Open unknowns, not findings. #382 later
  answered #52 by a different route.

## Agent's recommended capture priority

Items 1,2,3,4,5 -> write as `reference_*` memory files. All five are live-API-verified, none are in
CLAUDE.md or the memory index, and each cost a real debugging session (or an Apple bug report).
Item 2 is especially notable — its own issue text cites a memory file that was never created.
Items 9-11 fit the existing `feedback_*` convention.
