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
xcodegen generate                # produces MistDemoApp.xcodeproj
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
