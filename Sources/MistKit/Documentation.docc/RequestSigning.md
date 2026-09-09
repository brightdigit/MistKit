# Request Signing

How every outgoing request acquires its credentials — the token manager, the authenticator, the middleware between them, and the ECDSA signature for server-to-server calls.

## Overview

MistKit signs requests with an HTTP middleware rather than with the generator's built-in security schemes. The middleware knows nothing about CloudKit's three authentication methods; it asks a ``TokenManager`` for the current ``Authenticator`` and lets that value mutate the request. Adding a scheme means adding an authenticator, not touching the middleware.

Which scheme is legal for which database, and how a call site picks one, is covered in <doc:AuthenticationAndDatabases>. This article is about the mechanics underneath.

## TokenManager

A ``TokenManager`` owns the credential lifecycle — loading, validating, rotating, persisting — and vends an ``Authenticator`` to whoever needs to apply those credentials to a request:

```swift
public protocol TokenManager: Sendable {
  var hasCredentials: Bool { get async }
  func validateCredentials() async throws(TokenManagerError) -> Bool
  func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)?
  func didReceiveRotatedWebAuthToken(_ token: String) async throws(TokenManagerError)
}
```

Four managers ship in the box: ``APITokenManager``, ``WebAuthTokenManager``, ``ServerToServerAuthManager``, and the runtime-upgradable ``AdaptiveTokenManager``. When you construct ``CloudKitService`` with a ``Credentials`` value you never name them — the per-call resolution in `Credentials+TokenManager.swift` picks one from the target ``Database`` and ``PublicAuthPreference``.

`didReceiveRotatedWebAuthToken(_:)` has a no-op default so managers that never hold a web auth token compile unchanged.

## Authenticator

Each concrete ``Authenticator`` owns both the credential payload and the rule for attaching it to a request:

```swift
public protocol Authenticator: Sendable {
  static var storageKey: String { get }
  var defaultStorageIdentifier: String { get }
  init(decoding data: Data) throws
  func authenticate(request: inout HTTPRequest, body: inout HTTPBody?) async throws
  func encoded() throws -> Data
}
```

The `init(decoding:)` / `encoded()` pair is the on-disk format used by ``TokenStorage``. `Authenticator` deliberately does not inherit `Codable` or `Equatable`: either would impose a `Self` requirement and prevent its use as `any Authenticator`.

### Why `body` is `inout`

`HTTPBody` is a single-pass async sequence. ``ServerToServerAuthenticator`` has to read every byte to compute the SHA-256 over the body, which consumes the iterator. It buffers the bytes and reassigns `body = HTTPBody(bytes)` so downstream middleware and the transport see a fresh, replayable copy of the same data. The `inout` parameter exists for that reassignment; the other two authenticators never touch `body`.

## The middleware

`AuthenticationMiddleware` conforms to OpenAPIRuntime's [`ClientMiddleware`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clientmiddleware) and intercepts every outgoing request:

```swift
internal struct AuthenticationMiddleware: ClientMiddleware {
  internal let tokenManager: any TokenManager

  internal func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    guard let authenticator = try await tokenManager.currentAuthenticator() else {
      throw TokenManagerError.invalidCredentials(.noCredentialsAvailable)
    }

    var modifiedRequest = request
    var modifiedBody = body
    try await authenticator.authenticate(request: &modifiedRequest, body: &modifiedBody)
    let (response, responseBody) = try await next(modifiedRequest, modifiedBody, baseURL)
    if let rotated = response.headerFields[.cloudKitWebAuthToken] {
      do {
        try await tokenManager.didReceiveRotatedWebAuthToken(rotated)
      } catch {
        let message = "Failed to consume rotated web auth token: \(error.localizedDescription)"
        Logger(subsystem: .auth).warning("\(message)")
        RotatedWebAuthTokenFailureReporter.assertionHandler(message)
      }
    }
    return (response, responseBody)
  }
}
```

The complete round trip, for any scheme:

```
App                 queryRecords(...) / createRecord(...)
 │
 ▼
OpenAPI Client ───▶ AuthenticationMiddleware.intercept(request, body, next)
                          │
                          ├─▶ tokenManager.currentAuthenticator()
                          │      ├─ nil  → throws TokenManagerError.invalidCredentials(.noCredentialsAvailable)
                          │      └─ some → authenticator
                          │
                          ├─▶ authenticator.authenticate(&request, &body)   ← scheme-specific (below)
                          │
                          ├─▶ next(request, body, baseURL) ──▶ transport ──▶ api.apple-cloudkit.com
                          │                                                        │
                          │◀──────────────────────── (response, body) ◀────────────┘
                          │
                          └─▶ X-Apple-CloudKit-Web-Auth-Token present?
                                 └─ yes → tokenManager.didReceiveRotatedWebAuthToken(token)
 ▲
 └── decoded result
```

The per-scheme branching — one query item, two query items, or three signed headers — lives entirely inside each `authenticate(request:body:)`.

## API token

``APITokenAuthenticator`` appends one query item and returns. No body access, no async work:

```swift
public func authenticate(
  request: inout HTTPRequest,
  body: inout HTTPBody?
) async throws {
  request.appendQueryItems([URLQueryItem(name: "ckAPIToken", value: token)])
}
```

```text
GET /database/1/iCloud.com.example/development/public/records/query?ckAPIToken=abc123...
```

The token is a 64-character hex string identifying the container; the initializer validates that shape. On its own it grants whatever the public schema's `_world` role allows.

## Web auth token

``WebAuthTokenAuthenticator`` URL-encodes the user token through `CharacterMapEncoder` and appends both items:

```
AuthenticationMiddleware ──▶ WebAuthTokenAuthenticator.authenticate(&request, &body)
                                   │
                                   ├─▶ CharacterMapEncoder.encode(webAuthToken)
                                   │        +  →  %2B
                                   │        /  →  %2F
                                   │        =  →  %3D
                                   │
                                   └─▶ append ?ckAPIToken=<…>&ckWebAuthToken=<encoded>
```

```swift
public func authenticate(
  request: inout HTTPRequest,
  body: inout HTTPBody?
) async throws {
  let encoded = Self.encoder.encode(webAuthToken)
  request.appendQueryItems([
    URLQueryItem(name: "ckAPIToken", value: apiToken),
    URLQueryItem(name: "ckWebAuthToken", value: encoded),
  ])
}
```

CloudKit rejects a token containing raw `+`, `/`, or `=`, and those three characters are exactly what a base64-flavored token contains. The three-entry map is the whole encoder.

This scheme grants access to the private and shared databases for the authenticated user, and is the only one accepted on the `/users/*` routes.

### Rotation

Every CloudKit response carries an `X-Apple-CloudKit-Web-Auth-Token` header with a fresh token, and [Apple documents the previous token as invalid](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html) once the response is received. The middleware forwards the header to the manager; ``WebAuthTokenManager`` validates and stores it, and ``AdaptiveTokenManager`` additionally persists it to its ``TokenStorage``:

```swift
public func didReceiveRotatedWebAuthToken(_ token: String) async throws(TokenManagerError) {
  guard webAuthToken != nil else {
    return
  }

  let authenticator = try WebAuthTokenAuthenticator(
    apiToken: apiToken,
    webAuthToken: token
  )
  self.webAuthToken = token

  if let storage = storage {
    do {
      try await storage.store(authenticator, identifier: apiToken)
    } catch {
      Logger(subsystem: .auth).warning(
        "Failed to store credentials after token rotation: \(error.localizedDescription)"
      )
    }
  }
}
```

A custom ``TokenManager`` that holds a web auth token should override the method too, or it will keep sending the token from its first request.

## Server to server

``ServerToServerAuthenticator`` is used for backend services without a user. It buffers the body, signs, and appends headers:

```
AuthenticationMiddleware ──▶ ServerToServerAuthenticator.authenticate(&request, &body)
                                   │
                                   ├─▶ Data(buffering: &body, upTo: bodyBufferLimit)
                                   │      (consumes the stream, reassigns a replayable HTTPBody)
                                   │
                                   ├─▶ RequestSignature(keyID, privateKey, requestBody, webServiceSubpath)
                                   │      └─ signed header bundle
                                   │
                                   └─▶ request.headerFields.append(contentsOf: signature.headers)
```

```swift
public func authenticate(
  request: inout HTTPRequest,
  body: inout HTTPBody?
) async throws {
  let bodyData = try await Data(buffering: &body, upTo: bodyBufferLimit)

  let signature = try RequestSignature(
    keyID: keyID,
    privateKey: privateKey,
    requestBody: bodyData,
    webServiceSubpath: request.path
  )

  request.headerFields.append(contentsOf: signature.headers)
}
```

`bodyBufferLimit` defaults to ``ServerToServerAuthenticator/defaultBodyBufferLimit`` (1 MiB). A body larger than that fails the request rather than being signed over a truncated copy that would not match what the transport sends.

### RequestSignature

`RequestSignature` is an internal value type holding a signed header bundle:

```swift
internal struct RequestSignature: Sendable {
  internal let keyID: String
  internal let iso8601DateString: String          // exact string that was signed
  internal let signatureDerRepresentation: Data   // DER bytes
  internal var signatureBase64: String { ... }    // wire form, derived on demand
  internal var headers: HTTPFields { ... }        // typed headers, ready to append
}
```

It is a transport-format value, not a domain value, and two storage choices follow from that:

- **The date is stored as a `String`, not a `Date`.** The ISO 8601 string is part of the signed payload. Re-formatting a `Date` on every header access risks a wire string that differs from what was signed (formatter options, fractional seconds), and every such mismatch is an indistinguishable `401`. Storing the string locks the wire form to the signed form.
- **The signature is stored as DER `Data`, not a base64 `String`.** The bytes are the natural form; base64 is computed on demand, and the struct stays free of the `@available` constraints that come with [`P256.Signing.ECDSASignature`](https://github.com/apple/swift-crypto).

### Signing process

The convenience initializer `init(keyID:privateKey:requestBody:webServiceSubpath:date:)` does:

1. **Format the ISO 8601 date.** `Date.ISO8601FormatStyle` on macOS 12 / iOS 15 / tvOS 15 / watchOS 8 and later; a shared [`ISO8601DateFormatter`](https://developer.apple.com/documentation/foundation/iso8601dateformatter) (documented thread-safe for `string(from:)`) on older systems.
2. **Hash the body.** `SHA256.cloudKitBodyHash(of:)` returns `base64(SHA256(body))`, or the **empty string** when the body is `nil` — not the hash of empty data. Both are defensible; only one is what CloudKit accepts.
3. **Build the payload:** `"<iso8601Date>:<bodyHash>:<webServiceSubpath>"`.
4. **Sign with P-256.** `privateKey.signature(for: Data(payload.utf8))` → DER bytes.
5. **Store** the key ID, the exact date string, and the DER bytes.

The core initializer takes the pre-formatted strings directly, which is what deterministic tests use:

```swift
internal init(
  keyID: String,
  privateKey: P256.Signing.PrivateKey,
  bodyHash: String,
  webServiceSubpath: String,
  iso8601DateString: String
) throws {
  let payload = "\(iso8601DateString):\(bodyHash):\(webServiceSubpath)"
  let signature = try privateKey.signature(for: Data(payload.utf8))

  self.init(
    keyID: keyID,
    iso8601DateString: iso8601DateString,
    signatureDerRepresentation: signature.derRepresentation
  )
}
```

### Wire format

```http
X-Apple-CloudKit-Request-KeyID: <keyID>
X-Apple-CloudKit-Request-ISO8601Date: 2026-05-15T14:30:00Z
X-Apple-CloudKit-Request-SignatureV1: <base64-of-DER-signature>
```

There is no `Authorization` header. The [`HTTPField.Name`](https://github.com/apple/swift-http-types) constants for these three headers — and for the `X-Apple-CloudKit-Web-Auth-Token` response header — live in `Sources/MistKit/Authentication/HTTPField.Name+CloudKit.swift`.

## AdaptiveTokenManager

``AdaptiveTokenManager`` is an `actor` that starts with an API token and can be upgraded to web authentication at runtime — the shape a web app needs, where anonymous public reads precede a sign-in:

```swift
public actor AdaptiveTokenManager: TokenManager {
  internal let apiToken: String
  internal var webAuthToken: String?
  internal let storage: (any TokenStorage)?

  public func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    if let webToken = webAuthToken {
      return try WebAuthTokenAuthenticator(apiToken: apiToken, webAuthToken: webToken)
    }
    return try APITokenAuthenticator(token: apiToken)
  }
}
```

``AdaptiveTokenManager/upgradeToWebAuthentication(webAuthToken:)`` validates the token by constructing a ``WebAuthTokenAuthenticator``, stores it, and persists to ``TokenStorage`` when one was supplied — a storage failure is logged, not thrown, so the upgrade itself never fails on persistence. A typical flow:

1. App starts with the API token only and can read the public database.
2. The user completes CloudKit's web sign-in and the app receives a web auth token.
3. The app calls `upgradeToWebAuthentication(webAuthToken:)`.
4. Every subsequent request carries the user's token; the private database is reachable.

The actor makes the state change safe under concurrent requests, and the optional storage lets the credentials survive relaunch.

## Choosing a manager

```
Credentials / config
        │
        ├── API token only ──────────────────▶ APITokenManager ──────────▶ APITokenAuthenticator ──▶ public (reads)
        ├── API + web auth token ────────────▶ WebAuthTokenManager ──────▶ WebAuthTokenAuthenticator ──▶ private / shared / public (user)
        ├── key ID + P-256 key ──────────────▶ ServerToServerAuthManager ▶ ServerToServerAuthenticator ──▶ public (service)
        └── API token now, upgrade later ───▶ AdaptiveTokenManager ─┬──▶ APITokenAuthenticator      (before upgrade)
                                                                    └──▶ WebAuthTokenAuthenticator  (after upgrade)
```

With ``Credentials`` this selection is automatic per call. Pass a manager to ``CloudKitService/init(containerIdentifier:tokenManager:environment:)`` only when you need the same manager for every call regardless of database — stub managers in tests, or a bespoke flow that refreshes credentials from a remote store.

## Topics

### Protocols

- ``TokenManager``
- ``Authenticator``
- ``TokenStorage``

### Authenticators

- ``APITokenAuthenticator``
- ``WebAuthTokenAuthenticator``
- ``ServerToServerAuthenticator``

### Token managers

- ``APITokenManager``
- ``WebAuthTokenManager``
- ``ServerToServerAuthManager``
- ``AdaptiveTokenManager``

### Errors

- ``TokenManagerError``
- ``TokenStorageError``
- ``InvalidCredentialReason``
