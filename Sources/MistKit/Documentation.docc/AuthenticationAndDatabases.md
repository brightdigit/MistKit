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

The public initializers wire up `URLSessionTransport`; a transport-accepting initializer exists but is internal today (see <doc:ConfiguringMistKit>).

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

The standard path — ``Credentials`` plus per-call ``Database`` — covers almost every use. Reach for ``CloudKitService/init(containerIdentifier:tokenManager:environment:)`` only when:

- You need to **dynamically refresh** credentials between requests (e.g. rotate web-auth tokens from a remote secret store).
- You're **testing** and want every dispatched operation to use a stub manager that returns canned authenticators.
- You're building a **specialized auth flow** that doesn't fit the developer-key / user-token / API-token taxonomy.

A custom manager is used for *every* dispatched operation regardless of database — you opt out of the per-call resolution entirely. See <doc:RequestSigning> for the ``TokenManager`` protocol and the concrete managers.

## Obtaining credentials from the CloudKit Console

Everything below starts in the [CloudKit Console](https://icloud.developer.apple.com/dashboard/): pick your container, then open **Tokens & Keys**.

### API token

Under **API Tokens**, press `+`, name the token, and pick a **Sign-in Callback**. Optionally tick **User Info** to have the user's name returned alongside the web auth token. Save, and copy the token string into `CLOUDKIT_API_TOKEN`.

The sign-in callback decides how a web auth token comes back to you later:

- **URL Redirect** — Apple's sign-in page redirects the browser to a URL you supply with the token appended as the `ckSession` query parameter. Pick this when your backend handles the callback directly.
- **Post Message** — Apple's sign-in window posts a JavaScript `message` event to your page with the token in `e.data.ckWebAuthToken`. This is what CloudKit JS uses by default.

An API token alone cannot reach the private or shared database. Its main job is to identify the container for the flows below.

### Web auth token via browser redirect

1. Your service makes a request with only `ckAPIToken` set.
2. CloudKit replies `401` with `serverErrorCode` `AUTHENTICATION_REQUIRED` and a `redirectURL` pointing at Apple's sign-in page.
3. Your service redirects the browser there; the user signs in with their Apple ID.
4. Apple redirects back to your registered callback with `ckSession=…` (the web auth token).
5. Your service stores that token next to the API token and uses both for every subsequent request — MistKit sends it as the `ckWebAuthToken` query item.

MistKit surfaces step 2 as ``CloudKitError/authenticationRequired(reason:)`` on single-record conveniences, and as a per-item ``OperationFailure`` (whose ``OperationFailure/redirectURL`` carries the sign-in URL) on batch results:

```swift
do {
  _ = try await service.queryRecords(Query(recordType: "Note"), database: .private)
} catch CloudKitError.authenticationRequired(let reason) {
  // Send the user through the sign-in flow, then retry with the new token.
  logger.info("Sign-in required: \(reason ?? "")")
}
```

The token is valid for 30 minutes by default, or two weeks if the user ticks *Keep me signed in*, and CloudKit returns a rotated token in the `X-Apple-CloudKit-Web-Auth-Token` header of every response. MistKit adopts the rotated token automatically through ``TokenManager/didReceiveRotatedWebAuthToken(_:)`` — see <doc:RequestSigning>.

### Web auth token from an iOS app

If your backend acts on behalf of a user who is already signed in to your iOS app, skip the browser. `CKFetchWebAuthTokenOperation` exchanges the device's iCloud session for a web auth token your server can use:

```swift
extension CKDatabase {
  func fetchWebAuthToken(apiToken: String) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
      let operation = CKFetchWebAuthTokenOperation(apiToken: apiToken)
      operation.qualityOfService = .userInitiated
      operation.fetchWebAuthTokenResultBlock = { @Sendable result in
        continuation.resume(with: result)
      }
      add(operation)
    }
  }
}
```

Run it against the **private** database — on the public database it fails or returns an unattributed token. Post the result to your backend over your own authenticated API; from there the MistKit side is identical to the browser flow.

### Server-to-server key

Under **Server-to-Server Keys**, press `+`. The console shows the exact commands; the key pair is yours, and only the public half is uploaded:

```bash
# Step 1: generate a P-256 private key
openssl ecparam -name prime256v1 -genkey -noout -out eckey.pem

# Step 2: output the public key and paste it into the console
openssl ec -in eckey.pem -pubout
```

Name the key, paste the public key, save, and copy the **Key ID** into `CLOUDKIT_KEY_ID`. Keep `eckey.pem` on the server — never commit it — and hand it to MistKit as ``PrivateKeyMaterial/file(path:)`` or, when a secret store injects the PEM contents, ``PrivateKeyMaterial/raw(_:)``.

Every request is then signed with the key: MistKit builds the payload `<iso8601Date>:<base64 SHA-256 of body>:<subpath>`, signs it with ECDSA P-256, and sends the `X-Apple-CloudKit-Request-KeyID`, `X-Apple-CloudKit-Request-ISO8601Date`, and `X-Apple-CloudKit-Request-SignatureV1` headers. There is no `Authorization` header. <doc:RequestSigning> walks through the implementation.

### Rotating a server-to-server key

Keys do not expire on their own, but the console allows several active keys per container, which makes a zero-downtime rotation possible:

1. Generate a new key pair and add its public key as a new entry.
2. Roll the new Key ID and PEM into your secret store.
3. Restart the service so it picks up the new credentials.
4. Once the new key is confirmed in use, delete the old key from the console.

### Environment variables

The conventional variable names used by MistDemo, BushelCloud, and CelestraCloud:

| Variable | Method |
| --- | --- |
| `CLOUDKIT_CONTAINER_ID`, `CLOUDKIT_ENVIRONMENT` | All |
| `CLOUDKIT_API_TOKEN` | API token / web auth |
| `CLOUDKIT_WEB_AUTH_TOKEN` | Web auth |
| `CLOUDKIT_KEY_ID`, `CLOUDKIT_PRIVATE_KEY` or `CLOUDKIT_PRIVATE_KEY_PATH` | Server-to-server |

Where those values come from per platform — CI secrets, Kubernetes, `systemd`, managed hosts — is covered in <doc:DeployingMistKit>.

## Further reading

- <doc:RequestSigning> — the middleware, the authenticators, and the signing payload in detail.
- <doc:CloudKitAsYourBackend> — the talk that motivates the three methods, with console screenshots.
- <doc:WhatCloudKitGotWrong> — why the auth matrix has holes and what each signing mistake looks like on the wire.

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
