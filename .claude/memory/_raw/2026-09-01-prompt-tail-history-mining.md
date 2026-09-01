# Raw mining output: the prompt-only tail (2025-10-20 → 2026-09-01)

Captured 2026-09-01. Source: `~/.claude/history.jsonl`, filtered to records whose `project` path
contains "MistKit". UNCURATED.

**This corpus has ONE VOICE.** `history.jsonl` stores only what the human typed — no assistant
replies, no tool calls. Every finding here is therefore a complaint with no defendant: you can see
that Leo corrected something, never what was corrected or whether the correction landed. All
findings cap at SPECULATIVE by construction.

## Corpus statistics (measured, frozen)

| metric | value |
|---|---|
| MistKit-path records | 1,307 |
| slash-commands (dropped) | 351 (26.9%) |
| real prompts analyzed | **956** |
| prompt length | p50 **44 chars**, p90 162, p99 457, max 4,547 |

Per-month real prompts:

| 2025-10 | 2025-11 | 2025-12 | 2026-01 | 2026-02 | 2026-04 | 2026-05 | 2026-06 | 2026-07 | 2026-08 | 2026-09 |
|---|---|---|---|---|---|---|---|---|---|---|
| 21 | **400** | 18 | 42 | **154** | 42 | **245** | 1 | 7 | 25 | 1 |

Only **2025-11, 2026-02, 2026-05** carry enough mass to compare rates. Three points is a sequence,
not a trend — no line should be drawn through them.

## Correction-phrase tagging (multi-label; a prompt may carry several)

| tag | n | of 956 |
|---|---|---|
| recurrence (`again`/`still`/`keep`/`repeatedly`) | 51 | 5.3% |
| prohibition (`don't`/`do not`/`shouldn't`) | 42 | 4.4% |
| substitute (`instead`/`rather than`/`prefer`) | 16 | 1.7% |
| flat_no (opens with `no`/`nope`/`wrong`) | 14 | 1.5% |
| why_q (`why did/are/is/can't…`) | 14 | 1.5% |
| revert (`revert`/`undo`/`roll back`/`restore`) | 8 | 0.8% |
| defect (`wrong`/`incorrect`/`mistake`/`broke`) | 7 | 0.7% |
| directive (`always`/`never`) | 3 | 0.3% |
| **union** | **141** | **14.7%** |
| `i told you` | **0** | — |
| `you already` | **0** | — |
| `stop doing` | **0** | — |

**Precision caveat, stated rather than filtered away:** a visible share of tagged prompts are
*pasted* review text, CI logs, or code comments rather than Leo's own words (`pastedContents` is
non-empty on some; p99 length 457 vs p50 44 shows the tail is pasted material). Treat the union of
141 as an upper bound on genuine corrections.

## The zero results are the finding

`i told you` = 0/956. `you already` = 0/956. `stop doing` = 0/956. Across ten months and 956
prompts Leo never once expresses exasperation at repetition in those words. Combined with the
**44-character median**, this independently corroborates the remote PR pass's characterization —
*"the corrections are TERSE — Leo reviews in short imperative fragments"* — from a completely
different corpus. Two independent sources, same conclusion.

## Verbatim exemplars (unedited; short prompts quoted in full)

**Reaching past the curated API into generated OpenAPI code** — the "Grabby AI" theme, twice, in
Leo's own words:
- "OpenAPI types shouldn't be available. We need those abstractions built."
- "Why are using the OpenAPI types instead of the available types in MistKit? What is missing?"

**Flat rejections:**
- "no keep it the same"
- "No we did need that"
- "no I want them committed"
- "no let me reset the schema and give you a new keyid"
- "No it does have some support. Read https://github.com/swiftlang/swift-format/blob/main/Documentation/IgnoringSource.md"

**Reverts:**
- "okay. let's undo that."
- "Let's create a github issue for this for now. Undo the change to @.swiftlint.yml"
- "It looks like we deleted the example it's in the main branch at Examples. Restore it and move it to Examples/MistDemo"
- "undo that. I meant concerning the explaination of the openapi generator should be near the beginning…"

**Substitutions:**
- "Can we use logging instead of print/debugPrint?"
- "Use Data(someString.utf8) instead of force unwrapping."
- "Could it be an array or tuple of types instead?"

**Challenges to unverified claims:**
- "shouldn't the limit be 200? What's the documented limit?"
- "How is it used because I don't see a boolean field type in CloudKit?"
- "Why can't you use the Swift Package?"
- "why are you analyzing those directories?"

Note "Let's create a github issue for this for now. Undo the change to @.swiftlint.yml" is a single
prompt carrying **two** prior-art directives at once — capture-findings-as-issues *and*
revert-incidental-drift.

## What this corpus categorically cannot show

- **No cause.** "no keep it the same" corrects *something*; that something is unrecoverable.
- **No outcome.** Whether a correction landed, was repeated, or was ignored is invisible.
- **No repetition detection.** Knowing two prompts corrected *the same thing* needs the assistant
  side. Clustering on Leo's phrasing conflates "use an initializer" said about two different types
  with the same thing said twice — so this corpus cannot confirm the PR pass's "signal is in
  repetition" claim, only echo its terseness observation.
- **Survivorship bias.** Full transcripts for 2025-10-20 → 2026-08-24 were rotated away; this is
  the only surviving record of ten months, and it is one-sided. There is no way to prove 1,307 is
  the true total.
- **`display` is the pre-submission buffer**, not the sent message: it includes pasted blocks and
  drafts, and 26.9% of it is slash-commands.
