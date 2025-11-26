---
title: "Rebuilding MistKit with Claude Code: From CloudKit Docs to Type-Safe Swift (Part 1)"
date: 2025-11-26 00:00
description: Follow the journey of rebuilding MistKit v1.0 using Claude Code and swift-openapi-generator. Learn how OpenAPI specifications transformed Apple's CloudKit documentation into a type-safe Swift client, and discover the challenges of mapping CloudKit's quirky REST API to modern Swift patterns.
tags: swift, cloudkit, openapi, code-generation, ai-assisted-development, swift-6, claude-code, server-side-swift, async-await
featuredImage: /media/tutorials/rebuilding-mistkit-claude-code/mistkit-rebuild-part1-hero.webp
subscriptionCTA: Want to learn more about AI-assisted Swift development and modern API design patterns? Sign up for our newsletter to get notified when Part 2 drops, covering real-world MistKit applications and lessons learned from AI collaboration.
---

In my previous article about [Building SyntaxKit with AI](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/), I explored how code generation could transform SwiftSyntax's 80+ lines of verbose API calls into 10 lines of elegant, declarative Swift.

That's when I decided to export the idea of updating MistKit for several use cases and how Claude Code can help.

📚 **[View Documentation](https://swiftpackageindex.com/brightdigit/MistKit/documentation)** | 🐙 **[GitHub Repository](https://github.com/brightdigit/MistKit)**

- [The Decision to Rebuild](#the-decision-to-rebuild)
  - [The State of MistKit v0.2](#the-state-of-mistkit-v02)
  - [The Need for Change](#the-need-for-change)
  - [The Game Changer: swift-openapi-generator](#the-game-changer-swift-openapi-generator)
  - [Learning from SyntaxKit's Pattern](#learning-from-syntaxkits-pattern)
- [Building with Claude Code](#building-with-claude-code)
  - [Why OpenAPI + swift-openapi-generator?](#why-openapi--swift-openapi-generator)
  - [Challenge #1: Type System Polymorphism](#challenge-1-type-system-polymorphism)
  - [Challenge #2: Authentication Complexity](#challenge-2-authentication-complexity)
  - [Challenge #3: API Ergonomics](#challenge-3-api-ergonomics)
  - [Challenge #4: Error Handling](#challenge-4-error-handling)
  - [The Iterative Workflow with Claude](#the-iterative-workflow-with-claude)
- [What's Next](#whats-next)

<a id="the-decision-to-rebuild"></a>
## The Decision to Rebuild

<a id="the-need-for-change"></a>
### The Need for Change

<!-- ORIGINAL [CONTENT] BLOCK - PRESERVED AS-IS -->
Swift had transformed while MistKit stood still:
- **Swift 6** with strict concurrency checking
- **async/await** as standard (not experimental)
- **Server-side Swift maturity** (Vapor 4, swift-nio, AWS Lambda)
- **Modern patterns** expected (Result types, AsyncSequence, property wrappers)

MistKit v0.2, frozen in 2021, couldn't take advantage of any of this.
<!-- END ORIGINAL [CONTENT] -->

<a id="the-game-changer-swift-openapi-generator"></a>
### The Game Changer: swift-openapi-generator

<!-- ORIGINAL [CONTENT] BLOCK - PRESERVED AS-IS -->
At WWDC 2023, Apple announced `swift-openapi-generator`—a tool that reads OpenAPI specifications and automatically generates type-safe Swift client code. This single tool made the MistKit rebuild feasible. If I had an OpenAPI spec, I could easily create a library which made the necessary calls to CloudKit as needed, as well as compatibility with server-side (AsyncHTTP) or client-side APIs (URLSession).

What I needed was a way to easily create that spec, since Apple only provides documentation for the CloudKit REST API.
<!-- END ORIGINAL [CONTENT] -->

<a id="learning-from-syntaxkits-pattern"></a>
### Learning from SyntaxKit's Pattern

<!-- ORIGINAL [CONTENT] BLOCK - PRESERVED AS-IS -->
With my work on SyntaxKit, I could see that if I fed sufficient documentation on an API to an LLM, it can understand how to develop against it. Even so, any failures come with the ability to learn and adapt either with internal documentation or writing sufficient tests.

Just as I was able to simplify SwiftSyntax into a simpler API, I can have an LLM create an OpenAPI spec for CloudKit and build an API on top of the generated code.
<!-- END ORIGINAL [CONTENT] -->

<!-- CLAUDE-WRITTEN PROSE - REVIEW AND EDIT AS NEEDED -->
<!-- Theme: Connecting SyntaxKit lessons to MistKit approach, pattern recognition -->
<!-- Target: ~100-150 words -->

The pattern was clear: **give Claude the right context, and it could translate Apple's prose documentation into machine-readable OpenAPI**. SyntaxKit taught me that code generation works best when you have a clear source of truth—for SyntaxKit it was SwiftSyntax ASTs, for MistKit it would be CloudKit's REST API documentation. The abstraction layer would come later.

The rebuild was ready to begin.
<!-- END CLAUDE-WRITTEN -->

<!-- WRITING GUIDANCE FOR THIS SECTION -->
<!-- Key phrases: "pattern was clear", "source of truth", "abstraction layer would come later" -->
<!-- Voice notes: Makes explicit connection between SyntaxKit and MistKit approaches -->
<!-- Connect to: Reinforces "generate for precision, abstract for ergonomics" from opening -->
<!-- Transition: Sets up "Building with Claude Code" section about actual implementation -->
<!-- END GUIDANCE -->

<a id="building-with-claude-code"></a>
## Building with Claude Code

<!-- ORIGINAL [CONTENT] BLOCK - PRESERVED AS-IS -->
I needed a way for Claude Code to understand how the CloudKit REST API worked. There was one main document I used—the [CloudKit Web Services Documentation Site](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/). The CloudKit Web Services Documentation Site, which hasn't been updated since June of 2016, contains the most thorough documentation on how the REST API works and hopefully can provide enough for Claude to start crafting the OpenAPI spec.

By running the site (as well as the swift-openapi-generator documentation) through llm.codes, and saving the exported markdown documentation in the `.claude` directory and letting Claude Code know about it (i.e. add a reference to it in Claude.md), I could now start having Claude Code translate the documentation into a usable API.
<!-- END ORIGINAL [CONTENT] -->

<a id="why-openapi--swift-openapi-generator"></a>
### Why OpenAPI + swift-openapi-generator?

With swift-openapi-generator available (announced WWDC 2023), the path forward became clear:

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

This had many benefits:

- Type safety (if it compiles, it's valid CloudKit usage)
- Completeness (every endpoint defined)
- Maintainability (spec changes = regenerate code)
- No manual JSON parsing or networking boilerplate
- Cross-platform (macOS, iOS, Linux, server-side Swift)

<a id="challenge-1-type-system-polymorphism"></a>
### Challenge #1: Type System Polymorphism

**The Core Problem:**

CloudKit fields are dynamically typed—one field can be STRING, INT64, DOUBLE, TIMESTAMP, BYTES, REFERENCE, ASSET, LOCATION, or LIST. But OpenAPI is statically typed. How do we model this polymorphism?

**The Claude Code Conversation:**

```
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

<!-- ORIGINAL [CONTENT] BLOCK - PRESERVED AS-IS -->
Having developed MistKit previously, I understood the challenge of various field types and the difficulty in expressing that in Swift.
<!-- END ORIGINAL [CONTENT] -->

<!-- CLAUDE-WRITTEN PROSE - REVIEW AND EDIT AS NEEDED -->
<!-- Theme: Reflection on Claude collaboration for polymorphism -->
<!-- Target: ~40 words -->
Claude's suggestion of `typeOverrides` was the breakthrough—instead of fighting OpenAPI's type system, we'd let the generator create basic types, then override with our custom implementation that handles CloudKit's quirks.
<!-- END CLAUDE-WRITTEN -->

<!-- WRITING GUIDANCE FOR THIS SECTION -->
<!-- Key phrases: "breakthrough", "instead of fighting", "handles CloudKit's quirks" -->
<!-- Voice notes: Shows how Claude provided the pattern, not just code -->
<!-- Connect to: Shows first successful Claude collaboration, sets pattern for other challenges -->
<!-- END GUIDANCE -->

**Understanding ASSET vs ASSETID:**

CloudKit uses two different type discriminators for asset fields:

**ASSET** - Full asset metadata returned by CloudKit
- Appears in: Query responses, lookup responses, modification responses
- Contains: `fileChecksum`, `size`, `downloadURL`, `wrappingKey`, `receipt`
- Use case: When you need to download or verify the asset file

**ASSETID** - Asset reference placeholder
- Appears in: Record creation/update requests
- Contains: Same structure as ASSET, but typically only `downloadURL` populated
- Use case: When you're referencing an already-uploaded asset

**The Quirk**: Both decode to the same `AssetValue` structure, but CloudKit distinguishes them with different type strings (`"ASSET"` vs `"ASSETID"`). Our custom implementation handles this elegantly:

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

**The Result:** Type-safe field values with CloudKit-specific quirks baked into the implementation. If it compiles, the field values are valid.

<a id="challenge-2-authentication-complexity"></a>
### Challenge #2: Authentication Complexity

<!-- CLAUDE-WRITTEN PROSE - REVIEW AND EDIT AS NEEDED -->
<!-- Theme: Authentication challenge introduction -->
<!-- Target: ~40 words -->
<!-- ORIGINAL [CONTENT] BLOCK - PRESERVED AS-IS -->
The most difficult challenge was dealing with the 3 different methods of authentication:
<!-- END ORIGINAL [CONTENT] -->

This became a complexity problem when trying to model it in OpenAPI.
<!-- END CLAUDE-WRITTEN -->

<!-- WRITING GUIDANCE FOR THIS SECTION -->
<!-- Key phrases: "flexibility became a complexity problem" -->
<!-- Voice notes: Sets up the technical challenge -->
<!-- Connect to: Introduction to authentication methods -->
<!-- END GUIDANCE -->

**The Three CloudKit Authentication Methods:**

1. **API Token** - Container-level access
   - Query parameter: `ckAPIToken`
   - Simplest method

2. **Web Auth Token** - User-specific access
   - Two query parameters: `ckAPIToken` + `ckWebAuthToken`
   - For web applications

3. **Server-to-Server** - Enterprise access
   - ECDSA P-256 signature in Authorization header
   - Most complex, most secure

**The Generator Limitation:**

<!-- ORIGINAL [CONTENT] BLOCK - PRESERVED AS-IS -->
While we can model these in OpenAPI yaml, this isn't helpful to the developer using MistKit. Specifically if you intend to use the **Web Auth Token** method. To acquire a **Web Auth Token**, you need to start with just your service's **API Token** and then authenticate (typically through the web) to get the **Web Auth Token**. At this point you'd need to switch to using the **Web Auth Token** authentication method. Switching between different authentication methods aren't supported necessarily via the swift-openapi-generator.
<!-- END ORIGINAL [CONTENT] -->

**The Claude Insight - Middleware Pattern:**

Claude suggested: "Use middleware to handle authentication dynamically rather than relying on generator's built-in auth."

**The Solution:**

1. **OpenAPI**: Define all three `securitySchemes` but make endpoint security optional (`security: []`)
2. **Middleware**: Implement `AuthenticationMiddleware` that inspects `TokenManager` at runtime
3. **TokenManager Protocol**: Three implementations (API, WebAuth, ServerToServer)
4. **Runtime Selection**: Client chooses auth method via TokenManager injection

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

**Why This Works:**
- ✅ Generator doesn't need to handle auth complexity
- ✅ We control authentication at runtime
- ✅ Easy to test (inject mock TokenManager)
- ✅ Supports all three methods seamlessly
- ✅ Can switch auth methods without code changes

**The Breakthrough - September 20, 2025:**

> From conversation after completing the auth layer:
>
> **User**: "Can you run MistDemo to test the actual functionality?"
>
> **Claude**: *[Runs demo successfully]*
> "Perfect! The MistDemo ran successfully:
> - 🔐 Web Authentication - Used API token + web auth token
> - 📡 CloudKit API Calls - Made multiple successful requests
> - 🌐 HTTP Integration - AuthenticationMiddleware properly added all required parameters
> - 📊 Data Retrieval - Successfully retrieved TodoItem records from CloudKit
>
> The authentication layer is working as designed. **All three authentication methods have a solid foundation! 🎉**"

<a id="challenge-3-api-ergonomics"></a>
### Challenge #3: API Ergonomics

**The Problem - Generated Code is Verbose:**

Using swift-openapi-generator's output directly:

```swift
// Painful verbose usage
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

**Problems:**
- 🔴 Too much boilerplate
- 🔴 Nested type references
- 🔴 Manual response unwrapping
- 🔴 Not idiomatic Swift

**The Design Session with Claude:**

```
Me: "I need the generated code hidden, but a friendly public API.
     Users shouldn't know OpenAPI exists."

Claude: "Three layers:
         1. Generated (internal only)
         2. Middleware + protocols (internal)
         3. Simple public API

         Here's a protocol sketch for CloudKitService..."

Me: "I want clean, idiomatic Swift. What should the public API look like?"

Claude: "Hide all the OpenAPI types:
         - Internal generated client
         - Public CloudKitService wrapper
         - Simple async methods
         - Clean error types"

Me: "What about TokenManager?"

Claude: "Make it an Actor for thread safety:
         protocol TokenManager: Actor {
             var hasCredentials: Bool { get async }
             func getCurrentCredentials() async throws -> TokenCredentials?
         }
         This gives you actor isolation for all token operations."
```

**The Three-Layer Architecture:**

```
┌─────────────────────────────────────────┐
│  User Code (Public API)                 │
│  • CloudKitService wrapper              │
│  • Simple, intuitive methods            │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  MistKit Abstraction (Internal)         │
│  • MistKitClient                        │
│  • TokenManager implementations (3)     │
│  • Middleware (Auth, Logging)           │
│  • CustomFieldValue                     │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  Generated OpenAPI Client (Internal)    │
│  • Client.swift (3,268 lines)           │
│  • Types.swift (7,208 lines)            │
└─────────────────────────────────────────┘
```

**The Result:** A clean public API that hides all OpenAPI complexity. Generated code stays internal, users interact with idiomatic Swift. Type safety maintained throughout, but ergonomics dramatically improved.

<a id="challenge-4-error-handling"></a>
### Challenge #4: Error Handling

<!-- ORIGINAL [CONTENT] BLOCK - PRESERVED AS-IS -->
**The Problem - CloudKit's Complex Error Model:**

CloudKit returns 9+ HTTP status codes (400, 401, 403, 404, 409, 412, 413, 421, 429, 500, 503), each with nested error details including `serverErrorCode`, `reason`, `uuid`, and sometimes `redirectURL` or `retryAfter`. How do we model this complexity in OpenAPI while making it type-safe and actionable in Swift?

**Before: Apple's Prose Documentation**

> **Record Fetch Error Dictionary**
>
> The error dictionary describing a failed operation with the following keys:
>
> - `recordName`: The name of the record that the operation failed on.
> - `reason`: A string indicating the reason for the error.
> - `serverErrorCode`: A string containing the code for the error that occurred. For possible values, see Error Codes.
> - `retryAfter`: The suggested time to wait before trying this operation again.
> - `uuid`: A unique identifier for this error.
> - `redirectURL`: A redirect URL for the user to securely sign in.

**After: OpenAPI Specification**

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

**Translation Decisions**:

1. **Error Code Enum**: Converted prose list of error codes to explicit enum
2. **HTTP Status Mapping**: Created reusable response components for each HTTP status
3. **Consistent Schema**: All errors use same `ErrorResponse` schema
4. **Status Documentation**: Linked HTTP statuses to CloudKit error codes in descriptions

This enables:
- **Type-Safe Error Handling**: Generated code includes all possible error codes
- **Automatic Deserialization**: Errors automatically parsed to correct type
- **Centralized Definitions**: Define once, reference everywhere

**HTTP Status Code to CloudKit Error Mapping**:

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

**The Result**:

This structured error handling enables the generated client to provide specific, actionable error messages rather than generic HTTP failures. Developers get type-safe error codes, HTTP status mapping, and clear guidance on how to handle each error condition.
<!-- END ORIGINAL [CONTENT] -->

<a id="the-iterative-workflow-with-claude"></a>
### The Iterative Workflow with Claude

**The Pattern That Emerged:**

1. **I draft the structure**
   - Sketch endpoints, major types, auth flow
   - Provide CloudKit domain knowledge

2. **Claude expands**
   - Fills in request/response schemas
   - Generates boilerplate for similar endpoints
   - Creates consistent patterns

3. **I review for CloudKit accuracy**
   - Check against Apple docs
   - Add edge cases and CloudKit quirks
   - Refine error responses

4. **Claude validates consistency**
   - Catches schema mismatches
   - Finds missing `$ref` references
   - Suggests improvements

5. **Iterate until complete**

**Example - The `/records/query` Endpoint**:
- Me: "Here's the query endpoint from Apple's docs"
- Claude: "Here's a complete OpenAPI definition with request/response schemas"
- Me: "Add `resultsLimit` validation and `continuationMarker` for pagination"
- Claude: "Updated, and I noticed the `zoneID` should be optional"

**Timeline**: What might take a week solo took 3-4 days with Claude's help.

**Key Message**: Claude Code shines at iterative refinement of structured data.

**The OpenAPI Creation Sprint - July 2024:**

The actual work of creating the OpenAPI specification took 4 days. I started with Apple's CloudKit Web Services documentation and worked through iterative refinement with Claude: sketch → expand → review → refine. We solved Field Value polymorphism with the oneOf pattern (handling the ASSETID quirk), completed authentication modeling with three security schemes, and Claude suggested the middleware pattern for auth early. The impact was clear—accelerated spec creation (4 days vs estimated 1 week solo) and consistent endpoint patterns across 15 operations.

The foundation was set. But would it actually work in production?

<a id="whats-next"></a>
## What's Next

<!-- CLAUDE-WRITTEN PROSE - REVIEW AND EDIT AS NEEDED -->
<!-- Theme: Cliffhanger leading to Part 2 - real-world validation -->
<!-- Target: ~150 words -->

After three months of collaboration with Claude, I had:
- ✅ 10,476 lines of generated, type-safe Swift code
- ✅ Three authentication methods working seamlessly
- ✅ CustomFieldValue handling CloudKit's polymorphic types
- ✅ Clean public API hiding OpenAPI complexity
- ✅ 161 tests across 47 test files

The OpenAPI spec was complete. The generated client compiled. The abstraction layer was elegant. Unit tests passed.

**But unit tests prove correctness—real applications prove usability.**

Would MistKit's abstractions actually work when building production software? Could the type-safe API handle CloudKit's quirks at scale? Would developers find it intuitive, or would they hit walls the unit tests never revealed?

I needed to find out. Not with toy examples or mock data, but with real applications solving real problems. So I built two: **Celestra**, an RSS aggregator syncing thousands of articles to CloudKit, and **Bushel**, a macOS version tracker managing complex software relationships.

What I discovered changed how I think about API design, AI collaboration, and the gap between "it compiles" and "it works."

**[Continue to Part 2: Real-World Lessons →](https://brightdigit.com/tutorials/rebuilding-mistkit-claude-code-part-2/)**
<!-- END CLAUDE-WRITTEN -->

<!-- WRITING GUIDANCE FOR THIS SECTION -->
<!-- Key phrases: "unit tests prove correctness—real applications prove usability", "changed how I think" -->
<!-- Voice notes: Creates tension between theory and practice, concrete examples (Celestra, Bushel) -->
<!-- Connect to: Sets up Part 2's focus on real-world validation and lessons learned -->
<!-- END GUIDANCE -->

---

**In this series:**
1. [Building SyntaxKit with AI](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/) - Elegant code generation with SwiftSyntax
2. **Rebuilding MistKit with Claude Code (Part 1)** ← You are here
3. Coming soon: Rebuilding MistKit with Claude Code (Part 2) - Real-world validation and lessons learned
