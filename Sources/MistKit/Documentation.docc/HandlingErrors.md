# Handling Errors

Three layers of typed errors — construction, authentication, and request — surface MistKit failures with enough detail to route, retry, or report.

## Overview

Every MistKit failure is one of a small set of typed errors thrown at a specific layer:

| Layer | Error type | Surfaces from |
| --- | --- | --- |
| Construction | ``CredentialsValidationError`` | ``Credentials`` initializer |
| Token management | ``TokenManagerError`` | Token manager resolution and refresh |
| Token storage | ``TokenStorageError`` | Custom ``TokenStorage`` implementations |
| Request | ``CloudKitError`` | Every ``CloudKitService`` operation |

Operation methods declare typed throws — `async throws(CloudKitError)` — so the compiler enforces exhaustive switching at the call site if you choose to switch.

## Construction-time validation

``Credentials`` runs cheap validation on the values you pass in. The only thrown case is ``CredentialsValidationError/empty``, raised when neither ``Credentials/serverToServer`` nor ``Credentials/apiAuth`` is populated:

```swift
do {
  let credentials = try Credentials()  // both nil
} catch CredentialsValidationError.empty {
  // Misconfigured deployment — log and exit, this is a programming error.
}
```

Deeper per-field reasons (empty token, malformed PEM, key-ID format) live in ``InvalidCredentialReason`` and surface later, wrapped in ``TokenManagerError/invalidCredentials(_:)``, when the credentials are actually used to authenticate.

> Note: In debug builds, ``Credentials/init(serverToServer:apiAuth:)`` asserts on empty input. In release it throws. Treat this as a configuration check at process start, not a runtime branch.

## Token manager errors

``TokenManagerError`` is thrown from authentication resolution — when MistKit picks a token manager for the current call's ``Database``, validates its inputs, or signs the outgoing request.

| Case | Recoverable? | Typical cause |
| --- | --- | --- |
| ``TokenManagerError/invalidCredentials(_:)`` | No | Malformed token or key surfaces at first use |
| ``TokenManagerError/authenticationFailed(_:)`` | Sometimes | Server-side rejection or signing error |
| ``TokenManagerError/tokenExpired`` | Yes | Refresh the web-auth token and retry |
| ``TokenManagerError/networkError(_:)`` | Yes | Transient connectivity during auth |
| ``TokenManagerError/internalError(_:)`` | No | Bug or missing platform support |

The wrapped reason enums (``InvalidCredentialReason``, ``AuthenticationFailedReason``, ``NetworkErrorReason``, ``InternalErrorReason``) carry the concrete cause and a human-readable `description`. Switch on the wrapper first, then on the reason if you need to act on it:

```swift
do {
  _ = try await service.fetchCaller()
} catch let error as TokenManagerError {
  switch error {
  case .tokenExpired:
    try await refreshWebAuthToken()
  case .invalidCredentials(let reason):
    logger.error("Bad credentials: \(reason.description)")
  case .networkError, .authenticationFailed, .internalError:
    throw error
  }
}
```

> Tip: ``TokenManagerError/invalidCredentials(_:)`` with reason ``InvalidCredentialReason/serverToServerOnlySupportsPublicDatabase(_:)`` indicates a programming error — you tried `.private` or `.shared` with server-to-server credentials. Fix the call site; do not retry.

## Token storage errors

``TokenStorageError`` is for custom ``TokenStorage`` implementations — keychain wrappers, encrypted file stores, remote secret managers. The built-in `InMemoryTokenStorage` never throws it. If you implement ``TokenStorage`` yourself, raise these so MistKit's diagnostics stay consistent:

- ``TokenStorageError/storageFailed(reason:)`` — write failed, include backend detail
- ``TokenStorageError/notFound(identifier:)`` — credential lookup missed
- ``TokenStorageError/accessDenied`` — OS-level permission failure (keychain locked, etc.)
- ``TokenStorageError/corruptedStorage`` — stored bytes failed to deserialize

## Request errors

Every operation on ``CloudKitService`` throws ``CloudKitError``. The cases group naturally by recoverability:

| Case | Recoverable? | When it fires |
| --- | --- | --- |
| ``CloudKitError/httpError(statusCode:)`` | Depends on status code | HTTP non-2xx without parseable body |
| ``CloudKitError/httpErrorWithDetails(statusCode:serverErrorCode:reason:)`` | Depends on `serverErrorCode` | CloudKit returned a structured error |
| ``CloudKitError/httpErrorWithRawResponse(statusCode:rawResponse:)`` | Sometimes | Validation rejection or unparseable error body |
| ``CloudKitError/invalidResponse`` | No | Server returned 2xx but no payload |
| ``CloudKitError/incompleteResponse(reason:)`` | No | A composed convenience got a valid response missing data it needed |
| ``CloudKitError/networkError(_:)`` | Often | URLSession-level failure (timeout, DNS, TLS) |
| ``CloudKitError/decodingError(_:)`` | No | Schema mismatch between OpenAPI client and CloudKit |
| ``CloudKitError/underlyingError(_:)`` | Depends | Unclassified throw from the transport stack |
| ``CloudKitError/unsupportedOperationType(_:)`` | No | Bug — server returned a record op MistKit doesn't model |
| ``CloudKitError/paginationLimitExceeded(maxPages:records:)`` | Yes — but inspect | Auto-paginator hit its guard with records still collected |
| ``CloudKitError/missingCredentials(database:availability:reason:)`` | No | The configured ``Credentials`` don't cover the call's database/auth combo |
| ``CloudKitError/invalidPrivateKey(path:underlying:)`` | No | S2S key file is missing, unreadable, or not a valid ECDSA P-256 PEM |

Use ``CloudKitError/httpStatusCode`` to read the status code uniformly across the three `httpError*` cases without switching:

```swift
do {
  let records = try await service.queryRecords(
    recordType: "Note",
    database: .private
  ).records
} catch let error as CloudKitError {
  if let status = error.httpStatusCode, (500..<600).contains(status) {
    // Transient — caller can retry with backoff.
    throw RetryableError.serverError(status)
  }
  throw error
}
```

### `paginationLimitExceeded` carries partial results

``CloudKitService/queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:database:)`` walks the continuation marker for you and stops at `maxPages` (default `1_000`) as a runaway guard. When it trips, the records collected so far are attached to the error so the caller can decide:

```swift
do {
  let all = try await service.queryAllRecords(
    recordType: "AuditEvent",
    pageSize: 200,
    database: .private
  )
} catch CloudKitError.paginationLimitExceeded(let maxPages, let partial) {
  logger.warning("Stopped after \(maxPages) pages with \(partial.count) records")
  // Either accept the partial result, raise the cap, or narrow the query.
}
```

## Retry and recovery

Recoverable failures fall into three buckets:

1. **Transient network** (``CloudKitError/networkError(_:)``, ``TokenManagerError/networkError(_:)``) — retry with exponential backoff and a jitter, bounded to ~3 attempts.
2. **Expired web-auth token** (``TokenManagerError/tokenExpired``) — refresh the token in your token store, then retry the call once.
3. **5xx HTTP** (``CloudKitError/httpStatusCode`` in `500..<600`) — same backoff strategy as transient network.

Everything else — auth failures, decoding errors, missing credentials, 4xx HTTP — is a programming or configuration error. Surface it, do not retry.

A minimal retry helper:

```swift
func retrying<T>(
  attempts: Int = 3,
  _ operation: () async throws -> T
) async throws -> T {
  var lastError: any Error
  for attempt in 1...attempts {
    do {
      return try await operation()
    } catch let error as CloudKitError where isTransient(error) {
      lastError = error
      try await Task.sleep(for: .milliseconds(100 * (1 << attempt)))
    } catch {
      throw error
    }
  }
  throw lastError
}

func isTransient(_ error: CloudKitError) -> Bool {
  if case .networkError = error { return true }
  if let status = error.httpStatusCode, (500..<600).contains(status) {
    return true
  }
  return false
}
```

> Warning: Do not retry ``CloudKitError/missingCredentials(database:availability:reason:)`` or ``CloudKitError/invalidPrivateKey(path:underlying:)``. These indicate the deployment is misconfigured and the next attempt will fail identically.

## Topics

### Error types

- ``CloudKitError``
- ``TokenManagerError``
- ``TokenStorageError``
- ``CredentialsValidationError``

### Failure reasons

- ``InvalidCredentialReason``
- ``AuthenticationFailedReason``
- ``NetworkErrorReason``
- ``InternalErrorReason``
- ``CredentialAvailability``
