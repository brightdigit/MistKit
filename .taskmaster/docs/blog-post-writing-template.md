# Blog Post Writing Template: Rebuilding MistKit with Claude Code

**Instructions**: Answer the prompts below with your actual experiences. Each section has questions to guide you, word count targets, and placeholders for your responses.

---

## PART 1: Introduction - The Decision to Rebuild (650 words)

### Opening Paragraph: SyntaxKit Transition (~150 words)

**Prompt**: Write the opening that connects SyntaxKit to MistKit

**Questions to answer**:
1. What was the key lesson from building SyntaxKit? (the pattern/philosophy)
2. When did you look at MistKit v0.2 and realize it needed a rebuild?
3. What made you confident you could do it after SyntaxKit?

**Write here**:
```
[Your opening paragraph - start with "In my previous article about Building SyntaxKit with AI..."]

It had been more than 5 years since I looked at MistKit, my swift package for doing CloudKit on the server. I no longer had a reason to use the product since Sign In With Apple would suffice. However, I did have a couple use cases where it would handy and it's very reasonable pricing would make it an interesting prospect.

In my previous article, I talked about building SyntaxKit using Cursor and Claude Code based on Apple's documentation, exploring the AST of code examples, and more. In the article, I am going to explain a different tact. 

With the creation of the Swift openapi generator, we have a great tool already available to us for generating API from openapi documentation. In this article, I'm going to talk about my approach to create my own openapi document based on the CloudKit documentation, overcoming pitfalls, creating an abstraction layer and my goals for this project.

Through building SyntaxKit, I discovered a sustainable pattern: Me + Claude Code + Code Generation working in harmony. It was time to apply this three-way collaboration to MistKit.
```

---

### Section 1.1: State of MistKit v0.2 (~150 words)

Originally developed as an easy way to link Apple Watches to account in Heartwitch, I hadn't touched MistKit in over 5 years and a lot has changed:

* **Sign In With Apple** offers a simpler way to login from the Apple Watch while not having to maintain 2 databases. Going forward this is the way I would develop authentication on a full stack swift application.

* **OpenAPI Generator** - in 2020 I had to develop my own abstraction for Vapor vs Async Client vs URLSession. Along with the code generation, this would great simplify my codebase.

* **Swift 6** - in 2020 there were still plenty of completion handlers. With async-await I can create something that's both much cleaner and safer.

On top of these major advances, it was much too difficult in my limited time to continue adding features to the library. However with the advent of LLMs I was offered an opportunity to think differently.

---

### Section 1.2: Need for Change (~100 words)

Just as with SyntaxKit, I can take an indirect approach to rebuilding MistKit with these new technologies. Rather then building the Swift API directly, we create an openapi document which the code generator can use to generate the CloudKit API for me.

OpenAPI is a specification for documenting HTTP services—essentially a YAML file that defines every endpoint, request/response schema, and error case for an API. Apple's swift-openapi-generator reads this document and generates type-safe Swift code at build time: a `Client` type with methods for each operation, Codable structs for all models, and automatic encoding/decoding. Instead of maintaining thousands of lines of networking boilerplate, you maintain one OpenAPI document, and the generator keeps your code in sync whenever the spec changes.

This worked for the most part except for 2 challenging pieces: dynamic data types and authentication.

---





```

---

### Section 1.4: The Bold Decision (~200 words)

**Prompt**: Describe the three-way collaboration vision

**Questions to answer**:
1. What role would OpenAPI play?
We would create a openapi.yml for the CloudKit Rest API. Swift OpenAPI Generator would generate the code to communicate with it.
2. What role would Claude Code play?
Claude Code would parse Apple's documentation and iteratively build the openapi.yml.
3. What role would you play?
>I would provide requirements and guidance on how I want MistKit to work.
4. What was the timeline?
> No timeline
5. What was the result?

> We've been able to successfully write and read record type of all kinds right now.

**The Vision - A Three-Way Collaboration**:

1. **OpenAPI specification**:
The OpenAPI spec would serve as the foundation, defining all 17 CloudKit Web Services endpoints across six categories (records, zones, subscriptions, users, assets, tokens). The Swift OpenAPI Generator would then transform this single YAML file into over 20,000 lines of type-safe Swift code—complete request/response models, HTTP client logic, and automatic encoding/decoding. Any API changes would simply require updating the spec and regenerating.

2. **Claude Code**:
Claude would handle the translation of Apple's prose documentation into structured OpenAPI YAML, maintaining consistency across hundreds of schemas. It would also generate comprehensive test suites, draft the abstraction layer code, and assist with refactoring when architectural decisions changed.

3. **Human architecture** (you):
I would provide the architectural vision—the three-layer design, protocol-oriented patterns, and security constraints. I have a better understanding of what a developer would want to do and what is required for a modern Swift library. LLMs can be dated pretty quickly and I have a good understanding of the openapi generator as well as CloudKit. So I spot a misunderstanding and an outdated implementation of an API easily. My domain expertise in CloudKit's quirks (like ASSETID vs ASSET) would guide the implementation decisions.


**Timeline**: July 2025 - Present (~4 months, ongoing development)

**The Result**:
- ✅ **17 CloudKit endpoints** fully specified in OpenAPI specification
- ✅ **20,952 lines** of auto-generated, type-safe Swift code from the spec
- ✅ **157 test methods** across 66 test files covering authentication, middleware, field types, and error handling
- ✅ **45 hand-written Swift files** in the abstraction layer
- ✅ **Core features working**: Query/modify records, list zones, fetch user info, both authentication methods (Web Auth Token, Server-to-Server)




```

---

## PART 2: Translating CloudKit Docs to OpenAPI with Claude Code (900 words)

### Section 2.1: Why OpenAPI? (~150 words)

**OpenAPI** (formerly Swagger) is a specification format for describing REST APIs—a blueprint that defines every endpoint, parameter, request/response schema, authentication requirement, and error format. Think of it as machine-readable API documentation.

**The "Aha" Moment**: CloudKit Web Services is already a well-defined REST API. Apple's documentation describes every endpoint, parameter, and response format. Instead of manually translating that documentation into Swift code (and keeping it in sync), we could:

1. Create an OpenAPI specification from Apple's documentation
2. Use Apple's `swift-openapi-generator` to create type-safe Swift code
3. Build a friendly abstraction layer on top

**Benefits of this approach**:
- ✅ **Type safety** — If the request compiles, it matches the OpenAPI spec
- ✅ **Completeness** — Every endpoint defined in the spec is available
- ✅ **Maintainability** — Spec changes regenerate code automatically
- ✅ **Accuracy** — Generated code exactly matches API requirements
- ✅ **No manual JSON** — Codable types handle serialization

---

### Section 2.2: The Translation Challenge (~150 words) **NEW**

**Prompt**: Describe why translating CloudKit docs to OpenAPI was challenging

**Questions to answer**:
1. What format are Apple's CloudKit docs in? (prose, not machine-readable)
> prose
2. What needed to be translated? (endpoints, types, errors into structured YAML)
Yes all of these things needed to be translated correctly.
3. Why was this perfect for Claude Code collaboration?
It is really good at reading documentation, requirements, or descriptions of any kind and translating them to code.
4. What was your role vs Claude's role?
Claude's role was to translate the documentation into yaml. My role was to guide Claude with my experience working with the CloudKit Rest API.

**Write here**:
```
**The Human Problem**:

Apple's CloudKit documentation exists in two main forms—both written for human readers, not machines. The web services documentation describes endpoints and structures in prose, while the CloudKit JS documentation provides additional structural details. Neither is machine-readable or structured enough to directly generate code from.

I needed to convert these narrative documents into an easy-to-use format (markdown) that Claude Code could process. Using https://llm.codes, I transformed both documentation sources into markdown that preserved the technical details while being digestible for AI analysis.


**Why This Was Perfect for Claude Code**:

This translation task played directly to Claude's strengths. Pattern recognition allowed it to identify consistent structures across Apple's documentation—similar endpoint patterns, repeating field types, common error responses. Consistency checking meant Claude could maintain uniformity across the large YAML specification with hundreds of schemas, catching discrepancies I might miss. Most importantly, iteration speed was phenomenal—when I spotted a CloudKit quirk or API edge case, Claude could refine the spec in minutes rather than the hours manual editing would require.


**The Workflow That Emerged**:

1. **I provide**: Markdown-converted Apple documentation for a specific endpoint or feature
2. **Claude drafts**: Initial OpenAPI YAML with endpoints, schemas, and types
3. **I review**: Check for CloudKit-specific quirks and architectural fit
4. **Claude updates**: Refine based on my domain expertise feedback
5. **Iterate**: Continue until the endpoint is complete and validated



```

---

### Section 2.3: Field Value - The Dynamic Typing Challenge (~250 words) **MAJOR**

**Prompt**: Tell the story of solving the Field Value polymorphism problem WITH Claude

**Questions to answer**:
1. What was the problem? (CloudKit fields are dynamically typed, OpenAPI is static)
✅ **ANSWERED**: CloudKit uses dynamic typing like GraphQL - a single field can be string, int, double, location, reference, asset, etc. OpenAPI requires static types known at compile time.

2. What did you tell Claude initially?
✅ **ANSWERED**: "Here's the CloudKit field value structure from Apple's docs. Each field has a 'value' that can be any of a dozen different types, plus a 'type' string indicating which one it is."

3. What did Claude suggest first? (probably `oneOf` pattern)
✅ **ANSWERED**: Yes, Claude suggested using OpenAPI's `oneOf` pattern to model the polymorphic values.

4. What CloudKit quirk did you identify? (ASSETID vs ASSET)
✅ **ANSWERED**: ASSET is used for uploads (contains fileChecksum, size, receipt, wrappingKey), while ASSETID is used for downloads (contains downloadURL). Both use the same AssetValue structure but different type identifiers.

5. What did Claude suggest for that?
✅ **ANSWERED**: Claude suggested handling both ASSET and ASSETID types by decoding them to the same AssetValue type using a decoder dictionary pattern.

6. How did you arrive at the final CustomFieldValue design?
✅ **ANSWERED**: Used a decoder dictionary with closures instead of switch statements, created a type override in the OpenAPI generator config, and implemented a two-layer design: public `FieldValue` enum for the API, internal `CustomFieldValue` struct for wire format.

**Write here**:
```
**The Core Problem**:

CloudKit fields are dynamically typed—a single field can hold strings, numbers, locations, references, or assets. Just like GraphQL, CloudKit uses runtime type information to determine what each field contains. However, OpenAPI and Swift's type system expect static types known at compile time.

CloudKit's JSON structure looks like this:
{
  "name": {"value": "John", "type": "STRING"},
  "age": {"value": 42, "type": "INT64"},
  "photo": {"value": {...}, "type": "ASSET"}
}

The challenge: How do you model this polymorphism in OpenAPI's static schema system?




**The Claude Code Conversation**:

Me: "Here's the CloudKit field value structure from Apple's docs. Each field has a 'value' that can be any of a dozen different types, plus a 'type' string indicating which one it is."

Claude: "I can model this using OpenAPI's `oneOf` pattern. Let me draft a schema:"

```yaml
FieldValue:
  type: object
  properties:
    value:
      oneOf:
        - $ref: '#/components/schemas/StringValue'
        - $ref: '#/components/schemas/Int64Value'
        - $ref: '#/components/schemas/AssetValue'
        - $ref: '#/components/schemas/ReferenceValue'
        - $ref: '#/components/schemas/LocationValue'
        - $ref: '#/components/schemas/ListValue'
    type:
      type: string
      enum: [STRING, INT64, DOUBLE, BYTES, REFERENCE, ASSET, ASSETID, LOCATION, TIMESTAMP, LIST]
```

Me: "Wait—there are TWO asset types: ASSET and ASSETID. What's the difference, and how should we handle them?"

Claude: "Looking at Apple's documentation, ASSET is used when uploading (contains fileChecksum, size, receipt, wrappingKey), while ASSETID is used when reading (contains downloadURL). They use the same structure but different type identifiers depending on context. Both should decode to AssetValue."

Me: "Good catch. Now we need a custom implementation because the generated code won't handle this nuance automatically. Can you create a CustomFieldValue type?"

Claude: "Here's a design using a decoder dictionary pattern:

```swift
internal struct CustomFieldValue: Codable, Sendable {
    internal enum FieldTypePayload: String, Codable {
        case asset = "ASSET"
        case assetid = "ASSETID"
        // ... other types
    }

    private static let fieldTypeDecoders: [FieldTypePayload: (Container) throws -> CustomFieldValuePayload] = [
        .asset: { .assetValue(try $0.decode(AssetValue.self, forKey: .value)) },
        .assetid: { .assetValue(try $0.decode(AssetValue.self, forKey: .value)) },
        // ... other decoders
    ]

    internal let value: CustomFieldValuePayload
    internal let type: FieldTypePayload?
}
```

This uses a dictionary of closures instead of a massive switch statement, making it easier to maintain."

Me: "Perfect. Now add comprehensive tests for all field types, including edge cases."

Claude: "I'll generate tests covering all field types: String, Int64, Double, Bytes, Date, Location (with all optional fields), Reference (with and without actions), Asset (upload context), ASSETID (download context), and Lists (including nested lists and empty arrays)."



**The Iterative Design Process**:

1. **OpenAPI Schema**: Used `oneOf` pattern to model polymorphic values, enumerated all type identifiers including ASSET/ASSETID distinction

2. **Custom Swift Type**: Created `CustomFieldValue` with decoder dictionary pattern, unified ASSET/ASSETID handling to same `AssetValue` type

3. **Type Override**: Configured OpenAPI generator to replace generated `FieldValue` with `CustomFieldValue`:
```yaml
typeOverrides:
  schemas:
    FieldValue: CustomFieldValue
```

4. **Two-Layer Design**: Public `FieldValue` enum for clean API, internal `CustomFieldValue` struct for wire format handling

5. **Comprehensive Testing**: Generated test suite covering all field types, edge cases, and the ASSET/ASSETID distinction

```

**Technical content to include** (from existing draft):
- JSON example of polymorphic field (lines 161-183)
- OpenAPI oneOf YAML (lines 186-211)

---

### Section 2.4: Authentication - Two Methods (~200 words)

CloudKit supports two authentication methods:

1. **Web Auth Token** — User-specific access that requires first obtaining an API Token, then exchanging it for a Web Auth Token (both sent as query parameters)
2. **Server-to-Server** — Enterprise access using ECDSA P-256 signatures

In OpenAPI, these become security schemes:

```yaml
components:
  securitySchemes:
    ApiTokenAuth:
      type: apiKey
      in: query
      name: ckAPIToken
      description: API token authentication

    WebAuthToken:
      type: apiKey
      in: query
      name: ckWebAuthToken
      description: Web authentication token

    ServerToServerAuth:
      type: http
      scheme: bearer
      description: Server-to-server authentication using ECDSA signatures
```

**Claude's Contribution**:

Claude helped model all three security schemes in the OpenAPI specification, ensuring they properly represented CloudKit's authentication requirements. Claude suggested defining them as optional security schemes that could be applied per-endpoint, allowing the flexibility to specify which authentication methods work with each operation. This made the spec accurate to CloudKit's actual API behavior where different operations may support different auth methods.

---

### Section 2.5: Iterative Refinement Workflow (~150 words) **NEW**

**Prompt**: Describe the back-and-forth workflow that emerged

**Questions to answer**:
1. What was the pattern? (draft → expand → review → validate → iterate)
2. Can you give a specific example? (like modeling `/records/query`)
3. How long did it take vs solo estimate?

**The Pattern That Emerged**:

**1. I Draft Requirements and Guidance**

I provided detailed guidance on how I wanted the API to work based on my experience with CloudKit's actual behavior. I stressed certain styling conventions and test expectations. For validation, I had Claude build command-line tools to test each endpoint in real-world scenarios—actual Web Auth and server-to-server authentication against live CloudKit.

**2. Claude Expands into Implementation**

Claude translated my requirements into the OpenAPI YAML specification, creating endpoint definitions with request/response schemas. Claude also drafted the initial abstraction layer code for easier usage.

**3. I Review for Correctness and Completeness**

I verified the API specification made sense and could actually work with CloudKit's real behavior. One key concern was ensuring Claude wasn't generating specs that only looked correct but wouldn't work in practice.

**4. Claude Validates Through Testing**

For each endpoint, Claude generated unit tests for the types and middleware, then created real-world test scenarios using command-line tools. This caught issues like incorrect field types or missing optional parameters.

**5. Iterate Until Endpoint is Complete**

We iterated on each individual endpoint until it passed all three validation layers:
- ✅ **Correct spec**: OpenAPI accurately represents CloudKit's API
- ✅ **Unit tests pass**: Types, middleware, and authentication work correctly
- ✅ **Real-world validation**: Command-line tool successfully calls CloudKit and handles responses

Only then would we move to the next endpoint. The library is still in progress—not all CloudKit endpoints are implemented yet, but each completed endpoint has been thoroughly validated through this iterative process.

**Example - The `/records/query` Endpoint**:

**Round 1**: I explained the query endpoint requirements. Claude generated initial OpenAPI spec.

**Round 2**: Claude created unit tests for the query request/response types.

**Round 3**: I noticed the `resultsLimit` had no bounds. Claude added `minimum: 1, maximum: 200` constraints based on CloudKit's actual limits.

**Round 4**: Claude built a command-line tool to test actual queries against CloudKit. Tool revealed we were missing the `desiredKeys` optimization field.

**Round 5**: Added `desiredKeys`, regenerated code, re-tested. Query endpoint now complete and validated.

**Timeline**:

With Claude, implementing and validating each endpoint took 2-4 days depending on complexity. Solo, I estimate 1-2 weeks per endpoint—the iteration cycle of spec → generate → test → fix would be much slower without AI assistance catching edge cases and generating test scenarios.

---

## PART 3: swift-openapi-generator Integration and Challenges (800 words)

### Section 3.1: Why swift-openapi-generator? (~150 words)

Apple announced `swift-openapi-generator` at WWDC 2023, and it immediately became the obvious choice for MistKit:

✅ **Official Apple tool** — Maintained by the Swift Server Workgroup
✅ **Modern Swift** — Generates code using async/await, Sendable, and Swift 6 features
✅ **Cross-platform** — Works on macOS, Linux, and anywhere Swift runs
✅ **Active development** — Regular updates and improvements
✅ **Production-ready** — Used in Apple's own services

**Alternative considered**: We could have used other OpenAPI generators like `openapi-generator` (Java-based) or custom code generation, but `swift-openapi-generator` is purpose-built for modern Swift and integrates seamlessly with Swift Package Manager.

This mirrors the approach from SyntaxKit, where we chose Apple's official SwiftSyntax over alternative AST libraries. Using first-party tools ensures compatibility, ongoing support, and alignment with Swift's evolution. The generator transforms our OpenAPI specification into over 20,000 lines of type-safe Swift code with automatic Codable conformance, typed error handling, and Sendable compliance—all from a single YAML file.

---

### Section 3.2: Authentication Method Conflicts - THE CHALLENGE (~300 words) ⭐ **HIGH PRIORITY**

**Prompt**: Tell the story of the authentication challenge - this is a KEY section

**Questions to answer**:
1. What did swift-openapi-generator expect? (one auth method per endpoint)
2. What did CloudKit need? (three methods, runtime selection)
3. What did you try first that didn't work?
4. What was Claude's key insight? (middleware pattern)
5. How does the solution work? (TokenManager protocol + middleware)
6. Why does this work better than the generator's built-in auth?

**Write here**:
```
**The Problem**:

swift-openapi-generator expects you to define ONE authentication method per endpoint at compile-time. You declare security schemes in your OpenAPI spec, and the generator creates code that expects you to provide those credentials when you instantiate the client.

But CloudKit Web Services needs TWO different authentication methods that must be selected at **runtime**:
1. **Web Auth Token**: User-scoped authentication that requires first obtaining an API Token from the CloudKit dashboard, then exchanging it for a Web Auth Token via the `/tokens/create` endpoint. Both tokens travel together in subsequent requests as query parameters.
2. **Server-to-Server**: Key-based authentication for backend services using ECDSA P-256 signatures. Each request is signed with a private key, and the signature travels in HTTP headers.

These methods have completely different wire formats (query parameters vs. headers) and different use cases (user operations vs. administrative operations). How do you model this when the generator assumes compile-time selection?

**The OpenAPI Challenge**:

OpenAPI security schemes are compile-time declarations. The generator expects you to pick ONE method when you configure your client. There's no built-in support for runtime method selection or complex multi-step authentication flows like CloudKit's Web Auth Token exchange.

**Our First Attempt** (didn't work):

We tried defining both methods in the OpenAPI security array, hoping the generator would provide runtime flexibility:

```yaml
security:
  - ApiTokenAuth: []
  - WebAuthToken: []
  - ServerToServerAuth: []
```

**Problem with that approach**: The generator treated these as compile-time alternatives. You'd still need to choose which auth method to use when instantiating the client—exactly what we were trying to avoid.

**The Solution (Claude's Key Insight)**:

**Claude suggested**: "Don't use the generator's built-in authentication system. Instead, build an **abstraction layer** using the ClientMiddleware protocol from swift-openapi-runtime. This lets you handle authentication at request time, not client initialization time."

**The Approach** (our 4-step solution):

1. **OpenAPI**: Define security schemes for documentation purposes only—don't enforce them in the generated client.

2. **TokenManager Protocol**: Create an abstract interface for authentication credentials with implementations for each method (WebAuthTokenManager, ServerToServerAuthManager, plus APITokenManager for the transitional state during Web Auth Token exchange).

3. **AuthenticationMiddleware**: Implement ClientMiddleware that intercepts every request, gets credentials from the TokenManager, and applies the appropriate authentication based on the method type at runtime.

4. **Runtime Selection**: Inject the TokenManager into the middleware, and the same generated client code works identically regardless of which authentication method is being used—seamless switching.

**Show the AuthenticationMiddleware code**:
```swift
// From AuthenticationMiddleware.swift - the runtime switch
switch credentials.method {
case .apiToken(let apiToken):
  addAPITokenAuthentication(apiToken: apiToken, to: &urlComponents)

case .webAuthToken(let apiToken, let webToken):
  addWebAuthTokenAuthentication(
    apiToken: apiToken,
    webToken: webToken,
    to: &urlComponents
  )

case .serverToServer:
  modifiedRequest = try await addServerToServerAuthentication(
    to: modifiedRequest,
    body: body
  )
}
```

**Why This Works** (list 5 benefits):
- ✅ **Seamless switching**: Change authentication methods by swapping the TokenManager implementation—no changes to API calling code
- ✅ **Runtime flexibility**: Select auth method based on available credentials at runtime, not compile-time
- ✅ **Abstraction hides complexity**: Client code doesn't know or care which authentication method is being used
- ✅ **Handles multi-step flows**: Web Auth Token exchange is handled transparently by AdaptiveTokenManager
- ✅ **Testable and extensible**: Inject mock TokenManagers for testing; middleware pattern supports logging, retry, and other concerns

**Claude's Role in This**:

Claude made this solution possible by:
- Suggesting the ClientMiddleware protocol from swift-openapi-runtime as the architectural foundation
- Helping design the TokenManager abstraction with separate implementations for each auth method
- Identifying that API Token is an intermediate state in the Web Auth flow, not a standalone authentication method
- Recognizing that an abstraction layer enables seamless method switching while keeping the generated client code unchanged

**Key Insight**: When your API's runtime requirements don't fit a code generator's compile-time assumptions, an abstraction layer provides the flexibility without fighting the tool. The TokenManager + Middleware pattern lets us seamlessly switch authentication methods while keeping the same client API—the generated code doesn't need to know about our authentication complexity.

```

---

### Section 3.3: Generated Code Quality (~200 words)

The swift-openapi-generator produces impressive results from our CloudKit OpenAPI specification:

**Generated Code Statistics**:
- **20,952 lines** of type-safe Swift code
- **17 CloudKit endpoints** across six categories (records, zones, subscriptions, users, assets, tokens)
- **100+ Codable types** for requests, responses, and data models
- All code is `Sendable`, `Hashable`, and thread-safe by default

**Before** (manual JSON):
```swift
// Easy to make mistakes - no compile-time checking
let json: [String: Any] = [
    "query": [
        "recordType": "User",
        "filterBy": "age > 18"  // Wrong! Should be an array of filter objects
    ]
]
```

**After** (generated types):
```swift
// Impossible to get wrong - compile error if invalid
let input = Operations.queryRecords.Input(
    path: .init(version: "1", container: containerID, environment: .production, database: ._public),
    body: .json(.init(query: .init(
        recordType: "User",
        filterBy: [.init(fieldName: "age", comparator: .GREATER_THAN, fieldValue: .init(value: .int64Value(18)))]
    )))
)
```

**Benefits**:
- ✅ **Type safety** — If it compiles, it matches the API spec
- ✅ **Sendable conformance** — Safe across actor boundaries
- ✅ **Typed errors** — Each HTTP status gets its own case
- ✅ **No manual JSON** — Codable handles serialization automatically

---

## PART 4: Building the Abstraction Layer with Claude Code (900 words)

### Section 4.1: Problem with Raw Generated Code (~150 words)

Generated code is powerful, but it's not always pleasant to use directly. Using the generated client requires verbose, nested type references:

```swift
// Direct generated code usage - works, but painful
let input = Operations.queryRecords.Input(
    path: .init(
        version: "1",
        container: "iCloud.com.example.MyApp",
        environment: Components.Parameters.environment.production,
        database: Components.Parameters.database._private
    ),
    body: .json(.init(
        query: .init(
            recordType: "User",
            filterBy: [
                .init(
                    fieldName: "age",
                    comparator: .GREATER_THAN,
                    fieldValue: Components.Schemas.FieldValue(value: .int64Value(18), type: .INT64)
                )
            ]
        )
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

**Problems**: Too much boilerplate, nested type references, manual response unwrapping, and not idiomatic Swift. MistKit's abstraction layer solves this.

---

### Section 4.2: Designing the Architecture - Collaboration Story (~300 words)

**The Initial Design Session with Claude**:

Me: "The generated code works but it's too verbose. I need a clean abstraction layer that hides the OpenAPI complexity. It should feel natural to Swift developers, use modern concurrency patterns, and support both authentication methods seamlessly."

Claude: "I suggest a three-layer architecture: a public-facing service layer that provides simple methods, an internal abstraction layer with protocol-based authentication management, and the generated OpenAPI client at the bottom. We can use the ClientMiddleware protocol from swift-openapi-runtime to handle authentication transparently."

Me: "Good start. The TokenManager should be an actor for thread-safe credential management, and we need separate implementations for each auth method. How do we handle the Web Auth Token exchange flow where you start with just an API token?"

Claude: "Here's a protocol-based design:

```swift
protocol TokenManager: Actor {
    func credentials() async throws -> AuthenticationCredentials
}

// Separate implementations
actor WebAuthTokenManager: TokenManager { }
actor ServerToServerAuthManager: TokenManager { }
actor AdaptiveTokenManager: TokenManager { } // Handles token exchange
```

The middleware intercepts requests, calls `credentials()`, and applies the auth method based on the credential type. The same client code works with any TokenManager—just swap the implementation."

**The Architecture That Emerged**:

```
User Code (CloudKitService)
    ↓ Simple, intuitive methods
MistKit Abstraction Layer
    ↓ Protocol-based TokenManager + AuthenticationMiddleware
Generated OpenAPI Client
    ↓ Type-safe HTTP operations
OpenAPI Runtime
```

**What Claude Contributed**:
- ClientMiddleware pattern suggestion from swift-openapi-runtime
- Protocol-based TokenManager design with actor isolation
- Recognition that middleware enables runtime auth method switching

**What I Contributed**:
- Requirements for thread safety and modern Swift patterns
- Insight about API Token being transitional state, not standalone auth
- Decision to use actors for TokenManager implementations

**Key Insight**: The collaboration worked because I provided domain knowledge (CloudKit's auth quirks) while Claude provided architectural patterns (middleware, protocols) from its knowledge of Swift ecosystem best practices.

---

### Section 4.3: Modern Swift Features (~200 words)

MistKit leverages modern Swift features throughout:

**1. Async/Await for All Operations**

Every CloudKit operation uses async/await naturally:

```swift
protocol TokenManager: Sendable {
    var hasCredentials: Bool { get async }
    func validateCredentials() async throws(TokenManagerError) -> Bool
}
```

**2. Sendable Compliance**

All types are `Sendable` for thread-safety:

```swift
internal struct MistKitConfiguration: Sendable {
    internal let container: String
    internal let environment: Environment
    // All immutable - inherently thread-safe
}
```

**3. Typed Throws (Swift 6)**

Specific error types enable precise error handling:

```swift
func validateCredentials() async throws(TokenManagerError) -> Bool

// Guaranteed error type
catch let error as TokenManagerError {
    switch error {
    case .invalidCredentials(.apiTokenEmpty): // ...
    }
}
```

**4. Protocol-Oriented Design**

The TokenManager protocol enables flexible implementations:

```swift
public protocol TokenManager: Sendable { }
public struct APITokenManager: TokenManager { }
public struct WebAuthTokenManager: TokenManager { }
public struct ServerToServerAuthManager: TokenManager { }
```

**5. Middleware Pattern**

Authentication and logging as composable middleware layers, using the swift-openapi-runtime ClientMiddleware protocol for seamless integration with the generated client.

---

### Section 4.4: CustomFieldValue Design Decision (~150 words)

**The Question**: Should we use the generated FieldValue type or override it with a custom implementation?

**The CloudKit Quirk**:

CloudKit uses two different type identifiers for assets:
- **ASSET**: Used when uploading (contains fileChecksum, size, receipt, wrappingKey)
- **ASSETID**: Used when downloading (contains downloadURL)

Both decode to the same `AssetValue` structure, but the generated code couldn't handle this dual-type pattern automatically—it would create separate types for each.

**The Decision**: Override with a custom implementation that maps both ASSET and ASSETID to the same underlying type.

**Configuration** in `openapi-generator-config.yaml`:
```yaml
typeOverrides:
  schemas:
    FieldValue: CustomFieldValue
```

**Claude's Role**:

Claude helped by:
- Drafting the CustomFieldValue decoder dictionary pattern using closures instead of massive switch statements
- Generating comprehensive tests for all field types including the ASSET/ASSETID edge case
- Suggesting the two-layer design: internal `CustomFieldValue` for wire format, public `FieldValue` enum for API

This override ensures CloudKit's polymorphic fields work correctly while maintaining type safety.

---

### Section 4.5: Security Built-In (~100 words)

Security is built into MistKit from the ground up. LoggingMiddleware automatically masks sensitive data:

```swift
internal enum SecureLogging {
    internal static func maskToken(_ token: String) -> String {
        guard token.count > 8 else { return "***" }
        let prefix = token.prefix(4)
        let suffix = token.suffix(4)
        return "\(prefix)***\(suffix)"
    }
}

// In LoggingMiddleware
private func formatQueryValue(for item: URLQueryItem) -> String {
    guard let value = item.value else { return "nil" }

    // Automatically mask sensitive parameters
    if item.name.lowercased().contains("token") ||
       item.name.lowercased().contains("key") {
        return SecureLogging.maskToken(value)
    }

    return value
}
```

**Output**: `ckAPIToken=iClo***oken` instead of exposing full tokens.

**Collaboration note**: Claude generated the logging middleware structure, while I specified the security constraints and masking requirements based on CloudKit's sensitive parameter names.


---

## PART 6: Lessons Learned - Building with Claude Code (750 words)

### Section 6.1: What Claude Code Excelled At (~200 words) **EXPAND**

**Prompt**: Expand on each thing Claude did well with specific examples

**Current draft has bullets** (lines 1354-1362) - expand each

**Questions for each item**:

**✅ Test Generation**:
- How many tests?
- What types?
- What edge cases did Claude find?

**✅ OpenAPI Schema Validation**:
- What inconsistencies did Claude catch?
- Examples?

**✅ Boilerplate Code**:
- What boilerplate?
- How much time saved?

**✅ Refactoring Assistance**:
- When did architecture change?
- How did Claude help update code?

**✅ Documentation**:
- What docs did Claude draft?

**✅ Test Generation**

Claude excelled at generating comprehensive test suites. For MistKit, Claude created **157 test methods** across **66 test files**, covering authentication middleware, field type encoding/decoding, error handling, and edge cases.

Most impressively, Claude identified edge cases I hadn't considered—like testing empty lists, nested lists, and the ASSET vs ASSETID distinction in different contexts. When I asked for "field value tests," Claude generated tests for all 10+ field types with their optional parameters and boundary conditions. This would have taken weeks to write manually.

**✅ OpenAPI Schema Validation**

Claude caught inconsistencies in the OpenAPI specification that would have caused runtime errors. For example, when I initially defined the query endpoint, Claude noticed that `resultsLimit` had no constraints and suggested adding `minimum: 1, maximum: 200` based on CloudKit's actual API limits. Claude also spotted missing required fields and inconsistent enum values across related schemas.

**✅ Boilerplate Code**

Claude generated all the middleware implementations, TokenManager protocol implementations, and error handling boilerplate. Instead of spending days writing similar patterns across different auth methods, Claude drafted the initial implementations in minutes. I focused on reviewing and refining the security-sensitive parts while Claude handled the mechanical translation.

**✅ Refactoring Assistance**

When I decided to change from struct-based TokenManagers to actor-based implementations for better thread safety, Claude helped update all the call sites, tests, and documentation. This architectural change touched dozens of files—Claude handled the mechanical find-and-replace work while I focused on verifying the concurrency semantics were correct.

**✅ Documentation**

Claude drafted DocC documentation comments for all public APIs, including parameter descriptions, error cases, and usage examples. While I refined the explanations to match CloudKit terminology, Claude provided the initial structure and comprehensive coverage, ensuring no public API was left undocumented.

---

### Section 6.2: What Required Human Judgment (~200 words) **EXPAND**

**Prompt**: Expand on each thing that needed your judgment with specific examples

**Current draft has bullets** (lines 1364-1370) - expand each

**Questions for each item**:

**❌ Architecture Decisions**:
- What specific decisions?
- Why couldn't Claude make these?

**❌ Security Patterns**:
- What security decisions?
- Examples of what you specified?

**❌ Authentication Strategy**:
- What choice did you make?
- Why?

**❌ Performance Trade-offs**:
- What trade-off?
- Why that choice?

**❌ Developer Experience**:
- What DX decisions?
- Examples?

**❌ Architecture Decisions**

The three-layer architecture (public service → abstraction layer → generated client) was a human decision. Claude could suggest patterns, but deciding to hide the generated code entirely behind a friendly API required understanding MistKit's target audience—developers who want simple CloudKit access, not OpenAPI experts. I made the call that user-facing types should be clean Swift enums and structs, not nested Components.Schemas references.

**❌ Security Patterns**

I specified which parameters needed masking (anything with "token" or "key" in the name), how much of the token to show (first 4 and last 4 characters), and that credentials should never be logged in full. Claude implemented the masking logic, but determining what constitutes "sensitive data" in CloudKit's context required my domain knowledge.

**❌ Authentication Strategy**

The decision to use protocol-based TokenManager with actor isolation, rather than a simpler closure-based approach, was mine. I knew we needed thread-safe credential management, support for token refresh, and seamless switching between auth methods. Claude suggested the middleware pattern, but I decided actors were the right concurrency primitive for TokenManagers based on their state management needs.

**❌ Performance Trade-offs**

I chose to pre-generate and commit the OpenAPI client code rather than using the build plugin. This trades larger repository size for faster consumer builds and better IDE experience. Claude couldn't make this trade-off—it requires understanding developer workflows, CI/CD pipelines, and library distribution best practices.

**❌ Developer Experience**

Decisions like making the public API use simple method calls (`client.queryRecords(...)`) instead of exposing the generated Input/Output types required understanding what feels natural to Swift developers. I chose to use result types for operations rather than throwing errors for business logic failures (like "record not found"), keeping Swift error handling for actual errors.

---

### Section 6.3: The Effective Collaboration Pattern (~200 words) **NEW**

**Prompt**: Describe the workflow that emerged

**Questions to answer**:
1. What were the 5 steps?
2. Can you give a real example? (TokenManager protocol design with rounds?)

**The Workflow That Emerged**:

**Step 1**: I Define Architecture and Constraints
"I need actor-based TokenManagers that support three authentication methods, with async credential retrieval and automatic token refresh for Web Auth Tokens."

**Step 2**: Claude Drafts Implementation
Claude produces the protocol definition, three implementations (APITokenManager, WebAuthTokenManager, ServerToServerAuthManager), and the middleware integration—typically within 15 minutes.

**Step 3**: I Review for Security, Performance, Design
I check: Are credentials properly isolated in actors? Is the error handling comprehensive? Does the API feel natural? Are there any data races? Should this be `internal` or `public`?

**Step 4**: Claude Generates Tests and Edge Cases
"Write tests for all three TokenManager implementations, including edge cases like expired tokens, missing credentials, and concurrent access." Claude generates 20+ test cases covering scenarios I might have missed.

**Step 5**: Iterate Until Complete
Typically 2-3 iterations. First draft gets the structure right, second iteration refines edge cases and error messages, third iteration polishes documentation and naming.

**Real Example - AuthenticationMiddleware Design**:

**Round 1**:
Me: "We need middleware that applies authentication based on the TokenManager's credential type—query parameters for Web Auth, headers for Server-to-Server."
Claude: Delivers initial middleware with authentication logic and proper error handling.

**Round 2**:
Me: "The ECDSA signature generation needs the request body for Server-to-Server. Also add request logging for debugging."
Claude: Updates middleware to pass body through, adds LoggingMiddleware, chains them correctly.

**Round 3**:
Me: "Mask sensitive parameters in logs—anything with 'token' or 'key' in the name."
Claude: Implements SecureLogging utility and integrates it into LoggingMiddleware.

**Result**: Completed in 3 hours vs estimated 2 days solo. The iteration speed—getting feedback, making changes, generating tests—made the difference.

---

### Section 6.4: Lessons Applied from SyntaxKit (~150 words) **NEW**

**Prompt**: Connect to lessons from SyntaxKit

**Questions to answer**:
1. What did SyntaxKit teach you?
2. How did you apply those to MistKit?
3. What lessons were reinforced?

**SyntaxKit Taught Me**:

1. **Use official Apple tooling** - SwiftSyntax proved more reliable than third-party parsers
2. **AI excels at generation, not architecture** - Claude helped with traversal patterns, not AST design
3. **Commit generated code** - Reviewable artifacts beat build-time generation
4. **Start with the spec** - AST definitions drove everything; code followed

**Applied to MistKit**:

1. ✅ Chose `swift-openapi-generator` (official Apple tool) over third-party alternatives
2. ✅ I designed the three-layer architecture; Claude implemented the patterns
3. ✅ Pre-generated OpenAPI client code committed to repository for review
4. ✅ OpenAPI spec is the source of truth; all Swift code derives from it

**Reinforced Lessons**:

The SyntaxKit experience taught me to trust code generation when you control the source specification. MistKit reinforced this: OpenAPI spec → 20,000+ lines of type-safe Swift with zero maintenance burden. Both projects prove that specification-driven development with AI assistance is sustainable.

The key insight remains: **AI accelerates the mechanical work once you've made the architectural decisions**. SyntaxKit used SwiftSyntax's AST as the spec; MistKit uses OpenAPI. Different domains, same pattern—let the specification drive everything, use AI for the translation work.

**Key Message**: Code generation + AI collaboration isn't about replacing developers—it's about freeing us from mechanical translation work so we can focus on architecture, security, and developer experience. The pattern works across domains: AST manipulation (SyntaxKit) and REST APIs (MistKit) both benefit from this approach.

---

## PART 7: Conclusion - The OpenAPI + Claude Code Pattern (700 words)

### Section 7.1: The Pattern Emerges (~200 words) **NEW**

**Prompt**: Draw the connection between SyntaxKit and MistKit patterns

**Use the comparison table from outline** (lines 830-843), then explain

**Write here**:
```
**From SyntaxKit to MistKit - A Philosophy**:

[Paste or recreate the comparison table]

| Aspect | SyntaxKit | MistKit |
|--------|-----------|---------|
| **Domain** | [Fill] | [Fill] |
| **Generation Source** | [Fill] | [Fill] |
| [etc.] | | |


**The Common Philosophy**:

[Explain the pattern in your words]




[What's the formula?]



```

---

### Section 7.2: What v1.0 Alpha Delivers (~150 words)

**Already exists in draft - KEEP**

From lines 1387-1395

**Action**: ✅ Copy from existing draft

---

### Section 7.3: Series Continuity & What's Next (~200 words) **NEW**

**Prompt**: Position within the series and tease future articles

**Questions to answer**:
1. What was Part 1 (SyntaxKit) about and its lesson?
2. What is Part 2 (MistKit) about and its lesson?
3. What's coming in Parts 3 & 4? (Bushel, Celestra)
4. How does the series evolve?

**Write here**:
```
**Modern Swift Patterns Series**:

**Part 1**: [SyntaxKit - what and lesson]



**Part 2**: [MistKit - what and lesson]



**Coming Next**:
- **Part 3**: [Bushel - what will it show?]
- **Part 4**: [Celestra - what will it show?]

**The Evolution**:

[How does the series progress? Compile-time → specification → application?]




```

---

### Section 7.4: The Bigger Philosophy (~150 words) **NEW**

**Prompt**: Explain why this approach matters

**Write here**:
```
**Sustainable Development Through Collaboration**:

[Explain the three-way collaboration in your words]




**Why This Matters**:

**OpenAPI eliminates**: [What maintenance burden?]


**Claude eliminates**: [What tedium?]


**You provide**: [What irreplaceable judgment?]


**Together**: [What's the result?]




```

---

### Try It Yourself + Closing (~50 words)

**Already exists in draft - KEEP**

From lines 1408-1421

**Add closing thought**:

**Write here**:
```
**Closing Thought**:

[One sentence capturing the essence]
```

---

## 📝 Writing Priorities

**Start with these three HIGH PRIORITY sections** (your explicit requests):

1. ⭐ **Part 3, Section 3.2**: Authentication Method Conflicts (~300 words)
2. ⭐ **Part 5, Section 5.3**: Testing Explosion (~250 words)
3. ⭐ **Part 2, Section 2.3**: Field Value Claude Conversation (~250 words)

Then work through the rest in order or as inspiration strikes.

---

## 💡 Writing Tips

**For Claude Conversation Sections**:
- Use actual dialogue format when possible
- Show the back-and-forth
- Include what you learned or realized
- Make it feel authentic, not constructed

**For Technical Sections**:
- Lead with the problem
- Show the solution
- Explain why it works
- Keep code examples focused

**For Timeline/Journey Sections**:
- Be specific about dates/weeks
- Include estimates vs actual
- Show Claude's acceleration
- Keep it narrative, not just lists

**Voice/Tone**:
- Conversational but technical
- Honest about challenges
- Specific about Claude's role
- Clear about your judgment calls

---

**When you're done filling this out, you'll have ~4,900 words of authentic blog post content ready to assemble!**
