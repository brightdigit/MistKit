![MistKit Logo](Sources/MistKit/Documentation.docc/Resources/logo.svg)

# MistKit


[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FMistKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/brightdigit/MistKit)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FMistKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/brightdigit/MistKit)
[![License](https://img.shields.io/github/license/brightdigit/MistKit)](LICENSE)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/brightdigit/MistKit/MistKit.yml?label=actions&logo=github&?branch=main)](https://github.com/brightdigit/MistKit/actions)
[![Codecov](https://img.shields.io/codecov/c/github/brightdigit/MistKit)](https://codecov.io/gh/brightdigit/MistKit)
[![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/brightdigit/MistKit)](https://www.codefactor.io/repository/github/brightdigit/MistKit)
[![Maintainability](https://qlty.sh/badges/55637213-d307-477e-a710-f9dba332d955/maintainability.svg)](https://qlty.sh/gh/brightdigit/projects/MistKit)
[![Documentation](https://img.shields.io/badge/docc-read_documentation-blue)](https://swiftpackageindex.com/brightdigit/MistKit/documentation)

A Swift Package for Server-Side and Command-Line Access to [CloudKit Web Services](https://developer.apple.com/documentation/cloudkitwebservices)

## Table of Contents
- [Overview](#overview)
    - [Key Features](#key-features)
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
- [License](#license)
- [Acknowledgments](#acknowledgments)
- [Roadmap](#roadmap)
- [Support](#support)

## Overview

MistKit provides a modern Swift interface to [CloudKit Web Services](https://developer.apple.com/documentation/cloudkitwebservices) REST API, enabling cross-platform CloudKit access for server-side Swift applications, command-line tools, and platforms where the [CloudKit framework](https://developer.apple.com/documentation/cloudkit) isn't available. 

Built with Swift concurrency (async/await) and designed for modern Swift applications, MistKit supports all three CloudKit authentication methods and provides type-safe access to CloudKit operations.

## Key Features

- **🌍 Cross-Platform Support**: Works on macOS, iOS, tvOS, watchOS, visionOS, and Linux
- **⚡ Modern Swift**: Built with Swift 6 concurrency features and structured error handling
- **🔐 Multiple Authentication Methods**: API token, web authentication, and server-to-server authentication
- **🛡️ Type-Safe**: Comprehensive type safety with Swift's type system
- **📋 OpenAPI-Based**: Generated from CloudKit Web Services [OpenAPI specification](https://www.openapis.org/) using [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)
- **🔒 Secure**: Built-in security best practices and credential management

## Getting Started

### Installation

Add MistKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/brightdigit/MistKit.git", from: "1.0.0-beta.1")
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

| Platform | Minimum Version | Server-to-Server Auth |
|----------|-----------------|----------------------|
| macOS | 10.15+ | 11.0+ |
| iOS | 13.0+ | 14.0+ |
| tvOS | 13.0+ | 14.0+ |
| watchOS | 6.0+ | 7.0+ |
| visionOS | 1.0+ | 1.0+ |
| Linux | Ubuntu 18.04+ | ✅ |
| Windows | 10+ | ✅ |

### Quick Start

#### 1. Choose Your Authentication Method

MistKit supports three authentication methods depending on your use case:

##### API Token (Container-level access)
```swift
import MistKit

let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!
)
```

##### Web Authentication (User-specific access)
```swift
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!,
    webAuthToken: userWebAuthToken
)
```

##### Server-to-Server (Enterprise access, public database only)
```swift
let serverManager = try ServerToServerAuthManager(
    keyIdentifier: ProcessInfo.processInfo.environment["CLOUDKIT_KEY_ID"]!,
    privateKeyData: privateKeyData
)

let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    tokenManager: serverManager,
    environment: .production,
    database: .public
)
```

#### 2. Create CloudKit Service

```swift
do {
    let service = try CloudKitService(
        containerIdentifier: "iCloud.com.example.MyApp",
        apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!
    )
    // Use service for CloudKit operations
} catch {
    print("Failed to create service: \\(error)")
}
```

## Usage

### Authentication

#### API Token Authentication

1. **Get API Token**:
   - Log into [Apple Developer Console](https://developer.apple.com)
   - Navigate to CloudKit Database
   - Generate an API Token

2. **Set Environment Variable**:
   ```bash
   export CLOUDKIT_API_TOKEN="your_api_token_here"
   ```

3. **Use in Code**:
   ```swift
   let service = try CloudKitService(
       containerIdentifier: "iCloud.com.example.MyApp",
       apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!
   )
   ```

#### Web Authentication

Web authentication enables user-specific operations and requires both an API token and a web authentication token. The token can be obtained either through [CloudKit JS](https://developer.apple.com/documentation/cloudkitjs) authentication (browser flow) or from an iOS/macOS app via [`CKFetchWebAuthTokenOperation`](https://developer.apple.com/documentation/cloudkit/ckfetchwebauthtokenoperation), which exchanges the user's existing iCloud session for a token your backend can use.

```swift
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    apiToken: apiToken,
    webAuthToken: webAuthToken
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

3. **Use in Code**:
   ```swift
   let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: "private_key.pem"))

   let serverManager = try ServerToServerAuthManager(
       keyIdentifier: "your_key_id",
       privateKeyData: privateKeyData
   )
   let service = try CloudKitService(
       containerIdentifier: "iCloud.com.example.MyApp",
       tokenManager: serverManager,
       environment: .production,
       database: .public
   )
   ```

### Error Handling

MistKit provides comprehensive error handling with typed errors:

```swift
do {
    let service = try CloudKitService(
        containerIdentifier: "iCloud.com.example.MyApp",
        apiToken: apiToken
    )
    // Perform operations
} catch let error as CloudKitError {
    print("CloudKit error: \\(error.localizedDescription)")
} catch let error as TokenManagerError {
    print("Authentication error: \\(error.localizedDescription)")
} catch {
    print("Unexpected error: \\(error)")
}
```

#### Error Types

- **`CloudKitError`**: CloudKit Web Services API errors
- **`TokenManagerError`**: Authentication and credential errors
- **`TokenStorageError`**: Token storage and persistence errors

### Advanced Usage

#### Using AsyncHTTPClient Transport

For server-side applications, MistKit can use [swift-openapi-async-http-client](https://github.com/swift-server/swift-openapi-async-http-client) as the underlying HTTP transport, backed by [AsyncHTTPClient](https://github.com/swift-server/async-http-client). This is particularly useful for server-side Swift applications that need robust HTTP client capabilities.

```swift
import MistKit
import OpenAPIAsyncHTTPClient

// AsyncHTTPClient instance usually supplied by the Server API
let httpClient : HTTPClient

// Create the transport
let transport = AsyncHTTPClientTransport(client: httpClient)

// Use with CloudKit service
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    apiToken: apiToken,
    transport: transport
)
```

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
- **[BushelCloud](Examples/BushelCloud/)**: Server-to-Server auth demo syncing macOS restore images, Xcode, and Swift versions — backend for the [Bushel app](https://getbushel.app)
- **[CelestraCloud](Examples/CelestraCloud/)**: RSS reader demonstrating CloudKit query filtering, sorting, and web etiquette patterns — backend for the [Celestra app](https://celestr.app), built with [SyndiKit](https://github.com/brightdigit/SyndiKit)

## Documentation

- **[API Documentation](https://swiftpackageindex.com/brightdigit/MistKit/~/documentation)**: Complete API reference

### Apple References

- **[CloudKit Web Services](https://developer.apple.com/documentation/cloudkitwebservices)**: Official CloudKit Web Services REST API documentation
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

### v1.0.0-alpha.1

- [x] [Composing Web Service Requests](https://github.com/brightdigit/MistKit/issues/111) ✅
- [x] [Modifying Records (records/modify)](https://github.com/brightdigit/MistKit/issues/114) ✅
- [x] [Fetching Records Using a Query (records/query)](https://github.com/brightdigit/MistKit/issues/114) ✅
- [x] [Fetching Records by Record Name (records/lookup)](https://github.com/brightdigit/MistKit/issues/114) ✅
- [x] [Fetching Current User Identity (users/caller)](https://github.com/brightdigit/MistKit/issues/114) ✅

### v1.0.0-alpha.2

- [x] [Vapor Token Client](https://github.com/brightdigit/MistKit/issues/113) ✅
- [x] [Vapor Token Storage](https://github.com/brightdigit/MistKit/issues/113) ✅
- [x] [Vapor URL Client](https://github.com/brightdigit/MistKit/issues/113) ✅
- [x] [Swift NIO URL Client](https://github.com/brightdigit/MistKit/issues/113) ✅
- [x] [Date Field Types](https://github.com/brightdigit/MistKit/issues/110) ✅
- [x] [Location Field Types](https://github.com/brightdigit/MistKit/issues/110) ✅
- [x] [List Field Types](https://github.com/brightdigit/MistKit/issues/110) ✅
- [x] [Reference Field Types](https://github.com/brightdigit/MistKit/issues/110) ✅
- [x] [Error Codes](https://github.com/brightdigit/MistKit/issues/115) ✅
- [x] [Fetching Zones (zones/list)](https://github.com/brightdigit/MistKit/issues/116) ✅

### v1.0.0-alpha.3

- [x] [Uploading Assets (assets/upload)](https://github.com/brightdigit/MistKit/issues/30) ✅
- [x] [Add Support for swiftlang/swift-source-compat-suite](https://github.com/brightdigit/MistKit/issues/185) ✅

### v1.0.0-alpha.4

- [x] [Uploading Assets (assets/upload)](https://github.com/brightdigit/MistKit/issues/30) ✅
- [x] [Add Support for swiftlang/swift-source-compat-suite](https://github.com/brightdigit/MistKit/issues/185) ✅
- [x] [MistDemo - Web Authentication Demo](https://github.com/brightdigit/MistKit/pull/227) ✅
- [x] [WASM Platform Support](https://github.com/brightdigit/MistKit/pull/206) ✅
- [x] [Android Platform Support](https://github.com/brightdigit/MistKit/pull/189) ✅

### v1.0.0-alpha.5

- [x] [Name Component Types](https://github.com/brightdigit/MistKit/issues/26) ✅
- [x] [Discovering User Identities (POST users/discover)](https://github.com/brightdigit/MistKit/issues/27) ✅
- [x] [Fetching Record Changes (records/changes)](https://github.com/brightdigit/MistKit/issues/40) ✅
- [x] [Fetching Zones by Identifier (zones/lookup)](https://github.com/brightdigit/MistKit/issues/44) ✅
- [x] [Fetching Zone Changes (zones/changes)](https://github.com/brightdigit/MistKit/issues/48) ✅
- [x] [Fix QueryFilter IN/NOT_IN serialization](https://github.com/brightdigit/MistKit/issues/192)  ✅

### v1.0.0-beta.1

**Querying & Sync**
- [x] Query pagination with continuation markers ([#306](https://github.com/brightdigit/MistKit/pull/306)) ✅
- [x] Operation classification & batch sync result tracking ([#296](https://github.com/brightdigit/MistKit/pull/296)) ✅

**Authentication**
- [x] `AuthenticationMiddleware` refactor — each `Authenticator` applies itself ([#294](https://github.com/brightdigit/MistKit/pull/294)) ✅
- [x] Strengthened environment & database configuration validation ([#293](https://github.com/brightdigit/MistKit/pull/293)) ✅

**Error Handling**
- [x] Typed `TokenManagerError` and safe `RecordOperation` conversion ([#305](https://github.com/brightdigit/MistKit/pull/305)) ✅
- [x] Move `CloudKitResponseType` defaults to protocol extension ([#292](https://github.com/brightdigit/MistKit/pull/292)) ✅

**Concurrency**
- [x] Replace custom `AsyncChannel` with `swift-async-algorithms` ([#280](https://github.com/brightdigit/MistKit/pull/280)) ✅

**MistDemo**
- [x] `--database` flag and `demo-errors` command ([#282](https://github.com/brightdigit/MistKit/pull/282)) ✅
- [x] Test split, CRUD commands, auth fix, native app ([#271](https://github.com/brightdigit/MistKit/pull/271) / [#273](https://github.com/brightdigit/MistKit/pull/273)) ✅
- [x] `IntegrationTestRunner` refactored into protocol-based phase pipeline ([#283](https://github.com/brightdigit/MistKit/pull/283)) ✅

**Tooling & CI**
- [x] Test suite improvements ([#286](https://github.com/brightdigit/MistKit/pull/286) / [#287](https://github.com/brightdigit/MistKit/pull/287)) ✅
- [x] CI updates for May 2026 ([#277](https://github.com/brightdigit/MistKit/pull/277)) ✅
- [x] Fail lint job when any command fails ([#303](https://github.com/brightdigit/MistKit/pull/303)) ✅

### v1.0.0-alpha.X

- [ ] [Discovering All User Identities (GET users/discover)](https://github.com/brightdigit/MistKit/issues/28)
- [ ] [Referencing Existing Assets (assets/rereference)](https://github.com/brightdigit/MistKit/issues/31)
- [ ] [Fetching Contacts (users/lookup/contacts)](https://github.com/brightdigit/MistKit/issues/33)
- [ ] [Fetching Users by Email (users/lookup/email)](https://github.com/brightdigit/MistKit/issues/34)
- [ ] [Fetching Users by Record Name (users/lookup/id)](https://github.com/brightdigit/MistKit/issues/35)
- [ ] [Fetching Record Information (records/resolve)](https://github.com/brightdigit/MistKit/issues/41)
- [ ] [Accepting Share Records (records/accept)](https://github.com/brightdigit/MistKit/issues/42)
- [ ] [Fetching Database Changes (changes/database)](https://github.com/brightdigit/MistKit/issues/46)
- [ ] [Modifying Zones (zones/modify)](https://github.com/brightdigit/MistKit/issues/45)
- [ ] [Fetching Record Zone Changes (changes/zone)](https://github.com/brightdigit/MistKit/issues/47)
- [ ] [Fetching Subscriptions (subscriptions/list)](https://github.com/brightdigit/MistKit/issues/49)
- [ ] [Fetching Subscriptions by Identifier (subscriptions/lookup)](https://github.com/brightdigit/MistKit/issues/50)
- [ ] [Modifying Subscriptions (subscriptions/modify)](https://github.com/brightdigit/MistKit/issues/51)
- [ ] [Creating APNs Tokens (tokens/create)](https://github.com/brightdigit/MistKit/issues/52)
- [ ] [Registering Tokens (tokens/register)](https://github.com/brightdigit/MistKit/issues/53)
- [ ] [Feature: Add custom CloudKit zone support for queries](https://github.com/brightdigit/MistKit/issues/146)

### v1.0.0

- [ ] [System Field Integration](https://github.com/brightdigit/MistKit/issues/116)
- [ ] [Handle Data Size Limits](https://github.com/brightdigit/MistKit/issues/38)
- [ ] [Add architecture diagrams to Bushel documentation](https://github.com/brightdigit/MistKit/issues/140)
- [ ] [Add comprehensive test suite for Bushel demo](https://github.com/brightdigit/MistKit/issues/136)
- [ ] [Implement incremental sync with change tracking for Bushel](https://github.com/brightdigit/MistKit/issues/137)
- [ ] [Migrate Bushel Demo to it's own Repository](https://github.com/brightdigit/MistKit/issues/183)
- [ ] [Migrate Celestra Demo to it's own Repository](https://github.com/brightdigit/MistKit/issues/184)

### v1.1.0

- [ ] [Add CloudKit Schema Management APIs (cktool/cktooljs functionality)](https://github.com/brightdigit/MistKit/issues/135)
- [ ] [Add KeyPath-based QueryFilter API for Type-Safe Filtering](https://github.com/brightdigit/MistKit/issues/149)

## Support

- **Issues**: [GitHub Issues](https://github.com/brightdigit/MistKit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/brightdigit/MistKit/discussions)
- **Documentation**: [API Reference](https://brightdigit.github.io/MistKit)

---

*MistKit: Bringing CloudKit to every Swift platform* 🌟
