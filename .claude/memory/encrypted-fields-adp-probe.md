---
name: encrypted-fields-adp-probe
description: Issue #392 live characterization — an ADP-enabled iCloud test account exists (2026-09-14); run `mistdemo probe-encrypted` per account, not test-private
metadata:
  type: project
---

As of 2026-09-14 Leo has an Advanced Data Protection (ADP) iCloud test account for
issue #392 (encrypted fields over CloudKit Web Services). The live comparison
(standard protection vs ADP: scenarios B0/C4, B1a/B1b/B1c, B3) is run with
`swift run mistdemo probe-encrypted` (Examples/MistDemo), one run per account's
`CLOUDKIT_WEB_AUTH_TOKEN`, and the summary block pasted into issue #392.

**Why:** `test-private` aborts on the first failing phase and `EncryptedFieldsPhase`
deletes its zone, so it cannot persist a record under standard protection and read it
back under ADP, nor reach the asset-download step once the encrypted step fails.
`lookupRecords` also has no `zoneID` parameter, so the probe defaults to `_defaultZone`.

**Results so far (2026-09-14):**
- **B0/C4 standard account — PASS.** Encrypted STRING write needs an explicit `type`
  (untagged → `BAD_REQUEST … ENCRYPTED_BYTES … defined to be: ENCRYPTED_STRING`); with
  `type: STRING` CloudKit echoes `isEncrypted: true` + plaintext on modify, lookup and
  query. Asset upload/download in the same record works. The asset came back with
  `wrappingKey`/`referenceChecksum` set (contradicts the older "never appear live" note in
  CLAUDE.md; not yet known whether that depends on the encrypted sibling field).
- **B1a ADP account — sign-in never yields a token.** CloudKit JS popup: with web access
  off → "iCloud Data Web Access is Off"; with web access on + trusted device armed via
  icloud.com → "Authentication Error — This action could not be completed." Standard
  account signs in within a minute through the same flow. Chrome HAR (2026-09-14): Apple ID
  sign-in + device approval succeed and 302 to `cdn.apple-cloudkit.com/ck-auth/` with an
  `oauth_token`; the failing step is `setup.apple-cloudkit.com/setup/ws/1/oauth/validateToken`
  → 200 `{"status":13}`, a status `ckauth.js` has no handler for (0 success, 7 TOS, 11 poll `requestPCS`, 12 web-access-off); telemetry `CKAUTHunknownError` / `CKJSUnexpectedAuthError`.
  Chrome == Safari. iCloud.com control (same ADP account): `setup.icloud.com/setup/ws/1/`
  `requestWebAccessState` → `enableDeviceConsentForPCS` → `requestPCS {appName:"notes3"}`, then
  Notes' `/database/1/com.apple.notes/production/private/*` calls all 200 incl. encrypted fields —
  first-party apps get per-app key release; third-party containers are refused before that loop.
  Research write-up: `.claude/docs/research/adp-web-auth-signin.md` §1.1.
- `records/changes` is invalid in `_defaultZone` ("cannot get changes in default zone");
  `lookupRecords` has no `zoneID`, so the probe defaults to the default zone and skips
  the changes step there (use `--zone-name` to swap which read is skipped).

**How to apply:** Prerequisite is `"secret" ENCRYPTED STRING` on `Note` deployed to the
`iCloud.com.brightdigit.MistDemo` development schema. Keep `CloudKitError` mapping as-is
(no ADP-specific case) until an ADP account actually reaches the API.

## Session handoff — 2026-09-14 (stopped for a machine restart)

**Branch `392-encrypted-fields`, all work UNCOMMITTED in the worktree** (`git status` lists it).
Tracking issue for ADP: #486. Results comment posted on #392 (links #486). Research doc:
`.claude/docs/research/adp-web-auth-signin.md` (§1.1 HAR, §1.2 `{"status":13}` + `ckauth.js` table,
§1.3 icloud.com control). Both confirmed: nothing for MistKit to handle under ADP.

### Done and verified
- `probe-encrypted` MistDemo command (5 new files under `Examples/MistDemo/Sources/MistDemoKit/`).
- MistKit fixes with tests: explicit `type` on encrypted fields (`Components.Schemas.RecordOperation`,
  `FilterBuilder.cloudKitListType` now internal); `RecordInfo` tolerant decoder; logging middleware
  64 KiB replay via `Sources/MistKit/OpenAPI/ReplayingBodyIterator.swift` (actor).
- Live B0/C4 pass; C2 filter → `BAD_REQUEST "Field 'secret' has a value type of ENCRYPTED_STRING and
  cannot be queried using filter type EQUALS"`; C2 sort → accepted, meaningless order. A1 client guard
  fires; server-side writing a schema-`ENCRYPTED` field to the **public** DB without the flag →
  per-record `BAD_REQUEST "encrypted fields are not supported in the public database"`.
- DocC: `WorkingWithRecords.md` "Encrypted fields" section + fixed stale `createRecord`/`updateRecord`
  symbol links (now include `encryptedFields:`); `AuthenticationAndDatabases.md` ADP `> Important` note.
- MistDemo `create --encrypted-fields a,b` (key `record.encrypted.fields`… see `MistDemoKeys+Record`);
  shared single-record table header now "Found 1 record(s)" and `create` prints its own ✅ line.
- Last green: MistKit 689 tests, MistDemo 1020 tests, `./Scripts/lint.sh` clean (before the last
  MistDemo edits — re-run).

### C3 answered (2026-09-14)
Writing `isEncrypted` to a field the schema declares **plain** → `BAD_REQUEST
"Attempt to save encrypted data in non encrypted field type"`. Note this differs from the
inverse direction (an `ENCRYPTED` field written **without** the flag), which reports
`invalid attempt to set value type ENCRYPTED_BYTES … defined to be: ENCRYPTED_STRING`.
The schema declaration governs; the flag must agree with it both ways. Control
(`secret:string:… --encrypted-fields secret`) succeeded and the read-back echoed
`"encryptedFields":["secret"]` with the value in plaintext. Posted to #392; the DocC
bullet "Existing fields cannot be converted" now carries both strings.

### Pitfall that cost time — RESOLVED, it was a CLI bug (issue #487)
The earlier "No fields provided" failures were **not** zsh word-splitting (each flag was
quoted explicitly and it still failed). A comma-bearing `--field` value is mis-parsed by
`CommandLineArgumentsProvider`: `MistDemoKeys.Record.field` is an `OptionalConfigKey<String>`
and swift-configuration's `arraySeparator` defaults to `,`, so the value reads back as nil
and `CreateConfig.parseFieldsFromSources` throws `noFieldsProvided`. Proof: the **same**
string via `CLOUDKIT_FIELD=…` env works; `--field "title:string:C3 probe"` (no comma, spaces
fine) works; two separate `--field` flags also fail. Pre-existing, not a #392 regression.
**Workaround for live probes: one `--field` per value, no commas, or use the env var.**

### Remaining
- ADP (#486) stays blocked — no supported way to get a `ckWebAuthToken` for a third-party
  container while ADP is on.
- `Examples/MistDemo/.env` has **two** `CLOUDKIT_WEB_AUTH_TOKEN` lines (6 and 9) with
  different values. Which wins is unverified; auth currently works, but edit the wrong one
  and you will debug a "fresh" token that is not in effect. Worth de-duplicating.
- Leave `EncryptedFieldsPhase` pre-existing lint warnings (function length, type order)
  unless cheap.
