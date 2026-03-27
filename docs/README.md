# MistKit Content & Talks

This directory contains educational content, conference materials, and articles about [MistKit](../README.md) and server-side CloudKit — an ongoing series covering what Apple's documentation leaves out.

## What This Is About

CloudKit Web Services is a REST API that works on any platform: server-side Swift, Linux, Android, Windows — not just Apple devices. Most developers don't know this, and Apple's documentation for server-to-server authentication is famously incomplete.

This content series covers the patterns that two production backends (BushelCloud and CelestraCloud) required to get right.

## Core Themes

| Theme | What It Covers |
|---|---|
| **Server-to-Server Auth** | Key pair generation, ECDSA request signing, credential lifecycle, what Apple's docs omit |
| **Type Safety** | CloudKit's dynamic fields vs. Swift's static types — discriminated unions, OpenAPI `oneOf` |
| **Error Handling** | 9 HTTP status codes, retry logic, exponential backoff, conflict resolution |
| **API Ergonomics** | Three-layer architecture: generated OpenAPI → abstraction → user-facing Swift API |

## Accepted Conference Talks (2026)

| Conference | Location | Date | Materials |
|---|---|---|---|
| Swift Craft 2026 | — | June 2026 | [Submission](conferences/swift-craft-2026/) |
| Swift Rockies 2026 | Calgary, AB | July 2026 | [Submission](conferences/swift-rockies-2026/) |
| iOSDevUK 2026 | Aberystwyth, Wales | Sept 7–10, 2026 | [Submission](conferences/iosdevuk-2026/) |

## Directory Structure

```
docs/
├── conferences/     # Accepted CFP submissions and talk materials
├── articles/        # Blog posts and written content in progress
├── prep/            # Talk outline and demo script
└── marketing/       # Promotion, content strategy, consulting
```

## Related

- [MistKit source code](../Sources/MistKit/)
- [MistDemo example app](../Examples/MistDemo/)
- [OpenAPI specification](../openapi.yaml)
