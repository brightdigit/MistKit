# Authentication Middleware

MistKit's authentication system uses an HTTP middleware pattern to transparently sign every request with the correct credentials, supporting three authentication methods and runtime upgrades between them.

## TokenManager Protocol

A `TokenManager` is the lifecycle owner of credentials (loading, validating, rotating, persisting). It vends an `Authenticator` to whomever needs to apply those credentials to an outgoing request:

```swift
public protocol TokenManager: Sendable {
  var hasCredentials: Bool { get async }
  func validateCredentials() async throws(TokenManagerError) -> Bool
  func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)?
}
```

Each concrete `Authenticator` (`APITokenAuthenticator`, `WebAuthTokenAuthenticator`, `ServerToServerAuthenticator`) owns both the credential payload and the rule for attaching it to a request:

```swift
public protocol Authenticator: Sendable {
  static var storageKey: String { get }
  var defaultStorageIdentifier: String { get }
  init(decoding data: Data) throws
  func authenticate(request: inout HTTPRequest, body: inout HTTPBody?) async throws
  func encoded() throws -> Data
}
```

Bundling the credential with the application logic keeps new authentication schemes from rippling into the middleware: any `Authenticator` can be plugged in without changes elsewhere.

## The Middleware Intercept

`AuthenticationMiddleware` conforms to the OpenAPI `ClientMiddleware` protocol and intercepts every outgoing request. The middleware itself is trivial — it asks the token manager for the current authenticator and lets the authenticator apply itself:

```swift
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
  return try await next(modifiedRequest, modifiedBody, baseURL)
}
```

The branching the middleware used to do — query parameter for API token, two query parameters for web auth, signed headers for server-to-server — now lives inside each concrete `Authenticator.authenticate(request:body:)` implementation.

## API Token Authentication

The simplest method — appends a query parameter:

```
GET /database/1/iCloud.com.example/development/public/records/query?ckAPIToken=abc123...
```

- Token is a 64-character hex string identifying the container.
- Grants **public database** access only.
- Validated via regex: `^[a-f0-9]{64}$`

## Web Auth Token Authentication

Adds a second query parameter for user-specific operations:

```
GET ...?ckAPIToken=abc123...&ckWebAuthToken=encoded-token
```

The web auth token is URL-encoded via `CharacterMapEncoder`:

```swift
// CharacterMapEncoder replaces URL-unsafe characters:
//   + → %2B
//   / → %2F
//   = → %3D
let encoded = tokenEncoder.encode(webToken)
```

This grants access to **private and shared databases** for the authenticated user.

## Server-to-Server (ECDSA P-256) Authentication

Used for backend services without user interaction. The signing process:

1. **Generate ISO 8601 date**: `2026-05-05T14:30:00Z`
2. **Hash the request body**: `SHA256(body) → base64`
3. **Build the signing payload**:
   ```
   [ISO8601Date]:[BodyHashBase64]:[URLSubpath]
   ```
4. **Sign with P-256 private key**: `ECDSA(payload) → DER → base64`
5. **Attach as HTTP headers**:
   ```http
   X-Apple-CloudKit-Request-KeyID: <keyID>
   X-Apple-CloudKit-Request-ISO8601Date: 2026-05-05T14:30:00Z
   X-Apple-CloudKit-Request-SignatureV1: <base64-signature>
   ```

Implementation in `ServerToServerAuthManager+RequestSigning.swift`:

```swift
func signRequest(url: URL, body: Data?) throws -> RequestSignature {
    let date = ISO8601DateFormatter().string(from: Date())
    let bodyHash = SHA256.hash(data: body ?? Data()).base64EncodedString()
    let subpath = url.path  // e.g. /database/1/iCloud.com.example/...
    let payload = "\(date):\(bodyHash):\(subpath)"

    let signature = try privateKey.signature(for: Data(payload.utf8))
    return RequestSignature(
        keyID: keyID,
        date: date,
        signature: signature.derRepresentation.base64EncodedString()
    )
}
```

## AdaptiveTokenManager & `upgradeToWebAuthentication`

`AdaptiveTokenManager` is an **actor** that enables runtime transitions between auth methods. It vends an `APITokenAuthenticator` while API-only and switches to a `WebAuthTokenAuthenticator` once upgraded:

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

    @discardableResult
    public func upgradeToWebAuthentication(
        webAuthToken: String
    ) async throws(TokenManagerError) -> WebAuthTokenAuthenticator {
        let authenticator = try WebAuthTokenAuthenticator(
            apiToken: apiToken,
            webAuthToken: webAuthToken
        )
        self.webAuthToken = webAuthToken

        if let storage = storage {
            // Don't fail the upgrade if storage fails — just log.
            try? await storage.store(authenticator, identifier: apiToken)
        }

        return authenticator
    }
}
```

`WebAuthTokenAuthenticator`'s initializer is what validates the token (empty / too-short tokens throw `TokenManagerError.invalidCredentials`), so the manager doesn't duplicate that logic. The companion `downgradeToAPIOnly()` and `updateWebAuthToken(_:)` methods live alongside on `AdaptiveTokenManager+Transitions`.

### Why This Matters

A typical flow for a client app:

1. App starts with **API token only** → can query public database
2. User authenticates via CloudKit's web auth flow → receives web auth token
3. App calls `upgradeToWebAuthentication(webAuthToken:)` → all subsequent requests include the user's token
4. App can now access **private database** operations

The actor ensures thread-safe state mutation, and the optional `TokenStorage` protocol allows persisting credentials across app launches.

## Authentication Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   AuthenticationMiddleware                  │
│                                                             │
│  Request ──→ tokenManager.currentAuthenticator()            │
│                         │                                   │
│                         ▼                                   │
│      authenticator.authenticate(request:body:)              │
│         (concrete type decides query param vs.              │
│          query params vs. ECDSA P-256 headers)              │
│                         │                                   │
│                         ▼                                   │
│                  next(request, body)                        │
└─────────────────────────────────────────────────────────────┘

        AdaptiveTokenManager (actor)
        ┌──────────────────────────────────────────────┐
        │  apiToken ──────→ APITokenAuthenticator      │──→ Public DB only
        │       │                                      │
        │  upgradeToWebAuthentication(webAuthToken:)   │
        │       ▼                                      │
        │  apiToken + webAuthToken ──→                 │
        │                  WebAuthTokenAuthenticator   │──→ Private/Shared DB
        └──────────────────────────────────────────────┘
```
