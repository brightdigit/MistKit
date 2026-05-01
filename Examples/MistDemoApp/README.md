# MistDemoApp — Native CloudKit Demo

A SwiftUI demo app that talks to the same CloudKit container as the
[MistDemo CLI/web tool](../MistDemo/), but uses **Apple's native CloudKit
framework** (`CKContainer`, `CKDatabase`, `CKQuery`) instead of MistKit.

The two demos are intended to be shown side-by-side in presentations:

| Surface | Stack | Use case |
|---|---|---|
| `MistDemo` CLI / web (`mistdemo`) | MistKit (CloudKit Web Services REST) | Server, Linux, command line, web |
| `MistDemoApp` (this directory) | Apple CloudKit framework | Native macOS / iOS apps |

Both target the container `iCloud.com.brightdigit.MistDemo`.

## What's included (read-side parity with MistDemo CLI)

- **iCloud Account view** — `CKContainer.accountStatus()`
- **Zones list** — `CKDatabase.allRecordZones()` (parity with `mistdemo lookup-zones`)
- **Record query** — `CKDatabase.records(matching:)` (parity with `mistdemo query`)
- **Record detail** — displays each `CKRecord` field

Write operations (create / update / delete) are intentionally not included
in the first cut — the focus is read-side parity for the presentation.

## Running on macOS (SPM)

```bash
cd Examples/MistDemoApp
swift run MistDemoApp
```

This works because Swift Package Manager can produce a runnable macOS
executable. You'll need the host Mac to be signed in to iCloud for the
account-status check to succeed.

> CloudKit access from a `swift run`-launched binary works for the demo's
> read-only operations, but the binary is **not codesigned with an iCloud
> entitlement**, so writes to the private database will be rejected. For
> the full presentation experience (or any iOS use), wrap this code in an
> Xcode app target as described below.

## Running on iOS / signed macOS app (Xcode)

iOS apps require an `.app` bundle and an iCloud + CloudKit entitlement,
which Swift Package Manager cannot produce on its own. To run on iOS or
ship a signed macOS app:

1. In Xcode, create a new **Multiplatform App** target.
2. Drag `Sources/MistDemoApp/` into the target. The same SwiftUI files
   work on iOS and macOS unchanged — only `MistDemoAppMain.swift`'s
   `defaultSize(...)` is gated to macOS.
3. In **Signing & Capabilities**, add the **iCloud** capability and check
   **CloudKit**. Add the container ID
   `iCloud.com.brightdigit.MistDemo` to the container list.
4. Build and run.

The CloudKit container, schema, and data are shared with the MistDemo CLI
demos — anything you create with `mistdemo create ...` shows up here, and
vice versa.
