# CloudKit Limits and Performance

CloudKit caps per-request work and per-account throughput. This article documents the limits MistKit enforces itself, the limits CloudKit enforces server-side, and the design choices in MistKit that shape performance.

## Overview

CloudKit Web Services is a remote API with per-request size limits and per-account rate limits. MistKit adds two small guards of its own — a page cap on auto-pagination and a transport-pool separation for asset uploads — and otherwise defers to CloudKit's documented limits.

| Concern | Enforced where | Notes |
| --- | --- | --- |
| Records per query response | CloudKit | Max 200; the `limit` parameter is validated 1–200. |
| Pages per auto-paginated query | MistKit | `maxPages: 1_000` on ``CloudKitService/queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:database:)``. |
| Records per modify batch | CloudKit | Practical cap around 200; chunk larger batches client-side. |
| Asset upload size / connection pool | MistKit (transport separation) | `URLSession.shared` used for CDN uploads to avoid HTTP/2 reuse with the API host. |
| Requests per second | CloudKit | Server-side rate limit; surfaces as 503/429. |

## Pagination guard

``CloudKitService/queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:database:)`` walks CloudKit's `continuationMarker` for you. Two safeguards prevent runaway iteration:

1. **`maxPages` cap (default `1_000`)** — if the auto-paginator hits the cap, it throws ``CloudKitError/paginationLimitExceeded(maxPages:records:)``. The records collected so far are attached to the error so the caller can resume from a narrowed query or accept a partial result.
2. **Stuck-marker detection** — if CloudKit returns an empty page with the same continuation marker it just gave you, the paginator stops cleanly rather than spinning. This guards against a server-side bug pattern where the cursor never advances.

```swift
do {
  let all = try await service.queryAllRecords(
    recordType: "AuditEvent",
    pageSize: 200,
    database: .private
  )
} catch CloudKitError.paginationLimitExceeded(let cap, let partial) {
  // Either accept partial, raise `maxPages`, or narrow the query with filters.
}
```

Raise `maxPages` when you know the result set is genuinely large. Narrow filters when you don't — most production queries return well under 1,000 pages.

## Batching writes

CloudKit's `/records/modify` endpoint accepts a batch of operations in a single round-trip. The practical server-side cap is around 200 operations per request. ``CloudKitService/modifyRecords(_:atomic:database:)`` does not chunk for you — split larger batches yourself:

```swift
let chunked = stride(from: 0, to: operations.count, by: 200).map {
  Array(operations[$0..<min($0 + 200, operations.count)])
}
for chunk in chunked {
  _ = try await service.modifyRecords(chunk, atomic: false, database: .private)
}
```

| Choice | When to prefer |
| --- | --- |
| Single-op (`createRecord`, etc.) | Independent operations triggered by user actions; readability over throughput |
| Batched (`modifyRecords`, `atomic: false`) | Throughput-bound work where independent operations can share a request |
| Batched (`modifyRecords`, `atomic: true`) | Semantically linked operations that must commit together |

`atomic: true` is more expensive server-side and fails the entire batch on any one failure. Use it only when the operations are genuinely transactional.

## Asset upload transport

Asset uploads are a two-step workflow: ``CloudKitService/requestAssetUploadURL(recordType:fieldName:recordName:database:)`` returns a one-time URL on `cvws.icloud-content.com`, then ``CloudKitService/uploadAssetData(_:to:using:)`` PUTs the bytes there. MistKit's high-level ``CloudKitService/uploadAssets(data:recordType:fieldName:recordName:using:database:)`` chains both steps.

The CDN upload deliberately does **not** flow through the configured ``ClientTransport``. It uses `URLSession.shared` directly:

> Warning: CloudKit's API host (`api.apple-cloudkit.com`) and asset CDN (`cvws.icloud-content.com`) are different origins. Reusing the same HTTP/2 connection across both produces 421 Misdirected Request errors. Asset uploads keep a separate connection pool to avoid this.

This has two implications for consumers:

1. **Custom transports do not see asset upload bytes.** If you instrumented `transport:` to log requests, asset uploads will be missing.
2. **A custom ``AssetUploader`` must keep its connection pool separate from the API host.** The default implementation uses `URLSession.shared`; only override it for testing or specialized CDN configurations, and never share an HTTP/2 connection with `api.apple-cloudkit.com`.

```swift
// Default: production-safe, separate connection pool.
let receipt = try await service.uploadAssets(
  data: imageData,
  recordType: "Photo",
  fieldName: "image",
  database: .private
)

// Testing: inject a mock uploader.
let receipt = try await service.uploadAssets(
  data: imageData,
  recordType: "Photo",
  fieldName: "image",
  using: { data, url in (statusCode: 200, data: Data()) },
  database: .private
)
```

CloudKit imposes a per-asset size cap (in the tens of megabytes, exact figure documented in [CloudKit Web Services](https://developer.apple.com/documentation/cloudkitwebservices)). Oversized uploads surface as ``CloudKitError/httpErrorWithDetails(statusCode:serverErrorCode:reason:)`` from the CDN.

## Rate limiting

CloudKit enforces per-account and per-container rate limits server-side. The exact thresholds vary by account tier and are documented by Apple — MistKit does not duplicate the canonical numbers. Surfaces are:

- HTTP 503 with retry-after — back off and retry.
- HTTP 429 — back off and retry.
- HTTP 5xx generally — treat as transient.

See <doc:HandlingErrors> for the retry helper pattern. Read ``CloudKitError/httpStatusCode`` to branch on status without switching on every `httpError*` case.

> Tip: Hammering the API from a hot loop (sync jobs, migrations) is the usual way to trip rate limits. Throttle long-running tasks to a few requests per second per container, and concentrate concurrency in `modifyRecords` batches rather than in many parallel single-record calls.

## Connection reuse for the API host

By default ``CloudKitService`` uses `URLSessionTransport` from `swift-openapi-urlsession`, which gives you HTTP/2 multiplexing against `api.apple-cloudkit.com` automatically. There is no per-call session — every operation through one ``CloudKitService`` shares the underlying URLSession's connection pool, so a burst of operations does not pay TCP/TLS setup per call.

For custom transports, prefer one transport per `CloudKitService` and reuse the same `CloudKitService` across calls. Creating a fresh service per request defeats connection reuse.

## Topics

### Limits

- ``CloudKitError/paginationLimitExceeded(maxPages:records:)``
- ``CloudKitService/queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:database:)``
- ``CloudKitService/modifyRecords(_:atomic:database:)``

### Asset uploads

- ``CloudKitService/uploadAssets(data:recordType:fieldName:recordName:using:database:)``
- ``CloudKitService/requestAssetUploadURL(recordType:fieldName:recordName:database:)``
- ``CloudKitService/uploadAssetData(_:to:using:)``
- ``AssetUploader``

### See Also

- <doc:WorkingWithRecords>
- <doc:HandlingErrors>
- <doc:ConfiguringMistKit>
