# MistDemoApp — Native CloudKit Demo

A SwiftUI demo app that talks to the same CloudKit container as the
MistDemo CLI/web tool, but uses **Apple's native CloudKit framework**
(`CKContainer`, `CKDatabase`, `CKQuery`) instead of MistKit.

The two demos are intended to be shown side-by-side in presentations:

| Surface | Stack | Use case |
|---|---|---|
| `MistDemo` CLI / web (`mistdemo`) | MistKit (CloudKit Web Services REST) | Server, Linux, command line, web |
| `MistDemoApp` (this directory) | Apple CloudKit framework | Native macOS / iOS apps |

Both target the container `iCloud.com.brightdigit.MistDemo` and the same
`Note` record schema (see `schema.ckdb`).

## What's included (read-side parity with MistDemo CLI)

- **iCloud Account view** — `CKContainer.accountStatus()`
- **Zones list** — `CKDatabase.allRecordZones()` (parity with `mistdemo lookup-zones`)
- **Notes query** — `CKDatabase.records(matching:)` for `Note` records, sorted by `index`
- **Note detail** — typed view of `title`, `index`, `image`, `createdAt`, `modified`
- **Create / update / delete** — `CKDatabase.save(_:)` and `deleteRecord(withID:)`

The `Note` model in `Sources/MistDemoApp/Models/CloudKitModels.swift`
mirrors the `Note` record type in `schema.ckdb`.

## Layout

The reusable code lives in the `MistDemoApp` library target of the
local Swift package. The Xcode project only references a thin `@main`
shell:

```
Examples/MistDemo/
├── Package.swift                     # mistdemo CLI + MistDemoApp library
├── project.yml                       # XcodeGen config
├── App/
│   └── MistDemoApp.swift             # @main App + WindowGroup
├── Sources/
│   ├── MistDemo/                     # CLI entry point
│   ├── MistDemoKit/                  # CLI library (used by mistdemo)
│   ├── ConfigKeyKit/                 # Configuration parsing
│   └── MistDemoApp/               # SwiftUI library used by the Xcode app
│       ├── Models/CloudKitModels.swift
│       ├── Services/NativeCloudKitService.swift
│       └── Views/{RootView,AccountView,ZoneListView,QueryView,NoteEditView,RecordDetailView}.swift
└── schema.ckdb                       # CloudKit schema for Note record
```

The same `MistDemoApp` source files compile for both macOS and iOS;
only `App/MistDemoApp.swift`'s `defaultSize(...)` is gated to macOS.

## Recommended path: open in Xcode

CloudKit requires an `.app` bundle with the iCloud + CloudKit
entitlement. The Xcode project is generated from `project.yml` via
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen           # one-time
cd Examples/MistDemo
cp .env.example .env            # one-time — fill in CLOUDKIT_API_TOKEN, BUNDLE_ID_PREFIX, DEVELOPMENT_TEAM
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
already lists the container. If you don't have access to the
BrightDigit signing identity, set `BUNDLE_ID_PREFIX` in `.env` to a
prefix you own and `DEVELOPMENT_TEAM` to your team ID before running
`make generate`.

## Setting the CloudKit API token

The app's iCloud Account view exchanges your **public CloudKit API
token** (from CloudKit Dashboard) for a web auth token via
`CKFetchWebAuthTokenOperation`. The token is the same value the
MistDemo CLI reads from `$CLOUDKIT_API_TOKEN`, so one source covers
both halves of the demo.

There are three ways to provide it, ranked by ergonomics:

1. **`.env` → `make generate` (recommended).** Copy `.env.example` to
   `.env` (gitignored) and fill in `CLOUDKIT_API_TOKEN`. Then run
   `make generate` from `Examples/MistDemo`. The Makefile sources
   `.env`; XcodeGen substitutes `${CLOUDKIT_API_TOKEN}` into the
   generated scheme's `environmentVariables`, so when you run the app
   from Xcode the value reaches it through
   `ProcessInfo.processInfo.environment`. The whole `.xcodeproj` is
   gitignored repo-wide, so the substituted value never lands in git.
   Survives Xcode debug runs and iOS Simulator runs.

2. **Ad-hoc terminal env var.** Useful when launching from a shell:
   `CLOUDKIT_API_TOKEN=<token> open MistDemoApp.xcodeproj`. The app
   reads `ProcessInfo.processInfo.environment` on launch.

3. **Manual paste in the app.** The TextField in iCloud Account still
   accepts ad-hoc values; they persist via `@AppStorage`
   (`UserDefaults`) until cleared.

The `.env` file is gitignored, the `.xcodeproj` is gitignored repo-wide,
and `.env.example` only names the variable — so the secret never lands
in the repo at any stage of the pipeline.
