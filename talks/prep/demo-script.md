# Demo Script: MistKit Server-to-Server Authentication

> Used during Act 3 of the CloudKit talk (live code or pre-recorded)
> Target duration: 5-7 minutes

---

## Setup

**Prerequisites:**
- Xcode with MistKit package added
- Apple Developer account with CloudKit container configured
- Server-to-server key pair (generated in CloudKit Dashboard)

**Demo project:** A minimal Swift command-line tool that authenticates with CloudKit and performs a simple query.

---

## Step 1: Key Pair Generation (1 min)

Show the CloudKit Dashboard flow:
1. Navigate to CloudKit Dashboard → your container → Server-to-Server Keys
2. Generate a new key pair
3. Download the private key (`.pem` file)
4. Note the key ID

**Talking point:** "Apple gives you a `.pem` file and a key ID. What they don't tell you is how to actually use these to sign requests."

---

## Step 2: Request Signing Implementation (2 min)

Walk through the MistKit authentication code:

```swift
// Show how MistKit handles the signing process
// 1. Load the private key
// 2. Create the signing payload (date + body + path)
// 3. Sign with ECDSA
// 4. Attach to request headers
```

**Key points to highlight:**
- The signing payload format (Apple's docs are vague on this)
- ECDSA signature generation
- Header format (`X-Apple-CloudKit-Request-KeyID`, `X-Apple-CloudKit-Request-ISO8601Date`, `X-Apple-CloudKit-Request-SignedMessage`)

**Talking point:** "This is the part where most developers give up. The signing format isn't documented clearly, and getting any part wrong gives you a generic 401."

---

## Step 3: Environment Switching (1 min)

Demonstrate switching between development and production:

```swift
// Show environment configuration
// - Development: ckc-development container
// - Production: ckc-production container
// - How MistKit handles the switch
```

**Talking point:** "In development, you'll get helpful error messages. In production, you get... less help. Test everything in development first."

---

## Step 4: Error Handling Demonstration (1.5 min)

Trigger and handle common errors:

1. **401 Unauthorized** — Invalid key or signature
2. **404 Not Found** — Wrong record type or zone
3. **409 Conflict** — Concurrent modification

```swift
// Show typed error handling
// - How MistKit maps HTTP status codes to Swift errors
// - Retry logic with exponential backoff
// - Conflict resolution strategy
```

**Talking point:** "9 different HTTP status codes, each with its own recovery strategy. MistKit gives you typed errors instead of raw status codes."

---

## Step 5: Live Query Example (1.5 min)

Execute a working query:

```swift
// Perform a simple record query
// - Show the request being signed
// - Show the response being decoded
// - Show type-safe field access
```

**Expected output:** Display query results with proper type handling.

**Talking point:** "From zero documentation to type-safe queries in 10,476 lines of Swift. That's what production-ready CloudKit looks like."

---

## Fallback Plan

If live coding fails:
- Switch to pre-recorded video of the same demo
- Have terminal output screenshots as static slides
- Key code snippets already embedded in slide deck

---

## Demo Environment Checklist

- [ ] MistKit demo project builds and runs
- [ ] CloudKit container has test data
- [ ] Private key file accessible
- [ ] Internet connection verified (CloudKit needs network)
- [ ] Pre-recorded backup video ready
- [ ] Terminal font size increased for projector visibility
