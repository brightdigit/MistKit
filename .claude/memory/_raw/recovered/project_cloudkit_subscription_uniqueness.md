---
name: CloudKit subscription uniqueness is content-based, not ID-based
description: Empirically observed: CloudKit treats subscription duplicates by (recordType, firesOn) — not by subscriptionID. Reported as misleading INTERNAL_ERROR.
type: project
originSessionId: de767511-1f68-44f7-9629-bcac9f648cf4
---
CloudKit Web Services enforces subscription uniqueness on the
`(recordType, firesOn)` tuple of a query subscription, **not** on
`subscriptionID`. Verified empirically via
`mistdemo probe-duplicate-subscription --database public` on
2026-05-25:

- Different `subscriptionID` + same `(recordType, firesOn)` → `INTERNAL_ERROR`
  with reason `"could not find subscription we just created"`.
- **Same `subscriptionID` twice** → succeeds silently (CloudKit appears to
  be idempotent on the ID; the second create returns the existing record).
- Different `firesOn` (e.g. `[.create]` vs `[.update]`) → succeeds.
- **Superset `firesOn`** (`[.create]` vs `[.create, .update]`) → succeeds.
  So uniqueness is exact-set match on `firesOn`, not overlap.

**Why:** the obvious mental model — "subscriptionID is the unique key, so
duplicate-ID creates fail" — is wrong. CloudKit re-fetches the
just-created subscription, finds the existing semantic duplicate ahead of
it, and bubbles the post-write read failure up as the generic
`INTERNAL_ERROR` with that specific reason string. There is no
`CONFLICT`/`EXISTS` code for this case.

**How to apply:** when a user hits the
`isLikelyDuplicate`/`subscriptionLikelyDuplicate` path in
`CloudKitService+ModifySubscriptions.swift`, the right remediation is
`listSubscriptions` → look for an existing subscription with the same
`(recordType, firesOn)`, not the same `subscriptionID`. If the user
*intentionally* wants two subscriptions for the same trigger, they
can't have them — CloudKit will reject the second one regardless of
the ID they pick. Document this in any future user-facing guidance and
factor it into integration test cleanup (clean by query identity, not
by ID alone).
