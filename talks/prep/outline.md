# CloudKit as Your Backend: From iOS to Server-Side Swift
## Presentation Outline — 60 Minutes (Swift Craft, May 18-19)

> Based on [swift-craft-2026/cloudkit-talk-submission.md](../swift-craft-2026/cloudkit-talk-submission.md)
> Adaptable to 45-min (Swift Rockies, iOSDevUK) by trimming Acts 4-5 and Q&A

---

## Act 1: The Documentation Gap (6 min)

**Goal:** Establish the problem — Apple's CloudKit server-to-server docs are insufficient for production use.

| Slide | Content | Duration |
|---|---|---|
| 1 | Title slide + intro | 1 min |
| 2 | "What CloudKit promises" — iCloud sync, zero backend, Apple handles infrastructure | 1.5 min |
| 3 | "What happens when you need a server" — the documentation gap | 1.5 min |
| 4 | Two production examples: podcast aggregator (BushelCloud) + RSS reader (CelestraCloud) — what we needed vs. what Apple provided | 2 min |

**Key message:** Apple documents the happy path. Production needs the rest.

---

## Act 2: The Rebuild — OpenAPI + AI (8 min)

**Goal:** Show how MistKit was rebuilt using OpenAPI spec generation and AI assistance.

| Slide | Content | Duration |
|---|---|---|
| 5 | MistKit history: original library → why a rebuild was needed | 2 min |
| 6 | OpenAPI approach: spec-driven development with swift-openapi-generator | 2 min |
| 7 | AI-assisted rebuild: how Claude Code helped generate 10,476 lines of type-safe code | 2 min |
| 8 | The result: 161 tests, full type safety, production-ready | 2 min |

**Key message:** Modern tooling (OpenAPI + AI) can make CloudKit's complexity manageable.

---

## Act 3: Server-to-Server Authentication (10 min)

**Goal:** Walk through the authentication implementation that Apple barely documents.

| Slide | Content | Duration |
|---|---|---|
| 9 | Authentication overview: what Apple tells you vs. what you need | 2 min |
| 10 | Key pair generation — step by step | 2 min |
| 11 | **LIVE CODE:** Request signing implementation | 3 min |
| 12 | Environment switching (development → production) | 1.5 min |
| 13 | Common pitfalls and debugging auth failures | 1.5 min |

**Transition to demo:** "Let me show you this working..."

**Demo:** → See [demo-script.md](demo-script.md) for MistKit auth walkthrough

---

## Act 4: Type Polymorphism & Error Handling (15 min)

**Goal:** Deep dive into making CloudKit's dynamic type system safe in Swift.

| Slide | Content | Duration |
|---|---|---|
| 14 | The problem: CloudKit fields are dynamically typed | 2 min |
| 15 | OpenAPI discriminated unions for type safety | 2 min |
| 16 | **CODE DEMO:** Type-safe record field access | 3 min |
| 17 | Error handling overview: 9 HTTP status codes | 2 min |
| 18 | **CODE DEMO:** Typed error responses with retry logic | 3 min |
| 19 | Conflict resolution with exponential backoff (CelestraCloud patterns) | 2 min |
| 20 | Production error handling: what we learned from real deployments | 1 min |

**Key message:** Type safety isn't optional when your backend talks to CloudKit.

---

## Act 5: API Ergonomics (7 min)

**Goal:** Show the three-layer architecture that makes OpenAPI-generated code feel Swift-native.

| Slide | Content | Duration |
|---|---|---|
| 21 | The three-layer architecture: Generated → Abstraction → User API | 2 min |
| 22 | Layer 1: Raw OpenAPI-generated code (what you get) | 1.5 min |
| 23 | Layer 2: Abstraction layer (Swift idioms, error mapping) | 1.5 min |
| 24 | Layer 3: User-facing API (what developers actually call) | 2 min |

**Key message:** Good API design bridges the gap between generated code and developer experience.

---

## Closing + Q&A (14 min)

| Slide | Content | Duration |
|---|---|---|
| 25 | When to use CloudKit as your backend (decision framework) | 2 min |
| 26 | Resources: MistKit repo, blog articles, related talks | 2 min |
| 27 | Q&A | 10 min |

---

## Adaptation Notes

### For Swift Rockies (45 min)
- Compress Acts 1-2 to 10 min combined
- Trim Act 4 code demos (show pre-recorded instead of live)
- Reduce Q&A to 5 min

### For iOSDevUK (45 min)
- Same timing as Swift Rockies
- Adjust tone for first-time speaker emphasis
- More beginner-friendly framing of authentication concepts

---

## Materials Needed

- [ ] Slide deck (Keynote or Deckset)
- [ ] MistKit demo project (clean, working state)
- [ ] Pre-recorded demo backup (in case of live coding issues)
- [ ] Production screenshots from BushelCloud & CelestraCloud (anonymized)
- [ ] Code snippets for slides (syntax highlighted)
