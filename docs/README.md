# MistKit Content & Talks

This directory contains educational content, reference material, and articles about [MistKit](../README.md) and server-side CloudKit — an ongoing series covering what Apple's documentation leaves out.

## What This Is About

CloudKit Web Services is a REST API that works on any platform: server-side Swift, Linux, Android, Windows — not just Apple devices. Most developers don't know this, and Apple's documentation for server-to-server authentication is famously incomplete.

This content series covers the patterns that two production backends (BushelCloud and CelestraCloud) required to get right.

## Start Here

**[talk-prep.md](talk-prep.md)** — Key points, narrative, technical topics, talk structure, and demo guide. Use this when creating any derived content: talks, workshops, blog posts, videos, or social media posts.

## Core Themes

| Theme | What It Covers |
|---|---|
| **Server-to-Server Auth** | Key pair generation, ECDSA request signing, credential lifecycle, what Apple's docs omit |
| **Type Safety** | CloudKit's dynamic fields vs. Swift's static types — discriminated unions, OpenAPI `oneOf` |
| **Error Handling** | 9 HTTP status codes, retry logic, exponential backoff, conflict resolution |
| **API Ergonomics** | Three-layer architecture: generated OpenAPI → abstraction → user-facing Swift API |

## Accepted Talks (2026)

- **Swift Craft 2026** — June 2026 (60 min)
- **Swift Rockies 2026** — Calgary, AB, July 2026 (45 min)
- **iOSDevUK 2026** — Aberystwyth, Wales, Sept 7–10, 2026 (30 min)

## Directory Structure

```
docs/
├── talk-prep.md   # Key points, narrative, talk structure, and demo guide
├── articles/      # Blog posts and written content in progress
└── marketing/     # Promotion, content strategy, consulting
```

## Related

- [MistKit source code](../Sources/MistKit/)
- [MistDemo example app](../Examples/MistDemo/)
- [OpenAPI specification](../openapi.yaml)
