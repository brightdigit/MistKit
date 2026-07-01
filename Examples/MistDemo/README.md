# MistDemo

Three runnable demos that exercise the same CloudKit container from
three different stacks, intended to be shown side-by-side:

| Surface | Stack | Use case |
|---|---|---|
| `mistdemo` CLI (`query`, `create`, `update`, `delete`, …) | MistKit (CloudKit Web Services REST) | Command-line, scripts, CI, Linux |
| `mistdemo web` | MistKit + Hummingbird server + browser UI | Interactive demo, presentations |
| `MistDemoApp` | Apple CloudKit framework (`CKContainer`, `CKDatabase`) | Native macOS / iOS apps |

All three target the container `iCloud.com.brightdigit.MistDemo` and the
same `Note` record schema (see [`schema.ckdb`](schema.ckdb)). The same
`$CLOUDKIT_API_TOKEN` covers the CLI/web and is also exchanged for a
web-auth token by the native app, so one source of credentials feeds
every surface.

## Prerequisites

1. An Apple Developer account with a CloudKit container.
2. A CloudKit **API token** for that container (from the CloudKit
   Console). The web and native demos use the web-auth flow, so
   server-to-server signing keys are not needed.
3. Swift 6+ toolchain (for the CLI/web). The native app additionally
   requires Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

---

## CLI — `mistdemo`

The CLI is the broadest surface — every CloudKit operation MistKit
supports has a subcommand. See `swift run mistdemo --help` for the full
list. The most common commands:

```bash
cd Examples/MistDemo
swift run mistdemo query --record-type Note
swift run mistdemo create --record-type Note --fields '{"title":"Hi"}'
swift run mistdemo auth-token              # capture a web-auth token
swift run mistdemo test-public             # integration suite, public DB
swift run mistdemo test-private            # integration suite, private DB
```

Configuration comes from `MistDemoConfiguration` — flags,
`CLOUDKIT_*` env vars, or `--config-file ~/.mistdemo/config.json` all
work.

---

## Web — `mistdemo web`

A long-running Hummingbird server that pairs the CloudKit browser-side
auth round trip with a CRUD UI driven by MistKit on the server. Run
`mistdemo web`, complete the iCloud sign-in in the browser, then drive
record create / query / update / delete from the same page until you
Ctrl+C the server.

### Quick start

```bash
cd Examples/MistDemo
swift run mistdemo web --api-token "$CLOUDKIT_API_TOKEN"
```

Or via env var:

```bash
CLOUDKIT_API_TOKEN=… swift run mistdemo web
```

The CLI prints the server URL. The `web` command does **not** open the
browser by default (the server is long-running and often driven from a
different machine); pass `--browser` to opt in. The `auth-token` command
**does** open the browser by default — the captured token is the whole
point of running it. Sign in with your Apple ID; the server captures the
web-auth token and the CRUD UI on the page becomes live.

### Options

| Flag | Default | Notes |
|---|---|---|
| `--api-token <token>` | (required) | Or set `CLOUDKIT_API_TOKEN` |
| `--container-identifier <id>` | `iCloud.com.brightdigit.MistDemo` | Your CloudKit container |
| `--environment <env>` | `development` | `development` or `production` |
| `--host <host>` | `127.0.0.1` | Bind address |
| `--port <port>` | `8080` | Server port |
| `--browser` | on for `auth-token`, off for `web` | Open browser on startup |
| `--no-browser` | — | Suppress the open (wins if both flags set) |

Configuration is read via `MistDemoConfiguration`, so the same keys
(`api.token`, `container.identifier`, `environment`, `port`, `host`,
`browser`, `no.browser`) can be supplied through `--config-file ~/.mistdemo/config.json`
or environment variables.

### What the server exposes

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/` and `/index.html` | Interactive demo page |
| `GET` | `/api/config` | CloudKit JS config (loopback-only) |
| `POST` | `/api/authenticate` | Capture web-auth token from the browser |
| `POST` | `/api/records/query` | Query records |
| `POST` | `/api/records/create` | Create record |
| `POST` | `/api/records/update` | Update record |
| `POST` | `/api/records/delete` | Delete record |

The page has a **mode toggle** that compares the two stacks against the
same container:

- **MistKit (server-side)** — the page calls `/api/records/*` on this
  server, which talks to CloudKit Web Services via MistKit.
- **CloudKit JS (browser-side)** — the page talks directly to CloudKit
  from the browser using the config returned by `/api/config`.

### Calling the API directly

Once the browser has completed the auth round trip, the same endpoints
can be exercised from a terminal:

```bash
curl -X POST http://127.0.0.1:8080/api/records/query \
  -H 'Content-Type: application/json' \
  -d '{"recordType":"Note"}'
```

### Tests

```bash
cd Examples/MistDemo
swift test --filter WebServerTests
swift test --filter WebAuthTokenStoreTests
```

`WebServerTests` uses `MockBackend` to drive the routes without
hitting CloudKit. `WebAuthTokenStoreTests` covers the token-capture
stream that backs the auth response.

### Layout

The web command's code lives under `Sources/MistDemoKit/`:

```
Sources/MistDemoKit/
├── Commands/WebCommand.swift              # `mistdemo web` entry point
├── Configuration/WebConfig.swift          # Flags / env / config-file binding
├── Resources/index.html                   # Served at GET /
└── Server/
    ├── WebServer.swift                    # Hummingbird router + handlers
    ├── WebBackend.swift                   # MistKit-backed backend
    ├── WebRequests.swift                  # Request payloads
    ├── WebResponse.swift                  # Response payloads
    ├── WebIndexHTML.swift                 # Loads index HTML from Bundle.module
    └── WebAuthTokenStore.swift            # Captures the token from /api/authenticate
```

Tests are under `Tests/MistDemoTests/Server/`.

### Security notes

- The server binds to `127.0.0.1` by default and rejects non-loopback
  requests to `/api/config`. Override `--host` with care.
- The web-auth token is short-lived. Re-run `mistdemo web` to refresh it.
- Never commit your CloudKit API token; prefer `CLOUDKIT_API_TOKEN` or a
  config file outside the repo.

### Troubleshooting

**The "Allow" notification appears but no code shows up.** When you sign in,
Apple sends a *trusted-device* two-factor prompt ("Apple Account Sign In
Requested … used to sign in on the web"). Clicking **Allow** is supposed to
display a 6-digit code to type into the `idmsa.apple.com` window, but macOS
sometimes fails to show that code modal — so the six boxes stay empty and
sign-in stalls.

This is Apple/macOS behavior, not a MistDemo or MistKit bug: the sign-in page
is served by `idmsa.apple.com` and driven by Apple's CloudKit JS widget, which
owns the entire Apple ID + two-factor challenge. MistDemo only captures the
resulting web-auth token after you succeed.

Reliable workaround — generate the code yourself instead of waiting for the
popup:

- **On the Mac:** System Settings → *[your name]* → **Sign-In & Security** →
  **Get Verification Code**.
- **On iPhone / iPad:** Settings → *[your name]* → **Sign-In & Security** →
  **Get Verification Code**.

Type the six digits into the sign-in window. (Requesting the code via SMS also
works, but "Get Verification Code" is faster and doesn't depend on your
carrier.)

---

## Native app — `MistDemoApp`

A SwiftUI demo app that talks to the same CloudKit container, but uses
**Apple's native CloudKit framework** (`CKContainer`, `CKDatabase`,
`CKQuery`) instead of MistKit.

### What's included (read-side parity with the CLI)

- **iCloud Account view** — `CKContainer.accountStatus()`
- **Zones list** — `CKDatabase.allRecordZones()` (parity with `mistdemo lookup-zones`)
- **Notes query** — `CKDatabase.records(matching:)` for `Note` records, sorted by `index`
- **Note detail** — typed view of `title`, `index`, `image`; created/modified come from CloudKit system metadata
- **Create / update / delete** — `CKDatabase.save(_:)` and `deleteRecord(withID:)`

The `Note` model in `Sources/MistDemoApp/Models/CloudKitModels.swift`
mirrors the `Note` record type in `schema.ckdb`.

### Layout

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
│   └── MistDemoApp/                  # SwiftUI library used by the Xcode app
│       ├── Models/CloudKitModels.swift
│       ├── Services/NativeCloudKitService.swift
│       └── Views/{RootView,AccountView,ZoneListView,QueryView,NoteEditView,RecordDetailView}.swift
└── schema.ckdb                       # CloudKit schema for Note record
```

The same `MistDemoApp` source files compile for both macOS and iOS;
only `App/MistDemoApp.swift`'s `defaultSize(...)` is gated to macOS.

### Recommended path: open in Xcode

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

### Setting the CloudKit API token

The app's iCloud Account view exchanges your **public CloudKit API
token** (from CloudKit Dashboard) for a web auth token via
`CKFetchWebAuthTokenOperation`. The token is the same value the
CLI/web reads from `$CLOUDKIT_API_TOKEN`, so one source covers every
surface.

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
