<!--
Downloaded via https://llm.codes by @steipete on November 12, 2025 at 02:56 PM
Source URL: https://swiftpackageindex.com/apple/swift-log/main/documentation/logging
Total pages processed: 122
URLs filtered: Yes
Content de-duplicated: Yes
Availability strings filtered: Yes
Code blocks only: No
-->

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging

Framework

# Logging

A unified, performant, and ergonomic logging API for Swift.

## Overview

SwiftLog provides a logging API package designed to establish a common API the ecosystem can use. It allows packages to emit log messages without tying them to any specific logging implementation, while applications can choose any compatible logging backend.

SwiftLog is an _API package_ which cuts the logging problem in half:

1. A logging API (this package)

2. Logging backend implementations (community-provided)

This separation allows libraries to adopt the API while applications choose any compatible logging backend implementation without requiring changes from libraries.

## Getting Started

Use this package if you’re writing a cross-platform application (for example, Linux and macOS) or library, and want to target this logging API.

### Adding the Dependency

Add the dependency to your `Package.swift`:

.package(url: "https://github.com/apple/swift-log", from: "1.6.0")

And to your target:

.target(
name: "YourTarget",
dependencies: [\
.product(name: "Logging", package: "swift-log")\
]
)

### Basic Usage

// Import the logging API
import Logging

// Create a logger with a label
let logger = Logger(label: "MyLogger")

// Use it to log messages
logger.info("Hello World!")

This outputs:

2025-10-24T17:26:47-0700 info MyLogger: [your_app] Hello World!

### Default Behavior

SwiftLog provides basic console logging via `StreamLogHandler`. By default it uses `stdout`, however, you can configure it to use `stderr` instead:

LoggingSystem.bootstrap(StreamLogHandler.standardError)

`StreamLogHandler` is primarily for convenience. For production applications, implement the `LogHandler` protocol directly or use a community-maintained backend.

## Topics

### Logging API

Understanding Loggers and Log Handlers

Learn how to create and configure loggers, set log levels, and use metadata to add context to your log messages.

`struct Logger`

A Logger emits log messages using methods that correspond to a log level.

`enum LoggingSystem`

The logging system is a global facility where you can configure the default logging backend implementation.

### Log Handlers

`protocol LogHandler`

A log handler provides an implementation of a logging backend.

`struct MultiplexLogHandler`

A pseudo log handler that sends messages to multiple other log handlers.

`struct StreamLogHandler`

Stream log handler presents log messages to STDERR or STDOUT.

`struct SwiftLogNoOpLogHandler`

A no-operation log handler, used when no logging is required

### Best Practices

Best practices for effective logging with SwiftLog.

Implementing a log handler

Create a custom logging backend that provides logging services for your apps and libraries.

- Logging
- Overview
- Getting Started
- Adding the Dependency
- Basic Usage
- Default Behavior
- Topics

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler

- Logging
- StreamLogHandler

Structure

# StreamLogHandler

Stream log handler presents log messages to STDERR or STDOUT.

struct StreamLogHandler

Logging.swift

## Mentioned in

Understanding Loggers and Log Handlers

## Overview

This is a simple implementation of `LogHandler` that directs `Logger` output to either `stderr` or `stdout` via the factory methods.

Metadata is merged in the following order:

1. Metadata set on the log handler itself is used as the base metadata.

2. The handler’s `metadataProvider` is invoked, overriding any existing keys.

3. The per-log-statement metadata is merged, overriding any previously set keys.

## Topics

### Creating a stream log handler

Creates a stream log handler that directs its output to STDOUT.

Creates a stream log handler that directs its output to STDOUT using the metadata provider you provide.

Creates a stream log handler that directs its output to STDERR.

Creates a stream log handler that directs its output to STDERR using the metadata provider you provide.

### Sending log messages

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt)`

Log a message using the log level and source that you provide.

### Updating metadata

Add, change, or remove a logging metadata item.

### Inspecting a log handler

`var logLevel: Logger.Level`

Get the log level configured for this `Logger`.

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

`var metadataProvider: Logger.MetadataProvider?`

The metadata provider.

## Relationships

### Conforms To

- `LogHandler`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Log Handlers

`protocol LogHandler`

A log handler provides an implementation of a logging backend.

`struct MultiplexLogHandler`

A pseudo log handler that sends messages to multiple other log handlers.

`struct SwiftLogNoOpLogHandler`

A no-operation log handler, used when no logging is required

- StreamLogHandler
- Mentioned in
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler

- Logging
- LogHandler

Protocol

# LogHandler

A log handler provides an implementation of a logging backend.

protocol LogHandler : _SwiftLogSendableLogHandler

LogHandler.swift

## Mentioned in

Implementing a log handler

## Overview

This type is an implementation detail and should not normally be used, unless you implement your own logging backend. To use the SwiftLog API, please refer to the documentation of `Logger`.

# Implementation requirements

To implement your own `LogHandler` you should respect a few requirements that are necessary so applications work as expected, regardless of the selected `LogHandler` implementation.

- The `LogHandler` must be a `struct`.

- The metadata and `logLevel` properties must be implemented so that setting them on a `Logger` does not affect other instances of `Logger`.

### Treat log level & metadata as values

When developing your `LogHandler`, please make sure the following test works.

@Test
func logHandlerValueSemantics() {
LoggingSystem.bootstrap(MyLogHandler.init)
var logger1 = Logger(label: "first logger")
logger1.logLevel = .debug
logger1[metadataKey: "only-on"] = "first"

var logger2 = logger1
logger2.logLevel = .error // Must not affect logger1
logger2[metadataKey: "only-on"] = "second" // Must not affect logger1

// These expectations must pass
#expect(logger2[metadataKey: "only-on"] == "second")
}

### Special cases

In certain special cases, the log level behaving like a value on `Logger` might not be what you want. For example, you might want to set the log level across _all_`Logger`s to `.debug` when a signal (for example `SIGUSR1`) is received to be able to debug special failures in production. This special case is acceptable but please create a solution specific to your `LogHandler` implementation to achieve that.

The following code illustrates an example implementation of this behavior. On reception of the signal you would call `LogHandlerWithGlobalLogLevelOverride.overrideGlobalLogLevel = .debug`, for example.

import class Foundation.NSLock

public struct LogHandlerWithGlobalLogLevelOverride: LogHandler {
// The static properties hold the globally overridden
// log level (if overridden).
private static let overrideLock = NSLock()
private static var overrideLogLevel: Logger.Level? = nil

// this holds the log level if not overridden
private var _logLevel: Logger.Level = .info

// metadata storage
public var metadata: Logger.Metadata = [:]

public init(label: String) {
// [...]
}

public var logLevel: Logger.Level {
// When asked for the log level, check
// if it was globally overridden or not.
get {
LogHandlerWithGlobalLogLevelOverride.overrideLock.lock()
defer { LogHandlerWithGlobalLogLevelOverride.overrideLock.unlock() }
return LogHandlerWithGlobalLogLevelOverride.overrideLogLevel ?? self._logLevel
}
// Set the log level whenever asked
// (note: this might not have an effect if globally
// overridden).
set {
self._logLevel = newValue
}
}

public func log(
level: Logger.Level,
message: Logger.Message,
metadata: Logger.Metadata?,
source: String,
file: String,
function: String,
line: UInt) {
// [...]
}

get {
return self.metadata[metadataKey]
}
set(newValue) {
self.metadata[metadataKey] = newValue
}
}

// This is the function to globally override the log level,
// it is not part of the `LogHandler` protocol.
public static func overrideGlobalLogLevel(_ logLevel: Logger.Level) {
LogHandlerWithGlobalLogLevelOverride.overrideLock.lock()
defer { LogHandlerWithGlobalLogLevelOverride.overrideLock.unlock() }
LogHandlerWithGlobalLogLevelOverride.overrideLogLevel = logLevel
}
}

## Topics

### Sending log messages

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt)`

The library calls this method when a log handler must emit a log message.

**Required** Default implementation provided.

A default implementation for a log message handler that forwards the source location for the message.

Deprecated

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt)`

SwiftLog 1.0 log compatibility method.

A default implementation for a log message handler.

### Updating metadata

Add, remove, or change the logging metadata.

**Required**

### Inspecting a log handler

`var logLevel: Logger.Level`

Get or set the configured log level.

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

`var metadataProvider: Logger.MetadataProvider?`

The metadata provider this log handler uses when a log statement is about to be emitted.

## Relationships

### Inherits From

- `Swift.Sendable`
- `Swift.SendableMetatype`

### Conforming Types

- `MultiplexLogHandler`
- `StreamLogHandler`
- `SwiftLogNoOpLogHandler`

## See Also

### Log Handlers

`struct MultiplexLogHandler`

A pseudo log handler that sends messages to multiple other log handlers.

`struct StreamLogHandler`

Stream log handler presents log messages to STDERR or STDOUT.

`struct SwiftLogNoOpLogHandler`

A no-operation log handler, used when no logging is required

- LogHandler
- Mentioned in
- Overview
- Implementation requirements
- Treat log level & metadata as values
- Special cases
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/understandingloggers

- Logging
- Understanding Loggers and Log Handlers

Article

# Understanding Loggers and Log Handlers

Learn how to create and configure loggers, set log levels, and use metadata to add context to your log messages.

## Overview

Create or retrieve a logger to get an instance for logging messages. Log messages have a level that you use to indicate the message’s importance.

SwiftLog defines seven log levels, represented by `Logger.Level`, ordered from least to most severe:

- `Logger.Level.trace`

- `Logger.Level.debug`

- `Logger.Level.info`

- `Logger.Level.notice`

- `Logger.Level.warning`

- `Logger.Level.error`

- `Logger.Level.critical`

Once a message is sent to a logger, a log handler processes it. The app using the logger configures the handler, usually for the environment in which that app runs, processing messages appropriate to that environment. If the app doesn’t provide its own log handler, SwiftLog defaults to using a `StreamLogHandler` that outputs log messages to `STDOUT`.

### Loggers

Loggers are used to emit log messages at different severity levels:

// Informational message
logger.info("Processing request")

// Something went wrong
logger.error("Houston, we have a problem")

`Logger` is a value type with value semantics, meaning that when you modify a logger’s configuration (like its log level or metadata), it only affects that specific logger instance:

let baseLogger = Logger(label: "MyApp")

// Create a new logger with different configuration.
var requestLogger = baseLogger
requestLogger.logLevel = .debug
requestLogger[metadataKey: "request-id"] = "\(UUID())"

// baseLogger is unchanged. It still has default log level and no metadata
// requestLogger has debug level and request-id metadata.

This value type behavior makes loggers safe to pass between functions and modify without unexpected side effects.

### Log Levels

Log levels can be changed per logger without affecting others:

var logger = Logger(label: "MyLogger")
logger.logLevel = .debug

For guidance on what level to use for a message, see 001: Choosing log levels.

### Logging Metadata

Metadata provides contextual information crucial for debugging:

var logger = Logger(label: "com.example.server")
logger[metadataKey: "request.id"] = "\(UUID())"
logger.info("Processing request")

Output:

2019-03-13T18:30:02+0000 info: request-uuid=F8633013-3DD8-481C-9256-B296E43443ED Processing request

### Source vs Label

A `Logger` has an immutable `label` that identifies its creator, while each log message carries a `source` parameter that identifies where the message originated. Use `source` for filtering messages from specific subsystems.

## See Also

### Logging API

`struct Logger`

A Logger emits log messages using methods that correspond to a log level.

`enum LoggingSystem`

The logging system is a global facility where you can configure the default logging backend implementation.

- Understanding Loggers and Log Handlers
- Overview
- Loggers
- Log Levels
- Logging Metadata
- Source vs Label
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger



---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loggingsystem

- Logging
- LoggingSystem

Enumeration

# LoggingSystem

The logging system is a global facility where you can configure the default logging backend implementation.

enum LoggingSystem

Logging.swift

## Overview

`LoggingSystem` is set up just once in a given program to set up the desired logging backend implementation. The default behavior, if you don’t define otherwise, sets the `LogHandler` to use a `StreamLogHandler` that presents its output to `STDOUT`.

You can configure that handler to present the output to `STDERR` instead using the following code:

LoggingSystem.bootstrap(StreamLogHandler.standardError)

The default ( `StreamLogHandler`) is intended to be a convenience. For production applications, implement the `LogHandler` protocol directly, or use a community-maintained backend.

## Topics

### Initializing the logging system

A one-time configuration function that globally selects the implementation for your desired logging backend.

### Inspecting the logging system

`static var metadataProvider: Logger.MetadataProvider?`

System wide `Logger.MetadataProvider` that was configured during the logging system’s `bootstrap`.

## See Also

### Logging API

Understanding Loggers and Log Handlers

Learn how to create and configure loggers, set log levels, and use metadata to add context to your log messages.

`struct Logger`

A Logger emits log messages using methods that correspond to a log level.

- LoggingSystem
- Overview
- Topics
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler

- Logging
- MultiplexLogHandler

Structure

# MultiplexLogHandler

A pseudo log handler that sends messages to multiple other log handlers.

struct MultiplexLogHandler

Logging.swift

### Effective Logger.Level

When first initialized, the multiplex log handlers’ log level is automatically set to the minimum of all the provided log handlers. This ensures that each of the handlers are able to log at their appropriate level any log events they might be interested in.

Example: If log handler `A` is logging at `.debug` level, and log handler `B` is logging at `.info` level, the log level of the constructed `MultiplexLogHandler([A, B])` is set to `.debug`. This means that this handler will operate on debug messages, while only logged by the underlying `A` log handler (since `B`’s log level is `.info` and thus it would not actually log that log message).

If the log level is _set_ on a `Logger` backed by an `MultiplexLogHandler` the log level applies to _all_ underlying log handlers, allowing a logger to still select at what level it wants to log regardless of if the underlying handler is a multiplex or a normal one. If for some reason one might want to not allow changing a log level of a specific handler passed into the multiplex log handler, this is possible by wrapping it in a handler which ignores any log level changes.

### Effective Logger.Metadata

Since a `MultiplexLogHandler` is a combination of multiple log handlers, the handling of metadata can be non-obvious. For example, the underlying log handlers may have metadata of their own set before they are used to initialize the multiplex log handler.

The multiplex log handler acts purely as proxy and does not make any changes to underlying handler metadata other than proxying writes that users made on a `Logger` instance backed by this handler.

Setting metadata is always proxied through to _all_ underlying handlers, meaning that if a modification like `logger[metadataKey: "x"] = "y"` is made, all the underlying log handlers used to create the multiplex handler observe this change.

Reading metadata from the multiplex log handler MAY need to pick one of conflicting values if the underlying log handlers were previously initiated with metadata before passing them into the multiplex handler. The multiplex handler uses the order in which the handlers were passed in during its initialization as a priority indicator - the first handler’s values are more important than the next handlers values, etc.

Example: If the multiplex log handler was initiated with two handlers like this: `MultiplexLogHandler([handler1, handler2])`. The handlers each have some already set metadata: `handler1` has metadata values for keys `one` and `all`, and `handler2` has values for keys `two` and `all`.

A query through the multiplex log handler the key `one` naturally returns `handler1`’s value, and a query for `two` naturally returns `handler2`’s value. Querying for the key `all` will return `handler1`’s value, as that handler has a high priority, as indicated by its earlier position in the initialization, than the second handler. The same rule applies when querying for the `metadata` property of the multiplex log handler; it constructs `Metadata` uniquing values.

## Topics

### Creating a multiplex log handler

[`init([any LogHandler])`](https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/init(_:))

Create a multiplex log handler.

[`init([any LogHandler], metadataProvider: Logger.MetadataProvider?)`](https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/init(_:metadataprovider:))

Create a multiplex log handler with the metadata provider you provide.

### Sending log messages

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt)`

Log a message using the log level and source that you provide.

### Updating metadata

Add, change, or remove a logging metadata item.

### Inspecting a log handler

`var logLevel: Logger.Level`

Get or set the log level configured for this `Logger`.

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

`var metadataProvider: Logger.MetadataProvider?`

The metadata provider.

## Relationships

### Conforms To

- `LogHandler`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Log Handlers

`protocol LogHandler`

A log handler provides an implementation of a logging backend.

`struct StreamLogHandler`

Stream log handler presents log messages to STDERR or STDOUT.

`struct SwiftLogNoOpLogHandler`

A no-operation log handler, used when no logging is required

- MultiplexLogHandler
- Effective Logger.Level
- Effective Logger.Metadata
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler

- Logging
- SwiftLogNoOpLogHandler

Structure

# SwiftLogNoOpLogHandler

A no-operation log handler, used when no logging is required

struct SwiftLogNoOpLogHandler

Logging.swift

## Topics

### Creating a Swift Log no-op log handler

`init()`

Creates a no-op log handler.

`init(String)`

### Sending log messages

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt)`

A proxy that discards every log message that you provide.

### Updating metadata

Add, change, or remove a logging metadata item.

### Inspecting a log handler

`var logLevel: Logger.Level`

Get or set the log level configured for this `Logger`.

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

`var metadataProvider: Logger.MetadataProvider?`

Default implementation for a metadata provider that defaults to nil.

### Instance Methods

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt)`

A proxy that discards every log message it receives.

## Relationships

### Conforms To

- `LogHandler`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Log Handlers

`protocol LogHandler`

A log handler provides an implementation of a logging backend.

`struct MultiplexLogHandler`

A pseudo log handler that sends messages to multiple other log handlers.

`struct StreamLogHandler`

Stream log handler presents log messages to STDERR or STDOUT.

- SwiftLogNoOpLogHandler
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loggingbestpractices

- Logging
- Logging best practices

# Logging best practices

Best practices for effective logging with SwiftLog.

## Overview

This collection of best practices helps library authors and application developers create effective, maintainable logging that works well across diverse environments. Each practice is designed to ensure your logs are useful for debugging while being respectful of system resources and operational requirements.

### Who Should Use These Practices

- **Library Authors**: Creating reusable components that log appropriately.

- **Application Developers**: Implementing logging strategies in applications.

### Philosophy

Good logging strikes a balance between providing useful information and avoiding system overhead. These practices are based on real-world experience with production systems and emphasize:

- **Predictable behavior** across different environments.

- **Performance consciousness** to avoid impacting application speed.

- **Operational awareness** to support production debugging and monitoring.

- **Developer experience** to make debugging efficient and pleasant.

### Contributing to these practices

These best practices evolve based on community experience and are maintained by the Swift Server Working Group ( SSWG). Each practice includes:

- **Clear motivation** explaining why the practice matters

- **Concrete examples** showing good and bad patterns

- **Alternatives considered** documenting trade-offs and rejected approaches

## Topics

001: Choosing log levels

Select appropriate log levels in applications and libraries.

002: Structured logging

Use metadata to create machine-readable, searchable log entries.

003: Accepting loggers in libraries

Accept loggers through method parameters to ensure proper metadata propagation.

## See Also

### Best Practices

Implementing a log handler

Create a custom logging backend that provides logging services for your apps and libraries.

- Logging best practices
- Overview
- Who Should Use These Practices
- Philosophy
- Contributing to these practices
- Topics
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/implementingaloghandler

- Logging
- Implementing a log handler

Article

# Implementing a log handler

Create a custom logging backend that provides logging services for your apps and libraries.

## Overview

To become a compatible logging backend that any SwiftLog consumer can use, you need to fulfill a few requirements, primarily conforming to the `LogHandler` protocol.

### Implement with value type semantics

Your log handler **must be a `struct`** and exhibit value semantics. This ensures that changes to one logger don’t affect others.

To verify that your handler reflects value semantics ensure that it passes this test:

@Test
func logHandlerValueSemantics() {
LoggingSystem.bootstrap(MyLogHandler.init)
var logger1 = Logger(label: "first logger")
logger1.logLevel = .debug
logger1[metadataKey: "only-on"] = "first"

var logger2 = logger1
logger2.logLevel = .error // Must not affect logger1
logger2[metadataKey: "only-on"] = "second" // Must not affect logger1

// These expectations must pass
#expect(logger2[metadataKey: "only-on"] == "second")
}

### Example implementation

Here’s a complete example of a simple print-based log handler:

import Foundation
import Logging

public struct PrintLogHandler: LogHandler {
private let label: String
public var logLevel: Logger.Level = .info
public var metadata: Logger.Metadata = [:]

public init(label: String) {
self.label = label
}

public func log(
level: Logger.Level,
message: Logger.Message,
metadata: Logger.Metadata?,
source: String,
file: String,
function: String,
line: UInt
) {
let timestamp = ISO8601DateFormatter().string(from: Date())
let levelString = level.rawValue.uppercased()

// Merge handler metadata with message metadata
let combinedMetadata = Self.prepareMetadata(
base: self.metadata
explicit: metadata
)

// Format metadata
let metadataString = combinedMetadata.map { "\($0.key)=\($0.value)" }.joined(separator: ",")

// Create log line and print to console
let logLine = "\(label) \(timestamp) \(levelString) [\(metadataString)]: \(message)"
print(logLine)
}

get {
return self.metadata[key]
}
set {
self.metadata[key] = newValue
}
}

static func prepareMetadata(
base: Logger.Metadata,
explicit: Logger.Metadata?

var metadata = base

guard let explicit else {
// all per-log-statement values are empty
return metadata
}

metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })

return metadata
}
}

#### Metadata providers

Metadata providers allow you to dynamically add contextual information to all log messages without explicitly passing it each time. Common use cases include request IDs, user sessions, or trace contexts that should be included in logs throughout a request’s lifecycle.

public struct PrintLogHandler: LogHandler {
private let label: String
public var logLevel: Logger.Level = .info
public var metadata: Logger.Metadata = [:]
public var metadataProvider: Logger.MetadataProvider?

// Get provider metadata
let providerMetadata = metadataProvider?.get() ?? [:]

// Merge handler metadata with message metadata
let combinedMetadata = Self.prepareMetadata(
base: self.metadata,
provider: self.metadataProvider,
explicit: metadata
)

static func prepareMetadata(
base: Logger.Metadata,
provider: Logger.MetadataProvider?,
explicit: Logger.Metadata?

let provided = provider?.get() ?? [:]

guard !provided.isEmpty || !((explicit ?? [:]).isEmpty) else {
// all per-log-statement values are empty
return metadata
}

if !provided.isEmpty {
metadata.merge(provided, uniquingKeysWith: { _, provided in provided })
}

if let explicit = explicit, !explicit.isEmpty {
metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })
}

### Performance considerations

1. **Avoid blocking**: Don’t block the calling thread for I/O operations.

2. **Lazy evaluation**: Remember that messages and metadata are autoclosures.

3. **Memory efficiency**: Don’t hold onto large amounts of messages.

## See Also

### Related Documentation

`protocol LogHandler`

A log handler provides an implementation of a logging backend.

`struct StreamLogHandler`

Stream log handler presents log messages to STDERR or STDOUT.

`struct MultiplexLogHandler`

A pseudo log handler that sends messages to multiple other log handlers.

### Best Practices

Best practices for effective logging with SwiftLog.

- Implementing a log handler
- Overview
- Implement with value type semantics
- Example implementation
- Advanced features
- Performance considerations
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler).

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/understandingloggers)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loggingsystem)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loggingbestpractices)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/implementingaloghandler)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loggingsystem/bootstrap(_:)

#app-main)

- Logging
- LoggingSystem
- bootstrap(\_:)

Type Method

# bootstrap(\_:)

A one-time configuration function that globally selects the implementation for your desired logging backend.

@preconcurrency

Logging.swift

## Parameters

`factory`

A closure that provides a `Logger` label identifier and produces an instance of the `LogHandler`.

## Discussion

## See Also

### Initializing the logging system

- bootstrap(\_:)
- Parameters
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loggingsystem/bootstrap(_:metadataprovider:)

#app-main)

- Logging
- LoggingSystem
- bootstrap(\_:metadataProvider:)

Type Method

# bootstrap(\_:metadataProvider:)

A one-time configuration function that globally selects the implementation for your desired logging backend.

@preconcurrency
static func bootstrap(

metadataProvider: Logger.MetadataProvider?
)

Logging.swift

## Parameters

`factory`

A closure that provides a `Logger` label identifier and produces an instance of the `LogHandler`.

`metadataProvider`

The `MetadataProvider` used to inject runtime-generated metadata from the execution context.

## Discussion

## See Also

### Initializing the logging system

- bootstrap(\_:metadataProvider:)
- Parameters
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loggingsystem/metadataprovider

- Logging
- LoggingSystem
- metadataProvider

Type Property

# metadataProvider

System wide `Logger.MetadataProvider` that was configured during the logging system’s `bootstrap`.

static var metadataProvider: Logger.MetadataProvider? { get }

Logging.swift

## Discussion

When creating a `Logger` using the plain `init(label:)` initializer, this metadata provider will be provided to it.

When using custom log handler factories, make sure to provide the bootstrapped metadata provider to them, or the metadata will not be filled in automatically using the provider on log-sites. While using a custom factory to avoid using the bootstrapped metadata provider may sometimes be useful, usually it will lead to un-expected behavior, so make sure to always propagate it to your handlers.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/metadataprovider-swift.struct

- Logging
- Logger
- Logger.MetadataProvider

Structure

# Logger.MetadataProvider

A MetadataProvider automatically injects runtime-generated metadata to all logs emitted by a logger.

struct MetadataProvider

MetadataProvider.swift

### Example

A metadata provider may be used to automatically inject metadata such as trace IDs:

import Tracing //

let metadataProvider = MetadataProvider {
guard let traceID = Baggage.current?.traceID else { return nil }
return ["traceID": "\(traceID)"]
}
let logger = Logger(label: "example", metadataProvider: metadataProvider)
var baggage = Baggage.topLevel
baggage.traceID = 42
Baggage.withValue(baggage) {
logger.info("hello") // automatically includes ["traceID": "42"] metadata
}

We recommend referring to swift-distributed-tracing for metadata providers which make use of its tracing and metadata propagation infrastructure. It is however possible to make use of metadata providers independently of tracing and instruments provided by that library, if necessary.

## Topics

### Creating a metadata provider

Creates a new metadata provider.

### Invoking the provider

Invokes the metadata provider and returns the generated contextual metadata.

### Merging metadata

A pseudo metadata provider that merges metadata from multiple other metadata providers.

## Relationships

### Conforms To

- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Creating Loggers

`init(label: String)`

Construct a logger with the label you provide to identify the creator of the logger.

`init(label: String, metadataProvider: Logger.MetadataProvider)`

Creates a logger using the label that identifies the creator of the logger or a non-standard log handler.

- Logger.MetadataProvider
- Example
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loggingsystem/bootstrap(_:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loggingsystem/bootstrap(_:metadataprovider:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loggingsystem/metadataprovider)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/metadataprovider-swift.struct)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/metadataprovider

- Logging
- StreamLogHandler
- metadataProvider

Instance Property

# metadataProvider

The metadata provider.

var metadataProvider: Logger.MetadataProvider?

Logging.swift

## See Also

### Inspecting a log handler

`var logLevel: Logger.Level`

Get the log level configured for this `Logger`.

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/standardoutput(label:)

#app-main)

- Logging
- StreamLogHandler
- standardOutput(label:)

Type Method

# standardOutput(label:)

Creates a stream log handler that directs its output to STDOUT.

Logging.swift

## See Also

### Creating a stream log handler

Creates a stream log handler that directs its output to STDOUT using the metadata provider you provide.

Creates a stream log handler that directs its output to STDERR.

Creates a stream log handler that directs its output to STDERR using the metadata provider you provide.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/standardoutput(label:metadataprovider:)

# The page you're looking for can't be found.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/standarderror(label:)

#app-main)

- Logging
- StreamLogHandler
- standardError(label:)

Type Method

# standardError(label:)

Creates a stream log handler that directs its output to STDERR.

Logging.swift

## See Also

### Creating a stream log handler

Creates a stream log handler that directs its output to STDOUT.

Creates a stream log handler that directs its output to STDOUT using the metadata provider you provide.

Creates a stream log handler that directs its output to STDERR using the metadata provider you provide.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/standarderror(label:metadataprovider:)

#app-main)

- Logging
- StreamLogHandler
- standardError(label:metadataProvider:)

Type Method

# standardError(label:metadataProvider:)

Creates a stream log handler that directs its output to STDERR using the metadata provider you provide.

static func standardError(
label: String,
metadataProvider: Logger.MetadataProvider?

Logging.swift

## See Also

### Creating a stream log handler

Creates a stream log handler that directs its output to STDOUT.

Creates a stream log handler that directs its output to STDOUT using the metadata provider you provide.

Creates a stream log handler that directs its output to STDERR.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/log(level:message:metadata:source:file:function:line:)

#app-main)

- Logging
- StreamLogHandler
- log(level:message:metadata:source:file:function:line:)

Instance Method

# log(level:message:metadata:source:file:function:line:)

Log a message using the log level and source that you provide.

func log(
level: Logger.Level,
message: Logger.Message,
metadata explicitMetadata: Logger.Metadata?,
source: String,
file: String,
function: String,
line: UInt
)

Logging.swift

## Parameters

`level`

The log level to log the `message`.

`message`

The message to be logged. The `message` parameter supports any string interpolation literal.

`explicitMetadata`

One-off metadata to attach to this log message.

`source`

The source this log message originates from. The value defaults to the module that emits the log message.

`file`

The file this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#fileID`.

`function`

The function this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#function`.

`line`

The line this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#line`.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/subscript(metadatakey:)

#app-main)

- Logging
- StreamLogHandler
- subscript(metadataKey:)

Instance Subscript

# subscript(metadataKey:)

Add, change, or remove a logging metadata item.

Logging.swift

## Overview

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/loglevel

- Logging
- StreamLogHandler
- logLevel

Instance Property

# logLevel

Get the log level configured for this `Logger`.

var logLevel: Logger.Level

Logging.swift

## Discussion

## See Also

### Inspecting a log handler

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

`var metadataProvider: Logger.MetadataProvider?`

The metadata provider.

- logLevel
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/metadata

- Logging
- StreamLogHandler
- metadata

Instance Property

# metadata

Get or set the entire metadata storage as a dictionary.

var metadata: Logger.Metadata { get set }

Logging.swift

## See Also

### Inspecting a log handler

`var logLevel: Logger.Level`

Get the log level configured for this `Logger`.

`var metadataProvider: Logger.MetadataProvider?`

The metadata provider.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/loghandler-implementations



---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/metadataprovider)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/standardoutput(label:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/standardoutput(label:metadataprovider:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/standarderror(label:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/standarderror(label:metadataprovider:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/log(level:message:metadata:source:file:function:line:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/subscript(metadatakey:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/loglevel)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/metadata)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/streamloghandler/loghandler-implementations)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level

- Logging
- Logger
- Logger.Level

Enumeration

# Logger.Level

The log level.

enum Level

Logging.swift

## Mentioned in

001: Choosing log levels

Understanding Loggers and Log Handlers

## Overview

Log levels are ordered by their severity, with `.trace` being the least severe and `.critical` being the most severe.

## Topics

### Log Levels

`case trace`

Appropriate for messages that contain information normally of use only when tracing the execution of a program.

`case debug`

Appropriate for messages that contain information normally of use only when debugging a program.

`case info`

Appropriate for informational messages.

`case notice`

Appropriate for conditions that are not error conditions, but that may require special handling.

`case warning`

Appropriate for messages that are not error conditions, but more severe than notice.

`case error`

Appropriate for error conditions.

`case critical`

Appropriate for critical error conditions that usually require immediate attention.

### Initializers

`init?(rawValue: String)`

## Relationships

### Conforms To

- `Swift.CaseIterable`
- `Swift.Comparable`
- `Swift.Copyable`
- `Swift.Decodable`
- `Swift.Encodable`
- `Swift.Equatable`
- `Swift.Hashable`
- `Swift.RawRepresentable`
- `Swift.Sendable`
- `Swift.SendableMetatype`

## See Also

### Sending general log messages

Log a message using the log level you provide.

Log a message using the log level and source that you provide.

`struct Message`

The content of log message.

`typealias Metadata`

The type of the metadata storage.

- Logger.Level
- Mentioned in
- Overview
- Topics
- Relationships
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/trace



---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/debug

- Logging
- Logger
- Logger.Level
- Logger.Level.debug

Case

# Logger.Level.debug

Appropriate for messages that contain information normally of use only when debugging a program.

case debug

Logging.swift

## Mentioned in

001: Choosing log levels

Understanding Loggers and Log Handlers

## See Also

### Log Levels

`case trace`

Appropriate for messages that contain information normally of use only when tracing the execution of a program.

`case info`

Appropriate for informational messages.

`case notice`

Appropriate for conditions that are not error conditions, but that may require special handling.

`case warning`

Appropriate for messages that are not error conditions, but more severe than notice.

`case error`

Appropriate for error conditions.

`case critical`

Appropriate for critical error conditions that usually require immediate attention.

- Logger.Level.debug
- Mentioned in
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/info

- Logging
- Logger
- Logger.Level
- Logger.Level.info

Case

# Logger.Level.info

Appropriate for informational messages.

case info

Logging.swift

## Mentioned in

001: Choosing log levels

Understanding Loggers and Log Handlers

## See Also

### Log Levels

`case trace`

Appropriate for messages that contain information normally of use only when tracing the execution of a program.

`case debug`

Appropriate for messages that contain information normally of use only when debugging a program.

`case notice`

Appropriate for conditions that are not error conditions, but that may require special handling.

`case warning`

Appropriate for messages that are not error conditions, but more severe than notice.

`case error`

Appropriate for error conditions.

`case critical`

Appropriate for critical error conditions that usually require immediate attention.

- Logger.Level.info
- Mentioned in
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/notice

- Logging
- Logger
- Logger.Level
- Logger.Level.notice

Case

# Logger.Level.notice

Appropriate for conditions that are not error conditions, but that may require special handling.

case notice

Logging.swift

## Mentioned in

001: Choosing log levels

Understanding Loggers and Log Handlers

## See Also

### Log Levels

`case trace`

Appropriate for messages that contain information normally of use only when tracing the execution of a program.

`case debug`

Appropriate for messages that contain information normally of use only when debugging a program.

`case info`

Appropriate for informational messages.

`case warning`

Appropriate for messages that are not error conditions, but more severe than notice.

`case error`

Appropriate for error conditions.

`case critical`

Appropriate for critical error conditions that usually require immediate attention.

- Logger.Level.notice
- Mentioned in
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/warning

- Logging
- Logger
- Logger.Level
- Logger.Level.warning

Case

# Logger.Level.warning

Appropriate for messages that are not error conditions, but more severe than notice.

case warning

Logging.swift

## Mentioned in

001: Choosing log levels

Understanding Loggers and Log Handlers

## See Also

### Log Levels

`case trace`

Appropriate for messages that contain information normally of use only when tracing the execution of a program.

`case debug`

Appropriate for messages that contain information normally of use only when debugging a program.

`case info`

Appropriate for informational messages.

`case notice`

Appropriate for conditions that are not error conditions, but that may require special handling.

`case error`

Appropriate for error conditions.

`case critical`

Appropriate for critical error conditions that usually require immediate attention.

- Logger.Level.warning
- Mentioned in
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/error

- Logging
- Logger
- Logger.Level
- Logger.Level.error

Case

# Logger.Level.error

Appropriate for error conditions.

case error

Logging.swift

## Mentioned in

001: Choosing log levels

Understanding Loggers and Log Handlers

## See Also

### Log Levels

`case trace`

Appropriate for messages that contain information normally of use only when tracing the execution of a program.

`case debug`

Appropriate for messages that contain information normally of use only when debugging a program.

`case info`

Appropriate for informational messages.

`case notice`

Appropriate for conditions that are not error conditions, but that may require special handling.

`case warning`

Appropriate for messages that are not error conditions, but more severe than notice.

`case critical`

Appropriate for critical error conditions that usually require immediate attention.

- Logger.Level.error
- Mentioned in
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/critical

- Logging
- Logger
- Logger.Level
- Logger.Level.critical

Case

# Logger.Level.critical

Appropriate for critical error conditions that usually require immediate attention.

case critical

Logging.swift

## Mentioned in

001: Choosing log levels

Understanding Loggers and Log Handlers

## Discussion

When a `critical` message is logged, the logging backend (`LogHandler`) is free to perform more heavy-weight operations to capture system state (such as capturing stack traces) to facilitate debugging.

## See Also

### Log Levels

`case trace`

Appropriate for messages that contain information normally of use only when tracing the execution of a program.

`case debug`

Appropriate for messages that contain information normally of use only when debugging a program.

`case info`

Appropriate for informational messages.

`case notice`

Appropriate for conditions that are not error conditions, but that may require special handling.

`case warning`

Appropriate for messages that are not error conditions, but more severe than notice.

`case error`

Appropriate for error conditions.

- Logger.Level.critical
- Mentioned in
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/001-choosingloglevels

- Logging
- Logging best practices
- 001: Choosing log levels

Article

# 001: Choosing log levels

Select appropriate log levels in applications and libraries.

## Overview

SwiftLog defines seven log levels, and choosing the right level is crucial for creating well-behaved libraries that don’t overwhelm logging systems or misuse severity levels. This practice provides clear guidance on when to use each level.

### Motivation

Libraries must be well-behaved across various use cases and cannot assume specific logging backend configurations. Using inappropriate log levels can flood production logs, trigger false alerts, or make debugging more difficult. Following consistent log level guidelines ensures your library integrates well with diverse application environments.

### Log levels

SwiftLog defines seven log levels via `Logger.Level`, ordered from least to most severe:

- `Logger.Level.trace`

- `Logger.Level.debug`

- `Logger.Level.info`

- `Logger.Level.notice`

- `Logger.Level.warning`

- `Logger.Level.error`

- `Logger.Level.critical`

### Level guidelines

How you use log levels depends in large part if you are developing a library, or an application which bootstraps its logging system and is in full control over its logging environment.

#### For libraries

Libraries should use **info level or less severe** (info, debug, trace).

Libraries **should not** log information on **warning or more severe levels**, unless it is a one-time (for example during startup) warning, that cannot lead to overwhelming log outputs.

Each level serves different purposes:

##### Trace Level

- **Usage**: Log everything needed to diagnose hard-to-reproduce bugs.

- **Performance**: May impact performance; assume it won’t be used in production.

- **Content**: Internal state, detailed operation flows, diagnostic information.

##### Debug Level

- **Usage**: May be enabled in some production deployments.

- **Performance**: Should not significantly undermine production performance.

- **Content**: High-level operation overview, connection events, major decisions.

##### Info Level

- **Usage**: Reserved for things that went wrong but can’t be communicated through other means, like throwing from a method.

- **Examples**: Connection retry attempts, fallback mechanisms, recoverable failures.

- **Guideline**: Use sparingly - Don’t use for normal successful operations.

#### For applications

Applications can use **any level** depending on the context and what they want to achieve. Applications have full control over their logging strategy.

#### Configuring logger log levels

It depends on the use-case of your application which log level your logger should use. For **console and other end-user-visible displays**: Consider using **notice level** as the minimum visible level to avoid overwhelming users with technical details.

#### Recommended: Libraries should use info level or lower

// ✅ Good: Trace level for detailed diagnostics
logger.trace("Connection pool state", metadata: [\
"active": "\(activeConnections)",\
"idle": "\(idleConnections)",\
"pending": "\(pendingRequests)"\
])

// ✅ Good: Debug level for high-value operational info
logger.debug("Database connection established", metadata: [\
"host": "\(host)",\
"database": "\(database)",\
"connectionTime": "\(duration)"\
])

// ✅ Good: Info level for issues that can't be communicated through other means
logger.info("Connection failed, retrying", metadata: [\
"attempt": "\(attemptNumber)",\
"maxRetries": "\(maxRetries)",\
"host": "\(host)"\
])

#### Use sparingly: Warning and error levels

// ✅ Good: One-time startup warning or error
logger.warning("Deprecated TLS version detected. Consider upgrading to TLS 1.3")

#### Avoid: Logging potentially intentional failures at info level

Some failures may be completely intentional from the high-level perspective of a developer or system using your library. For example: failure to resolve a domain, failure to make a request, or failure to complete some task;

Instead, log at debug or trace levels and offer alternative ways to observe these behaviors, for example using `swift-metrics` to emit counts.

// ❌ Bad: Normal operations at info level flood production logs
logger.info("Request failed")

#### Avoid: Normal operations at info level

// ❌ Bad: Normal operations at info level flood production logs
logger.info("HTTP request received")
logger.info("Database query executed")
logger.info("Response sent")

// ✅ Good: Use appropriate levels instead
logger.debug("Processing request", metadata: ["path": "\(path)"])
logger.trace("Query", metadata: ["sql": "\(query)"])
logger.debug("Request completed", metadata: ["status": "\(status)"])

## See Also

002: Structured logging

Use metadata to create machine-readable, searchable log entries.

003: Accepting loggers in libraries

Accept loggers through method parameters to ensure proper metadata propagation.

- 001: Choosing log levels
- Overview
- Motivation
- Log levels
- Level guidelines
- Example
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level),

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/trace)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/debug)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/info)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/notice)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/warning)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/error)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger/level/critical)



---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/001-choosingloglevels).

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/init()

#app-main)

- Logging
- SwiftLogNoOpLogHandler
- init()

Initializer

# init()

Creates a no-op log handler.

init()

Logging.swift

## See Also

### Creating a Swift Log no-op log handler

`init(String)`

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/init(_:)

#app-main)

- Logging
- SwiftLogNoOpLogHandler
- init(\_:)

Initializer

# init(\_:)

Creates a no-op log handler.

init(_: String)

Logging.swift

## See Also

### Creating a Swift Log no-op log handler

`init()`

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/log(level:message:metadata:source:file:function:line:)

#app-main)

- Logging
- SwiftLogNoOpLogHandler
- log(level:message:metadata:source:file:function:line:)

Instance Method

# log(level:message:metadata:source:file:function:line:)

A proxy that discards every log message that you provide.

func log(
level: Logger.Level,
message: Logger.Message,
metadata: Logger.Metadata?,
source: String,
file: String,
function: String,
line: UInt
)

Logging.swift

## Parameters

`level`

The log level to log the `message`.

`message`

The message to be logged. The `message` parameter supports any string interpolation literal.

`metadata`

One-off metadata to attach to this log message.

`source`

The source this log message originates from. The value defaults to the module that emits the log message.

`file`

The file this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#fileID`.

`function`

The function this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#function`.

`line`

The line this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#line`.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/subscript(metadatakey:)

#app-main)

- Logging
- SwiftLogNoOpLogHandler
- subscript(metadataKey:)

Instance Subscript

# subscript(metadataKey:)

Add, change, or remove a logging metadata item.

Logging.swift

## Overview

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/loglevel

- Logging
- SwiftLogNoOpLogHandler
- logLevel

Instance Property

# logLevel

Get or set the log level configured for this `Logger`.

var logLevel: Logger.Level { get set }

Logging.swift

## Discussion

## See Also

### Inspecting a log handler

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

`var metadataProvider: Logger.MetadataProvider?`

Default implementation for a metadata provider that defaults to nil.

- logLevel
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/metadata

- Logging
- SwiftLogNoOpLogHandler
- metadata

Instance Property

# metadata

Get or set the entire metadata storage as a dictionary.

var metadata: Logger.Metadata { get set }

Logging.swift

## See Also

### Inspecting a log handler

`var logLevel: Logger.Level`

Get or set the log level configured for this `Logger`.

`var metadataProvider: Logger.MetadataProvider?`

Default implementation for a metadata provider that defaults to nil.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/metadataprovider

- Logging
- SwiftLogNoOpLogHandler
- metadataProvider

Instance Property

# metadataProvider

Default implementation for a metadata provider that defaults to nil.

var metadataProvider: Logger.MetadataProvider? { get set }

LogHandler.swift

## Discussion

This default exists in order to facilitate the source-compatible introduction of the `metadataProvider` protocol requirement.

## See Also

### Inspecting a log handler

`var logLevel: Logger.Level`

Get or set the log level configured for this `Logger`.

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

- metadataProvider
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/log(level:message:metadata:file:function:line:)

#app-main)

- Logging
- SwiftLogNoOpLogHandler
- log(level:message:metadata:file:function:line:)

Instance Method

# log(level:message:metadata:file:function:line:)

A proxy that discards every log message it receives.

func log(
level: Logger.Level,
message: Logger.Message,
metadata: Logger.Metadata?,
file: String,
function: String,
line: UInt
)

Logging.swift

## Parameters

`level`

The log level to log the `message`.

`message`

The message to be logged. The `message` parameter supports any string interpolation literal.

`metadata`

One-off metadata to attach to this log message.

`file`

The file this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#fileID`.

`function`

The function this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#function`.

`line`

The line this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#line`.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/loghandler-implementations

- Logging
- SwiftLogNoOpLogHandler
- LogHandler Implementations

API Collection

# LogHandler Implementations

## Topics

### Instance Properties

`var metadataProvider: Logger.MetadataProvider?`

Default implementation for a metadata provider that defaults to nil.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/init())

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/init(_:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/log(level:message:metadata:source:file:function:line:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/subscript(metadatakey:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/loglevel)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/metadata)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/metadataprovider)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/log(level:message:metadata:file:function:line:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/swiftlognooploghandler/loghandler-implementations)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/002-structuredlogging

- Logging
- Logging best practices
- 002: Structured logging

Article

# 002: Structured logging

Use metadata to create machine-readable, searchable log entries.

## Overview

Structured logging uses metadata to separate human-readable messages from machine-readable data. This practice makes logs easier to search, filter, and analyze programmatically while maintaining readability.

### Motivation

Traditional string-based logging embeds all information in the message text, making it more difficult for automated tools to parse and extract. Structured logging separates these concerns; messages provide human readable context while metadata provides structured data for tooling.

#### Recommended: Structured logging

// ✅ Structured - message provides context, metadata provides data
logger.info(
"Accepted connection",
metadata: [\
"connection.id": "\(id)",\
"connection.peer": "\(peer)",\
"connections.total": "\(count)"\
]
)

logger.error(
"Database query failed",
metadata: [\
"query.retries": "\(retries)",\
"query.error": "\(error)",\
"query.duration": "\(duration)"\
]
)

### Advanced: Nested metadata for complex data

// ✅ Complex structured data
logger.trace(
"HTTP request started",
metadata: [\
"request.id": "\(requestId)",\
"request.method": "GET",\
"request.path": "/api/users",\
"request.headers": [\
"user-agent": "\(userAgent)"\
],\
"client.ip": "\(clientIP)",\
"client.country": "\(country)"\
]
)

#### Avoid: Unstructured logging

// ❌ Not structured - hard to parse programmatically
logger.info("Accepted connection \(id) from \(peer), total: \(count)")
logger.error("Database query failed after \(retries) retries: \(error)")

### Metadata key conventions

Use hierarchical dot-notation for related fields:

// ✅ Good: Hierarchical keys
logger.debug(
"Database operation completed",
metadata: [\
"db.operation": "SELECT",\
"db.table": "users",\
"db.duration": "\(duration)",\
"db.rows": "\(rowCount)"\
]
)

// ✅ Good: Consistent prefixing
logger.info(
"HTTP response",
metadata: [\
"http.method": "POST",\
"http.status": "201",\
"http.path": "/api/users",\
"http.duration": "\(duration)"\
]
)

## See Also

001: Choosing log levels

Select appropriate log levels in applications and libraries.

003: Accepting loggers in libraries

Accept loggers through method parameters to ensure proper metadata propagation.

- 002: Structured logging
- Overview
- Motivation
- Example
- Advanced: Nested metadata for complex data
- Metadata key conventions
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/003-acceptingloggers

- Logging
- Logging best practices
- 003: Accepting loggers in libraries

Article

# 003: Accepting loggers in libraries

Accept loggers through method parameters to ensure proper metadata propagation.

## Overview

Libraries should accept logger instances through method parameters rather than storing them as instance variables. This practice ensures metadata (such as correlation IDs) is properly propagated down the call stack, while giving applications control over logging configuration.

### Motivation

When libraries accept loggers as method parameters, they enable automatic propagation of contextual metadata attached to the logger instance. This is especially important for distributed systems where correlation IDs must flow through the entire request processing pipeline.

#### Recommended: Accept logger through method parameters

// ✅ Good: Pass the logger through method parameters.
struct RequestProcessor {

// Add structured metadata that every log statement should contain.
var logger = logger
logger[metadataKey: "request.method"] = "\(request.method)"
logger[metadataKey: "request.path"] = "\(request.path)"
logger[metadataKey: "request.id"] = "\(request.id)"

logger.debug("Processing request")

// Pass the logger down to maintain metadata context.
let validatedData = try validateRequest(request, logger: logger)
let result = try await executeBusinessLogic(validatedData, logger: logger)

logger.debug("Request processed successfully")
return result
}

logger.debug("Validating request parameters")
// Include validation logic that uses the same logger context.
return ValidatedRequest(request)
}

logger.debug("Executing business logic")

// Further propagate the logger to other services.
let dbResult = try await databaseService.query(data.query, logger: logger)

logger.debug("Business logic completed")
return HTTPResponse(data: dbResult)
}
}

#### Alternative: Accept logger through initializer when appropriate

// ✅ Acceptable: Logger through initializer for long-lived components
final class BackgroundJobProcessor {
private let logger: Logger

init(logger: Logger) {
self.logger = logger
}

func run() async {
// Execute some long running work
logger.debug("Update about long running work")
// Execute some more long running work
}
}

#### Avoid: Libraries creating their own loggers

Libraries might create their own loggers; however, this leads to two problems. First, users of the library can’t inject their own loggers which means they have no control in customizing the log level or log handler. Secondly, it breaks the metadata propagation since users can’t pass in a logger with already attached metadata.

// ❌ Bad: Library creates its own logger
final class MyLibrary {
private let logger = Logger(label: "MyLibrary") // Loses all context
}

// ✅ Good: Library accepts logger from caller
final class MyLibrary {
func operation(logger: Logger) {
// Maintains caller's context and metadata
}
}

## See Also

001: Choosing log levels

Select appropriate log levels in applications and libraries.

002: Structured logging

Use metadata to create machine-readable, searchable log entries.

- 003: Accepting loggers in libraries
- Overview
- Motivation
- Example
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/001-choosingloglevels)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/002-structuredlogging)



---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/003-acceptingloggers)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/log(level:message:metadata:source:file:function:line:)

#app-main)

- Logging
- MultiplexLogHandler
- log(level:message:metadata:source:file:function:line:)

Instance Method

# log(level:message:metadata:source:file:function:line:)

Log a message using the log level and source that you provide.

func log(
level: Logger.Level,
message: Logger.Message,
metadata: Logger.Metadata?,
source: String,
file: String,
function: String,
line: UInt
)

Logging.swift

## Parameters

`level`

The log level to log the `message`.

`message`

The message to be logged. The `message` parameter supports any string interpolation literal.

`metadata`

One-off metadata to attach to this log message.

`source`

The source this log message originates from. The value defaults to the module that emits the log message.

`file`

The file this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#fileID`.

`function`

The function this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#function`.

`line`

The line this log message originates from. There’s usually no need to pass it explicitly, as it defaults to `#line`.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/subscript(metadatakey:)

#app-main)

- Logging
- MultiplexLogHandler
- subscript(metadataKey:)

Instance Subscript

# subscript(metadataKey:)

Add, change, or remove a logging metadata item.

Logging.swift

## Overview

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/loglevel

- Logging
- MultiplexLogHandler
- logLevel

Instance Property

# logLevel

Get or set the log level configured for this `Logger`.

var logLevel: Logger.Level { get set }

Logging.swift

## Discussion

## See Also

### Inspecting a log handler

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

`var metadataProvider: Logger.MetadataProvider?`

The metadata provider.

- logLevel
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/metadata

- Logging
- MultiplexLogHandler
- metadata

Instance Property

# metadata

Get or set the entire metadata storage as a dictionary.

var metadata: Logger.Metadata { get set }

Logging.swift

## See Also

### Inspecting a log handler

`var logLevel: Logger.Level`

Get or set the log level configured for this `Logger`.

`var metadataProvider: Logger.MetadataProvider?`

The metadata provider.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/metadataprovider



---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/loghandler-implementations

- Logging
- MultiplexLogHandler
- LogHandler Implementations

API Collection

# LogHandler Implementations

## Topics

### Instance Methods

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt)`

A default implementation for a log message handler.

Deprecated

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/init(_:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/init(_:metadataprovider:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/log(level:message:metadata:source:file:function:line:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/subscript(metadatakey:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/loglevel)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/metadata)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/metadataprovider)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/multiplexloghandler/loghandler-implementations)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/log(level:message:metadata:source:file:function:line:)

#app-main)

- Logging
- LogHandler
- log(level:message:metadata:source:file:function:line:)

Instance Method

# log(level:message:metadata:source:file:function:line:)

The library calls this method when a log handler must emit a log message.

func log(
level: Logger.Level,
message: Logger.Message,
metadata: Logger.Metadata?,
source: String,
file: String,
function: String,
line: UInt
)

LogHandler.swift

**Required** Default implementation provided.

## Parameters

`level`

The log level of the message.

`message`

The message to log. To obtain a `String` representation call `message.description`.

`metadata`

The metadata associated to this log message.

`source`

The source where the log message originated, for example the logging module.

`file`

The file this log message originates from.

`function`

The function this log message originates from.

`line`

The line this log message originates from.

## Discussion

There is no need for the `LogHandler` to check if the `level` is above or below the configured `logLevel` as `Logger` already performed this check and determined that a message should be logged.

## Default Implementations

### LogHandler Implementations

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt)`

A default implementation for a log message handler that forwards the source location for the message.

Deprecated

## See Also

### Sending log messages

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt)`

SwiftLog 1.0 log compatibility method.

A default implementation for a log message handler.

- log(level:message:metadata:source:file:function:line:)
- Parameters
- Discussion
- Default Implementations
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/log(level:message:metadata:source:file:function:line:)-69pez



---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/log(level:message:metadata:file:function:line:)

#app-main)

- Logging
- LogHandler
- log(level:message:metadata:file:function:line:)

Instance Method

# log(level:message:metadata:file:function:line:)

SwiftLog 1.0 log compatibility method.

func log(
level: Logger.Level,
message: Logger.Message,
metadata: Logger.Metadata?,
file: String,
function: String,
line: UInt
)

LogHandler.swift

**Required** Default implementation provided.

## Parameters

`level`

The log level of the message.

`message`

The message to log. To obtain a `String` representation call `message.description`.

`metadata`

The metadata associated to this log message.

`file`

The file this log message originates from.

`function`

The function this log message originates from.

`line`

The line this log message originates from.

## Discussion

Please do _not_ implement this method when you create a LogHandler implementation. Implement `log(level:message:metadata:source:file:function:line:)` instead.

## Default Implementations

### LogHandler Implementations

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt)`

A default implementation for a log message handler.

Deprecated

## See Also

### Sending log messages

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt)`

The library calls this method when a log handler must emit a log message.

A default implementation for a log message handler that forwards the source location for the message.

- log(level:message:metadata:file:function:line:)
- Parameters
- Discussion
- Default Implementations
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/log(level:message:metadata:file:function:line:)-1xdau

-1xdau#app-main)

- Logging
- LogHandler
- log(level:message:metadata:file:function:line:)

Instance Method

# log(level:message:metadata:file:function:line:)

A default implementation for a log message handler.

func log(
level: Logger.Level,
message: Logger.Message,
metadata: Logger.Metadata?,
file: String,
function: String,
line: UInt
)

LogHandler.swift

## Parameters

`level`

The log level of the message.

`message`

The message to log. To obtain a `String` representation call `message.description`.

`metadata`

The metadata associated to this log message.

`file`

The file this log message originates from.

`function`

The function this log message originates from.

`line`

The line this log message originates from.

## See Also

### Sending log messages

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt)`

The library calls this method when a log handler must emit a log message.

**Required** Default implementation provided.

A default implementation for a log message handler that forwards the source location for the message.

Deprecated

`func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt)`

SwiftLog 1.0 log compatibility method.

- log(level:message:metadata:file:function:line:)
- Parameters
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/subscript(metadatakey:)

#app-main)

- Logging
- LogHandler
- subscript(metadataKey:)

Instance Subscript

# subscript(metadataKey:)

Add, remove, or change the logging metadata.

LogHandler.swift

**Required**

## Parameters

`metadataKey`

The key for the metadata item

## Overview

- subscript(metadataKey:)
- Parameters
- Overview

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/loglevel

- Logging
- LogHandler
- logLevel

Instance Property

# logLevel

Get or set the configured log level.

var logLevel: Logger.Level { get set }

LogHandler.swift

**Required**

## Discussion

## See Also

### Inspecting a log handler

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

`var metadataProvider: Logger.MetadataProvider?`

The metadata provider this log handler uses when a log statement is about to be emitted.

**Required** Default implementation provided.

- logLevel
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/metadata

- Logging
- LogHandler
- metadata

Instance Property

# metadata

Get or set the entire metadata storage as a dictionary.

var metadata: Logger.Metadata { get set }

LogHandler.swift

**Required**

## Discussion

## See Also

### Inspecting a log handler

`var logLevel: Logger.Level`

Get or set the configured log level.

`var metadataProvider: Logger.MetadataProvider?`

The metadata provider this log handler uses when a log statement is about to be emitted.

**Required** Default implementation provided.

- metadata
- Discussion
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/metadataprovider

- Logging
- LogHandler
- metadataProvider

Instance Property

# metadataProvider

The metadata provider this log handler uses when a log statement is about to be emitted.

var metadataProvider: Logger.MetadataProvider? { get set }

LogHandler.swift

**Required** Default implementation provided.

## Discussion

A `Logger.MetadataProvider` may add a constant set of metadata, or use task-local values to pick up contextual metadata and add it to emitted logs.

## Default Implementations

### LogHandler Implementations

`var metadataProvider: Logger.MetadataProvider?`

Default implementation for a metadata provider that defaults to nil.

## See Also

### Inspecting a log handler

`var logLevel: Logger.Level`

Get or set the configured log level.

**Required**

`var metadata: Logger.Metadata`

Get or set the entire metadata storage as a dictionary.

- metadataProvider
- Discussion
- Default Implementations
- See Also

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/logger).

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/log(level:message:metadata:source:file:function:line:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/log(level:message:metadata:source:file:function:line:)-69pez)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/log(level:message:metadata:file:function:line:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/log(level:message:metadata:file:function:line:)-1xdau)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/subscript(metadatakey:))

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/loglevel)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/metadata)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

# https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/loghandler/metadataprovider)

Has it really been five years since Swift Package Index launched? Read our anniversary blog post!

#### 404 - Not Found

If you were expecting to find a page here, please raise an issue.

From here, you'll want to go to the home page or search for a package.

|
|

---

