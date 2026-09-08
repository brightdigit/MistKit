# Deploying MistKit

From a local CLI to a scheduled CloudKit job in CI — building a static Linux binary, getting credentials into the process, and structuring GitHub Actions workflows for scheduled sync.

## Overview

The hard part of using MistKit on a backend is not writing the code. It is deciding where the code runs, how the credentials get there, and what happens when nobody is watching. This article picks up where <doc:AuthenticationAndDatabases> leaves off and covers the operational side, using two production deployments as worked examples: [BushelCloud](https://github.com/brightdigit/BushelCloud) and [CelestraCloud](https://github.com/brightdigit/CelestraCloud). Both live in this repository under `Examples/`, and both ship today as scheduled GitHub Actions jobs writing to a CloudKit public database from stock Ubuntu runners.

"Deploying" a MistKit-based service means one of three things:

1. **A long-running web service** that handles user requests and talks to CloudKit on their behalf (web auth token) or as itself (server-to-server).
2. **A scheduled job** — a CLI or daemon that wakes on a cron, pulls data from somewhere, and writes it to CloudKit (server-to-server).
3. **A one-shot CLI** a human runs occasionally — data import, schema bootstrapping, audits.

The first is a normal web-app deployment where MistKit is just another HTTP client. The second is where backend CloudKit shines and where the operational patterns are least obvious, so it gets most of the space below. The third is the local-dev story plus credential hygiene.

| Concern | Long-running service | Scheduled job |
| --- | --- | --- |
| **Auth** | Web auth token (per user), API token (public reads), or server-to-server | Server-to-server (or API token for read-only public sync) |
| **Runtime** | Vapor/Hummingbird host, kept warm | Container or `runs-on:` runner, exits on completion |
| **Credentials** | Long-lived secrets in the process environment | Injected per run from CI secrets |
| **Idempotency** | Per request | Per run — "what if this fires twice?" |
| **Observability** | Existing APM / logs | Job summary, artifacts, optional notification |
| **Failure mode** | Returns 5xx to the caller | Silent unless you wire up alerts |

## Picking an auth method for your deployment

From a deployment perspective the question is: **what credentials does my running process need, and where do they come from?**

### Server-to-server (autonomous services, scheduled jobs)

Ship with `CLOUDKIT_KEY_ID` and either `CLOUDKIT_PRIVATE_KEY` (inline PEM) or `CLOUDKIT_PRIVATE_KEY_PATH` (a file). The PEM is the sensitive piece — the private half of an ECDSA P-256 key pair — and it is limited to the **public database**. Use it for scheduled jobs, daemons, and CLIs that write on their own behalf, or a long-running service that operates as itself.

### API token (public-database readers)

Ship with `CLOUDKIT_API_TOKEN` only. No signing, no key file, no clock-synchronised timestamps. The trade-off is that an API token alone grants only what the public schema's `_world` role allows — typically reads. Good fits: a read replica mirroring a public dataset into a search index, a status page, a thin proxy exposing a curated subset of public records.

### Web auth token (acting on behalf of a user)

Ship with `CLOUDKIT_API_TOKEN` **and** a per-user `CLOUDKIT_WEB_AUTH_TOKEN`. The second token arrives at request time through one of the sign-in flows in <doc:AuthenticationAndDatabases>; it is not something you set once as a static variable. There is no good reason to run a *scheduled job* on a web auth token — it expires in 30 minutes (two weeks with "Keep me signed in") and rotates on every response, so a nightly job would be dead by the second night. It belongs to long-running services that hold tokens in a session store.

## Building a deployable binary

### Static Linux builds

MistKit targets cross-platform Swift, so the deployment artifact for Linux is a single statically-linked binary that needs no Swift runtime on the host:

```bash
swift build -c release --static-swift-stdlib
```

Both examples build inside the official Swift container image so the binary is portable across any modern Ubuntu runner. BushelCloud's build workflow runs the job in `container: swiftlang/swift:nightly-6.4.x-noble`; its sync action's fallback path does the same with `docker run` inside a `runs-on: ubuntu-latest` step. CelestraCloud sets the container at the job level. Either works; the job-level form is slightly cleaner when every step needs the toolchain. (Both currently pin a Swift 6.4 nightly because their manifests declare `swift-tools-version: 6.4`; move to a release image when one ships.)

The same binary drops into a distroless or `ubuntu:noble` image for Kubernetes, Fly.io, or a plain `systemd` unit on a VPS.

### Binary caching in CI

A release build from scratch takes a couple of minutes on a stock runner. For a job that fires three times a day that is wasted time — and time during which a transient toolchain or network hiccup can fail a scheduled production run. Both repos build once and reuse:

- **CelestraCloud** caches the binary with `actions/cache@v4`, keyed on the hash of `Sources/**/*.swift` and `Package.swift`, and passes it to each downstream tier job through `actions/upload-artifact@v4` / `download-artifact@v4`.
- **BushelCloud** publishes the binary from a separate `bushel-cloud-build.yml` workflow and has the sync action download that artifact, falling back to an inline build when the artifact has expired:

```yaml
- name: Download pre-built binary (if available)
  id: download-binary
  uses: dawidd6/action-download-artifact@v3
  continue-on-error: true  # Don't fail if artifact is missing
  with:
    workflow: bushel-cloud-build.yml
    workflow_conclusion: success
    name: bushel-cloud-binary
    path: ./binary
    branch: ${{ github.ref_name }}

- name: Build binary (fallback if artifact unavailable)
  if: steps.download-binary.outcome != 'success'
  shell: bash
  run: |
    docker run --rm -v "$PWD:/workspace" -w /workspace swiftlang/swift:nightly-6.4.x-noble \
      swift build -c release --static-swift-stdlib
    mkdir -p ./binary
    cp .build/release/bushel-cloud ./binary/
```

GitHub Actions artifact retention defaults to 90 days; the fallback prevents a stale-artifact failure on day 91.

For a long-running service the equivalent is shipping a built image: one workflow builds and publishes the container, the runtime pulls and runs it.

## Providing credentials at runtime

These patterns apply whether MistKit runs as a GitHub Actions job, a container on Kubernetes, a `systemd` daemon, or a developer's local CLI. Only *how* values reach the process environment changes.

### The environment-variable contract

MistKit itself has no configuration dependency (see <doc:ConfiguringMistKit>); the example CLIs read these variables, and they are the conventional names to use:

| Variable | Method | Purpose |
| --- | --- | --- |
| `CLOUDKIT_CONTAINER_ID` | All | Container identifier, e.g. `iCloud.com.example.MyApp` |
| `CLOUDKIT_ENVIRONMENT` | All | `development` or `production` |
| `CLOUDKIT_API_TOKEN` | API token / web auth | Token from the CloudKit Console |
| `CLOUDKIT_WEB_AUTH_TOKEN` | Web auth | Per-user token from the sign-in flow |
| `CLOUDKIT_KEY_ID` | Server-to-server | Key ID from the CloudKit Console |
| `CLOUDKIT_PRIVATE_KEY` | Server-to-server | Inline PEM contents |
| `CLOUDKIT_PRIVATE_KEY_PATH` | Server-to-server | Filesystem path to the PEM file |

A minimal bootstrap reads them once at startup and constructs the service:

```swift
let env = ProcessInfo.processInfo.environment

guard let containerID = env["CLOUDKIT_CONTAINER_ID"] else {
  throw ConfigurationError.missingRequired("CLOUDKIT_CONTAINER_ID")
}
guard let keyID = env["CLOUDKIT_KEY_ID"] else {
  throw ConfigurationError.missingRequired("CLOUDKIT_KEY_ID")
}

let privateKey: PrivateKeyMaterial
if let inline = env["CLOUDKIT_PRIVATE_KEY"] {
  privateKey = .raw(inline)
} else if let path = env["CLOUDKIT_PRIVATE_KEY_PATH"] {
  privateKey = .file(path: path)
} else {
  throw ConfigurationError.missingRequired("CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH")
}

let credentials = try Credentials(
  serverToServer: ServerToServerCredentials(keyID: keyID, privateKey: privateKey)
)

let service = CloudKitService(
  containerIdentifier: containerID,
  credentials: credentials,
  environment: env["CLOUDKIT_ENVIRONMENT"] == "production" ? .production : .development
)
```

``PrivateKeyMaterial/raw(_:)`` normalizes literal `\n` escapes, which matters when a CI secret store escapes the newlines in the PEM on the way through. The [MistKitConfiguration](https://github.com/brightdigit/MistKitConfiguration) package does this parsing for you, with CLI-argument and `.env` layering on top.

### Inline values vs. file paths

- **Inline** (`CLOUDKIT_PRIVATE_KEY`) is simplest when the credential comes from a CI secret store or a `.env` file: pass the string through and the key never touches disk. BushelCloud's composite action does this:

  ```yaml
  env:
    CLOUDKIT_KEY_ID: ${{ inputs.cloudkit-key-id }}
    CLOUDKIT_PRIVATE_KEY: ${{ inputs.cloudkit-private-key }}
    CLOUDKIT_ENVIRONMENT: ${{ inputs.environment }}
    CLOUDKIT_CONTAINER_ID: ${{ inputs.container-id }}
  ```

- **File path** (`CLOUDKIT_PRIVATE_KEY_PATH`) is what you want when the platform mounts the credential as a file — Kubernetes secrets, `systemd`'s `LoadCredential=`, Docker secrets, a secrets-manager CSI driver — because you inherit its encryption-at-rest and rotation. CelestraCloud writes the PEM to a temp file first:

  ```yaml
  env:
    CLOUDKIT_PRIVATE_KEY_PATH: /tmp/cloudkit_key.pem

  steps:
    - name: Create CloudKit private key file
      run: |
        cat <<'EOF' > $CLOUDKIT_PRIVATE_KEY_PATH
        ${{ secrets.CLOUDKIT_PRIVATE_KEY }}
        EOF
        chmod 600 $CLOUDKIT_PRIVATE_KEY_PATH

    # ... sync step ...

    - name: Cleanup private key
      if: always()
      run: rm -f $CLOUDKIT_PRIVATE_KEY_PATH
  ```

  The `chmod 600` and the `if: always()` cleanup matter little on an ephemeral runner and a great deal on a long-lived host.

### Validate the key before you hit CloudKit

A truncated PEM does not fail at parse time; it fails when you sign the first request, as a generic `401 AUTHENTICATION_FAILED` with no hint why. BushelCloud's action validates the PEM shape before the sync step:

```bash
if ! grep -q "BEGIN.*PRIVATE KEY" <<< "$CLOUDKIT_PRIVATE_KEY"; then
  echo "Error: PEM header not found"
  echo "Common issues: missing BEGIN/END markers, extra whitespace, copy/paste truncation"
  exit 1
fi

if ! grep -q "END.*PRIVATE KEY" <<< "$CLOUDKIT_PRIVATE_KEY"; then
  echo "Error: PEM footer not found"
  exit 1
fi

PEM_CONTENT=$(sed -n '/BEGIN/,/END/p' <<< "$CLOUDKIT_PRIVATE_KEY" | grep -v "BEGIN\|END")
if ! base64 -d >/dev/null 2>&1 <<< "$PEM_CONTENT"; then
  echo "Error: PEM content is not valid base64"
  exit 1
fi
```

The here-string form (`<<< "$VAR"`) is deliberate: it keeps the secret out of the process argument list, which on Linux is visible to other users via `/proc/*/cmdline`. Do not pipe secrets through `echo "$PEM" | grep`.

For a long-running service the same check belongs in the startup health check — fail at boot, not on the first request. MistKit's own equivalent is ``CloudKitError/invalidPrivateKey(path:underlying:)``, thrown when a `.file(path:)` PEM cannot be read or parsed.

### Wiring it up in different runtimes

- **Local development** — a `.env` file in the project root (add it to `.gitignore`), loaded by MistKitConfiguration or `source`d into the shell.
- **GitHub Actions / GitLab CI** — the project's secret store, exposed through `env:` blocks or `${{ secrets.NAME }}`.
- **Docker / Compose** — `environment:`, `env_file:`, or `--env-file`.
- **Kubernetes** — `Secret` resources projected as env vars (`envFrom: secretRef:`) or files (`volumeMounts` + `secret:`); the file form pairs with `CLOUDKIT_PRIVATE_KEY_PATH`.
- **systemd on a VPS** — `EnvironmentFile=` for plain variables; `LoadCredential=` for keys that should stay encrypted at rest.
- **Managed platforms** (Fly.io, Railway, Render, Lambda) — each has a secrets tab; the values land in `ProcessInfo.processInfo.environment` the same way.

## Scheduling strategies

`on: schedule:` is the easy part. The design decisions are *what* to schedule and *how often*.

### Single cron: BushelCloud

BushelCloud syncs macOS, Xcode, and Swift version data three times a day. There is one logical job, so the schedule is three lines:

```yaml
on:
  schedule:
    - cron: '17 2 * * *'   # 02:17 UTC
    - cron: '43 10 * * *'  # 10:43 UTC
    - cron: '29 18 * * *'  # 18:29 UTC

  workflow_dispatch:  # Manual trigger for testing
```

The offsets give roughly eight-hour spacing, aligned with the twelve-hour cache of one upstream source (the VirtualBuddy TSS API). `workflow_dispatch` stays on for ad-hoc reruns.

The **production** sync (`cloudkit-sync-prod.yml`) is `workflow_dispatch` only: the live production container is updated when a human clicks the button, after the development environment has had a clean run. Commit to that policy early.

### Tiered scheduling: CelestraCloud

Not all RSS feeds are equal. Popular feeds want frequent refresh; feeds that have not published in months can be checked weekly. `update-feeds.yml` encodes this with two cron lines, a `determine-tier` job that inspects the current hour, and downstream jobs gated on its outputs:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'   # Daily: standard feeds
    - cron: '0 3 * * 0'   # Weekly Sunday: stale feeds
```

`determine-tier` reads `date -u +%H`, emits a `tier` output (`high`, `standard`, `stale`, or `pr-test`), and each tier job carries `if: needs.determine-tier.outputs.runs_standard == 'true'` (and so on). One workflow, several schedules, no duplicated YAML.

Within a tier the CLI call is parameterized by the tier's filters:

```yaml
strategy:
  matrix:
    include:
      - name: "Pass 1: Very popular feeds"
        args: "--update-min-popularity 100 --update-max-failures 2 --update-delay 2.0 --update-limit 100"
      - name: "Pass 2: Popular feeds"
        args: "--update-min-popularity 10 --update-max-failures 5 --update-delay 2.5 --update-limit 100"
```

Those `--update-*` flags map straight onto ``QueryFilter`` values in the CLI. The same pattern works for any job that needs "the top N by some metric" without scanning the whole table.

### Avoiding the thundering herd

BushelCloud schedules at `:17`, `:43`, and `:29`. GitHub documents that scheduled workflows can be delayed during periods of high load, particularly at the top of the hour when half the world's crons fire. A non-zero minute typically lands closer to the intended time.

## Concurrency, idempotency, and retries

BushelCloud uses a `concurrency` group with `cancel-in-progress: true` so a new sync cancels an older one still in flight:

```yaml
concurrency:
  group: cloudkit-sync-dev
  cancel-in-progress: true
```

This is safe **only because the job is idempotent**. BushelCloud uses deterministic record names derived from build numbers and `.forceReplace` operations, so a rerun updates existing records rather than duplicating them. CelestraCloud queries by GUID before uploading and skips articles that already exist. Neither cares whether the previous run finished.

If your job is not idempotent — it appends to a log, or increments a counter — keep the default `cancel-in-progress: false` and add an application-level lock (a CloudKit record acting as a leader-election token, for instance).

MistKit deliberately does **not** retry transient errors for you. For `THROTTLED` (429) and `TRY_AGAIN_LATER` (503) the pattern is a small wrapper at the operation site with exponential backoff:

```swift
func withBackoff<T>(_ operation: () async throws -> T) async throws -> T {
  var delay: UInt64 = 1_000_000_000  // 1 s in nanoseconds
  for attempt in 1...5 {
    do {
      return try await operation()
    } catch CloudKitError.throttled, CloudKitError.tryAgainLater {
      if attempt == 5 { throw CloudKitError.tryAgainLater(reason: "gave up after 5 attempts") }
      try await Task.sleep(nanoseconds: delay)
      delay *= 2
    }
  }
  fatalError("unreachable")
}
```

<doc:HandlingErrors> lists which ``CloudKitError`` cases are worth retrying; everything else is a configuration or programming error and should surface.

## Observability: reporting from a cron job

The hardest part of a quiet scheduled job is knowing whether it ran and what it did. Both repos use two-step reporting: the CLI writes a structured JSON report, and a CI step turns it into the workflow's summary page via `$GITHUB_STEP_SUMMARY`.

CelestraCloud passes `--update-json-output-path ./feed-update-standard.json` to the CLI and a `summary` job `jq`s the results into Markdown:

```bash
total_feeds=$(jq -r '.summary.totalFeeds // 0' "$json_file")
success_count=$(jq -r '.summary.successCount // 0' "$json_file")
echo "- **Total Feeds Processed:** $total_feeds" >> $GITHUB_STEP_SUMMARY
echo "- **Successful:** $success_count" >> $GITHUB_STEP_SUMMARY
```

BushelCloud does the same through the `BUSHEL_SYNC_JSON_OUTPUT_FILE` environment variable, with a per-record-type table of created / updated / failed counts. Both retain the JSON as a workflow artifact (`actions/upload-artifact@v4`, 7–30 days) so a separate process — a daily digest, a dashboard scrape, a manual audit — can read historical results without re-running the job.

For a long-running service the equivalent is the request logging you already have (MistKit emits through swift-log — see <doc:ConfiguringMistKit>) plus a health-check endpoint that exercises a representative MistKit call so auth or schema drift shows up before users notice.

## Development vs. production environments

CloudKit containers expose two parallel environments, and ``Environment`` on ``CloudKitService`` (or `CLOUDKIT_ENVIRONMENT` in the example CLIs) selects one. The pattern that works:

1. **Two workflows or deployments**, one per environment. BushelCloud has `cloudkit-sync-dev.yml` (scheduled) and `cloudkit-sync-prod.yml` (`workflow_dispatch` only).
2. **Two sets of secrets**, suffixed `_DEV` and `_PROD`, referenced explicitly. No shared default that one environment can accidentally cross-contaminate. Server-to-server keys are created per environment in the CloudKit Console, so the production key is a different key.
3. **Schema changes go through development first**, deployed with `cktool` and verified by the next scheduled dev sync. Once dev has been clean for a day, promote the schema to production and trigger the prod deployment.

This is ordinary dev/prod hygiene with one CloudKit-specific quirk: the schema lives on Apple's infrastructure and must be promoted explicitly, from the console or with `xcrun cktool`.

## Topics

### Types

- ``Credentials``
- ``ServerToServerCredentials``
- ``PrivateKeyMaterial``
- ``Environment``

## See Also

- <doc:AuthenticationAndDatabases>
- <doc:ConfiguringMistKit>
- <doc:HandlingErrors>
- <doc:CloudKitAsYourBackend>
