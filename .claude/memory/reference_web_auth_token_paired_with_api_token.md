---
name: web-auth-token-paired-with-api-token
description: A CloudKit web-auth token only works with the API token + container that minted it; a 421 in CI with fresh tokens means the CLOUDKIT_API_TOKEN/CONTAINER_ID secrets are stale
metadata:
  type: reference
---

A CloudKit web-auth token is bound to the API token (and container) used to mint
it. Verified 2026-11-25: freshly captured `CLOUDKIT_WEB_AUTH_TOKEN` /
`CLOUDKIT_SHAREE_WEB_AUTH_TOKEN` passed `mistdemo test-private` locally but the
"Live CloudKit Integration" job still failed with HTTP 421
`AUTHENTICATION_REQUIRED`, because the repo's `CLOUDKIT_API_TOKEN` secret
(2026-05-14) was not the API token in `MistDemo.env`. Setting
`CLOUDKIT_API_TOKEN` + `CLOUDKIT_CONTAINER_ID` from `MistDemo.env` fixed it.
`test-public` kept passing throughout because it signs with the
server-to-server key, not web-auth.

**How to apply:** refresh all of them together with
`./Scripts/refresh-web-auth-tokens.sh --update-env --rerun`, which pushes the
API token + container pair along with the tokens.
