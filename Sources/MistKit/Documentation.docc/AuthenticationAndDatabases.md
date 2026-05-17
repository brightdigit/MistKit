# Authentication and Databases

Configure ``CloudKitService`` once with the credentials it needs, then pick a ``Database`` — and, for `.public`, a signing method — at every call site.

## Overview

CloudKit Web Services accepts three authentication schemes, and only some scheme/database combinations are legal:

| Database | API token | Web auth | Server-to-server |
| --- | :-: | :-: | :-: |
| `.public` | read-only | ✓ user-attributed | ✓ developer-attributed |
| `.private` | — | ✓ | — |
| `.shared` | — | ✓ | — |

The same backend legitimately needs both attribution paths — server-attributed writes against the public database (catalog seeds, moderation actions) and user-attributed reads against `users/caller` (knowing which iCloud user a session belongs to). MistKit models this by:

1. Letting ``CloudKitService`` hold a ``Credentials`` value that carries either or both credential sets.
2. Making the target ``Database`` an argument on each operation, with `.public` carrying a ``PublicAuthPreference`` that picks the signing method *for that call*.

Configuration is what's available; the call site picks what to use.

## Construct credentials

``Credentials`` holds an optional ``APICredentials`` and/or ``ServerToServerCredentials``. At least one must be present — an empty value asserts in debug and throws ``CredentialsValidationError/empty`` in release.

### API token (with optional web-auth token)

The API token alone gives container-level access to the public database. Add a web-auth token to operate as a specific iCloud user — required for `.private` and `.shared`, and for any user-identity route.

```swift
let credentials = try Credentials(
  apiAuth: APICredentials(
    apiToken: env("CLOUDKIT_API_TOKEN"),
    webAuthToken: env("CLOUDKIT_WEB_AUTH_TOKEN")   // optional
  )
)
```

### Server-to-server (developer-attributed)

Provide a CloudKit key ID and an ECDSA P-256 private key. ``PrivateKeyMaterial`` accepts either raw key bytes, PEM data, or a path to a PEM file.

```swift
let credentials = try Credentials(
  serverToServer: ServerToServerCredentials(
    keyID: env("CLOUDKIT_KEY_ID"),
    privateKey: .file(path: env("CLOUDKIT_PRIVATE_KEY_PATH"))
  )
)
```

``PrivateKeyMaterial`` is `.raw(String)` for an inline PEM (literal `\n` escapes are normalized) or `.file(path:)` for a PEM read off disk when the credentials are first consumed.

### Both — one service, both attribution paths

Populate both fields when a single backend has work that splits across attribution boundaries:

```swift
let credentials = try Credentials(
  serverToServer: ServerToServerCredentials(
    keyID: env("CLOUDKIT_KEY_ID"),
    privateKey: .file(path: env("CLOUDKIT_PRIVATE_KEY_PATH"))
  ),
  apiAuth: APICredentials(
    apiToken: env("CLOUDKIT_API_TOKEN"),
    webAuthToken: env("CLOUDKIT_WEB_AUTH_TOKEN")
  )
)
```

## Build the service

```swift
let service = CloudKitService(
  containerIdentifier: "iCloud.com.example.MyApp",
  credentials: credentials,
  environment: .production
)
```

The service does **not** carry a database. The database is chosen per call, and the appropriate token manager is resolved from ``Credentials`` each time. Misconfiguration (no credential set covers a given call's database/user-context combination) surfaces at the call site as ``CloudKitError/missingCredentials(database:availability:reason:)``, not at construction.

For a custom transport (mock, instrumented, WASI), use the generic initializer:

```swift
let service = CloudKitService(
  containerIdentifier: container,
  credentials: credentials,
  environment: .production,
  transport: customTransport
)
```

## Pick a database per call

``Database`` is an enum with three cases:

```swift
public enum Database: Sendable, Hashable {
  case `public`(PublicAuthPreference)
  case `private`
  case shared
}
```

`.private` and `.shared` carry no payload — they always sign with web-auth (the only scheme CloudKit accepts on those scopes).

```swift
let notes = try await service.queryRecords(
  recordType: "Note",
  database: .private
)
```

`.public` requires a ``PublicAuthPreference`` so each call says explicitly how it wants to be attributed:

```swift
// Server-attributed: catalog seed write that should look like "the app did this".
try await service.createRecord(
  recordType: "FeaturedPost",
  fields: featuredPostFields,
  database: .public(.requires(.serverToServer))
)

// User-attributed: a public post created by the signed-in user.
try await service.createRecord(
  recordType: "Post",
  fields: postFields,
  database: .public(.requires(.webAuth))
)
```

## Two preference modes: prefers vs requires

Both factories take a ``PublicAuthPreference/Mode`` (``PublicAuthPreference/Mode/serverToServer`` or ``PublicAuthPreference/Mode/webAuth``):

| Factory | Behavior when the chosen scheme is missing |
| --- | --- |
| ``PublicAuthPreference/prefers(_:)`` | Fall back to the other configured credential set when possible. |
| ``PublicAuthPreference/requires(_:)`` | Throw ``CloudKitError/missingCredentials(database:availability:reason:)`` with `availability == .preferenceRequired`. |

Use `.prefers(_:)` when either attribution is acceptable and you'd rather degrade gracefully than fail (development tooling, mixed environments). Use `.requires(_:)` when attribution is part of the contract — a write that *must* be attributed to a specific user, or a server task that *must not* leak user identity — and a misconfigured deployment should fail loudly.

There is no default on the `database:` parameter. Every call picks explicitly.

## User-identity routes

A handful of routes (`/users/caller`, `/users/discover`, `/users/lookup/email`, `/users/lookup/id`) only work against the public database with web-auth credentials — CloudKit rejects server-to-server signing on these endpoints. MistKit's user-identity methods (``CloudKitService/fetchCaller()``, ``CloudKitService/lookupUsersByEmail(_:)``, ``CloudKitService/lookupUsersByRecordName(_:)``) pass `.public(.requires(.webAuth))` internally — they will throw ``CloudKitError/missingCredentials(database:availability:reason:)`` if your ``Credentials`` lack ``APICredentials/webAuthToken``.

## Where the signing happens

The middleware chain is one step: ``Authenticator`` does the work, the middleware just hands it the request.

```
service.createRecord(database: .public(.requires(.webAuth)))
                │
                ▼
        TokenManager.currentAuthenticator()           ← picked from Credentials
                │
                ▼
        AuthenticationMiddleware.intercept(request)
                │                                      ← appends ckAPIToken=,
        Authenticator.authenticate(request:body:)      ← ckWebAuthToken=, or
                │                                      ← X-Apple-CloudKit-* headers
                ▼
        next(request, body, baseURL)
```

For server-to-server, ``ServerToServerAuthenticator`` consumes the request body to compute the signed payload, then reassigns a buffered copy so downstream middleware and the transport see the same bytes.

## When to use a custom TokenManager

The standard path — ``Credentials`` plus per-call ``Database`` — covers almost every use. Reach for ``CloudKitService/init(containerIdentifier:tokenManager:environment:transport:)`` only when:

- You need to **dynamically refresh** credentials between requests (e.g. rotate web-auth tokens from a remote secret store).
- You're **testing** and want every dispatched operation to use a stub manager that returns canned authenticators.
- You're building a **specialized auth flow** that doesn't fit the developer-key / user-token / API-token taxonomy.

A custom manager is used for *every* dispatched operation regardless of database — you opt out of the per-call resolution entirely. See ``TokenManager`` and the concrete managers under "Advanced — custom token managers and storage" on the module landing page.

## Reference material

The longer prose guides live in the repo (outside this DocC bundle):

- `docs/cloudkit-guide/articles/authenticating-cloudkit-backend-services.md` — full backend setup walkthrough including obtaining tokens, the browser-redirect web-auth flow, `CKFetchWebAuthTokenOperation` for iOS handoff, CloudKit Dashboard configuration, and CI/CD secret rotation.
- `docs/internals/authentication-middleware.md` — Mermaid diagrams of the middleware chain and per-scheme signing paths.

## Topics

### Credentials

- ``Credentials``
- ``APICredentials``
- ``ServerToServerCredentials``
- ``PrivateKeyMaterial``
- ``CredentialsValidationError``

### Database scoping

- ``Database``
- ``PublicAuthPreference``
- ``PublicAuthPreference/Mode``

### Request signing

- ``Authenticator``
- ``APITokenAuthenticator``
- ``WebAuthTokenAuthenticator``
- ``ServerToServerAuthenticator``

### Errors

- ``CloudKitError``
- ``CredentialAvailability``
- ``TokenManagerError``
- ``InvalidCredentialReason``
