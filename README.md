![MistKit Logo](Sources/MistKit/Documentation.docc/Resources/logo.svg)

# MistKit


[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FMistKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/brightdigit/MistKit)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FMistKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/brightdigit/MistKit)
[![License](https://img.shields.io/github/license/brightdigit/MistKit)](LICENSE)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/brightdigit/MistKit/MistKit.yml?label=actions&logo=github&?branch=main)](https://github.com/brightdigit/MistKit/actions)
[![Codecov](https://img.shields.io/codecov/c/github/brightdigit/MistKit)](https://codecov.io/gh/brightdigit/MistKit)
[![Maintainability](https://qlty.sh/badges/55637213-d307-477e-a710-f9dba332d955/maintainability.svg)](https://qlty.sh/gh/brightdigit/projects/MistKit)
[![Documentation](https://img.shields.io/badge/docc-read_documentation-blue)](https://swiftpackageindex.com/brightdigit/MistKit/documentation)

A Swift Package for Server-Side and Command-Line Access to [CloudKit Web Services](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html)

## Table of Contents
- [Overview](#overview)
    - [Key Features](#key-features)
- [Why Server-Side CloudKit?](#why-server-side-cloudkit)
- [Getting Started](#getting-started)
    - [Installation](#installation)
    - [Requirements](#requirements)
    - [Platform Support](#platform-support)
    - [Quick Start](#quick-start)
- [Usage](#usage)
    - [Authentication](#authentication)
    - [Error Handling](#error-handling)
    - [Advanced Usage](#advanced-usage)
    - [Examples](#examples)
- [Documentation](#documentation)
    - [Guides](#guides)
    - [CloudKit as Your Backend (talk)](#cloudkit-as-your-backend-talk)
- [License](#license)
- [Acknowledgments](#acknowledgments)
- [Roadmap](#roadmap)
- [Support](#support)

## Overview

MistKit provides a modern Swift interface to [CloudKit Web Services](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html) REST API, enabling cross-platform CloudKit access for server-side Swift applications, command-line tools, and platforms where the [CloudKit framework](https://developer.apple.com/documentation/cloudkit) isn't available. 

Built with Swift concurrency (async/await) and designed for modern Swift applications, MistKit supports all three CloudKit authentication methods and provides type-safe access to CloudKit operations.

## Key Features

- **🌍 Cross-Platform Support**: Works on macOS, iOS, tvOS, watchOS, visionOS, Linux, and Windows
- **⚡ Modern Swift**: Built with Swift 6 concurrency features and structured error handling
- **🔐 Multiple Authentication Methods**: API token, web authentication, and server-to-server authentication
- **🛡️ Type-Safe**: Comprehensive type safety with Swift's type system
- **📋 OpenAPI-Based**: Generated from CloudKit Web Services [OpenAPI specification](https://www.openapis.org/) using [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)
- **🔒 Secure**: Built-in security best practices and credential management

## Why Server-Side CloudKit?

Apple's CloudKit framework only runs on Apple platforms. MistKit wraps the CloudKit Web Services REST API so server-side Swift, Linux services, and command-line tools can take part in the same containers as your apps. Four patterns cover most uses:

- **Public database as a managed catalog** — a scheduled job writes data every user wants and the app just queries it. [BushelCloud](https://github.com/brightdigit/BushelCloud) ([`Examples/BushelCloud`](Examples/BushelCloud/)) syncs macOS restore images and Xcode/Swift versions for [Bushel](https://getbushel.app); [CelestraCloud](https://github.com/brightdigit/CelestraCloud) ([`Examples/CelestraCloud`](Examples/CelestraCloud/)) syncs RSS feeds for [Celestra](https://celestr.app). Software-version catalogs, asset packs, feature flags, and MDM configuration fit the same shape.
- **Private database on behalf of a user** — the user signs in once, the server keeps their web auth token, and reads or writes their private database while they are away. [HeartWitch](https://github.com/brightdigit/HeartWitch) links an Apple Watch to a Vapor backend this way; wearable data pipelines, two-way sync with external services, and server-side processing of uploads are the same idea.
- **Web app ↔ Apple device bridge** — a browser portal for a CloudKit-backed app, or a webhook handler that writes straight into a user's records.
- **Data aggregation** — anonymized telemetry read through `records/changes`, or crowdsourced data cleaned up by a background job.

The talk that walks through all of this is [CloudKit as Your Backend](#cloudkit-as-your-backend-talk) below.

## Getting Started

### Installation

Add MistKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/brightdigit/MistKit.git", from: "1.0.0-beta.5")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/brightdigit/MistKit.git`
3. Select version and add to your target


### Requirements

- Swift 6.1+
- Xcode 16.0+ (for iOS/macOS development)
- Linux: Ubuntu 18.04+ with Swift 6.1+

### Platform Support

#### Minimum Platform Versions

| Platform | Minimum Version |
|----------|-----------------|
| macOS | 11.0+ |
| iOS | 14.0+ |
| tvOS | 14.0+ |
| watchOS | 7.0+ |
| visionOS | 1.0+ |
| Linux | Ubuntu 18.04+ |
| Windows | 10+ |

### Quick Start

#### 1. Choose Your Authentication Method

MistKit supports three credential types via the `Credentials` value. The service
does **not** carry a database — each operation picks its database (and signing
method, for the public database) at the call site.

##### API Token (read-only against the public database)
```swift
import MistKit

let credentials = try Credentials(
    apiAuth: APICredentials(
        apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!
    )
)
let service = CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    credentials: credentials
)
```

##### Web Authentication (user-context routes, private/shared database)
```swift
let credentials = try Credentials(
    apiAuth: APICredentials(
        apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!,
        webAuthToken: userWebAuthToken
    )
)
let service = CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    credentials: credentials
)
```

##### Server-to-Server (public database only)
```swift
let credentials = try Credentials(
    serverToServer: ServerToServerCredentials(
        keyID: ProcessInfo.processInfo.environment["CLOUDKIT_KEY_ID"]!,
        privateKey: .file(path: "private_key.pem")
    )
)
let service = CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    credentials: credentials,
    environment: .production
)
```

Provide both `apiAuth` and `serverToServer` to a single `Credentials` when one
service must hit public-database routes via S2S signing **and** user-context
routes via web-auth — MistKit picks the appropriate token manager per call.

#### 2. Call an Operation (database chosen per call)

```swift
let result = try await service.queryRecords(
    Query(recordType: "Post"),
    database: .public(.prefers(.serverToServer))
)
let records = result.records
```

`Database.public` carries a `PublicAuthPreference`:
`.prefers(.serverToServer)` / `.prefers(.webAuth)` (fall back if not configured)
or `.requires(.serverToServer)` / `.requires(.webAuth)` (throw if not configured).
Private/shared always use web-auth.

## Usage

### Authentication

#### API Token Authentication

1. **Get API Token**:
   - Log into the [CloudKit Console](https://icloud.developer.apple.com/dashboard/)
   - Navigate to CloudKit Database
   - Generate an API Token

2. **Set Environment Variable**:
   ```bash
   export CLOUDKIT_API_TOKEN="your_api_token_here"
   ```

3. **Use in Code**:
   ```swift
   let credentials = try Credentials(
       apiAuth: APICredentials(
           apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!
       )
   )
   let service = CloudKitService(
       containerIdentifier: "iCloud.com.example.MyApp",
       credentials: credentials
   )
   ```

#### Web Authentication

Web authentication enables user-specific operations and requires both an API token and a web authentication token. The token can be obtained either through [CloudKit JS](https://developer.apple.com/documentation/cloudkitjs) authentication (browser flow) or from an iOS/macOS app via [`CKFetchWebAuthTokenOperation`](https://developer.apple.com/documentation/cloudkit/ckfetchwebauthtokenoperation), which exchanges the user's existing iCloud session for a token your backend can use.

```swift
let credentials = try Credentials(
    apiAuth: APICredentials(apiToken: apiToken, webAuthToken: webAuthToken)
)
let service = CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    credentials: credentials
)
```

#### Server-to-Server Authentication

Server-to-server authentication provides enterprise-level access using ECDSA P-256 key signing. Note that this method only supports the public database.

1. **Generate Key Pair**:
   ```bash
   # Generate private key
   openssl ecparam -genkey -name prime256v1 -noout -out private_key.pem

   # Extract public key
   openssl ec -in private_key.pem -pubout -out public_key.pem
   ```

2. **Upload Public Key**: Upload the public key to Apple Developer Console

3. **Use in Code** (the simplest path — `Credentials` resolves the PEM at first use):
   ```swift
   let credentials = try Credentials(
       serverToServer: ServerToServerCredentials(
           keyID: "your_key_id",
           privateKey: .file(path: "private_key.pem")
       )
   )
   let service = CloudKitService(
       containerIdentifier: "iCloud.com.example.MyApp",
       credentials: credentials,
       environment: .production
   )

   // Each call selects its database scope explicitly:
   let records = try await service.queryRecords(
       Query(recordType: "Post"),
       database: .public(.requires(.serverToServer))
   ).records
   ```

   To plug in a custom `TokenManager` (e.g. with shared connection pooling),
   use the `tokenManager:` initializer instead:

   ```swift
   let pemString = try String(contentsOfFile: "private_key.pem", encoding: .utf8)
   let serverManager = try ServerToServerAuthManager(
       keyID: "your_key_id",
       pemString: pemString
   )
   let service = CloudKitService(
       containerIdentifier: "iCloud.com.example.MyApp",
       tokenManager: serverManager,
       environment: .production
   )
   ```

### Error Handling

MistKit provides comprehensive error handling with typed errors:

```swift
do {
    let credentials = try Credentials(
        apiAuth: APICredentials(apiToken: apiToken)
    )
    let service = CloudKitService(
        containerIdentifier: "iCloud.com.example.MyApp",
        credentials: credentials
    )
    // Perform operations — each call picks its database, e.g.:
    let posts = try await service.queryRecords(
        Query(recordType: "Post"),
        database: .public(.prefers(.serverToServer))
    ).records
} catch let error as CloudKitError {
    print("CloudKit error: \\(error.localizedDescription)")
} catch let error as TokenManagerError {
    print("Authentication error: \\(error.localizedDescription)")
} catch let error as CredentialsValidationError {
    print("Credentials error: \\(error.localizedDescription)")
} catch {
    print("Unexpected error: \\(error)")
}
```

#### Error Types

- **`CloudKitError`**: CloudKit Web Services API errors (typed throws on every operation)
- **`CredentialsValidationError`**: Surfaces when `Credentials.init` is called with neither `apiAuth` nor `serverToServer`
- **`TokenManagerError`**: Authentication and credential errors
- **`TokenStorageError`**: Token storage and persistence errors

### Advanced Usage

#### More Operations

Beyond querying and CRUD, MistKit covers zones, subscriptions, push tokens, and
asset re-referencing. Every call takes an explicit `database:`.

```swift
// Zones
let zone = try await service.createZone(
    zoneName: "Notes",
    database: .private
)
try await service.deleteZone(zoneName: "Notes", database: .private)
// Batch create/delete via service.modifyZones(_:database:)
// (takes [ZoneOperation], returns [ZoneChangeResult] — inspect
// `.zones` and `.failures` for per-zone outcomes).

// Subscriptions
let subs = try await service.listSubscriptions(database: .private)
let one = try await service.lookupSubscriptions(ids: ["sub-1"], database: .private)
// Create/update/delete via service.modifySubscriptions(_:database:)
// (takes [SubscriptionOperation], returns [SubscriptionResult]).

// APNs push tokens
let token = try await service.createAPNsToken(
    environment: .development,
    database: .private
)
try await service.registerAPNsToken(
    token.apnsToken,
    environment: .development,
    database: .private
)

// Re-reference existing CDN assets without re-uploading bytes
let assets = try await service.rereferenceAssets(
    [(recordName: "rec-1", fieldName: "photo")],
    database: .private
)
```

#### Change Tracking

CloudKit exposes four change-tracking endpoints. MistKit wraps all four; each
single-request primitive has an auto-paginating `fetchAll…` companion.

| Apple endpoint | Purpose | MistKit method | Auto-paginating |
|---|---|---|---|
| `records/changes` | Fetching Record Changes | `fetchRecordChanges` | `fetchAllRecordChanges` |
| `changes/database` | Fetching Database Changes — *which zones* changed | `fetchDatabaseChanges` | `fetchAllDatabaseChanges` |
| `changes/zone` | Fetching Record Zone Changes — records *within* zones | `fetchRecordZoneChanges` | `fetchAllRecordZoneChanges` |
| `zones/changes` | Fetching Zone Changes — **deprecated by Apple** | ~~`fetchZoneChanges`~~ | ~~`fetchAllZoneChanges`~~ |

> `zones/changes` is deprecated by Apple in favor of `changes/database`, so
> `fetchZoneChanges` / `fetchAllZoneChanges` are marked `@available(*, deprecated)`.
> Use `fetchDatabaseChanges` instead.

The typical database-sync flow asks *which zones changed*, then fetches the
records inside them:

```swift
// 1. Which zones changed?
let database = try await service.fetchDatabaseChanges(
    syncToken: lastDatabaseToken,
    database: .private
)

// 2. What changed inside them?
let result = try await service.fetchAllRecordZoneChanges(
    zones: database.changedZones.map {
        ZoneChangesRequest(zoneID: ZoneID(zoneName: $0.zoneName))
    },
    database: .private
)

for change in result.changes {
    print("\(change.zone.zoneName): \(change.records.count) changed")
    // Persist change.syncToken per zone — each zone paginates independently.
}
```

Both operations report per-zone problems as data rather than throwing, so one
bad zone never discards the zones that succeeded:

```swift
for failure in result.failures {
    print("\(failure.zoneName) failed: \(failure.serverErrorCode.rawValue)")
}
```

#### Auto-Chunking Conveniences

CloudKit caps batch requests at 200 items. `lookupAllRecords` and the
`lookupInfos:` form of `discoverAllUserIdentities` split oversized inputs into
≤`maxRecordsPerRequest` (200) batches automatically and concatenate the results
in input order — no manual chunking required.

```swift
let records = try await service.lookupAllRecords(
    recordNames: thousandsOfNames,   // chunked into 200-item requests
    database: .private
)

let identities = try await service.discoverAllUserIdentities(
    lookupInfos: manyLookupInfos,
    batchSize: 200
)
```

#### HTTP Transport

Non-WASI platforms default to `URLSessionTransport` — no transport plumbing is
required. On Apple platforms, the default convenience initializer used in the
examples above wires up `URLSessionTransport` automatically.

WASI builds use the generic, transport-accepting initializer; see
`Sources/MistKit/CloudKitService/CloudKitService+Initialization.swift` for the
internal entry point. A custom transport on Apple platforms (e.g. for
server-side Swift with AsyncHTTPClient) is not yet exposed in the public
v1.0.0-beta surface — track via the project roadmap.

#### Adaptive Token Manager

For applications that might upgrade from API-only to web authentication:

```swift
let adaptiveManager = AdaptiveTokenManager(
    apiToken: apiToken,
    storage: storage
)

// Later, upgrade to web authentication
try await adaptiveManager.upgradeToWebAuthentication(webAuthToken: webToken)
```

### Examples

Check out the `Examples/` directory for complete working examples:

- **[MistDemo](Examples/MistDemo/)**: Web-based CloudKit authentication demo with automatic token capture
- **[BushelCloud](Examples/BushelCloud/)** ([standalone repo](https://github.com/brightdigit/BushelCloud)): Server-to-Server auth demo syncing macOS restore images, Xcode, and Swift versions from a scheduled GitHub Actions job — backend for the [Bushel app](https://getbushel.app)
- **[CelestraCloud](Examples/CelestraCloud/)** ([standalone repo](https://github.com/brightdigit/CelestraCloud)): RSS reader demonstrating CloudKit query filtering, sorting, and web etiquette patterns — backend for the [Celestra app](https://celestr.app), built with [SyndiKit](https://github.com/brightdigit/SyndiKit)

## Documentation

- **[API Documentation](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit)**: Complete API reference, hosted on Swift Package Index

### Guides

The DocC catalog (`Sources/MistKit/Documentation.docc/`) carries the long-form guides. Links below point at the published pages; pages added on this branch appear once Swift Package Index rebuilds the default branch.

- **[CloudKit as Your Backend](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/cloudkitasyourbackend)**: the conference talk in article form — see [below](#cloudkit-as-your-backend-talk)
- **[Authentication and Databases](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/authenticationanddatabases)**: which credentials reach which database, obtaining tokens and keys from the CloudKit Console
- **[Request Signing](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/requestsigning)**: token managers, authenticators, the middleware, and the ECDSA payload
- **[Working with Records](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/workingwithrecords)**: query, create, update, delete, batch, and sync
- **[Field Type Polymorphism](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/fieldtypepolymorphism)**: how nine CloudKit field types map onto one Swift enum, and the wire-format traps
- **[Handling Errors](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/handlingerrors)**: typed errors at every layer and how CloudKit's JSON becomes a `CloudKitError`
- **[Deploying MistKit](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/deployingmistkit)**: static Linux builds, credentials in CI, scheduling, idempotency, observability
- **[Configuring MistKit](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/configuringmistkit)** and **[CloudKit Limits and Performance](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/cloudkitlimitsandperformance)**
- **[Abstraction Layer Architecture](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/abstractionlayerarchitecture)**, **[OpenAPI Code Generation](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/openapicodegeneration)**, **[Generated Code Workflow](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/generatedcodeworkflow)**, **[Generated Code Analysis](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/generatedcodeanalysis)**
- **[What CloudKit Got Wrong](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/whatcloudkitgotwrong)**: where Apple's documentation and Apple's server disagree
- **[What the AI Got Wrong](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/whattheaigotwrong)**: an evidence-backed catalogue of AI-assisted development failure modes from this project

Articles on brightdigit.com: [Rebuilding MistKit with Claude Code, part 1](https://brightdigit.com/tutorials/rebuilding-mistkit-claude-code-part-1/) and [part 2](https://brightdigit.com/tutorials/rebuilding-mistkit-claude-code-part-2/).

### CloudKit as Your Backend (talk)

*From iOS to Server-Side Swift* — given in 2026 at Swift Craft and iOSDevUK by Leo Dion ([@leogdion@c.im](https://c.im/@leogdion)). The full article, following the slide order with screenshots and code from this repository, is in the DocC catalog: **[CloudKit as Your Backend](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit/cloudkitasyourbackend)** (source: [`CloudKitAsYourBackend.md`](Sources/MistKit/Documentation.docc/CloudKitAsYourBackend.md)). Download the slides: [CloudKit-Backend-iOSDevUK.pdf](https://github.com/brightdigit/MistKit/releases/download/1.0.0-beta.5/CloudKit-Backend-iOSDevUK.pdf) (~12 MB).

> CloudKit has excellent documentation for iOS and macOS client development. But backend services — podcast aggregation, RSS readers, data processing — face APIs that Apple barely documents. I rebuilt a comprehensive CloudKit library using AI-generated OpenAPI specifications. The result: type-safe Swift code supporting three authentication methods (server-to-server, web authentication token, and API token), typed error handling, and production deployments.

Links from the talk:

#### Leo Dion / BrightDigit

- [MistKit on GitHub](https://github.com/brightdigit/MistKit) and [MistKit issues](https://github.com/brightdigit/MistKit/issues) — "What's next?"
- [MistDemo](Examples/MistDemo/) — CLI, macOS app and web demo used for integration testing
- [Bushel](https://getbushel.app) — Virtualization for App Developers
- [AtLeast](https://atleast.app) — Passive Timer for Apple Watch
- [Heartwitch](https://heartwitch.app) — Apple Watch heart-rate streaming; [App Store](https://apps.apple.com/us/app/heartwitch/id1480031203)
- [BrightDigit](https://brightdigit.com)
- [linktr.ee/leogdion](https://linktr.ee/leogdion)
- [iOSDevUK](https://www.iosdevuk.com)

#### Use case examples

- [BushelCloud](https://github.com/brightdigit/BushelCloud) — server-to-server sync of macOS restore images, Xcode and Swift versions for Bushel; the GitHub Actions deployment shown in the talk (also at [`Examples/BushelCloud`](Examples/BushelCloud/))
  - [`cloudkit-sync-dev.yml`](Examples/BushelCloud/.github/workflows/cloudkit-sync-dev.yml) — scheduled workflow
  - [`cloudkit-sync` composite action](Examples/BushelCloud/.github/actions/cloudkit-sync/action.yml)
- [CelestraCloud](https://github.com/brightdigit/CelestraCloud) — RSS feed sync into a public database for Celestra, with query filtering and sorting (also at [`Examples/CelestraCloud`](Examples/CelestraCloud/))
- [HeartWitch](https://github.com/brightdigit/HeartWitch) — the private-database, Apple Watch to Vapor bridge
- [Rebuilding MistKit with Claude Code, part 1](https://brightdigit.com/tutorials/rebuilding-mistkit-claude-code-part-1/) and [part 2](https://brightdigit.com/tutorials/rebuilding-mistkit-claude-code-part-2/)

#### What is CloudKit

- [WWDC 2014 "Introducing CloudKit" (session 208)](https://nonstrict.eu/wwdcindex/wwdc2014/208/) — Apple no longer hosts the video; this mirror has the video, slides and transcript. Transcript only: [ASCIIwwdc](https://asciiwwdc.com/2014/sessions/208)
- [CloudKit framework documentation](https://developer.apple.com/documentation/cloudkit)
- [Enabling CloudKit in your app](https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app) — Xcode capability setup
- [CloudKit Console](https://icloud.developer.apple.com/dashboard/)
- [Integrating a text-based schema into your workflow](https://developer.apple.com/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow)
- [cktool](https://developer.apple.com/icloud/ck-tool/) and [Automating CloudKit Development](https://developer.apple.com/icloud/cloudkit/automating/)

#### CloudKit Web Services

- [CloudKit JS](https://developer.apple.com/documentation/cloudkitjs)
- [CloudKit Web Services Reference](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html) — archived
  - [Composing Web Service Requests](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html)
  - [Accessing CloudKit Using an API Token](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html#//apple_ref/doc/uid/TP40015240-CH24-SW2)
  - [Accessing CloudKit Using a Server-to-Server Key](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html#//apple_ref/doc/uid/TP40015240-CH24-SW6)
  - [Document Revision History](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/RevisionHistory.html) — last updated 2016
  - [Uploading Assets](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/UploadAssets.html)
  - [Types and Dictionaries](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Types.html) — field types
  - [Error Codes](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/ErrorCodes.html)
  - [Discovering User Identities (POST users/discover)](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/DiscoveringUserIdentities%28usersdiscover%29.html)
  - [Discovering All User Identities (GET users/discover)](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/DiscoveringAllUserIdentities.html) — the endpoint that returns HTTP 500
- Base URL: `https://api.apple-cloudkit.com/database/{version}/{container}/{environment}/{database}/{operation}`
- [Apple Developer Support](https://developer.apple.com/support/) — contact URL in the OpenAPI document

#### Authentication

- [CKFetchWebAuthTokenOperation](https://developer.apple.com/documentation/cloudkit/ckfetchwebauthtokenoperation)
- [Sign in with Apple](https://developer.apple.com/documentation/signinwithapple) — mentioned as not existing when Heartwitch was built
- [swift-crypto](https://github.com/apple/swift-crypto) — `P256.Signing.PrivateKey` used in `RequestSignature`
- MistKit source shown in the talk: [`AuthenticationMiddleware.swift`](Sources/MistKit/Authentication/AuthenticationMiddleware.swift), [`APITokenAuthenticator.swift`](Sources/MistKit/Authentication/APITokenAuthenticator.swift), [`WebAuthTokenAuthenticator.swift`](Sources/MistKit/Authentication/WebAuthTokenAuthenticator.swift), [`ServerToServerAuthenticator.swift`](Sources/MistKit/Authentication/ServerToServerAuthenticator.swift), [`RequestSignature.swift`](Sources/MistKit/Authentication/RequestSignature.swift)

#### Swift OpenAPI Generator

- [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)
- [WWDC23 "Meet Swift OpenAPI Generator"](https://developer.apple.com/videos/play/wwdc2023/10171/)
- [Documentation](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator) and [tutorial: Working with Swift OpenAPI Generator](https://swiftpackageindex.com/apple/swift-openapi-generator/tutorials/swift-openapi-generator)
- [ClientMiddleware](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clientmiddleware) — the ["Implement a custom client middleware"](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clientmiddleware#Implement-a-custom-client-middleware) bearer-token example is a section on that page
- [Example projects](https://github.com/apple/swift-openapi-generator/tree/main/Examples) — including auth, logging and retrying middleware examples
- Package ecosystem: [swift-openapi-runtime](https://github.com/apple/swift-openapi-runtime), [swift-openapi-urlsession](https://github.com/apple/swift-openapi-urlsession), [swift-openapi-async-http-client](https://github.com/swift-server/swift-openapi-async-http-client), [swift-okhttp](https://github.com/frameo-net/swift-okhttp), [swift-openapi-vapor](https://github.com/vapor/swift-openapi-vapor), [swift-openapi-hummingbird](https://github.com/hummingbird-project/swift-openapi-hummingbird), [swift-openapi-lambda](https://github.com/awslabs/swift-openapi-lambda)
- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)
- [MistKit `openapi.yaml`](openapi.yaml)

#### Field types and error handling

- [`FieldValue.swift`](Sources/MistKit/Models/FieldValues/FieldValue.swift)
- [MistKit issue #28: discoverAllUserIdentities returns HTTP 500](https://github.com/brightdigit/MistKit/issues/28)
  - Broken call, CloudKit Web Services: [Discovering All User Identities (GET users/discover)](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/DiscoveringAllUserIdentities.html)
  - Broken call, CloudKit JS: [`CloudKit.Container.discoverAllUserIdentities`](https://developer.apple.com/documentation/cloudkitjs/cloudkit.container/discoveralluseridentities)
- Apple Feedback FB22754466 — public copy on [Open Radar](https://openradar.appspot.com/FB22754466); filed via [Feedback Assistant](https://feedbackassistant.apple.com/)

#### Deployment

- [GitHub Actions: scheduled workflows (`schedule` / cron)](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#schedule)
- [GitHub Actions: using secrets](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions)
- [GitHub Actions: creating a composite action](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action)
- [actions/checkout](https://github.com/actions/checkout)
- [dawidd6/action-download-artifact](https://github.com/dawidd6/action-download-artifact)
- [Swift Docker images](https://hub.docker.com/_/swift) — the sync action builds with `swiftlang/swift:nightly-6.4.x-noble`
- [swift-configuration](https://github.com/apple/swift-configuration) — how the example CLIs read configuration from environment variables or arguments
- [MistKitConfiguration](https://github.com/brightdigit/MistKitConfiguration) — the shared credential-configuration package built on it (also at [`Packages/MistKitConfiguration`](Packages/MistKitConfiguration/))

#### Other tools mentioned

- [Hummingbird](https://hummingbird.codes) — server behind the MistDemo web interface
- [Vapor](https://vapor.codes) — Heartwitch backend
- [OBS Studio](https://obsproject.com) — Heartwitch streaming overlay

### Apple References

- **[CloudKit Web Services](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html)**: Official CloudKit Web Services REST API documentation
- **[CloudKit framework](https://developer.apple.com/documentation/cloudkit)**: On-device CloudKit framework (iOS/macOS)
- **[CloudKit JS](https://developer.apple.com/documentation/cloudkitjs)**: Browser-based CloudKit access used for web auth token capture
- **[CKFetchWebAuthTokenOperation](https://developer.apple.com/documentation/cloudkit/ckfetchwebauthtokenoperation)**: iOS/macOS API for exchanging an iCloud session for a web auth token

### Related Swift Packages

- **[swift-openapi-generator](https://github.com/apple/swift-openapi-generator)**: Generates type-safe Swift clients from OpenAPI specs
- **[swift-openapi-async-http-client](https://github.com/swift-server/swift-openapi-async-http-client)**: AsyncHTTPClient transport for OpenAPI clients
- **[AsyncHTTPClient](https://github.com/swift-server/async-http-client)**: HTTP client for server-side Swift
- **[swift-crypto](https://github.com/apple/swift-crypto)**: Cross-platform crypto used for ECDSA P-256 server-to-server signing

## License

MistKit is released under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- Built on [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator)
- Uses [Swift Crypto](https://github.com/apple/swift-crypto) for server-to-server authentication
- Inspired by CloudKit Web Services REST API

## Roadmap

### v1.1.0

- [ ] [Add CloudKit Schema Management APIs (cktool/cktooljs functionality)](https://github.com/brightdigit/MistKit/issues/135)
- [ ] [Add KeyPath-based QueryFilter API for Type-Safe Filtering](https://github.com/brightdigit/MistKit/issues/149)

## Support

- **Issues**: [GitHub Issues](https://github.com/brightdigit/MistKit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/brightdigit/MistKit/discussions)
- **Documentation**: [API Reference](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation/mistkit)

---

*MistKit: Bringing CloudKit to every Swift platform* 🌟
