# MistKit

[![Swift 6.1](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-lightgrey.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Swift Package for Server-Side and Command-Line Access to CloudKit Web Services

## Overview

MistKit provides a modern Swift interface to CloudKit Web Services REST API, enabling cross-platform CloudKit access for server-side Swift applications, command-line tools, and platforms where the CloudKit framework isn't available.

Built with Swift concurrency (async/await) and designed for modern Swift applications, MistKit supports all three CloudKit authentication methods and provides type-safe access to CloudKit operations.

## Key Features

- **🌍 Cross-Platform Support**: Works on macOS, iOS, tvOS, watchOS, visionOS, and Linux
- **⚡ Modern Swift**: Built with Swift 6 concurrency features and structured error handling
- **🔐 Multiple Authentication Methods**: API token, web authentication, and server-to-server authentication
- **🛡️ Type-Safe**: Comprehensive type safety with Swift's type system
- **📋 OpenAPI-Based**: Generated from CloudKit Web Services OpenAPI specification
- **🔒 Secure**: Built-in security best practices and credential management

## Installation

### Swift Package Manager

Add MistKit to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/brightdigit/MistKit.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/brightdigit/MistKit.git`
3. Select version and add to your target

## Quick Start

### 1. Choose Your Authentication Method

MistKit supports three authentication methods depending on your use case:

#### API Token (Container-level access)
```swift
import MistKit

let config = MistKitConfiguration.apiToken(
    container: "iCloud.com.example.MyApp",
    environment: .development,
    database: .public,
    apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!
)
```

#### Web Authentication (User-specific access)
```swift
let config = MistKitConfiguration.webAuth(
    container: "iCloud.com.example.MyApp",
    environment: .development,
    database: .private,
    apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!,
    webAuthToken: userWebAuthToken
)
```

#### Server-to-Server (Enterprise access, public database only)
```swift
let config = MistKitConfiguration.serverToServer(
    container: "iCloud.com.example.MyApp",
    environment: .production,
    keyID: ProcessInfo.processInfo.environment["CLOUDKIT_KEY_ID"]!,
    privateKeyData: privateKeyData
)
```

### 2. Create and Use Client

```swift
do {
    let client = try MistKitClient(configuration: config)
    // Use client for CloudKit operations
} catch {
    print("Failed to create client: \\(error)")
}
```

## Authentication Setup

### API Token Authentication

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
   let config = MistKitConfiguration.apiToken(
       container: "iCloud.com.example.MyApp",
       environment: .development,
       database: .public,
       apiToken: ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!
   )
   ```

### Web Authentication

Web authentication enables user-specific operations and requires both an API token and a web authentication token obtained through CloudKit JS authentication.

```swift
let config = MistKitConfiguration.webAuth(
    container: "iCloud.com.example.MyApp",
    environment: .development,
    database: .private,
    apiToken: apiToken,
    webAuthToken: webAuthToken
)
```

### Server-to-Server Authentication

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

   let config = MistKitConfiguration.serverToServer(
       container: "iCloud.com.example.MyApp",
       environment: .production,
       keyID: "your_key_id",
       privateKeyData: privateKeyData
   )
   ```

## Platform Support

### Minimum Platform Versions

| Platform | Minimum Version | Server-to-Server Auth |
|----------|-----------------|----------------------|
| macOS | 10.15+ | 11.0+ |
| iOS | 13.0+ | 14.0+ |
| tvOS | 13.0+ | 14.0+ |
| watchOS | 6.0+ | 7.0+ |
| visionOS | 1.0+ | 1.0+ |
| Linux | Ubuntu 18.04+ | ✅ |

## Error Handling

MistKit provides comprehensive error handling with typed errors:

```swift
do {
    let client = try MistKitClient(configuration: config)
    // Perform operations
} catch let error as CloudKitError {
    print("CloudKit error: \\(error.localizedDescription)")
} catch let error as TokenManagerError {
    print("Authentication error: \\(error.localizedDescription)")
} catch {
    print("Unexpected error: \\(error)")
}
```

### Error Types

- **`CloudKitError`**: CloudKit Web Services API errors
- **`TokenManagerError`**: Authentication and credential errors
- **`TokenStorageError`**: Token storage and persistence errors

## Security Best Practices

### Environment Variables

Always store sensitive credentials in environment variables:

```bash
# .env file (never commit this!)
CLOUDKIT_API_TOKEN=your_api_token_here
CLOUDKIT_KEY_ID=your_key_id_here
```

### Secure Logging

MistKit automatically masks sensitive information in logs:

```swift
// Sensitive data is automatically redacted in log output
print("Token: \\(secureToken)") // Outputs: Token: abc12345***
```

### Token Storage

For persistent applications, use secure token storage:

```swift
let storage = InMemoryTokenStorage() // For development
// Use KeychainTokenStorage() for production (implement as needed)

let config = MistKitConfiguration.webAuth(
    container: "iCloud.com.example.MyApp",
    environment: .development,
    database: .private,
    apiToken: apiToken,
    webAuthToken: webAuthToken,
    storage: storage
)
```

## Advanced Usage

### Custom Transport

You can provide custom transport for testing or special networking requirements:

```swift
let customTransport = YourCustomTransport()
let client = try MistKitClient(
    configuration: config,
    transport: customTransport
)
```

### Adaptive Token Manager

For applications that might upgrade from API-only to web authentication:

```swift
let adaptiveManager = AdaptiveTokenManager(
    apiToken: apiToken,
    storage: storage
)

// Later, upgrade to web authentication
try await adaptiveManager.upgradeToWebAuth(webAuthToken: webToken)
```

## Examples

Check out the `Examples/` directory for complete working examples:

- **Command Line Tool**: Basic CloudKit operations from the command line
- **Server Application**: Using MistKit in a server-side Swift application
- **Cross-Platform App**: Shared CloudKit logic across multiple platforms

## Documentation

- **[API Documentation](https://brightdigit.github.io/MistKit)**: Complete API reference
- **[DocC Documentation](./Sources/MistKit/Documentation.docc)**: Interactive documentation
- **[CloudKit Web Services](https://developer.apple.com/documentation/cloudkitwebservices)**: Apple's official CloudKit Web Services documentation

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/brightdigit/MistKit.git
   cd MistKit
   ```

2. **Install dependencies**:
   ```bash
   swift package resolve
   ```

3. **Run tests**:
   ```bash
   swift test
   ```

4. **Generate documentation**:
   ```bash
   swift package generate-documentation
   ```

### Code Style

We use SwiftLint to maintain code quality. Install it and run:

```bash
swiftlint --fix
```

## Requirements

- Swift 6.1+
- Xcode 16.0+ (for iOS/macOS development)
- Linux: Ubuntu 18.04+ with Swift 6.1+

## License

MistKit is released under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- Built on [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator)
- Uses [Swift Crypto](https://github.com/apple/swift-crypto) for server-to-server authentication
- Inspired by CloudKit Web Services REST API

## Support

- **Issues**: [GitHub Issues](https://github.com/brightdigit/MistKit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/brightdigit/MistKit/discussions)
- **Documentation**: [API Reference](https://brightdigit.github.io/MistKit)

---

*MistKit: Bringing CloudKit to every Swift platform* 🌟