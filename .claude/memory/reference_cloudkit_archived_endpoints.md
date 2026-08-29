---
name: reference_cloudkit_archived_endpoints
description: "The repo's .claude/docs/webservices.md is incomplete — verify CloudKit endpoints against Apple's archived reference, not just local docs"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 85eb85c8-acee-4c14-9f93-0db663866771
---

The local `.claude/docs/webservices.md` does NOT cover every CloudKit Web Services endpoint. Notably it omits `assets/rereference`. Do not conclude an endpoint "doesn't exist" from grepping local docs alone.

Authoritative source: Apple's archived CloudKit Web Services Reference, e.g. `assets/rereference` at https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/RereferenceAssets.html

`POST /database/1/{container}/{env}/{database}/assets/rereference` — request `{ zoneID?, assets: [{ recordName, fieldName }] }`, response = array of Asset dictionaries reusable to set asset fields on other records without re-upload (asset deduplication). Tracked in issue #31. Related: [[feedback_findings_to_issues_not_code]].
