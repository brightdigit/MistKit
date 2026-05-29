## 1.0.0-beta.2

### Subscriptions & Push Notifications
* Push Notifications & Subscriptions epic — `listSubscriptions`, `lookupSubscriptions`, `modifySubscriptions`, `createAPNsToken`, `registerAPNsToken` by @leogdion in https://github.com/brightdigit/MistKit/pull/381

### Zones
* Zone API: `createZone`, `deleteZone`, `fetchAllZoneChanges` by @leogdion in https://github.com/brightdigit/MistKit/pull/367
* `list-zones`, `modify-zones`, discover, and validate by @leogdion in https://github.com/brightdigit/MistKit/pull/368

### Assets
* Implement `assets/rereference` endpoint and API by @leogdion in https://github.com/brightdigit/MistKit/pull/393

### Batch Conveniences
* Auto-chunking conveniences for batch operations (`lookupAllRecords`, `discoverAllUserIdentities(lookupInfos:batchSize:)`) by @leogdion in https://github.com/brightdigit/MistKit/pull/389

### Correctness & Safety
* Tag and validate ambiguous `FieldValue` scalar types (`TIMESTAMP`, `BYTES`, `DOUBLE`) by @leogdion in https://github.com/brightdigit/MistKit/pull/377
* Make response→domain conversion failures loud; add `RecordResult` by @leogdion in https://github.com/brightdigit/MistKit/pull/372
* Pre-1.0.0 correctness & safety hardening by @leogdion in https://github.com/brightdigit/MistKit/pull/357
* Style & error audit: explicit import access + scoped flake gates by @leogdion in https://github.com/brightdigit/MistKit/pull/363

### Tooling, MistDemo & Docs
* Scaffold MistDemo (CLI + App + Web) for v1.0.0-beta.2 endpoints by @leogdion in https://github.com/brightdigit/MistKit/pull/371
* Wire landed MistKit endpoints into the MistDemo web app by @leogdion in https://github.com/brightdigit/MistKit/pull/396
* `setup-mistkit`: pin to resolved revision by @leogdion in https://github.com/brightdigit/MistKit/pull/380
* Enable MistDemo integration workflow on `claude/**` branches by @leogdion in https://github.com/brightdigit/MistKit/pull/374

**Full Changelog**: https://github.com/brightdigit/MistKit/compare/1.0.0-beta.1...1.0.0-beta.2

## 1.0.0-beta.1

### Querying & Sync
* Add query pagination support with continuation markers by @leogdion in https://github.com/brightdigit/MistKit/pull/306
* Add operation classification and batch sync result tracking by @leogdion in https://github.com/brightdigit/MistKit/pull/296
* `paginationLimitExceeded` now carries accumulated records by @leogdion in https://github.com/brightdigit/MistKit/pull/326

### Authentication & User Identity
* Refactor AuthenticationMiddleware so each Authenticator applies itself by @leogdion in https://github.com/brightdigit/MistKit/pull/294
* Strengthen environment and database configuration validation by @leogdion in https://github.com/brightdigit/MistKit/pull/293
* Add public + web-auth user-identity endpoints (`fetchCaller`, `discoverAllUserIdentities`, `lookupUsersByEmail`, `lookupUsersByRecordName`) by @leogdion in https://github.com/brightdigit/MistKit/pull/315

### Error Handling
* Improve error handling: typed TokenManagerError and safe RecordOperation conversion by @leogdion in https://github.com/brightdigit/MistKit/pull/305
* Move CloudKitResponseType default implementations to protocol extension by @leogdion in https://github.com/brightdigit/MistKit/pull/292

### Concurrency
* Replace custom AsyncChannel with swift-async-algorithms by @leogdion in https://github.com/brightdigit/MistKit/pull/280

### MistDemo
* MistDemo: --database flag + demo-errors command by @leogdion in https://github.com/brightdigit/MistKit/pull/282
* Refactor IntegrationTestRunner into protocol-based phase pipeline by @leogdion in https://github.com/brightdigit/MistKit/pull/283
* MistDemo improvements: test split, CRUD, auth fix, native app by @leogdion in https://github.com/brightdigit/MistKit/pull/271 / https://github.com/brightdigit/MistKit/pull/273
* Interactive MistDemo: web toggle + native app refresh by @leogdion in https://github.com/brightdigit/MistKit/pull/332

### Tooling, CI & Docs
* First draft revision of docs by @leogdion in https://github.com/brightdigit/MistKit/pull/268
* Docs refresh + CI fixes by @leogdion in https://github.com/brightdigit/MistKit/pull/309
* Test suite improvements for v1.0.0-beta.1 by @leogdion in https://github.com/brightdigit/MistKit/pull/286 / https://github.com/brightdigit/MistKit/pull/287
* CI Updates for May 2026 by @leogdion in https://github.com/brightdigit/MistKit/pull/277
* Fail lint job when any command fails, not only in STRICT mode by @leogdion in https://github.com/brightdigit/MistKit/pull/303
* Fix CI failures + review nits from PR #298 by @leogdion in https://github.com/brightdigit/MistKit/pull/322
* Add MistDemo-Integration workflow for live CloudKit runs by @leogdion in https://github.com/brightdigit/MistKit/pull/345
* v1.0.0-beta.1 follow-ups + CI fixes by @leogdion in https://github.com/brightdigit/MistKit/pull/343

**Full Changelog**: https://github.com/brightdigit/MistKit/compare/1.0.0-alpha.5...1.0.0-beta.1

## 1.0.0-alpha.5

* Add lookupZones, fetchRecordChanges, and uploadAssets operations by @leogdion in https://github.com/brightdigit/MistKit/pull/204
* Fix QueryFilter IN/NOT_IN serialization by @leogdion in https://github.com/brightdigit/MistKit/pull/205
* Migrate server-side CloudKit tutorial content by @leogdion in https://github.com/brightdigit/MistKit/pull/248

**Full Changelog**: https://github.com/brightdigit/MistKit/compare/1.0.0-alpha.4...1.0.0-alpha.5
