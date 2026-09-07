# MistDemo is the live-verification oracle

CloudKit wire facts exercised through MistDemo count as live-confirmed:

- MistDemo **web interface** (browser against a real container)
- `mistdemo test-public` / `mistdemo test-private` integration phases

Do **not** re-flag covered behaviors as "unproven", "needs a live container", or "one-shot archaeology only" when MistDemo already runs them. That includes (non-exhaustive): `users/caller`, `records/resolve` / `records/accept`, `createShare`, `assets/rereference` (and ASSETID tagging on that path), `ownerRecordName` / zone payload metadata, shared-zone round-trips.

Prose that still hedges those facts (some `openapi.yaml` descriptions; older archaeology `_raw/` "never live-confirmed" notes) is stale relative to MistDemo coverage — prefer MistDemo phases when they conflict.

On the `447-iosdevuk-talk` branch, `docs/what-cloudkit-got-wrong.md` ("Still unresolved" + §1 rotation gap) and `docs/what-the-ai-got-wrong.md` (Limitations §10) were refreshed against this MistDemo coverage.
