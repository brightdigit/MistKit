---
name: reference_cloudkit_archived_endpoints
description: "The repo's .claude/docs/webservices.md is incomplete — verify CloudKit endpoints against Apple's archived reference, not just local docs"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 85eb85c8-acee-4c14-9f93-0db663866771
---

`.claude/docs/webservices.md` is a **partial scrape, not the reference** — and it is far more
incomplete than its 289 KB suggests. It contains exactly **two** endpoint headings:
`users/current` and `records/modify`. Verified counts (2026-09-01) — every one of these returns
**zero** hits:

`zones/changes` · `changes/database` · `changes/zone` · `records/changes` · `records/resolve` ·
`records/accept` · `assets/rereference` · `tokens/create` · `metaSyncToken` · `syncToken` ·
`moreComing` · `continuationMarker` · `"Zone Dictionary"`

Most of the remaining bulk is `CloudKitQuickStart` / `iCloudDesignGuide` filler, plus at least
four literal `# The page you're looking for can't be found.` blocks where the scrape 404'd.

**The trap:** grepping this file for almost any endpoint returns zero, and zero reads as proof
of absence. Never conclude an endpoint "doesn't exist" — or that a key is unused — from
grepping local docs alone. Go to Apple's archived reference, and prefer a live call over both.

Authoritative source: Apple's archived CloudKit Web Services Reference, e.g. `assets/rereference` at https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/RereferenceAssets.html

`POST /database/1/{container}/{env}/{database}/assets/rereference` — request `{ zoneID?, assets: [{ recordName, fieldName }] }`, response = array of Asset dictionaries reusable to set asset fields on other records without re-upload (asset deduplication). Tracked in issue #31. Related: [[feedback_findings_to_issues_not_code]].
