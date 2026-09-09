<!--
Downloaded via https://llm.codes by @steipete on December 23, 2025 at 05:09 PM
Source URL: https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration
Total pages processed: 200
URLs filtered: Yes
Content de-duplicated: Yes
Availability strings filtered: Yes
Code blocks only: No
-->

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration

Library

# Configuration

A Swift library for reading configuration in applications and libraries.

## Overview

Swift Configuration defines an abstraction between configuration _readers_ and _providers_.

Applications and libraries _read_ configuration through a consistent API, while the actual _provider_ is set up once at the application’s entry point.

For example, to read the timeout configuration value for an HTTP client, check out the following examples using different providers:

# Environment variables:
HTTP_TIMEOUT=30
let provider = EnvironmentVariablesProvider()
let config = ConfigReader(provider: provider)
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
print(httpTimeout) // prints 30
# Program invoked with:
program --http-timeout 30
let provider = CommandLineArgumentsProvider()
let config = ConfigReader(provider: provider)
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
print(httpTimeout) // prints 30
{
"http": {
"timeout": 30
}
}

filePath: "/etc/config.json"
)
let config = ConfigReader(provider: provider)
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
print(httpTimeout) // prints 30
{
"http": {
"timeout": 30
}
}

filePath: "/etc/config.json"
)
// Omitted: Add `provider` to a ServiceGroup
let config = ConfigReader(provider: provider)
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
print(httpTimeout) // prints 30
http:
timeout: 30

filePath: "/etc/config.yaml"
)
let config = ConfigReader(provider: provider)
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
print(httpTimeout) // prints 30
http:
timeout: 30

filePath: "/etc/config.yaml"
)
// Omitted: Add `provider` to a ServiceGroup
let config = ConfigReader(provider: provider)
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
print(httpTimeout) // prints 30
/
|-- run
|-- secrets
|-- http-timeout

Contents of the file `/run/secrets/http-timeout`: `30`.

let provider = try await DirectoryFilesProvider(
directoryPath: "/run/secrets"
)
let config = ConfigReader(provider: provider)
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
print(httpTimeout) // prints 30
// Environment variables consulted first, then JSON.
let primaryProvider = EnvironmentVariablesProvider()

filePath: "/etc/config.json"
)
let config = ConfigReader(providers: [\
primaryProvider,\
secondaryProvider\
])
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
print(httpTimeout) // prints 30
let provider = InMemoryProvider(values: [\
"http.timeout": 30,\
])
let config = ConfigReader(provider: provider)
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
print(httpTimeout) // prints 30

For a selection of more detailed examples, read through Example use cases.

For a video introduction, check out our talk on YouTube.

These providers can be combined to form a hierarchy, for details check out Provider hierarchy.

### Quick start

Add the dependency to your `Package.swift`:

.package(url: "https://github.com/apple/swift-configuration", from: "1.0.0")

Add the library dependency to your target:

.product(name: "Configuration", package: "swift-configuration")

Import and use in your code:

import Configuration

let config = ConfigReader(provider: EnvironmentVariablesProvider())
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
print("The HTTP timeout is: \(httpTimeout)")

### Package traits

This package offers additional integrations you can enable using package traits. To enable an additional trait on the package, update the package dependency:

.package(
url: "https://github.com/apple/swift-configuration",
from: "1.0.0",
+ traits: [.defaults, "YAML"]
)

Available traits:

- **`JSON`** (default): Adds support for `JSONSnapshot`, which enables using `FileProvider` and `ReloadingFileProvider` with JSON files.

- **`Logging`** (opt-in): Adds support for `AccessLogger`, a way to emit access events into a Swift Log `Logger`.

- **`Reloading`** (opt-in): Adds support for `ReloadingFileProvider`, which provides auto-reloading capability for file-based configuration.

- **`CommandLineArguments`** (opt-in): Adds support for `CommandLineArgumentsProvider` for parsing command line arguments.

- **`YAML`** (opt-in): Adds support for `YAMLSnapshot`, which enables using `FileProvider` and `ReloadingFileProvider` with YAML files.

### Supported platforms and minimum versions

The library is supported on Apple platforms and Linux.

| Component | macOS | Linux | iOS | tvOS | watchOS | visionOS |
| --- | --- | --- | --- | --- | --- | --- |
| Configuration | ✅ 15+ | ✅ | ✅ 18+ | ✅ 18+ | ✅ 11+ | ✅ 2+ |

#### Three access patterns

The library provides three distinct ways to read configuration values:

- **Get**: Synchronously return the current value available locally, in memory:

let timeout = config.int(forKey: "http.timeout", default: 60)

- **Fetch**: Asynchronously get the most up-to-date value from disk or a remote server:

let timeout = try await config.fetchInt(forKey: "http.timeout", default: 60)

- **Watch**: Receive updates when a configuration value changes:

try await config.watchInt(forKey: "http.timeout", default: 60) { updates in
for try await timeout in updates {
print("HTTP timeout updated to: \(timeout)")
}
}

For detailed guidance on when to use each access pattern, see Choosing the access pattern. Within each of the access patterns, the library offers different reader methods that reflect your needs of optional, default, and required configuration parameters. To understand the choices available, see Choosing reader methods.

#### Providers

The library includes comprehensive built-in provider support:

- Environment variables: `EnvironmentVariablesProvider`

- Command-line arguments: `CommandLineArgumentsProvider`

- JSON file: `FileProvider` and `ReloadingFileProvider` with `JSONSnapshot`

- YAML file: `FileProvider` and `ReloadingFileProvider` with `YAMLSnapshot`

- Directory of files: `DirectoryFilesProvider`

- In-memory: `InMemoryProvider` and `MutableInMemoryProvider`

- Key transforming: `KeyMappingProvider`

You can also implement a custom `ConfigProvider`.

#### Provider hierarchy

In addition to using providers individually, you can create fallback behavior using an array of providers. The first provider that returns a non-nil value wins.

The following example shows a provider hierarchy where environment variables take precedence over command line arguments, a JSON file, and in-memory defaults:

// Create a hierarchy of providers with fallback behavior.
let config = ConfigReader(providers: [\
// First, check environment variables.\
EnvironmentVariablesProvider(),\
// Then, check command-line options.\
CommandLineArgumentsProvider(),\
// Then, check a JSON config file.\

// Finally, fall \
])

// Uses the first provider that has a value for "http.timeout".
let timeout = config.int(forKey: "http.timeout", default: 15)

#### Hot reloading

Long-running services can periodically reload configuration with `ReloadingFileProvider`:

// Omitted: add provider to a ServiceGroup
let config = ConfigReader(provider: provider)

Read Using reloading providers for details on how to receive updates as configuration changes.

#### Namespacing and scoped readers

The built-in namespacing of `ConfigKey` interprets `"http.timeout"` as an array of two components: `"http"` and `"timeout"`. The following example uses `scoped(to:)` to create a namespaced reader with the key `"http"`, to allow reads to use the shorter key `"timeout"`:

Consider the following JSON configuration:

{
"http": {
"timeout": 60
}
}
// Create the root reader.
let config = ConfigReader(provider: provider)

// Create a scoped reader for HTTP settings.
let httpConfig = config.scoped(to: "http")

// Now you can access values with shorter keys.
// Equivalent to reading "http.timeout" on the root reader.
let timeout = httpConfig.int(forKey: "timeout")

#### Debugging and troubleshooting

Debugging with `AccessReporter` makes it possible to log all accesses to a config reader:

let logger = Logger(label: "config")
let config = ConfigReader(
provider: provider,
accessReporter: AccessLogger(logger: logger)
)
// Now all configuration access is logged, with secret values redacted

You can also add the following environment variable, and emit log accesses into a file without any code changes:

CONFIG_ACCESS_LOG_FILE=/var/log/myapp/config-access.log

and then read the file:

tail -f /var/log/myapp/config-access.log

Check out the built-in `AccessLogger`, `FileAccessLogger`, and Troubleshooting and access reporting.

#### Secrets handling

The library provides built-in support for handling sensitive configuration values securely:

// Mark sensitive values as secrets to prevent them from appearing in logs
let privateKey = try snapshot.requiredString(forKey: "mtls.privateKey", isSecret: true)
let optionalAPIToken = config.string(forKey: "api.token", isSecret: true)

When values are marked as secrets, they are automatically redacted from access logs and debugging output. Read Handling secrets correctly for guidance on best practices for secrets management.

#### Consistent snapshots

Retrieve related values from a consistent snapshot using `ConfigSnapshotReader`, which you get by calling `snapshot()`.

This ensures that multiple values are read from a single snapshot inside each provider, even when using providers that update their internal values. For example by downloading new data periodically:

let config = /* a reader with one or more providers that change values over time */
let snapshot = config.snapshot()
let certificate = try snapshot.requiredString(forKey: "mtls.certificate")
let privateKey = try snapshot.requiredString(forKey: "mtls.privateKey", isSecret: true)
// `certificate` and `privateKey` are guaranteed to come from the same snapshot in the provider

#### Extensible ecosystem

Any package can implement a `ConfigProvider`, making the ecosystem extensible for custom configuration sources.

## Topics

### Essentials

Configuring applications

Provide flexible and consistent configuration for your application.

Configuring libraries

Provide a consistent and flexible way to configure your library.

Example use cases

Review common use cases with ready-to-copy code samples.

Adopting best practices

Follow these principles to make your code easily configurable and composable with other libraries.

### Readers and providers

`struct ConfigReader`

A type that provides read-only access to configuration values from underlying providers.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`struct ConfigSnapshotReader`

A container type for reading config values from snapshots.

Choosing the access pattern

Learn how to select the right method for reading configuration values based on your needs.

Choosing reader methods

Choose between optional, default, and required variants of configuration methods.

Handling secrets correctly

Protect sensitive configuration values from accidental disclosure in logs and debug output.

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

Using reloading providers

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

### Creating a custom provider

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

`protocol FileParsingOptions`

A type that provides parsing options for file configuration snapshots.

`enum ConfigContent`

The raw content of a configuration value.

`struct ConfigValue`

A configuration value that wraps content with metadata.

`enum ConfigType`

The supported configuration value types.

`struct LookupResult`

The result of looking up a configuration value in a provider.

`enum SecretsSpecifier`

A specification for identifying which configuration values contain sensitive information.

`struct ConfigUpdatesAsyncSequence`

A concrete async sequence for delivering updated configuration values.

### Configuration keys

`struct ConfigKey`

A configuration key representing a relative path to a configuration value.

`struct AbsoluteConfigKey`

A configuration key that represents an absolute path to a configuration value.

`enum ConfigContextValue`

A value that can be stored in a configuration context.

### Troubleshooting and access reporting

Troubleshooting and access reporting

Check out some techniques to debug unexpected issues and to increase visibility into accessed config values.

`protocol AccessReporter`

A type that receives and processes configuration access events.

`class AccessLogger`

An access reporter that logs configuration access events using the Swift Log API.

`class FileAccessLogger`

An access reporter that writes configuration access events to a file.

`struct AccessEvent`

An event that captures information about accessing a configuration value.

`struct BroadcastingAccessReporter`

An access reporter that forwards events to multiple other reporters.

### Value conversion

`protocol ExpressibleByConfigString`

A protocol for types that can be initialized from configuration string values.

`protocol ConfigBytesFromStringDecoder`

A protocol for decoding string configuration values into byte arrays.

`struct ConfigBytesFromBase64StringDecoder`

A decoder that converts base64-encoded strings into byte arrays.

`struct ConfigBytesFromHexStringDecoder`

A decoder that converts hexadecimal-encoded strings into byte arrays.

### Contributing

Developing Swift Configuration

Learn about tools and conventions used to develop the Swift Configuration package.

Collaborate on API changes to Swift Configuration by writing a proposal.

### Extended Modules

Foundation

SystemPackage

- Configuration
- Overview
- Quick start
- Package traits
- Supported platforms and minimum versions
- Key features
- Topics

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/handling-secrets-correctly

- Configuration
- Handling secrets correctly

Article

# Handling secrets correctly

Protect sensitive configuration values from accidental disclosure in logs and debug output.

## Overview

Swift Configuration provides built-in support for marking sensitive values as secrets. Secret values are automatically redacted by access reporters to prevent accidental disclosure of API keys, passwords, and other sensitive information.

### Marking values as secret when reading

Use the `isSecret` parameter on any configuration reader method to mark a value as secret:

let config = ConfigReader(provider: provider)

// Mark sensitive values as secret
let apiKey = try config.requiredString(
forKey: "api.key",
isSecret: true
)
let dbPassword = config.string(
forKey: "database.password",
isSecret: true
)

// Regular values don't need the parameter
let serverPort = try config.requiredInt(forKey: "server.port")
let logLevel = config.string(
forKey: "log.level",
default: "info"
)

This works with all access patterns and method variants:

// Works with fetch and watch too
let latestKey = try await config.fetchRequiredString(
forKey: "api.key",
isSecret: true
)

try await config.watchString(
forKey: "api.key",
isSecret: true
) { updates in
for await key in updates {
// Handle secret key updates
}
}

### Provider-level secret specification

Use `SecretsSpecifier` to automatically mark values as secret based on keys or content when creating providers:

#### Mark all values as secret

The following example marks all configuration read by the `DirectoryFilesProvider` as secret:

let provider = DirectoryFilesProvider(
directoryPath: "/run/secrets",
secretsSpecifier: .all
)

#### Mark specific keys as secret

The following example marks three specific keys from a provider as secret:

let provider = EnvironmentVariablesProvider(
secretsSpecifier: .specific(["API_KEY", "DATABASE_PASSWORD", "JWT_SECRET"])
)

#### Dynamic secret detection

The following example marks keys as secret based on the closure you provide. In this case, keys that contain `password`, `secret`, or `token` are all marked as secret:

filePath: "/etc/config.json",
secretsSpecifier: .dynamic { key, value in
key.lowercased().contains("password") ||
key.lowercased().contains("secret") ||
key.lowercased().contains("token")
}
)

#### No secret values

The following example asserts that none of the values returned from the provider are considered secret:

filePath: "/etc/config.json",
secretsSpecifier: .none
)

### For provider implementors

When implementing a custom `ConfigProvider`, use the `ConfigValue` type’s `isSecret` property:

// Create a secret value
let secretValue = ConfigValue("sensitive-data", isSecret: true)

// Create a regular value
let regularValue = ConfigValue("public-data", isSecret: false)

Set the `isSecret` property to `true` when your provider knows the values are read from a secrets store and must not be logged.

### How secret values are protected

Secret values are automatically handled by:

- **`AccessLogger`** and **`FileAccessLogger`**: Redact secret values in logs.

print(provider)

### Best practices

1. **Mark all sensitive data as secret**: API keys, passwords, tokens, private keys, connection strings.

2. **Use provider-level specification** when you know which keys are always secret.

3. **Use reader-level marking** for context-specific secrets or when the same key might be secret in some contexts but not others.

4. **Be conservative**: When in doubt, mark values as secret. It’s safer than accidentally leaking sensitive data.

For additional guidance on configuration security and overall best practices, see Adopting best practices. To debug issues with secret redaction in access logs, check out Troubleshooting and access reporting. When selecting between required, optional, and default method variants for secret values, refer to Choosing reader methods.

## See Also

### Readers and providers

`struct ConfigReader`

A type that provides read-only access to configuration values from underlying providers.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`struct ConfigSnapshotReader`

A container type for reading config values from snapshots.

Choosing the access pattern

Learn how to select the right method for reading configuration values based on your needs.

Choosing reader methods

Choose between optional, default, and required variants of configuration methods.

- Handling secrets correctly
- Overview
- Marking values as secret when reading
- Provider-level secret specification
- For provider implementors
- How secret values are protected
- Best practices
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/yamlsnapshot

- Configuration
- YAMLSnapshot

Class

# YAMLSnapshot

A snapshot of configuration values parsed from YAML data.

final class YAMLSnapshot

YAMLSnapshot.swift

## Mentioned in

Using reloading providers

## Overview

This class represents a point-in-time view of configuration values. It handles the conversion from YAML types to configuration value types.

## Usage

Use with `FileProvider` or `ReloadingFileProvider`:

let config = ConfigReader(provider: provider)

## Topics

### Creating a YAML snapshot

`convenience init(data: RawSpan, providerName: String, parsingOptions: YAMLSnapshot.ParsingOptions) throws`

`struct ParsingOptions`

Custom input configuration for YAML snapshot creation.

### Snapshot configuration

`protocol FileConfigSnapshot`

A protocol for configuration snapshots created from file data.

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

### Instance Properties

`let providerName: String`

The name of the provider that created this snapshot.

## Relationships

### Conforms To

- `ConfigSnapshot`
- `FileConfigSnapshot`
- `Swift.Copyable`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- YAMLSnapshot
- Mentioned in
- Overview
- Usage
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configurationtesting

Library

# ConfigurationTesting

A set of testing utilities for Swift Configuration adopters.

## Overview

This testing library adds a Swift Testing-based `ConfigProvider` compatibility suite, recommended for implementors of custom configuration providers.

## Topics

### Structures

`struct ProviderCompatTest`

A comprehensive test suite for validating `ConfigProvider` implementations.

- ConfigurationTesting
- Overview
- Topics

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accesslogger

- Configuration
- AccessLogger

Class

# AccessLogger

An access reporter that logs configuration access events using the Swift Log API.

final class AccessLogger

AccessLogger.swift

## Mentioned in

Handling secrets correctly

Troubleshooting and access reporting

Configuring libraries

## Overview

This reporter integrates with the Swift Log library to provide structured logging of configuration accesses. Each configuration access generates a log entry with detailed metadata about the operation, making it easy to track configuration usage and debug issues.

## Package traits

This type is guarded by the `Logging` package trait.

## Usage

Create an access logger and pass it to your configuration reader:

import Logging

let logger = Logger(label: "config.access")
let accessLogger = AccessLogger(logger: logger, level: .info)
let config = ConfigReader(
provider: EnvironmentVariablesProvider(),
accessReporter: accessLogger
)

## Log format

Each access event generates a structured log entry with metadata including:

- `kind`: The type of access operation (get, fetch, watch).

- `key`: The configuration key that was accessed.

- `location`: The source code location where the access occurred.

- `value`: The resolved configuration value (redacted for secrets).

- `counter`: An incrementing counter for tracking access frequency.

- Provider-specific information for each provider in the hierarchy.

## Topics

### Creating an access logger

`init(logger: Logger, level: Logger.Level, message: Logger.Message)`

Creates a new access logger that reports configuration access events.

## Relationships

### Conforms To

- `AccessReporter`
- `Swift.Copyable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Troubleshooting and access reporting

Check out some techniques to debug unexpected issues and to increase visibility into accessed config values.

`protocol AccessReporter`

A type that receives and processes configuration access events.

`class FileAccessLogger`

An access reporter that writes configuration access events to a file.

`struct AccessEvent`

An event that captures information about accessing a configuration value.

`struct BroadcastingAccessReporter`

An access reporter that forwards events to multiple other reporters.

- AccessLogger
- Mentioned in
- Overview
- Package traits
- Usage
- Log format
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/reloadingfileprovider

- Configuration
- ReloadingFileProvider

Class

# ReloadingFileProvider

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

ReloadingFileProvider.swift

## Mentioned in

Using reloading providers

Choosing the access pattern

Troubleshooting and access reporting

## Overview

`ReloadingFileProvider` is a generic file-based configuration provider that monitors a configuration file for changes and automatically reloads the data when the file is modified. This provider works with different file formats by using different snapshot types that conform to `FileConfigSnapshot`.

## Usage

Create a reloading provider by specifying the snapshot type and file path:

// Using with a JSON snapshot and a custom poll interval

filePath: "/etc/config.json",
pollInterval: .seconds(30)
)

// Using with a YAML snapshot

filePath: "/etc/config.yaml"
)

## Service integration

This provider implements the `Service` protocol and must be run within a `ServiceGroup` to enable automatic reloading:

let serviceGroup = ServiceGroup(services: [provider], logger: logger)
try await serviceGroup.run()

The provider monitors the file by polling at the specified interval (default: 15 seconds) and notifies any active watchers when changes are detected.

## Configuration from a reader

You can also initialize the provider using a configuration reader:

let envConfig = ConfigReader(provider: EnvironmentVariablesProvider())

This expects a `filePath` key in the configuration that specifies the path to the file. For a full list of configuration keys, check out `init(snapshotType:parsingOptions:config:)`.

## File monitoring

The provider detects changes by monitoring both file timestamps and symlink target changes. When a change is detected, it reloads the file and notifies all active watchers of the updated configuration values.

## Topics

### Creating a reloading file provider

`convenience init(snapshotType: Snapshot.Type, parsingOptions: Snapshot.ParsingOptions, filePath: FilePath, allowMissing: Bool, pollInterval: Duration, logger: Logger, metrics: any MetricsFactory) async throws`

Creates a reloading file provider that monitors the specified file path.

`convenience init(snapshotType: Snapshot.Type, parsingOptions: Snapshot.ParsingOptions, config: ConfigReader, logger: Logger, metrics: any MetricsFactory) async throws`

Creates a reloading file provider using configuration from a reader.

### Service lifecycle

`func run() async throws`

### Monitoring file changes

`protocol FileConfigSnapshot`

A protocol for configuration snapshots created from file data.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

### Instance Properties

`let providerName: String`

The human-readable name of the provider.

## Relationships

### Conforms To

- `ConfigProvider`
Conforms when `Snapshot` conforms to `FileConfigSnapshot`.

- `ServiceLifecycle.Service`
- `Swift.Copyable`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- ReloadingFileProvider
- Mentioned in
- Overview
- Usage
- Service integration
- Configuration from a reader
- File monitoring
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/jsonsnapshot

- Configuration
- JSONSnapshot

Structure

# JSONSnapshot

A snapshot of configuration values parsed from JSON data.

struct JSONSnapshot

JSONSnapshot.swift

## Mentioned in

Example use cases

Using reloading providers

## Overview

This structure represents a point-in-time view of configuration values. It handles the conversion from JSON types to configuration value types.

## Usage

Use with `FileProvider` or `ReloadingFileProvider`:

let config = ConfigReader(provider: provider)

## Topics

### Creating a JSON snapshot

`init(data: RawSpan, providerName: String, parsingOptions: JSONSnapshot.ParsingOptions) throws`

`struct ParsingOptions`

Parsing options for JSON snapshot creation.

### Snapshot configuration

`protocol FileConfigSnapshot`

A protocol for configuration snapshots created from file data.

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

### Instance Properties

`let providerName: String`

The name of the provider that created this snapshot.

## Relationships

### Conforms To

- `ConfigSnapshot`
- `FileConfigSnapshot`
- `Swift.Copyable`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- JSONSnapshot
- Mentioned in
- Overview
- Usage
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/fileprovider

- Configuration
- FileProvider

Structure

# FileProvider

A configuration provider that reads from a file on disk using a configurable snapshot type.

FileProvider.swift

## Mentioned in

Example use cases

Troubleshooting and access reporting

## Overview

`FileProvider` is a generic file-based configuration provider that works with different file formats by using different snapshot types that conform to `FileConfigSnapshot`. This allows for a unified interface for reading JSON, YAML, or other structured configuration files.

## Usage

Create a provider by specifying the snapshot type and file path:

// Using with a JSON snapshot

filePath: "/etc/config.json"
)

// Using with a YAML snapshot

filePath: "/etc/config.yaml"
)

The provider reads the file once during initialization and creates an immutable snapshot of the configuration values. For auto-reloading behavior, use `ReloadingFileProvider`.

## Configuration from a reader

You can also initialize the provider using a configuration reader that specifies the file path through environment variables or other configuration sources:

let envConfig = ConfigReader(provider: EnvironmentVariablesProvider())

This expects a `filePath` key in the configuration that specifies the path to the file. For a full list of configuration keys, check out `init(snapshotType:parsingOptions:config:)`.

## Topics

### Creating a file provider

`init(snapshotType: Snapshot.Type, parsingOptions: Snapshot.ParsingOptions, filePath: FilePath, allowMissing: Bool) async throws`

Creates a file provider that reads from the specified file path.

`init(snapshotType: Snapshot.Type, parsingOptions: Snapshot.ParsingOptions, config: ConfigReader) async throws`

Creates a file provider using a file path from a configuration reader.

### Reading configuration files

`protocol FileConfigSnapshot`

A protocol for configuration snapshots created from file data.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

## Relationships

### Conforms To

- `ConfigProvider`
Conforms when `Snapshot` conforms to `FileConfigSnapshot`.

- `Swift.Copyable`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

Using reloading providers

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- FileProvider
- Mentioned in
- Overview
- Usage
- Configuration from a reader
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/example-use-cases

- Configuration
- Example use cases

Article

# Example use cases

Review common use cases with ready-to-copy code samples.

## Overview

For complete working examples with step-by-step instructions, see the Examples directory in the repository.

### Reading from environment variables

Use `EnvironmentVariablesProvider` to read configuration values from environment variables where your app launches. The following example creates a `ConfigReader` with an environment variable provider, and reads the key `server.port`, providing a default value of `8080`:

import Configuration

let config = ConfigReader(provider: EnvironmentVariablesProvider())
let port = config.int(forKey: "server.port", default: 8080)

The default environment key encoder uses an underscore to separate key components, making the environment variable name above `SERVER_PORT`.

### Reading from a JSON configuration file

You can store multiple configuration values together in a JSON file and read them from the fileystem using `FileProvider` with `JSONSnapshot`. The following example creates a `ConfigReader` for a JSON file at the path `/etc/config.json`, and reads a url and port number collected as properties of the `database` JSON object:

let config = ConfigReader(

)

// Access nested values using dot notation.
let databaseURL = config.string(forKey: "database.url", default: "localhost")
let databasePort = config.int(forKey: "database.port", default: 5432)

The matching JSON for this configuration might look like:

{
"database": {
"url": "localhost",
"port": 5432
}
}

### Reading from a directory of secret files

Use the `DirectoryFilesProvider` to read multiple values collected together in a directory on the fileystem, each in a separate file. The default directory key encoder uses a hyphen in the filename to separate key components. The following example uses the directory `/run/secrets` as a base, and reads the file `database-password` as the key `database.password`:

// Common pattern for secrets downloaded by an init container.
let config = ConfigReader(
provider: try await DirectoryFilesProvider(
directoryPath: "/run/secrets"
)
)

// Reads the file `/run/secrets/database-password`
let dbPassword = config.string(forKey: "database.password")

This pattern is useful for reading secrets that your infrastructure makes available on the file system, such as Kubernetes secrets mounted into a container’s filesystem.

### Handling optional configuration files

File-based providers support an `allowMissing` parameter to control whether missing files should throw an error or be treated as empty configuration. This is useful when configuration files are optional.

When `allowMissing` is `false` (the default), missing files throw an error:

// This will throw an error if config.json doesn't exist
let config = ConfigReader(

filePath: "/etc/config.json",
allowMissing: false // This is the default
)
)

When `allowMissing` is `true`, missing files are treated as empty configuration:

// This won't throw if config.json is missing - treats it as empty
let config = ConfigReader(

filePath: "/etc/config.json",
allowMissing: true
)
)

// Returns the default value if the file is missing
let port = config.int(forKey: "server.port", default: 8080)

The same applies to other file-based providers:

// Optional secrets directory
let secretsConfig = ConfigReader(
provider: try await DirectoryFilesProvider(
directoryPath: "/run/secrets",
allowMissing: true
)
)

// Optional environment file
let envConfig = ConfigReader(
provider: try await EnvironmentVariablesProvider(
environmentFilePath: "/etc/app.env",
allowMissing: true
)
)

// Optional reloading configuration
let reloadingConfig = ConfigReader(

filePath: "/etc/dynamic-config.yaml",
allowMissing: true
)
)

### Setting up a fallback hierarchy

Use multiple providers together to provide a configuration hierarchy that can override values at different levels. The following example uses both an environment variable provider and a JSON provider together, with values from environment variables overriding values from the JSON file. In this example, the defaults are provided using an `InMemoryProvider`, which are only read if the environment variable or the JSON key don’t exist:

let config = ConfigReader(providers: [\
// First check environment variables.\
EnvironmentVariablesProvider(),\
// Then check the config file.\

// Finally, use hardcoded defaults.\
InMemoryProvider(values: [\
"app.name": "MyApp",\
"server.port": 8080,\
"logging.level": "info"\
])\
])

### Fetching a value from a remote source

You can host dynamic configuration that your app can retrieve remotely and use either the “fetch” or “watch” access pattern. The following example uses the “fetch” access pattern to asynchronously retrieve a configuration from the remote provider:

let myRemoteProvider = MyRemoteProvider(...)
let config = ConfigReader(provider: myRemoteProvider)

// Makes a network call to retrieve the up-to-date value.
let samplingRatio = try await config.fetchDouble(forKey: "sampling.ratio")

### Watching for configuration changes

You can periodically update configuration values using a reloading provider. The following example reloads a YAML file from the filesystem every 30 seconds, and illustrates using `watchInt(forKey:isSecret:fileID:line:updatesHandler:)` to provide an async sequence of updates that you can apply.

import Configuration
import ServiceLifecycle

// Create a reloading YAML provider

filePath: "/etc/app-config.yaml",
pollInterval: .seconds(30)
)
// Omitted: add `provider` to the ServiceGroup.

let config = ConfigReader(provider: provider)

// Watch for timeout changes and update HTTP client configuration.
// Needs to run in a separate task from the provider.
try await config.watchInt(forKey: "http.requestTimeout", default: 30) { updates in
for await timeout in updates {
print("HTTP request timeout updated: \(timeout)s")
// Update HTTP client timeout configuration in real-time
}
}

For details on reloading providers and ServiceLifecycle integration, see Using reloading providers.

### Prefixing configuration keys

In most cases, the configuration key provided by the reader can be directly used by the provided, for example `http.timeout` used as the environment variable name `HTTP_TIMEOUT`.

Sometimes you might need to transform the incoming keys in some way, before they get delivered to the provider. A common example is prefixing each key with a constant prefix, for example `myapp`, turning the key `http.timeout` to `myapp.http.timeout`.

You can use `KeyMappingProvider` and related extensions on `ConfigProvider` to achieve that.

The following example uses the key mapping provider to adjust an environment variable provider to look for keys with the prefix `myapp`:

// Create a base provider for environment variables
let envProvider = EnvironmentVariablesProvider()

// Wrap it with a key mapping provider to automatically prepend "myapp." to all keys
let prefixedProvider = envProvider.prefixKeys(with: "myapp")

let config = ConfigReader(provider: prefixedProvider)

// This reads from the "MYAPP_DATABASE_URL" environment variable.
let databaseURL = config.string(forKey: "database.url", default: "localhost")

For more configuration guidance, see Adopting best practices. To understand different reader method variants, check out Choosing reader methods.

## See Also

### Essentials

Configuring applications

Provide flexible and consistent configuration for your application.

Configuring libraries

Provide a consistent and flexible way to configure your library.

Adopting best practices

Follow these principles to make your code easily configurable and composable with other libraries.

- Example use cases
- Overview
- Reading from environment variables
- Reading from a JSON configuration file
- Reading from a directory of secret files
- Handling optional configuration files
- Setting up a fallback hierarchy
- Fetching a value from a remote source
- Watching for configuration changes
- Prefixing configuration keys
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader/scoped(to:)

#app-main)

- Configuration
- ConfigReader
- scoped(to:)

Instance Method

# scoped(to:)

Returns a scoped config reader with the specified key appended to the current prefix.

ConfigReader.swift

## Parameters

`configKey`

The key components to append to the current key prefix.

## Return Value

A config reader for accessing values within the specified scope.

## Discussion

let httpConfig = config.scoped(to: ConfigKey(["http", "client"]))
let timeout = httpConfig.int(forKey: "timeout", default: 30) // Reads "http.client.timeout"

- scoped(to:)
- Parameters
- Return Value
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/environmentvariablesprovider

- Configuration
- EnvironmentVariablesProvider

Structure

# EnvironmentVariablesProvider

A configuration provider that sources values from environment variables.

struct EnvironmentVariablesProvider

EnvironmentVariablesProvider.swift

## Mentioned in

Troubleshooting and access reporting

Configuring applications

Example use cases

## Overview

This provider reads configuration values from environment variables, supporting both the current process environment and `.env` files. It automatically converts hierarchical configuration keys into standard environment variable naming conventions and handles type conversion for all supported configuration value types.

## Key transformation

Configuration keys are transformed into environment variable names using these rules:

- Components are joined with underscores

- All characters are converted to uppercase

- CamelCase is detected and word boundaries are marked with underscores

- Non-alphanumeric characters are replaced with underscores

For example: `http.serverTimeout` becomes `HTTP_SERVER_TIMEOUT`

## Supported data types

The provider supports all standard configuration types:

- Strings, integers, doubles, and booleans

- Arrays of strings, integers, doubles, and booleans (comma-separated by default)

- Byte arrays (base64-encoded by default)

- Arrays of byte chunks

## Secret handling

Environment variables can be marked as secrets using a `SecretsSpecifier`. Secret values are automatically redacted in debug output and logging.

## Usage

### Reading environment variables in the current process

// Assuming the environment contains the following variables:
// HTTP_CLIENT_USER_AGENT=Config/1.0 (Test)
// HTTP_CLIENT_TIMEOUT=15.0
// HTTP_SECRET=s3cret
// HTTP_VERSION=2
// ENABLED=true

let provider = EnvironmentVariablesProvider(
secretsSpecifier: .specific(["HTTP_SECRET"])
)
// Prints all values, redacts "HTTP_SECRET" automatically.
print(provider)
let config = ConfigReader(provider: provider)
let isEnabled = config.bool(forKey: "enabled", default: false)
let userAgent = config.string(forKey: "http.client.user-agent", default: "unspecified")
// ...

### Reading environment variables from a \`.env\`-style file

// Assuming the local file system has a file called `.env` in the current working directory
// with the following contents:
//
// HTTP_CLIENT_USER_AGENT=Config/1.0 (Test)
// HTTP_CLIENT_TIMEOUT=15.0
// HTTP_SECRET=s3cret
// HTTP_VERSION=2
// ENABLED=true

let provider = try await EnvironmentVariablesProvider(
environmentFilePath: ".env",
secretsSpecifier: .specific(["HTTP_SECRET"])
)
// Prints all values, redacts "HTTP_SECRET" automatically.
print(provider)
let config = ConfigReader(provider: provider)
let isEnabled = config.bool(forKey: "enabled", default: false)
let userAgent = config.string(forKey: "http.client.user-agent", default: "unspecified")
// ...

### Config context

The environment variables provider ignores the context passed in `context`.

## Topics

### Creating an environment variable provider

Creates a new provider that reads from the current process environment.

Creates a new provider from a custom dictionary of environment variables.

Creates a new provider that reads from an environment file.

### Inspecting an environment variable provider

Returns the raw string value for a specific environment variable name.

## Relationships

### Conforms To

- `ConfigProvider`
- `Swift.Copyable`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Built-in providers

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

Using reloading providers

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- EnvironmentVariablesProvider
- Mentioned in
- Overview
- Key transformation
- Supported data types
- Secret handling
- Usage
- Reading environment variables in the current process
- Reading environment variables from a \`.env\`-style file
- Config context
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey

- Configuration
- ConfigKey

Structure

# ConfigKey

A configuration key representing a relative path to a configuration value.

struct ConfigKey

ConfigKey.swift

## Overview

Configuration keys consist of hierarchical string components forming paths similar to file system paths or JSON object keys. For example, `["http", "timeout"]` represents the `timeout` value nested under `http`.

Keys support additional context information that providers can use to refine lookups or provide specialized behavior.

## Usage

Create keys using string literals, arrays, or the initializers:

let key1: ConfigKey = "database.connection.timeout"
let key2 = ConfigKey(["api", "endpoints", "primary"])
let key3 = ConfigKey("server.port", context: ["environment": .string("production")])

## Topics

### Creating a configuration key

[`init(String, context: [String : ConfigContextValue])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/init(_:context:)-6vten)

Creates a new configuration key.

[`init([String], context: [String : ConfigContextValue])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/init(_:context:)-9ifez)

### Inspecting a configuration key

[`var components: [String]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/components)

The hierarchical components that make up this configuration key.

[`var context: [String : ConfigContextValue]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/context)

Additional context information for this configuration key.

## Relationships

### Conforms To

- `Swift.Comparable`
- `Swift.Copyable`
- `Swift.CustomStringConvertible`
- `Swift.Equatable`
- `Swift.ExpressibleByArrayLiteral`
- `Swift.ExpressibleByExtendedGraphemeClusterLiteral`
- `Swift.ExpressibleByStringLiteral`
- `Swift.ExpressibleByUnicodeScalarLiteral`
- `Swift.Hashable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Configuration keys

`struct AbsoluteConfigKey`

A configuration key that represents an absolute path to a configuration value.

`enum ConfigContextValue`

A value that can be stored in a configuration context.

- ConfigKey
- Overview
- Usage
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/commandlineargumentsprovider

- Configuration
- CommandLineArgumentsProvider

Structure

# CommandLineArgumentsProvider

A configuration provider that sources values from command-line arguments.

struct CommandLineArgumentsProvider

CommandLineArgumentsProvider.swift

## Overview

Reads configuration values from CLI arguments with type conversion and secrets handling. Keys are encoded to CLI flags at lookup time.

## Package traits

This type is guarded by the `CommandLineArgumentsSupport` package trait.

## Key formats

- `--key value` \- A key-value pair with separate arguments.

- `--key=value` \- A key-value pair with an equals sign.

- `--flag` \- A Boolean flag, treated as `true`.

- `--key val1 val2` \- Multiple values (arrays).

Configuration keys are transformed to CLI flags: `["http", "serverTimeout"]` → `--http-server-timeout`.

## Array handling

Arrays can be specified in multiple ways:

- **Space-separated**: `--tags swift configuration cli`

- **Repeated flags**: `--tags swift --tags configuration --tags cli`

- **Comma-separated**: `--tags swift,configuration,cli`

- **Mixed**: `--tags swift,configuration --tags cli`

All formats produce the same result when accessed as an array type.

## Usage

// CLI: program --debug --host localhost --ports 8080 8443
let provider = CommandLineArgumentsProvider()
let config = ConfigReader(provider: provider)

let isDebug = config.bool(forKey: "debug", default: false) // true
let host = config.string(forKey: "host", default: "0.0.0.0") // "localhost"
let ports = config.intArray(forKey: "ports", default: []) // [8080, 8443]

### With secrets

let provider = CommandLineArgumentsProvider(
secretsSpecifier: .specific(["--api-key"])
)

### Custom arguments

let provider = CommandLineArgumentsProvider(
arguments: ["program", "--verbose", "--timeout", "30"],
secretsSpecifier: .dynamic { key, _ in key.contains("--secret") }
)

## Topics

### Creating a command line arguments provider

Creates a new CLI provider with the provided arguments.

## Relationships

### Conforms To

- `ConfigProvider`
- `Swift.Copyable`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

Using reloading providers

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- CommandLineArgumentsProvider
- Overview
- Package traits
- Key formats
- Array handling
- Usage
- With secrets
- Custom arguments
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/choosing-reader-methods

- Configuration
- Choosing reader methods

Article

# Choosing reader methods

Choose between optional, default, and required variants of configuration methods.

## Overview

For every configuration access pattern (get, fetch, watch) and data type, Swift Configuration provides three method variants that handle missing or invalid values differently:

- **Optional variant**: Returns `nil` when a value is missing or cannot be converted.

- **Default variant**: Returns a fallback value when a value is missing or cannot be converted.

- **Required variant**: Throws an error when a value is missing or cannot be converted.

Understanding these variants helps you write robust configuration code that handles missing values appropriately for your use case.

### Optional variants

Optional variants return `nil` when a configuration value is missing or cannot be converted to the expected type. These methods have the simplest signatures and are ideal when configuration values are truly optional.

let config = ConfigReader(provider: EnvironmentVariablesProvider())

// Optional get
let timeout: Int? = config.int(forKey: "http.timeout")
let apiUrl: String? = config.string(forKey: "api.url")

// Optional fetch
let latestTimeout: Int? = try await config.fetchInt(forKey: "http.timeout")

// Optional watch
try await config.watchInt(forKey: "http.timeout") { updates in
for await timeout in updates {
if let timeout = timeout {
print("Timeout is set to: \(timeout)")
} else {
print("No timeout configured")
}
}
}

#### When to use

Use optional variants when:

- **Truly optional features**: The configuration controls optional functionality.

- **Gradual rollouts**: New configuration that might not be present everywhere.

- **Conditional behavior**: Your code can operate differently based on presence or absence.

- **Debugging and diagnostics**: You want to detect missing configuration explicitly.

#### Error handling behavior

Optional variants handle errors gracefully by returning `nil`:

- Missing values return `nil`.

- Type conversion errors return `nil`.

- Provider errors return `nil` (except for fetch variants, which always propagate provider errors).

// These all return nil instead of throwing
let missingPort = config.int(forKey: "nonexistent.port") // nil
let invalidPort = config.int(forKey: "invalid.port.value") // nil (if value can't convert to Int)
let failingPort = config.int(forKey: "provider.error.key") // nil (if provider fails)

// Fetch variants still throw provider errors
do {
let port = try await config.fetchInt(forKey: "network.error") // Throws provider error
} catch {
// Handle network or provider errors
}

### Default variants

Default variants return a specified fallback value when a configuration value is missing or cannot be converted. These provide guaranteed non-optional results while handling missing configuration gracefully.

// Default get
let timeout = config.int(forKey: "http.timeout", default: 30)
let retryCount = config.int(forKey: "network.retries", default: 3)

// Default fetch
let latestTimeout = try await config.fetchInt(forKey: "http.timeout", default: 30)

// Default watch
try await config.watchInt(forKey: "http.timeout", default: 30) { updates in
for await timeout in updates {
print("Using timeout: \(timeout)") // Always has a value
connectionManager.setTimeout(timeout)
}
}

#### When to use

Use default variants when:

- **Sensible defaults exist**: You have reasonable fallback values for missing configuration.

- **Simplified code flow**: You want to avoid optional handling in business logic.

- **Required functionality**: The feature needs a value to operate, but can use defaults.

- **Configuration evolution**: New settings that should work with older deployments.

#### Choosing good defaults

Consider these principles when choosing default values:

// Safe defaults that won't cause issues
let timeout = config.int(forKey: "http.timeout", default: 30) // Reasonable timeout
let maxRetries = config.int(forKey: "retries.max", default: 3) // Conservative retry count
let cacheSize = config.int(forKey: "cache.size", default: 1000) // Modest cache size

// Environment-specific defaults
let logLevel = config.string(forKey: "log.level", default: "info") // Safe default level
let enableDebug = config.bool(forKey: "debug.enabled", default: false) // Secure default

// Performance defaults that err on the side of caution
let batchSize = config.int(forKey: "batch.size", default: 100) // Small safe batch
let maxConnections = config.int(forKey: "pool.max", default: 10) // Conservative pool

#### Error handling behavior

Default variants handle errors by returning the default value:

- Missing values return the default.

- Type conversion errors return the default.

- Provider errors return the default (except for fetch variants).

### Required variants

Required variants throw errors when configuration values are missing or cannot be converted. These enforce that critical configuration must be present and valid.

do {
// Required get
let serverPort = try config.requiredInt(forKey: "server.port")
let databaseHost = try config.requiredString(forKey: "database.host")

// Required fetch
let latestPort = try await config.fetchRequiredInt(forKey: "server.port")

// Required watch
try await config.watchRequiredInt(forKey: "server.port") { updates in
for try await port in updates {
print("Server port updated to: \(port)")
server.updatePort(port)
}
}
} catch {
fatalError("Configuration error: \(error)")
}

#### When to use

Use required variants when:

- **Essential service configuration**: Server ports, database hosts, service endpoints.

- **Application startup**: Values needed before the application can function properly.

- **Critical functionality**: Configuration that must be present for core features to work.

- **Fail-fast behavior**: You want immediate errors for missing critical configuration.

### Choosing the right variant

Use this decision tree to select the appropriate variant:

#### Is the configuration value critical for application operation?

**Yes** → Use **required variants**

// Critical values that must be present
let serverPort = try config.requiredInt(forKey: "server.port")
let databaseHost = try config.requiredString(forKey: "database.host")

**No** → Continue to next question

#### Do you have a reasonable default value?

**Yes** → Use **default variants**

// Optional features with sensible defaults
let timeout = config.int(forKey: "http.timeout", default: 30)
let retryCount = config.int(forKey: "retries", default: 3)

**No** → Use **optional variants**

// Truly optional features where absence is meaningful
let debugEndpoint = config.string(forKey: "debug.endpoint")
let customTheme = config.string(forKey: "ui.theme")

### Context and type conversion

All variants support the same additional features:

#### Configuration context

// Optional with context
let timeout = config.int(
forKey: ConfigKey(
"service.timeout",
context: ["environment": "production", "region": "us-east-1"]
)
)

// Default with context
let timeout = config.int(
forKey: ConfigKey(
"service.timeout",
context: ["environment": "production"]
),
default: 30
)

// Required with context
let timeout = try config.requiredInt(
forKey: ConfigKey(
"service.timeout",
context: ["environment": "production"]
)
)

#### Type conversion

String configuration values can be automatically converted to other types using the `as:` parameter. This works with:

**Built-in convertible types:**

- `SystemPackage.FilePath`: Converts from file paths.

- `Foundation.URL`: Converts from URL strings.

- `Foundation.UUID`: Converts from UUID strings.

- `Foundation.Date`: Converts from ISO8601 date strings.

**String-backed enums:**

**Custom types:**

- Types that you explicitly conform to `ExpressibleByConfigString`.

// Built-in type conversion
let apiUrl = config.string(forKey: "api.url", as: URL.self)
let requestId = config.string(forKey: "request.id", as: UUID.self)
let configPath = config.string(forKey: "config.path", as: FilePath.self)
let startDate = config.string(forKey: "launch.date", as: Date.self)

enum LogLevel: String {
case debug, info, warning, error
}

// Optional conversion
let level: LogLevel? = config.string(forKey: "log.level", as: LogLevel.self)

// Default conversion
let level = config.string(forKey: "log.level", as: LogLevel.self, default: .info)

// Required conversion
let level = try config.requiredString(forKey: "log.level", as: LogLevel.self)

// Custom type conversion (ExpressibleByConfigString)
struct DatabaseURL: ExpressibleByConfigString {
let url: URL

init?(configString: String) {
guard let url = URL(string: configString) else { return nil }
self.url = url
}

var description: String { url.absoluteString }
}
let dbUrl = config.string(forKey: "database.url", as: DatabaseURL.self)

#### Secret handling

// Mark sensitive values as secrets in all variants
let optionalKey = config.string(forKey: "api.key", isSecret: true)
let defaultKey = config.string(forKey: "api.key", isSecret: true, default: "development-key")
let requiredKey = try config.requiredString(forKey: "api.key", isSecret: true)

Also check out Handling secrets correctly.

### Best practices

1. **Use required variants** only for truly critical configuration.

2. **Use default variants** for user experience settings where missing configuration shouldn’t break functionality.

3. **Use optional variants** for feature flags and debugging where the absence of configuration is meaningful.

4. **Choose safe defaults** that won’t cause security issues or performance problems if used in production.

For guidance on selecting between get, fetch, and watch access patterns, see Choosing the access pattern. For more configuration guidance, check out Adopting best practices.

## See Also

### Readers and providers

`struct ConfigReader`

A type that provides read-only access to configuration values from underlying providers.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`struct ConfigSnapshotReader`

A container type for reading config values from snapshots.

Choosing the access pattern

Learn how to select the right method for reading configuration values based on your needs.

Handling secrets correctly

Protect sensitive configuration values from accidental disclosure in logs and debug output.

- Choosing reader methods
- Overview
- Optional variants
- Default variants
- Required variants
- Choosing the right variant
- Context and type conversion
- Best practices
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/keymappingprovider

- Configuration
- KeyMappingProvider

Structure

# KeyMappingProvider

A configuration provider that maps all keys before delegating to an upstream provider.

KeyMappingProvider.swift

## Mentioned in

Example use cases

## Overview

Use `KeyMappingProvider` to automatically apply a mapping function to every configuration key before passing it to an underlying provider. This is particularly useful when the upstream source of configuration keys differs from your own. Another example is namespacing configuration values from specific sources, such as prefixing environment variables with an application name while leaving other configuration sources unchanged.

### Common use cases

Use `KeyMappingProvider` for:

- Rewriting configuration keys to match upstream configuration sources.

- Legacy system integration that adapts existing sources with different naming conventions.

## Example

Use `KeyMappingProvider` when you want to map keys for specific providers in a multi-provider setup:

// Create providers
let envProvider = EnvironmentVariablesProvider()

// Only remap the environment variables, not the JSON config
let keyMappedEnvProvider = KeyMappingProvider(upstream: envProvider) { key in
key.prepending(["myapp", "prod"])
}

let config = ConfigReader(providers: [\
keyMappedEnvProvider, // Reads from "MYAPP_PROD_*" environment variables\
jsonProvider // Reads from JSON without prefix\
])

// This reads from "MYAPP_PROD_DATABASE_HOST" env var or "database.host" in JSON
let host = config.string(forKey: "database.host", default: "localhost")

## Convenience method

You can also use the `prefixKeys(with:)` convenience method on configuration provider types to wrap one in a `KeyMappingProvider`:

let envProvider = EnvironmentVariablesProvider()
let keyMappedEnvProvider = envProvider.mapKeys { key in
key.prepending(["myapp", "prod"])
}

## Topics

### Creating a key-mapping provider

Creates a new provider.

## Relationships

### Conforms To

- `ConfigProvider`
Conforms when `Upstream` conforms to `ConfigProvider`.

- `Swift.Copyable`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

Using reloading providers

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

- KeyMappingProvider
- Mentioned in
- Overview
- Common use cases
- Example
- Convenience method
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/choosing-access-patterns

- Configuration
- Choosing the access pattern

Article

# Choosing the access pattern

Learn how to select the right method for reading configuration values based on your needs.

## Overview

Swift Configuration provides three access patterns for retrieving configuration values, each optimized for different use cases and performance requirements.

The three access patterns are:

- **Get**: Synchronous access to current values available locally, in-memory.

- **Fetch**: Asynchronous access to retrieve fresh values from authoritative sources, optionally with extra context.

- **Watch**: Reactive access that provides real-time updates when values change.

### Get: Synchronous local access

The “get” pattern provides immediate, synchronous access to configuration values that are already available in memory. This is the fastest and most commonly used access pattern.

let config = ConfigReader(provider: EnvironmentVariablesProvider())

// Get the current timeout value synchronously
let timeout = config.int(forKey: "http.timeout", default: 30)

// Get a required value that must be present
let apiKey = try config.requiredString(forKey: "api.key", isSecret: true)

#### When to use

Use the “get” pattern when:

- **Performance is critical**: You need immediate access without async overhead.

- **Values are stable**: Configuration doesn’t change frequently during runtime.

- **Simple providers**: Using environment variables, command-line arguments, or files.

- **Startup configuration**: Reading values during application initialization.

- **Request handling**: Accessing configuration in hot code paths where async calls would add latency.

#### Behavior characteristics

- Returns the currently cached value from the provider.

- No network or I/O operations occur during the call.

- Values may become stale if the underlying data source changes and the provider is either non-reloading, or has a long reload interval.

### Fetch: Asynchronous fresh access

The “fetch” pattern asynchronously retrieves the most current value from the authoritative data source, ensuring you always get up-to-date configuration.

let config = ConfigReader(provider: remoteConfigProvider)

// Fetch the latest timeout from a remote configuration service
let timeout = try await config.fetchInt(forKey: "http.timeout", default: 30)

// Fetch with context for environment-specific configuration
let dbConnectionString = try await config.fetchRequiredString(
forKey: ConfigKey(
"database.url",
context: [\
"environment": "production",\
"region": "us-west-2",\
"service": "user-service"\
]
),
isSecret: true
)

#### When to use

Use the “fetch” pattern when:

- **Freshness is critical**: You need the latest configuration values.

- **Remote providers**: Using configuration services, databases, or external APIs that perform evaluation remotely.

- **Infrequent access**: Reading configuration occasionally, not in hot paths.

- **Setup operations**: Configuring long-lived resources like database connections where one-time overhead isn’t a concern, and the improved freshness is important.

- **Administrative operations**: Fetching current settings for management interfaces.

#### Behavior characteristics

- Always contacts the authoritative data source.

- May involve network calls, file system access, or database queries.

- Providers may (but are not required to) cache the fetched value for subsequent “get” calls.

- Throws an error if the provider fails to reach the source.

### Watch: Reactive continuous updates

The “watch” pattern provides an async sequence of configuration updates, allowing you to react to changes in real-time. This is ideal for long-running services that need to adapt to configuration changes without restarting.

The async sequence is required to receive the current value as the first element as quickly as possible - this is part of the API contract with configuration providers (for details, check out `ConfigProvider`.)

let config = ConfigReader(provider: reloadingProvider)

// Watch for timeout changes and update connection pools
try await config.watchInt(forKey: "http.timeout", default: 30) { updates in
for await newTimeout in updates {
print("HTTP timeout updated to: \(newTimeout)")
connectionPool.updateTimeout(newTimeout)
}
}

#### When to use

Use the “watch” pattern when:

- **Dynamic configuration**: Values change during application runtime.

- **Hot reloading**: You need to update behavior without restarting the service.

- **Feature toggles**: Enabling or disabling features based on configuration changes.

- **Resource management**: Adjusting timeouts, limits, or thresholds dynamically.

- **A/B testing**: Updating experimental parameters in real-time.

#### Behavior characteristics

- Immediately emits the initial value, then subsequent updates.

- Continues monitoring until the task is cancelled.

- Works with providers like `ReloadingFileProvider`.

For details on reloading providers, check out Using reloading providers.

### Using configuration context

All access patterns support configuration context, which provides additional metadata to help providers return more specific values. Context is particularly useful with the “fetch” and “watch” patterns when working with dynamic or environment-aware providers.

#### Filtering watch updates using context

let context: [String: ConfigContextValue] = [\
"environment": "production",\
"region": "us-east-1",\
"service_version": "2.1.0",\
"feature_tier": "premium",\
"load_factor": 0.85\
]

// Get environment-specific database configuration
let dbConfig = try await config.fetchRequiredString(
forKey: ConfigKey(
"database.connection_string",
context: context
),
isSecret: true
)

// Watch for region-specific timeout adjustments
try await config.watchInt(
forKey: ConfigKey(
"api.timeout",
context: ["region": "us-west-2"]
),
default: 5000
) { updates in
for await timeout in updates {
apiClient.updateTimeout(milliseconds: timeout)
}
}

#### Get pattern performance

- **Fastest**: No async overhead, immediate return.

- **Memory usage**: Minimal, uses cached values.

- **Best for**: Request handling, hot code paths, startup configuration.

#### Fetch pattern performance

- **Moderate**: Async overhead plus data source access time.

- **Network dependent**: Performance varies with provider implementation.

- **Best for**: Infrequent access, setup operations, administrative tasks.

#### Watch pattern performance

- **Background monitoring**: Continuous resource usage for monitoring.

- **Event-driven**: Efficient updates only when values change.

- **Best for**: Long-running services, dynamic configuration, feature toggles.

### Error handling strategies

Each access pattern handles errors differently:

#### Get pattern errors

// Returns nil or default value for missing/invalid config
let timeout = config.int(forKey: "http.timeout", default: 30)

// Required variants throw errors for missing values
do {
let apiKey = try config.requiredString(forKey: "api.key")
} catch {
// Handle missing required configuration
}

#### Fetch pattern errors

// All fetch methods propagate provider and conversion errors
do {
let config = try await config.fetchRequiredString(forKey: "database.url")
} catch {
// Handle network errors, missing values, or conversion failures
}

#### Watch pattern errors

// Errors appear in the async sequence
try await config.watchRequiredInt(forKey: "port") { updates in
do {
for try await port in updates {
server.updatePort(port)
}
} catch {
// Handle provider errors or missing required values
}
}

### Best practices

1. **Choose based on use case**: Use “get” for performance-critical paths, “fetch” for freshness, and “watch” for hot reloading.

2. **Handle errors appropriately**: Design error handling strategies that match your application’s resilience requirements.

3. **Use context judiciously**: Provide context when you need environment-specific or conditional configuration values.

4. **Monitor configuration access**: Use `AccessReporter` to understand your application’s configuration dependencies.

5. **Cache wisely**: For frequently accessed values, prefer “get” over repeated “fetch” calls.

For more guidance on selecting the right reader methods for your needs, see Choosing reader methods. To learn about handling sensitive configuration values securely, check out Handling secrets correctly. If you encounter issues with configuration access, refer to Troubleshooting and access reporting for debugging techniques.

## See Also

### Readers and providers

`struct ConfigReader`

A type that provides read-only access to configuration values from underlying providers.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`struct ConfigSnapshotReader`

A container type for reading config values from snapshots.

Choosing reader methods

Choose between optional, default, and required variants of configuration methods.

Handling secrets correctly

Protect sensitive configuration values from accidental disclosure in logs and debug output.

- Choosing the access pattern
- Overview
- Get: Synchronous local access
- Fetch: Asynchronous fresh access
- Watch: Reactive continuous updates
- Using configuration context
- Summary of performance considerations
- Error handling strategies
- Best practices
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessreporter

- Configuration
- AccessReporter

Protocol

# AccessReporter

A type that receives and processes configuration access events.

protocol AccessReporter : Sendable

AccessReporter.swift

## Mentioned in

Troubleshooting and access reporting

Choosing the access pattern

Configuring libraries

## Overview

Access reporters track when configuration values are read, fetched, or watched, to provide visibility into configuration usage patterns. This is useful for debugging, auditing, and understanding configuration dependencies.

## Topics

### Required methods

`func report(AccessEvent)`

Processes a configuration access event.

**Required**

## Relationships

### Inherits From

- `Swift.Sendable`
- `Swift.SendableMetatype`

### Conforming Types

- `AccessLogger`
- `BroadcastingAccessReporter`
- `FileAccessLogger`

## See Also

### Troubleshooting and access reporting

Check out some techniques to debug unexpected issues and to increase visibility into accessed config values.

`class AccessLogger`

An access reporter that logs configuration access events using the Swift Log API.

`class FileAccessLogger`

An access reporter that writes configuration access events to a file.

`struct AccessEvent`

An event that captures information about accessing a configuration value.

`struct BroadcastingAccessReporter`

An access reporter that forwards events to multiple other reporters.

- AccessReporter
- Mentioned in
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/using-reloading-providers

- Configuration
- Using reloading providers

Article

# Using reloading providers

Automatically reload configuration from files when they change.

## Overview

A reloading provider monitors configuration files for changes and automatically updates your application’s configuration without requiring restarts. Swift Configuration provides:

- `ReloadingFileProvider` with `JSONSnapshot` for JSON configuration files.

- `ReloadingFileProvider` with `YAMLSnapshot` for YAML configuration files.

#### Creating and running providers

Reloading providers run in a `ServiceGroup`:

import ServiceLifecycle

filePath: "/etc/config.json",
allowMissing: true, // Optional: treat missing file as empty config
pollInterval: .seconds(15)
)

let serviceGroup = ServiceGroup(
services: [provider],
logger: logger
)

try await serviceGroup.run()

#### Reading configuration

Use a reloading provider in the same fashion as a static provider, pass it to a `ConfigReader`:

let config = ConfigReader(provider: provider)
let host = config.string(
forKey: "database.host",
default: "localhost"
)

#### Poll interval considerations

Choose poll intervals based on how quickly you need to detect changes:

// Development: Quick feedback
pollInterval: .seconds(1)

// Production: Balanced performance (default)
pollInterval: .seconds(15)

// Batch processing: Resource efficient
pollInterval: .seconds(300)

### Watching for changes

The following sections provide examples of watching for changes in configuration from a reloading provider.

#### Individual values

The example below watches for updates in a single key, `database.host`:

try await config.watchString(
forKey: "database.host"
) { updates in
for await host in updates {
print("Database host updated: \(host)")
}
}

#### Configuration snapshots

The following example reads the `database.host` and `database.password` key with the guarantee that they are read from the same update of the reloading file:

try await config.watchSnapshot { updates in
for await snapshot in updates {
let host = snapshot.string(forKey: "database.host")
let password = snapshot.string(forKey: "database.password", isSecret: true)
print("Configuration updated - Database: \(host)")
}
}

### Comparison with static providers

| Feature | Static providers | Reloading providers |
| --- | --- | --- |
| **File reading** | Load once at startup | Reloading on change |
| **Service lifecycle** | Not required | Conforms to `Service` and must run in a `ServiceGroup` |
| **Configuration updates** | Require restart | Automatic reload |

### Handling missing files during reloading

Reloading providers support the `allowMissing` parameter to handle cases where configuration files might be temporarily missing or optional. This is useful for:

- Optional configuration files that might not exist in all environments.

- Configuration files that are created or removed dynamically.

- Graceful handling of file system issues during service startup.

#### Missing file behavior

When `allowMissing` is `false` (the default), missing files cause errors:

filePath: "/etc/config.json",
allowMissing: false // Default: throw error if file is missing
)
// Will throw an error if config.json doesn't exist

When `allowMissing` is `true`, missing files are treated as empty configuration:

filePath: "/etc/config.json",
allowMissing: true // Treat missing file as empty config
)
// Won't throw if config.json is missing - uses empty config instead

#### Behavior during reloading

If a file becomes missing after the provider starts, the behavior depends on the `allowMissing` setting:

- **`allowMissing: false`**: The provider keeps the last known configuration and logs an error.

- **`allowMissing: true`**: The provider switches to empty configuration.

In both cases, when a valid file comes back, the provider will load it and recover.

// Example: File gets deleted during runtime
try await config.watchString(forKey: "database.host", default: "localhost") { updates in
for await host in updates {
// With allowMissing: true, this will receive "localhost" when file is removed
// With allowMissing: false, this keeps the last known value
print("Database host: \(host)")
}
}

#### Configuration-driven setup

The following example sets up an environment variable provider to select the path and interval to watch for a JSON file that contains the configuration for your app:

let envProvider = EnvironmentVariablesProvider()
let envConfig = ConfigReader(provider: envProvider)

config: envConfig.scoped(to: "json")
// Reads JSON_FILE_PATH and JSON_POLL_INTERVAL_SECONDS
)

### Migration from static providers

1. **Replace initialization**:

// Before

// After

2. **Add the provider to a ServiceGroup**:

let serviceGroup = ServiceGroup(services: [provider], logger: logger)
try await serviceGroup.run()

3. **Use ConfigReader**:

let config = ConfigReader(provider: provider)

// Live updates.
try await config.watchDouble(forKey: "timeout") { updates in
// Handle changes
}

// On-demand reads - returns the current value, so might change over time.
let timeout = config.double(forKey: "timeout", default: 60.0)

For guidance on choosing between get, fetch, and watch access patterns with reloading providers, see Choosing the access pattern. For troubleshooting reloading provider issues, check out Troubleshooting and access reporting. To learn about in-memory providers as an alternative, see Using in-memory providers.

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- Using reloading providers
- Overview
- Basic usage
- Watching for changes
- Comparison with static providers
- Handling missing files during reloading
- Advanced features
- Migration from static providers
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/mutableinmemoryprovider

- Configuration
- MutableInMemoryProvider

Class

# MutableInMemoryProvider

A configuration provider that stores mutable values in memory.

final class MutableInMemoryProvider

MutableInMemoryProvider.swift

## Mentioned in

Using in-memory providers

## Overview

Unlike `InMemoryProvider`, this provider allows configuration values to be modified after initialization. It maintains thread-safe access to values and supports real-time notifications when values change, making it ideal for dynamic configuration scenarios.

## Change notifications

The provider supports watching for configuration changes through the standard `ConfigProvider` watching methods. When a value changes, all active watchers are automatically notified with the new value.

## Use cases

The mutable in-memory provider is particularly useful for:

- **Dynamic configuration**: Values that change during application runtime

- **Configuration bridges**: Adapting external configuration systems that push updates

- **Testing scenarios**: Simulating configuration changes in unit tests

- **Feature flags**: Runtime toggles that can be modified programmatically

## Performance characteristics

This provider offers O(1) lookup time with minimal synchronization overhead. Value updates are atomic and efficiently notify only the relevant watchers.

## Usage

// Create provider with initial values
let provider = MutableInMemoryProvider(initialValues: [\
"feature.enabled": true,\
"api.timeout": 30.0,\
"database.host": "localhost"\
])

let config = ConfigReader(provider: provider)

// Read initial values
let isEnabled = config.bool(forKey: "feature.enabled") // true

// Update values dynamically
provider.setValue(false, forKey: "feature.enabled")

// Read updated values
let stillEnabled = config.bool(forKey: "feature.enabled") // false

To learn more about the in-memory providers, check out Using in-memory providers.

## Topics

### Creating a mutable in-memory provider

[`init(name: String?, initialValues: [AbsoluteConfigKey : ConfigValue])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/mutableinmemoryprovider/init(name:initialvalues:))

Creates a new mutable in-memory provider with the specified initial values.

### Updating values in a mutable in-memory provider

`func setValue(ConfigValue?, forKey: AbsoluteConfigKey)`

Updates the stored value for the specified configuration key.

## Relationships

### Conforms To

- `ConfigProvider`
- `Swift.Copyable`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

Using reloading providers

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- MutableInMemoryProvider
- Mentioned in
- Overview
- Change notifications
- Use cases
- Performance characteristics
- Usage
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/development

- Configuration
- Developing Swift Configuration

Article

# Developing Swift Configuration

Learn about tools and conventions used to develop the Swift Configuration package.

## Overview

The Swift Configuration package is developed using modern Swift development practices and tools. This guide covers the development workflow, code organization, and tooling used to maintain the package.

### Process

We follow an open process and discuss development on GitHub issues, pull requests, and on the Swift Forums. Details on how to submit an issue or a pull requests can be found in CONTRIBUTING.md.

Large features and changes go through a lightweight proposals process - to learn more, check out Proposals.

#### Package organization

The package contains several Swift targets organized by functionality:

- **Configuration** \- Core configuration reading APIs and built-in providers.

- **ConfigurationTesting** \- Testing utilities for external configuration providers.

- **ConfigurationTestingInternal** \- Internal testing utilities and helpers.

#### Running CI checks locally

You can run the Github Actions workflows locally using act. To run all the jobs that run on a pull request, use the following command:

% act pull_request
% act workflow_call -j soundness --input shell_check_enabled=true

To bind-mount the working directory to the container, rather than a copy, use `--bind`. For example, to run just the formatting, and have the results reflected in your working directory:

% act --bind workflow_call -j soundness --input format_check_enabled=true

If you’d like `act` to always run with certain flags, these can be be placed in an `.actrc` file either in the current working directory or your home directory, for example:

--container-architecture=linux/amd64
--remote-name upstream
--action-offline-mode

#### Code generation with gyb

This package uses the “generate your boilerplate” (gyb) script from the Swift repository to stamp out repetitive code for each supported primitive type.

The files that include gyb syntax end with `.gyb`, and after making changes to any of those files, run:

./Scripts/generate_boilerplate_files_with_gyb.sh

If you’re adding a new `.gyb` file, also make sure to add it to the exclude list in `Package.swift`.

After running this script, also run the formatter before opening a PR.

#### Code formatting

The project uses swift-format for consistent code style. You can run CI checks locally using `act`.

To run formatting checks:

act --bind workflow_call -j soundness --input format_check_enabled=true

#### Testing

The package includes comprehensive test suites for all components:

- Unit tests for individual providers and utilities.

- Compatibility tests using `ProviderCompatTest` for built-in providers.

Run tests using Swift Package Manager:

swift test --enable-all-traits

#### Documentation

Documentation is written using DocC and includes:

- API reference documentation in source code.

- Conceptual guides in `.docc` catalogs.

- Usage examples and best practices.

- Troubleshooting guides.

Preview documentation locally:

SWIFT_PREVIEW_DOCS=1 swift package --disable-sandbox preview-documentation --target Configuration

#### Code style

- Follow Swift API Design Guidelines.

- Use meaningful names for types, methods, and variables.

- Include comprehensive documentation for all APIs, not only public types.

- Write unit tests for new functionality.

#### Provider development

When developing new configuration providers:

1. Implement the `ConfigProvider` protocol.

2. Add comprehensive unit tests.

3. Run compatibility tests using `ProviderCompatTest`.

4. Add documentation to all symbols, not just `public`.

#### Documentation requirements

All APIs must include:

- Clear, concise documentation comments.

- Usage examples where appropriate.

- Parameter and return value descriptions.

- Error conditions and handling.

## See Also

### Contributing

Collaborate on API changes to Swift Configuration by writing a proposal.

- Developing Swift Configuration
- Overview
- Process
- Repository structure
- Development tools
- Contributing guidelines
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/troubleshooting

- Configuration
- Troubleshooting and access reporting

Article

# Troubleshooting and access reporting

Check out some techniques to debug unexpected issues and to increase visibility into accessed config values.

## Overview

### Debugging configuration issues

If your configuration values aren’t being read correctly, check:

1. **Environment variable naming**: When using `EnvironmentVariablesProvider`, keys are automatically converted to uppercase with dots replaced by underscores. For example, `database.url` becomes `DATABASE_URL`.

2. **Provider ordering**: When using multiple providers, they’re checked in order and the first one that returns a value wins.

3. **Debug with an access reporter**: Use access reporting to see which keys are being queried and what values (if any) are being returned. See the next section for details.

For guidance on selecting the right configuration access patterns and reader methods, check out Choosing the access pattern and Choosing reader methods.

### Access reporting

Configuration access reporting can help you debug issues and understand which configuration values your application is using. Swift Configuration provides two built-in ways to log access ( `AccessLogger` and `FileAccessLogger`), and you can also implement your own `AccessReporter`.

#### Using AccessLogger

`AccessLogger` integrates with Swift Log and records all configuration accesses:

let logger = Logger(label: "...")
let accessLogger = AccessLogger(logger: logger)
let config = ConfigReader(provider: provider, accessReporter: accessLogger)

// Each access will now be logged.
let timeout = config.double(forKey: "http.timeout", default: 30.0)

This produces log entries showing:

- Which configuration keys were accessed.

- What values were returned (with secret values redacted).

- Which provider supplied the value.

- Whether default values were used.

- The location of the code reading the config value.

- The timestamp of the access.

#### Using FileAccessLogger

For writing access events to a file, especially useful during ad-hoc debugging, use `FileAccessLogger`:

let fileLogger = try FileAccessLogger(filePath: "/var/log/myapp/config-access.log")
let config = ConfigReader(provider: provider, accessReporter: fileLogger)

You can also enable file access logging for the whole application, without recompiling your code, by setting an environment variable:

export CONFIG_ACCESS_LOG_FILE=/var/log/myapp/config-access.log

And then read from the file to see one line per config access:

tail -f /var/log/myapp/config-access.log

#### Provider errors

If any provider throws an error during lookup:

- **Required methods** (`requiredString`, etc.): Error is immediately thrown to the caller.

- **Optional methods** (with or without defaults): Error is handled gracefully; `nil` or the default value is returned.

#### Missing values

When no provider has the requested value:

- **Methods with defaults**: Return the provided default value.

- **Methods without defaults**: Return `nil`.

- **Required methods**: Throw an error.

#### File not found errors

File-based providers ( `FileProvider`, `ReloadingFileProvider`, `DirectoryFilesProvider`, `EnvironmentVariablesProvider` with file path) can throw “file not found” errors when expected configuration files don’t exist.

Common scenarios and solutions:

**Optional configuration files:**

// Problem: App crashes when optional config file is missing

// Solution: Use allowMissing parameter

filePath: "/etc/optional-config.json",
allowMissing: true
)

**Environment-specific files:**

// Different environments may have different config files
let configPath = "/etc/\(environment)/config.json"

filePath: configPath,
allowMissing: true // Gracefully handle missing env-specific configs
)

**Container startup issues:**

// Config files might not be ready when container starts

filePath: "/mnt/config/app.json",
allowMissing: true // Allow startup with empty config, load when available
)

#### Configuration not updating

If your reloading provider isn’t detecting file changes:

1. **Check ServiceGroup**: Ensure the provider is running in a `ServiceGroup`.

2. **Enable verbose logging**: The built-in providers use Swift Log for detailed logging, which can help spot issues.

3. **Verify file path**: Confirm the file path is correct, the file exists, and file permissions are correct.

4. **Check poll interval**: Consider if your poll interval is appropriate for your use case.

#### ServiceGroup integration issues

Common ServiceGroup problems:

// Incorrect: Provider not included in ServiceGroup

let config = ConfigReader(provider: provider)
// File monitoring won't work

// Correct: Provider runs in ServiceGroup

let serviceGroup = ServiceGroup(services: [provider], logger: logger)
try await serviceGroup.run()

For more details about reloading providers and ServiceLifecycle integration, see Using reloading providers. To learn about proper configuration practices that can prevent common issues, check out Adopting best practices.

## See Also

### Troubleshooting and access reporting

`protocol AccessReporter`

A type that receives and processes configuration access events.

`class AccessLogger`

An access reporter that logs configuration access events using the Swift Log API.

`class FileAccessLogger`

An access reporter that writes configuration access events to a file.

`struct AccessEvent`

An event that captures information about accessing a configuration value.

`struct BroadcastingAccessReporter`

An access reporter that forwards events to multiple other reporters.

- Troubleshooting and access reporting
- Overview
- Debugging configuration issues
- Access reporting
- Error handling
- Reloading provider troubleshooting
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/fileparsingoptions

- Configuration
- FileParsingOptions

Protocol

# FileParsingOptions

A type that provides parsing options for file configuration snapshots.

protocol FileParsingOptions : Sendable

FileProviderSnapshot.swift

## Overview

This protocol defines the requirements for parsing options types used with `FileConfigSnapshot` implementations. Types conforming to this protocol provide configuration parameters that control how file data is interpreted and parsed during snapshot creation.

The parsing options are passed to the `init(data:providerName:parsingOptions:)` initializer, allowing custom file format implementations to access format-specific parsing settings such as character encoding, date formats, or validation rules.

## Usage

Implement this protocol to provide parsing options for your custom `FileConfigSnapshot`:

struct MyParsingOptions: FileParsingOptions {
let encoding: String.Encoding
let dateFormat: String?
let strictValidation: Bool

static let `default` = MyParsingOptions(
encoding: .utf8,
dateFormat: nil,
strictValidation: false
)
}

struct MyFormatSnapshot: FileConfigSnapshot {
typealias ParsingOptions = MyParsingOptions

init(data: RawSpan, providerName: String, parsingOptions: ParsingOptions) throws {
// Implementation that inspects `parsingOptions` properties like `encoding`,
// `dateFormat`, and `strictValidation`.
}
}

## Topics

### Required properties

``static var `default`: Self``

The default instance of this options type.

**Required**

### Parsing options

`protocol FileConfigSnapshot`

A protocol for configuration snapshots created from file data.

## Relationships

### Inherits From

- `Swift.Sendable`
- `Swift.SendableMetatype`

### Conforming Types

- `JSONSnapshot.ParsingOptions`
- `YAMLSnapshot.ParsingOptions`

## See Also

### Creating a custom provider

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`enum ConfigContent`

The raw content of a configuration value.

`struct ConfigValue`

A configuration value that wraps content with metadata.

`enum ConfigType`

The supported configuration value types.

`struct LookupResult`

The result of looking up a configuration value in a provider.

`enum SecretsSpecifier`

A specification for identifying which configuration values contain sensitive information.

`struct ConfigUpdatesAsyncSequence`

A concrete async sequence for delivering updated configuration values.

- FileParsingOptions
- Overview
- Usage
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshot

- Configuration
- ConfigSnapshot

Protocol

# ConfigSnapshot

An immutable snapshot of a configuration provider’s state.

protocol ConfigSnapshot : Sendable

ConfigProvider.swift

## Overview

Snapshots enable consistent reads of multiple related configuration keys by capturing the provider’s state at a specific moment. This prevents the underlying data from changing between individual key lookups.

## Topics

### Required methods

`var providerName: String`

The human-readable name of the configuration provider that created this snapshot.

**Required**

Returns a value for the specified key from this immutable snapshot.

## Relationships

### Inherits From

- `Swift.Sendable`
- `Swift.SendableMetatype`

### Inherited By

- `FileConfigSnapshot`

### Conforming Types

- `JSONSnapshot`
- `YAMLSnapshot`

## See Also

### Creating a custom provider

`protocol FileParsingOptions`

A type that provides parsing options for file configuration snapshots.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`enum ConfigContent`

The raw content of a configuration value.

`struct ConfigValue`

A configuration value that wraps content with metadata.

`enum ConfigType`

The supported configuration value types.

`struct LookupResult`

The result of looking up a configuration value in a provider.

`enum SecretsSpecifier`

A specification for identifying which configuration values contain sensitive information.

`struct ConfigUpdatesAsyncSequence`

A concrete async sequence for delivering updated configuration values.

- ConfigSnapshot
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configuring-applications

- Configuration
- Configuring applications

Article

# Configuring applications

Provide flexible and consistent configuration for your application.

## Overview

Swift Configuration provides consistent configuration for your tools and applications. This guide shows how to:

1. Set up a configuration hierarchy with multiple providers.

2. Configure your application’s components.

3. Access configuration values in your application and libraries.

4. Monitor configuration access with access reporting.

This pattern works well for server applications where configuration comes from environment variables, configuration files, and remote services.

### Setting up a configuration hierarchy

Start by creating a configuration hierarchy in your application’s entry point. This defines the order in which configuration sources are consulted when looking for values:

import Configuration
import Logging

// Create a logger.
let logger: Logger = ...

// Set up the configuration hierarchy:
// - environment variables first,
// - then JSON file,
// - then in-memory defaults.
// Also emit log accesses into the provider logger,
// with secrets automatically redacted.

let config = ConfigReader(
providers: [\
EnvironmentVariablesProvider(),\

filePath: "/etc/myapp/config.json",\
allowMissing: true // Optional: treat missing file as empty config\
),\
InMemoryProvider(values: [\
"http.server.port": 8080,\
"http.server.host": "127.0.0.1",\
"http.client.timeout": 30.0\
])\
],
accessReporter: AccessLogger(logger: logger)
)

// Start your application with the config.
try await runApplication(config: config, logger: logger)

This configuration hierarchy gives priority to environment variables, then falls

Next, configure your application using the configuration reader:

func runApplication(
config: ConfigReader,
logger: Logger
) async throws {
// Get server configuration.
let serverHost = config.string(
forKey: "http.server.host",
default: "localhost"
)
let serverPort = config.int(
forKey: "http.server.port",
default: 8080
)

// Read library configuration with a scoped reader
// with the prefix `http.client`.
let httpClientConfig = HTTPClientConfiguration(
config: config.scoped(to: "http.client")
)
let httpClient = HTTPClient(configuration: httpClientConfig)

// Run your server with the configured components
try await startHTTPServer(
host: serverHost,
port: serverPort,
httpClient: httpClient,
logger: logger
)
}

Finally, you configure your application across the three sources. A fully configured set of environment variables could look like the following:

export HTTP_SERVER_HOST=localhost
export HTTP_SERVER_PORT=8080
export HTTP_CLIENT_TIMEOUT=30.0
export HTTP_CLIENT_MAX_CONCURRENT_CONNECTIONS=20
export HTTP_CLIENT_BASE_URL="https://example.com"
export HTTP_CLIENT_DEBUG_LOGGING=true

In JSON:

{
"http": {
"server": {
"host": "localhost",
"port": 8080
},
"client": {
"timeout": 30.0,
"maxConcurrentConnections": 20,
"baseURL": "https://example.com",
"debugLogging": true
}
}
}

And using `InMemoryProvider`:

[\
"http.server.port": 8080,\
"http.server.host": "127.0.0.1",\
"http.client.timeout": 30.0,\
"http.client.maxConcurrentConnections": 20,\
"http.client.baseURL": "https://example.com",\
"http.client.debugLogging": true,\
]

In practice, you’d only specify a subset of the config keys in each location, to match the needs of your service’s operators.

### Using scoped configuration

For services with multiple instances of the same component, but with different settings, use scoped configuration:

// For our server example, we might have different API clients
// that need different settings:

let adminConfig = config.scoped(to: "services.admin")
let customerConfig = config.scoped(to: "services.customer")

// Using the admin API configuration
let adminBaseURL = adminConfig.string(
forKey: "baseURL",
default: "https://admin-api.example.com"
)
let adminTimeout = adminConfig.double(
forKey: "timeout",
default: 60.0
)

// Using the customer API configuration
let customerBaseURL = customerConfig.string(
forKey: "baseURL",
default: "https://customer-api.example.com"
)
let customerTimeout = customerConfig.double(
forKey: "timeout",
default: 30.0
)

This can be configured via environment variables as follows:

# Admin API configuration
export SERVICES_ADMIN_BASE_URL="https://admin.internal-api.example.com"
export SERVICES_ADMIN_TIMEOUT=120.0
export SERVICES_ADMIN_DEBUG_LOGGING=true

# Customer API configuration
export SERVICES_CUSTOMER_BASE_URL="https://api.example.com"
export SERVICES_CUSTOMER_MAX_CONCURRENT_CONNECTIONS=20
export SERVICES_CUSTOMER_TIMEOUT=15.0

For details about the key conversion logic, check out `EnvironmentVariablesProvider`.

For more configuration guidance, see Adopting best practices. To understand different access patterns and reader methods, refer to Choosing the access pattern and Choosing reader methods. For handling secrets securely, check out Handling secrets correctly.

## See Also

### Essentials

Configuring libraries

Provide a consistent and flexible way to configure your library.

Example use cases

Review common use cases with ready-to-copy code samples.

Adopting best practices

Follow these principles to make your code easily configurable and composable with other libraries.

- Configuring applications
- Overview
- Setting up a configuration hierarchy
- Configure your application
- Using scoped configuration
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/systempackage

- Configuration
- SystemPackage

Extended Module

# SystemPackage

## Topics

### Extended Structures

`extension FilePath`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configupdatesasyncsequence

- Configuration
- ConfigUpdatesAsyncSequence

Structure

# ConfigUpdatesAsyncSequence

A concrete async sequence for delivering updated configuration values.

AsyncSequences.swift

## Topics

### Creating an asynchronous update sequence

Creates a new concrete async sequence wrapping the provided existential sequence.

## Relationships

### Conforms To

- `Swift.Copyable`
- `Swift.Sendable`
- `Swift.SendableMetatype`
- `_Concurrency.AsyncSequence`

## See Also

### Creating a custom provider

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

`protocol FileParsingOptions`

A type that provides parsing options for file configuration snapshots.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`enum ConfigContent`

The raw content of a configuration value.

`struct ConfigValue`

A configuration value that wraps content with metadata.

`enum ConfigType`

The supported configuration value types.

`struct LookupResult`

The result of looking up a configuration value in a provider.

`enum SecretsSpecifier`

A specification for identifying which configuration values contain sensitive information.

- ConfigUpdatesAsyncSequence
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/expressiblebyconfigstring

- Configuration
- ExpressibleByConfigString

Protocol

# ExpressibleByConfigString

A protocol for types that can be initialized from configuration string values.

protocol ExpressibleByConfigString : CustomStringConvertible

ExpressibleByConfigString.swift

## Mentioned in

Choosing reader methods

## Overview

Conform your custom types to this protocol to enable automatic conversion when using the `as:` parameter with configuration reader methods such as `string(forKey:as:isSecret:fileID:line:)`.

## Custom types

For other custom types, conform to the protocol `ExpressibleByConfigString` by providing a failable initializer and the `description` property:

struct DatabaseURL: ExpressibleByConfigString {
let url: URL

init?(configString: String) {
guard let url = URL(string: configString) else { return nil }
self.url = url
}

var description: String { url.absoluteString }
}

// Now you can use it with automatic conversion
let config = ConfigReader(provider: EnvironmentVariablesProvider())
let dbUrl = config.string(forKey: "database.url", as: DatabaseURL.self)

## Built-in conformances

The following Foundation types already conform to `ExpressibleByConfigString`:

- `SystemPackage.FilePath` \- Converts from file paths.

- `Foundation.URL` \- Converts from URL strings.

- `Foundation.UUID` \- Converts from UUID strings.

- `Foundation.Date` \- Converts from ISO8601 date strings.

## Topics

### Required methods

`init?(configString: String)`

Creates an instance from a configuration string value.

**Required**

## Relationships

### Inherits From

- `Swift.CustomStringConvertible`

### Conforming Types

- `Date`
- `FilePath`
- `URL`
- `UUID`

## See Also

### Value conversion

`protocol ConfigBytesFromStringDecoder`

A protocol for decoding string configuration values into byte arrays.

`struct ConfigBytesFromBase64StringDecoder`

A decoder that converts base64-encoded strings into byte arrays.

`struct ConfigBytesFromHexStringDecoder`

A decoder that converts hexadecimal-encoded strings into byte arrays.

- ExpressibleByConfigString
- Mentioned in
- Overview
- Custom types
- Built-in conformances
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/using-in-memory-providers

- Configuration
- Using in-memory providers

Article

# Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

## Overview

Swift Configuration provides two in-memory providers, which are directly instantiated with the desired keys and values, rather than being parsed from another representation. These providers are particularly useful for testing, providing fallback values, and bridging with other configuration systems.

- `InMemoryProvider` is an immutable value type, and can be useful for defining overrides and fallbacks in a provider hierarchy.

- `MutableInMemoryProvider` is a mutable reference type, allowing you to update values and get any watchers notified automatically. It can be used to bridge from other stateful, callback-based configuration sources.

### InMemoryProvider

The `InMemoryProvider` is ideal for static configuration values that don’t change during application runtime.

#### Basic usage

Create an `InMemoryProvider` with a dictionary of configuration values:

let provider = InMemoryProvider(values: [\
"database.host": "localhost",\
"database.port": 5432,\
"api.timeout": 30.0,\
"debug.enabled": true\
])

let config = ConfigReader(provider: provider)
let host = config.string(forKey: "database.host") // "localhost"
let port = config.int(forKey: "database.port") // 5432

#### Using with hierarchical keys

You can use `AbsoluteConfigKey` for more complex key structures:

let provider = InMemoryProvider(values: [\
AbsoluteConfigKey(["http", "client", "timeout"]): 30.0,\
AbsoluteConfigKey(["http", "server", "port"]): 8080,\
AbsoluteConfigKey(["logging", "level"]): "info"\
])

#### Configuration context

The in-memory provider performs exact matching of config keys, including the context. This allows you to provide different values for the same key path based on contextual information.

The following example shows using two keys with the same key path, but different context, and giving them two different values:

let provider = InMemoryProvider(
values: [\
AbsoluteConfigKey(\
["http", "client", "timeout"],\
context: ["upstream": "example1.org"]\
): 15.0,\
AbsoluteConfigKey(\
["http", "client", "timeout"],\
context: ["upstream": "example2.org"]\
): 30.0,\
]
)

With a provider configured this way, a config reader will return the following results:

let config = ConfigReader(provider: provider)
config.double(forKey: "http.client.timeout") // nil
config.double(
forKey: ConfigKey(
"http.client.timeout",
context: ["upstream": "example1.org"]
)
) // 15.0
config.double(
forKey: ConfigKey(
"http.client.timeout",
context: ["upstream": "example2.org"]
)
) // 30.0

### MutableInMemoryProvider

The `MutableInMemoryProvider` allows you to modify configuration values at runtime and notify watchers of changes.

#### Basic usage

let provider = MutableInMemoryProvider()
provider.setValue("localhost", forKey: "database.host")
provider.setValue(5432, forKey: "database.port")

let config = ConfigReader(provider: provider)
let host = config.string(forKey: "database.host") // "localhost"

#### Updating values

You can update values after creation, and any watchers will be notified:

// Initial setup
provider.setValue("debug", forKey: "logging.level")

// Later in your application, watchers are notified
provider.setValue("info", forKey: "logging.level")

#### Watching for changes

Use the provider’s async sequence to watch for configuration changes:

let config = ConfigReader(provider: provider)
try await config.watchString(
forKey: "logging.level",
as: Logger.Level.self,
default: .debug
) { updates in
for try await level in updates {
print("Logging level changed to: \(level)")
}
}

#### Testing

In-memory providers are excellent for unit testing:

func testDatabaseConnection() {
let testProvider = InMemoryProvider(values: [\
"database.host": "test-db.example.com",\
"database.port": 5433,\
"database.name": "test_db"\
])

let config = ConfigReader(provider: testProvider)
let connection = DatabaseConnection(config: config)
// Test your database connection logic
}

#### Fallback values

Use `InMemoryProvider` as a fallback in a provider hierarchy:

let fallbackProvider = InMemoryProvider(values: [\
"api.timeout": 30.0,\
"retry.maxAttempts": 3,\
"cache.enabled": true\
])

let config = ConfigReader(providers: [\
EnvironmentVariablesProvider(),\
fallbackProvider\
// Used when environment variables are not set\
])

#### Bridging other systems

Use `MutableInMemoryProvider` to bridge configuration from other systems:

class ConfigurationBridge {
private let provider = MutableInMemoryProvider()

func updateFromExternalSystem(_ values: [String: ConfigValue]) {
for (key, value) in values {
provider.setValue(value, forKey: key)
}
}
}

For comparison with reloading providers, see Using reloading providers. To understand different access patterns and when to use each provider type, check out Choosing the access pattern. For more configuration guidance, refer to Adopting best practices.

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

Using reloading providers

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- Using in-memory providers
- Overview
- InMemoryProvider
- MutableInMemoryProvider
- Common Use Cases
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader/snapshot()

#app-main)

- Configuration
- ConfigReader
- snapshot()

Instance Method

# snapshot()

Returns a snapshot of the current configuration state.

ConfigSnapshotReader.swift

## Return Value

The snapshot.

## Discussion

The snapshot reader provides read-only access to the configuration’s state at the time the method was called.

let snapshot = config.snapshot()
// Use snapshot to read config values
let cert = snapshot.string(forKey: "cert")
let privateKey = snapshot.string(forKey: "privateKey")
// Ensures that both values are coming from the same underlying snapshot and that a provider
// didn't change its internal state between the two `string(...)` calls.
let identity = MyIdentity(cert: cert, privateKey: privateKey)

## See Also

### Reading from a snapshot

Watches the configuration for changes.

- snapshot()
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/best-practices

- Configuration
- Adopting best practices

Article

# Adopting best practices

Follow these principles to make your code easily configurable and composable with other libraries.

## Overview

When designing configuration for Swift libraries and applications, follow these patterns to create consistent, maintainable code that integrates well with the Swift ecosystem.

### Document configuration keys

Include thorough documentation about what configuration keys your library reads. For each key, document:

- The key name and its hierarchical structure.

- The expected data type.

- Whether the key is required or optional.

- Default values when applicable.

- Valid value ranges or constraints.

- Usage examples.

public struct HTTPClientConfiguration {
/// ...
///
/// ## Configuration keys:
/// - `timeout` (double, optional, default: 30.0): Request timeout in seconds.
/// - `maxRetries` (int, optional, default: 3, range: 0-10): Maximum retry attempts.
/// - `baseURL` (string, required): Base URL for requests.
/// - `apiKey` (string, required, secret): API authentication key.
///
/// ...
public init(config: ConfigReader) {
// Implementation...
}
}

### Use sensible defaults

Provide reasonable default values to make your library work without extensive configuration.

// Good: Provides sensible defaults
let timeout = config.double(forKey: "http.timeout", default: 30.0)
let maxConnections = config.int(forKey: "http.maxConnections", default: 10)

// Avoid: Requiring configuration for common scenarios
let timeout = try config.requiredDouble(forKey: "http.timeout") // Forces users to configure

### Use scoped configuration

Organize your configuration keys logically using namespaces to keep related keys together.

// Good:
let httpConfig = config.scoped(to: "http")
let timeout = httpConfig.double(forKey: "timeout", default: 30.0)
let retries = httpConfig.int(forKey: "retries", default: 3)

// Better (in libraries): Offer a convenience method that reads your library's configuration.
// Tip: Read the configuration values from the provided reader directly, do not scope it
// to a "myLibrary" namespace. Instead, let the caller of MyLibraryConfiguration.init(config:)
// perform any scoping for your library's configuration.
public struct MyLibraryConfiguration {
public init(config: ConfigReader) {
self.timeout = config.double(forKey: "timeout", default: 30.0)
self.retries = config.int(forKey: "retries", default: 3)
}
}

// Called from an app - the caller is responsible for adding a namespace and naming it, if desired.
let libraryConfig = MyLibraryConfiguration(config: config.scoped(to: "myLib"))

### Mark secrets appropriately

Mark sensitive configuration values like API keys, passwords, or tokens as secrets using the `isSecret: true` parameter. This tells access reporters to redact those values in logs.

// Mark sensitive values as secrets
let apiKey = try config.requiredString(forKey: "api.key", isSecret: true)
let password = config.string(forKey: "database.password", default: nil, isSecret: true)

// Regular values don't need the isSecret parameter
let timeout = config.double(forKey: "api.timeout", default: 30.0)

Some providers also support the `SecretsSpecifier`, allowing you to mark which values are secret during application bootstrapping.

For comprehensive guidance on handling secrets securely, see Handling secrets correctly.

### Prefer optional over required

Only mark configuration as required if your library absolutely cannot function without it. For most cases, provide sensible defaults and make configuration optional.

// Good: Optional with sensible defaults
let timeout = config.double(forKey: "timeout", default: 30.0)
let debug = config.bool(forKey: "debug", default: false)

// Use required only when absolutely necessary
let apiEndpoint = try config.requiredString(forKey: "api.endpoint")

For more details, check out Choosing reader methods.

### Validate configuration values

Validate configuration values and throw meaningful errors for invalid input to catch configuration issues early.

public init(config: ConfigReader) throws {
let timeout = config.double(forKey: "timeout", default: 30.0)

throw MyConfigurationError.invalidTimeout("Timeout must be positive, got: \(timeout)")
}

let maxRetries = config.int(forKey: "maxRetries", default: 3)

throw MyConfigurationError.invalidRetryCount("Max retries must be 0-10, got: \(maxRetries)")
}

self.timeout = timeout
self.maxRetries = maxRetries
}

#### When to use reloading providers

Use reloading providers when you need configuration changes to take effect without restarting your application:

- Long-running services that can’t be restarted frequently.

- Development environments where you iterate on configuration.

- Applications that receive configuration updates through file deployments.

Check out Using reloading providers to learn more.

#### When to use static providers

Use static providers when configuration doesn’t change during runtime:

- Containerized applications with immutable configuration.

- Applications where configuration is set once at startup.

For help choosing between different access patterns and reader method variants, see Choosing the access pattern and Choosing reader methods. For troubleshooting configuration issues, refer to Troubleshooting and access reporting.

## See Also

### Essentials

Configuring applications

Provide flexible and consistent configuration for your application.

Configuring libraries

Provide a consistent and flexible way to configure your library.

Example use cases

Review common use cases with ready-to-copy code samples.

- Adopting best practices
- Overview
- Document configuration keys
- Use sensible defaults
- Use scoped configuration
- Mark secrets appropriately
- Prefer optional over required
- Validate configuration values
- Choosing provider types
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/secretsspecifier

- Configuration
- SecretsSpecifier

Enumeration

# SecretsSpecifier

A specification for identifying which configuration values contain sensitive information.

SecretsSpecifier.swift

## Mentioned in

Adopting best practices

Handling secrets correctly

## Overview

Configuration providers use secrets specifiers to determine which values should be marked as sensitive and protected from accidental disclosure in logs, debug output, or access reports. Secret values are handled specially by `AccessReporter` instances and other components that process configuration data.

## Usage patterns

### Mark all values as secret

Use this for providers that exclusively handle sensitive data:

let provider = InMemoryProvider(
values: ["api.key": "secret123", "db.password": "pass456"],
secretsSpecifier: .all
)

### Mark specific keys as secret

Use this when you know which specific keys contain sensitive information:

let provider = EnvironmentVariablesProvider(
secretsSpecifier: .specific(
["API_KEY", "DATABASE_PASSWORD", "JWT_SECRET"]
)
)

### Dynamic secret detection

Use this for complex logic that determines secrecy based on key patterns or values:

filePath: "/etc/config.json",
secretsSpecifier: .dynamic { key, value in
// Mark keys containing "password",
// "secret", or "token" as secret
key.lowercased().contains("password") ||
key.lowercased().contains("secret") ||
key.lowercased().contains("token")
}
)

### No secret values

Use this for providers that handle only non-sensitive configuration:

let provider = InMemoryProvider(
values: ["app.name": "MyApp", "log.level": "info"],
secretsSpecifier: .none
)

## Topics

### Types of specifiers

`case all`

The library treats all configuration values as secrets.

The library treats the specified keys as secrets.

The library determines the secret status dynamically by evaluating each key-value pair.

`case none`

The library treats no configuration values as secrets.

### Inspecting a secrets specifier

Determines whether a configuration value should be treated as secret.

## Relationships

### Conforms To

- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Creating a custom provider

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

`protocol FileParsingOptions`

A type that provides parsing options for file configuration snapshots.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`enum ConfigContent`

The raw content of a configuration value.

`struct ConfigValue`

A configuration value that wraps content with metadata.

`enum ConfigType`

The supported configuration value types.

`struct LookupResult`

The result of looking up a configuration value in a provider.

`struct ConfigUpdatesAsyncSequence`

A concrete async sequence for delivering updated configuration values.

- SecretsSpecifier
- Mentioned in
- Overview
- Usage patterns
- Mark all values as secret
- Mark specific keys as secret
- Dynamic secret detection
- No secret values
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/directoryfilesprovider

- Configuration
- DirectoryFilesProvider

Structure

# DirectoryFilesProvider

A configuration provider that reads values from individual files in a directory.

struct DirectoryFilesProvider

DirectoryFilesProvider.swift

## Mentioned in

Example use cases

Handling secrets correctly

Troubleshooting and access reporting

## Overview

This provider reads configuration values from a directory where each file represents a single configuration key-value pair. The file name becomes the configuration key, and the file contents become the value. This approach is commonly used by secret management systems that mount secrets as individual files.

## Key mapping

Configuration keys are transformed into file names using these rules:

- Components are joined with dashes.

- Non-alphanumeric characters (except dashes) are replaced with underscores.

For example:

## Value handling

The provider reads file contents as UTF-8 strings and converts them to the requested type. For binary data (bytes type), it reads raw file contents directly without string conversion. Leading and trailing whitespace is always trimmed from string values.

## Supported data types

The provider supports all standard configuration types:

- Strings (UTF-8 text files)

- Integers, doubles, and booleans (parsed from string contents)

- Arrays (using configurable separator, comma by default)

- Byte arrays (raw file contents)

## Secret handling

By default, all values are marked as secrets for security. This is appropriate since this provider is typically used for sensitive data mounted by secret management systems.

## Usage

### Reading from a secrets directory

// Assuming /run/secrets contains files:
// - database-password (contains: "secretpass123")
// - max-connections (contains: "100")
// - enable-cache (contains: "true")

let provider = try await DirectoryFilesProvider(
directoryPath: "/run/secrets"
)

let config = ConfigReader(provider: provider)
let dbPassword = config.string(forKey: "database.password") // "secretpass123"
let maxConn = config.int(forKey: "max.connections", default: 50) // 100
let cacheEnabled = config.bool(forKey: "enable.cache", default: false) // true

### Reading binary data

// For binary files like certificates or keys
let provider = try await DirectoryFilesProvider(
directoryPath: "/run/secrets"
)

let config = ConfigReader(provider: provider)
let certData = try config.requiredBytes(forKey: "tls.cert") // Raw file bytes

### Custom array handling

// If files contain comma-separated lists
let provider = try await DirectoryFilesProvider(
directoryPath: "/etc/config"
)

// File "allowed-hosts" contains: "host1.example.com,host2.example.com,host3.example.com"
let hosts = config.stringArray(forKey: "allowed.hosts", default: [])
// ["host1.example.com", "host2.example.com", "host3.example.com"]

## Configuration context

This provider ignores the context passed in `context`. All keys are resolved using only their component path.

## Topics

### Creating a directory files provider

Creates a new provider that reads files from a directory.

## Relationships

### Conforms To

- `ConfigProvider`
- `Swift.Copyable`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

Using reloading providers

Automatically reload configuration from files when they change.

Using in-memory providers

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`struct InMemoryProvider`

A configuration provider that stores values in memory.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- DirectoryFilesProvider
- Mentioned in
- Overview
- Key mapping
- Value handling
- Supported data types
- Secret handling
- Usage
- Reading from a secrets directory
- Reading binary data
- Custom array handling
- Configuration context
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey

- Configuration
- AbsoluteConfigKey

Structure

# AbsoluteConfigKey

A configuration key that represents an absolute path to a configuration value.

struct AbsoluteConfigKey

ConfigKey.swift

## Mentioned in

Using in-memory providers

## Overview

Absolute configuration keys are similar to relative keys but represent complete paths from the root of the configuration hierarchy. They are used internally by the configuration system after resolving any key prefixes or scoping.

Like relative keys, absolute keys consist of hierarchical components and optional context information.

## Topics

### Creating an absolute configuration key

`init(ConfigKey)`

Creates a new absolute configuration key from a relative key.

[`init([String], context: [String : ConfigContextValue])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/init(_:context:))

Creates a new absolute configuration key.

### Inspecting an absolute configuration key

[`var components: [String]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/components)

The hierarchical components that make up this absolute configuration key.

[`var context: [String : ConfigContextValue]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/context)

Additional context information for this configuration key.

### Instance Methods

Returns a new absolute configuration key by appending the given relative key.

Returns a new absolute configuration key by prepending the given relative key.

## Relationships

### Conforms To

- `Swift.Comparable`
- `Swift.Copyable`
- `Swift.CustomStringConvertible`
- `Swift.Equatable`
- `Swift.ExpressibleByArrayLiteral`
- `Swift.ExpressibleByExtendedGraphemeClusterLiteral`
- `Swift.ExpressibleByStringLiteral`
- `Swift.ExpressibleByUnicodeScalarLiteral`
- `Swift.Hashable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Configuration keys

`struct ConfigKey`

A configuration key representing a relative path to a configuration value.

`enum ConfigContextValue`

A value that can be stored in a configuration context.

- AbsoluteConfigKey
- Mentioned in
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configbytesfromhexstringdecoder

- Configuration
- ConfigBytesFromHexStringDecoder

Structure

# ConfigBytesFromHexStringDecoder

A decoder that converts hexadecimal-encoded strings into byte arrays.

struct ConfigBytesFromHexStringDecoder

ConfigBytesFromStringDecoder.swift

## Overview

This decoder interprets string configuration values as hexadecimal-encoded data and converts them to their binary representation. It expects strings to contain only valid hexadecimal characters (0-9, A-F, a-f).

## Hexadecimal format

The decoder expects strings with an even number of characters, where each pair of characters represents one byte. For example, “48656C6C6F” represents the bytes for “Hello”.

## Topics

### Creating bytes from a hex string decoder

`init()`

Creates a new hexadecimal decoder.

## Relationships

### Conforms To

- `ConfigBytesFromStringDecoder`
- `Swift.Copyable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Value conversion

`protocol ExpressibleByConfigString`

A protocol for types that can be initialized from configuration string values.

`protocol ConfigBytesFromStringDecoder`

A protocol for decoding string configuration values into byte arrays.

`struct ConfigBytesFromBase64StringDecoder`

A decoder that converts base64-encoded strings into byte arrays.

- ConfigBytesFromHexStringDecoder
- Overview
- Hexadecimal format
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent

- Configuration
- ConfigContent

Enumeration

# ConfigContent

The raw content of a configuration value.

@frozen
enum ConfigContent

ConfigProvider.swift

## Topics

### Types of configuration content

`case string(String)`

A string value.

[`case stringArray([String])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/stringarray(_:))

An array of string values.

`case bool(Bool)`

A Boolean value.

[`case boolArray([Bool])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/boolarray(_:))

An array of Boolean value.

`case int(Int)`

An integer value.

[`case intArray([Int])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/intarray(_:))

An array of integer values.

`case double(Double)`

A double value.

[`case doubleArray([Double])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/doublearray(_:))

An array of double values.

[`case bytes([UInt8])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytes(_:))

An array of bytes.

[`case byteChunkArray([[UInt8]])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytechunkarray(_:))

An array of byte arrays.

## Relationships

### Conforms To

- `Swift.Copyable`
- `Swift.Equatable`
- `Swift.ExpressibleByBooleanLiteral`
- `Swift.ExpressibleByExtendedGraphemeClusterLiteral`
- `Swift.ExpressibleByFloatLiteral`
- `Swift.ExpressibleByIntegerLiteral`
- `Swift.ExpressibleByStringLiteral`
- `Swift.ExpressibleByUnicodeScalarLiteral`
- `Swift.Hashable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Creating a custom provider

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

`protocol FileParsingOptions`

A type that provides parsing options for file configuration snapshots.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`struct ConfigValue`

A configuration value that wraps content with metadata.

`enum ConfigType`

The supported configuration value types.

`struct LookupResult`

The result of looking up a configuration value in a provider.

`enum SecretsSpecifier`

A specification for identifying which configuration values contain sensitive information.

`struct ConfigUpdatesAsyncSequence`

A concrete async sequence for delivering updated configuration values.

- ConfigContent
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configvalue

- Configuration
- ConfigValue

Structure

# ConfigValue

A configuration value that wraps content with metadata.

struct ConfigValue

ConfigProvider.swift

## Mentioned in

Handling secrets correctly

## Overview

Configuration values pair raw content with a flag indicating whether the value contains sensitive information. Secret values are protected from accidental disclosure in logs and debug output:

let apiKey = ConfigValue(.string("sk-abc123"), isSecret: true)

## Topics

### Creating a config value

`init(ConfigContent, isSecret: Bool)`

Creates a new configuration value.

### Inspecting a config value

`var content: ConfigContent`

The configuration content.

`var isSecret: Bool`

Whether this value contains sensitive information that should not be logged.

## Relationships

### Conforms To

- `Swift.Copyable`
- `Swift.CustomStringConvertible`
- `Swift.Equatable`
- `Swift.ExpressibleByBooleanLiteral`
- `Swift.ExpressibleByExtendedGraphemeClusterLiteral`
- `Swift.ExpressibleByFloatLiteral`
- `Swift.ExpressibleByIntegerLiteral`
- `Swift.ExpressibleByStringLiteral`
- `Swift.ExpressibleByUnicodeScalarLiteral`
- `Swift.Hashable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Creating a custom provider

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

`protocol FileParsingOptions`

A type that provides parsing options for file configuration snapshots.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`enum ConfigContent`

The raw content of a configuration value.

`enum ConfigType`

The supported configuration value types.

`struct LookupResult`

The result of looking up a configuration value in a provider.

`enum SecretsSpecifier`

A specification for identifying which configuration values contain sensitive information.

`struct ConfigUpdatesAsyncSequence`

A concrete async sequence for delivering updated configuration values.

- ConfigValue
- Mentioned in
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/foundation

- Configuration
- Foundation

Extended Module

# Foundation

## Topics

### Extended Structures

`extension Date`

`extension URL`

`extension UUID`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshotreader

- Configuration
- ConfigSnapshotReader

Structure

# ConfigSnapshotReader

A container type for reading config values from snapshots.

struct ConfigSnapshotReader

ConfigSnapshotReader.swift

## Overview

A config snapshot reader provides read-only access to config values stored in an underlying `ConfigSnapshot`. Unlike a config reader, which can access live, changing config values from providers, a snapshot reader works with a fixed, immutable snapshot of the configuration data.

## Usage

Get a snapshot reader from a config reader by using the `snapshot()` method. All values in the snapshot are guaranteed to be from the same point in time:

// Get a snapshot from a ConfigReader
let config = ConfigReader(provider: EnvironmentVariablesProvider())
let snapshot = config.snapshot()
// Use snapshot to read config values
let cert = snapshot.string(forKey: "cert")
let privateKey = snapshot.string(forKey: "privateKey")
// Ensures that both values are coming from the same
// underlying snapshot and that a provider didn't change
// its internal state between the two `string(...)` calls.
let identity = MyIdentity(cert: cert, privateKey: privateKey)

Or you can watch for snapshot updates using the `watchSnapshot(fileID:line:updatesHandler:)` method:

try await config.watchSnapshot { snapshots in
for await snapshot in snapshots {
// Process each new configuration snapshot
let cert = snapshot.string(forKey: "cert")
let privateKey = snapshot.string(forKey: "privateKey")
// Ensures that both values are coming from the same
// underlying snapshot and that a provider didn't change
// its internal state between the two `string(...)` calls.
let newCert = MyCert(cert: cert, privateKey: privateKey)
print("Certificate was updated: \(newCert.redactedDescription)")
}
}

### Scoping

Like `ConfigReader`, you can set a key prefix on the config snapshot reader, allowing all config lookups to prepend a prefix to the keys, which lets you pass a scoped snapshot reader to nested components.

let httpConfig = snapshotReader.scoped(to: "http")
let timeout = httpConfig.int(forKey: "timeout")
// Reads from "http.timeout" in the snapshot

### Config keys and context

The library requests config values using a canonical “config key”, that represents a key path. You can provide additional context that was used by some providers when the snapshot was created.

let httpTimeout = snapshotReader.int(
forKey: ConfigKey("http.timeout", context: ["upstream": "example.com"]),
default: 60
)

### Automatic type conversion

String configuration values can be automatically converted to other types using the `as:` parameter. This works with:

- Types that you explicitly conform to `ExpressibleByConfigString`.

- Built-in types that already conform to `ExpressibleByConfigString`:

- `SystemPackage.FilePath` \- Converts from file paths.

- `Foundation.URL` \- Converts from URL strings.

- `Foundation.UUID` \- Converts from UUID strings.

- `Foundation.Date` \- Converts from ISO8601 date strings.

// Built-in type conversion
let apiUrl = snapshot.string(
forKey: "api.url",
as: URL.self
)
let requestId = snapshot.string(
forKey: "request.id",
as: UUID.self
)

enum LogLevel: String {
case debug, info, warning, error
}
let logLevel = snapshot.string(
forKey: "logging.level",
as: LogLevel.self,
default: .info
)

// Custom type conversion (ExpressibleByConfigString)
struct DatabaseURL: ExpressibleByConfigString {
let url: URL

init?(configString: String) {
guard let url = URL(string: configString) else { return nil }
self.url = url
}

var description: String { url.absoluteString }
}
let dbUrl = snapshot.string(
forKey: "database.url",
as: DatabaseURL.self
)

### Access reporting

When reading from a snapshot, access events are reported to the access reporter from the original config reader. This helps debug which config values are accessed, even when reading from snapshots.

## Topics

### Creating a snapshot

Returns a snapshot of the current configuration state.

Watches the configuration for changes.

### Namespacing

Returns a scoped snapshot reader by appending the provided key to the current key prefix.

### Synchronously reading string values

Synchronously gets a config value for the given config key.

Synchronously gets a config value for the given config key, with a default fallback.

Synchronously gets a config value for the given config key, converting from string.

Synchronously gets a config value for the given config key with default fallback, converting from string.

### Synchronously reading lists of string values

Synchronously gets an array of config values for the given config key, converting from strings.

Synchronously gets an array of config values for the given config key with default fallback, converting from strings.

### Synchronously reading required string values

Synchronously gets a required config value for the given config key, throwing an error if it’s missing.

Synchronously gets a required config value for the given config key, converting from string.

### Synchronously reading required lists of string values

Synchronously gets a required array of config values for the given config key, converting from strings.

### Synchronously reading Boolean values

### Synchronously reading required Boolean values

### Synchronously reading lists of Boolean values

### Synchronously reading required lists of Boolean values

### Synchronously reading integer values

### Synchronously reading required integer values

### Synchronously reading lists of integer values

### Synchronously reading required lists of integer values

### Synchronously reading double values

### Synchronously reading required double values

### Synchronously reading lists of double values

### Synchronously reading required lists of double values

### Synchronously reading bytes

### Synchronously reading required bytes

### Synchronously reading collections of byte chunks

### Synchronously reading required collections of byte chunks

## Relationships

### Conforms To

- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Readers and providers

`struct ConfigReader`

A type that provides read-only access to configuration values from underlying providers.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

Choosing the access pattern

Learn how to select the right method for reading configuration values based on your needs.

Choosing reader methods

Choose between optional, default, and required variants of configuration methods.

Handling secrets correctly

Protect sensitive configuration values from accidental disclosure in logs and debug output.

- ConfigSnapshotReader
- Overview
- Usage
- Scoping
- Config keys and context
- Automatic type conversion
- Access reporting
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontextvalue

- Configuration
- ConfigContextValue

Enumeration

# ConfigContextValue

A value that can be stored in a configuration context.

enum ConfigContextValue

ConfigContext.swift

## Overview

Context values support common data types used for configuration metadata.

## Topics

### Configuration context values

`case string(String)`

A string value.

`case bool(Bool)`

A Boolean value.

`case int(Int)`

An integer value.

`case double(Double)`

A floating point value.

## Relationships

### Conforms To

- `Swift.Copyable`
- `Swift.CustomStringConvertible`
- `Swift.Equatable`
- `Swift.ExpressibleByBooleanLiteral`
- `Swift.ExpressibleByExtendedGraphemeClusterLiteral`
- `Swift.ExpressibleByFloatLiteral`
- `Swift.ExpressibleByIntegerLiteral`
- `Swift.ExpressibleByStringLiteral`
- `Swift.ExpressibleByUnicodeScalarLiteral`
- `Swift.Hashable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Configuration keys

`struct ConfigKey`

A configuration key representing a relative path to a configuration value.

`struct AbsoluteConfigKey`

A configuration key that represents an absolute path to a configuration value.

- ConfigContextValue
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader

- Configuration
- ConfigReader

Structure

# ConfigReader

A type that provides read-only access to configuration values from underlying providers.

struct ConfigReader

ConfigReader.swift

## Mentioned in

Configuring libraries

Example use cases

Using reloading providers

## Overview

Use `ConfigReader` to access configuration values from various sources like environment variables, JSON files, or in-memory stores. The reader supports provider hierarchies, key scoping, and access reporting for debugging configuration usage.

## Usage

To read configuration values, create a config reader with one or more providers:

let config = ConfigReader(provider: EnvironmentVariablesProvider())
let httpTimeout = config.int(forKey: "http.timeout", default: 60)

### Using multiple providers

Create a hierarchy of providers by passing an array to the initializer. The reader queries providers in order, using the first non-nil value it finds:

do {
let config = ConfigReader(providers: [\
// First, check environment variables\
EnvironmentVariablesProvider(),\
// Then, check a JSON config file\

// Finally, fall \
])

// Uses the first provider that has a value for "http.timeout"
let timeout = config.int(forKey: "http.timeout", default: 15)
} catch {
print("Failed to create JSON provider: \(error)")
}

The `get` and `fetch` methods query providers sequentially, while the `watch` method monitors all providers in parallel and returns the first non-nil value from the latest results.

### Creating scoped readers

Create a scoped reader to access nested configuration sections without repeating key prefixes. This is useful for passing configuration to specific components.

Given this JSON configuration:

{
"http": {
"timeout": 60
}
}

Create a scoped reader for the HTTP section:

let httpConfig = config.scoped(to: "http")
let timeout = httpConfig.int(forKey: "timeout") // Reads "http.timeout"

### Understanding config keys

The library accesses configuration values using config keys that represent a hierarchical path to the value. Internally, the library represents a key as a list of string components, such as `["http", "timeout"]`.

### Using configuration context

Provide additional context to help providers return more specific values. In the following example with a configuration that includes repeated configurations per “upstream”, the value returned is potentially constrained to the configuration with the matching context:

let httpTimeout = config.int(
forKey: ConfigKey("http.timeout", context: ["upstream": "example.com"]),
default: 60
)

Providers can use this context to return specialized values or fall

The library can automatically convert string configuration values to other types using the `as:` parameter. This works with:

- Types that you explicitly conform to `ExpressibleByConfigString`.

- Built-in types that already conform to `ExpressibleByConfigString`:

- `SystemPackage.FilePath` \- Converts from file paths.

- `Foundation.URL` \- Converts from URL strings.

- `Foundation.UUID` \- Converts from UUID strings.

- `Foundation.Date` \- Converts from ISO8601 date strings.

// Built-in type conversion
let apiUrl = config.string(forKey: "api.url", as: URL.self)
let requestId = config.string(
forKey: "request.id",
as: UUID.self
)

enum LogLevel: String {
case debug, info, warning, error
}
let logLevel = config.string(
forKey: "logging.level",
as: LogLevel.self,
default: .info
)

// Custom type conversion (ExpressibleByConfigString)
struct DatabaseURL: ExpressibleByConfigString {
let url: URL

init?(configString: String) {
guard let url = URL(string: configString) else { return nil }
self.url = url
}

var description: String { url.absoluteString }
}
let dbUrl = config.string(
forKey: "database.url",
as: DatabaseURL.self
)

### How providers encode keys

Each `ConfigProvider` interprets config keys according to its data source format. For example, `EnvironmentVariablesProvider` converts `["http", "timeout"]` to the environment variable name `HTTP_TIMEOUT` by uppercasing components and joining with underscores.

### Monitoring configuration access

Use an access reporter to track which configuration values your application reads. The reporter receives `AccessEvent` instances containing the requested key, calling code location, returned value, and source provider.

This helps debug configuration issues and to discover the config dependencies in your codebase.

### Protecting sensitive values

Mark sensitive configuration values as secrets to prevent logging by access loggers. Both config readers and providers can set the `isSecret` property. When either marks a value as sensitive, `AccessReporter` instances should not log the raw value.

### Configuration context

Configuration context supplements the configuration key components with extra metadata that providers can use to refine value lookups or return more specific results. Context is particularly useful for scenarios where the same configuration key might need different values based on runtime conditions.

Create context using dictionary literal syntax with automatic type inference:

let context: [String: ConfigContextValue] = [\
"environment": "production",\
"region": "us-west-2",\
"timeout": 30,\
"retryEnabled": true\
]

#### Provider behavior

Not all providers use context information. Providers that support context can:

- Return specialized values based on context keys.

- Fall ,
default: "localhost:5432"
)

### Error handling behavior

The config reader handles provider errors differently based on the method type:

- **Get and watch methods**: Gracefully handle errors by returning `nil` or default values, except for “required” variants which rethrow errors.

- **Fetch methods**: Always rethrow both provider and conversion errors.

- **Required methods**: Rethrow all errors without fallback behavior.

The library reports all provider errors to the access reporter through the `providerResults` array, even when handled gracefully.

## Topics

### Creating config readers

`init(provider: some ConfigProvider, accessReporter: (any AccessReporter)?)`

Creates a config reader with a single provider.

[`init(providers: [any ConfigProvider], accessReporter: (any AccessReporter)?)`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader/init(providers:accessreporter:))

Creates a config reader with multiple providers.

### Retrieving a scoped config reader

Returns a scoped config reader with the specified key appended to the current prefix.

### Reading from a snapshot

Returns a snapshot of the current configuration state.

Watches the configuration for changes.

## Relationships

### Conforms To

- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Readers and providers

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`struct ConfigSnapshotReader`

A container type for reading config values from snapshots.

Choosing the access pattern

Learn how to select the right method for reading configuration values based on your needs.

Choosing reader methods

Choose between optional, default, and required variants of configuration methods.

Handling secrets correctly

Protect sensitive configuration values from accidental disclosure in logs and debug output.

- ConfigReader
- Mentioned in
- Overview
- Usage
- Using multiple providers
- Creating scoped readers
- Understanding config keys
- Using configuration context
- Automatic type conversion
- How providers encode keys
- Monitoring configuration access
- Protecting sensitive values
- Configuration context
- Error handling behavior
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configbytesfromstringdecoder

- Configuration
- ConfigBytesFromStringDecoder

Protocol

# ConfigBytesFromStringDecoder

A protocol for decoding string configuration values into byte arrays.

protocol ConfigBytesFromStringDecoder : Sendable

ConfigBytesFromStringDecoder.swift

## Overview

This protocol defines the interface for converting string-based configuration values into binary data. Different implementations can support various encoding formats such as base64, hexadecimal, or other custom encodings.

## Usage

Implementations of this protocol are used by configuration providers that need to convert string values to binary data, such as cryptographic keys, certificates, or other binary configuration data.

let decoder: ConfigBytesFromStringDecoder = .base64
let bytes = decoder.decode("SGVsbG8gV29ybGQ=") // "Hello World" in base64

## Topics

### Required methods

Decodes a string value into an array of bytes.

**Required**

### Built-in decoders

`static var base64: ConfigBytesFromBase64StringDecoder`

A decoder that interprets string values as base64-encoded data.

`static var hex: ConfigBytesFromHexStringDecoder`

A decoder that interprets string values as hexadecimal-encoded data.

## Relationships

### Inherits From

- `Swift.Sendable`
- `Swift.SendableMetatype`

### Conforming Types

- `ConfigBytesFromBase64StringDecoder`
- `ConfigBytesFromHexStringDecoder`

## See Also

### Value conversion

`protocol ExpressibleByConfigString`

A protocol for types that can be initialized from configuration string values.

`struct ConfigBytesFromBase64StringDecoder`

A decoder that converts base64-encoded strings into byte arrays.

`struct ConfigBytesFromHexStringDecoder`

A decoder that converts hexadecimal-encoded strings into byte arrays.

- ConfigBytesFromStringDecoder
- Overview
- Usage
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configbytesfrombase64stringdecoder

- Configuration
- ConfigBytesFromBase64StringDecoder

Structure

# ConfigBytesFromBase64StringDecoder

A decoder that converts base64-encoded strings into byte arrays.

struct ConfigBytesFromBase64StringDecoder

ConfigBytesFromStringDecoder.swift

## Overview

This decoder interprets string configuration values as base64-encoded data and converts them to their binary representation.

## Topics

### Creating bytes from a base64 string

`init()`

Creates a new base64 decoder.

## Relationships

### Conforms To

- `ConfigBytesFromStringDecoder`
- `Swift.Copyable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Value conversion

`protocol ExpressibleByConfigString`

A protocol for types that can be initialized from configuration string values.

`protocol ConfigBytesFromStringDecoder`

A protocol for decoding string configuration values into byte arrays.

`struct ConfigBytesFromHexStringDecoder`

A decoder that converts hexadecimal-encoded strings into byte arrays.

- ConfigBytesFromBase64StringDecoder
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configtype

- Configuration
- ConfigType

Enumeration

# ConfigType

The supported configuration value types.

@frozen
enum ConfigType

ConfigProvider.swift

## Topics

### Types of configuration content

`case string`

A string value.

`case stringArray`

An array of string values.

`case bool`

A Boolean value.

`case boolArray`

An array of Boolean values.

`case int`

An integer value.

`case intArray`

An array of integer values.

`case double`

A double value.

`case doubleArray`

An array of double values.

`case bytes`

An array of bytes.

`case byteChunkArray`

An array of byte chunks.

### Initializers

`init?(rawValue: String)`

## Relationships

### Conforms To

- `Swift.BitwiseCopyable`
- `Swift.Equatable`
- `Swift.Hashable`
- `Swift.RawRepresentable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Creating a custom provider

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

`protocol FileParsingOptions`

A type that provides parsing options for file configuration snapshots.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`enum ConfigContent`

The raw content of a configuration value.

`struct ConfigValue`

A configuration value that wraps content with metadata.

`struct LookupResult`

The result of looking up a configuration value in a provider.

`enum SecretsSpecifier`

A specification for identifying which configuration values contain sensitive information.

`struct ConfigUpdatesAsyncSequence`

A concrete async sequence for delivering updated configuration values.

- ConfigType
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent

- Configuration
- AccessEvent

Structure

# AccessEvent

An event that captures information about accessing a configuration value.

struct AccessEvent

AccessReporter.swift

## Overview

Access events are generated whenever configuration values are accessed through `ConfigReader` and `ConfigSnapshotReader` methods. They contain metadata about the access, results from individual providers, and the final outcome of the operation.

## Topics

### Creating an access event

Creates a configuration access event.

`struct Metadata`

Metadata describing the configuration access operation.

`struct ProviderResult`

The result of a configuration lookup from a specific provider.

### Inspecting an access event

The final outcome of the configuration access operation.

`var conversionError: (any Error)?`

An error that occurred when converting the raw config value into another type, for example `RawRepresentable`.

`var metadata: AccessEvent.Metadata`

Metadata that describes the configuration access operation.

[`var providerResults: [AccessEvent.ProviderResult]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent/providerresults)

The results from each configuration provider that was queried.

## Relationships

### Conforms To

- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Troubleshooting and access reporting

Troubleshooting and access reporting

Check out some techniques to debug unexpected issues and to increase visibility into accessed config values.

`protocol AccessReporter`

A type that receives and processes configuration access events.

`class AccessLogger`

An access reporter that logs configuration access events using the Swift Log API.

`class FileAccessLogger`

An access reporter that writes configuration access events to a file.

`struct BroadcastingAccessReporter`

An access reporter that forwards events to multiple other reporters.

- AccessEvent
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/broadcastingaccessreporter

- Configuration
- BroadcastingAccessReporter

Structure

# BroadcastingAccessReporter

An access reporter that forwards events to multiple other reporters.

struct BroadcastingAccessReporter

AccessReporter.swift

## Overview

Use this reporter to send configuration access events to multiple destinations simultaneously. Each upstream reporter receives a copy of every event in the order they were provided during initialization.

let fileLogger = try FileAccessLogger(filePath: "/tmp/config.log")
let accessLogger = AccessLogger(logger: logger)
let broadcaster = BroadcastingAccessReporter(upstreams: [fileLogger, accessLogger])

let config = ConfigReader(
provider: EnvironmentVariablesProvider(),
accessReporter: broadcaster
)

## Topics

### Creating a broadcasting access reporter

[`init(upstreams: [any AccessReporter])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/broadcastingaccessreporter/init(upstreams:))

Creates a new broadcasting access reporter.

## Relationships

### Conforms To

- `AccessReporter`
- `Swift.Copyable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Troubleshooting and access reporting

Troubleshooting and access reporting

Check out some techniques to debug unexpected issues and to increase visibility into accessed config values.

`protocol AccessReporter`

A type that receives and processes configuration access events.

`class AccessLogger`

An access reporter that logs configuration access events using the Swift Log API.

`class FileAccessLogger`

An access reporter that writes configuration access events to a file.

`struct AccessEvent`

An event that captures information about accessing a configuration value.

- BroadcastingAccessReporter
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/lookupresult

- Configuration
- LookupResult

Structure

# LookupResult

The result of looking up a configuration value in a provider.

struct LookupResult

ConfigProvider.swift

## Overview

Providers return this result from value lookup methods, containing both the encoded key used for the lookup and the value found:

let result = try provider.value(forKey: key, type: .string)
if let value = result.value {
print("Found: \(value)")
}

## Topics

### Creating a lookup result

`init(encodedKey: String, value: ConfigValue?)`

Creates a lookup result.

### Inspecting a lookup result

`var encodedKey: String`

The provider-specific encoding of the configuration key.

`var value: ConfigValue?`

The configuration value found for the key, or nil if not found.

## Relationships

### Conforms To

- `Swift.Equatable`
- `Swift.Hashable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Creating a custom provider

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

`protocol FileParsingOptions`

A type that provides parsing options for file configuration snapshots.

`protocol ConfigProvider`

A type that provides configuration values from a data source.

`enum ConfigContent`

The raw content of a configuration value.

`struct ConfigValue`

A configuration value that wraps content with metadata.

`enum ConfigType`

The supported configuration value types.

`enum SecretsSpecifier`

A specification for identifying which configuration values contain sensitive information.

`struct ConfigUpdatesAsyncSequence`

A concrete async sequence for delivering updated configuration values.

- LookupResult
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/proposals

- Configuration
- Proposals

# Proposals

Collaborate on API changes to Swift Configuration by writing a proposal.

## Overview

For non-trivial changes that affect the public API, the Swift Configuration project adopts a lightweight version of the Swift Evolution process.

Writing a proposal first helps discuss multiple possible solutions early, apply useful feedback from other contributors, and avoid reimplementing the same feature multiple times.

While it’s encouraged to get feedback by opening a pull request with a proposal early in the process, it’s also important to consider the complexity of the implementation when evaluating different solutions. For example, this might mean including a link to a branch containing a prototype implementation of the feature in the pull request description.

### Steps

1. Make sure there’s a GitHub issue for the feature or change you would like to propose.

2. Duplicate the `SCO-NNNN.md` document and replace `NNNN` with the next available proposal number.

3. Link the GitHub issue from your proposal, and fill in the proposal.

4. Open a pull request with your proposal and solicit feedback from other contributors.

5. Once a maintainer confirms that the proposal is ready for review, the state is updated accordingly. The review period is 7 days, and ends when one of the maintainers marks the proposal as Ready for Implementation, or Deferred.

6. Before the pull request is merged, there should be an implementation ready, either in the same pull request, or a separate one, linked from the proposal.

7. The proposal is considered Approved once the implementation, proposal PRs have been merged, and, if originally disabled by a feature flag, feature flag enabled unconditionally.

If you have any questions, ask in an issue on GitHub.

### Possible review states

- Awaiting Review

- In Review

- Ready for Implementation

- In Preview

- Approved

- Deferred

## Topics

SCO-NNNN: Feature name

Feature abstract – a one sentence summary.

SCO-0001: Generic file providers

Introduce format-agnostic providers to simplify implementing additional file formats beyond JSON and YAML.

SCO-0002: Remove custom key decoders

Remove the custom key decoder feature to fix a flaw and simplify the project

SCO-0003: Allow missing files in file providers

Add an `allowMissing` parameter to file-based providers to handle missing configuration files gracefully.

## See Also

### Contributing

Developing Swift Configuration

Learn about tools and conventions used to develop the Swift Configuration package.

- Proposals
- Overview
- Steps
- Possible review states
- Topics
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/inmemoryprovider

- Configuration
- InMemoryProvider

Structure

# InMemoryProvider

A configuration provider that stores values in memory.

struct InMemoryProvider

InMemoryProvider.swift

## Mentioned in

Using in-memory providers

Configuring applications

Example use cases

## Overview

This provider maintains a static dictionary of configuration values in memory, making it ideal for providing default values, overrides, or test configurations. Values are immutable once the provider is created and never change over time.

## Use cases

The in-memory provider is particularly useful for:

- **Default configurations**: Providing fallback values when other providers don’t have a value

- **Configuration overrides**: Taking precedence over other providers

- **Testing**: Creating predictable configuration states for unit tests

- **Static configurations**: Embedding compile-time configuration values

## Value types

The provider supports all standard configuration value types and automatically handles type validation. Values must match the requested type exactly - no automatic conversion is performed - for example, requesting a `String` value for a key that stores an `Int` value will throw an error.

## Performance characteristics

This provider offers O(1) lookup time and performs no I/O operations. All values are stored in memory.

## Usage

let provider = InMemoryProvider(values: [\
"http.client.user-agent": "Config/1.0 (Test)",\
"http.client.timeout": 15.0,\
"http.secret": ConfigValue("s3cret", isSecret: true),\
"http.version": 2,\
"enabled": true\
])
// Prints all values, redacts "http.secret" automatically.
print(provider)
let config = ConfigReader(provider: provider)
let isEnabled = config.bool(forKey: "enabled", default: false)

To learn more about the in-memory providers, check out Using in-memory providers.

## Topics

### Creating an in-memory provider

[`init(name: String?, values: [AbsoluteConfigKey : ConfigValue])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/inmemoryprovider/init(name:values:))

Creates a new in-memory provider with the specified configuration values.

## Relationships

### Conforms To

- `ConfigProvider`
- `Swift.Copyable`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Built-in providers

`struct EnvironmentVariablesProvider`

A configuration provider that sources values from environment variables.

`struct CommandLineArgumentsProvider`

A configuration provider that sources values from command-line arguments.

`struct FileProvider`

A configuration provider that reads from a file on disk using a configurable snapshot type.

`class ReloadingFileProvider`

A configuration provider that reads configuration from a file on disk with automatic reloading capability.

`struct JSONSnapshot`

A snapshot of configuration values parsed from JSON data.

`class YAMLSnapshot`

A snapshot of configuration values parsed from YAML data.

Using reloading providers

Automatically reload configuration from files when they change.

`struct DirectoryFilesProvider`

A configuration provider that reads values from individual files in a directory.

Learn about the `InMemoryProvider` and `MutableInMemoryProvider` built-in types.

`class MutableInMemoryProvider`

A configuration provider that stores mutable values in memory.

`struct KeyMappingProvider`

A configuration provider that maps all keys before delegating to an upstream provider.

- InMemoryProvider
- Mentioned in
- Overview
- Use cases
- Value types
- Performance characteristics
- Usage
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configuring-libraries

- Configuration
- Configuring libraries

Article

# Configuring libraries

Provide a consistent and flexible way to configure your library.

## Overview

Swift Configuration provides a pattern for configuring libraries that works across various configuration sources: environment variables, JSON files, and remote configuration services.

This guide shows how to adopt this pattern in your library to make it easier to compose in larger applications.

Adopt this pattern in three steps:

1. Define your library’s configuration as a dedicated type (you might already have such a type in your library).

2. Add a convenience method that accepts a `ConfigReader` \- can be an initializer, or a method that updates your configuration.

3. Extract the individual configuration values using the provided reader.

This approach makes your library configurable regardless of the user’s chosen configuration source and composes well with other libraries.

### Define your configuration type

Start by defining a type that encapsulates all the configuration options for your library.

/// Configuration options for a hypothetical HTTPClient.
public struct HTTPClientConfiguration {
/// The timeout for network requests in seconds.
public var timeout: Double

/// The maximum number of concurrent connections.
public var maxConcurrentConnections: Int

/// Base URL for API requests.
public var baseURL: String

/// Whether to enable debug logging.
public var debugLogging: Bool

/// Create a configuration with explicit values.
public init(
timeout: Double = 30.0,
maxConcurrentConnections: Int = 5,
baseURL: String = "https://api.example.com",
debugLogging: Bool = false
) {
self.timeout = timeout
self.maxConcurrentConnections = maxConcurrentConnections
self.baseURL = baseURL
self.debugLogging = debugLogging
}
}

### Add a convenience method

Next, extend your configuration type to provide a method that accepts a `ConfigReader` as a parameter. In the example below, we use an initializer.

extension HTTPClientConfiguration {
/// Creates a new HTTP client configuration using values from the provided reader.
///
/// ## Configuration keys
/// - `timeout` (double, optional, default: `30.0`): The timeout for network requests in seconds.
/// - `maxConcurrentConnections` (int, optional, default: `5`): The maximum number of concurrent connections.
/// - `baseURL` (string, optional, default: `"https://api.example.com"`): Base URL for API requests.
/// - `debugLogging` (bool, optional, default: `false`): Whether to enable debug logging.
///
/// - Parameter config: The config reader to read configuration values from.
public init(config: ConfigReader) {
self.timeout = config.double(forKey: "timeout", default: 30.0)
self.maxConcurrentConnections = config.int(forKey: "maxConcurrentConnections", default: 5)
self.baseURL = config.string(forKey: "baseURL", default: "https://api.example.com")
self.debugLogging = config.bool(forKey: "debugLogging", default: false)
}
}

### Example: Adopting your library

Once you’ve made your library configurable, users can easily configure it from various sources. Here’s how someone might configure your library using environment variables:

import Configuration
import YourHTTPLibrary

// Create a config reader from environment variables.
let config = ConfigReader(provider: EnvironmentVariablesProvider())

// Initialize your library's configuration from a config reader.
let httpConfig = HTTPClientConfiguration(config: config)

// Create your library instance with the configuration.
let httpClient = HTTPClient(configuration: httpConfig)

// Start using your library.
httpClient.get("/users") { response in
// Handle the response.
}

With this approach, users can configure your library by setting environment variables that match your config keys:

# Set configuration for your library through environment variables.
export TIMEOUT=60.0
export MAX_CONCURRENT_CONNECTIONS=10
export BASE_URL="https://api.production.com"
export DEBUG_LOGGING=true

Your library now adapts to the user’s environment without any code changes.

### Working with secrets

Mark configuration values that contain sensitive information as secret to prevent them from being logged:

extension HTTPClientConfiguration {
public init(config: ConfigReader) throws {
self.apiKey = try config.requiredString(forKey: "apiKey", isSecret: true)
// Other configuration...
}
}

Built-in `AccessReporter` types such as `AccessLogger` and `FileAccessLogger` automatically redact secret values to avoid leaking sensitive information.

For more guidance on secrets handling, see Handling secrets correctly. For more configuration guidance, check out Adopting best practices. To understand different access patterns and reader methods, refer to Choosing the access pattern and Choosing reader methods.

## See Also

### Essentials

Configuring applications

Provide flexible and consistent configuration for your application.

Example use cases

Review common use cases with ready-to-copy code samples.

Adopting best practices

Follow these principles to make your code easily configurable and composable with other libraries.

- Configuring libraries
- Overview
- Define your configuration type
- Add a convenience method
- Example: Adopting your library
- Working with secrets
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/yamlsnapshot/configsnapshot-implementations

- Configuration
- YAMLSnapshot
- ConfigSnapshot Implementations

API Collection

# ConfigSnapshot Implementations

## Topics

### Instance Methods

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/yamlsnapshot/init(data:providername:parsingoptions:)

#app-main)

- Configuration
- YAMLSnapshot
- init(data:providerName:parsingOptions:)

Initializer

# init(data:providerName:parsingOptions:)

Inherited from `FileConfigSnapshot.init(data:providerName:parsingOptions:)`.

convenience init(
data: RawSpan,
providerName: String,
parsingOptions: YAMLSnapshot.ParsingOptions
) throws

YAMLSnapshot.swift

## See Also

### Creating a YAML snapshot

`struct ParsingOptions`

Custom input configuration for YAML snapshot creation.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/yamlsnapshot/parsingoptions

- Configuration
- YAMLSnapshot
- YAMLSnapshot.ParsingOptions

Structure

# YAMLSnapshot.ParsingOptions

Custom input configuration for YAML snapshot creation.

struct ParsingOptions

YAMLSnapshot.swift

## Overview

This struct provides configuration options for parsing YAML data into configuration snapshots, including byte decoding and secrets specification.

## Topics

### Initializers

Creates custom input configuration for YAML snapshots.

### Instance Properties

`var bytesDecoder: any ConfigBytesFromStringDecoder`

A decoder of bytes from a string.

A specifier for determining which configuration values should be treated as secrets.

### Type Properties

``static var `default`: YAMLSnapshot.ParsingOptions``

The default custom input configuration.

## Relationships

### Conforms To

- `FileParsingOptions`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Creating a YAML snapshot

`convenience init(data: RawSpan, providerName: String, parsingOptions: YAMLSnapshot.ParsingOptions) throws`

- YAMLSnapshot.ParsingOptions
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configurationtesting/providercompattest

- ConfigurationTesting
- ProviderCompatTest

Structure

# ProviderCompatTest

A comprehensive test suite for validating `ConfigProvider` implementations.

struct ProviderCompatTest

ProviderCompatTest.swift

## Overview

This test suite verifies that configuration providers correctly implement all required functionality including synchronous and asynchronous value retrieval, snapshot operations, and value watching capabilities.

## Usage

Create a test instance with your provider and run the compatibility tests:

let provider = MyCustomProvider()
let test = ProviderCompatTest(provider: provider)
try await test.runTest()

## Required Test Data

The provider under test must be populated with specific test values to ensure comprehensive validation. The required configuration data includes:

\
"string": String("Hello"),\
"other.string": String("Other Hello"),\
"int": Int(42),\
"other.int": Int(24),\
"double": Double(3.14),\
"other.double": Double(2.72),\
"bool": Bool(true),\
"other.bool": Bool(false),\
"bytes": [UInt8,\
"other.bytes": UInt8,\
"stringy.array": String,\
"other.stringy.array": String,\
"inty.array": Int,\
"other.inty.array": Int,\
"doubly.array": Double,\
"other.doubly.array": Double,\
"booly.array": Bool,\
"other.booly.array": Bool,\
"byteChunky.array": [[UInt8]]([.magic, .magic2]),\
"other.byteChunky.array": [[UInt8]]([.magic, .magic2, .magic]),\
]

## Topics

### Structures

`struct TestConfiguration`

Configuration options for customizing test behavior.

### Initializers

`init(provider: any ConfigProvider, configuration: ProviderCompatTest.TestConfiguration)`

Creates a new compatibility test suite.

### Instance Methods

`func runTest() async throws`

Executes the complete compatibility test suite.

## Relationships

### Conforms To

- `Swift.Sendable`
- `Swift.SendableMetatype`

- ProviderCompatTest
- Overview
- Usage
- Required Test Data
- Topics
- Relationships

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/fileconfigsnapshot

- Configuration
- FileConfigSnapshot

Protocol

# FileConfigSnapshot

A protocol for configuration snapshots created from file data.

protocol FileConfigSnapshot : ConfigSnapshot, CustomDebugStringConvertible, CustomStringConvertible

FileProviderSnapshot.swift

## Overview

This protocol extends `ConfigSnapshot` to provide file-specific functionality for creating configuration snapshots from raw file data. Types conforming to this protocol can parse various file formats (such as JSON and YAML) and convert them into configuration values.

Commonly used with `FileProvider` and `ReloadingFileProvider`.

## Implementation

To create a custom file configuration snapshot:

struct MyFormatSnapshot: FileConfigSnapshot {
typealias ParsingOptions = MyParsingOptions

let values: [String: ConfigValue]
let providerName: String

init(data: RawSpan, providerName: String, parsingOptions: MyParsingOptions) throws {
self.providerName = providerName
// Parse the data according to your format
self.values = try parseMyFormat(data, using: parsingOptions)
}
}

The snapshot is responsible for parsing the file data and converting it into a representation of configuration values that can be queried by the configuration system.

## Topics

### Required methods

`init(data: RawSpan, providerName: String, parsingOptions: Self.ParsingOptions) throws`

Creates a new snapshot from file data.

**Required**

`associatedtype ParsingOptions : FileParsingOptions`

The parsing options type used for parsing this snapshot.

### Protocol requirements

`protocol ConfigSnapshot`

An immutable snapshot of a configuration provider’s state.

## Relationships

### Inherits From

- `ConfigSnapshot`
- `Swift.CustomDebugStringConvertible`
- `Swift.CustomStringConvertible`
- `Swift.Sendable`
- `Swift.SendableMetatype`

### Conforming Types

- `JSONSnapshot`
- `YAMLSnapshot`

- FileConfigSnapshot
- Overview
- Implementation
- Topics
- Relationships

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/yamlsnapshot/providername

- Configuration
- YAMLSnapshot
- providerName

Instance Property

# providerName

The name of the provider that created this snapshot.

let providerName: String

YAMLSnapshot.swift

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/yamlsnapshot/customdebugstringconvertible-implementations

- Configuration
- YAMLSnapshot
- CustomDebugStringConvertible Implementations

API Collection

# CustomDebugStringConvertible Implementations

## Topics

### Instance Properties

`var debugDescription: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/yamlsnapshot/customstringconvertible-implementations

- Configuration
- YAMLSnapshot
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/yamlsnapshot/fileconfigsnapshot-implementations

- Configuration
- YAMLSnapshot
- FileConfigSnapshot Implementations

API Collection

# FileConfigSnapshot Implementations

## Topics

### Initializers

`convenience init(data: RawSpan, providerName: String, parsingOptions: YAMLSnapshot.ParsingOptions) throws`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accesslogger/accessreporter-implementations

- Configuration
- AccessLogger
- AccessReporter Implementations

API Collection

# AccessReporter Implementations

## Topics

### Instance Methods

`func report(AccessEvent)`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/jsonsnapshot/init(data:providername:parsingoptions:)

#app-main)

- Configuration
- JSONSnapshot
- init(data:providerName:parsingOptions:)

Initializer

# init(data:providerName:parsingOptions:)

Inherited from `FileConfigSnapshot.init(data:providerName:parsingOptions:)`.

init(
data: RawSpan,
providerName: String,
parsingOptions: JSONSnapshot.ParsingOptions
) throws

JSONSnapshot.swift

## See Also

### Creating a JSON snapshot

`struct ParsingOptions`

Parsing options for JSON snapshot creation.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/jsonsnapshot/customstringconvertible-implementations

- Configuration
- JSONSnapshot
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/jsonsnapshot/parsingoptions

- Configuration
- JSONSnapshot
- JSONSnapshot.ParsingOptions

Structure

# JSONSnapshot.ParsingOptions

Parsing options for JSON snapshot creation.

struct ParsingOptions

JSONSnapshot.swift

## Overview

This struct provides configuration options for parsing JSON data into configuration snapshots, including byte decoding and secrets specification.

## Topics

### Initializers

Creates parsing options for JSON snapshots.

### Instance Properties

`var bytesDecoder: any ConfigBytesFromStringDecoder`

A decoder of bytes from a string.

A specifier for determining which configuration values should be treated as secrets.

### Type Properties

``static var `default`: JSONSnapshot.ParsingOptions``

The default parsing options.

## Relationships

### Conforms To

- `FileParsingOptions`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Creating a JSON snapshot

`init(data: RawSpan, providerName: String, parsingOptions: JSONSnapshot.ParsingOptions) throws`

- JSONSnapshot.ParsingOptions
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/jsonsnapshot/customdebugstringconvertible-implementations

- Configuration
- JSONSnapshot
- CustomDebugStringConvertible Implementations

API Collection

# CustomDebugStringConvertible Implementations

## Topics

### Instance Properties

`var debugDescription: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/reloadingfileprovider/run()

#app-main)

- Configuration
- ReloadingFileProvider
- run()

Instance Method

# run()

Inherited from `Service.run()`.

func run() async throws

ReloadingFileProvider.swift

Available when `Snapshot` conforms to `FileConfigSnapshot`.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/jsonsnapshot/providername

- Configuration
- JSONSnapshot
- providerName

Instance Property

# providerName

The name of the provider that created this snapshot.

let providerName: String

JSONSnapshot.swift

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/jsonsnapshot/fileconfigsnapshot-implementations

- Configuration
- JSONSnapshot
- FileConfigSnapshot Implementations

API Collection

# FileConfigSnapshot Implementations

## Topics

### Initializers

`init(data: RawSpan, providerName: String, parsingOptions: JSONSnapshot.ParsingOptions) throws`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accesslogger/init(logger:level:message:)

#app-main)

- Configuration
- AccessLogger
- init(logger:level:message:)

Initializer

# init(logger:level:message:)

Creates a new access logger that reports configuration access events.

init(
logger: Logger,
level: Logger.Level = .debug,
message: Logger.Message = "Config value accessed"
)

AccessLogger.swift

## Parameters

`logger`

The logger to emit access events to.

`level`

The log level for access events. Defaults to `.debug`.

`message`

The static message text for log entries. Defaults to “Config value accessed”.

## Discussion

let logger = Logger(label: "my.app.config")

// Log at debug level by default
let accessLogger = AccessLogger(logger: logger)

// Customize the log level
let accessLogger = AccessLogger(logger: logger, level: .info)

- init(logger:level:message:)
- Parameters
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/reloadingfileprovider/providername

- Configuration
- ReloadingFileProvider
- providerName

Instance Property

# providerName

The human-readable name of the provider.

let providerName: String

ReloadingFileProvider.swift

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/jsonsnapshot/configsnapshot-implementations

- Configuration
- JSONSnapshot
- ConfigSnapshot Implementations

API Collection

# ConfigSnapshot Implementations

## Topics

### Instance Methods

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/reloadingfileprovider/init(snapshottype:parsingoptions:filepath:allowmissing:pollinterval:logger:metrics:)

#app-main)

- Configuration
- ReloadingFileProvider
- init(snapshotType:parsingOptions:filePath:allowMissing:pollInterval:logger:metrics:)

Initializer

# init(snapshotType:parsingOptions:filePath:allowMissing:pollInterval:logger:metrics:)

Creates a reloading file provider that monitors the specified file path.

convenience init(
snapshotType: Snapshot.Type = Snapshot.self,
parsingOptions: Snapshot.ParsingOptions = .default,
filePath: FilePath,
allowMissing: Bool = false,
pollInterval: Duration = .seconds(15),
logger: Logger = Logger(label: "ReloadingFileProvider"),
metrics: any MetricsFactory = MetricsSystem.factory
) async throws

ReloadingFileProvider.swift

## Parameters

`snapshotType`

The type of snapshot to create from the file contents.

`parsingOptions`

Options used by the snapshot to parse the file data.

`filePath`

The path to the configuration file to monitor.

`allowMissing`

A flag controlling how the provider handles a missing file.

- When `false` (the default), if the file is missing or malformed, throws an error.

- When `true`, if the file is missing, treats it as empty. Malformed files still throw an error.

`pollInterval`

How often to check for file changes.

`logger`

The logger instance to use for this provider.

`metrics`

The metrics factory to use for monitoring provider performance.

## Discussion

## See Also

### Creating a reloading file provider

`convenience init(snapshotType: Snapshot.Type, parsingOptions: Snapshot.ParsingOptions, config: ConfigReader, logger: Logger, metrics: any MetricsFactory) async throws`

Creates a reloading file provider using configuration from a reader.

- init(snapshotType:parsingOptions:filePath:allowMissing:pollInterval:logger:metrics:)
- Parameters
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/reloadingfileprovider/customdebugstringconvertible-implementations

- Configuration
- ReloadingFileProvider
- CustomDebugStringConvertible Implementations

API Collection

# CustomDebugStringConvertible Implementations

## Topics

### Instance Properties

`var debugDescription: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/reloadingfileprovider/customstringconvertible-implementations

- Configuration
- ReloadingFileProvider
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/fileprovider/init(snapshottype:parsingoptions:config:)

#app-main)

- Configuration
- FileProvider
- init(snapshotType:parsingOptions:config:)

Initializer

# init(snapshotType:parsingOptions:config:)

Creates a file provider using a file path from a configuration reader.

init(
snapshotType: Snapshot.Type = Snapshot.self,
parsingOptions: Snapshot.ParsingOptions = .default,
config: ConfigReader
) async throws

FileProvider.swift

## Parameters

`snapshotType`

The type of snapshot to create from the file contents.

`parsingOptions`

Options used by the snapshot to parse the file data.

`config`

A configuration reader that contains the required configuration keys.

## Discussion

This initializer reads the file path from the provided configuration reader and creates a snapshot from that file.

## Configuration keys

- `filePath` (string, required): The path to the configuration file to read.

- `allowMissing` (bool, optional, default: false): A flag controlling how the provider handles a missing file. When `false` (the default), if the file is missing or malformed, throws an error. When `true`, if the file is missing, treats it as empty. Malformed files still throw an error.

## See Also

### Creating a file provider

`init(snapshotType: Snapshot.Type, parsingOptions: Snapshot.ParsingOptions, filePath: FilePath, allowMissing: Bool) async throws`

Creates a file provider that reads from the specified file path.

- init(snapshotType:parsingOptions:config:)
- Parameters
- Discussion
- Configuration keys
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/fileprovider/customstringconvertible-implementations

- Configuration
- FileProvider
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/fileprovider/customdebugstringconvertible-implementations

- Configuration
- FileProvider
- CustomDebugStringConvertible Implementations

API Collection

# CustomDebugStringConvertible Implementations

## Topics

### Instance Properties

`var debugDescription: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/fileprovider/init(snapshottype:parsingoptions:filepath:allowmissing:)

#app-main)

- Configuration
- FileProvider
- init(snapshotType:parsingOptions:filePath:allowMissing:)

Initializer

# init(snapshotType:parsingOptions:filePath:allowMissing:)

Creates a file provider that reads from the specified file path.

init(
snapshotType: Snapshot.Type = Snapshot.self,
parsingOptions: Snapshot.ParsingOptions = .default,
filePath: FilePath,
allowMissing: Bool = false
) async throws

FileProvider.swift

## Parameters

`snapshotType`

The type of snapshot to create from the file contents.

`parsingOptions`

Options used by the snapshot to parse the file data.

`filePath`

The path to the configuration file to read.

`allowMissing`

A flag controlling how the provider handles a missing file.

- When `false` (the default), if the file is missing or malformed, throws an error.

- When `true`, if the file is missing, treats it as empty. Malformed files still throw an error.

## Discussion

This initializer reads the file at the given path and creates a snapshot using the specified snapshot type. The file is read once during initialization.

## See Also

### Creating a file provider

`init(snapshotType: Snapshot.Type, parsingOptions: Snapshot.ParsingOptions, config: ConfigReader) async throws`

Creates a file provider using a file path from a configuration reader.

- init(snapshotType:parsingOptions:filePath:allowMissing:)
- Parameters
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/reloadingfileprovider/configprovider-implementations

- Configuration
- ReloadingFileProvider
- ConfigProvider Implementations

API Collection

# ConfigProvider Implementations

## Topics

### Instance Methods

Creates a new configuration provider where each key is rewritten by the given closure.

Creates a new prefixed configuration provider.

Implements `watchSnapshot` by getting the current snapshot and emitting it immediately.

Implements `watchValue` by getting the current value and emitting it immediately.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/environmentvariablesprovider/init(environmentvariables:secretsspecifier:bytesdecoder:arrayseparator:)

#app-main)

- Configuration
- EnvironmentVariablesProvider
- init(environmentVariables:secretsSpecifier:bytesDecoder:arraySeparator:)

Initializer

# init(environmentVariables:secretsSpecifier:bytesDecoder:arraySeparator:)

Creates a new provider from a custom dictionary of environment variables.

init(
environmentVariables: [String : String],

bytesDecoder: some ConfigBytesFromStringDecoder = .base64,
arraySeparator: Character = ","
)

EnvironmentVariablesProvider.swift

## Parameters

`environmentVariables`

A dictionary of environment variable names and values.

`secretsSpecifier`

Specifies which environment variables should be treated as secrets.

`bytesDecoder`

The decoder used for converting string values to byte arrays.

`arraySeparator`

The character used to separate elements in array values.

## Discussion

This initializer allows you to provide a custom set of environment variables, which is useful for testing or when you want to override specific values.

let customEnvironment = [\
"DATABASE_HOST": "localhost",\
"DATABASE_PORT": "5432",\
"API_KEY": "secret-key"\
]
let provider = EnvironmentVariablesProvider(
environmentVariables: customEnvironment,
secretsSpecifier: .specific(["API_KEY"])
)

## See Also

### Creating an environment variable provider

Creates a new provider that reads from the current process environment.

Creates a new provider that reads from an environment file.

- init(environmentVariables:secretsSpecifier:bytesDecoder:arraySeparator:)
- Parameters
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/context

- Configuration
- AbsoluteConfigKey
- context

Instance Property

# context

Additional context information for this configuration key.

var context: [String : ConfigContextValue]

ConfigKey.swift

## Discussion

Context provides extra information that providers can use to refine lookups or return more specific values. Not all providers use context information.

## See Also

### Inspecting an absolute configuration key

[`var components: [String]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/components)

The hierarchical components that make up this absolute configuration key.

- context
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/commandlineargumentsprovider/customstringconvertible-implementations

- Configuration
- CommandLineArgumentsProvider
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader/watchint(forkey:issecret:fileid:line:updateshandler:)

#app-main)

- Configuration
- ConfigReader
- watchInt(forKey:isSecret:fileID:line:updatesHandler:)

Instance Method

# watchInt(forKey:isSecret:fileID:line:updatesHandler:)

Watches for updates to a config value for the given config key.

forKey key: ConfigKey,
isSecret: Bool = false,
fileID: String = #fileID,
line: UInt = #line,

ConfigReader+methods.swift

## Parameters

`key`

The config key to watch.

`isSecret`

Whether the value should be treated as secret for logging and debugging purposes.

`fileID`

The file ID where this call originates. Used for access reporting.

`line`

The line number where this call originates. Used for access reporting.

`updatesHandler`

A closure that handles an async sequence of updates to the value. The sequence produces `nil` if the value is missing or can’t be converted.

## Return Value

The result produced by the handler.

## Mentioned in

Example use cases

## Discussion

Use this method to observe changes to optional configuration values over time. The handler receives an async sequence that produces the current value whenever it changes, or `nil` if the value is missing or can’t be converted.

try await config.watchInt(forKey: ["server", "port"]) { updates in
for await port in updates {
if let port = port {
print("Server port is: \(port)")
} else {
print("No server port configured")
}
}
}

## See Also

### Watching integer values

Watches for updates to a config value for the given config key with default fallback.

- watchInt(forKey:isSecret:fileID:line:updatesHandler:)
- Parameters
- Return Value
- Mentioned in
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/reloadingfileprovider/service-implementations

- Configuration
- ReloadingFileProvider
- Service Implementations

API Collection

# Service Implementations

## Topics

### Instance Methods

`func run() async throws`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/customstringconvertible-implementations

- Configuration
- ConfigKey
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/init(_:context:)-6vten

-6vten#app-main)

- Configuration
- ConfigKey
- init(\_:context:)

Initializer

# init(\_:context:)

Creates a new configuration key.

init(
_ string: String,
context: [String : ConfigContextValue] = [:]
)

ConfigKey.swift

## Parameters

`string`

The string representation of the key path, for example `"http.timeout"`.

`context`

Additional context information for the key.

## See Also

### Creating a configuration key

[`init([String], context: [String : ConfigContextValue])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/init(_:context:)-9ifez)

- init(\_:context:)
- Parameters
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/environmentvariablesprovider/environmentvalue(forname:)

#app-main)

- Configuration
- EnvironmentVariablesProvider
- environmentValue(forName:)

Instance Method

# environmentValue(forName:)

Returns the raw string value for a specific environment variable name.

EnvironmentVariablesProvider.swift

## Parameters

`name`

The exact name of the environment variable to retrieve.

## Return Value

The string value of the environment variable, or nil if not found.

## Discussion

This method provides direct access to environment variable values by name, without any key transformation or type conversion. It’s useful when you need to access environment variables that don’t follow the standard configuration key naming conventions.

let provider = EnvironmentVariablesProvider()
let path = try provider.environmentValue(forName: "PATH")
let home = try provider.environmentValue(forName: "HOME")

- environmentValue(forName:)
- Parameters
- Return Value
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/environmentvariablesprovider/init(environmentfilepath:allowmissing:secretsspecifier:bytesdecoder:arrayseparator:)

#app-main)

- Configuration
- EnvironmentVariablesProvider
- init(environmentFilePath:allowMissing:secretsSpecifier:bytesDecoder:arraySeparator:)

Initializer

# init(environmentFilePath:allowMissing:secretsSpecifier:bytesDecoder:arraySeparator:)

Creates a new provider that reads from an environment file.

init(
environmentFilePath: FilePath,
allowMissing: Bool = false,

bytesDecoder: some ConfigBytesFromStringDecoder = .base64,
arraySeparator: Character = ","
) async throws

EnvironmentVariablesProvider.swift

## Parameters

`environmentFilePath`

The file system path to the environment file to load.

`allowMissing`

A flag controlling how the provider handles a missing file.

- When `false` (the default), if the file is missing or malformed, throws an error.

- When `true`, if the file is missing, treats it as empty. Malformed files still throw an error.

`secretsSpecifier`

Specifies which environment variables should be treated as secrets.

`bytesDecoder`

The decoder used for converting string values to byte arrays.

`arraySeparator`

The character used to separate elements in array values.

## Discussion

This initializer loads environment variables from an `.env` file at the specified path. The file should contain key-value pairs in the format `KEY=value`, one per line. Comments (lines starting with `#`) and empty lines are ignored.

// Load from a .env file
let provider = try await EnvironmentVariablesProvider(
environmentFilePath: ".env",
allowMissing: true,
secretsSpecifier: .specific(["API_KEY"])
)

## See Also

### Creating an environment variable provider

Creates a new provider that reads from the current process environment.

Creates a new provider from a custom dictionary of environment variables.

- init(environmentFilePath:allowMissing:secretsSpecifier:bytesDecoder:arraySeparator:)
- Parameters
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/environmentvariablesprovider/customstringconvertible-implementations

- Configuration
- EnvironmentVariablesProvider
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/keymappingprovider/init(upstream:keymapper:)

#app-main)

- Configuration
- KeyMappingProvider
- init(upstream:keyMapper:)

Initializer

# init(upstream:keyMapper:)

Creates a new provider.

init(
upstream: Upstream,

)

KeyMappingProvider.swift

## Parameters

`upstream`

The upstream provider to delegate to after mapping.

`mapKey`

A closure to remap configuration keys.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configprovider/prefixkeys(with:)

#app-main)

- Configuration
- ConfigProvider
- prefixKeys(with:)

Instance Method

# prefixKeys(with:)

Creates a new prefixed configuration provider.

ConfigProvider+Operators.swift

## Return Value

A provider which prefixes keys with the given prefix.

## Discussion

- Parameter: prefix: The configuration key to prepend to all configuration keys.

## See Also

### Conveniences

Implements `watchValue` by getting the current value and emitting it immediately.

Implements `watchSnapshot` by getting the current snapshot and emitting it immediately.

Creates a new configuration provider where each key is rewritten by the given closure.

- prefixKeys(with:)
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/environmentvariablesprovider/customdebugstringconvertible-implementations

- Configuration
- EnvironmentVariablesProvider
- CustomDebugStringConvertible Implementations

API Collection

# CustomDebugStringConvertible Implementations

## Topics

### Instance Properties

`var debugDescription: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/fileprovider/configprovider-implementations

- Configuration
- FileProvider
- ConfigProvider Implementations

API Collection

# ConfigProvider Implementations

## Topics

### Instance Properties

`var providerName: String`

### Instance Methods

Creates a new configuration provider where each key is rewritten by the given closure.

Creates a new prefixed configuration provider.

Implements `watchSnapshot` by getting the current snapshot and emitting it immediately.

Implements `watchValue` by getting the current value and emitting it immediately.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/reloadingfileprovider/init(snapshottype:parsingoptions:config:logger:metrics:)

#app-main)

- Configuration
- ReloadingFileProvider
- init(snapshotType:parsingOptions:config:logger:metrics:)

Initializer

# init(snapshotType:parsingOptions:config:logger:metrics:)

Creates a reloading file provider using configuration from a reader.

convenience init(
snapshotType: Snapshot.Type = Snapshot.self,
parsingOptions: Snapshot.ParsingOptions = .default,
config: ConfigReader,
logger: Logger = Logger(label: "ReloadingFileProvider"),
metrics: any MetricsFactory = MetricsSystem.factory
) async throws

ReloadingFileProvider.swift

## Parameters

`snapshotType`

The type of snapshot to create from the file contents.

`parsingOptions`

Options used by the snapshot to parse the file data.

`config`

A configuration reader that contains the required configuration keys.

`logger`

The logger instance to use for this provider.

`metrics`

The metrics factory to use for monitoring provider performance.

## Configuration keys

- `filePath` (string, required): The path to the configuration file to monitor.

- `allowMissing` (bool, optional, default: false): A flag controlling how the provider handles a missing file. When `false` (the default), if the file is missing or malformed, throws an error. When `true`, if the file is missing, treats it as empty. Malformed files still throw an error.

- `pollIntervalSeconds` (int, optional, default: 15): How often to check for file changes in seconds.

## See Also

### Creating a reloading file provider

`convenience init(snapshotType: Snapshot.Type, parsingOptions: Snapshot.ParsingOptions, filePath: FilePath, allowMissing: Bool, pollInterval: Duration, logger: Logger, metrics: any MetricsFactory) async throws`

Creates a reloading file provider that monitors the specified file path.

- init(snapshotType:parsingOptions:config:logger:metrics:)
- Parameters
- Configuration keys
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/equatable-implementations

- Configuration
- ConfigKey
- Equatable Implementations

API Collection

# Equatable Implementations

## Topics

### Operators

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/expressiblebyextendedgraphemeclusterliteral-implementations

- Configuration
- ConfigKey
- ExpressibleByExtendedGraphemeClusterLiteral Implementations

API Collection

# ExpressibleByExtendedGraphemeClusterLiteral Implementations

## Topics

### Initializers

`init(unicodeScalarLiteral: Self.ExtendedGraphemeClusterLiteralType)`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/comparable-implementations

- Configuration
- ConfigKey
- Comparable Implementations

API Collection

# Comparable Implementations

## Topics

### Operators

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/init(_:context:)-9ifez

-9ifez#app-main)

- Configuration
- ConfigKey
- init(\_:context:)

Initializer

# init(\_:context:)

Creates a new configuration key.

init(
_ components: [String],
context: [String : ConfigContextValue] = [:]
)

ConfigKey.swift

## Parameters

`components`

The hierarchical components that make up the key path.

`context`

Additional context information for the key.

## See Also

### Creating a configuration key

[`init(String, context: [String : ConfigContextValue])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/init(_:context:)-6vten)

- init(\_:context:)
- Parameters
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/keymappingprovider/customdebugstringconvertible-implementations

- Configuration
- KeyMappingProvider
- CustomDebugStringConvertible Implementations

API Collection

# CustomDebugStringConvertible Implementations

## Topics

### Instance Properties

`var debugDescription: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/commandlineargumentsprovider/init(arguments:secretsspecifier:bytesdecoder:)

#app-main)

- Configuration
- CommandLineArgumentsProvider
- init(arguments:secretsSpecifier:bytesDecoder:)

Initializer

# init(arguments:secretsSpecifier:bytesDecoder:)

Creates a new CLI provider with the provided arguments.

init(
arguments: [String] = CommandLine.arguments,

bytesDecoder: some ConfigBytesFromStringDecoder = .base64
)

CommandLineArgumentsProvider.swift

## Parameters

`arguments`

The command-line arguments to parse.

`secretsSpecifier`

Specifies which CLI arguments should be treated as secret.

`bytesDecoder`

The decoder used for converting string values into bytes.

## Discussion

// Uses the current process's arguments.
let provider = CommandLineArgumentsProvider()
// Uses custom arguments.
let provider = CommandLineArgumentsProvider(arguments: ["program", "--test", "--port", "8089"])

- init(arguments:secretsSpecifier:bytesDecoder:)
- Parameters
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configbytesfromhexstringdecoder/configbytesfromstringdecoder-implementations

- Configuration
- ConfigBytesFromHexStringDecoder
- ConfigBytesFromStringDecoder Implementations

API Collection

# ConfigBytesFromStringDecoder Implementations

## Topics

### Type Properties

`static var hex: ConfigBytesFromHexStringDecoder`

A decoder that interprets string values as hexadecimal-encoded data.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/mutableinmemoryprovider/init(name:initialvalues:)

#app-main)

- Configuration
- MutableInMemoryProvider
- init(name:initialValues:)

Initializer

# init(name:initialValues:)

Creates a new mutable in-memory provider with the specified initial values.

init(
name: String? = nil,
initialValues: [AbsoluteConfigKey : ConfigValue]
)

MutableInMemoryProvider.swift

## Parameters

`name`

An optional name for the provider, used in debugging and logging.

`initialValues`

A dictionary mapping absolute configuration keys to their initial values.

## Discussion

This initializer takes a dictionary of absolute configuration keys mapped to their initial values. The provider can be modified after creation using the `setValue(_:forKey:)` methods.

let key1 = AbsoluteConfigKey(components: ["database", "host"], context: [:])
let key2 = AbsoluteConfigKey(components: ["database", "port"], context: [:])

let provider = MutableInMemoryProvider(
name: "dynamic-config",
initialValues: [\
key1: "localhost",\
key2: 5432\
]
)

// Later, update values dynamically
provider.setValue("production-db", forKey: key1)

- init(name:initialValues:)
- Parameters
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/expressiblebyarrayliteral-implementations

- Configuration
- ConfigKey
- ExpressibleByArrayLiteral Implementations

API Collection

# ExpressibleByArrayLiteral Implementations

## Topics

### Initializers

`init(arrayLiteral: String...)`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/environmentvariablesprovider/configprovider-implementations

- Configuration
- EnvironmentVariablesProvider
- ConfigProvider Implementations

API Collection

# ConfigProvider Implementations

## Topics

### Instance Properties

`var providerName: String`

### Instance Methods

Creates a new configuration provider where each key is rewritten by the given closure.

Creates a new prefixed configuration provider.

Implements `watchSnapshot` by getting the current snapshot and emitting it immediately.

Implements `watchValue` by getting the current value and emitting it immediately.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/context

- Configuration
- ConfigKey
- context

Instance Property

# context

Additional context information for this configuration key.

var context: [String : ConfigContextValue]

ConfigKey.swift

## Discussion

Context provides extra information that providers can use to refine lookups or return more specific values. Not all providers use context information.

## See Also

### Inspecting a configuration key

[`var components: [String]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/components)

The hierarchical components that make up this configuration key.

- context
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessreporter/report(_:)

#app-main)

- Configuration
- AccessReporter
- report(\_:)

Instance Method

# report(\_:)

Processes a configuration access event.

func report(_ event: AccessEvent)

AccessReporter.swift

**Required**

## Parameters

`event`

The configuration access event to process.

## Discussion

This method is called whenever a configuration value is accessed through a `ConfigReader` or a `ConfigSnapshotReader`. Implementations should handle events efficiently as they may be called frequently.

- report(\_:)
- Parameters
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/commandlineargumentsprovider/customdebugstringconvertible-implementations

- Configuration
- CommandLineArgumentsProvider
- CustomDebugStringConvertible Implementations

API Collection

# CustomDebugStringConvertible Implementations

## Topics

### Instance Properties

`var debugDescription: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/doublearray(_:)

#app-main)

- Configuration
- ConfigContent
- ConfigContent.doubleArray(\_:)

Case

# ConfigContent.doubleArray(\_:)

An array of double values.

case doubleArray([Double])

ConfigProvider.swift

## See Also

### Types of configuration content

`case string(String)`

A string value.

[`case stringArray([String])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/stringarray(_:))

An array of string values.

`case bool(Bool)`

A Boolean value.

[`case boolArray([Bool])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/boolarray(_:))

An array of Boolean value.

`case int(Int)`

An integer value.

[`case intArray([Int])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/intarray(_:))

An array of integer values.

`case double(Double)`

A double value.

[`case bytes([UInt8])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytes(_:))

An array of bytes.

[`case byteChunkArray([[UInt8]])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytechunkarray(_:))

An array of byte arrays.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontextvalue/expressiblebyextendedgraphemeclusterliteral-implementations

- Configuration
- ConfigContextValue
- ExpressibleByExtendedGraphemeClusterLiteral Implementations

API Collection

# ExpressibleByExtendedGraphemeClusterLiteral Implementations

## Topics

### Initializers

`init(unicodeScalarLiteral: Self.ExtendedGraphemeClusterLiteralType)`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/secretsspecifier/specific(_:)

#app-main)

- Configuration
- SecretsSpecifier
- SecretsSpecifier.specific(\_:)

Case

# SecretsSpecifier.specific(\_:)

The library treats the specified keys as secrets.

SecretsSpecifier.swift

## Parameters

`keys`

The set of keys that should be treated as secrets.

## Discussion

Use this case when you have a known set of keys that contain sensitive information. All other keys will be treated as non-secret.

## See Also

### Types of specifiers

`case all`

The library treats all configuration values as secrets.

The library determines the secret status dynamically by evaluating each key-value pair.

`case none`

The library treats no configuration values as secrets.

- SecretsSpecifier.specific(\_:)
- Parameters
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/fileconfigsnapshot/init(data:providername:parsingoptions:)

# An unknown error occurred.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/directoryfilesprovider/init(directorypath:allowmissing:secretsspecifier:arrayseparator:)

#app-main)

- Configuration
- DirectoryFilesProvider
- init(directoryPath:allowMissing:secretsSpecifier:arraySeparator:)

Initializer

# init(directoryPath:allowMissing:secretsSpecifier:arraySeparator:)

Creates a new provider that reads files from a directory.

init(
directoryPath: FilePath,
allowMissing: Bool = false,

arraySeparator: Character = ","
) async throws

DirectoryFilesProvider.swift

## Parameters

`directoryPath`

The file system path to the directory containing configuration files.

`allowMissing`

A flag controlling how the provider handles a missing directory.

- When `false`, if the directory is missing, throws an error.

- When `true`, if the directory is missing, treats it as empty.

`secretsSpecifier`

Specifies which values should be treated as secrets.

`arraySeparator`

The character used to separate elements in array values.

## Discussion

This initializer scans the specified directory and loads all regular files as configuration values. Subdirectories are not traversed. Hidden files (starting with a dot) are skipped.

// Load configuration from a directory
let provider = try await DirectoryFilesProvider(
directoryPath: "/run/secrets"
)

- init(directoryPath:allowMissing:secretsSpecifier:arraySeparator:)
- Parameters
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configtype/string

- Configuration
- ConfigType
- ConfigType.string

Case

# ConfigType.string

A string value.

case string

ConfigProvider.swift

## See Also

### Types of configuration content

`case stringArray`

An array of string values.

`case bool`

A Boolean value.

`case boolArray`

An array of Boolean values.

`case int`

An integer value.

`case intArray`

An array of integer values.

`case double`

A double value.

`case doubleArray`

An array of double values.

`case bytes`

An array of bytes.

`case byteChunkArray`

An array of byte chunks.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/string(_:)

#app-main)

- Configuration
- ConfigContent
- ConfigContent.string(\_:)

Case

# ConfigContent.string(\_:)

A string value.

case string(String)

ConfigProvider.swift

## See Also

### Types of configuration content

[`case stringArray([String])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/stringarray(_:))

An array of string values.

`case bool(Bool)`

A Boolean value.

[`case boolArray([Bool])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/boolarray(_:))

An array of Boolean value.

`case int(Int)`

An integer value.

[`case intArray([Int])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/intarray(_:))

An array of integer values.

`case double(Double)`

A double value.

[`case doubleArray([Double])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/doublearray(_:))

An array of double values.

[`case bytes([UInt8])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytes(_:))

An array of bytes.

[`case byteChunkArray([[UInt8]])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytechunkarray(_:))

An array of byte arrays.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/keymappingprovider/configprovider-implementations

- Configuration
- KeyMappingProvider
- ConfigProvider Implementations

API Collection

# ConfigProvider Implementations

## Topics

### Instance Properties

`var providerName: String`

### Instance Methods

Creates a new configuration provider where each key is rewritten by the given closure.

Creates a new prefixed configuration provider.

Implements `watchSnapshot` by getting the current snapshot and emitting it immediately.

Implements `watchValue` by getting the current value and emitting it immediately.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/boolarray(_:)

#app-main)

- Configuration
- ConfigContent
- ConfigContent.boolArray(\_:)

Case

# ConfigContent.boolArray(\_:)

An array of Boolean value.

case boolArray([Bool])

ConfigProvider.swift

## See Also

### Types of configuration content

`case string(String)`

A string value.

[`case stringArray([String])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/stringarray(_:))

An array of string values.

`case bool(Bool)`

A Boolean value.

`case int(Int)`

An integer value.

[`case intArray([Int])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/intarray(_:))

An array of integer values.

`case double(Double)`

A double value.

[`case doubleArray([Double])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/doublearray(_:))

An array of double values.

[`case bytes([UInt8])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytes(_:))

An array of bytes.

[`case byteChunkArray([[UInt8]])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytechunkarray(_:))

An array of byte arrays.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent/init(metadata:providerresults:conversionerror:result:)

#app-main)

- Configuration
- AccessEvent
- init(metadata:providerResults:conversionError:result:)

Initializer

# init(metadata:providerResults:conversionError:result:)

Creates a configuration access event.

init(
metadata: AccessEvent.Metadata,
providerResults: [AccessEvent.ProviderResult],
conversionError: (any Error)? = nil,

AccessReporter.swift

## Parameters

`metadata`

Metadata describing the access operation.

`providerResults`

The results from each provider queried.

`conversionError`

An error that occurred when converting the raw config value into another type, for example `RawRepresentable`.

`result`

The final outcome of the access operation.

## See Also

### Creating an access event

`struct Metadata`

Metadata describing the configuration access operation.

`struct ProviderResult`

The result of a configuration lookup from a specific provider.

- init(metadata:providerResults:conversionError:result:)
- Parameters
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/mutableinmemoryprovider/setvalue(_:forkey:)

#app-main)

- Configuration
- MutableInMemoryProvider
- setValue(\_:forKey:)

Instance Method

# setValue(\_:forKey:)

Updates the stored value for the specified configuration key.

func setValue(
_ value: ConfigValue?,
forKey key: AbsoluteConfigKey
)

MutableInMemoryProvider.swift

## Parameters

`value`

The new configuration value, or `nil` to remove the value entirely.

`key`

The absolute configuration key to update.

## Discussion

This method atomically updates the value and notifies all active watchers of the change. If the new value is the same as the existing value, no notification is sent.

let provider = MutableInMemoryProvider(initialValues: [:])
let key = AbsoluteConfigKey(components: ["api", "enabled"], context: [:])

// Set a new value
provider.setValue(true, forKey: key)

// Remove a value
provider.setValue(nil, forKey: key)

- setValue(\_:forKey:)
- Parameters
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/fileparsingoptions/default

- Configuration
- FileParsingOptions
- default

Type Property

# default

The default instance of this options type.

static var `default`: Self { get }

FileProviderSnapshot.swift

**Required**

## Discussion

This property provides a default configuration that can be used when no parsing options are specified.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/environmentvariablesprovider/init(secretsspecifier:bytesdecoder:arrayseparator:)

#app-main)

- Configuration
- EnvironmentVariablesProvider
- init(secretsSpecifier:bytesDecoder:arraySeparator:)

Initializer

# init(secretsSpecifier:bytesDecoder:arraySeparator:)

Creates a new provider that reads from the current process environment.

init(

bytesDecoder: some ConfigBytesFromStringDecoder = .base64,
arraySeparator: Character = ","
)

EnvironmentVariablesProvider.swift

## Parameters

`secretsSpecifier`

Specifies which environment variables should be treated as secrets.

`bytesDecoder`

The decoder used for converting string values to byte arrays.

`arraySeparator`

The character used to separate elements in array values.

## Discussion

This initializer creates a provider that sources configuration values from the environment variables of the current process.

// Basic usage
let provider = EnvironmentVariablesProvider()

// With secret handling
let provider = EnvironmentVariablesProvider(
secretsSpecifier: .specific(["API_KEY", "DATABASE_PASSWORD"])
)

## See Also

### Creating an environment variable provider

Creates a new provider from a custom dictionary of environment variables.

Creates a new provider that reads from an environment file.

- init(secretsSpecifier:bytesDecoder:arraySeparator:)
- Parameters
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/expressiblebystringliteral-implementations

- Configuration
- ConfigKey
- ExpressibleByStringLiteral Implementations

API Collection

# ExpressibleByStringLiteral Implementations

## Topics

### Initializers

`init(extendedGraphemeClusterLiteral: Self.StringLiteralType)`

`init(stringLiteral: String)`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/components

- Configuration
- ConfigKey
- components

Instance Property

# components

The hierarchical components that make up this configuration key.

var components: [String]

ConfigKey.swift

## Discussion

Each component represents a level in the configuration hierarchy. For example, `["database", "connection", "timeout"]` represents a three-level nested key.

## See Also

### Inspecting a configuration key

[`var context: [String : ConfigContextValue]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configkey/context)

Additional context information for this configuration key.

- components
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configupdatesasyncsequence/init(_:)

#app-main)

- Configuration
- ConfigUpdatesAsyncSequence
- init(\_:)

Initializer

# init(\_:)

Creates a new concrete async sequence wrapping the provided existential sequence.

AsyncSequences.swift

## Parameters

`upstream`

The async sequence to wrap.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/foundation/uuid

- Configuration
- Foundation
- UUID

Extended Structure

# UUID

ConfigurationFoundation

extension UUID

## Topics

## Relationships

### Conforms To

- `ExpressibleByConfigString`
- `Swift.Copyable`
- `Swift.CustomStringConvertible`

- UUID
- Topics
- Relationships

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/mutableinmemoryprovider/customstringconvertible-implementations

- Configuration
- MutableInMemoryProvider
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configbytesfrombase64stringdecoder/init()

#app-main)

- Configuration
- ConfigBytesFromBase64StringDecoder
- init()

Initializer

# init()

Creates a new base64 decoder.

init()

ConfigBytesFromStringDecoder.swift

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/commandlineargumentsprovider/configprovider-implementations

- Configuration
- CommandLineArgumentsProvider
- ConfigProvider Implementations

API Collection

# ConfigProvider Implementations

## Topics

### Instance Properties

`var providerName: String`

### Instance Methods

Creates a new configuration provider where each key is rewritten by the given closure.

Creates a new prefixed configuration provider.

Implements `watchSnapshot` by getting the current snapshot and emitting it immediately.

Implements `watchValue` by getting the current value and emitting it immediately.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configvalue/customstringconvertible-implementations

- Configuration
- ConfigValue
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader/string(forkey:as:issecret:fileid:line:)-4oust

-4oust#app-main)

- Configuration
- ConfigReader
- string(forKey:as:isSecret:fileID:line:)

Instance Method

# string(forKey:as:isSecret:fileID:line:)

Synchronously gets a config value for the given config key, converting from string.

forKey key: ConfigKey,
as type: Value.Type = Value.self,
isSecret: Bool = false,
fileID: String = #fileID,
line: UInt = #line

ConfigReader+methods.swift

## Parameters

`key`

The config key to look up.

`type`

The type to convert the string value to.

`isSecret`

Whether the value should be treated as secret for logging and debugging purposes.

`fileID`

The file ID where this call originates. Used for access reporting.

`line`

The line number where this call originates. Used for access reporting.

## Return Value

The value converted to the expected type if found and convertible, otherwise `nil`.

## Discussion

Use this method to retrieve configuration values that can be converted from strings, such as custom types conforming to string conversion protocols. If the value doesn’t exist or can’t be converted to the expected type, the method returns `nil`.

let serverMode = config.string(forKey: ["server", "mode"], as: ServerMode.self)

## See Also

### Synchronously reading string values

Synchronously gets a config value for the given config key.

Synchronously gets a config value for the given config key, with a default fallback.

Synchronously gets a config value for the given config key with default fallback, converting from string.

- string(forKey:as:isSecret:fileID:line:)
- Parameters
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytes(_:)

#app-main)

- Configuration
- ConfigContent
- ConfigContent.bytes(\_:)

Case

# ConfigContent.bytes(\_:)

An array of bytes.

case bytes([UInt8])

ConfigProvider.swift

## See Also

### Types of configuration content

`case string(String)`

A string value.

[`case stringArray([String])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/stringarray(_:))

An array of string values.

`case bool(Bool)`

A Boolean value.

[`case boolArray([Bool])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/boolarray(_:))

An array of Boolean value.

`case int(Int)`

An integer value.

[`case intArray([Int])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/intarray(_:))

An array of integer values.

`case double(Double)`

A double value.

[`case doubleArray([Double])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/doublearray(_:))

An array of double values.

[`case byteChunkArray([[UInt8]])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytechunkarray(_:))

An array of byte arrays.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configvalue/content

- Configuration
- ConfigValue
- content

Instance Property

# content

The configuration content.

var content: ConfigContent

ConfigProvider.swift

## See Also

### Inspecting a config value

`var isSecret: Bool`

Whether this value contains sensitive information that should not be logged.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader/watchsnapshot(fileid:line:updateshandler:)

#app-main)

- Configuration
- ConfigReader
- watchSnapshot(fileID:line:updatesHandler:)

Instance Method

# watchSnapshot(fileID:line:updatesHandler:)

Watches the configuration for changes.

fileID: String = #fileID,
line: UInt = #line,

ConfigSnapshotReader.swift

## Parameters

`fileID`

The file where this method is called from.

`line`

The line where this method is called from.

`updatesHandler`

A closure that receives an async sequence of `ConfigSnapshotReader` instances.

## Return Value

The value returned by the handler.

## Discussion

This method watches the configuration for changes and provides a stream of snapshots to the handler closure. Each snapshot represents the configuration state at a specific point in time.

try await config.watchSnapshot { snapshots in
for await snapshot in snapshots {
// Process each new configuration snapshot
let cert = snapshot.string(forKey: "cert")
let privateKey = snapshot.string(forKey: "privateKey")
// Ensures that both values are coming from the same underlying snapshot and that a provider
// didn't change its internal state between the two `string(...)` calls.
let newCert = MyCert(cert: cert, privateKey: privateKey)
print("Certificate was updated: \(newCert.redactedDescription)")
}
}

## See Also

### Reading from a snapshot

Returns a snapshot of the current configuration state.

- watchSnapshot(fileID:line:updatesHandler:)
- Parameters
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/mutableinmemoryprovider/configprovider-implementations

- Configuration
- MutableInMemoryProvider
- ConfigProvider Implementations

API Collection

# ConfigProvider Implementations

## Topics

### Instance Properties

`var providerName: String`

### Instance Methods

Creates a new configuration provider where each key is rewritten by the given closure.

Creates a new prefixed configuration provider.

Implements `watchSnapshot` by getting the current snapshot and emitting it immediately.

Implements `watchValue` by getting the current value and emitting it immediately.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configvalue/expressiblebybooleanliteral-implementations

- Configuration
- ConfigValue
- ExpressibleByBooleanLiteral Implementations

API Collection

# ExpressibleByBooleanLiteral Implementations

## Topics

### Initializers

`init(booleanLiteral: Bool)`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/directoryfilesprovider/configprovider-implementations

- Configuration
- DirectoryFilesProvider
- ConfigProvider Implementations

API Collection

# ConfigProvider Implementations

## Topics

### Instance Properties

`var providerName: String`

### Instance Methods

Creates a new configuration provider where each key is rewritten by the given closure.

Creates a new prefixed configuration provider.

Implements `watchSnapshot` by getting the current snapshot and emitting it immediately.

Implements `watchValue` by getting the current value and emitting it immediately.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/int(_:)

#app-main)

- Configuration
- ConfigContent
- ConfigContent.int(\_:)

Case

# ConfigContent.int(\_:)

An integer value.

case int(Int)

ConfigProvider.swift

## See Also

### Types of configuration content

`case string(String)`

A string value.

[`case stringArray([String])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/stringarray(_:))

An array of string values.

`case bool(Bool)`

A Boolean value.

[`case boolArray([Bool])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/boolarray(_:))

An array of Boolean value.

[`case intArray([Int])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/intarray(_:))

An array of integer values.

`case double(Double)`

A double value.

[`case doubleArray([Double])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/doublearray(_:))

An array of double values.

[`case bytes([UInt8])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytes(_:))

An array of bytes.

[`case byteChunkArray([[UInt8]])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytechunkarray(_:))

An array of byte arrays.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/secretsspecifier/none

- Configuration
- SecretsSpecifier
- SecretsSpecifier.none

Case

# SecretsSpecifier.none

The library treats no configuration values as secrets.

case none

SecretsSpecifier.swift

## Discussion

Use this case when the provider handles only non-sensitive configuration data that can be safely logged or displayed.

## See Also

### Types of specifiers

`case all`

The library treats all configuration values as secrets.

The library treats the specified keys as secrets.

The library determines the secret status dynamically by evaluating each key-value pair.

- SecretsSpecifier.none
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytechunkarray(_:)

#app-main)

- Configuration
- ConfigContent
- ConfigContent.byteChunkArray(\_:)

Case

# ConfigContent.byteChunkArray(\_:)

An array of byte arrays.

case byteChunkArray([[UInt8]])

ConfigProvider.swift

## See Also

### Types of configuration content

`case string(String)`

A string value.

[`case stringArray([String])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/stringarray(_:))

An array of string values.

`case bool(Bool)`

A Boolean value.

[`case boolArray([Bool])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/boolarray(_:))

An array of Boolean value.

`case int(Int)`

An integer value.

[`case intArray([Int])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/intarray(_:))

An array of integer values.

`case double(Double)`

A double value.

[`case doubleArray([Double])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/doublearray(_:))

An array of double values.

[`case bytes([UInt8])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytes(_:))

An array of bytes.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configvalue/issecret

- Configuration
- ConfigValue
- isSecret

Instance Property

# isSecret

Whether this value contains sensitive information that should not be logged.

var isSecret: Bool

ConfigProvider.swift

## See Also

### Inspecting a config value

`var content: ConfigContent`

The configuration content.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configbytesfromhexstringdecoder/init()

#app-main)

- Configuration
- ConfigBytesFromHexStringDecoder
- init()

Initializer

# init()

Creates a new hexadecimal decoder.

init()

ConfigBytesFromStringDecoder.swift

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontextvalue/expressiblebybooleanliteral-implementations

- Configuration
- ConfigContextValue
- ExpressibleByBooleanLiteral Implementations

API Collection

# ExpressibleByBooleanLiteral Implementations

## Topics

### Initializers

`init(booleanLiteral: Bool)`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent/result

- Configuration
- AccessEvent
- result

Instance Property

# result

The final outcome of the configuration access operation.

AccessReporter.swift

## Discussion

## See Also

### Inspecting an access event

`var conversionError: (any Error)?`

An error that occurred when converting the raw config value into another type, for example `RawRepresentable`.

`var metadata: AccessEvent.Metadata`

Metadata that describes the configuration access operation.

[`var providerResults: [AccessEvent.ProviderResult]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent/providerresults)

The results from each configuration provider that was queried.

- result
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshotreader/scoped(to:)

#app-main)

- Configuration
- ConfigSnapshotReader
- scoped(to:)

Instance Method

# scoped(to:)

Returns a scoped snapshot reader by appending the provided key to the current key prefix.

ConfigSnapshotReader.swift

## Parameters

`configKey`

The key to append to the current key prefix.

## Return Value

A reader for accessing scoped values.

## Discussion

Use this method to create a reader that accesses a subset of the configuration.

let httpConfig = snapshotReader.scoped(to: ["client", "http"])
let timeout = httpConfig.int(forKey: "timeout") // Reads from "client.http.timeout" in the snapshot

- scoped(to:)
- Parameters
- Return Value
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/broadcastingaccessreporter/accessreporter-implementations

- Configuration
- BroadcastingAccessReporter
- AccessReporter Implementations

API Collection

# AccessReporter Implementations

## Topics

### Instance Methods

`func report(AccessEvent)`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshotreader/string(forkey:as:issecret:fileid:line:)-7bpif

-7bpif#app-main)

- Configuration
- ConfigSnapshotReader
- string(forKey:as:isSecret:fileID:line:)

Instance Method

# string(forKey:as:isSecret:fileID:line:)

Synchronously gets a config value for the given config key, converting from string.

forKey key: ConfigKey,
as type: Value.Type = Value.self,
isSecret: Bool = false,
fileID: String = #fileID,
line: UInt = #line

ConfigSnapshotReader+methods.swift

## Parameters

`key`

The config key to look up.

`type`

The type to convert the string value to.

`isSecret`

Whether the value should be treated as secret for logging and debugging purposes.

`fileID`

The file ID where this call originates. Used for access reporting.

`line`

The line number where this call originates. Used for access reporting.

## Return Value

The value converted to the expected type if found and convertible, otherwise `nil`.

## Discussion

Use this method to retrieve configuration values that can be converted from strings, such as custom types conforming to string conversion protocols. If the value doesn’t exist or can’t be converted to the expected type, the method returns `nil`.

let serverMode = snapshot.string(forKey: ["server", "mode"], as: ServerMode.self)

## See Also

### Synchronously reading string values

Synchronously gets a config value for the given config key.

Synchronously gets a config value for the given config key, with a default fallback.

Synchronously gets a config value for the given config key with default fallback, converting from string.

- string(forKey:as:isSecret:fileID:line:)
- Parameters
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/customstringconvertible-implementations

- Configuration
- AbsoluteConfigKey
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/keymappingprovider/customstringconvertible-implementations

- Configuration
- KeyMappingProvider
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontextvalue/bool(_:)

#app-main)

- Configuration
- ConfigContextValue
- ConfigContextValue.bool(\_:)

Case

# ConfigContextValue.bool(\_:)

A Boolean value.

case bool(Bool)

ConfigContext.swift

## See Also

### Configuration context values

`case string(String)`

A string value.

`case int(Int)`

An integer value.

`case double(Double)`

A floating point value.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader-fetch

- Configuration
- ConfigReader
- Asynchronously fetching values

API Collection

# Asynchronously fetching values

## Topics

### Asynchronously fetching string values

Asynchronously fetches a config value for the given config key.

Asynchronously fetches a config value for the given config key, with a default fallback.

Asynchronously fetches a config value for the given config key, converting from string.

Asynchronously fetches a config value for the given config key with default fallback, converting from string.

### Asynchronously fetching lists of string values

Asynchronously fetches an array of config values for the given config key, converting from strings.

Asynchronously fetches an array of config values for the given config key with default fallback, converting from strings.

### Asynchronously fetching required string values

Asynchronously fetches a required config value for the given config key, throwing an error if it’s missing.

Asynchronously fetches a required config value for the given config key, converting from string.

### Asynchronously fetching required lists of string values

Asynchronously fetches a required array of config values for the given config key, converting from strings.

### Asynchronously fetching Boolean values

### Asynchronously fetching required Boolean values

### Asynchronously fetching lists of Boolean values

### Asynchronously fetching required lists of Boolean values

### Asynchronously fetching integer values

### Asynchronously fetching required integer values

### Asynchronously fetching lists of integer values

### Asynchronously fetching required lists of integer values

### Asynchronously fetching double values

### Asynchronously fetching required double values

### Asynchronously fetching lists of double values

### Asynchronously fetching required lists of double values

### Asynchronously fetching bytes

### Asynchronously fetching required bytes

### Asynchronously fetching lists of byte chunks

### Asynchronously fetching required lists of byte chunks

## See Also

### Reading from a snapshot

Returns a snapshot of the current configuration state.

Watches the configuration for changes.

- Asynchronously fetching values
- Topics
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader-watch

- Configuration
- ConfigReader
- Watching values

API Collection

# Watching values

## Topics

### Watching string values

Watches for updates to a config value for the given config key.

Watches for updates to a config value for the given config key, converting from string.

Watches for updates to a config value for the given config key with default fallback.

Watches for updates to a config value for the given config key with default fallback, converting from string.

### Watching required string values

Watches for updates to a required config value for the given config key.

Watches for updates to a required config value for the given config key, converting from string.

### Watching lists of string values

Watches for updates to an array of config values for the given config key, converting from strings.

Watches for updates to an array of config values for the given config key with default fallback, converting from strings.

### Watching required lists of string values

Watches for updates to a required array of config values for the given config key, converting from strings.

### Watching Boolean values

### Watching required Boolean values

### Watching lists of Boolean values

### Watching required lists of Boolean values

### Watching integer values

### Watching required integer values

### Watching lists of integer values

### Watching required lists of integer values

### Watching double values

### Watching required double values

### Watching lists of double values

### Watching required lists of double values

### Watching bytes

### Watching required bytes

### Watching lists of byte chunks

### Watching required lists of byte chunks

## See Also

### Reading from a snapshot

Returns a snapshot of the current configuration state.

Watches the configuration for changes.

- Watching values
- Topics
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/yamlsnapshot/parsingoptions/init(bytesdecoder:secretsspecifier:)

#app-main)

- Configuration
- YAMLSnapshot
- YAMLSnapshot.ParsingOptions
- init(bytesDecoder:secretsSpecifier:)

Initializer

# init(bytesDecoder:secretsSpecifier:)

Creates custom input configuration for YAML snapshots.

init(
bytesDecoder: some ConfigBytesFromStringDecoder = .base64,

)

YAMLSnapshot.swift

## Parameters

`bytesDecoder`

The decoder to use for converting string values to byte arrays.

`secretsSpecifier`

The specifier for identifying secret values.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshotreader/string(forkey:as:issecret:default:fileid:line:)-2mphx

-2mphx#app-main)

- Configuration
- ConfigSnapshotReader
- string(forKey:as:isSecret:default:fileID:line:)

Instance Method

# string(forKey:as:isSecret:default:fileID:line:)

Synchronously gets a config value for the given config key with default fallback, converting from string.

forKey key: ConfigKey,
as type: Value.Type = Value.self,
isSecret: Bool = false,
default defaultValue: Value,
fileID: String = #fileID,
line: UInt = #line

ConfigSnapshotReader+methods.swift

## Parameters

`key`

The config key to look up.

`type`

The type to convert the string value to.

`isSecret`

Whether the value should be treated as secret for logging and debugging purposes.

`defaultValue`

The fallback value returned when the config value is missing or invalid.

`fileID`

The file ID where this call originates. Used for access reporting.

`line`

The line number where this call originates. Used for access reporting.

## Return Value

The config value if found and convertible, otherwise the default value.

## Discussion

Use this method when you need a guaranteed non-nil result for string-convertible types. If the configuration value is missing or can’t be converted to the expected type, the default value is returned instead.

let serverMode = snapshot.string(forKey: ["server", "mode"], as: ServerMode.self, default: .production)

## See Also

### Synchronously reading string values

Synchronously gets a config value for the given config key.

Synchronously gets a config value for the given config key, with a default fallback.

Synchronously gets a config value for the given config key, converting from string.

- string(forKey:as:isSecret:default:fileID:line:)
- Parameters
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent/conversionerror

- Configuration
- AccessEvent
- conversionError

Instance Property

# conversionError

An error that occurred when converting the raw config value into another type, for example `RawRepresentable`.

var conversionError: (any Error)?

AccessReporter.swift

## See Also

### Inspecting an access event

The final outcome of the configuration access operation.

`var metadata: AccessEvent.Metadata`

Metadata that describes the configuration access operation.

[`var providerResults: [AccessEvent.ProviderResult]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent/providerresults)

The results from each configuration provider that was queried.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configbytesfromstringdecoder/decode(_:)

#app-main)

- Configuration
- ConfigBytesFromStringDecoder
- decode(\_:)

Instance Method

# decode(\_:)

Decodes a string value into an array of bytes.

ConfigBytesFromStringDecoder.swift

**Required**

## Parameters

`value`

The string representation to decode.

## Return Value

An array of bytes if decoding succeeds, or `nil` if it fails.

## Discussion

This method attempts to parse the provided string according to the decoder’s specific format and returns the corresponding byte array. If the string cannot be decoded (due to invalid format or encoding), the method returns `nil`.

- decode(\_:)
- Parameters
- Return Value
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader-get

- Configuration
- ConfigReader
- Synchronously reading values

API Collection

# Synchronously reading values

## Topics

### Synchronously reading string values

Synchronously gets a config value for the given config key.

Synchronously gets a config value for the given config key, with a default fallback.

Synchronously gets a config value for the given config key, converting from string.

Synchronously gets a config value for the given config key with default fallback, converting from string.

### Synchronously reading lists of string values

Synchronously gets an array of config values for the given config key, converting from strings.

Synchronously gets an array of config values for the given config key with default fallback, converting from strings.

### Synchronously reading required string values

Synchronously gets a required config value for the given config key, throwing an error if it’s missing.

Synchronously gets a required config value for the given config key, converting from string.

### Synchronously reading required lists of string values

Synchronously gets a required array of config values for the given config key, converting from strings.

### Synchronously reading Boolean values

### Synchronously reading required Boolean values

### Synchronously reading lists of Boolean values

### Synchronously reading required lists of Boolean values

### Synchronously reading integer values

### Synchronously reading required integer values

### Synchronously reading lists of integer values

### Synchronously reading required lists of integer values

### Synchronously reading double values

### Synchronously reading required double values

### Synchronously reading lists of double values

### Synchronously reading required lists of double values

### Synchronously reading bytes

### Synchronously reading required bytes

### Synchronously reading collections of byte chunks

### Synchronously reading required collections of byte chunks

## See Also

### Reading from a snapshot

Returns a snapshot of the current configuration state.

Watches the configuration for changes.

- Synchronously reading values
- Topics
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/intarray(_:)

#app-main)

- Configuration
- ConfigContent
- ConfigContent.intArray(\_:)

Case

# ConfigContent.intArray(\_:)

An array of integer values.

case intArray([Int])

ConfigProvider.swift

## See Also

### Types of configuration content

`case string(String)`

A string value.

[`case stringArray([String])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/stringarray(_:))

An array of string values.

`case bool(Bool)`

A Boolean value.

[`case boolArray([Bool])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/boolarray(_:))

An array of Boolean value.

`case int(Int)`

An integer value.

`case double(Double)`

A double value.

[`case doubleArray([Double])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/doublearray(_:))

An array of double values.

[`case bytes([UInt8])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytes(_:))

An array of bytes.

[`case byteChunkArray([[UInt8]])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytechunkarray(_:))

An array of byte arrays.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/foundation/url

- Configuration
- Foundation
- URL

Extended Structure

# URL

ConfigurationFoundation

extension URL

## Topics

## Relationships

### Conforms To

- `ExpressibleByConfigString`
- `Swift.Copyable`
- `Swift.CustomStringConvertible`

- URL
- Topics
- Relationships

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/appending(_:)

#app-main)

- Configuration
- AbsoluteConfigKey
- appending(\_:)

Instance Method

# appending(\_:)

Returns a new absolute configuration key by appending the given relative key.

ConfigKey.swift

## Parameters

`relative`

The relative configuration key to append to this key.

## Return Value

A new absolute configuration key with the relative key appended.

- appending(\_:)
- Parameters
- Return Value

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configvalue/init(_:issecret:)

#app-main)

- Configuration
- ConfigValue
- init(\_:isSecret:)

Initializer

# init(\_:isSecret:)

Creates a new configuration value.

init(
_ content: ConfigContent,
isSecret: Bool
)

ConfigProvider.swift

## Parameters

`content`

The configuration content.

`isSecret`

Whether the value contains sensitive information.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshotreader/string(forkey:issecret:default:fileid:line:)

#app-main)

- Configuration
- ConfigSnapshotReader
- string(forKey:isSecret:default:fileID:line:)

Instance Method

# string(forKey:isSecret:default:fileID:line:)

Synchronously gets a config value for the given config key, with a default fallback.

func string(
forKey key: ConfigKey,
isSecret: Bool = false,
default defaultValue: String,
fileID: String = #fileID,
line: UInt = #line

ConfigSnapshotReader+methods.swift

## Parameters

`key`

The config key to look up.

`isSecret`

Whether the value should be treated as secret for logging and debugging purposes.

`defaultValue`

The fallback value returned when the config value is missing or invalid.

`fileID`

The file ID where this call originates. Used for access reporting.

`line`

The line number where this call originates. Used for access reporting.

## Return Value

The config value if found and convertible, otherwise the default value.

## Discussion

Use this method when you need a guaranteed non-nil result. If the configuration value is missing or can’t be converted to the expected type, the default value is returned instead.

let maxRetries = snapshot.int(forKey: ["network", "maxRetries"], default: 3)

## See Also

### Synchronously reading string values

Synchronously gets a config value for the given config key.

Synchronously gets a config value for the given config key, converting from string.

Synchronously gets a config value for the given config key with default fallback, converting from string.

- string(forKey:isSecret:default:fileID:line:)
- Parameters
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/systempackage/filepath

- Configuration
- SystemPackage
- FilePath

Extended Structure

# FilePath

ConfigurationSystemPackage

extension FilePath

## Topics

## Relationships

### Conforms To

- `ExpressibleByConfigString`
- `Swift.Copyable`
- `Swift.CustomStringConvertible`

- FilePath
- Topics
- Relationships

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/expressiblebyconfigstring/init(configstring:)

#app-main)

- Configuration
- ExpressibleByConfigString
- init(configString:)

Initializer

# init(configString:)

Creates an instance from a configuration string value.

init?(configString: String)

ExpressibleByConfigString.swift

**Required**

## Parameters

`configString`

The string value from the configuration provider.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent/metadata-swift.struct

- Configuration
- AccessEvent
- AccessEvent.Metadata

Structure

# AccessEvent.Metadata

Metadata describing the configuration access operation.

struct Metadata

AccessReporter.swift

## Overview

Contains information about the type of access, the key accessed, value type, source location, and timestamp.

## Topics

### Creating access event metadata

`init(accessKind: AccessEvent.Metadata.AccessKind, key: AbsoluteConfigKey, valueType: ConfigType, sourceLocation: AccessEvent.Metadata.SourceLocation, accessTimestamp: Date)`

Creates access event metadata.

`enum AccessKind`

The type of configuration access operation.

### Inspecting access event metadata

`var accessKind: AccessEvent.Metadata.AccessKind`

The type of configuration access operation for this event.

`var accessTimestamp: Date`

The timestamp when the configuration access occurred.

`var key: AbsoluteConfigKey`

The configuration key accessed.

`var sourceLocation: AccessEvent.Metadata.SourceLocation`

The source code location where the access occurred.

`var valueType: ConfigType`

The expected type of the configuration value.

### Structures

`struct SourceLocation`

The source code location where a configuration access occurred.

## Relationships

### Conforms To

- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Creating an access event

Creates a configuration access event.

`struct ProviderResult`

The result of a configuration lookup from a specific provider.

- AccessEvent.Metadata
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/broadcastingaccessreporter/init(upstreams:)

#app-main)

- Configuration
- BroadcastingAccessReporter
- init(upstreams:)

Initializer

# init(upstreams:)

Creates a new broadcasting access reporter.

init(upstreams: [any AccessReporter])

AccessReporter.swift

## Parameters

`upstreams`

The reporters that will receive forwarded events.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configvalue/expressiblebyextendedgraphemeclusterliteral-implementations

- Configuration
- ConfigValue
- ExpressibleByExtendedGraphemeClusterLiteral Implementations

API Collection

# ExpressibleByExtendedGraphemeClusterLiteral Implementations

## Topics

### Initializers

`init(unicodeScalarLiteral: Self.ExtendedGraphemeClusterLiteralType)`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontextvalue/customstringconvertible-implementations

- Configuration
- ConfigContextValue
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader/init(provider:accessreporter:)

#app-main)

- Configuration
- ConfigReader
- init(provider:accessReporter:)

Initializer

# init(provider:accessReporter:)

Creates a config reader with a single provider.

init(
provider: some ConfigProvider,
accessReporter: (any AccessReporter)? = nil
)

ConfigReader.swift

## Parameters

`provider`

The configuration provider.

`accessReporter`

The reporter for configuration access events.

## See Also

### Creating config readers

[`init(providers: [any ConfigProvider], accessReporter: (any AccessReporter)?)`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader/init(providers:accessreporter:))

Creates a config reader with multiple providers.

- init(provider:accessReporter:)
- Parameters
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/prepending(_:)

# An unknown error occurred.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configtype/int

- Configuration
- ConfigType
- ConfigType.int

Case

# ConfigType.int

An integer value.

case int

ConfigProvider.swift

## See Also

### Types of configuration content

`case string`

A string value.

`case stringArray`

An array of string values.

`case bool`

A Boolean value.

`case boolArray`

An array of Boolean values.

`case intArray`

An array of integer values.

`case double`

A double value.

`case doubleArray`

An array of double values.

`case bytes`

An array of bytes.

`case byteChunkArray`

An array of byte chunks.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configvalue/equatable-implementations

- Configuration
- ConfigValue
- Equatable Implementations

API Collection

# Equatable Implementations

## Topics

### Operators

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontextvalue/string(_:)

#app-main)

- Configuration
- ConfigContextValue
- ConfigContextValue.string(\_:)

Case

# ConfigContextValue.string(\_:)

A string value.

case string(String)

ConfigContext.swift

## See Also

### Configuration context values

`case bool(Bool)`

A Boolean value.

`case int(Int)`

An integer value.

`case double(Double)`

A floating point value.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configtype/stringarray

- Configuration
- ConfigType
- ConfigType.stringArray

Case

# ConfigType.stringArray

An array of string values.

case stringArray

ConfigProvider.swift

## See Also

### Types of configuration content

`case string`

A string value.

`case bool`

A Boolean value.

`case boolArray`

An array of Boolean values.

`case int`

An integer value.

`case intArray`

An array of integer values.

`case double`

A double value.

`case doubleArray`

An array of double values.

`case bytes`

An array of bytes.

`case byteChunkArray`

An array of byte chunks.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshotreader/stringarray(forkey:issecret:fileid:line:)

#app-main)

- Configuration
- ConfigSnapshotReader
- stringArray(forKey:isSecret:fileID:line:)

Instance Method

# stringArray(forKey:isSecret:fileID:line:)

Synchronously gets a config value for the given config key.

func stringArray(
forKey key: ConfigKey,
isSecret: Bool = false,
fileID: String = #fileID,
line: UInt = #line

ConfigSnapshotReader+methods.swift

## Parameters

`key`

The config key to look up.

`isSecret`

Whether the value should be treated as secret for logging and debugging purposes.

`fileID`

The file ID where this call originates. Used for access reporting.

`line`

The line number where this call originates. Used for access reporting.

## Return Value

The value converted to the expected type if found and convertible, otherwise `nil`.

## Discussion

Use this method to retrieve optional configuration values from a snapshot. If the value doesn’t exist or can’t be converted to the expected type, the method returns `nil`.

let port = snapshot.int(forKey: ["server", "port"])

## See Also

### Synchronously reading lists of string values

Synchronously gets an array of config values for the given config key, converting from strings.

Synchronously gets a config value for the given config key, with a default fallback.

Synchronously gets an array of config values for the given config key with default fallback, converting from strings.

- stringArray(forKey:isSecret:fileID:line:)
- Parameters
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/components

- Configuration
- AbsoluteConfigKey
- components

Instance Property

# components

The hierarchical components that make up this absolute configuration key.

var components: [String]

ConfigKey.swift

## Discussion

Each component represents a level in the configuration hierarchy, forming a complete path from the root of the configuration structure.

## See Also

### Inspecting an absolute configuration key

[`var context: [String : ConfigContextValue]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/context)

Additional context information for this configuration key.

- components
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configtype/bool

- Configuration
- ConfigType
- ConfigType.bool

Case

# ConfigType.bool

A Boolean value.

case bool

ConfigProvider.swift

## See Also

### Types of configuration content

`case string`

A string value.

`case stringArray`

An array of string values.

`case boolArray`

An array of Boolean values.

`case int`

An integer value.

`case intArray`

An array of integer values.

`case double`

A double value.

`case doubleArray`

An array of double values.

`case bytes`

An array of bytes.

`case byteChunkArray`

An array of byte chunks.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/secretsspecifier/dynamic(_:)

#app-main)

- Configuration
- SecretsSpecifier
- SecretsSpecifier.dynamic(\_:)

Case

# SecretsSpecifier.dynamic(\_:)

The library determines the secret status dynamically by evaluating each key-value pair.

SecretsSpecifier.swift

## Parameters

`closure`

A closure that takes a key and value and returns whether the value should be treated as secret.

## Discussion

Use this case when you need complex logic to determine whether a value is secret based on the key name, value content, or other criteria.

## See Also

### Types of specifiers

`case all`

The library treats all configuration values as secrets.

The library treats the specified keys as secrets.

`case none`

The library treats no configuration values as secrets.

- SecretsSpecifier.dynamic(\_:)
- Parameters
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/secretsspecifier/all

- Configuration
- SecretsSpecifier
- SecretsSpecifier.all

Case

# SecretsSpecifier.all

The library treats all configuration values as secrets.

case all

SecretsSpecifier.swift

## Discussion

Use this case when the provider exclusively handles sensitive information and all values should be protected from disclosure.

## See Also

### Types of specifiers

The library treats the specified keys as secrets.

The library determines the secret status dynamically by evaluating each key-value pair.

`case none`

The library treats no configuration values as secrets.

- SecretsSpecifier.all
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configurationtesting/providercompattest/testconfiguration

- ConfigurationTesting
- ProviderCompatTest
- ProviderCompatTest.TestConfiguration

Structure

# ProviderCompatTest.TestConfiguration

Configuration options for customizing test behavior.

struct TestConfiguration

ProviderCompatTest.swift

## Topics

### Initializers

[`init(overrides: [String : ConfigContent])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configurationtesting/providercompattest/testconfiguration/init(overrides:))

Creates a new test configuration.

### Instance Properties

[`var overrides: [String : ConfigContent]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configurationtesting/providercompattest/testconfiguration/overrides)

Value overrides for testing custom scenarios.

## Relationships

### Conforms To

- `Swift.Sendable`
- `Swift.SendableMetatype`

- ProviderCompatTest.TestConfiguration
- Topics
- Relationships

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/foundation/date

- Configuration
- Foundation
- Date

Extended Structure

# Date

ConfigurationFoundation

extension Date

## Topics

## Relationships

### Conforms To

- `ExpressibleByConfigString`
- `Swift.Copyable`
- `Swift.CustomStringConvertible`

- Date
- Topics
- Relationships

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configtype/boolarray

- Configuration
- ConfigType
- ConfigType.boolArray

Case

# ConfigType.boolArray

An array of Boolean values.

case boolArray

ConfigProvider.swift

## See Also

### Types of configuration content

`case string`

A string value.

`case stringArray`

An array of string values.

`case bool`

A Boolean value.

`case int`

An integer value.

`case intArray`

An array of integer values.

`case double`

A double value.

`case doubleArray`

An array of double values.

`case bytes`

An array of bytes.

`case byteChunkArray`

An array of byte chunks.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontextvalue/equatable-implementations

- Configuration
- ConfigContextValue
- Equatable Implementations

API Collection

# Equatable Implementations

## Topics

### Operators

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/init(_:)

#app-main)

- Configuration
- AbsoluteConfigKey
- init(\_:)

Initializer

# init(\_:)

Creates a new absolute configuration key from a relative key.

init(_ relative: ConfigKey)

ConfigKey.swift

## Parameters

`relative`

The relative configuration key to convert.

## See Also

### Creating an absolute configuration key

[`init([String], context: [String : ConfigContextValue])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/init(_:context:))

Creates a new absolute configuration key.

- init(\_:)
- Parameters
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configupdatesasyncsequence/asyncsequence-implementations

- Configuration
- ConfigUpdatesAsyncSequence
- AsyncSequence Implementations

API Collection

# AsyncSequence Implementations

## Topics

### Instance Methods

[`func chunked<C>(by: AsyncTimerSequence<C>) -> AsyncChunksOfCountOrSignalSequence<Self, [Self.Element], AsyncTimerSequence<C>>`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configupdatesasyncsequence/chunked(by:)-trjw)

`func chunked<C, Collected>(by: AsyncTimerSequence<C>, into: Collected.Type) -> AsyncChunksOfCountOrSignalSequence<Self, Collected, AsyncTimerSequence<C>>`

[`func chunks<C>(ofCount: Int, or: AsyncTimerSequence<C>) -> AsyncChunksOfCountOrSignalSequence<Self, [Self.Element], AsyncTimerSequence<C>>`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configupdatesasyncsequence/chunks(ofcount:or:)-8u4c4)

`func chunks<C, Collected>(ofCount: Int, or: AsyncTimerSequence<C>, into: Collected.Type) -> AsyncChunksOfCountOrSignalSequence<Self, Collected, AsyncTimerSequence<C>>`

`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configupdatesasyncsequence/makeasynciterator())

`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configupdatesasyncsequence/share(bufferingpolicy:))

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshot/value(forkey:type:)

#app-main)

- Configuration
- ConfigSnapshot
- value(forKey:type:)

Instance Method

# value(forKey:type:)

Returns a value for the specified key from this immutable snapshot.

func value(
forKey key: AbsoluteConfigKey,
type: ConfigType

ConfigProvider.swift

**Required**

## Parameters

`key`

The configuration key to look up.

`type`

The expected configuration value type.

## Return Value

The lookup result containing the value and encoded key, or nil if not found.

## Discussion

Unlike `value(forKey:type:)`, this method always returns the same value for identical parameters because the snapshot represents a fixed point in time. Values can be accessed synchronously and efficiently.

## See Also

### Required methods

`var providerName: String`

The human-readable name of the configuration provider that created this snapshot.

- value(forKey:type:)
- Parameters
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configtype/intarray

- Configuration
- ConfigType
- ConfigType.intArray

Case

# ConfigType.intArray

An array of integer values.

case intArray

ConfigProvider.swift

## See Also

### Types of configuration content

`case string`

A string value.

`case stringArray`

An array of string values.

`case bool`

A Boolean value.

`case boolArray`

An array of Boolean values.

`case int`

An integer value.

`case double`

A double value.

`case doubleArray`

An array of double values.

`case bytes`

An array of bytes.

`case byteChunkArray`

An array of byte chunks.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontextvalue/double(_:)

#app-main)

- Configuration
- ConfigContextValue
- ConfigContextValue.double(\_:)

Case

# ConfigContextValue.double(\_:)

A floating point value.

case double(Double)

ConfigContext.swift

## See Also

### Configuration context values

`case string(String)`

A string value.

`case bool(Bool)`

A Boolean value.

`case int(Int)`

An integer value.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/directoryfilesprovider/customstringconvertible-implementations

- Configuration
- DirectoryFilesProvider
- CustomStringConvertible Implementations

API Collection

# CustomStringConvertible Implementations

## Topics

### Instance Properties

`var description: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontextvalue/int(_:)

#app-main)

- Configuration
- ConfigContextValue
- ConfigContextValue.int(\_:)

Case

# ConfigContextValue.int(\_:)

An integer value.

case int(Int)

ConfigContext.swift

## See Also

### Configuration context values

`case string(String)`

A string value.

`case bool(Bool)`

A Boolean value.

`case double(Double)`

A floating point value.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/comparable-implementations

- Configuration
- AbsoluteConfigKey
- Comparable Implementations

API Collection

# Comparable Implementations

## Topics

### Operators

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configreader/init(providers:accessreporter:)

#app-main)

- Configuration
- ConfigReader
- init(providers:accessReporter:)

Initializer

# init(providers:accessReporter:)

Creates a config reader with multiple providers.

init(
providers: [any ConfigProvider],
accessReporter: (any AccessReporter)? = nil
)

ConfigReader.swift

## Parameters

`providers`

The configuration providers, queried in order until a value is found.

`accessReporter`

The reporter for configuration access events.

## See Also

### Creating config readers

`init(provider: some ConfigProvider, accessReporter: (any AccessReporter)?)`

Creates a config reader with a single provider.

- init(providers:accessReporter:)
- Parameters
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshotreader/string(forkey:as:issecret:default:fileid:line:)-fzpe

-fzpe#app-main)

- Configuration
- ConfigSnapshotReader
- string(forKey:as:isSecret:default:fileID:line:)

Instance Method

# string(forKey:as:isSecret:default:fileID:line:)

Synchronously gets a config value for the given config key with default fallback, converting from string.

forKey key: ConfigKey,
as type: Value.Type = Value.self,
isSecret: Bool = false,
default defaultValue: Value,
fileID: String = #fileID,
line: UInt = #line

ConfigSnapshotReader+methods.swift

## Parameters

`key`

The config key to look up.

`type`

The type to convert the string value to.

`isSecret`

Whether the value should be treated as secret for logging and debugging purposes.

`defaultValue`

The fallback value returned when the config value is missing or invalid.

`fileID`

The file ID where this call originates. Used for access reporting.

`line`

The line number where this call originates. Used for access reporting.

## Return Value

The config value if found and convertible, otherwise the default value.

## Discussion

Use this method when you need a guaranteed non-nil result for string-convertible types. If the configuration value is missing or can’t be converted to the expected type, the default value is returned instead.

let serverMode = snapshot.string(forKey: ["server", "mode"], as: ServerMode.self, default: .production)

## See Also

### Synchronously reading string values

Synchronously gets a config value for the given config key.

Synchronously gets a config value for the given config key, with a default fallback.

Synchronously gets a config value for the given config key, converting from string.

- string(forKey:as:isSecret:default:fileID:line:)
- Parameters
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/absoluteconfigkey/init(_:context:)

#app-main)

- Configuration
- AbsoluteConfigKey
- init(\_:context:)

Initializer

# init(\_:context:)

Creates a new absolute configuration key.

init(
_ components: [String],
context: [String : ConfigContextValue] = [:]
)

ConfigKey.swift

## Parameters

`components`

The hierarchical components that make up the complete key path.

`context`

Additional context information for the key.

## See Also

### Creating an absolute configuration key

`init(ConfigKey)`

Creates a new absolute configuration key from a relative key.

- init(\_:context:)
- Parameters
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/mutableinmemoryprovider/customdebugstringconvertible-implementations

- Configuration
- MutableInMemoryProvider
- CustomDebugStringConvertible Implementations

API Collection

# CustomDebugStringConvertible Implementations

## Topics

### Instance Properties

`var debugDescription: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent/providerresult

- Configuration
- AccessEvent
- AccessEvent.ProviderResult

Structure

# AccessEvent.ProviderResult

The result of a configuration lookup from a specific provider.

struct ProviderResult

AccessReporter.swift

## Overview

Contains the provider’s name and the outcome of querying that provider, which can be either a successful lookup result or an error.

## Topics

### Creating provider results

Creates a provider result.

### Inspecting provider results

The outcome of the configuration lookup operation.

`var providerName: String`

The name of the configuration provider that processed the lookup.

## Relationships

### Conforms To

- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Creating an access event

Creates a configuration access event.

`struct Metadata`

Metadata describing the configuration access operation.

- AccessEvent.ProviderResult
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshotreader/string(forkey:issecret:fileid:line:)

#app-main)

- Configuration
- ConfigSnapshotReader
- string(forKey:isSecret:fileID:line:)

Instance Method

# string(forKey:isSecret:fileID:line:)

Synchronously gets a config value for the given config key.

func string(
forKey key: ConfigKey,
isSecret: Bool = false,
fileID: String = #fileID,
line: UInt = #line

ConfigSnapshotReader+methods.swift

## Parameters

`key`

The config key to look up.

`isSecret`

Whether the value should be treated as secret for logging and debugging purposes.

`fileID`

The file ID where this call originates. Used for access reporting.

`line`

The line number where this call originates. Used for access reporting.

## Return Value

The value converted to the expected type if found and convertible, otherwise `nil`.

## Discussion

Use this method to retrieve optional configuration values from a snapshot. If the value doesn’t exist or can’t be converted to the expected type, the method returns `nil`.

let port = snapshot.int(forKey: ["server", "port"])

## See Also

### Synchronously reading string values

Synchronously gets a config value for the given config key, with a default fallback.

Synchronously gets a config value for the given config key, converting from string.

Synchronously gets a config value for the given config key with default fallback, converting from string.

- string(forKey:isSecret:fileID:line:)
- Parameters
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/double(_:)

#app-main)

- Configuration
- ConfigContent
- ConfigContent.double(\_:)

Case

# ConfigContent.double(\_:)

A double value.

case double(Double)

ConfigProvider.swift

## See Also

### Types of configuration content

`case string(String)`

A string value.

[`case stringArray([String])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/stringarray(_:))

An array of string values.

`case bool(Bool)`

A Boolean value.

[`case boolArray([Bool])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/boolarray(_:))

An array of Boolean value.

`case int(Int)`

An integer value.

[`case intArray([Int])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/intarray(_:))

An array of integer values.

[`case doubleArray([Double])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/doublearray(_:))

An array of double values.

[`case bytes([UInt8])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytes(_:))

An array of bytes.

[`case byteChunkArray([[UInt8]])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytechunkarray(_:))

An array of byte arrays.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/stringarray(_:)

#app-main)

- Configuration
- ConfigContent
- ConfigContent.stringArray(\_:)

Case

# ConfigContent.stringArray(\_:)

An array of string values.

case stringArray([String])

ConfigProvider.swift

## See Also

### Types of configuration content

`case string(String)`

A string value.

`case bool(Bool)`

A Boolean value.

[`case boolArray([Bool])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/boolarray(_:))

An array of Boolean value.

`case int(Int)`

An integer value.

[`case intArray([Int])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/intarray(_:))

An array of integer values.

`case double(Double)`

A double value.

[`case doubleArray([Double])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/doublearray(_:))

An array of double values.

[`case bytes([UInt8])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytes(_:))

An array of bytes.

[`case byteChunkArray([[UInt8]])`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configcontent/bytechunkarray(_:))

An array of byte arrays.

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshotreader/string(forkey:as:issecret:fileid:line:)-8hlcf

-8hlcf#app-main)

- Configuration
- ConfigSnapshotReader
- string(forKey:as:isSecret:fileID:line:)

Instance Method

# string(forKey:as:isSecret:fileID:line:)

Synchronously gets a config value for the given config key, converting from string.

forKey key: ConfigKey,
as type: Value.Type = Value.self,
isSecret: Bool = false,
fileID: String = #fileID,
line: UInt = #line

ConfigSnapshotReader+methods.swift

## Parameters

`key`

The config key to look up.

`type`

The type to convert the string value to.

`isSecret`

Whether the value should be treated as secret for logging and debugging purposes.

`fileID`

The file ID where this call originates. Used for access reporting.

`line`

The line number where this call originates. Used for access reporting.

## Return Value

The value converted to the expected type if found and convertible, otherwise `nil`.

## Discussion

Use this method to retrieve configuration values that can be converted from strings, such as custom types conforming to string conversion protocols. If the value doesn’t exist or can’t be converted to the expected type, the method returns `nil`.

let serverMode = snapshot.string(forKey: ["server", "mode"], as: ServerMode.self)

## See Also

### Synchronously reading string values

Synchronously gets a config value for the given config key.

Synchronously gets a config value for the given config key, with a default fallback.

Synchronously gets a config value for the given config key with default fallback, converting from string.

- string(forKey:as:isSecret:fileID:line:)
- Parameters
- Return Value
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/directoryfilesprovider/customdebugstringconvertible-implementations

- Configuration
- DirectoryFilesProvider
- CustomDebugStringConvertible Implementations

API Collection

# CustomDebugStringConvertible Implementations

## Topics

### Instance Properties

`var debugDescription: String`

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/configsnapshot/providername

- Configuration
- ConfigSnapshot
- providerName

Instance Property

# providerName

The human-readable name of the configuration provider that created this snapshot.

var providerName: String { get }

ConfigProvider.swift

**Required**

## Discussion

Used by `AccessReporter` and when diagnostic logging the config reader types.

## See Also

### Required methods

Returns a value for the specified key from this immutable snapshot.

- providerName
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/secretsspecifier/issecret(key:value:)

#app-main)

- Configuration
- SecretsSpecifier
- isSecret(key:value:)

Instance Method

# isSecret(key:value:)

Determines whether a configuration value should be treated as secret.

func isSecret(
key: KeyType,
value: ValueType

SecretsSpecifier.swift

Available when `KeyType` conforms to `Hashable`, `KeyType` conforms to `Sendable`, and `ValueType` conforms to `Sendable`.

## Parameters

`key`

The provider-specific configuration key.

`value`

The configuration value to evaluate.

## Return Value

`true` if the value should be treated as secret; otherwise, `false`.

## Discussion

This method evaluates the secrets specifier against the provided key-value pair to determine if the value contains sensitive information that should be protected from disclosure.

let isSecret = specifier.isSecret(key: "API_KEY", value: "secret123")
// Returns: true

- isSecret(key:value:)
- Parameters
- Return Value
- Discussion

|
|

---

# https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent/metadata-swift.property

- Configuration
- AccessEvent
- metadata

Instance Property

# metadata

Metadata that describes the configuration access operation.

var metadata: AccessEvent.Metadata

AccessReporter.swift

## See Also

### Inspecting an access event

The final outcome of the configuration access operation.

`var conversionError: (any Error)?`

An error that occurred when converting the raw config value into another type, for example `RawRepresentable`.

[`var providerResults: [AccessEvent.ProviderResult]`](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/accessevent/providerresults)

The results from each configuration provider that was queried.

|
|

---

