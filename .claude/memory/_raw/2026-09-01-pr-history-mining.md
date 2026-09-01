# Raw mining output: PR review threads (pre-2026-08-26)

Captured 2026-09-01. Source: subagent sweep of all 191 closed PRs on brightdigit/MistKit,
looking for durable corrections from leogdion that predate the `.claude/memory/` convention
(which began 2026-08-26). UNCURATED — this is the agent's raw report, kept so the findings
survive; promote items to real memory files after human review.

Agent's own verification notes: typed throws is pervasive (145 sites); `RetryPolicy` is gone;
no stored `database` on the service; `defaultDatabase` gone (superseded by per-call `database:`).

## Tier 1 — strongly load-bearing, still current, NOT in memory/CLAUDE.md

1. **ALWAYS use typed throws (`throws(SomeError)`), with an error type specific to the failure.**
   Leo repeatedly rejected generic `throws` in conversion code and asked for a more specific
   error type so callers can handle failures exhaustively.
   PR #372 (3 comments: "use Typed Throws" x2 on FieldValue+Components.swift; "This error should
   be more specific and we should use typed throws" on FieldValue+Components+List.swift); PR #132
   "Let's use typed throws". Confidence: HIGH/current (145 `throws(` sites today).

2. **ALWAYS force enum consumers to use `if case let` — do NOT add convenience accessors/`toX()`
   helpers that flatten an enum.** "developers should use `if case let`". The enum's exhaustiveness
   is the API, not a bag of optional getters.
   PR #372 (RecordResult.swift, UserRecordName.swift, DiscoverUserIdentitiesPhase.swift);
   PR #134 ("Is this really needed? Why not use `case let`?"). Confidence: HIGH (recurs across two
   PRs seven months apart).

3. **PREFER an initializer over a conversion method or free function** (`X.init(from: Y)`, not
   `y.toX()` / `makeX(y)`). Leo's single most repeated review note across the whole history.
   PR #152 (titled "refactor: replace toSomeType methods with initializer pattern"); PR #232
   ("why can't this be in a initializer" x2, "make this an initializer on URLRequest"); PR #228
   ("make this an initializer", "move to FieldValue initializer"); PR #293; PR #372; PR #134
   ("move to initializer" x2, "use initializers", "initializer?"); PR #132.
   ~12 occurrences across 7 PRs. Confidence: HIGH/current.

4. **NEVER hardcode a magic string or number inline — hoist to a named constant/enum; prefer an
   enum's `rawValue` over a string literal.** "why are we using strings instead of enumeration or
   rawValue of enum"; "replace strings and numbers with constants somewhere"; "Isn't 200 a constant
   somewhere? perhaps MistKit?" (this produced `CloudKitService.maxRecordsPerRequest`).
   PRs #377, #424, #296, #105 (4x "store these as constants"), #228, #371.
   Spans Sep 2025 -> Aug 2026. Confidence: HIGH/current.

5. **ALWAYS fix wrong types in `openapi.yaml` and regenerate — NEVER patch around them in
   hand-written Swift.** "why isn't this fixed in the openapi.yaml?" (on ZoneInfo); "Have we updated
   the generated code accordingly?" PRs #372, #132.
   NOTE: CLAUDE.md says "never edit Sources/MistKitOpenAPI/" but omits the positive corollary —
   a *modeling* defect must be pushed back into the spec, not compensated for in the curated layer.
   Confidence: HIGH/current.

6. **NEVER leak `MistKitOpenAPI` into curated/public API or into example `Package.swift` deps.**
   Leo asked "why do we need MistKitOpenAPI?" three times in one review (Examples/BushelCloud/
   Package.swift, Examples/MistDemo/Package.swift, Sources/MistKit/CloudKitError.swift).
   The generated module is an escape hatch, not a dependency examples should carry.
   PR #372. Confidence: HIGH/current (it is an `internal import` in MistKit today, per the #430 note).

7. **NEVER put a policy-bearing default of `nil` on an injected dependency; require the caller to
   supply it.** "I'd rather Transport isn't default nil" (Courier.swift). PR #381.
   Extends existing `feedback_no_silent_policy_defaults.md` (which is scoped to signing/attribution)
   to injected transports/dependencies generally. Confidence: MEDIUM-HIGH.

## Tier 2 — real and recurring, narrower scope

8. **PREFER injecting a closure over defining a protocol for single-method dependencies; the closure
   returns raw results and decoding happens outside.** Verbatim: "let's make this just a closure
   instead of a protocol and have it return an optional statusCode and the response data and throw
   an unspecified error type. We'll move the decoding outside of this implementation." Also "rather
   than storing the ClientTransport, can we have a protocol or closure which uploads for us?"
   PR #230. This is exactly the shape `AssetUploader` has today; CLAUDE.md documents the *result*
   but not the general preference. Confidence: HIGH/current.

9. **ALWAYS use an explicit argument label on injected-dependency parameters (`with uploader:`), and
   make the default value the parameter's default rather than branching inside.** PR #230.
   Confidence: MEDIUM-HIGH/current.

10. **NEVER hand-roll a type in an Example that MistKit already provides — check MistKit first.**
    "Isn't this in MistKit already somewhere?"; "isn't this in MistKit already?" (SortOrder); "why
    can't we use types in MistKit already for this?" (FieldType); "is this already in MistKit?"
    (CloudKitData); "Is this universal? Shouldn't it move to MistKit?" (CourierNotification — which
    did move). Stated rationale: universality — CloudKit-general things belong in the library.
    PRs #293, #228, #132, #381, #393. 7+ occurrences across 5 PRs. Confidence: HIGH/current.
    Complements `project_examples_dir_is_for_mistkit_dev.md`.

11. **ALWAYS split types into one-declaration-per-file; keep files small.** "each type and extension
    in it's own file", "split this file", "flatten all single file folders". Leo linked a gist as the
    standard: https://gist.github.com/leogdion/0806c2f41aeb2c77db6a4a846cf13c0f
    PRs #228, #232, #105, #132, #287, #371; PR #247 added the rule.
    NOW LINT-ENFORCED (`.swiftlint.yml:55` `one_declaration_per_file`, plus `file_length`), so lower
    value to record — but the gist link appears nowhere in the repo and is worth keeping.

12. **Test grouping: one `enum` suite per type-under-test, with a nested `struct` suite per facet.**
    "All WebAuthToken tests should [be] under the enum"; "CloudKitService could be a super enum Suite
    for each enum Suite (DiscoverUserIdentities, etc...)". PR #287.
    PARTIALLY SUPERSEDED by `feedback_test_parent_enum_vs_struct.md` (the later, refined form), but
    #287 adds the nesting shape (enum -> struct per facet) the memory doesn't spell out.
    Confidence: MEDIUM.

13. **NEVER reach past the public API in a test to forge state (e.g. hardcoding a sentinel); route
    through the same decoding path production uses.** "this seems like a bad pattern. Is there an
    alternative?" — test was hardcoding the "Unknown" recordType sentinel; fix was constructing via
    `RecordInfo(from: Components.Schemas.RecordResponse())`. PR #296. Confidence: MEDIUM-HIGH.

## Tier 3 — CloudKit/API facts and one-off reversals

14. **`LocationValue.timestamp` is milliseconds and CloudKit rejects a fractional TIMESTAMP with
    BAD_REQUEST — it must be rounded, same as scalar `.date`.** Leo asked "why does it need to be
    rounded?" twice; the answer came from a live CelestraCloud integration failure (commit 1eb639a).
    The field is typed `Swift.Double?` on the wire. PR #377.
    CLAUDE.md documents the *scalar* TIMESTAMP tagging story in detail but never mentions
    LocationValue.timestamp has the same constraint. GENUINELY MISSING. Confidence: HIGH/current.

15. **NEVER use a separate `URLSession` where a MistKit transport should be used — except across host
    boundaries, where connection-pool separation wins.** Leo pushed twice ("rather than using
    URLSession it should use the same client as the MistKit client. See how ClientTransport works";
    "We have a Transport alias but we use a URLSession. What if someone wanted to AsyncHTTPClient?").
    Resolution was a compromise: keep host separation (webcourier != api.apple-cloudkit.com -> 421
    risk) but make the transport an injectable `@Sendable` closure instead of hard-coded URLSession.
    PR #381. CLAUDE.md covers the asset-upload case but not that the same reasoning was applied to
    WebCourier, nor Leo's standing objection to hard-coded URLSession. Confidence: HIGH/current.

16. **`CloudKitService` must NOT carry a database; database is a per-call argument.**
    "should database even be part of the CloudKitService since calls could be for either"; "why does
    the service have a database?"; "We should allow any set of authentication values". PR #315.
    LARGELY SUPERSEDED — this is the origin story of today's `Database` + `PublicAuthPreference`
    design (PR #340), which CLAUDE.md documents fully. Keep as provenance only.

17. **REVERSAL: `RetryPolicy` was deliberately removed — do not reintroduce retry logic.**
    "may want to remove RetryPolicy" (#105) -> "should we even have a retryPolicy" (#134) ->
    PR #148 "Remove Retry Policy and Implement Web Etiquette". Replacement is respectful HTTP client
    behavior (rate-limit honoring), not retries. Zero `RetryPolicy` references in Sources/MistKit today.
    CLAUDE.md mentions CelestraCloud's "respectful HTTP client patterns" but never says retries were
    deliberately removed — a future agent could easily re-add them. Confidence: HIGH/current.

18. **REVERSAL: let CloudKit generate record names — do not generate them client-side.**
    PR #153 ("refactor: delegate record name generation to CloudKit server").
    Not in CLAUDE.md or memory; plausible to get wrong again. Confidence: MEDIUM-HIGH.

19. **NEVER leave "unfixable" warnings suppressed — fix the underlying issue.**
    "fix this issue instead of ignoring it" (suppressed diagnostic in PlatformApplication.swift).
    PR #371; consistent with PR #414 ("drop lint disable") and PR #442. Confidence: MEDIUM/current.

20. **In non-library demo/HTML-generation code, PREFER `try`/force-unwrap over defensive `guard let`
    ceremony.** "I don't think we need to do guard let etc... just force unwrap and try". PR #332.
    The INVERSE of the fail-loud-but-typed stance in the library — a deliberate demo-code carve-out.
    Confidence: MEDIUM; risk of over-application if recorded without the scope caveat.

## Empty slices (reported honestly by the agent)

- PRs #1-#101 (2020-2021): pre-AI era, no agent corrections at all.
- PRs #380, #388-#397, #404-#423, #432-#435: zero leogdion review comments (self-authored/merged).
- PR #163: 20 comments, all blog-post editorial — content feedback, not engineering directives.
- PR #233/#227: Leo did not comment; these are the agent's own justification posts. #227's claim
  that Swift Configuration was removed for API complexity / macOS 15+ was LATER REVERSED — MistDemo
  uses Swift Configuration today. Stale agent rationale, flagged for awareness.

## Agent's suggested top five to promote

#1 (typed throws), #3 (initializer over conversion method), #5 (fix the spec, not the Swift),
#14 (LocationValue.timestamp rounding), #17 (RetryPolicy removed on purpose) — the ones where
nothing in CLAUDE.md or .claude/memory/ would stop an agent repeating the mistake tomorrow.
