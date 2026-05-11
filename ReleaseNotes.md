## 1.0.0-beta.1

### Querying & Sync
* Add query pagination support with continuation markers by @leogdion in https://github.com/brightdigit/MistKit/pull/306
* Add operation classification and batch sync result tracking by @leogdion in https://github.com/brightdigit/MistKit/pull/296

### Authentication
* Refactor AuthenticationMiddleware so each Authenticator applies itself by @leogdion in https://github.com/brightdigit/MistKit/pull/294
* Strengthen environment and database configuration validation by @leogdion in https://github.com/brightdigit/MistKit/pull/293

### Error Handling
* Improve error handling: typed TokenManagerError and safe RecordOperation conversion by @leogdion in https://github.com/brightdigit/MistKit/pull/305
* Move CloudKitResponseType default implementations to protocol extension by @leogdion in https://github.com/brightdigit/MistKit/pull/292
* **Breaking:** `CloudKitError.paginationLimitExceeded` now carries `records: [RecordInfo]` instead of `recordsCollected: Int`. When `queryAllRecords` / `fetchAllRecordChanges` exceed `maxPages`, callers can pattern-match the error to recover every record collected before the cap. `fetchAllRecordChanges` gains an explicit `maxPages:` parameter and no longer throws the generic `.invalidResponse` on overflow. Resolves [#313](https://github.com/brightdigit/MistKit/issues/313).

### Concurrency
* Replace custom AsyncChannel with swift-async-algorithms by @leogdion in https://github.com/brightdigit/MistKit/pull/280

### MistDemo
* MistDemo: --database flag + demo-errors command by @leogdion in https://github.com/brightdigit/MistKit/pull/282
* Refactor IntegrationTestRunner into protocol-based phase pipeline by @leogdion in https://github.com/brightdigit/MistKit/pull/283
* MistDemo improvements: test split, CRUD, auth fix, native app by @leogdion in https://github.com/brightdigit/MistKit/pull/271 / https://github.com/brightdigit/MistKit/pull/273

### Tooling & CI
* Test suite improvements for v1.0.0-beta.1 by @leogdion in https://github.com/brightdigit/MistKit/pull/286 / https://github.com/brightdigit/MistKit/pull/287
* CI Updates for May 2026 by @leogdion in https://github.com/brightdigit/MistKit/pull/277
* Fail lint job when any command fails, not only in STRICT mode by @leogdion in https://github.com/brightdigit/MistKit/pull/303

**Full Changelog**: https://github.com/brightdigit/MistKit/compare/1.0.0-alpha.5...1.0.0-beta.1

## 1.0.0-alpha.5

* Add lookupZones, fetchRecordChanges, and uploadAssets operations by @leogdion in https://github.com/brightdigit/MistKit/pull/204
* Fix QueryFilter IN/NOT_IN serialization by @leogdion in https://github.com/brightdigit/MistKit/pull/205
* Migrate server-side CloudKit tutorial content by @leogdion in https://github.com/brightdigit/MistKit/pull/248

**Full Changelog**: https://github.com/brightdigit/MistKit/compare/1.0.0-alpha.4...1.0.0-alpha.5
