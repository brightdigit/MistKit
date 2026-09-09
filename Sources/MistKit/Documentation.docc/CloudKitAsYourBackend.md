# CloudKit as Your Backend

From iOS to server-side Swift — the talk behind MistKit, consolidated into one article.

## Overview

CloudKit is great for iOS apps. How about backend services? This article is the written form of a conference talk by Leo Dion ([@leogdion@c.im](https://c.im/@leogdion)) that walks from "what is CloudKit" to a scheduled GitHub Actions job writing to a CloudKit public database from a stock Ubuntu runner, and explains the three problems that shaped MistKit along the way: authentication, field-type polymorphism, and error handling.

The talk was given in 2026 at Swift Craft, Swift Rockies (Calgary), and iOSDevUK (Aberystwyth). The abstract:

> CloudKit has excellent documentation for iOS and macOS client development. But backend services — podcast aggregation, RSS readers, data processing — face APIs that Apple barely documents. I rebuilt a comprehensive CloudKit library using AI-generated OpenAPI specifications. The result: type-safe Swift code supporting three authentication methods (server-to-server, web authentication token, and API token), typed error handling, and production deployments.

The sections below follow the slide order. Every code sample is taken from the current MistKit source or its example projects, so the article stays accurate as the library evolves. A complete list of the links shown during the talk is at the end, in <doc:CloudKitAsYourBackend#Links>.

## Table of Contents

- [Overview](#overview)
- [What is CloudKit](#what-is-cloudkit)
- [What is CloudKit Web Services](#what-is-cloudkit-web-services)
- [Why server-side CloudKit](#why-server-side-cloudkit)
    - [Private database: Heartwitch](#private-database-heartwitch)
    - [Public database: Bushel](#public-database-bushel)
- [Building MistKit](#building-mistkit)
- [Authentication](#authentication)
    - [API token](#api-token)
    - [Web auth token](#web-auth-token)
    - [Server to server](#server-to-server)
- [Field type polymorphism](#field-type-polymorphism)
- [Error handling](#error-handling)
- [Deployment](#deployment)
- [What's next](#whats-next)
- [Links](#links)
- [Questions](#questions)

## What is CloudKit

Travel back to WWDC 2014 — the year Swift was introduced — and you also find the introduction of CloudKit. The idea was simple: give iOS developers a backend for storage, logic, database, search, and notifications without running a server.

Setting it up is a checkbox in Xcode: enable the **iCloud** capability, tick **CloudKit**, and add a **container**. The container is the storage for your record types and records.

### Records and field types

Records are the main way data is stored. Think of a record as a table row with typed fields. The CloudKit Console lets you create record types and fields interactively; each field has one of nine types:

| CloudKit type | Native framework type | MistKit ``FieldValue`` case |
| --- | --- | --- |
| `STRING` | `String` | ``FieldValue/string(_:)`` |
| `INT64` | `Int` / `NSNumber` | ``FieldValue/int64(_:)`` |
| `DOUBLE` | `Double` / `NSNumber` | ``FieldValue/double(_:)`` |
| `BYTES` | `Data` | ``FieldValue/bytes(_:)`` |
| `TIMESTAMP` | `Date` | ``FieldValue/date(_:)`` |
| `LOCATION` | `CLLocation` | ``FieldValue/location(_:)`` |
| `REFERENCE` | `CKRecord.Reference` | ``FieldValue/reference(_:)`` |
| `ASSET` | `CKAsset` | ``FieldValue/asset(_:)`` |
| `LIST` | `Array` | ``FieldValue/list(_:)`` |

There is no boolean type — CloudKit stores booleans as `INT64` `0`/`1`, which is why MistKit offers ``FieldValue/init(booleanValue:)`` and ``FieldValue/boolValue``.

If you would rather script the schema than click through the console, CloudKit has a text-based schema language and the `cktool` command-line tool ([Integrating a text-based schema into your workflow](https://developer.apple.com/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow)):

```text
RECORD TYPE Note (
    "title"   STRING QUERYABLE SORTABLE SEARCHABLE,
    "index"   INT64 QUERYABLE SORTABLE,
    "image"   ASSET
);
```

Once a record type exists you can add records through the console — this is the `Note` type MistKit's demo apps use:

![CloudKit Console showing Note records in the MistDemo container](talk-cloudkit-console-records)

### Containers, environments, databases, zones

The hierarchy, top to bottom:

```
Container            iCloud.com.example.MyApp   (typically one per app)
 └─ Environment      development | production
     └─ Database     public | private | shared
         └─ Zone     _defaultZone | custom zones
             └─ Record
```

- The **private database** belongs to the signed-in user. Every user gets their own, and it lives in *their* iCloud account: delete the app and the data survives; delete the iCloud account and it is gone.
- The **public database** is shared by every user of the app. Reads do not require a signed-in user; writes do.
- The **shared database** holds records other users have shared with the current user.
- **Environments** let you develop against `development` and promote the schema to `production` from the console when it is ready.

A typical macOS app built on the native CloudKit framework shows the same records the console does:

![The MistDemo macOS app querying Note records](talk-mistdemo-macos)

Everything above is the native, on-device CloudKit story. The rest of the talk is about what happens when the code that needs those records does not run on an Apple device.

## What is CloudKit Web Services

Part of CloudKit's original design was access from the web. There are two ways in:

- **CloudKit JS** — a JavaScript library that gives a browser roughly the same API as the CloudKit framework. If you are running in a browser, use it; MistKit is not for that.
- **CloudKit Web Services** — the REST API underneath. Every operation is a `POST` (or occasionally `GET`) against:

```text
https://api.apple-cloudkit.com/database/{version}/{container}/{environment}/{database}/{operation}
```

The REST API is documented in Apple's *CloudKit Web Services Reference*, which is now in the developer library archive. Its **document revision history ends in 2016**. The API still works — it is what CloudKit JS talks to — but nothing about it has been written down by Apple in a decade, and in several places the archived reference and the live server disagree. <doc:WhatCloudKitGotWrong> catalogs those.

## Why server-side CloudKit

Each database has its own reason to be reached from a server.

### Private database: Heartwitch

[Heartwitch](https://heartwitch.app) is an Apple Watch app that streams a workout's heart rate to a browser overlay so streamers can show it on a live stream. Built before Sign in with Apple existed, it looked like this:

```
Apple Watch ──POST heart rate──▶ Vapor server ──WebSocket──▶ Browser ──▶ OBS overlay
                                     │
                                     └── PostgreSQL (username + password accounts)
```

The website had a username-and-password login. Typing a password on a watch face is a terrible experience, and the watch is already signed in to iCloud — so the watch app wrote its identity to the user's CloudKit private database instead. Linking the two identities happened on the web:

1. The watch app runs and adds an *Apple Watch* record to the user's private database.
2. The user signs in to the website.
3. The website offers "sign in to CloudKit" via CloudKit JS, which yields a web auth token.
4. The server uses that token to read the user's private database, finds the watch record, and stores the watch ID next to the Postgres account.
5. The watch posts heart rate with its watch ID; the Vapor server now knows which user it belongs to and where to stream it.

Step 4 is the important design decision: the server **copies** what it needs out of CloudKit. The private database is owned by the user, not by you, so treat it as an *input* rather than a system of record.

Source: [brightdigit/HeartWitch](https://github.com/brightdigit/HeartWitch).

### Public database: Bushel

[Bushel](https://getbushel.app) is a macOS virtual-machine app for developers. To install a particular macOS version into a VM you need its *restore image*, and Bushel needs to know which images exist, where to download them, whether Apple still signs them, and which Xcode and Swift versions they support.

That data is universal — every Bushel user wants the same list — so it belongs in a **public database**. A scheduled job pulls the data from several upstream sources and writes it into CloudKit; the app just queries the container:

```
GitHub Actions (cron) ──▶ bushel-cloud CLI (MistKit) ──▶ CloudKit public database ◀── Bushel app
        │
        └── IPSW, AppleDB, MESU, VirtualBuddy TSS, Xcode releases, swift.org
```

The same pattern powers [Celestra](https://celestr.app), an RSS reader whose feeds are fetched and synced to a public database on a schedule.

Sources: [brightdigit/BushelCloud](https://github.com/brightdigit/BushelCloud) (also in this repository under `Examples/BushelCloud/`) and [brightdigit/CelestraCloud](https://github.com/brightdigit/CelestraCloud) (`Examples/CelestraCloud/`).

### More use cases

The two stories above generalize into four families:

| Family | Examples |
| --- | --- |
| **Public database as a managed catalog** | Restore-image catalog (Bushel), RSS aggregation (Celestra), software-version catalogs, asset packs for a creative app, feature flags and remote config, MDM configuration catalogs |
| **Private database on behalf of a user** | Linking a wearable to an external service (Heartwitch), sensor-data pipelines to a fitness or research platform, two-way sync with Todoist/Notion/Calendar, server-side processing of a user's uploads (OCR, transcoding, tagging) |
| **Web app ↔ Apple device bridge** | A browser portal for a CloudKit-backed app, a webhook handler (Stripe, GitHub, forms) that writes straight into a user's records |
| **Data aggregation** | Anonymized telemetry read via `records/changes`, crowdsourced data cleaned and written back by a background steward |

Apple's CloudKit framework only runs on Apple platforms. MistKit wraps CloudKit Web Services so server-side Swift, Linux services, and command-line tools can take part in the same containers as your apps.

## Building MistKit

The first MistKit, started in 2020 for Heartwitch, was written by hand, which meant:

- writing each API call from the archived documentation,
- verifying whether that documentation was even correct,
- re-learning CloudKit's architecture piece by piece,
- implementing ECDSA signing for server-to-server authentication,
- and hand-writing two network stacks — `URLSession` for clients and `AsyncHTTPClient` for servers — before `async`/`await`.

Only what Heartwitch needed got implemented. Two things made a full rebuild feasible.

### Swift OpenAPI Generator

[swift-openapi-generator](https://github.com/apple/swift-openapi-generator), announced at WWDC 2023, reads an OpenAPI document and generates a type-safe Swift client. The document describes metadata, servers, paths (with their methods and responses), and reusable component schemas:

```yaml
openapi: 3.1.0
info:
  title: Todo API
  version: 1.0.0
servers:
  - url: https://api.example.com/v1
paths:
  /todos:
    get:
      operationId: listTodos
      responses:
        "200":
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: "#/components/schemas/Todo"
components:
  schemas:
    Todo:
      type: object
      required: [id, title, isCompleted]
      properties:
        id: { type: string }
        title: { type: string }
        isCompleted: { type: boolean }
```

The generator ships transports for `URLSession` and `AsyncHTTPClient`, plus server transports for Vapor, Hummingbird, and Lambda, so one spec covers every place MistKit needs to run. How MistKit drives the generator is in <doc:OpenAPICodeGeneration>; what the output looks like is in <doc:GeneratedCodeAnalysis>.

### Turning the documentation into a spec

The remaining problem was producing an OpenAPI document for an API that only exists as 2016-era prose. That is where AI-assisted development came in: each documented endpoint was fed to an LLM and translated into `openapi.yaml`, then abstractions were built on top. It was not automatic — hallucinated APIs, context-window limits, and unrequested scaffolding (retries, caches, "secure memory") were constant, and the assistant regularly declared success before running the build. The catalog of what went wrong, with evidence, is <doc:WhatTheAIGotWrong>; the narrative version is in the two *Rebuilding MistKit with Claude Code* articles ([part 1](https://brightdigit.com/tutorials/rebuilding-mistkit-claude-code-part-1/), [part 2](https://brightdigit.com/tutorials/rebuilding-mistkit-claude-code-part-2/)).

### Three layers

The result is layered so callers never see the generated code:

```
Your code            service.queryRecords(recordType: "Note", database: .private)
      │
      ▼
MistKit abstraction  CloudKitService · FieldValue · QueryFilter · CloudKitError
      │
      ▼
Generated client     Operations.queryRecords.Input / Output   (swift-openapi-generator)
      │
      ▼
CloudKit Web Services
```

<doc:AbstractionLayerArchitecture> describes each box.

### Proving it works

Unit tests were not enough — the assistant would report success on code that failed the moment it touched a real container. So MistDemo (`Examples/MistDemo/`) exists: a command-line tool with live integration phases (`mistdemo test-public`, `mistdemo test-private`), a macOS app, and a web interface served by Hummingbird that exercises every endpoint through either MistKit or CloudKit JS, side by side:

![The MistKit web demo, switching between MistKit and CloudKit JS backends](talk-mistdemo-web)

MistDemo is the live-verification oracle for everything in this article that describes CloudKit's wire behavior.

## Authentication

On a device, authentication is invisible: the user is signed in to iCloud and the framework does the rest. On a server you have to prove who you are with credentials you manage. Apple documents three methods; it is more honest to call it **two and a half**, because the first one is a prerequisite for the second rather than a peer.

All of them start in the CloudKit Console under **Tokens & Keys** for your container.

### API token

Create an API token with the `+` button, give it a name, choose a **sign-in callback** (see below), optionally restrict it to certain domains, and decide whether to allow user discoverability at sign-in. Every web-services request then carries it as a query item:

```text
?ckAPIToken=[API token]
```

CloudKit JS is configured the same way:

```javascript
CloudKit.configure({
  containers: [{
    containerIdentifier: '[insert your container ID here]',
    apiTokenAuth: { apiToken: '[insert your API token]' },
    environment: 'development'
  }]
});
```

On its own an API token grants only what the public database's `_world` role allows — typically reads. Its real job is to identify the container for the next method.

### Web auth token

A web auth token is what you need to act as a specific iCloud user, and the only way into the private and shared databases. Requests carry both tokens:

```text
?ckAPIToken=[API token]&ckWebAuthToken=[Web Auth Token]
```

The user gets one by signing in with their Apple ID:

![Apple's sign-in window for the MistDemo container](talk-icloud-sign-in)

How the token comes back depends on the sign-in callback chosen when the API token was created:

- **Post message** — Apple's sign-in window posts a `message` event to your page:

  ```javascript
  window.addEventListener('message', function(e) {
    console.log(e.data.ckWebAuthToken);
  })
  ```

- **URL redirect** — Apple redirects the browser to your callback URL with the token as a query parameter. Note the parameter is named `ckSession` on the redirect even though the request-side query item is `ckWebAuthToken`:

  ```text
  https://[callback-url]/?ckSession=[Web Auth Token]
  ```

Two facts about the token that Apple documents only in the archived reference:

- **Lifetime** — 30 minutes by default, two weeks if the user ticks *Keep me signed in*.
- **Rotation** — every response carries a fresh token in the `X-Apple-CloudKit-Web-Auth-Token` header, and the documented rule is that the previous token is invalid once the response arrives. MistKit's `AuthenticationMiddleware` reads that header after every request and hands it to ``TokenManager/didReceiveRotatedWebAuthToken(_:)``; ``WebAuthTokenManager`` and ``AdaptiveTokenManager`` adopt it. (In practice the live server has been observed to keep accepting old tokens, but the library follows the written rule.)

#### From inside an iOS app

You do not need a browser at all if the user is already signed in to your iOS app. `CKFetchWebAuthTokenOperation` exchanges the device's iCloud session for a web auth token that your server can use. MistDemo wraps it in an `async` function:

```swift
extension CKDatabase {
  internal func fetchWebAuthToken(apiToken: String) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
      let operation = CKFetchWebAuthTokenOperation(apiToken: apiToken)
      operation.qualityOfService = .userInitiated
      operation.fetchWebAuthTokenResultBlock = { @Sendable result in
        continuation.resume(with: result)
      }
      add(operation)
    }
  }
}
```

Run it against the **private** database; on the public database it fails or returns an unattributed token. Post the result to your backend over your own authenticated API and store it there.

### Server to server

For a job with no user — a cron job, a daemon, a CLI — use a server-to-server key. Under **Tokens & Keys → Server-to-Server Keys**, the console shows the exact commands:

![The "New Server-to-Server Key" page in the CloudKit Console](talk-server-to-server-key)

```bash
# Step 1: generate a P-256 private key
openssl ecparam -name prime256v1 -genkey -noout -out eckey.pem

# Step 2: output the public key (pipe to pbcopy to paste into the console)
openssl ec -in eckey.pem -pubout
```

Paste the public key into step 3, save, and copy the **Key ID**. The private key never leaves your server.

Each request is then signed. The payload is three strings joined by colons — the ISO 8601 date, the base64 SHA-256 of the body (or the empty string for no body), and the URL subpath — signed with ECDSA P-256 and sent in three headers:

| Header | Value |
| --- | --- |
| `X-Apple-CloudKit-Request-KeyID` | your key ID |
| `X-Apple-CloudKit-Request-ISO8601Date` | the same date that was signed |
| `X-Apple-CloudKit-Request-SignatureV1` | base64-encoded ECDSA signature |

There is no `Authorization` header. Every mistake in any of those pieces produces the same generic `401`, which is why the signing code in MistKit stores the exact date *string* it signed rather than re-formatting a `Date` on the way out.

### Which method for which database

| | Public | Private | Shared |
| --- | :-: | :-: | :-: |
| API token only | whatever `_world` grants | — | — |
| Web auth token | ✓ user-attributed | ✓ | ✓ |
| Server-to-server | ✓ developer-attributed | — | — |

The public database accepts two methods and they are **not interchangeable**: the same record written via web auth and via server-to-server ends up with two different creators, and the `/users/*` routes accept web auth only. MistKit therefore makes every public call say which it wants — ``Database/public(_:)`` carries a ``PublicAuthPreference`` — rather than defaulting silently. <doc:AuthenticationAndDatabases> covers the model; the deeper "why" is in <doc:WhatCloudKitGotWrong>.

### OpenAPI middleware

swift-openapi-generator does not know how to sign CloudKit requests, but it has middleware: `ServerMiddleware` runs before a request is received and `ClientMiddleware` runs before one is sent. Apple's own example shows a bearer-token middleware. MistKit's version is one small type whose only job is to ask a ``TokenManager`` for the current ``Authenticator`` and let it modify the request:

```swift
internal struct AuthenticationMiddleware: ClientMiddleware {
  internal let tokenManager: any TokenManager

  internal func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    guard let authenticator = try await tokenManager.currentAuthenticator() else {
      throw TokenManagerError.invalidCredentials(.noCredentialsAvailable)
    }

    var modifiedRequest = request
    var modifiedBody = body
    try await authenticator.authenticate(request: &modifiedRequest, body: &modifiedBody)
    let (response, responseBody) = try await next(modifiedRequest, modifiedBody, baseURL)
    if let rotated = response.headerFields[.cloudKitWebAuthToken] {
      do {
        try await tokenManager.didReceiveRotatedWebAuthToken(rotated)
      } catch {
        let message = "Failed to consume rotated web auth token: \(error.localizedDescription)"
        Logger(subsystem: .auth).warning("\(message)")
        RotatedWebAuthTokenFailureReporter.assertionHandler(message)
      }
    }
    return (response, responseBody)
  }
}
```

```
App ──▶ OpenAPI Client ──▶ AuthenticationMiddleware ──▶ TokenManager.currentAuthenticator()
                                    │
                                    ├── authenticator.authenticate(&request, &body)
                                    ▼
                           next(request, body, baseURL) ──▶ CloudKit
                                    │
                                    └── read X-Apple-CloudKit-Web-Auth-Token → tokenManager
```

Each scheme is one `authenticate(request:body:)` implementation. The API token appends a query item:

```swift
public func authenticate(
  request: inout HTTPRequest,
  body: inout HTTPBody?
) async throws {
  request.appendQueryItems([URLQueryItem(name: "ckAPIToken", value: token)])
}
```

The web auth token percent-encodes `+`, `/`, and `=` (CloudKit rejects the raw form) and appends both items:

```swift
public func authenticate(
  request: inout HTTPRequest,
  body: inout HTTPBody?
) async throws {
  let encoded = Self.encoder.encode(webAuthToken)
  request.appendQueryItems([
    URLQueryItem(name: "ckAPIToken", value: apiToken),
    URLQueryItem(name: "ckWebAuthToken", value: encoded),
  ])
}
```

Server-to-server buffers the body (so it can be both hashed and replayed), builds a signature, and appends the headers:

```swift
public func authenticate(
  request: inout HTTPRequest,
  body: inout HTTPBody?
) async throws {
  let bodyData = try await Data(buffering: &body, upTo: bodyBufferLimit)

  let signature = try RequestSignature(
    keyID: keyID,
    privateKey: privateKey,
    requestBody: bodyData,
    webServiceSubpath: request.path
  )

  request.headerFields.append(contentsOf: signature.headers)
}
```

`RequestSignature` does the actual signing:

```swift
internal init(
  keyID: String,
  privateKey: P256.Signing.PrivateKey,
  bodyHash: String,
  webServiceSubpath: String,
  iso8601DateString: String
) throws {
  let payload = "\(iso8601DateString):\(bodyHash):\(webServiceSubpath)"
  let signature = try privateKey.signature(for: Data(payload.utf8))

  self.init(
    keyID: keyID,
    iso8601DateString: iso8601DateString,
    signatureDerRepresentation: signature.derRepresentation
  )
}

internal var headers: HTTPFields {
  var fields = HTTPFields()
  fields[.cloudKitRequestKeyID] = keyID
  fields[.cloudKitRequestISO8601Date] = iso8601DateString
  fields[.cloudKitRequestSignatureV1] = signatureBase64
  return fields
}
```

where the body hash is `SHA256.cloudKitBodyHash(of:)` — `base64(SHA256(body))`, or `""` when there is no body. The full design, including why `body` is `inout`, is in <doc:RequestSigning>.

## Field type polymorphism

If you have handled JSON from a JavaScript-flavored API you know the problem: a field's value can be any of nine types, and the JSON does not always say which. MistKit models the domain side as one enum:

```swift
public enum FieldValue: Codable, Equatable, Sendable {
  case string(String)
  case int64(Int)
  case double(Double)
  case bytes(Data)  // Binary data; base64-encoded on the wire
  case date(Date)  // Date/time value
  case location(Location)
  case reference(Reference)
  case asset(Asset)
  case list([FieldValue])
}
```

``Location``, ``Reference``, and ``Asset`` are MistKit's own structs so the package does not depend on Core Location or CloudKit on the server. A reference is a record name plus an action; an asset is what CloudKit returns for a file, including the download URL:

```swift
public struct Reference: Codable, Equatable, Sendable {
  public enum Action: String, Codable, Sendable {
    case deleteSelf = "DELETE_SELF"
    case none = "NONE"
    case validate = "VALIDATE"
  }

  public let recordName: String
  public let action: Action?
}

public struct Asset: Codable, Equatable, Sendable {
  public let fileChecksum: String?
  public let size: Int64?
  public let referenceChecksum: String?
  public let wrappingKey: String?
  public let receipt: String?
  public let downloadURL: String?
}
```

In `openapi.yaml` the value is a `oneOf` over the nine wire shapes with an optional `type` tag:

```yaml
FieldValueRequest:
  properties:
    value:
      oneOf: [StringValue, Int64Value, DoubleValue, BytesValue,
              DateValue, LocationValue, ReferenceValue, AssetValue, ListValue]
    type:
      enum: [STRING, INT64, DOUBLE, BYTES, TIMESTAMP, REFERENCE, ASSET, ASSETID,
             LOCATION, STRING_LIST, INT64_LIST, ...]
```

The thirty-second version hides a lot: the `oneOf` has no discriminator, so a whole-millisecond timestamp decodes as an integer and a base64 blob decodes as a string, and three of the scalar types must be tagged explicitly on writes or CloudKit rejects them. <doc:FieldTypePolymorphism> has the whole story.

## Error handling

CloudKit documents its HTTP status codes and a JSON error body that is the same for all of them:

```json
{
  "uuid": "a1b2c3d4-...",
  "serverErrorCode": "AUTHENTICATION_FAILED",
  "reason": "The request requires authentication."
}
```

So the spec declares one `ErrorResponse` schema with an enum of codes and strings for everything else:

```yaml
ErrorResponse:
  properties:
    uuid: { type: string }
    serverErrorCode:
      type: string
      enum: [ACCESS_DENIED, ATOMIC_ERROR, AUTHENTICATION_FAILED, ...]
    reason: { type: string }
    redirectURL: { type: string }
```

and the generator produces a matching enum and struct. MistKit maps each of the fourteen documented codes onto its own ``CloudKitError`` case so callers pattern-match instead of comparing strings — see <doc:HandlingErrors>.

### The endpoint that returns HTTP 500

One documented call does not work at all: `GET users/discover` ("discover all user identities") returns `500 INTERNAL_ERROR` from both the REST API and Apple's own CloudKit JS, reproducibly, after authentication succeeds. It appears to have been retired server-side — possibly for privacy reasons — without the documentation changing. MistKit generates the operation from `openapi.yaml` but does not surface it in ``CloudKitService``; the `POST users/discover` form, which takes lookup infos, works and is what ``CloudKitService/discoverUserIdentities(lookupInfos:)`` calls. The details are tracked in [MistKit issue #28](https://github.com/brightdigit/MistKit/issues/28) and Apple Feedback FB22754466.

## Deployment

Bushel's sync job runs entirely in GitHub Actions. The key ID and private key (or a base64-encoded copy of it) live in repository secrets:

![Repository secrets: CLOUDKIT_KEY_ID, CLOUDKIT_PRIVATE_KEY, CLOUDKIT_API_TOKEN, CLOUDKIT_WEB_AUTH_TOKEN](talk-github-secrets)

The scheduled workflow (`Examples/BushelCloud/.github/workflows/cloudkit-sync-dev.yml`) fires three times a day at off-the-hour minutes and hands the secrets to a composite action:

```yaml
name: Scheduled CloudKit Sync (Development)

on:
  schedule:
    - cron: '17 2 * * *'   # 02:17 UTC
    - cron: '43 10 * * *'  # 10:43 UTC
    - cron: '29 18 * * *'  # 18:29 UTC
  workflow_dispatch:

concurrency:
  group: cloudkit-sync-dev
  cancel-in-progress: true

jobs:
  sync-dev:
    name: Sync to CloudKit (Development)
    runs-on: ubuntu-latest
    timeout-minutes: 30
    permissions:
      contents: read
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: CloudKit Sync
        uses: ./.github/actions/cloudkit-sync
        with:
          environment: development
          container-id: iCloud.com.brightdigit.Bushel
          cloudkit-key-id: ${{ secrets.CLOUDKIT_KEY_ID }}
          cloudkit-private-key: ${{ secrets.CLOUDKIT_PRIVATE_KEY }}
          virtualbuddy-api-key: ${{ secrets.VIRTUALBUDDY_API_KEY }}
          enable-export: 'false'
```

The action (`Examples/BushelCloud/.github/actions/cloudkit-sync/action.yml`) downloads a pre-built binary when one is cached, builds it in Docker otherwise, validates the PEM before touching CloudKit, and runs the CLI with the credentials in environment variables:

```yaml
name: 'CloudKit Sync Action'

inputs:
  environment:
    description: 'CloudKit environment (development or production)'
    required: true
  container-id:
    description: 'CloudKit container ID'
    required: true
  cloudkit-key-id:
    description: 'CloudKit S2S key ID'
    required: true
  cloudkit-private-key:
    description: 'CloudKit S2S private key (PEM content)'
    required: true

runs:
  using: "composite"
  steps:
    - name: Download pre-built binary (if available)
      id: download-binary
      uses: dawidd6/action-download-artifact@v3
      continue-on-error: true
      with:
        workflow: bushel-cloud-build.yml
        workflow_conclusion: success
        name: bushel-cloud-binary
        path: ./binary
        branch: ${{ github.ref_name }}

    - name: Build binary (fallback if artifact unavailable)
      if: steps.download-binary.outcome != 'success'
      shell: bash
      run: |
        docker run --rm -v "$PWD:/workspace" -w /workspace swiftlang/swift:nightly-6.4.x-noble \
          swift build -c release --static-swift-stdlib
        mkdir -p ./binary
        cp .build/release/bushel-cloud ./binary/

    - name: Make binary executable
      shell: bash
      run: chmod +x ./binary/bushel-cloud

    - name: Run CloudKit sync with change tracking
      shell: bash
      env:
        CLOUDKIT_KEY_ID: ${{ inputs.cloudkit-key-id }}
        CLOUDKIT_PRIVATE_KEY: ${{ inputs.cloudkit-private-key }}
        CLOUDKIT_ENVIRONMENT: ${{ inputs.environment }}
        CLOUDKIT_CONTAINER_ID: ${{ inputs.container-id }}
        BUSHEL_SYNC_JSON_OUTPUT_FILE: sync-result.json
      run: |
        ./binary/bushel-cloud sync \
          --verbose \
          --container-identifier "$CLOUDKIT_CONTAINER_ID"
```

The CLI writes a JSON report that the action turns into the workflow's summary page. Static builds, credential injection on other platforms, tiered scheduling, idempotency, and observability are covered in <doc:DeployingMistKit>.

## What's next

Every endpoint in the CloudKit Web Services reference is implemented — records, zones, changes, subscriptions, users, sharing, assets, and APNs tokens — and exercised live by MistDemo. What the project needs now is people using it: try it against your own container and file what you find on the [issue tracker](https://github.com/brightdigit/MistKit/issues).

And one more thing: Leo's apps, both backed by patterns from this talk — [Bushel](https://getbushel.app), virtualization for app developers, and [AtLeast](https://atleast.app), a passive timer for Apple Watch.

## Links

### Leo Dion / BrightDigit

- [MistKit on GitHub](https://github.com/brightdigit/MistKit)
- [MistKit issues](https://github.com/brightdigit/MistKit/issues) — "What's next?"
- [MistDemo](https://github.com/brightdigit/MistKit/tree/main/Examples/MistDemo) — CLI, macOS app and web demo used for integration testing
- [Bushel](https://getbushel.app) — Virtualization for App Developers
- [AtLeast](https://atleast.app) — Passive Timer for Apple Watch
- [Heartwitch](https://heartwitch.app) — Apple Watch heart-rate streaming; [App Store](https://apps.apple.com/us/app/heartwitch/id1480031203)
- [BrightDigit](https://brightdigit.com)
- [linktr.ee/leogdion](https://linktr.ee/leogdion)
- [iOSDevUK](https://www.iosdevuk.com)

### Use case examples

- [BushelCloud](https://github.com/brightdigit/BushelCloud) — server-to-server sync of macOS restore images, Xcode and Swift versions for Bushel; the GitHub Actions deployment shown in the talk (also at [`Examples/BushelCloud`](https://github.com/brightdigit/MistKit/tree/main/Examples/BushelCloud))
  - [`cloudkit-sync-dev.yml`](https://github.com/brightdigit/MistKit/blob/main/Examples/BushelCloud/.github/workflows/cloudkit-sync-dev.yml) — scheduled workflow
  - [`cloudkit-sync` composite action](https://github.com/brightdigit/MistKit/blob/main/Examples/BushelCloud/.github/actions/cloudkit-sync/action.yml)
- [CelestraCloud](https://github.com/brightdigit/CelestraCloud) — RSS feed sync into a public database for Celestra, with query filtering and sorting (also at [`Examples/CelestraCloud`](https://github.com/brightdigit/MistKit/tree/main/Examples/CelestraCloud))
- [HeartWitch](https://github.com/brightdigit/HeartWitch) — the private-database, Apple Watch to Vapor bridge
- [Rebuilding MistKit with Claude Code, part 1](https://brightdigit.com/tutorials/rebuilding-mistkit-claude-code-part-1/) and [part 2](https://brightdigit.com/tutorials/rebuilding-mistkit-claude-code-part-2/)

### What is CloudKit

- [WWDC 2014 "Introducing CloudKit" (session 208)](https://nonstrict.eu/wwdcindex/wwdc2014/208/) — Apple no longer hosts the video; this mirror has the video, slides and transcript. Transcript only: [ASCIIwwdc](https://asciiwwdc.com/2014/sessions/208)
- [CloudKit framework documentation](https://developer.apple.com/documentation/cloudkit)
- [Enabling CloudKit in your app](https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app) — Xcode capability setup
- [CloudKit Console](https://icloud.developer.apple.com/dashboard/)
- [Integrating a text-based schema into your workflow](https://developer.apple.com/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow)
- [cktool](https://developer.apple.com/icloud/ck-tool/) and [Automating CloudKit Development](https://developer.apple.com/icloud/cloudkit/automating/)

### CloudKit Web Services

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

### Authentication

- [CKFetchWebAuthTokenOperation](https://developer.apple.com/documentation/cloudkit/ckfetchwebauthtokenoperation)
- [Sign in with Apple](https://developer.apple.com/documentation/signinwithapple) — mentioned as not existing when Heartwitch was built
- [swift-crypto](https://github.com/apple/swift-crypto) — `P256.Signing.PrivateKey` used in `RequestSignature`
- MistKit source shown in the talk:
  - [`AuthenticationMiddleware.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Authentication/AuthenticationMiddleware.swift)
  - [`APITokenAuthenticator.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Authentication/APITokenAuthenticator.swift)
  - [`WebAuthTokenAuthenticator.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Authentication/WebAuthTokenAuthenticator.swift)
  - [`ServerToServerAuthenticator.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Authentication/ServerToServerAuthenticator.swift)
  - [`RequestSignature.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Authentication/RequestSignature.swift)

### Swift OpenAPI Generator

- [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)
- [WWDC23 "Meet Swift OpenAPI Generator"](https://developer.apple.com/videos/play/wwdc2023/10171/)
- [Documentation](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator) and [tutorial: Working with Swift OpenAPI Generator](https://swiftpackageindex.com/apple/swift-openapi-generator/tutorials/swift-openapi-generator)
- [ClientMiddleware](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clientmiddleware) — the ["Implement a custom client middleware"](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clientmiddleware#Implement-a-custom-client-middleware) bearer-token example is a section on that page
- [Example projects](https://github.com/apple/swift-openapi-generator/tree/main/Examples) — including auth, logging and retrying middleware examples
- Package ecosystem:
  - [swift-openapi-runtime](https://github.com/apple/swift-openapi-runtime)
  - [swift-openapi-urlsession](https://github.com/apple/swift-openapi-urlsession)
  - [swift-openapi-async-http-client](https://github.com/swift-server/swift-openapi-async-http-client)
  - [swift-okhttp](https://github.com/frameo-net/swift-okhttp)
  - [swift-openapi-vapor](https://github.com/vapor/swift-openapi-vapor)
  - [swift-openapi-hummingbird](https://github.com/hummingbird-project/swift-openapi-hummingbird)
  - [swift-openapi-lambda](https://github.com/awslabs/swift-openapi-lambda)
- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)
- [MistKit `openapi.yaml`](https://github.com/brightdigit/MistKit/blob/main/openapi.yaml)

### Field types and error handling

- [`FieldValue.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Models/FieldValues/FieldValue.swift)
- [MistKit issue #28: discoverAllUserIdentities returns HTTP 500](https://github.com/brightdigit/MistKit/issues/28)
  - Broken call, CloudKit Web Services: [Discovering All User Identities (GET users/discover)](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/DiscoveringAllUserIdentities.html)
  - Broken call, CloudKit JS: [`CloudKit.Container.discoverAllUserIdentities`](https://developer.apple.com/documentation/cloudkitjs/cloudkit.container/discoveralluseridentities)
- Apple Feedback FB22754466 — public copy on [Open Radar](https://openradar.appspot.com/FB22754466); filed via [Feedback Assistant](https://feedbackassistant.apple.com/)

### Deployment

- [GitHub Actions: scheduled workflows (`schedule` / cron)](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#schedule)
- [GitHub Actions: using secrets](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions)
- [GitHub Actions: creating a composite action](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action)
- [actions/checkout](https://github.com/actions/checkout)
- [dawidd6/action-download-artifact](https://github.com/dawidd6/action-download-artifact)
- [Swift Docker images](https://hub.docker.com/_/swift) — the sync action builds with `swiftlang/swift:nightly-6.4.x-noble`

### Other tools mentioned

- [Hummingbird](https://hummingbird.codes) — server behind the MistDemo web interface
- [Vapor](https://vapor.codes) — Heartwitch backend
- [OBS Studio](https://obsproject.com) — Heartwitch streaming overlay

## Questions

Questions asked during rehearsals and at the talks, with the answers as they stand today.

**How much does CloudKit cost?** There is no separate CloudKit fee beyond the Apple Developer Program. Quotas for storage, transfer, and requests scale with active users; exceeding them returns `QUOTA_EXCEEDED` or throttling. Apple does not publish a clear overage price list.

**What kind of database is it?** NoSQL, document-oriented, with a schema. Records have typed fields; relationships are references, not joins. The schema is defined up front (console or `cktool`), not created as you go.

**Do I need a signed-in user for the public database?** To write, yes. To read, no — the `_world` role decides.

**Why server-to-server instead of web auth for the public database?** Server-to-server is the only method that needs no human. It gives you a writable identity without anyone signing in, its key does not expire or rotate, and records it writes belong to your service rather than to whichever user happened to be signed in. A nightly job running on a web auth token would be dead by the second night. The mirror image is why private and shared reject server-to-server — there is no such thing as "your server's private database".

**How long does a web auth token last?** 30 minutes, or two weeks with *Keep me signed in*, and the documented rule is that it rotates on every response. See <doc:CloudKitAsYourBackend#Web-auth-token>.

**How do I get a web auth token from inside my iOS app?** `CKFetchWebAuthTokenOperation`, against the private database; see above.

**What happens to a user's private data if they delete the app or their iCloud account?** Delete the app: the data survives in iCloud. Sign out of iCloud: the data is intact but unreachable from that device. Delete the iCloud account: the data is gone and you never had a copy — which is why Heartwitch copies what it needs into Postgres.

**Can I use this from a browser extension?** Use CloudKit JS unless you specifically need Swift.

**Does this run on Linux? Windows? WASM?** Linux and Windows, yes — that is the point. Server-to-server signing needs swift-crypto, which is unavailable on Windows and WASI, so those targets use API-token + web-auth credentials. WASI also lacks a first-class HTTP transport; for browsers use CloudKit JS.

**How does this compare to Vapor plus the CloudKit framework?** The CloudKit framework only runs on Apple platforms. MistKit runs anywhere Swift runs.

**What is the production story for key storage?** GitHub Actions secrets for the two example jobs; a secrets manager or environment-variable injection in general. Never commit a `.pem`. <doc:DeployingMistKit> covers the options per platform.
