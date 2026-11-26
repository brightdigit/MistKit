# CloudKit Management API request format (issue #135 Phase 1)

**Researched:** 2026-10-29, for Mistico W0-3b (brightdigit/Mistico#49).
**Status:** request/response contract read from Apple's published client
library, then **verified live on 2026-11-24** against
`iCloud.com.brightdigit.MistDemo` (see "Live verification" below). It is now
the OpenAPI spec `management-openapi.yaml`.

## Sources (primary)

| Source | What it gives |
|---|---|
| npm `@apple/cktool.api.database@1.3.2` — `dist/types/operations/descriptors.d.ts`, `dist/esm/index.min.js` (`exportSchemaOp`, `importSchemaOp`, `validateSchemaOp`, `resetToProductionOp`) | method, path template, response content type, security requirement per operation |
| npm `@apple/cktool.api.base@1.3.2` — `dist/types/operations/security.d.ts` | security scheme → header names |
| npm `@apple/cktool.api.base@1.3.2` — `dist/types/models/CKEnvironment.d.ts`, `RequestError.d.ts` | environment spelling, error body |
| npm `@apple/cktool.core@1.3.2` — `dist/esm/index.min.js` (`Configuration`) | default `serverUrl`, path-parameter encoding, `X-CK-CLIENT` header |
| Apple, *Automating CloudKit Development* — https://developer.apple.com/icloud/cloudkit/automating/ | management token scope and lifetime |
| Apple, *Using cktool* — https://developer.apple.com/icloud/ck-tool/ | where tokens come from; `export-schema` CLI |

The previous guess in issue #135 (`https://api.apple-cloudkit.com/database/1/{container}/management/schema`) is **wrong**.

## Export schema

```
GET https://api.icloud.apple.com/v1/database/teams/{teamId}/containers/{containerId}/environments/{environment}/schema/export
X-Apple-CloudKit-Management-Token: <management token>
```

- `serverUrl` default in `@apple/cktool.core`: `https://api.icloud.apple.com`.
- `{environment}` is `CKEnvironment`: `DEVELOPMENT` or `PRODUCTION` (upper case).
- Path parameters are escaped with `encodeURIComponent`.
- `security: [["CookieAuth"], ["ManagementTokenAuth"]]` — either the `myacinfo`
  console cookie or the management-token header. User tokens and API tokens are
  not accepted for schema operations.
- Success: `200`, `contentType: "text/plain"`, "Returns a schema file" — CloudKit
  Schema Language text, as `cktool export-schema` writes to `.ckdb`.
- Failure (any other status, `0` = default): `application/json` `RequestError`:
  `code` (Int32, HTTP status), `message` (error code string), `reason`,
  `detailedMessage?`, `requestUuid?`, `retryAfterSeconds?`.
- CKTool JS also sends `X-CK-CLIENT: cktooljs-<version>`. MistKit doesn't; it
  isn't part of the security contract, and live calls succeed without it.

## Other schema operations (Phase 2+, not implemented)

| Operation | Method | Path (after `/v1/database/teams/{teamId}/containers/{containerId}`) | Auth |
|---|---|---|---|
| `importSchema` | PUT | `/environments/{environment}/schema` (multipart file) | management token |
| `validateSchema` | POST | `/environments/{environment}/schema/validate` → `{isValid, errorMessage?}` | management token |
| `resetToProduction` | POST | `/environments/{environment}/reset` | not checked |
| `resetConfigToProduction` | POST | `/containerConfig/reset` | user token / cookie |

`@apple/cktool.api.base` also has `getTeams` (`GET /users/current/teams`) and
`getContainers` (`GET /teams/{teamId}/containers`), both management-token
operations — useful for a team/container picker later.

## Management token

Apple: "A CloudKit management token is scoped to a team and user, and allows
access to the CloudKit management APIs. The management tokens have a default
lifespan of one year and can be revoked from the Settings section of CloudKit
Dashboard." Created in CloudKit Console → account Settings; shown once.

Not documented anywhere found: which team role (Account Holder / Admin /
Developer) may create or use one. Still unconfirmed: the 2026-11-24 live run
used one account's token only.

## Live verification (2026-11-24)

Run with `swift run mistdemo export-schema` and `curl` against
`iCloud.com.brightdigit.MistDemo`. Recorded bodies (request UUIDs scrubbed)
are in `Tests/MistKitTests/Management/RecordedManagementFixtures.swift`.

| Request | Status | Body |
|---|---|---|
| `DEVELOPMENT` export, valid token | `200`, `content-type: text/plain` | the schema (1,675 bytes) |
| `PRODUCTION` export, valid token | `200` | byte-identical to development |
| invalid token | `401`, `application/json` | `{"code":401,"message":"invalid-or-expired-session","reason":"Failed to validate management token","requestUuid":…}` |
| no token header | `401` | `message: authentication-failed`, `reason: There was a problem with your request.` |
| unknown container | **`403`** | `message: authorization-failed`, `reason: User doesn't have access to container or container does not exist` |
| lower-case `development` | `400` | `message: Request unparseable or not as per supported schema` |

Findings beyond CKTool JS's declarations:
- `message` is a kebab-case code, not SCREAMING_CASE.
- An unknown container is `403`, not `404`; it is indistinguishable from a
  container the token's user can't access.
- `code` always equalled the HTTP status. No response carried
  `detailedMessage` or `retryAfterSeconds`; every one carried `requestUuid`
  (also sent as the `x-apple-request-uuid` header).
- The environment segment is case-sensitive (upper case only).
- The live MistDemo schema has drifted from the committed
  `Examples/MistDemo/schema.ckdb`.

