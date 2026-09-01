# Documentation

## Guides & talk material

- **[cloudkit-guide/](cloudkit-guide/)** — Content reference, talk prep, and marketing materials for the server-side CloudKit speaking series
- **[why-mistkit.md](why-mistkit.md)** — Use-case catalog of server-side CloudKit patterns (public database, private database, web app bridge, data aggregation)
- **[video-outline.md](video-outline.md)** — Working outline for the recorded talk, with author/beginner Q&A threaded through
- **[talk-feedback.md](talk-feedback.md)** — Notes from the 2026-05-05 dry run: what works, what to cut, likely Q&A

## Retrospectives

- **[what-cloudkit-got-wrong.md](what-cloudkit-got-wrong.md)** — Where CloudKit Web Services itself was hard: authentication, field types, and Apple's documentation disagreeing with Apple's server
- **[what-the-ai-got-wrong.md](what-the-ai-got-wrong.md)** — Evidence-backed catalogue of recurring AI failure modes while building MistKit

## Internals

- **[internals/authentication-middleware.md](internals/authentication-middleware.md)** — Token managers, authenticators, and how every request gets signed
- **[internals/field-type-polymorphism.md](internals/field-type-polymorphism.md)** — The three-layer `FieldValue` type system and the request/response asymmetry
- **[internals/error-code-parsing.md](internals/error-code-parsing.md)** — Turning CloudKit's HTTP error responses into typed Swift errors
