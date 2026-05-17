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

MistKit runs on macOS, iOS, tvOS, watchOS, visionOS, Linux, WASI, and Windows. Server-to-server signing depends on Crypto / swift-crypto, so it is unavailable on Windows and WASI — those targets must use API-token + web-auth credentials. URL-loading conveniences and asset upload use `URLSession`; on WASI builds you supply a `ClientTransport` explicitly via the generic initializer.

> Tip: On native Apple platforms (macOS, iOS, tvOS, watchOS, visionOS) prefer the native [CloudKit framework](https://developer.apple.com/documentation/cloudkit). It integrates with the system account, handles push notifications and long-lived operations, and avoids the per-request signing overhead of the web-services API. MistKit is intended for environments where the native framework isn't available — server-side Swift, CLIs, Linux, and Windows.

> Warning: WASI is not a fully supported target. The web-services API requires HMAC/ECDSA signing and a working HTTP transport, neither of which has a first-class story on WASI today. For CloudKit access from the browser, use Apple's official [CloudKit JS](https://developer.apple.com/documentation/cloudkitjs) library instead.

## Topics

### Getting Started

- <doc:AbstractionLayerArchitecture>
- ``CloudKitService``
- ``Database``
- ``Environment``
- ``CloudKitError``
- ``RecordInfo``
- ``FieldValue``
- ``QueryFilter``
- ``QuerySort``
- ``QueryResult``
- ``RecordOperation``
- ``RecordChangesResult``
- ``RecordTimestamp``
- ``ZoneID``
- ``ZoneInfo``
- ``ZoneOperation``
- ``ZoneChangesResult``
- ``UserInfo``
- ``UserIdentity``
- ``UserIdentityLookupInfo``
- ``NameComponents``
- ``OperationClassification``
- ``BatchSyncResult``
- ``AssetUploadResponse``
- ``AssetUploadReceipt``
- ``AssetUploadToken``
- ``AssetUploader``

### Authentication

- <doc:AuthenticationAndDatabases>
- ``Credentials``
- ``APICredentials``
- ``ServerToServerCredentials``
- ``PublicAuthPreference``
- ``PrivateKeyMaterial``
- ``Authenticator``
- ``APITokenAuthenticator``
- ``WebAuthTokenAuthenticator``
- ``ServerToServerAuthenticator``
- ``TokenManager``
- ``APITokenManager``
- ``WebAuthTokenManager``
- ``AdaptiveTokenManager``
- ``ServerToServerAuthManager``
- ``TokenStorage``
- ``CredentialsValidationError``
- ``CredentialAvailability``
- ``InvalidCredentialReason``
- ``AuthenticationFailedReason``
- ``NetworkErrorReason``
- ``InternalErrorReason``
- ``TokenManagerError``
- ``TokenStorageError``

### Record management

- ``CloudKitRecord``
- ``RecordManaging``
- ``CloudKitRecordCollection``
- ``RecordTypeSet``
- ``RecordTypeIterating``

### OpenAPI code generation

- <doc:OpenAPICodeGeneration>
- <doc:GeneratedCodeWorkflow>
- <doc:GeneratedCodeAnalysis>

## See Also

- [CloudKit Web Services documentation](https://developer.apple.com/documentation/cloudkitwebservices)
- [Apple Developer Console](https://developer.apple.com)
- [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)
