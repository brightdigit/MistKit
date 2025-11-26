# ``MistKit``

A Swift Package for Server-Side and Command-Line Access to CloudKit Web Services

![MistKit Logo](logo)

## Overview

MistKit provides a modern Swift interface to CloudKit Web Services REST API, enabling cross-platform CloudKit access for server-side Swift applications, command-line tools, and platforms where the CloudKit framework isn't available.

Built with Swift concurrency (async/await) and designed for modern Swift applications, MistKit supports all three CloudKit authentication methods and provides type-safe access to CloudKit operations.

## Key Features

- **Cross-Platform Support**: Works on macOS, iOS, tvOS, watchOS, visionOS, and Linux
- **Modern Swift**: Built with Swift 6 concurrency features and structured error handling
- **Multiple Authentication Methods**: API token, web authentication, and server-to-server authentication
- **Type-Safe**: Comprehensive type safety with Swift's type system
- **OpenAPI-Based**: Generated from CloudKit Web Services OpenAPI specification
- **Secure**: Built-in security best practices and credential management

## Authentication Methods

### API Token Authentication

Provides container-level access using an API token from Apple Developer Console:

```swift
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    apiToken: "your-api-token"
)
```

### Web Authentication

Enables user-specific operations with both API token and web authentication token:

```swift
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    apiToken: "your-api-token",
    webAuthToken: "user-web-auth-token"
)
```

### Server-to-Server Authentication

Enterprise-level authentication using ECDSA P-256 key signing (public database only):

```swift
let serverManager = try ServerToServerAuthManager(
    keyIdentifier: "your-key-id",
    privateKeyData: privateKeyData
)

let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    tokenManager: serverManager,
    environment: .production,
    database: .public
)
```

## Getting Started

### Installation

Add MistKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/MistKit.git", from: "1.0.0")
]
```

### Basic Usage

1. **Choose Authentication**: Select your authentication method based on your needs
2. **Create Service**: Initialize CloudKitService with your authentication details
3. **Perform Operations**: Use the service to interact with CloudKit Web Services

```swift
import MistKit

// Create service with API token authentication
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!
)

// Use the service for CloudKit operations
// (Specific operations depend on your use case)
```

## Error Handling

MistKit provides comprehensive error handling with typed errors:

- ``CloudKitError`` - CloudKit Web Services API errors
- ``TokenManagerError`` - Authentication and credential errors
- ``TokenStorageError`` - Token storage and persistence errors

All errors conform to `LocalizedError` for user-friendly error messages.

## Security Best Practices

- **Environment Variables**: Store sensitive credentials in environment variables
- **Token Rotation**: Implement proper token rotation for server-to-server authentication
- **Secure Storage**: Use secure storage mechanisms for persistent credentials
- **Logging**: Sensitive information is automatically masked in logs

## Platform Support

### Minimum Platform Versions

- macOS 10.15+
- iOS 13.0+
- tvOS 13.0+
- watchOS 6.0+
- visionOS 1.0+
- Linux (Ubuntu 18.04+)

### Server-to-Server Authentication

Server-to-server authentication requires Crypto framework support:
- macOS 11.0+
- iOS 14.0+
- tvOS 14.0+
- watchOS 7.0+
- Linux with swift-crypto

## Topics

### Architecture and Development

- <doc:OpenAPICodeGeneration>
- <doc:GeneratedCodeAnalysis>
- <doc:GeneratedCodeWorkflow>
- <doc:AbstractionLayerArchitecture>

### Services

- ``CloudKitService``
- ``RequestSignature``

### Authentication

- ``TokenManager``
- ``APITokenManager``
- ``WebAuthTokenManager``
- ``AdaptiveTokenManager``
- ``ServerToServerAuthManager``
- ``TokenCredentials``
- ``AuthenticationMethod``
- ``AuthenticationMode``

### Storage

- ``TokenStorage``
- ``InMemoryTokenStorage``
- ``TokenStorageError``

### Configuration

- ``Environment``
- ``Database``
- ``EnvironmentConfig``

### Errors

- ``CloudKitError``
- ``TokenManagerError``
- ``InvalidCredentialReason``
- ``InternalErrorReason``

### Core Types

- ``FieldValue``
- ``RecordInfo``
- ``UserInfo``
- ``ZoneInfo``


## See Also

- [CloudKit Web Services Documentation](https://developer.apple.com/documentation/cloudkitwebservices)
- [Apple Developer Console](https://developer.apple.com)
- [Swift Package Manager](https://swift.org/package-manager/)
