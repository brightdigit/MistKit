---
title: Rebuilding MistKit with Claude Code - From CloudKit Docs to Type-Safe Swift (Part 1)
date: 2025-12-01 00:00
description: Follow the journey of rebuilding MistKit using Claude Code and swift-openapi-generator. Learn how OpenAPI specifications transformed Apple's CloudKit documentation into a type-safe Swift client, and discover the challenges of mapping CloudKit's quirky REST API to modern Swift patterns.
featuredImage: /media/tutorials/rebuilding-mistkit-claude-code/mistkit-rebuild-part1-hero.webp
subscriptionCTA: Want to learn more about AI-assisted Swift development? Sign up for our newsletter to get notified when Part 2 drops.
---

In my previous article about [Building SyntaxKit with AI](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/), I explored how with the help of [Claude Code](https://claude.ai/claude-code) I could transform SwiftSyntax's 80+ lines of verbose API calls into 10 lines of elegant, declarative Swift.

I saw how Claude Code could easily replace and understand patterns. That's when I decided to explore the idea of updating [MistKit](https://github.com/brightdigit/MistKit), my library for server-side CloudKit application and see how Claude Code can help.

---

**In this series:**

* [Building SyntaxKit with AI](/tutorials/syntaxkit-swift-code-generation/)
* _Rebuilding MistKit with Claude Code (Part 1)_
* [Rebuilding MistKit with Claude Code (Part 2)](/tutorials/rebuilding-mistkit-claude-code-part-2/)

---

📚 **[View Documentation](https://swiftpackageindex.com/brightdigit/MistKit/documentation)** | 🐙 **[GitHub Repository](https://github.com/brightdigit/MistKit)**

- [The Decision to Rebuild](#the-decision-to-rebuild)
  - [The Game Changer: swift-openapi-generator](#the-game-changer-swift-openapi-generator)
  - [Learning from SyntaxKit's Pattern](#learning-from-syntaxkits-pattern)
- [Building with Claude Code](#building-with-claude-code)
  - [Why OpenAPI + swift-openapi-generator?](#why-openapi--swift-openapi-generator)
  - [Challenge #1: Type System Polymorphism](#challenge-1-type-system-polymorphism)
  - [Challenge #2: Authentication Complexity](#challenge-2-authentication-complexity)
  - [Challenge #3: Error Handling](#challenge-3-error-handling)
  - [Challenge #4: API Ergonomics](#challenge-4-api-ergonomics)
  - [The Iterative Workflow with Claude](#the-iterative-workflow-with-claude)
- [What's Next](#whats-next)

<a id="the-decision-to-rebuild"></a>
## The Decision to Rebuild

I had a couple of use cases where MistKit running in the cloud would allow me to store data in a public database. However I hadn't touched the library in a while.

By now, [Swift had transformed](https://brightdigit.com/tutorials/swift-6-async-await-actors-fixes/) while MistKit stood still:
- **Swift 6** with strict concurrency checking
- **async/await** as standard (not experimental)
- **Server-side Swift maturity** (Vapor 4, swift-nio, AWS Lambda)
- **Modern patterns** expected (Result types, AsyncSequence, property wrappers)

MistKit, frozen in 2021, couldn't take advantage of any of this.

> youtube https://youtu.be/_-k97s1ZPzE

<a id="the-game-changer-swift-openapi-generator"></a>
### The Game Changer: [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)

At [WWDC 2023](https://developer.apple.com/videos/play/wwdc2023/10171/), Apple announced [`swift-openapi-generator`](https://github.com/apple/swift-openapi-generator)—a tool that reads OpenAPI specifications and automatically generates type-safe Swift client code. This single tool made the MistKit rebuild feasible. What was missing was an OpenAPI spec. If I had that I could easily create a library which made the necessary calls to CloudKit as needed, as well as compatibility with [server-side (AsyncHTTPClient)](https://github.com/swift-server/swift-openapi-async-http-client) or [client-side (URLSession)](https://github.com/apple/swift-openapi-urlsession) APIs .

That's where [Claude Code](https://claude.ai/claude-code) came in.

<a id="learning-from-syntaxkits-pattern"></a>
### Learning from SyntaxKit's Pattern

With my work on SyntaxKit, I could see that if I fed sufficient documentation on an API to an LLM, it can understand how to develop against it. There may be issues along the way. However, any failures come with the ability to learn and adapt either with internal documentation or writing sufficient tests.

Just as I was able to simplify SwiftSyntax into a simpler API with [SyntaxKit](https://github.com/brightdigit/SyntaxKit), I can have an LLM create an OpenAPI spec for CloudKit.

---

The pattern was clear: **give Claude the right context, and it could translate Apple's documentation into a usable OpenAPI spec**. SyntaxKit taught me that code generation works best when you have a clear source of truth—for SyntaxKit it was SwiftSyntax ASTs, for MistKit it would be CloudKit's REST API documentation. The abstraction layer would come later.

The rebuild was ready to begin.

![CloudKit Web Services Documentation Site](/media/tutorials/rebuilding-mistkit-claude-code/cloudkit-documentation.webp)

<a id="building-with-claude-code"></a>
## Building with [Claude Code](https://claude.ai/claude-code)

I needed a way for Claude Code to understand how the CloudKit REST API worked. There was one main document I used—the [CloudKit Web Services Documentation Site](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/). The [CloudKit Web Services Documentation](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/) Site, **which hasn't been updated since June of 2016**, contains the most thorough documentation on how the REST API works and hopefully can provide enough for Claude to start crafting the OpenAPI spec.

By running the site (as well as the swift-openapi-generator documentation) through llm.codes, saving the exported markdown documentation in the `.claude/docs` directory and letting Claude Code know about it (i.e. add a reference to it in Claude.md), I could now start having Claude Code translate the documentation into a usable API.

### Setting Up Claude Code for MistKit

Before diving in, here's what you need to understand about working with Claude Code:

**Documentation Export with llm.codes**
I used [llm.codes](https://llm.codes) (mentioned in my [SyntaxKit article](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/)) to convert Apple's web documentation into markdown format that Claude can easily understand. This tool crawls documentation sites and exports them as clean markdown files. It also works with DocC documentation from Swift packages, making it easy to give Claude context about any Swift library's API.

**Claude Code's Context System**
Claude Code uses a simple but powerful context system:
- `.claude/docs/` - Store reference documentation (like CloudKit API docs, swift-openapi-generator guides)
- `.claude/CLAUDE.md` or `CLAUDE.md` - Reference these docs so Claude knows to use them as context

This gives Claude the context it needs to understand CloudKit's API without you having to paste documentation repeatedly in every conversation.

```
.claude/docs
├── cktool-full.md              # Complete CloudKit CLI tool documentation
├── cktool.md                   # Condensed CloudKit CLI reference
├── cktooljs-full.md            # Full CloudKitJS documentation
├── cktooljs.md                 # CloudKitJS quick reference
├── cloudkit-public-database-architecture.md
├── cloudkit-schema-plan.md
├── cloudkit-schema-reference.md
├── cloudkitjs.md               # JavaScript SDK documentation
├── data-sources-api-research.md
├── firmware-wiki.md
├── https_-swiftpackageindex.com-apple-swift-log-main-documentation-logging.md
├── https_-swiftpackageindex.com-apple-swift-openapi-generator-1.10.3-documentation-swift-openapi-generator.md
├── https_-swiftpackageindex.com-brightdigit-SyndiKit-0.6.1-documentation-syndikit.md
├── mobileasset-wiki.md
├── protocol-extraction-continuation.md
├── QUICK_REFERENCE.md
├── README.md
├── schema-design-workflow.md
├── sosumi-cloudkit-schema-source.md
├── SUMMARY.md
├── testing-enablinganddisabling.md
└── webservices.md              # Primary CloudKit Web Services REST API documentation
```

Note: Files with "-full" suffix contain complete documentation exported from llm.codes, while shorter versions are condensed for quicker reference. The swift-openapi-generator docs were essential for understanding type overrides and middleware configuration.

<a id="why-openapi--swift-openapi-generator"></a>
### Why OpenAPI + [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)?

With [`swift-openapi-generator`](https://github.com/apple/swift-openapi-generator) available (announced WWDC 2023), the path forward became clear:

1. **Create OpenAPI specification from CloudKit documentation**
   - Translate Apple's prose docs → Machine-readable YAML
   - Every endpoint, parameter, response type formally defined

2. **Let swift-openapi-generator generate the client**
   - Run `swift build` → 10,476 lines of type-safe networking code appear
   - Request/response types (Codable structs)
   - API client methods (async/await)
   - Type-safe enums, JSON handling, URL building
   - Configuration: `openapi-generator-config.yaml` + Swift Package Manager build plugin

3. **Build clean abstraction layer on top**
   - Wrap generated code in friendly, idiomatic Swift API
   - Add TokenManager for authentication
   - CustomFieldValue for CloudKit's polymorphic types

By following [spec-driven development](https://brightdigit.com/tutorials/swift-openapi-generator/), we had many benefits:

- Type safety (if it compiles, it's valid CloudKit usage)
- Completeness (every endpoint defined)
- Maintainability (spec changes = regenerate code) 
- No manual JSON parsing or networking boilerplate
- Cross-platform (macOS, iOS, Linux, server-side Swift)

<a id="challenge-1-type-system-polymorphism"></a>
### Challenge #1: Type System Polymorphism
[CloudKit fields](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Types.html#//apple_ref/doc/uid/TP40015240-CH3-SW2) are dynamically typed—one field can be STRING, INT64, DOUBLE, TIMESTAMP, BYTES, REFERENCE, ASSET, LOCATION, or LIST. But [OpenAPI is statically typed](https://spec.openapis.org/oas/latest.html). How do we model this polymorphism?

```no-highlight
Me: "Here's CloudKit's field value structure from Apple's docs.
     A field can have value of type STRING, INT64, DOUBLE, TIMESTAMP,
     BYTES, REFERENCE, ASSET, LOCATION, LIST..."

Claude: "This is a discriminated union. Try modeling with oneOf in OpenAPI:
         The value property can be oneOf the different types,
         and the type field acts as a discriminator."

Me: "Good start, but there's a CloudKit quirk: ASSETID is different
     from ASSET. ASSET has full metadata, ASSETID is just a reference."

Claude: "Interesting! You'll need a type override in the generator config:
         typeOverrides:
           schemas:
             FieldValue: CustomFieldValue
         Then implement CustomFieldValue to handle ASSETID specially."

Me: "Perfect. Can you generate test cases for all field types?"

Claude: "Here are test cases for STRING, INT64, DOUBLE, TIMESTAMP,
         BYTES, REFERENCE, ASSET, ASSETID, LOCATION, and LIST..."
```

Having developed MistKit previously, I understood the challenge of various field types and the difficulty in expressing that in Swift. This is a common challenge in Swift with JSON data.

Claude's suggestion of [`typeOverrides`](https://swiftpackageindex.com/apple/swift-openapi-generator/1.10.3/documentation/swift-openapi-generator/configuring-the-generator#Type-overrides) was the breakthrough—instead of fighting OpenAPI's type system, we'd let the generator create basic types, then override with our custom implementation that handles CloudKit's quirks.

#### Understanding ASSET vs ASSETID

CloudKit uses two different type discriminators for [asset fields](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Types.html#//apple_ref/doc/uid/TP40015240-CH3-SW2):

**[ASSET](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Types.html#//apple_ref/doc/uid/TP40015240-CH3-SW2)** - Full asset metadata returned by CloudKit
- Appears in: Query responses, lookup responses, modification responses
- Contains: `fileChecksum`, `size`, `downloadURL`, `wrappingKey`, `receipt`
- Use case: When you need to download or verify the asset file

**[ASSETID](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Types.html#//apple_ref/doc/uid/TP40015240-CH3-SW2)** - Asset reference placeholder
- Appears in: Record creation/update requests
- Contains: Same structure as ASSET, but typically only `downloadURL` populated
- Use case: When you're referencing an already-uploaded asset

At the end of the day, both decode to the same `AssetValue` structure, but CloudKit distinguishes them with different type strings (`"ASSET"` vs `"ASSETID"`). Our custom implementation handles this elegantly:

```swift
internal struct CustomFieldValue: Codable, Hashable, Sendable {
    internal enum FieldTypePayload: String, Codable, Sendable {
        case asset = "ASSET"
        case assetid = "ASSETID"  // Both decode to AssetValue
        case string = "STRING"
        case int64 = "INT64"
        // ... more types
    }

    internal let value: CustomFieldValuePayload
    internal let type: FieldTypePayload?
}
```

Using the `CustomFieldValue` with the power of openapi-generator `typeOverides` allows us to implement the specific quirks of CloudKit field values.

<a id="challenge-2-authentication-complexity"></a>
### Challenge #2: Authentication Complexity

The next challenge was dealing with the 3 different methods of authentication:

1. **API Token** - Container-level access
   - Query parameter: `ckAPIToken`
   - Simplest method
   - A starting point for **Web Auth Token** 

2. **[Web Auth Token](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html#//apple_ref/doc/uid/TP40015240-CH24-SW2)** - User-specific access
   - Two query parameters: `ckAPIToken` + `ckWebAuthToken`
   - For private database access

3. **[Server-to-Server](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html#//apple_ref/doc/uid/TP40015240-CH24-SW6)** - Public Database Access
   - ECDSA P-256 signature in Authorization header
   - Most complex, most secure


This became a complexity problem when trying to model it in OpenAPI. What Claude suggested was to use the [ClientMiddleware API](https://swiftpackageindex.com/apple/swift-openapi-runtime/1.8.3/documentation/openapiruntime/clientmiddleware) to handle authentication dynamically rather than relying on generator's built-in auth. The meant we used:

1. **OpenAPI**: Define all three `securitySchemes` but make endpoint security optional (`security: []`)
2. **Middleware**: Implement `AuthenticationMiddleware` that inspects `TokenManager` at runtime
3. **TokenManager Protocol**: Three implementations (API, WebAuth, ServerToServer)
4. **Runtime Selection**: Client chooses auth method via TokenManager injection

Here's what it looks like:

```swift
internal struct AuthenticationMiddleware: ClientMiddleware {
    internal let tokenManager: any TokenManager

    func intercept(...) async throws -> (HTTPResponse, HTTPBody?) {
        guard let credentials = try await tokenManager.getCurrentCredentials() else {
            throw TokenManagerError.invalidCredentials(.noCredentialsAvailable)
        }

        var modifiedRequest = request

        switch credentials.method {
        case .apiToken(let token):
            // Add ckAPIToken to query parameters
        case .webAuthToken(let apiToken, let webToken):
            // Add both tokens to query parameters
        case .serverToServer(let keyID, let privateKey):
            // Sign request with ECDSA
            // Add Authorization header with signature
        }

        return try await next(modifiedRequest, body, baseURL)
    }
}
```

This helps because:

- ✅ Generator doesn't need to handle auth complexity
- ✅ We control authentication at runtime
- ✅ Easy to test (inject mock TokenManager)
- ✅ Supports all three methods seamlessly
- ✅ Can switch auth methods without code changes

While this looks like it will work I wanted to make absolute sure. When using an LLM **it's important to have code which actually proves that it works and not just unit test.** So I created a simple command line tool which would to both write and read from a public and private database:

```no-highlight
Me: "Can you run MistDemo to test the actual functionality?"

Claude: *[Runs demo successfully]*
"Perfect! The MistDemo ran successfully:
 - Web Authentication - Used API token + web auth token
 - CloudKit API Calls - Made multiple successful requests
 - HTTP Integration - AuthenticationMiddleware properly added all required parameters
 - Data Retrieval - Successfully retrieved TodoItem records from CloudKit

 The authentication layer is working as designed. All three authentication methods have a solid foundation!"
```

We'll touch more on this approach in [the next blog post.](/tutorials/rebuilding-mistkit-claude-code-part-2/)

<a id="challenge-3-error-handling"></a>
### Challenge #3: Error Handling

[CloudKit returns over 9 different HTTP status codes](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/ErrorCodes.html), each with nested error details including `serverErrorCode`, `reason`, `uuid`, and sometimes `redirectURL` or `retryAfter`. What would be nice is if we can parse these in a Swift-y way, taking advantage of Swift 6 features like typed throws for more precise error handling.

According to Apple's Documentation: 

> **Record Fetch Error Dictionary**
>
> The error dictionary describing a failed operation with the following keys:

 - `recordName`: The name of the record that the operation failed on.
 - `reason`: A string indicating the reason for the error.
 - `serverErrorCode`: A string containing the code for the error that occurred. For possible values, see Error Codes.
 - `retryAfter`: The suggested time to wait before trying this operation again.
 - `uuid`: A unique identifier for this error.
 - `redirectURL`: A redirect URL for the user to securely sign in.

Based on this, I had Claude create an openapi entry on this:

```yaml
components:
  schemas:
    ErrorResponse:
      type: object
      description: Error response object
      properties:
        uuid:
          type: string
          description: Unique error identifier for support
        serverErrorCode:
          type: string
          enum:
            - ACCESS_DENIED
            - ATOMIC_ERROR
            - AUTHENTICATION_FAILED
            - AUTHENTICATION_REQUIRED
            - BAD_REQUEST
            - CONFLICT
            - EXISTS
            - INTERNAL_ERROR
            - NOT_FOUND
            - QUOTA_EXCEEDED
            - THROTTLED
            - TRY_AGAIN_LATER
            - VALIDATING_REFERENCE_ERROR
            - ZONE_NOT_FOUND
        reason:
          type: string
        redirectURL:
          type: string

  responses:
    BadRequest:
      description: Bad request (400) - BAD_REQUEST, ATOMIC_ERROR
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    Unauthorized:
      description: Unauthorized (401) - AUTHENTICATION_FAILED
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    # ... additional error responses for 403, 404, 409, 412, 413, 421, 429, 500, 503
```

Claude was able to translate the documentation into:

1. **Error Code Enum**: Converted prose list of error codes to explicit enum
2. **HTTP Status Mapping**: Created reusable response components for each HTTP status
3. **Consistent Schema**: All errors use same `ErrorResponse` schema
4. **Status Documentation**: Linked HTTP statuses to CloudKit error codes in descriptions

This enables:
- **Type-Safe Error Handling**: Generated code includes all possible error codes
- **Automatic Deserialization**: Errors automatically parsed to correct type
- **Centralized Definitions**: Define once, reference everywhere

Here's how it's mapped:

| HTTP Status | CloudKit Error Codes | Client Action |
|-------------|---------------------|---------------|
| **400 Bad Request** | `BAD_REQUEST`, `ATOMIC_ERROR` | Fix request parameters or retry non-atomically |
| **401 Unauthorized** | `AUTHENTICATION_FAILED` | Re-authenticate or check credentials |
| **403 Forbidden** | `ACCESS_DENIED` | User lacks permissions |
| **404 Not Found** | `NOT_FOUND`, `ZONE_NOT_FOUND` | Verify resource exists |
| **409 Conflict** | `CONFLICT`, `EXISTS` | Fetch latest version and retry, or use force operations |
| **412 Precondition Failed** | `VALIDATING_REFERENCE_ERROR` | Referenced record doesn't exist |
| **413 Request Too Large** | `QUOTA_EXCEEDED` | Reduce request size or upgrade quota |
| **429 Too Many Requests** | `THROTTLED` | Implement exponential backoff |
| **500 Internal Error** | `INTERNAL_ERROR` | Retry with backoff |
| **503 Service Unavailable** | `TRY_AGAIN_LATER` | Temporary issue, retry later |

This structured [error handling](https://brightdigit.com/articles/swift-error-handling/) enables the generated client to provide specific, actionable error messages rather than generic HTTP failures. Developers get type-safe error codes, HTTP status mapping, and clear guidance on how to handle each error condition.

<a id="challenge-4-api-ergonomics"></a>
### Challenge #4: API Ergonomics

The generated OpenAPI client works, but it's not exactly ergonomic. Here's what a simple query looks like with the raw generated code:

```swift
// Verbose generated API
let input = Operations.queryRecords.Input(
    path: .init(
        version: "1",
        container: "iCloud.com.example.MyApp",
        environment: Components.Parameters.environment.production,
        database: Components.Parameters.database._private
    ),
    headers: .init(accept: [.json]),
    body: .json(.init(
        query: .init(recordType: "User")
    ))
)

let response = try await client.queryRecords(input)

switch response {
case .ok(let okResponse):
    let queryResponse = try okResponse.body.json
    // Process records...
default:
    // Handle errors...
}
```

The problem is there's too much boilerplate for simple operations when we can clean this up with a nicer abstraction. The solution was to build a three-layer architecture that keeps the generated code internal and exposes a clean public API:

<img class="full-size" src="/media/tutorials/rebuilding-mistkit-claude-code/mistkit-development-layers.svg" alt="Three-layer architecture showing User Code (public API), MistKit Abstraction (internal), and Generated OpenAPI Client (internal)" />

So now it can look something like this:

```swift
// Clean, idiomatic Swift
let service = try CloudKitService(
    container: "iCloud.com.example.MyApp",
    environment: .production,
    database: .private,
    tokenManager: tokenManager
)

let records = try await service.queryRecords(
    recordType: "User",
    filter: .equals("status", .string("active"))
)

// Type-safe field access
for record in records {
    if let name = record.fields["name"]?.stringValue {
        print("User: \(name)")
    }
}
```

In this case, we create a few abstraction to help:

- `FieldValue` enum for type-safe field access
- `RecordInfo` struct for read operations
- `QueryFilter` for building queries
- `CloudKitService` wrapper hiding OpenAPI complexity

This means the generated code stays internal while users interact with the more friendly API.

<a id="the-iterative-workflow-with-claude"></a>
### The Iterative Workflow with Claude

This process of building and refining was iterative when working with Claude Code:

1. **I draft the structure**
   - Provide CloudKit domain knowledge and desired API

2. **Claude expands**
   - Fills in request/response schemas
   - Generates boilerplate for similar endpoints
   - Creates consistent patterns

3. **I review for CloudKit accuracy**
   - Check against Apple docs
   - Add edge cases and CloudKit quirks
   - Refine error responses
   - Define integration and unit tests for verification

4. **Claude validates consistency**
   - Catches schema mismatches
   - Suggests improvements

5. **Iterate until complete**

Let's take for instance, this conversation I had with Claude:

```no-highlight
Me: "Here's the query endpoint from Apple's docs"

Claude: *[Creates complete OpenAPI definition]*
"Here's a complete OpenAPI definition with request/response schemas"

Me: "Add `resultsLimit` validation and `continuationMarker` for pagination"

Claude: *[Updates definition with pagination support]*
"Updated, and I noticed the `zoneID` should be optional"
```

> youtube https://youtu.be/gH3QnVHsUAc

By providing my own experience with great Swift APIs and Claude's ability at applying patterns, I quickly build a library that's friendly to use.

#### Building MistKit from Scratch with Claude Code

With Claude Code, I could easily create an openapi document based on the Apple's documentation. With my guidance and understanding with the REST API and good Swift design, I could guide Claude through issues like:

* Field Value with the oneOf pattern and handling the ASSETID quirk)
* completed authentication modeling with three security schemes

This will make it much easier to continue future features with MistKit and enabling me to create some server-side application for my apps.

<a id="whats-next"></a>
## What's Next

After three months of collaboration with Claude (**representing significant acceleration over manual development**), I had:
- ✅ 10,476 lines of generated, type-safe Swift code
- ✅ Three authentication methods working seamlessly
- ✅ CustomFieldValue handling CloudKit's polymorphic types
- ✅ Clean public API hiding OpenAPI complexity
- ✅ 161 tests across 47 test files

The OpenAPI spec was complete. The generated client compiled. The abstraction layer was elegant. Unit tests passed.

**How Claude Code Accelerated Development:**
- **Documentation Translation**: Converting Apple's prose documentation to a precise OpenAPI spec would have taken weeks manually. Claude handled the bulk of this in days, with me providing CloudKit domain expertise and corrections.
- **Boilerplate Generation**: The 10,476 lines of generated Swift code from swift-openapi-generator saved months of hand-writing networking code, request/response types, and JSON handling.
- **Pattern Application**: Once I established patterns (like `CustomFieldValue` for polymorphic types), Claude consistently applied them across the codebase.
- **Iteration Speed**: When authentication approaches needed refactoring, Claude could update dozens of files in minutes vs. hours of manual editing.

What would have likely taken 6-12 months of solo development was compressed into 3 months of _side-project_ collaboration, with Claude handling repetitive tasks while I focused on architecture, CloudKit-specific quirks, and real-world testing.

However I really needed to put it the test in my actual uses. In the next post, I'll talk about find flaws in MistKit by actually consuming my library with help from Claude Code. I'll be building a couple of command line tools for easily uploading data for [Bushel](https://getbushel.app) and a future RSS Reader to the public database. By doing this I'll understand [Claude's limitation, benefits and how to workaround those.](/tutorials/rebuilding-mistkit-claude-code-part-2/)
