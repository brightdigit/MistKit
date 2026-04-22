---
title: Rebuilding MistKit with Claude Code - Real-World Lessons and Collaboration Patterns (Part 2)
date: 2025-12-10 00:00
description: After building MistKit's type-safe CloudKit client, we put it to the test with real applications. Discover what happened when theory met practice—the unexpected discoveries, hard-earned lessons, and collaboration patterns that emerged from 428 Claude Code sessions over three months.
featuredImage: /media/tutorials/rebuilding-mistkit-claude-code/mistkit-rebuild-part1-hero.webp
subscriptionCTA: Want to learn more about AI-assisted Swift development and modern API design patterns? Sign up for our newsletter to get notified about the rest of the Modern Swift Patterns series and future tutorials on building production-ready Swift applications.
---

In [Part 1](https://brightdigit.com/tutorials/rebuilding-mistkit-claude-code-part-1/), I showed how [Claude Code](https://claude.ai/claude-code) and [swift-openapi-generator](https://github.com/apple/swift-openapi-generator) transformed [CloudKit's REST documentation](https://developer.apple.com/documentation/cloudkitjs/cloudkit/cloudkit_web_services) into a type-safe Swift client. We had 161 unit tests which passed, but would it actually work in the real world?

📚 **[View Documentation](https://swiftpackageindex.com/brightdigit/MistKit/documentation)** | 🐙 **[GitHub Repository](https://github.com/brightdigit/MistKit)**

- [Real-World Proof](#real-world-proof)
    - [The Celestra and Bushel Examples](#the-celestra-and-bushel-examples)
    - [Integration Testing Through Real Applications](#integration-testing-through-real-applications)
- [Lessons Learned](#lessons-learned)
    - [Unit Test Generation](#unit-test-generation)
    - [Human Guided Architecture](#human-guided-architecture)
    - [Grabby AI](#grabby-ai)
    - [Context Management](#context-management)
    - [Human + AI Code Reviews](#human--ai-code-reviews)
- [Multiplier, not a Replacement](#multiplier-not-a-replacement)

<a id="real-world-proof"></a>
## Real-World Proof

Would MistKit's abstractions actually work when building an application? I had 2 real-world applications for MistKit to try it out:

- an RSS aggregator syncing thousands of articles to CloudKit using [SyndiKit](https://github.com/brightdigit/SyndiKit) for an app codenamed **[Celestra](https://celestr.app)**
- For **[Bushel](https://getbushel.app)**, I wanted to track restore images and various metadata for macOS and developer software versions. 


<a id="the-celestra-and-bushel-examples"></a>
### The Celestra and Bushel Examples

Tests validate correctness, but real applications validate design. MistKit needed to prove it could power actual software and not just pass unit tests. Enter two real-world applications—**[the Celestra app](https://celestr.app)** (an RSS reader) and **[the Bushel app](https://getbushel.app)** (a macOS virtualization tool)—each powered by MistKit-driven CLI backends that populate CloudKit public databases. These CLI tools, running on scheduled cloud infrastructure, proved MistKit works in production.

The architecture for both follows the same pattern:
- **Consumer apps** ([the Celestra app](https://celestr.app), [the Bushel app](https://getbushel.app)) - iOS/macOS apps that read from CloudKit
- **CLI tools** - Built with MistKit, run on cloud infrastructure (cron jobs, cloud functions, scheduled tasks)
- **CloudKit public database** - Central data layer connecting CLI tools to apps

This pattern enables:
- **Automated updates**: CLI tools run on schedules without user devices being online
- **Separation of concerns**: Data population (CLI) vs data consumption (app)
- **Scalability**: Cloud infrastructure handles data aggregation, apps stay lightweight

#### Celestra: Automated RSS Feed Sync for a Reader App

The [Celestra app](https://celestr.app) is an RSS reader in development for iOS and macOS. To keep content fresh without requiring the app to be open, I built a [CLI tool with MistKit](https://github.com/brightdigit/MistKit/tree/main/Examples/Celestra) that runs on scheduled cloud infrastructure. The CLI tool runs periodically (cron job, cloud function, scheduled task) to fetch RSS feeds and sync them to CloudKit's public database, making fresh content available to all users instantly—even when their devices are offline.

This architecture enables push notifications on updated articles without the app running, and MistKit's batch operations can efficiently handle hundreds of content updates. The [CLI tool example](https://github.com/brightdigit/MistKit/tree/main/Examples/Celestra) demonstrates key MistKit patterns:

**Query filtering** - Find feeds that need updating:
```swift
// Query filtering - find stale feeds
QueryFilter.lessThan("lastAttempted", .date(cutoff))
QueryFilter.greaterThanOrEquals("usageCount", .int64(minPop))
```

**Batch operations** - Efficiently sync hundreds of articles:
```swift
// Batch operations
let operations = articles.map { article in
    RecordOperation.create(
        recordType: "Article",
        recordName: article.guid,
        fields: article.toCloudKitFields()
    )
}
service.modifyRecords(operations, atomic: false)
```

#### Bushel: Powering a macOS VM App with CloudKit

The [Bushel app](https://getbushel.app) is a macOS virtualization tool for developers. It currently allows pluggable _hubs_ to get a list of restore images, their download URLs, and their status. However, since the data is universal, I wanted a comprehensive, queryable central database of macOS restore images and various metadata about operating system versions and developer tools. Therefore I wanted a [CLI tool with MistKit](https://github.com/brightdigit/MistKit/tree/main/Examples/Bushel) that runs on scheduled cloud infrastructure (cron jobs, cloud functions, scheduled tasks) to populate a CloudKit public database with various metadata about macOS versions and their restore images.

This architecture provides:
- **Public Database**: Worldwide access to version history without embedding static JSON in the app
- **Automated Updates**: CLI tool syncs latest info on restore images, Xcode, and Swift versions
- **Queryable**: [Bushel app](https://getbushel.app) can easily query for restore images such as _macOS 15.2_
- **Scalable**: CLI tool aggregates data from various sources automatically
- **Deduplication**: buildNumber-based deduplication ensures clean data

The [CLI tool example](https://github.com/brightdigit/MistKit/tree/main/Examples/Bushel) demonstrates advanced MistKit patterns:

```swift
// Protocol-based record conversion
protocol CloudKitRecord {
    static var cloudKitRecordType: String { get }
    func toCloudKitFields() -> [String: FieldValue]
}

// Relationship handling
fields["minimumMacOS"] = .reference(
    FieldValue.Reference(recordName: restoreImageRecordName)
)
```

---

> transistor https://share.transistor.fm/s/ffcb9fc1

Both CLI tool examples serve as copy-paste starting points for new MistKit projects.
<!-- END ORIGINAL [CONTENT] -->

Watching MistKit power real applications was satisfying—I could see the generated code actually work in production. The CLI tools successfully synced RSS articles (Celestra) and tracked complex version relationships (Bushel). But more importantly, these real-world applications revealed critical issues that no unit test could catch.

<a id="integration-testing-through-real-applications"></a>
### Integration Testing Through Real Applications

Building real applications exposed issues no unit test could catch. Here's what Celestra and Bushel revealed:

- **Batch Operation Limits**: CloudKit enforces 200-operation-per-request limit (not documented clearly) therefore we added chunking logic.
- **Boolean Field Handling**: CloudKit has no native boolean type but we wanted the developer to safely use Swift Boolean types so we created a safe and easy way to use the standardized INT64 representation.

I was able to verify that the API design and critical pieces like Server-to-Server authentication were working as intended. These real-world tests validated MistKit's foundation.


<a id="lessons-learned"></a>
## Lessons Learned

There were few things which surprised me as far as what Claude Code was good and not good at and where [collaboration worked best](https://brightdigit.com/tutorials/syntaxkit-swift-code-generation/). Claude excelled at tasks I thought would be hard (comprehensive test generation). It struggled with things I assumed would be easy (knowing which APIs exist). Through iteration, a collaboration pattern emerged. Here's what I learned.

### Unit Test Generation

Test generation proved to be Claude Code's greatest strength, and it's ideal for LLMs because it leverages pattern recognition from vast training data. Claude has seen thousands of Swift test files and can apply those structural patterns to new domains. The task requires extrapolation from examples, not novel reasoning—Claude recognizes "if testing STRING type, also test empty string, Unicode, and nil" because that pattern appears frequently in its training corpus. A typical interaction looked like this:

```no-highlight
Me: "Generate tests for all CustomFieldValue types"

Claude: *[Creates tests covering all 10 field types with edge cases]*
"I've generated comprehensive tests covering:
 - All 10 field types (STRING, INT64, DOUBLE, TIMESTAMP, BYTES, REFERENCE, ASSET, ASSETID, LOCATION, LIST)
 - Edge cases: empty lists, nil values, malformed data
 - Encoding/decoding round-trips
 - Nested LIST types
 - Invalid type/value combinations

 I also added tests for the ASSET vs ASSETID quirk"
```

It was able to produce 161 tests across 47 files including edge cases I hadn't considered. The only quirk I found was that it favored [XCTest](https://developer.apple.com/documentation/xctest) over [Swift Testing](https://developer.apple.com/documentation/testing) at first. This makes sense since there's probably more training material in XCTest. I've primarily switched to Swift Testing for my new work. If you are in the same place then be sure to make a note of that in your `CLAUDE.md` when you start your project. 

### Human Guided Architecture

While Claude excelled at pattern-based tasks, architectural decisions consistently required human judgment. At various points, Claude would steer the architecture in strange directions that didn't seem correct. The issue is that its training is best for smaller contexts and code examples, which isn't enough for holistic system design. Be confident in steering Claude in the right direction—this is where developer expertise matters most. The risk is drift if the pattern isn't perfectly specified, but for well-defined transformations, LLMs excel. Luckily, Claude does a fairly good job at refactoring when corrected, and its context window (200K tokens in Sonnet 4.5) allows it to see multiple files simultaneously and apply consistent transformations across the codebase.

### Grabby AI

These limitations manifested in predictable patterns throughout the project. As we were implementing the CLI tools for Bushel and Celestra, Claude would often try to implement features using the direct [OpenAPI](https://www.openapis.org/) code as opposed to the abstracted API we had built:

```swift
// WRONG: Internal type reference
let operation = Components.Schemas.RecordOperation(
    recordType: "RestoreImage",
    fields: fields
)
```

Even going so far as to make those methods and properties `public`. Often referred to as power-grabbing, it would go outside its designated boundary, even though I would tell it often not to use those APIs. It's important to set those constraints clearly within the context window and review the code intentionally. All mistakes share common traits—Claude follows patterns from training data or generated code literally without questioning ergonomics or existence. The fix is always the same: explicit guidance in prompts and immediate verification of suggestions.

### Context Management

Managing these challenges required strategic context management. One of the biggest challenges working with Claude Code is managing its knowledge cutoffs and lack of familiarity with newer or niche APIs. In the world of Swift, Claude's training often predates [Swift Testing](https://developer.apple.com/documentation/testing) or [swift-openapi-generator](https://github.com/apple/swift-openapi-generator) specifics. This is where providing documentation upfront in `.claude/docs/` helps. With tools like [Sosumi.ai](https://sosumi.ai) for Apple API exploration and [llm.codes](https://llm.codes) I can provide documentation like:
- `testing-enablinganddisabling.md` (126KB) - Swift Testing patterns
- `webservices.md` (289KB) - CloudKit Web Services REST API reference
- `cloudkitjs.md` (188KB) - CloudKit operation patterns and data types
- `swift-openapi-generator.md` (235KB) - Code generation configuration

> youtube https://youtu.be/gH3QnVHsUAc

At the root of this is the `CLAUDE.md` file which acts as a table of contents, telling Claude where to look for specific information. Claude doesn't need to memorize everything—it needs to know where to look.

### Human + AI Code Reviews

Whatever your AI writes should be understood by you fairly well. Don't skip this step. This is especially important in the context of [humane code](https://brightdigit.com/articles/humane-code/)—code that is empathetic to future developers who need to understand and maintain it. AI-generated code still needs to communicate clearly with the humans who will work with it later.

> transistor https://share.transistor.fm/s/99f236b1

These patterns and practices reflect a deeper truth about AI-assisted development: Claude Code is a force multiplier, not a replacement for developer judgment. I provided architectural vision; Claude generated comprehensive implementations. I identified edge cases from domain knowledge; Claude translated them into exhaustive test suites. I steered strategic decisions; Claude handled mechanical transformations at scale. Together, we built something neither could have built alone—a production-ready CloudKit client that balances type safety with developer ergonomics.

<a id="multiplier-not-a-replacement"></a>
## Multiplier, not a Replacement

These lessons crystallized into a philosophy: **AI is a force multiplier, not a replacement**. Claude generated thousands of lines of code, but I architected what those lines should accomplish. It drafted comprehensive tests, but I knew which edge cases mattered. It refactored at scale, but I chose the patterns worth preserving. Where I lacked expertise translating CloudKit's REST API into an OpenAPI spec, Claude filled those gaps.

The proof came from real-world application. Building **Celestra** and **Bushel** validated MistKit's design beyond what unit tests could achieve. The CLI tools exposed batch operation limits, revealed boolean field handling quirks, and confirmed that Server-to-Server authentication worked in production. These discoveries transformed MistKit from a technically correct library into a production-ready tool.

Both CLI examples are now open source as starting points for new projects:
- [Bushel CLI Example](https://github.com/brightdigit/MistKit/tree/main/Examples/Bushel) - Demonstrates complex CloudKit relationships and batch operations powering the [Bushel app](https://getbushel.app)
- [Celestra CLI Example](https://github.com/brightdigit/MistKit/tree/main/Examples/Celestra) - Demonstrates public database patterns and automated sync for the [Celestra app](https://celestr.app)

Through 428 sessions across three months, Claude Code and I built MistKit v1.0 Alpha—a type-safe CloudKit client that proves AI-assisted development can deliver production-quality Swift libraries when human judgment guides the process.

