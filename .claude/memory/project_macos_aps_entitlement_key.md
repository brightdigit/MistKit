---
name: macos-aps-entitlement-key
description: "macOS push entitlement key differs from iOS — use com.apple.developer.aps-environment on macOS, aps-environment on iOS/tvOS"
metadata: 
  node_type: memory
  type: project
  originSessionId: 546d07b2-2fcf-42f0-914c-5da171098418
---

macOS apps need `com.apple.developer.aps-environment` in the entitlements file. iOS/tvOS use the unprefixed `aps-environment`. The macOS provisioning profile grants the prefixed form; if the `.entitlements` file only has the unprefixed key, codesign **silently strips** the entitlement from the signed binary (no build error), and APNs registration fails at runtime with NSError `"Application not properly entitled for push notifications."`

**Why:** Diagnosed in MistDemo (`Examples/MistDemo/MistDemoApp.entitlements`) on 2026-05-19. The signed `.app` had iCloud + sandbox but no aps key at all, while the embedded `.provisionprofile` clearly granted `com.apple.developer.aps-environment` — proving codesign stripped the iOS-style key because it didn't match the macOS profile grant. Took multiple hops (signing/profile diagnosis, capability declaration attempt) to spot the key-name mismatch.

**How to apply:** When sharing a single `.entitlements` file across iOS + macOS targets, include **both** keys — they coexist and each platform reads the one it expects. Watch for this in any cross-platform SwiftUI app where APNs registration fails despite the dev portal having Push enabled and the embedded profile looking correct.
