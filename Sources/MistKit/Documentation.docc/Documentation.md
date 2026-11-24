# ``MistKit``

A Swift package for server-side and command-line access to CloudKit Web Services.

![MistKit Logo](logo)

## Overview

MistKit wraps Apple's [CloudKit Web Services REST API](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html) with a modern Swift surface so server-side code, CLIs, and platforms without the native CloudKit framework (Linux, WASI, Windows) can read and write the same containers as your Apple apps.

The library is built on [`swift-openapi-generator`](https://github.com/apple/swift-openapi-generator) against an OpenAPI document written for CloudKit Web Services, with a hand-written abstraction layer on top that exposes typed records, async iteration, structured errors, and three authentication schemes.

New to server-side CloudKit? Start with <doc:CloudKitAsYourBackend>, the written form of the conference talk that explains why the library exists and how its pieces fit together.

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
  Query(recordType: "Note"),
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

MistKit runs on macOS, iOS, tvOS, watchOS, visionOS, Linux, [WASI](https://wasi.dev), and Windows. Server-to-server signing depends on Crypto / [swift-crypto](https://github.com/apple/swift-crypto), so it is unavailable on Windows and WASI — those targets must use API-token + web-auth credentials. URL-loading conveniences and asset upload use `URLSession`; the public initializers are compiled only for non-WASI platforms, and a public transport-accepting initializer for WASI is not available yet (see <doc:ConfiguringMistKit>).

> Tip: On native Apple platforms (macOS, iOS, tvOS, watchOS, visionOS) prefer the native [CloudKit framework](https://developer.apple.com/documentation/cloudkit). It integrates with the system account, handles push notifications and long-lived operations, and avoids the per-request signing overhead of the web-services API. MistKit is intended for environments where the native framework isn't available — server-side Swift, CLIs, Linux, and Windows.

> Warning: WASI is not a fully supported target. The web-services API requires HMAC/ECDSA signing and a working HTTP transport, neither of which has a first-class story on WASI today. For CloudKit access from the browser, use Apple's official [CloudKit JS](https://developer.apple.com/documentation/cloudkitjs) library instead.

## Topics

### Essentials

- <doc:CloudKitAsYourBackend>
- <doc:ConfiguringMistKit>
- <doc:AuthenticationAndDatabases>
- <doc:AbstractionLayerArchitecture>
- ``CloudKitService``
- ``Database``
- ``Environment``

### Records

- <doc:WorkingWithRecords>
- <doc:BatchingAndPagination>
- ``RecordInfo``
- ``FieldValue``
- ``Reference``
- ``Asset``
- ``Location``
- ``RecordTimestamp``
- ``RecordOperation``
- ``ZonedRecordOperation``
- ``RecordResult``
- ``RecordChangesResult``
- ``OperationClassification``
- ``BatchSyncResult``

### Queries

- <doc:BuildingQueries>
- ``Query``
- ``QueryFilter``
- ``QuerySort``
- ``FilterComparator``
- ``QueryResult``
- ``QueryDescriptor``
- ``QueryPredicate``
- ``QueryValidation``
- ``QueryValidationIssue``

### Zones and change tracking

- ``ZoneID``
- ``ZoneInfo``
- ``ZoneType``
- ``ZoneOperation``
- ``ZoneChangeResult``
- ``DatabaseChangesResult``
- ``ZoneChangesRequest``
- ``RecordZoneChangesResult``
- ``ZoneRecordChanges``
- ``ZoneChangesResult``

### Users and sharing

- ``UserInfo``
- ``UserIdentity``
- ``UserIdentityLookupInfo``
- ``NameComponents``
- ``CreatedShare``
- ``ShareInfo``
- ``ShareRecordInfo``
- ``ShortGUID``
- ``ShortGUIDDictionary``

### Assets

- ``AssetUploader``
- ``AssetUploadResponse``
- ``AssetUploadReceipt``
- ``AssetUploadToken``

### Subscriptions and notifications

- ``SubscriptionInfo``
- ``SubscriptionOperation``
- ``SubscriptionResult``
- ``Courier``
- ``WebCourierPoller``
- ``CourierNotification``
- ``APNsTokenResult``

### Schemas and the Management API

- <doc:ManagingSchemas>
- ``CloudKitManagementService``
- ``ManagementToken``
- ``CloudKitSchema``
- ``SchemaRecordType``
- ``SchemaField``
- ``SchemaFieldType``
- ``FieldType``
- ``SchemaSource``

### JSON and wire format

- <doc:EncodingRecordsAsJSON>
- <doc:FieldTypePolymorphism>
- ``WireFieldValue``
- ``WireRecord``
- ``WireRecordDocument``
- ``WireRecordOperation``
- ``ModifyRecordsRequestBody``
- ``FieldTypeTagging``

### Authentication

- ``Credentials``
- ``APICredentials``
- ``ServerToServerCredentials``
- ``PublicAuthPreference``
- ``PrivateKeyMaterial``
- ``CredentialVerification``
- ``TokenManager``
- ``TokenStorage``
- ``Authenticator``

### Errors

- <doc:HandlingErrors>
- ``CloudKitError``
- ``CloudKitManagementError``
- ``ConversionError``
- ``RecordFieldErrorContext``
- ``OperationFailure``
- ``TokenManagerError``
- ``CredentialsValidationError``

### Record management protocols

- ``CloudKitRecord``
- ``RecordManaging``
- ``CloudKitRecordCollection``
- ``RecordTypeSet``
- ``RecordTypeIterating``

### Operations and limits

- <doc:CloudKitLimitsAndPerformance>
- <doc:DeployingMistKit>
- <doc:iOSDevUKTalk>

### Under the hood

- <doc:RequestSigning>
- <doc:OpenAPICodeGeneration>
- <doc:GeneratedCodeWorkflow>
- <doc:GeneratedCodeAnalysis>

### Background

- <doc:WhatCloudKitGotWrong>
- <doc:WhatTheAIGotWrong>

## See Also

- [CloudKit Web Services documentation](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html)
- [CloudKit Console](https://icloud.developer.apple.com/dashboard/)
- [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)
