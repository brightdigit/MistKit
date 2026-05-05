# Authentication Middleware

MistKit's authentication system uses an HTTP middleware pattern to transparently sign every request with the correct credentials, supporting three authentication methods and runtime upgrades between them.

## TokenManager Protocol

All authentication flows implement a common protocol:

```swift
public protocol TokenManager: Sendable {
  var hasCredentials: Bool { get async }
  func validateCredentials() async throws(TokenManagerError) -> Bool
  func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials?
}
```

`TokenCredentials` carries an `AuthenticationMethod` enum:

```swift
public enum AuthenticationMethod: Sendable {
  case apiToken(String)
  case webAuthToken(apiToken: String, webToken: String)
  case serverToServer(keyID: String, privateKey: Data)
}
```

## The Middleware Intercept

`AuthenticationMiddleware` conforms to the OpenAPI middleware protocol and intercepts every outgoing request:

```swift
func intercept(_ request: HTTPRequest, body: HTTPBody?,
               next: (HTTPRequest, HTTPBody?) async throws -> (HTTPResponse, HTTPBody?))
    async throws -> (HTTPResponse, HTTPBody?)
{
    let credentials = try await tokenManager.getCurrentCredentials()

    switch credentials.method {
    case .apiToken(let token):
        // Append ?ckAPIToken=<token> to URL
    case .webAuthToken(let apiToken, let webToken):
        // Append ?ckAPIToken=<token>&ckWebAuthToken=<encoded-token>
    case .serverToServer(let keyID, let privateKey):
        // Add ECDSA signature headers
    }

    return try await next(modifiedRequest, body)
}
```

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

`AdaptiveTokenManager` is an **actor** that enables runtime transitions between auth methods:

```swift
public actor AdaptiveTokenManager: TokenManager {
    private var apiToken: String
    private var webAuthToken: String?
    private var storage: TokenStorage?

    public func upgradeToWebAuthentication(webAuthToken: String)
        async throws(TokenManagerError) -> TokenCredentials
    {
        // Validate
        guard !webAuthToken.isEmpty else {
            throw TokenManagerError.invalidCredentials(.webAuthTokenEmpty)
        }
        guard webAuthToken.count >= 10 else {
            throw TokenManagerError.invalidCredentials(.webAuthTokenTooShort)
        }

        // Store (actor isolation ensures thread safety)
        self.webAuthToken = webAuthToken

        // Optionally persist
        if let storage = storage {
            try await storage.store(credentials, identifier: apiToken)
        }

        return credentials  // Now returns .webAuthToken method
    }
}
```

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
│                   AuthenticationMiddleware                    │
│                                                              │
│  Request ──→ tokenManager.getCurrentCredentials()            │
│                         │                                    │
│              ┌──────────┼──────────┐                         │
│              ▼          ▼          ▼                         │
│         apiToken   webAuthToken  serverToServer              │
│              │          │          │                         │
│         Add query   Add query   Sign with                   │
│         param       params      ECDSA P-256                 │
│              │          │          │                         │
│              └──────────┼──────────┘                         │
│                         ▼                                    │
│                   next(request, body)                        │
└─────────────────────────────────────────────────────────────┘

        AdaptiveTokenManager (actor)
        ┌─────────────────────────────┐
        │  apiToken ──────────────────│──→ Public DB only
        │       │                     │
        │  upgradeToWebAuth()         │
        │       ▼                     │
        │  apiToken + webAuthToken ───│──→ Private/Shared DB
        └─────────────────────────────┘
```
