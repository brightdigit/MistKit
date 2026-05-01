# MistDemoApp — Native CloudKit Demo

A SwiftUI demo app that talks to the same CloudKit container as the
[MistDemo CLI/web tool](../MistDemo/), but uses **Apple's native CloudKit
framework** (`CKContainer`, `CKDatabase`, `CKQuery`) instead of MistKit.

The two demos are intended to be shown side-by-side in presentations:

| Surface | Stack | Use case |
|---|---|---|
| `MistDemo` CLI / web (`mistdemo`) | MistKit (CloudKit Web Services REST) | Server, Linux, command line, web |
| `MistDemoApp` (this directory) | Apple CloudKit framework | Native macOS / iOS apps |

Both target the container `iCloud.com.brightdigit.MistDemo` and the same
`Note` record schema (see `../MistDemo/schema.ckdb`).

## What's included (read-side parity with MistDemo CLI)

- **iCloud Account view** — `CKContainer.accountStatus()`
- **Zones list** — `CKDatabase.allRecordZones()` (parity with `mistdemo lookup-zones`)
- **Notes query** — `CKDatabase.records(matching:)` for `Note` records, sorted by `index`
- **Note detail** — typed view of `title`, `index`, `image`, `createdAt`, `modified`

The `Note` model in `Sources/MistDemoApp/Models/CloudKitModels.swift`
mirrors the `Note` record type in `Examples/MistDemo/schema.ckdb`. Write
operations (create / update / delete) are intentionally not included in
the first cut — the focus is read-side parity for the presentation.

## Recommended path: open in Xcode

CloudKit requires an `.app` bundle with the iCloud + CloudKit
entitlement. The Xcode project is generated from `project.yml` via
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen           # one-time
cd Examples/MistDemoApp
cp .env.example .env            # one-time — fill in CLOUDKIT_API_TOKEN
make generate                   # sources .env, runs xcodegen
open MistDemoApp.xcodeproj
```

Two schemes ship in the project:

- `MistDemoApp-macOS` — runs as a native macOS app
- `MistDemoApp-iOS` — runs on iOS / iPadOS (simulator or device)

Before running, in **Signing & Capabilities** for each target, sign in
to your Apple Developer account so Xcode can request the `iCloud +
CloudKit` entitlement against the
`iCloud.com.brightdigit.MistDemo` container.

The entitlements file (`MistDemoApp.entitlements`) is checked in and
already lists the container; you'll likely need to change the bundle
identifier prefix from `com.brightdigit` to your own team if you don't
have access to the BrightDigit signing identity.

## Setting the CloudKit API token

The app's iCloud Account view exchanges your **public CloudKit API
token** (from CloudKit Dashboard) for a web auth token via
`CKFetchWebAuthTokenOperation`. The token is the same value the
MistDemo CLI reads from `$CLOUDKIT_API_TOKEN`, so one source covers
both halves of the demo.

There are three ways to provide it, ranked by ergonomics:

1. **`.env` → `make generate` (recommended).** Copy `.env.example` to
   `.env` (gitignored) and fill in `CLOUDKIT_API_TOKEN`. Then run
   `make generate` from `Examples/MistDemoApp`. The Makefile sources
   `.env`; XcodeGen substitutes `${CLOUDKIT_API_TOKEN}` into the
   generated scheme's `environmentVariables`, so when you run the app
   from Xcode the value reaches it through
   `ProcessInfo.processInfo.environment`. The whole `.xcodeproj` is
   gitignored repo-wide, so the substituted value never lands in git.
   Survives Xcode debug runs and iOS Simulator runs.

2. **Ad-hoc terminal env var.** Useful for `swift run`:
   `CLOUDKIT_API_TOKEN=<token> swift run MistDemoApp`. The app reads
   `ProcessInfo.processInfo.environment` on launch. (Note: SPM-launched
   binaries have no iCloud entitlement, so the actual fetch will fail —
   but you can verify the seeding shows a "Loaded from CLOUDKIT_API_TOKEN"
   caption beneath the field.)

3. **Manual paste in the app.** The TextField in iCloud Account still
   accepts ad-hoc values; they persist via `@AppStorage`
   (`UserDefaults`) until cleared.

The `.env` file is gitignored, the `.xcodeproj` is gitignored repo-wide,
and `.env.example` only names the variable — so the secret never lands
in the repo at any stage of the pipeline.

## SPM-only path (read-only, no entitlements)

For a quick smoke test you can also build via Swift Package Manager:

```bash
cd Examples/MistDemoApp
swift run MistDemoApp
```

This works on macOS, but the resulting binary has no iCloud
entitlement, so CloudKit rejects every call with:

> Significant issue at CKContainer.m: In order to use CloudKit, your
> process must have a `com.apple.developer.icloud-services` entitlement.

Use this path only to check that the SwiftUI views compile. For an
actual end-to-end demo, use the Xcode path above.

## Source layout

```
Sources/MistDemoApp/
├── MistDemoApp.swift              # @main App + WindowGroup
├── Models/CloudKitModels.swift    # ZoneRow, Note (matches schema.ckdb)
├── Services/NativeCloudKitService.swift  # Thin CKContainer wrapper
└── Views/
    ├── RootView.swift             # NavigationSplitView shell
    ├── AccountView.swift          # iCloud account status
    ├── ZoneListView.swift         # Zones list
    ├── QueryView.swift            # Notes query
    └── RecordDetailView.swift     # Typed Note detail
```

The same source files compile for both macOS and iOS — only
`MistDemoApp.swift`'s `defaultSize(...)` is gated to macOS.
