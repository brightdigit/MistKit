---
name: reference_management_api_request_format
description: "CloudKit Management API (schema export) host, path, auth header and error body; from CKTool JS 1.3.2, live-verified 2026-11-24 (issue #135 Phase 1)"
metadata:
  node_type: memory
  type: reference
---

Schema export is the **Management API**, not CloudKit Web Services: `GET https://api.icloud.apple.com/v1/database/teams/{teamId}/containers/{containerId}/environments/{DEVELOPMENT|PRODUCTION}/schema/export`, header `X-Apple-CloudKit-Management-Token`, `200 text/plain` CloudKit Schema Language; errors are JSON `RequestError {code, message, reason, detailedMessage?, requestUuid?, retryAfterSeconds?}`. Spec: `management-openapi.yaml` → `Sources/MistKitManagementOpenAPI/`.

**Live-verified 2026-11-24** (`iCloud.com.brightdigit.MistDemo`, `mistdemo export-schema` + curl): every part of the CKTool contract held — the token header alone is enough (no `X-CK-CLIENT`), success is `content-type: text/plain`, failures are `application/json` with `code` == HTTP status. Things CKTool didn't tell us:
- `message` is a kebab-case code, not SCREAMING_CASE: `invalid-or-expired-session` (bad token, 401), `authentication-failed` (no token, 401), `authorization-failed` (unknown/inaccessible container, **403 not 404**); a lower-case environment segment is `400` with message `Request unparseable or not as per supported schema`.
- No response carried `detailedMessage` or `retryAfterSeconds`; every one carried `requestUuid` (also echoed as the `x-apple-request-uuid` header).
- Development and production exports of MistDemo were byte-identical.
- The live MistDemo schema has drifted from the committed `Examples/MistDemo/schema.ckdb` (live has `createdAt`, `modified`, `timestamp`, `Users`, `cloudkit.share`; the file marks `___createTime`/`___modTime` QUERYABLE, live doesn't).

**Why:** issue #135's original endpoint guess (`api.apple-cloudkit.com/database/1/{container}/management/…`) was wrong; the real contract is in Apple's `@apple/cktool.api.database` / `@apple/cktool.core` 1.3.2 npm packages, now confirmed live.
**How to apply:** `CloudKitManagementService` wraps the generated client; tests use `RecordedManagementFixtures` (recorded responses, request UUIDs scrubbed). Still unknown: which team role a management token needs. Full notes in `.claude/docs/research/135-management-api-request-format.md`.
