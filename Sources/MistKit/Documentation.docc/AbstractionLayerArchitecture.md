# Abstraction Layer Architecture

The hand-written Swift surface on top of MistKit's generated OpenAPI client — how the layers split responsibility, why the boundaries land where they do, and how Swift 6 concurrency shapes each one.

## Overview

The generated OpenAPI code is a faithful, namespaced translation of `openapi.yaml`. It is correct but verbose: every operation is a nested `Operations.<name>.Input` / `Output` enum tree, every response is a status-code enum, every error case requires explicit unwrapping. MistKit's abstraction layer turns that into the surface most callers actually want: typed records, async iteration, structured errors, and three authentication schemes that don't leak through to call sites.

This article describes how that layer is organised. For the per-call authentication model in particular, see <doc:AuthenticationAndDatabases>.

## Layered architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Caller (server, CLI, library consumer)                         │
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│  Wrapper layer                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐   │
│  │ CloudKitService  │  │ Credentials +    │  │ Authenticator│   │
│  │ + per-call DB    │  │ TokenManager     │  │ family       │   │
│  └──────────────────┘  └──────────────────┘  └──────────────┘   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐   │
│  │ FieldValue /     │  │ AuthenticationMW │  │ FilterBuilder│   │
│  │ RecordInfo etc.  │  │ + LoggingMW      │  │ + QueryFilter│   │
│  └──────────────────┘  └──────────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│  Generated OpenAPI client (Client.swift, Types.swift)           │
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│  OpenAPIRuntime  (ClientTransport, ClientMiddleware, HTTPBody)  │
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│  URLSessionTransport  /  custom ClientTransport (WASI, tests)   │
└─────────────────────────────────────────────────────────────────┘
```

Every box above either lives in `Sources/MistKit/` (hand-written) or is generated to `Sources/MistKitOpenAPI/` (committed). The generated layer never imports anything from the wrapper; the wrapper depends on the generated layer one-way.

## CloudKitService: the single entry point

``CloudKitService`` is a small `Sendable` struct that holds three things: a container identifier, an ``Environment``, and either a ``Credentials`` value (the normal case) or a fixed `TokenManager` (tests and bespoke flows). It does **not** carry a database — every operation that supports multiple scopes takes a `database:` argument at the call site, and the right token manager is resolved per call.

```swift
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct CloudKitService: Sendable {
  public let containerIdentifier: String
  public let environment: Environment

  internal let credentials: Credentials?
  internal let fixedTokenManager: (any TokenManager)?
  internal let transport: any ClientTransport
}
```

The four public initialisers live in `Sources/MistKit/CloudKitService/CloudKitService+Initialization.swift`:

| Initializer | Use case |
| --- | --- |
| `init(containerIdentifier:credentials:environment:transport:)` | Standard. Per-call database, per-call token manager resolution. |
| `init(containerIdentifier:tokenManager:environment:transport:)` | Bespoke. One manager for every dispatched call regardless of database. |
| `init(containerIdentifier:credentials:environment:)` | URLSession convenience (non-WASI). |
| `init(containerIdentifier:tokenManager:environment:)` | URLSession convenience (non-WASI). |

Operations are split across focused extension files (`CloudKitService+Operations.swift`, `+WriteOperations.swift`, `+ZoneOperations.swift`, `+UserOperations.swift`, `+AssetOperations.swift`, etc.). Each extension method takes a `database:` where applicable, resolves a `TokenManager`, builds a fresh generated `Client` with that manager wired into `AuthenticationMiddleware`, and dispatches the request.

## Authenticator: credential + signing rules

``Authenticator`` is the protocol that owns both the credential payload and the rules for attaching it to a request:

```swift
public protocol Authenticator: Sendable {
  static var storageKey: String { get }
  var defaultStorageIdentifier: String { get }
  init(decoding data: Data) throws
  func authenticate(request: inout HTTPRequest, body: inout HTTPBody?) async throws
  func encoded() throws -> Data
}
```

Three concrete implementations cover the CloudKit schemes:

- ``APITokenAuthenticator`` — appends `ckAPIToken=...` as a query item.
- ``WebAuthTokenAuthenticator`` — appends `ckAPIToken=...` and `ckWebAuthToken=...`.
- ``ServerToServerAuthenticator`` — buffers the body, computes an ECDSA P-256 signature, and writes the `X-Apple-CloudKit-Request-*` headers.

`authenticate(request:body:)` takes both `inout`. Server-to-server is the reason: it must read the request body to compute the signed payload, so it consumes the streaming body, hashes it, and re-assigns a buffered copy that downstream middleware and the transport can read again. The other two authenticators leave the body untouched.

`Authenticator` deliberately doesn't inherit `Equatable` or `Codable` — either would impose a `Self` requirement and prevent its use as `any Authenticator`, which the middleware and storage code depend on. Hand-rolled `init(decoding:)` and `encoded()` keep the on-disk format next to each type's invariants.

## TokenManager: vending the current authenticator

``TokenManager`` is what `AuthenticationMiddleware` actually asks for an authenticator each request:

```swift
public protocol TokenManager: Sendable {
  var hasCredentials: Bool { get async }
  func validateCredentials() async throws(TokenManagerError) -> Bool
  func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)?
}
```

When you pass a ``Credentials`` to ``CloudKitService``, the per-call dispatcher consults ``PublicAuthPreference`` and the target ``Database`` to decide which manager to instantiate for that call. When you inject a fixed manager via the bespoke initializer, the same manager handles every call.

A handful of concrete managers ship in the box (``APITokenManager``, ``WebAuthTokenManager``, ``ServerToServerAuthManager``, ``AdaptiveTokenManager``). Most code never names them — the ``Credentials``-driven resolution picks the right one. Implement the protocol yourself only when you need behavior the standard resolution doesn't cover (dynamic remote refresh, custom rotation).

## AuthenticationMiddleware: one place, one job

The middleware is intentionally small. It doesn't know what scheme is in use; it just asks the manager for an authenticator and lets it apply itself:

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
    return try await next(modifiedRequest, modifiedBody, baseURL)
  }
}
```

Adding a new authentication scheme means adding a new ``Authenticator`` and (if needed) a new manager. The middleware does not change. This is the structural payoff from making the credential type carry its own signing rules.

```
Request
   │
   ▼
AuthenticationMiddleware.intercept(request, body)
   ├── tokenManager.currentAuthenticator()         (async)
   ├── authenticator.authenticate(&request, &body) (sign / append query items)
   └── next(modifiedRequest, modifiedBody, baseURL)
                                                          │
                                                          ▼
                                              LoggingMiddleware  (debug builds)
                                                          │
                                                          ▼
                                              ClientTransport (URLSession)
                                                          │
                                                          ▼
                                                  api.apple-cloudkit.com
```

## Sendable everywhere

Every type that crosses a task boundary is `Sendable`. The wrapper enforces this top-down:

- ``CloudKitService`` is a `Sendable` struct with `let` fields.
- ``Credentials`` and the credential structs are `Sendable` value types.
- ``Authenticator`` declares a `Sendable` constraint on the protocol itself.
- ``TokenManager`` likewise.

Token-manager *implementations* that need mutable state (``AdaptiveTokenManager``, anything that caches a refreshed token) are `actor`s — the only `Sendable` shape that owns mutable state safely under Swift 6 strict concurrency. The middleware never reaches into those actors directly; it only calls `currentAuthenticator()`, which is `async`.

## Typed throws

Authentication code uses typed throws:

```swift
public func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)?
```

Callers know they're catching ``TokenManagerError`` specifically and can switch on ``InvalidCredentialReason`` / ``AuthenticationFailedReason`` / ``InternalErrorReason`` / ``NetworkErrorReason`` without `as?` casts. CloudKit operation errors map to ``CloudKitError`` — see <doc:GeneratedCodeAnalysis> for how generated response enums are folded into that type.

## FieldValue: request and response are different shapes

The CloudKit API is asymmetric: a field value in a request body omits the `type` field (CloudKit infers it from the value), while a field value in a response sometimes includes `type` explicitly. Reflecting this in the OpenAPI schema gives two generated types:

- `Components.Schemas.FieldValueRequest` — used inside `RecordRequest`.
- `Components.Schemas.FieldValueResponse` — used inside `RecordResponse`.

The wrapper exposes a single domain type, ``FieldValue``, and converts both directions:

- `Sources/MistKit/OpenAPI/Components/Components.Schemas.FieldValueRequest.swift` — domain ``FieldValue`` → `FieldValueRequest`.
- `Sources/MistKit/Models/FieldValues/FieldValue+Components.swift` — `FieldValueResponse` → domain ``FieldValue``.

Splitting the generated types means the compiler refuses to put a response value in a request slot. The single domain enum gives callers an ergonomic API.

## Query construction: QueryFilter and QuerySort

``QueryFilter`` and ``QuerySort`` are the public, typed surface for building queries. Each is a `struct` with static factory methods that mirror the CloudKit comparators:

```swift
let result = try await service.queryRecords(
  recordType: "Note",
  filters: [
    .greaterThan("modifiedAt", .date(since)),
    .listContains("tags", .string("important")),
  ],
  sortBy: [.descending("modifiedAt")],
  database: .private
)
```

The internal `FilterBuilder` (`Helpers/FilterBuilder.swift` + extensions) emits the underlying `Components.Schemas.Filter` values. List comparators wrap values in `ListValuePayload` so the JSON shape matches what CloudKit expects.

## Pagination

Query responses carry a continuation marker. ``QueryResult`` exposes it:

```swift
public struct QueryResult: Codable, Sendable {
  public let records: [RecordInfo]
  public let continuationMarker: String?
}
```

Two iteration helpers cover the common cases:

- ``CloudKitService/queryRecords(_:limit:desiredKeys:continuationMarker:zoneID:zoneWide:numbersAsStrings:database:)`` — single page.
- `queryAllRecords(...)` — auto-pagination with an enforced maximum, surfacing ``CloudKitError/paginationLimitExceeded(maxPages:records:)`` with the already-fetched records when the cap is reached.

Sync endpoints follow the same shape: ``RecordChangesResult`` and ``ZoneChangesResult`` carry `syncToken` and `moreComing`. `fetchAllRecordChanges(recordType:syncToken:)` walks the cursor automatically.

## Asset upload: separate URLSession by design

Asset upload is a two-step dance: ask CloudKit for a CDN URL, then PUT the bytes to the CDN. The two steps target **different hosts** (`api.apple-cloudkit.com` and `cvws.icloud-content.com`).

URLSession (and any HTTP/2 client) will happily reuse a connection between hosts when it can, and CloudKit's CDN responds with `421 Misdirected Request` if the wrong host is reached over a reused HTTP/2 connection. To avoid that, asset upload uses `URLSession.shared.upload(_:to:)` directly via a dedicated ``AssetUploader`` closure — **not** the injected `ClientTransport`. The two connection pools stay separate.

The closure shape (`(Data, URL) async throws -> (statusCode: Int?, data: Data)`) is a dependency-injection seam: tests pass in a stub uploader without touching the network. Custom uploaders in production code must preserve the connection-pool separation, or the same 421 errors will return.

## Logging

`MistKitLogger` is the central swift-log wrapper with three subsystems (`api`, `auth`, `network`). Helpers (`logError`, `logWarning`, `logInfo`, `logDebug`) call through `SecureLogging.safeLogMessage` by default to mask tokens, key IDs, and other secrets. Set `MISTKIT_DISABLE_LOG_REDACTION=1` to suppress redaction while debugging.

`LoggingMiddleware` runs after `AuthenticationMiddleware` and emits structured request/response logs in `DEBUG` builds — the auth values it sees are already in their wire form, but the secure helpers redact them again before they reach the log line.

## What the wrapper does *not* do

A few intentional non-features that show up in many wrapper libraries but not this one:

- **No `await` on every property.** ``CloudKitService`` is a `Sendable` struct, not an actor. Async surface is restricted to actual I/O.
- **No global state.** No shared client, no singletons, no ambient credentials. Every test gets its own service.
- **No completion-handler overloads.** Single async surface everywhere.
- **No record model registry.** ``RecordInfo`` is a typed dictionary on purpose — record schemas live in CloudKit, not in Swift type definitions. Build your own domain types on top.

## See Also

- <doc:AuthenticationAndDatabases>
- <doc:OpenAPICodeGeneration>
- <doc:GeneratedCodeAnalysis>
- <doc:GeneratedCodeWorkflow>
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [swift-openapi-runtime](https://github.com/apple/swift-openapi-runtime)
