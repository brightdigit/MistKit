---
name: project-change-tracking-custom-zones-only
description: CloudKit change tracking (changes/zone, records/changes) works only in custom zones, not _defaultZone — confirmed
metadata:
  type: project
---

CloudKit tracks changes only in custom zones: `changes/zone` and `records/changes` are rejected for `_defaultZone`. Leo confirmed this on 2026-11-24 (it was already asserted in MistDemo's `ChangeTrackingVerification.swift` / `FetchRecordZoneChangesPhase.swift`).

**Why:** the `SyncingChanges` DocC guide states it; reviewers flagged it as unverified until Leo confirmed.

**How to apply:** treat it as live-confirmed; don't re-flag it as unproven. Related: [[project-mistdemo-is-live-verification-oracle]].
