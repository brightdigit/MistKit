# ``MistKit``

A Swift package for server-side and command-line access to CloudKit Web Services.

![MistKit Logo](logo)

## Overview

MistKit wraps Apple's [CloudKit Web Services REST API](https://developer.apple.com/documentation/cloudkitwebservices) with a modern Swift surface so server-side code, CLIs, and platforms without the native CloudKit framework (Linux, WASI, Windows) can read and write the same containers as your Apple apps.

The library is built on `swift-openapi-generator` against Apple's published OpenAPI specification, with a hand-written abstraction layer on top that exposes typed records, async iteration, structured errors, and three authentication schemes.

## Quick start

Construct a ``CloudKitService`` with a ``Credentials`` value and pick a ``Database`` at each call site:

```swift
import MistKit

let credentials = try Credentials(
  apiAuth: APICredentials(
    apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!,
    webAuthToken: ProcessInfo.processInfo.environment["CLOUDKIT_WEB_AUTH_TOKEN"]
  )
)

let service = CloudKitService(
  containerIdentifier: "iCloud.com.example.MyApp",
  credentials: credentials,
  environment: .production
)

let result = try await service.queryRecords(
  recordType: "Note",
  database: .private
)
```

`.private` and `.shared` always sign with the web-auth token. `.public` carries a ``PublicAuthPreference`` — either ``PublicAuthPreference/prefers(_:)`` or ``PublicAuthPreference/requires(_:)`` — so each public-database call decides whether it is attributed to the developer key (server-to-server) or to the iCloud user (web-auth).

For the full set-up walkthrough — obtaining tokens, generating an ECDSA P-256 key, and running the service on a backend — see <doc:AuthenticationAndDatabases>.

## Architecture at a glance

```
Your code
    │
    ▼
CloudKitService            ←  per-call Database; resolves a TokenManager
    │                          from Credentials
    ▼
AuthenticationMiddleware   ←  asks the current Authenticator to sign/attach
    │
    ▼
Generated OpenAPI Client   ←  produced by swift-openapi-generator
    │
    ▼
ClientTransport            ←  URLSessionTransport by default
    │
    ▼
api.apple-cloudkit.com
```

The wrapper layer is described in <doc:AbstractionLayerArchitecture>. The code-generation pipeline that produces the OpenAPI client is covered in <doc:OpenAPICodeGeneration> and <doc:GeneratedCodeAnalysis>.

## Platform support

| Capability | Minimum |
| --- | --- |
| Core API (most operations) | macOS 11, iOS 14, tvOS 14, watchOS 7, visionOS 1, Linux, WASI, Windows |
| Server-to-server signing (requires Crypto) | macOS 11, iOS 14, tvOS 14, watchOS 7, Linux (via swift-crypto) |

URL-loading conveniences and asset upload use `URLSession`; on WASI builds you supply a `ClientTransport` explicitly via the generic initializer.

## Topics

### Essentials

- <doc:AuthenticationAndDatabases>
- ``CloudKitService``
- ``Credentials``
- ``Database``
- ``Environment``

### Authentication primitives

- ``APICredentials``
- ``ServerToServerCredentials``
- ``PrivateKeyMaterial``
- ``PublicAuthPreference``
- ``RequestSignature``

### Custom authenticators

- ``Authenticator``
- ``APITokenAuthenticator``
- ``WebAuthTokenAuthenticator``
- ``ServerToServerAuthenticator``

### Advanced — custom token managers and storage

The `TokenManager` protocol drives `AuthenticationMiddleware` for every dispatched request. Most code never touches it: pass a ``Credentials`` to ``CloudKitService`` and per-call resolution picks the right manager. Provide your own implementation only when ``Credentials``-driven selection isn't appropriate — for example, dynamic refresh against a remote secret store. Inject it via the bespoke `init(containerIdentifier:tokenManager:environment:transport:)` overload.

- ``TokenManager``
- ``APITokenManager``
- ``WebAuthTokenManager``
- ``AdaptiveTokenManager``
- ``ServerToServerAuthManager``
- ``AuthenticationMode``
- ``TokenStorage``
- ``InMemoryTokenStorage``
- ``TokenStorageError``

### Operation results

- ``QueryResult``
- ``RecordInfo``
- ``RecordChangesResult``
- ``ZoneChangesResult``
- ``ZoneInfo``
- ``ZoneID``
- ``ZoneOperation``
- ``UserInfo``
- ``UserIdentity``
- ``UserIdentityLookupInfo``
- ``NameComponents``
- ``RecordTimestamp``
- ``OperationClassification``
- ``BatchSyncResult``

### Field values

- ``FieldValue``
- ``QueryFilter``
- ``QuerySort``

### Asset upload

- ``AssetUploadResponse``
- ``AssetUploadReceipt``
- ``AssetUploadToken``

### Errors

- ``CloudKitError``
- ``CredentialAvailability``
- ``CredentialsValidationError``
- ``TokenManagerError``
- ``InvalidCredentialReason``
- ``AuthenticationFailedReason``
- ``NetworkErrorReason``
- ``InternalErrorReason``

### Internals

- <doc:AbstractionLayerArchitecture>
- <doc:OpenAPICodeGeneration>
- <doc:GeneratedCodeAnalysis>
- <doc:GeneratedCodeWorkflow>

## See Also

- [CloudKit Web Services documentation](https://developer.apple.com/documentation/cloudkitwebservices)
- [Apple Developer Console](https://developer.apple.com)
- [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)
