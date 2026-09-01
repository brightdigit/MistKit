# Recovered — memory files the archaeology declared lost

Recovered 2026-09-01 from `~/.claude/projects/-Users-leo-Documents-Projects-MistKit/memory/`,
Claude Code's **native/global** per-project memory store.

## Why these were invisible to the 2026-09-01 archaeology pass

Both the local and remote issue-mining passes independently reported
`project_cloudkit_subscription_uniqueness.md` as a **"CONFIRMED LOSS, not a judgment call"**
(see `../2026-09-01-issue-history-mining.md` item 2 and
`../2026-09-01-issue-history-mining-remote.md` item 2 — issue #387 cites the file by name).

It was never lost. It was written on 2026-05-25 into the native store, and later the repo adopted
the rule that project memories live in-repo at `.claude/memory/` and **never** in the native store
(`AGENTS.md` §"Memory & Corrections Convention"; `.claude/agent-notes.md`;
`.cursor/rules/in-repo-memory.mdc`). The archaeology agents honored that rule as a search boundary
and only looked in-repo — so the convention that banished these files also hid them from the
project that went looking for them.

**The lesson is the finding:** a "never store X there" rule needs a one-time sweep of the place it
forbids, or content written before the rule becomes unreachable exactly when someone needs it.

## What was recovered

| File | Date | Status vs. in-repo memory |
|---|---|---|
| `project_cloudkit_subscription_uniqueness.md` | 2026-05-25 | The declared loss. Content is a superset of what `_raw/2026-09-01-issue-history-mining.md` reconstructed second-hand from issue #387 — it carries the full five-variation probe matrix. |
| `feedback_ckoperation_continuation_isolation.md` | 2026-05-14 | **No in-repo equivalent.** `CK*Operation` → async bridges must be `nonisolated` under `@MainActor` or CloudKit's callback queue trips `_dispatch_assert_queue_fail`. |
| `feedback_spm_architecture.md` | 2026-05-01 | **No in-repo equivalent.** All code in SPM library targets; the Xcode project holds only the `@main` App entry point. |
| `ORIGINAL-MEMORY-INDEX.md` | 2026-05-25 | The native store's own `MEMORY.md`, kept verbatim as provenance. Renamed so it is not mistaken for this directory's index. |

UNCURATED, like the rest of `_raw/`. Promote into real `.claude/memory/` files after human review;
`project_cloudkit_subscription_uniqueness.md` is the obvious first candidate, since issue #387
already references it by exactly that name.
