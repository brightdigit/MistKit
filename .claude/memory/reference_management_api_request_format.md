---
name: reference_management_api_request_format
description: "CloudKit Management API (schema export) host, path, auth header and error body, from CKTool JS 1.3.2 (issue #135 Phase 1)"
metadata:
  node_type: memory
  type: reference
---

Schema export is the **Management API**, not CloudKit Web Services: `GET https://api.icloud.apple.com/v1/database/teams/{teamId}/containers/{containerId}/environments/{DEVELOPMENT|PRODUCTION}/schema/export`, header `X-Apple-CloudKit-Management-Token`, `200 text/plain` CloudKit Schema Language; errors are JSON `RequestError {code, message, reason, detailedMessage?, requestUuid?, retryAfterSeconds?}`.

**Why:** issue #135's original endpoint guess (`api.apple-cloudkit.com/database/1/{container}/management/…`) was wrong; the real contract is in Apple's `@apple/cktool.api.database` / `@apple/cktool.core` 1.3.2 npm packages.
**How to apply:** `CloudKitManagementService` implements it; full notes and sources in `.claude/docs/research/135-management-api-request-format.md`. Not yet live-verified — the first live export should confirm it and replace the provisional test fixtures.
