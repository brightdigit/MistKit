# Configuring MistKit

There is no single `MistKitConfiguration` type — configuration is what you pass to ``CloudKitService``: a container identifier, an ``Environment``, ``Credentials``, and (optionally) a custom transport.

## Overview

A configured MistKit setup is one call:

```swift
let service = CloudKitService(
  containerIdentifier: "iCloud.com.example.MyApp",
  credentials: credentials,
  environment: .production
)
```

Everything else — which ``Database`` to use, which signing method on the public database, which token to refresh — is decided per call. This article covers the construction-time inputs (container, environment, transport, logging). For credentials and per-call database selection, see <doc:AuthenticationAndDatabases>.

## Container identifier

The container identifier is the iCloud container your records live in. It is the same string you see in the CloudKit Dashboard under **Container ID**, prefixed with `iCloud.`:

```swift
"iCloud.com.example.MyApp"
```

A single container has separate `development` and `production` schemas, separate record stores, and separate user data. You do not switch containers between environments — you switch ``Environment``.

> Tip: Containers are configured in the [CloudKit Dashboard](https://icloud.developer.apple.com). The container identifier is also visible in your Xcode app target's CloudKit capability.

## Environment selection

``Environment`` has two cases: ``Environment/development`` and ``Environment/production``. They map to distinct CloudKit schemas and stores in the same container:

| Environment | Used for |
| --- | --- |
| `.development` | Schema migrations, local testing, staging deploys |
| `.production` | Released apps, production backends |

Drive the choice from configuration, not source:

```swift
let environment: Environment = ProcessInfo.processInfo
  .environment["CLOUDKIT_ENVIRONMENT"]
  .flatMap(Environment.init(caseInsensitive:))
  ?? .development
```

``Environment/init(caseInsensitive:)`` accepts `"development"` / `"production"` regardless of letter case and returns `nil` on anything else, so a misspelled env var fails closed at startup rather than silently shipping a dev build to prod.

> Warning: CloudKit promotes schema from `development` to `production` explicitly via the Dashboard. Code referencing fields that exist only in dev will succeed against `.development` and fail against `.production` with ``CloudKitError/httpErrorWithDetails(statusCode:serverErrorCode:reason:)``.

## Database scope at configuration time

``CloudKitService`` itself is database-agnostic — there is no `database:` parameter on the initializer. You pick the scope at each call site:

```swift
try await service.queryRecords(recordType: "Note", database: .private)
try await service.createRecord(
  recordType: "FeaturedPost",
  fields: fields,
  database: .public(.requires(.serverToServer))
)
```

The configuration question for your app is: which credentials does the deployment need to populate so the call sites it makes are reachable? An app that only queries the private database needs a web-auth token. An app that also seeds the public database with server-attributed writes needs server-to-server credentials. An app that does both populates both fields on ``Credentials``. See <doc:AuthenticationAndDatabases> for the full credential/database matrix.

## Custom transport

The default public initializer uses `URLSessionTransport` from `swift-openapi-urlsession`. For testing, request inspection, or platforms without URLSession, supply your own ``ClientTransport`` via the generic initializer:

```swift
let service = CloudKitService(
  containerIdentifier: container,
  credentials: credentials,
  environment: .development,
  transport: customTransport
)
```

Common reasons to override the transport:

- **Tests** — substitute a mock transport that asserts on outgoing requests and returns canned responses.
- **Instrumentation** — wrap `URLSessionTransport` to record request/response pairs for debugging.
- **WASI** — `URLSession` is unavailable, so the WASI build path requires a transport you provide (the public URLSession initializer is gated behind `#if !os(WASI)`).

> Warning: Asset uploads do **not** flow through the configured `transport`. They use `URLSession.shared` directly to avoid HTTP/2 connection reuse between CloudKit's API host and the CDN, which surfaces as 421 Misdirected Request errors. See <doc:CloudKitLimitsAndPerformance> for the full rationale.

## Logging

MistKit uses [swift-log](https://github.com/apple/swift-log). The package emits to four labeled subsystems; consumers install a `LogHandler` and choose verbosity per subsystem.

| Subsystem label | Use |
| --- | --- |
| `com.brightdigit.MistKit.api` | CloudKit API operations |
| `com.brightdigit.MistKit.auth` | Authentication and token management |
| `com.brightdigit.MistKit.network` | Network errors |
| `com.brightdigit.MistKit.middleware` | HTTP request/response traces (debug only) |

Bootstrap the logging system once at process start:

```swift
import Logging

LoggingSystem.bootstrap(StreamLogHandler.standardOutput)
```

To raise the middleware subsystem to `.debug` for troubleshooting without flooding the rest:

```swift
LoggingSystem.bootstrap { label in
  var handler = StreamLogHandler.standardOutput(label: label)
  if label == "com.brightdigit.MistKit.middleware" {
    handler.logLevel = .debug
  }
  return handler
}
```

> Note: Protocol traces — request/response bodies, headers, query params — are only emitted at `.debug`. The middleware guards expensive work (1 MiB body collection, query-param parsing) behind a level check, so the default `.info` level pays no overhead.

There is no built-in redaction. Sensitive data (tokens, raw bodies) appears only at `.debug`; control exposure by leaving the middleware subsystem at `.info` or higher in production.

## Environment-variable patterns

MistKit doesn't prescribe a secrets store, but the conventional env-var names line up with what's documented in <doc:AuthenticationAndDatabases> and used by the in-repo `MistDemo` integration runner:

| Variable | Used for |
| --- | --- |
| `CLOUDKIT_CONTAINER` | Container identifier |
| `CLOUDKIT_ENVIRONMENT` | `development` or `production` |
| `CLOUDKIT_API_TOKEN` | API token (public database read, web-auth attribution) |
| `CLOUDKIT_WEB_AUTH_TOKEN` | Web-auth token (private/shared, user-identity routes) |
| `CLOUDKIT_KEY_ID` | Server-to-server key ID |
| `CLOUDKIT_PRIVATE_KEY` / `CLOUDKIT_PRIVATE_KEY_PATH` | ECDSA P-256 PEM material (inline or file) |

A small helper keeps call sites tidy and fails closed on missing values:

```swift
func env(_ key: String) throws -> String {
  guard let value = ProcessInfo.processInfo.environment[key],
        !value.isEmpty else {
    throw ConfigError.missing(key)
  }
  return value
}
```

> Tip: Validate every required variable at startup, before constructing ``CloudKitService``. Missing or malformed credentials surface as ``CloudKitError/missingCredentials(database:availability:reason:)`` at the first call that needs them — much later than you want to discover the deployment is misconfigured.

## Topics

### Configuration

- ``CloudKitService``
- ``Environment``
- ``Database``

### See Also

- <doc:AuthenticationAndDatabases>
- <doc:HandlingErrors>
- <doc:CloudKitLimitsAndPerformance>
