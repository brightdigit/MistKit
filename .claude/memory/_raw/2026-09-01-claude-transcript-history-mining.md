# Raw mining output: Claude Code transcripts (2026-08-25 → 2026-09-01)

Captured 2026-09-01. Source: `~/.claude/projects/*MistKit*/**/*.jsonl` — 30 files, 18.16 MB,
9 main-session + 7 subagent files carrying signal. UNCURATED.

*** READ THE SCOPE LIMIT BEFORE ANY FINDING. ***

## This corpus cannot say what the AI got wrong while writing Swift

Measured over the 8-day window:
- **53 `Edit`/`Write` calls — 47 into `~/.claude/plans/*.md`, 6 into Swift** (two files:
  `CloudKitError+ErrorDescription.swift` ×4, `CloudKitErrorTests.swift` ×2).
- **3 of 6 substantive sessions ran in plan mode.**
- 22 subagents: **13 `Explore`, 3 `Plan`, 4 `general-purpose`, 0 implementation.** Six of the
  Explore agents were the memory-archaeology project, and the final session (`57810f5c`,
  `447-iosdevuk-talk`) is **this repo mining its own transcripts to prepare a talk about AI
  mistakes.**
- Human voice across 8 days: **28 turns, 3,547 bytes, median 93 characters.**

Everything below is about **planning, research and shell usage**. Anything resembling "Context
Management" or "the AI misreads its own history" is structurally inflated, because the corpus's
subject matter *is* history-reading. Each finding carries its own inflation verdict.

*** SECURITY: `b3c184c9` at 2026-08-28T18:02:32Z contains a live-looking CloudKit web-auth token
    pasted into the chat by the human. Do not quote that record in slides or docs. ***

## Corpus statistics

67 signal records: 28 `human`, 21 `tool_error`, 11 `denial`, 7 `retraction`.

| session | branch | date | human | denial | error | retraction |
|---|---|---|---|---|---|---|
| `b3c184c9` | `main` | 08-28 | 12 | 5 | 3 | 1 |
| `c4660020` | `407-mistkitconfiguration` | 08-31 | 7 | 3 | 1 | 2 |
| `b639a361` | `407-mistkitconfiguration` | 08-31 | 3 | 2 | 4 | 2 |
| `8c848b9c` | `146-custom-zone-queries` | 08-27 | 3 | — | — | — |
| `42e5aebf` | `main` | 08-25 | 2 | — | — | — |
| `57810f5c` | `447-iosdevuk-talk` | 09-01 | 1 | 1 | — | — |
| 7 × `agent-*` | — | 08-28 → 09-01 | — | — | 13 | 2 |

**Tool-error classification — only 9 of 21 are real failures:**

| class | n |
|---|---|
| Benign non-zero exit from a compound probe (output intact) | **12** |
| **AI's own malformed shell / regex** | **5** |
| **AI re-issuing a harness-blocked command** | **2** |
| Genuine environment failure | **2** |

Honest split on the 9 real failures: **7 the AI's own doing, 2 environmental.** **None of the 21 is
a code-rework signal.**

**Retractions:** 5 genuine self-corrections (all explicitly marked — "Let me correct" ×2,
"You're right", "I was wrong", "I misread"; none hedged), 2 extractor false positives where the AI
corrects a *human-written* document rather than itself. Median claim→retraction latency **under one
minute** (44 s and 13 s in the two measurable cases).

## Findings

### F1. Declare the plan finished while open questions remain — 8 of 11 denials / 4 sessions
Presented a plan for approval right after asserting completeness. Rejected 8 times — three times in
**14 minutes** in one session, three times in **33 minutes** in another.
- AI, immediately before three rejections: *"Plan is complete and both open decisions are resolved."* ·
  *"Writing the final plan."* · *"The plan now reflects the error redesign throughout."*
- Leo's rejection notes raise **new scope**, not defects: *"should we finish setting up MistDemo
  first on this branch?"* · *"let's exclude 407 and do that in the next beta; 430 where is
  metaSyncToken documented?"* · *"do all these in parallel"*
- Theme: NEW. Confidence: HIGH *within plan-mode*, LOW as a general claim.
- **Inflated** — `ExitPlanMode` can only be denied in plan mode. What it establishes is not "the AI
  plans badly" but *"when this AI plans, the approval gate is where the human intervenes."*

### F2. Rejecting plans, never code — 11 of 11 denials
`ExitPlanMode` ×8, `AskUserQuestion` ×3. `Edit`/`Write`/`Bash`/`Task`: **0**. Across 8 days Leo
rejected zero file mutations, zero shell commands, zero subagent launches. **4 of 11 denials carry
no note at all** — the AI got a bare "no" with nothing to correct against.
- **Heavily inflated.** With 6 Swift edits in the window this is near-tautological.
  **Do NOT present as "the AI's code was trusted."**

### F3. Recommend cancelling the work instead of doing it — and be wrong — 2 episodes, overturned 2 of 2
Twice concluded from documents alone that filed work should not proceed; twice reversed by the human
demanding evidence.
- **(a) #407:** asked to implement, the AI argued the issue was obsolete and led its question with
  *"Adopt, don't extract (Recommended)"*. Leo rejected with no note and typed the counter-proposal.
  **#407 shipped: 44 files, 35 tests, three PRs across three repos.**
- **(b) #430:** recorded it *"as closing, `not planned`"* on a 2-vs-1 documentation count, noting
  *"Plan mode blocks me from running it now."* Leo: **"Can we run a quick test for this?"** The live
  container settled it — AI: *"`zones/changes` pagination in MistKit has never worked. #430 is a
  confirmed bug — closing it would have been wrong."*
- Theme: Human Guided Architecture. Confidence: MEDIUM (n=2, both documented end-to-end, both
  resolved against the AI).
- **The single most transferable finding in this corpus, and NOT archaeology-contaminated** — it was
  settled by a live CloudKit POST. Five words from the human ("Can we run a quick test for this?")
  reversed a decision to close a real bug.

### F4. Reverse the architectural verdict on first push-back — 1 clean episode
Argued at length against a new package (*"most of the issue's factual premises are no longer true"*,
*"Nothing to extract — one example to fix"*), had `ExitPlanMode` rejected with a one-sentence
question, and **reversed within 13 seconds** — without new evidence, promising to gather it after.
- AI: *"You're right, and I was drawing the line in the wrong place."*
- Confidence: MEDIUM (n=1, but the 13-second gap is unusually clean). The reversal turned out
  **correct** (see F3a) — so this is a **process** failure, not an outcome failure: **the AI's
  confidence was uncoupled from its evidence in both directions.**

### F5. State a measurement as fact, then measure it — 4 episodes / 4 of 7 retractions
Asserted quantitative facts in confident bolded prose, then ran the check and retracted.
- Claim: *"The `read()` regions are **byte-identical** once comments and access modifiers are
  normalized."* → 44 seconds later: *"Let me correct my measurement — the marker didn't match."*
- Elsewhere: *"I was wrong that typed keys fix bare boolean flags"* — the corrected version notes a
  naive migration *"would have **regressed twelve working flags** … rather than fixing three."*
- Also: *"My status filter conflated cancelled runs with failures."*
- Theme: NEW. Confidence: MEDIUM. **Mitigating: in every case the AI caught itself, usually within a
  minute, and before acting on the claim.** One of the four is archaeology-contaminated; three are not.

### F6. Write plan gates that were never executed — 2 episodes
Wrote verification commands and dependency shapes into approved plans without running them.
- Made `LINT_MODE=STRICT ./Scripts/lint.sh` the gate for every parallel lane; the lane found it
  *"does not pass on `v1.0.0-beta.4` today — 54 pre-existing violations"* and that
  *"`Scripts/lint.sh` auto-rewrites your working tree."*
- Made a tagged `url:` MistKit dependency the primary approach; it breaks the monorepo build because
  a `path:` package takes identity from its directory name — with the sting that
  ***"`swift package resolve` succeeds** — only a build catches it."*
- A planned migration to `NSURLErrorFailingURLStringErrorKey` was pointless: *"**That constant is
  itself deprecated on corelibs-foundation** — using it just relocates the warning to a new line."*
  (**Corroborates fix-don't-suppress-warnings.**)
- Confidence: MEDIUM. Caught by real Linux builds, so not archaeological.

### F7. Write bash-isms into a zsh shell — 5 of 21 tool_errors / 4 sessions
`${!v}` bash indirect expansion → `(eval):3: bad substitution`; unquoted `===` separator twice,
where zsh EQUALS-expansion tries to resolve `==` as a command; an unguarded glob →
`no matches found`, aborting the whole loop; a malformed ugrep alternation.
- The failed command was a **credential-presence probe that never ran**.
- In 3 of 5 cases the cause is a long single-shot compound command written in one go.
- Confidence: MEDIUM-HIGH for existence, LOW for rate.
- **NOT inflated by the planning skew — orthogonal to session type. The cleanest transferable
  finding after F3.** Not a rework loop: each was one bad command re-issued correctly.

### F8. Re-issue a harness-blocked command one session later — 2 of 21 tool_errors
Ran `sleep 45; echo done` to wait on subagents, was blocked with an explicit rule, and issued the
byte-identical command again 86 minutes later in the next session.
- Confidence: **LOW. Discount this.** The two instances are in *different sessions*, so this is not
  within-context forgetting — only that a harness correction doesn't cross session boundaries, which
  is expected behavior rather than a model failure. It is the one finding that maps to Context
  Management and it is the weakest in the set.

### F9. Narrate a defect without filing it or locating it — 1 of 28 human turns
Reported a third-party library bug inside a prose checkpoint, implying a tracked issue and a known
location. It had neither.
- Leo, in full: **"1. Where is this issue?\n2. Where is this broke"**
- AI: *"**1. Where is this issue? — There isn't one.** … It's item 1 on my plan's follow-up list,
  still unfiled."*
- **Corroborates "capture findings as issues not code"** by showing the failure it prevents.
  Countervailing evidence in the same corpus: the AI *did* file #444 unprompted from a live response.

### F10. Plan against the wrong reading of an ambiguous instruction — 1 of 7 retractions
Took "branch cleanup" to mean pruning stale git branches; discovered the intended meaning only when
Leo restated it. **The AI never asked** — the correction came from the human volunteering it.
- Confidence: LOW (n=1). Amplified by the human's 93-character median turn.

### F11. Report "done" at an abstraction that hides the deviation — 2 of 28 human turns
- Leo: *"did you subrepo push for MistKitConfiguration and create PR onto main?"* → AI:
  *"Done — but not the way you'd expect, and the deviation matters. … **I did not use
  `git subrepo push` to seed the repo.**"*
- Confidence: LOW. In both cases the AI disclosed fully and accurately **the moment it was asked**.
  The failure is disclosure *ordering*, not honesty — a weaker claim than it first appears.

### F12. Spend the session planning and ship nothing — 1 of 28 human turns
Given three numbered tasks, spent 67 minutes in plan mode with subagents and completed none.
- AI: *"**Nothing implemented yet — 0 of 3 tasks done.** We were in plan mode until just now, so the
  branch is untouched."*
- **Maximally inflated — the most skew-dependent finding here.** Plan mode was the operator's
  choice, and the preceding assistant turn is a platform message: *"You've hit your session limit."*
  **Use as an illustration of a hazard, never as a measured rate.**

## Non-findings — searched for, NOT present

- **`Grabby AI`: ZERO instances.** `MistKitOpenAPI` appears in 3 records, none a reach — two are the
  same SwiftPM diagnostic quoted twice, and the third is **the AI stating the rule correctly,
  unprompted**: *"Resolve `Sources/MistKitOpenAPI/Types.swift` conflicts by **re-running the
  generator**, never by hand-merging"*. Corroborates the directive as **internalized** — with the
  caveat that 6 Swift edits is far too few to test it.
- **`Unit Test Generation`: zero failures.** Every test record is a success (1002 → 1010 tests;
  35 in the new package; 994 tests / 295 suites green on Linux). **An artefact of the window, not a
  verdict.**
- **Typed throws / initializer-over-conversion: no human correction occurred.** Each appears once,
  and only because the plan being rejected was *quoting the earlier PR-mining pass's own findings*.
  **Do not double-count the mining pass's output as fresh evidence.**
- **No magic strings / no silent nil defaults: the AI applied both unprompted.** It invoked the
  repo's own memory against a proposal — *"your own `feedback_no_silent_policy_defaults` memory
  forbids shipping that as a shared default."* Directives appear internalized.
- **Revert incidental drift: zero requests in 8 days.**
- **Never commit scratch/session/plan files: this window CONTRADICTS the directive.** Leo twice
  commissioned the opposite — *"Okay save the plan as a document and commit with [skip ci] and
  push"* and *"save progress in @.claude/HANDOFF-407.md and commit and push"*. The 47 plan edits
  went to `~/.claude/plans/`, outside the repo. **Report the directive as narrower than "never write
  plan documents."**
- **No code-rework loop of any kind.** Zero Edit/Write errors, zero build failures, zero test
  failures, zero repeated-file thrash.
- **No security failure by the AI.** Offered credentials, it asked for out-of-band handoff —
  *"update the file in place rather than pasting it here… so it doesn't land in this transcript."*
  (The human pasted the token anyway. See the security note above.)
