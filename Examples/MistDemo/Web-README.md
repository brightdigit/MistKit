# MistDemo Web — Interactive CRUD Demo

A long-running Hummingbird server that pairs the CloudKit browser-side
auth round trip with a CRUD UI driven by MistKit on the server. Run
`mistdemo web`, complete the iCloud sign-in in the browser, then drive
record create / query / update / delete from the same page until you
Ctrl+C the server.

The web demo is intended to be shown side-by-side with the other two
MistDemo surfaces:

| Surface | Stack | Use case |
|---|---|---|
| `mistdemo` CLI (`query`, `create`, `update`, `delete`, …) | MistKit (REST) | Command-line, scripts, CI |
| `mistdemo web` (this) | MistKit (REST) + Hummingbird server + browser UI | Interactive demo, presentations |
| `MistDemoApp` (`Native-README.md`) | Apple CloudKit framework | Native macOS / iOS apps |

All three target the container `iCloud.com.brightdigit.MistDemo` and the
same `Note` record schema (see `schema.ckdb`).

## Prerequisites

1. An Apple Developer account with a CloudKit container.
2. A CloudKit **API token** for that container (from the CloudKit
   Console). The web demo uses the web-auth flow, so server-to-server
   signing keys are not needed.
3. Swift 6+ toolchain.

## Quick start

```bash
cd Examples/MistDemo
swift run mistdemo web --api-token "$CLOUDKIT_API_TOKEN"
```

Or via env var:

```bash
CLOUDKIT_API_TOKEN=… swift run mistdemo web
```

The CLI prints the server URL and opens your browser automatically.
Sign in with your Apple ID; the server captures the web-auth token and
the CRUD UI on the page becomes live.

## Options

| Flag | Default | Notes |
|---|---|---|
| `--api-token <token>` | (required) | Or set `CLOUDKIT_API_TOKEN` |
| `--container-identifier <id>` | `iCloud.com.brightdigit.MistDemo` | Your CloudKit container |
| `--environment <env>` | `development` | `development` or `production` |
| `--host <host>` | `127.0.0.1` | Bind address |
| `--port <port>` | `8080` | Server port |
| `--no-browser` | off | Don't auto-open the browser |

Configuration is read via `MistDemoConfiguration`, so the same keys
(`api.token`, `container.identifier`, `environment`, `port`, `host`,
`no.browser`) can be supplied through `--config-file ~/.mistdemo/config.json`
or environment variables.

## What the server exposes

Loopback-only routes registered under `/api`:

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

## Calling the API directly

Once the browser has completed the auth round trip, the same endpoints
can be exercised from a terminal:

```bash
curl -X POST http://127.0.0.1:8080/api/records/query \
  -H 'Content-Type: application/json' \
  -d '{"recordType":"Note"}'
```

## Tests

```bash
cd Examples/MistDemo
swift test --filter WebServerTests
swift test --filter WebAuthTokenStoreTests
```

`WebServerTests` uses `MockBackend` to drive the routes without
hitting CloudKit. `WebAuthTokenStoreTests` covers the token-capture
stream that backs the auth response.

## Layout

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

## Security notes

- The server binds to `127.0.0.1` by default and rejects non-loopback
  requests to `/api/config`. Override `--host` with care.
- The web-auth token is short-lived. Re-run `mistdemo web` to refresh it.
- Never commit your CloudKit API token; prefer `CLOUDKIT_API_TOKEN` or a
  config file outside the repo.
