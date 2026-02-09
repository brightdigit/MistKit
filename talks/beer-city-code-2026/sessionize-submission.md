# Beer City Code 2026 - Server-Side CloudKit Submission

**Conference**: Beer City Code 2026
**Submission Deadline**: March 1, 2026
**Format**: Sessionize
**Talk Duration**: 50 minutes

---

## Session Title

CloudKit as Your Backend: From iOS to Server-Side Swift

---

## Description

You know CloudKit from iOS apps—how about backend services? CloudKit has excellent documentation for iOS development, but backend services using the Web Services APIs? Far less known.

I rebuilt MistKit, our CloudKit library, using AI-generated OpenAPI specifications. The result: 10,476 lines of type-safe Swift code supporting three authentication methods, nine HTTP status codes with typed error handling, and production use in Bushel (for syncing macOS/Swift/Xcode versions to CloudKit for the Bushel VM app) and Celestra (for syncing RSS feeds to CloudKit for the Celestra RSS reader).

This talk shares how to use CloudKit for server-side Swift with real production patterns:

**Three Authentication Methods:**
- API Token authentication (development/testing)
- Web Auth Token (user-specific operations)
- Server-to-Server authentication (autonomous backend services with key pairs)

**Type Safety with Dynamic Fields:**
- CloudKit fields are dynamically typed, Swift is statically typed
- Solving polymorphism with `oneOf`, discriminated unions, and type overrides
- Real example: CKRecordValue can be String, Int, Date, Asset, Reference, Location, or Array

**Production Error Handling:**
- CloudKit returns 9+ HTTP status codes with nested error details
- Building typed error hierarchies for resilience
- Retry logic for rate limits, conflict resolution, partial failures

**Ergonomic API Design:**
- Generated OpenAPI code is verbose and low-level
- Three-layer architecture: User API → MistKit abstraction → OpenAPI client
- Making CloudKit feel Swift-native from server-side code

Whether you're building data sync tools, RSS aggregators, or backend services, you'll leave with production patterns for using CloudKit beyond typical iOS client-side usage.

---

## Speaker Information

### Speaker Name
**First Name**: Leo
**Last Name**: Dion

### Speaker Tagline (200 characters max)
Creator of MistKit (210 stars), CloudKit backend library. Built production command-line tools: BushelCloud (syncs versions for Bushel VM), CelestraCloud (syncs RSS for Celestra reader). Host of EmpowerApps Podcast (203+ episodes).

### Speaker Email
leogdion+personal@brightdigit.com

### Speaker Biography

Leo Dion is the founder of BrightDigit, creator of MistKit (210 GitHub stars)—a modern Swift library for CloudKit's REST API. He rebuilt MistKit using AI-generated OpenAPI specifications, producing 10,476 lines of type-safe code supporting server-to-server authentication, polymorphic type handling, and production error patterns.

MistKit powers backend tools including BushelCloud (command-line tool for syncing macOS/Swift/Xcode versions to CloudKit for the Bushel VM app) and CelestraCloud (command-line tool for syncing RSS feeds to CloudKit for the Celestra RSS reader), demonstrating production CloudKit usage beyond typical iOS app scenarios.

Leo manages many Swift repositories including DataThespian (46 stars), PackageDSL (103 stars), and infrastructure tools like swift-build. He hosts the EmpowerApps Podcast (203+ episodes) featuring Apple platform developers.

His work spans AI-assisted development (generating 10,476 lines in 3 months), systematic automation (65-85% build time improvements), and production server-side Swift applications.

### Speaker Photo
**Status**: REQUIRED
**Requirements**: 1000x1000px minimum (square crop)
**File**: Professional headshot available (meets requirements)

### Speaker Links
- **X (Twitter)**: https://twitter.com/leogdion
- **LinkedIn**: https://www.linkedin.com/in/leogdion/
- **Company Website**: https://brightdigit.com
- **GitHub (BrightDigit)**: https://github.com/brightdigit
- **GitHub (Personal)**: https://github.com/leogdion
- **MistKit Repository**: https://github.com/brightdigit/MistKit
- **Podcast**: https://www.empowerapps.show

---

## Additional Conference-Specific Fields

### Track
Mobile

### Level
Intermediate

### Language
English

### Session Format
50-minute talk

### Tags
Swift, CloudKit, Server-Side Swift, Backend, REST API, Authentication, iOS, macOS, OpenAPI

### Learning Outcomes

Attendees will learn:

1. **Implement server-to-server CloudKit authentication**
   - Generate and securely store key pairs
   - Switch between development and production environments
   - Sign requests with proper token format
   - Handle authentication failures and token expiration
   - Use ClientMiddleware pattern for clean auth separation

2. **Solve CloudKit's type polymorphism in Swift**
   - Understand why CloudKit fields are dynamically typed
   - Use OpenAPI `oneOf` with discriminated unions
   - Implement custom type overrides for better ergonomics
   - Build type-safe record creation APIs
   - Handle runtime validation with clear error messages

3. **Implement production-grade error handling**
   - Handle all 9 CloudKit HTTP status codes appropriately
   - Build typed error hierarchies (not string throwing)
   - Implement retry logic for transient failures (429, 503)
   - Resolve conflicts for concurrent modifications (409)
   - Handle partial failures in batch operations
   - Generate user-friendly messages from CloudKit error codes

4. **Design ergonomic CloudKit APIs**
   - Understand three-layer architecture (generated → abstraction → user API)
   - Make verbose OpenAPI code feel Swift-native
   - Build intuitive record save/fetch/query interfaces
   - Hide low-level REST API details from users
   - Balance type safety with developer experience

5. **Choose when to use CloudKit for backend services**
   - Understand CloudKit strengths (Apple ecosystem integration, free tier)
   - Recognize CloudKit limitations (iOS/macOS focused, REST API constraints)
   - Compare CloudKit vs. Firebase vs. Vapor vs. other backends
   - Make informed decisions for specific use cases
   - Real examples: version data syncing (BushelCloud for Bushel VM), RSS feed syncing (CelestraCloud for Celestra reader)

---

## Commitment & Logistics

### Commitment
I agree to present this talk if accepted and understand the commitment required to deliver a high-quality session.

### Accommodation Needs
To be determined based on travel plans and hotel availability.

### Airfare Policy
I understand Beer City Code's airfare reimbursement policy and will coordinate travel arrangements accordingly.

---

## Why This Talk is Perfect for Beer City Code

### Technical Depth & Production Focus
Beer City Code emphasizes practical, production-ready content. This talk delivers:
- **Real command-line tools**: BushelCloud (syncs versions for Bushel VM), CelestraCloud (syncs RSS for Celestra reader)
- **10,476 lines of production code**: Not tutorials, actual working systems
- **Complete patterns**: Authentication → type safety → error handling → API design
- **Fills documentation gaps**: Apple's CloudKit server-side docs are sparse; this talk provides what's missing

### Mobile Track Fit
Perfect for the Mobile track:
- iOS/macOS backend services for Apple platform apps
- CloudKit integration from server perspective
- Production patterns for App Store apps needing backend processing
- Server-side Swift for mobile developers

### Intermediate Level Appropriate
- Requires Swift knowledge but not prior CloudKit server-side experience
- Accessible to iOS developers wanting backend capabilities
- Deep enough for teams building production CloudKit services
- Real-world complexity with practical solutions

### Unique Value
- **Fills critical gap**: Most CloudKit talks cover client-side iOS; this covers backend usage
- **Production patterns**: Real command-line tools in production (BushelCloud, CelestraCloud)
- **Documentation gaps**: Covers what Apple's sparse backend docs don't explain
- **Complete authentication coverage**: All three methods with production examples
- **Type safety approach**: Solving dynamic typing in statically-typed Swift
- **AI-assisted development angle**: Modern tooling for library development

### Complementary to Mobile Development
- Backend services power mobile apps
- CloudKit integration from both sides (client + server)
- Real use cases: podcast apps, RSS readers, data sync services
- Practical for developers wearing both hats (iOS app + backend)

---

## Resources Available Post-Talk

- MistKit: github.com/brightdigit/MistKit
- OpenAPI specifications (available in repo)
- Production command-line tools: BushelCloud, CelestraCloud
- Blog series: brightdigit.com/tutorials
- Complete authentication guide
- Error handling patterns
- Slides and code examples
