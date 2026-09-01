# Raw mining output: closed issues — REMOTE PASS (pre-2026-08-26)

Captured 2026-09-01 from a remote agent run in parallel with the local issue sweep in
`2026-09-01-issue-history-mining.md`. UNCURATED. Second independent read of the same corpus:
204 closed issues before the cutoff, 125 substantive ones dumped and grepped.

## Agreement with the local pass (= high confidence)

Both sweeps independently produced the SAME Tier-1 CloudKit facts: /device/ token routing,
subscription uniqueness on (recordType, firesOn), users/* public+web-auth requirement with its
two error signatures, and S2S attribution to the key identity. Two independent agents converging
on all four is the strongest signal available here.

## What this pass adds or states more precisely

### 1. /device/ routing — the DEBUGGING ARC is the valuable part
The fix was nearly written off as "browser-only or dead." #379 first fixed a 404 by removing the
{database} segment per Apple's docs, then hit 405 and ruled out auth BY ELIMINATION — web-auth
succeeded on every private-DB endpoint, S2S succeeded on the full public pipeline, and phase 15
SubscriptionRoundtripPhase passed with the SAME auth/container/environment that 405'd on
tokens/create. The actual answer came from READING CLOUDKIT JS: it calls setApiModuleName("device").
LESSON BEYOND THE FACT: when REST docs and observed behavior disagree, CloudKit JS's source is a
primary oracle for routing.
Sub-fact: `webcAuthToken` is a CloudKit-JS-INTERNAL concept, NOT in the REST response. An earlier
guess at that field name was wrong.
Issues #382, origin arc #379.

### 2. Subscription uniqueness — how MistKit currently detects it
The collision surfaces as generic INTERNAL_ERROR with reason "could not find subscription we just
created". MistKit infers it via `SubscriptionOperationFailure.isLikelyDuplicate` — an EXACT STRING
MATCH on that reason. That is brittle: if Apple reworded the message, duplicate detection breaks
silently. Worth knowing when touching subscriptions.
Issue #387. *** Confirms the local finding that project_cloudkit_subscription_uniqueness.md is
cited by #387 but was NEVER CREATED. Both agents flagged it independently. ***

### 3. users/caller — the 421 signature  *** NEW ***
A live curl against `/public/users/caller` returned HTTP 421 AUTHENTICATION_REQUIRED WITH A
REDIRECT URL, confirming the endpoint resolves and only needs fresh user-context auth.
A migration was ATTEMPTED AND REVERTED before this was understood.
Note the local pass reported users/caller ran successfully on PRIVATE + web-auth (leniency
exception). These two observations are not obviously contradictory (different auth freshness)
but SHOULD BE RECONCILED against a live container before either is written as a memory file.
Issues #28, #311, #312.

### 4. CloudKit echoes a DELETED subscription as a bare { subscriptionID }  *** NEW ***
The subscriptions/modify response for a DELETE carries ONLY `subscriptionID` — no
`subscriptionType`. Treating every response element as a full Subscription FATAL-ERRORED on
conversion. Must be filtered as a deletion-ack, not a conversion failure.
Live crash during the #379 integration run; fixed on that branch.
Agent's hedge: likely the same shape for records/modify deletes — "worth assuming, not asserting."
Issue #379. Confidence HIGH.

### 5. QueryFilter.in() — "CloudKit caps .in()" IS A FALSE LEAD  *** NEW, and valuable ***
The HTTP 400 "BadRequestException: Unexpected input" was a MISTKIT SERIALIZATION DEFECT, not a
CloudKit array-size limit and not an unsupported operator. The reporter ruled out size live at
97 -> 20 -> 2 values, all failing. Fix was wrapping list values in ListValuePayload (v1.0.0-alpha.5).
WHY THIS MATTERS: the issue thread's own "Analysis" section confidently lists "CloudKit Web Services
Limitation / undocumented size limits on .in()" as root cause #1. THAT HYPOTHESIS IS WRONG and is
the natural first guess anyone would make again.
NOTE: the LOCAL pass looked at #192 and reported the root cause was NOT recorded in the thread.
This remote pass says it was. Discrepancy — trust this one only after a spot-check of #192.
Issue #192. Class: CLOUDKIT API FACT (negative — a limit that does NOT exist).

### 6. Asset descriptor asymmetry — with an explicit UNVERIFIED sub-note
Reads return only downloadURL, fileChecksum, size (3 of 6). Writable fields (receipt,
referenceChecksum, wrappingKey) come only from the CDN upload step. Cannot round-trip an asset
from a read; assets/rereference is the supported path.
SPECULATIVE SUB-NOTE, NEVER LIVE-CONFIRMED: re-referenced assets are *likely* tagged ASSETID rather
than ASSET. openapi.yaml ALREADY models ASSETID as sharing AssetValue with ASSET (CLAUDE.md #376),
so THIS GUESS APPEARS TO HAVE BEEN ACTED ON without verification. Flagged as low confidence.
Issue #31.

## Open questions NEVER resolved — flagged "needs live verification", closed without it  *** NEW ***

- Whether a `database` subscriptionType exists (enum still [query, zone]) — #51, #379
- Whether RecordResponse carries pluginFields / zoneID; whether AssetUploadResponse includes a
  wrappingKey/receipt field — #385
- Subscription schema still lacks notificationInfo, zoneWide, firesOnce, and there is NO
  NotificationInfo schema at all — so created subscriptions CANNOT configure alert/badge/sound/
  content-available behavior — #51
- Apple Feedback Assistant reports SUGGESTED BUT NOT CONFIRMED FILED: a SUBSCRIPTION_EXISTS/CONFLICT
  error code (#387), and discoverAllUserIdentities HTTP 500 (#28 — whose title is literally
  "File Apple Feedback Assistant report")

## Honest negatives

- Issues 2-123 (2020-2021): CodeFactor lint, CI config, README. #100 closed "Not applicable after
  claude branch rewrite." No recoverable CloudKit facts. AGREES with local pass.
- **leogdion correcting a proposed approach IN COMMENTS: almost none.** The dominant comment pattern
  is single-line closures ("Completed and verified in codebase", "Shipped in PR #NNN"). THE
  SUBSTANTIVE CORRECTIONS LIVE IN ISSUE BODIES HE AUTHORED, NOT IN BACK-AND-FORTH THREADS.
  ^ This is a useful methodological note for any future archaeology.
- Issues 120,122,175,229,349,352,353: genuine bug fixes but Swift-side defects (wrong 421-vs-422
  status constant, ?? "Unknown" masking, fatalError in conversion), not CloudKit facts. Several are
  CodeRabbit-generated. Their design principles are already in CLAUDE.md's fail-loud philosophy.

## Discrepancies to resolve before promoting anything

1. #192 root cause: local says NOT recorded in thread; remote says it WAS. Spot-check.
2. users/caller: local reports success on private+web-auth; remote reports 421 on public needing
   fresh auth. Reconcile against a live container.
