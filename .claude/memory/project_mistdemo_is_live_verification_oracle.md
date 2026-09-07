# MistDemo is the live-verification oracle

CloudKit wire facts exercised through MistDemo count as live-confirmed:

- MistDemo **web interface** (browser against a real container)
- `mistdemo test-public` / `mistdemo test-private` integration phases

Do **not** re-flag covered behaviors as "unproven", "needs a live container", or "one-shot archaeology only" when MistDemo already runs them. That includes (non-exhaustive): `users/caller`, `records/resolve` / `records/accept`, `createShare`, `assets/rereference` (and ASSETID tagging on that path), `ownerRecordName` / zone payload metadata, shared-zone round-trips.

Prefer MistDemo phase coverage over archaeology notes that still hedge those facts when they conflict.
