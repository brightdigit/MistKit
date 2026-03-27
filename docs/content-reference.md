# Server-Side CloudKit: Content Reference

Key points, narrative, and technical content for creating talks, workshops, blog posts, videos, and social media posts about MistKit and server-side CloudKit.

---

## 1. Core Narrative & Hook

**Opening hook** (works for talks, videos, threads):
> "Raise your hand if you've used CloudKit from an iOS app. Keep it up if you've used CloudKit from a backend service. Yeah, that's the problem."

**The problem**: CloudKit server-side is Apple's worst-documented feature. 2016-era docs. Auth barely explained. No error handling examples. Type system challenges unaddressed. Stack Overflow full of unanswered questions.

**The solution story**: Built two production backends (BushelCloud + CelestraCloud) that required solving all of this. Then rebuilt MistKit from scratch using AI-generated OpenAPI specs to give others the patterns Apple didn't document.

**Key insight on AI**: AI excels at documentation→OpenAPI spec translation. Human expertise required for architecture, error patterns, and API design.

---

## 2. Three Authentication Methods

| Method | Use Case | Status |
|---|---|---|
| **API Token** | Dev/debug only, Dashboard-generated | Never production |
| **Web Auth Token** | User-specific backend ops, token passed from iOS app | Completely undocumented by Apple |
| **Server-to-Server** | Autonomous services, cron jobs, CLIs | Primary focus |

### Server-to-Server (Primary Focus)

**What Apple's docs cover**: Key pair generation, basic signing concept.

**What they don't cover**:
- Exactly what to sign: ISO8601 timestamp + request path + body hash (SHA-256)
- How to sign: ECDSA with P-256 curve
- Where to put it: `X-Apple-CloudKit-Request-SignatureV1` header
- The full token format
- Environment switching between dev and production containers
- Key lifecycle management and rotation

**`ClientMiddleware` pattern**: Separates auth from business logic. Testable (swap mock auth in tests). Reusable across operations. Production-ready.

---

## 3. Type System Polymorphism

**The problem**: CloudKit fields are runtime-dynamic JSON. Swift is statically typed. Mismatch.

```json
{ "value": "Hello" }        // String
{ "value": 42 }             // Int
{ "value": "2026-07-01" }   // Date (ISO8601 string)
{ "value": {...} }          // Asset, Reference, Location
{ "value": [...] }          // Array of any above
```

**The solution**: OpenAPI `oneOf` discriminated unions → Swift enum with associated values:

```swift
enum CKRecordValue {
    case string(String)
    case int64(Int64)
    case double(Double)
    case date(Date)
    case bytes(Data)
    case reference(CKRecordReference)
    case asset(CKAsset)
    case location(CKLocation)
    case list([CKRecordValue])
}
```

Custom type overrides in `openapi-generator-config.yaml` improve ergonomics. Compiler catches type errors at build time — not runtime surprises.

**Real example**: RSS article record — `title` (`.string`), `url` (`.string`), `publishDate` (`.date`), `unread` (`.int64`).

---

## 4. Production Error Handling

CloudKit returns 9 HTTP status codes, each requiring specific handling:

| Code | Meaning | Strategy |
|---|---|---|
| 200 | Success | — |
| 400 | Bad Request (malformed data) | Fix request, don't retry |
| 401 | Unauthorized (bad signature, expired token) | Refresh auth, retry |
| 404 | Not Found | Handle missing record |
| 409 | Conflict (concurrent modification) | Merge + retry |
| 412 | Precondition Failed | Conditional save failed |
| 421 | Misdirected Request (wrong container) | Fix configuration |
| 429 | Too Many Requests | Exponential backoff |
| 503 | Service Unavailable | Exponential backoff |

Each error carries nested JSON: `ckErrorCode`, `serverRecord` (on 409), `reason`.

**Retry logic**:
- **429**: Exponential backoff — 1s, 2s, 4s, 8s, 16s. Respect `retryAfter` header.
- **409**: Receive `serverRecord` in error body. Merge strategies: last-write-wins, field-level merge, or custom business logic. Re-sign and retry.
- **503**: Exponential backoff, max 3-5 attempts.
- **401**: Refresh auth credentials, retry.

**Typed error hierarchy**: `enum CloudKitError` with associated values — not string throwing. Enables pattern matching for specific recovery.

**Partial failures**: Batch operations can have mixed success/failure per record. Handle per-record, not all-or-nothing.

**Real example**: CelestraCloud — RSS sync every 15 minutes. Concurrent updates from multiple devices + aggressive CloudKit rate limiting. Both 409 and 429 handling are non-optional.

---

## 5. API Ergonomics: Three-Layer Architecture

**Problem**: OpenAPI-generated code is verbose and low-level.

```swift
// 40+ lines of this:
let request = Operations.SaveRecordsRequest(
    path: .init(databaseScope: "public", containerIdentifier: "iCloud.com.example.app"),
    body: .json(.init(operations: [.init(operationType: "create", record: .init(...))]))
)
```

**Three layers**:

| Layer | Responsibility |
|---|---|
| **Generated client** (Layer 1) | Auto-generated from OpenAPI spec. Never edit. Low-level REST. |
| **MistKit abstraction** (Layer 2) | Auth middleware, retry logic, error handling, response unwrapping, domain type conversion |
| **User-facing API** (Layer 3) | Swift-native, intuitive, feels like native CloudKit framework |

**After all three layers**:
```swift
try await database.save(record)  // 5 lines, type-safe, production-ready
```

---

## 6. Production Examples

| App | Purpose | Auth | Real Challenges |
|---|---|---|---|
| BushelCloud | Syncs macOS/Swift/Xcode version data for Bushel VM | Server-to-server | Concurrent updates from multiple version sources |
| CelestraCloud | Syncs RSS feeds for Celestra RSS reader | Server-to-server | 15-min polling, aggressive rate limiting, conflict resolution |

**Stats for credibility**:
- **MistKit**: 10,476 lines of type-safe Swift, 210 GitHub stars, 161 tests, 47 test files
- Built in 3 months using AI-assisted OpenAPI generation (vs. 6-12 months estimated manual work)
- **BushelCloud**: 179 files changed, 33,032 additions, 137 passing tests (Jan 8, 2026)
- **CelestraCloud**: 105 files changed, 23,534 additions (Jan 6, 2026)

---

## 7. Learning Outcomes

Audience leaves able to:
1. Implement server-to-server CloudKit auth — key pairs, request signing, environment switching
2. Design type-safe APIs for CloudKit's dynamic fields using OpenAPI discriminated unions
3. Handle all 9 CloudKit HTTP status codes with appropriate retry logic
4. Build the three-layer architecture to make generated code feel Swift-native
5. Decide when CloudKit is the right backend vs. Vapor, Firebase, or Supabase

---

## 8. Format Adaptations

| Format | Focus | Length |
|---|---|---|
| Social media post | Hook + one insight (auth gap, type safety, one error code) | Short |
| Blog post | One section deep-dive with real code | 2,000–3,000 words |
| 30-min talk | Auth + type system + error handling (skip rebuild story) | ~25 min content |
| 45-min talk | All 5 acts, moderate detail | ~38 min content |
| 60-min talk | All 5 acts, full examples + live demo | ~50 min content |
| Workshop | Attendees build a CloudKit backend service hands-on | 2–3 hours |

**Talk act structure** (scale up or down):
1. **Documentation Gap** — hook, show of hands, establish the problem
2. **The Rebuild Story** — MistKit + AI + OpenAPI (skip for short formats)
3. **Server-to-Server Auth** — the deep dive, live demo here
4. **Type System + Error Handling** — two sub-acts, combinable
5. **API Ergonomics** — before/after, three-layer payoff

---

## 9. When to Use CloudKit

**Use CloudKit when**:
- Building backend for an iOS/macOS app
- Data sync for indie/small team
- Zero server management preferred
- Already in the Apple ecosystem

**Consider alternatives when**:
- Android support needed → Firebase
- Complex relational queries → PostgreSQL/Supabase
- Real-time updates → Firebase
- Full backend control → Vapor/Hummingbird

**Reality check**: CloudKit's "free" tier has limits. Rate limiting (429) is real at scale. Factor in discovery time for undocumented auth patterns.

---

## 10. Memorable Phrases

- *"Apple's worst-documented feature"* — server-to-server authentication
- *"The patterns Apple's documentation doesn't cover"*
- *"AI excels at docs→spec translation; humans needed for architecture"*
- *"Compiler catches type errors, not runtime surprises"*
- *"Zero overlap, complete coverage"* — useful when pairing with a client-side CloudKit talk

---

## Accepted Talks (2026)

- **Swift Craft 2026** — June 2026 (60 min)
- **Swift Rockies 2026** — Calgary, AB, July 2026 (45 min)
- **iOSDevUK 2026** — Aberystwyth, Wales, Sept 7–10, 2026 (30 min)

Prep materials (outline, demo script): [prep/](prep/)
