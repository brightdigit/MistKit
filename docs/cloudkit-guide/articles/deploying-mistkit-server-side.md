---
title: Deploying MistKit - From Local CLI to a Scheduled CloudKit Job in CI
date: 2026-06-01 00:00
description: A practical walkthrough of running a MistKit-based service or scheduled job in production - how to build a static Linux binary, manage CloudKit credentials, and structure GitHub Actions workflows for tiered scheduled sync. Built around two real production deployments, BushelCloud and CelestraCloud.
featuredImage: /media/tutorials/[VERIFY: path to hero image]
subscriptionCTA: Subscribe for more deep dives on running Swift on the server.
---

<!-- NOTE: Audience is backend/server-side Swift developers who already know how to wire MistKit up locally and now need to actually ship it - to a server, a container, or a scheduled CI job. This is a deployment guide, not a getting-started guide. -->

<!-- DRAFT - not yet published. Verify all [VERIFY] markers and the dates/contents of the example repos before publishing. -->

The hard part of using MistKit on a backend isn't writing the code - it's deciding where the code runs, how the credentials get there, and what happens when nobody's watching. Once you've got CloudKit working from a local CLI, the next question is: how do I run this on a schedule, on Linux, without a Mac in the loop?

This article is the deployment guide that picks up where the [authentication walkthrough](/tutorials/authenticating-cloudkit-backend-services/) leaves off. Instead of focusing on which auth method to pick, it focuses on the operational side: how to build, package, and run a MistKit-based service so it works reliably on a server, in a container, or as a scheduled CI job. Two production deployments - [BushelCloud](https://github.com/brightdigit/BushelCloud) and [CelestraCloud](https://github.com/brightdigit/CelestraCloud) - are used throughout as worked examples, because both ship today as scheduled CI jobs that write to a CloudKit public database from stock Ubuntu runners.

---

**In this series:**

* [Rebuilding MistKit with Claude Code (Part 1)](/tutorials/rebuilding-mistkit-claude-code-part-1/)
* [Rebuilding MistKit with Claude Code (Part 2)](/tutorials/rebuilding-mistkit-claude-code-part-2/)
* [Authenticating CloudKit from Backend Services](/tutorials/authenticating-cloudkit-backend-services/)
* _Deploying MistKit: From Local CLI to a Scheduled CloudKit Job in CI_

---

- [What "Deploying" Actually Means Here](#what-deploying-means)
- [Workload Shapes: Server vs. Scheduled Job](#workload-shapes)
- [Picking an Auth Method for Your Deployment](#picking-auth-method)
  - [Server-to-Server (Autonomous Services, Scheduled Jobs)](#auth-s2s)
  - [API Token (Public-Database Readers)](#auth-api-token)
  - [Web Auth Token (Acting on Behalf of a User)](#auth-web-token)
- [Building a Deployable Binary](#building-a-deployable-binary)
  - [Static Linux Builds](#static-linux-builds)
  - [Binary Caching in CI](#binary-caching-in-ci)
- [Providing Credentials at Runtime](#providing-credentials)
  - [The Environment Variable Contract](#env-var-contract)
  - [Inline Values vs. File Paths](#inline-vs-path)
  - [Validating the Key Before You Hit CloudKit](#validating-the-key)
  - [Wiring It Up in Different Runtimes](#runtime-wiring)
- [Scheduling Strategies](#scheduling-strategies)
  - [Single-Cron: BushelCloud's Pattern](#single-cron-bushelcloud)
  - [Tiered Scheduling: CelestraCloud's Pattern](#tiered-celestracloud)
  - [Avoiding the Thundering Herd](#thundering-herd)
- [Concurrency, Idempotency, and Retries](#concurrency-and-retries)
- [Observability: Reporting from a Cron Job](#observability)
- [Dev vs. Prod CloudKit Environments](#dev-vs-prod)

<a id="what-deploying-means"></a>
## What "Deploying" Actually Means Here

"Deploying" a MistKit-based service can mean one of three things, depending on the workload:

1. **A long-running web service** that handles user requests and talks to CloudKit on their behalf (typically with a Web Auth Token, or system-attributed with Server-to-Server).
2. **A scheduled job** - a CLI or daemon that wakes up on a cron, pulls data from somewhere, and writes it to CloudKit (typically with Server-to-Server auth).
3. **A one-shot CLI** that a human runs occasionally - data import, schema bootstrapping, audits.

The first is closest to a "normal" web app deployment - your existing Vapor/Hummingbird playbook applies and MistKit is just another HTTP client inside it. The second is where backend CloudKit actually shines and where the operational patterns are non-obvious: there's no user session to lean on, no UI to report progress, and no Apple-supplied infrastructure to fall back on. The third is mostly the local-dev story plus credential hygiene.

Both example repos in this series - BushelCloud and CelestraCloud - are case (2): scheduled jobs running in GitHub Actions on Ubuntu. That's the shape this article spends the most time on, since it's the least documented. The build, credential, and observability sections also apply directly to case (1) - the only thing that differs is the scheduler.

<a id="workload-shapes"></a>
## Workload Shapes: Server vs. Scheduled Job

| Concern | Long-running service | Scheduled job |
|---------|---------------------|---------------|
| **Auth** | Web Auth Token (per user), API Token (public reads), or S2S (system-attributed) | Server-to-Server (or API Token for read-only public sync) |
| **Runtime** | Vapor/Hummingbird host, kept warm | Container or `runs-on:` runner, exits on completion |
| **Credentials** | Long-lived secrets in the process environment | Injected per-run from CI secrets |
| **Idempotency** | Per-request | Per-run - "what if this fires twice?" matters more |
| **Observability** | Existing APM / logs | Job summary, artifacts, optional notification |
| **Failure mode** | Returns 5xx to caller | Silent unless you wire up alerts |

The scheduled-job column is where the worked examples live, but most of the operational patterns - building a portable binary, injecting credentials from the environment, validating the key before first use - port directly to the long-running-service column.

<a id="picking-auth-method"></a>
## Picking an Auth Method for Your Deployment

The [authentication walkthrough](/tutorials/authenticating-cloudkit-backend-services/) covers the three methods in detail. From a deployment perspective, the key question is: **what credentials does my running process need to have available, and where do they come from?** That question has three different answers.

<a id="auth-s2s"></a>
### Server-to-Server (Autonomous Services, Scheduled Jobs)

This is what most of this article is about. Your deployment needs to ship with:

- `CLOUDKIT_KEY_ID` - the Key ID string from the CloudKit Dashboard
- `CLOUDKIT_PRIVATE_KEY` (inline PEM) **or** `CLOUDKIT_PRIVATE_KEY_PATH` (filesystem path)

The PEM file is the sensitive piece - it's the private half of an ECDSA P-256 key pair, and it's how your service proves it's allowed to write to the public database. Limited to the **public database only**.

Use S2S when: scheduled jobs, daemons, CLIs that write data on their own behalf, or a long-running service that operates as itself (not on behalf of a user) and only needs the public database.

<a id="auth-api-token"></a>
### API Token (Public-Database Readers)

The simplest possible credentialing for a backend service:

- `CLOUDKIT_API_TOKEN` - a single string from the CloudKit Dashboard

No signing, no key file, no clock-synchronized timestamps. Just an env var. The trade-off is that an API Token alone grants only limited public-database access - you can read public records that have a security role of `_world`, but you can't write, and you can't touch the private or shared databases.

Use API Token when: your backend service only **reads** data from the public database and you don't care about per-user attribution. A read replica that mirrors a CloudKit-hosted dataset into a search index, a status page that surfaces public-database counts, a thin REST proxy that exposes a curated subset of public records - all good fits.

The deployment story collapses to "set one env var" - everything in [Providing Credentials at Runtime](#providing-credentials) below still applies, but the PEM-validation step and the file-on-disk pattern don't.

<a id="auth-web-token"></a>
### Web Auth Token (Acting on Behalf of a User)

Web Auth Token requires **both**:

- `CLOUDKIT_API_TOKEN` - identifies the container
- `CLOUDKIT_WEB_AUTH_TOKEN` - identifies the specific user

The second token is per-user and arrives at your service through one of the flows documented in the auth article (browser redirect or `CKFetchWebAuthTokenOperation` handoff from an iOS app). It's not something you'd typically set as a static environment variable - it's something your service receives at request time and passes through to MistKit on a per-request basis.

There's no obvious reason to run a *scheduled job* with a Web Auth Token - schedule cycles outlive any reasonable user session, and the token would need refreshing on a cadence that defeats the point. It shows up in the deployment story only when a long-running web service holds tokens in a session store and uses MistKit to act on behalf of whichever user is currently making a request.

[VERIFY: web-auth-token lifetime and refresh behavior aren't clearly documented; confirm before publishing whether long-lived scheduled use is even practically possible.]

<a id="building-a-deployable-binary"></a>
## Building a Deployable Binary

<a id="static-linux-builds"></a>
### Static Linux Builds

MistKit targets cross-platform Swift, so the deployment artifact for a Linux service or scheduled job is a single statically-linked binary that doesn't need a Swift runtime on the host. Both BushelCloud and CelestraCloud build with `--static-swift-stdlib` against the official Swift Docker image:

```bash
swift build -c release --static-swift-stdlib
```

In CI, the build happens inside a `swift:6.2-noble` (Ubuntu Noble) container so the resulting binary is portable across any modern Ubuntu runner. CelestraCloud invokes this with `container: swift:6.2-noble` at the job level; BushelCloud uses `docker run --rm` inside a `runs-on: ubuntu-latest` step for the fallback build path. Either approach works - the container-at-job-level form is slightly cleaner when every step in a job needs the Swift toolchain.

The same `--static-swift-stdlib` binary drops straight into a distroless or `ubuntu:noble` container image for non-CI deployment targets (Kubernetes, Fly.io, a plain `systemd` unit on a VPS). No Swift runtime needed on the host.

[VERIFY: confirm Swift 6.2 is still the right minimum on a fresh `ubuntu-latest` image at publish time - this may have advanced.]

<a id="binary-caching-in-ci"></a>
### Binary Caching in CI

A `swift build -c release --static-swift-stdlib` from scratch in the Swift Docker image takes ~2 minutes on a stock `ubuntu-latest` runner. For a job that runs three times a day, that's six wasted minutes daily - and worse, it's six minutes during which a transient toolchain or network hiccup could fail a scheduled production run.

The pattern both repos use is to **build the binary once and cache it**:

```yaml
- name: Cache compiled binary
  id: cache-binary
  uses: actions/cache@v4
  with:
    path: .build/release/celestra-cloud
    key: celestra-cloud-${{ runner.os }}-${{ hashFiles('Sources/**/*.swift', 'Package.swift') }}-${{ github.event.inputs.force_rebuild || 'false' }}
```

The cache key is keyed on the hash of the Swift sources and `Package.swift`, so any code change invalidates it. CelestraCloud also wires an `actions/upload-artifact@v4` step after the build and `actions/download-artifact@v4` in each subsequent job, so a single build feeds multiple downstream sync jobs in the same workflow run (one per feed tier).

BushelCloud takes a similar shape but pulls the binary from a separate `bushel-cloud-build.yml` workflow's artifact, falling back to an inline build if the artifact has expired (GitHub Actions artifact retention defaults to 90 days). The fallback path is worth copying - it prevents a stale-artifact failure on day 91 from breaking your scheduled run.

For a long-running server deployment, the equivalent of "binary caching" is just shipping a built image: one CI workflow builds and publishes the container, the runtime pulls and runs it. Same end state, different scheduler.

<a id="providing-credentials"></a>
## Providing Credentials at Runtime

The credential-injection patterns below apply regardless of whether MistKit is running as a scheduled GitHub Actions job, a long-running container on Kubernetes, a systemd-managed daemon on a VPS, or a developer's local CLI. The only thing that changes per environment is *how* the values get into the process's environment - MistKit itself just reads them.

<a id="env-var-contract"></a>
### The Environment Variable Contract

MistKit (and the example CLIs) read all credentials from `ProcessInfo.processInfo.environment`. The full set of variables, by auth method:

| Variable | Method | Purpose |
|----------|--------|---------|
| `CLOUDKIT_CONTAINER_ID` | All | Container identifier, e.g. `iCloud.com.example.MyApp` |
| `CLOUDKIT_ENVIRONMENT` | All | `development` or `production` |
| `CLOUDKIT_API_TOKEN` | API Token / Web Auth | Public-DB token from Dashboard |
| `CLOUDKIT_WEB_AUTH_TOKEN` | Web Auth | Per-user token from sign-in flow |
| `CLOUDKIT_KEY_ID` | S2S | Server-to-Server key ID from Dashboard |
| `CLOUDKIT_PRIVATE_KEY` | S2S | Inline PEM contents |
| `CLOUDKIT_PRIVATE_KEY_PATH` | S2S | Filesystem path to PEM file |

A typical bootstrap in your service entrypoint reads these once at startup and constructs the `CloudKitService`:

```swift
let env = ProcessInfo.processInfo.environment

guard let containerID = env["CLOUDKIT_CONTAINER_ID"] else {
    throw ConfigurationError.missingRequired("CLOUDKIT_CONTAINER_ID")
}

let environment: CloudKitEnvironment =
    env["CLOUDKIT_ENVIRONMENT"] == "production" ? .production : .development

// S2S path - read PEM inline or from disk
guard let keyID = env["CLOUDKIT_KEY_ID"] else {
    throw ConfigurationError.missingRequired("CLOUDKIT_KEY_ID")
}

let pem: String
if let inline = env["CLOUDKIT_PRIVATE_KEY"] {
    pem = inline.replacingOccurrences(of: "\\n", with: "\n")
} else if let path = env["CLOUDKIT_PRIVATE_KEY_PATH"] {
    pem = try String(contentsOfFile: path, encoding: .utf8)
} else {
    throw ConfigurationError.missingRequired("CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH")
}

let manager = try ServerToServerAuthManager(keyID: keyID, pemString: pem)
let service = CloudKitService(
    containerIdentifier: containerID,
    tokenManager: manager,
    environment: environment
)
```

The `\\n` → `\n` replacement matters when the secrets-injection layer escapes newlines in the PEM contents (GitHub Actions, GitLab CI, and a handful of others do this). If your environment preserves newlines verbatim, you can drop the replacement.

<a id="inline-vs-path"></a>
### Inline Values vs. File Paths

For the Server-to-Server PEM specifically, MistKit accepts the key two ways: inline as `CLOUDKIT_PRIVATE_KEY`, or via a filesystem path in `CLOUDKIT_PRIVATE_KEY_PATH`. The choice depends on where the credential comes from in the host environment:

- **Inline** is the simplest path when the credential comes from a CI secret store or a `.env` file - you pass the PEM string through as-is and the key never touches disk.
- **File path** is what you want when the credential is mounted as a file by the platform - Kubernetes secrets, systemd's `LoadCredential=`, Docker secrets, a secrets-manager CSI driver. Pointing at the mount path means you get the platform's encryption-at-rest and rotation handling for free.

BushelCloud's composite action uses the inline form:

```yaml
env:
  CLOUDKIT_KEY_ID:        ${{ inputs.cloudkit-key-id }}
  CLOUDKIT_PRIVATE_KEY:   ${{ inputs.cloudkit-private-key }}
```

CelestraCloud writes the PEM to a temp file first, then points MistKit at the path:

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

  # ... sync step uses the binary with CLOUDKIT_PRIVATE_KEY_PATH set ...

  - name: Cleanup private key
    if: always()
    run: rm -f $CLOUDKIT_PRIVATE_KEY_PATH
```

Two things to call out: the `chmod 600` (so only the runner user can read it) and the `if: always()` cleanup step (so the key is removed even when the sync step fails). Neither matters much on an ephemeral runner that's thrown away after the run, but both are non-optional on long-lived hosts.

<a id="validating-the-key"></a>
### Validating the Key Before You Hit CloudKit

A truncated PEM doesn't fail at parse time - it fails when you try to sign a request, and the failure mode is a generic `401 AUTHENTICATION_FAILED` from CloudKit with no detail on _why_. BushelCloud's composite action validates the PEM format before the sync step runs, which dramatically shortens the debugging loop on credential rotation:

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

# Validate base64 content between headers
PEM_CONTENT=$(sed -n '/BEGIN/,/END/p' <<< "$CLOUDKIT_PRIVATE_KEY" | grep -v "BEGIN\|END")
if ! base64 -d >/dev/null 2>&1 <<< "$PEM_CONTENT"; then
  echo "Error: PEM content is not valid base64"
  exit 1
fi
```

The `<<< "$VAR"` (here-string) form is deliberate: it keeps the secret out of the process argument list, which on Linux is visible to other users via `/proc/*/cmdline`. Don't pipe secrets through `echo "$PEM" | grep` if you can avoid it.

For a long-running service, the same check belongs in the startup health check - fail loudly at boot rather than on the first request.

[VERIFY: GitHub's secret-redaction handles the `echo`-into-pipe case fine for log output, but the process-list visibility is still real on shared runners. Confirm before publishing.]

<a id="runtime-wiring"></a>
### Wiring It Up in Different Runtimes

Same env-var contract, different injection mechanism per runtime:

- **Local development** - A `.env` file in the project root, sourced with `source .env` or loaded by a library like Apple's [swift-configuration](https://github.com/apple/swift-configuration) (CelestraCloud does this - see its `Configuration/` directory). Add `.env` to `.gitignore`.
- **GitHub Actions / GitLab CI** - Secrets stored in the project's secret store, exposed via `env:` blocks or `${{ secrets.NAME }}` interpolation, as shown above.
- **Docker / Compose** - `environment:` block in `docker-compose.yml`, `env_file:`, or `--env-file` at `docker run` time.
- **Kubernetes** - `Secret` resources, projected into the pod either as env vars (`envFrom: secretRef:`) or as files (`volumeMounts: + secret:`). The file form pairs naturally with `CLOUDKIT_PRIVATE_KEY_PATH`.
- **systemd on a VPS** - `EnvironmentFile=` in the unit file for plain env vars; `LoadCredential=` (on systems with credential-encryption) for keys that should stay encrypted at rest.
- **Managed platforms (Fly.io, Railway, Render, Lambda)** - Each has its own "environment variables" or "secrets" tab in the dashboard. The injected values end up in `ProcessInfo.processInfo.environment` exactly the same way.

The MistKit side doesn't care which of these you use - it just reads the environment.

<a id="scheduling-strategies"></a>
## Scheduling Strategies

GitHub Actions' `on: schedule:` is the easy part - cron syntax, one line, done. The interesting design decisions are around _what_ to schedule and _how often_. (For long-running services this section doesn't apply - skip to [Concurrency, Idempotency, and Retries](#concurrency-and-retries).)

<a id="single-cron-bushelcloud"></a>
### Single-Cron: BushelCloud's Pattern

BushelCloud syncs macOS / Xcode / Swift version data three times a day. There's only one logical job ("scrape upstream sources, write to CloudKit"), and the scheduling reflects that:

```yaml
on:
  schedule:
    - cron: '17 2 * * *'   # 02:17 UTC
    - cron: '43 10 * * *'  # 10:43 UTC
    - cron: '29 18 * * *'  # 18:29 UTC

  workflow_dispatch:  # Manual trigger for testing
```

The three offsets are chosen to give roughly 8-hour spacing, aligned with the VirtualBuddy TSS API's 12-hour cache lifetime (one of BushelCloud's upstream data sources). Manual `workflow_dispatch` is left on for ad-hoc reruns and for the "I just merged a fix and want to see it run now" case.

Production sync runs are kept on `workflow_dispatch` only - the live production CloudKit container is only updated when a human explicitly clicks the button, after the development environment has had a clean run. This is one of those policy decisions that's worth committing to early.

<a id="tiered-celestracloud"></a>
### Tiered Scheduling: CelestraCloud's Pattern

CelestraCloud is more interesting because not all RSS feeds are equal. Popular feeds want frequent refresh; feeds that haven't published in months can be checked weekly. The workflow encodes this with multiple cron lines, a `determine-tier` job that inspects the current hour, and a set of downstream jobs gated on tier outputs:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'   # Daily: standard feeds
    - cron: '0 3 * * 0'   # Weekly Sunday: stale feeds
```

The `determine-tier` job reads `date -u +%H` and emits a `tier` output (`standard`, `stale`, `high`, or `pr-test`); each downstream job has an `if: needs.determine-tier.outputs.runs_standard == 'true'` guard. The result is a single workflow file that the cron scheduler can fire on multiple schedules without duplicating per-tier YAML.

Within a tier, the actual MistKit call is parameterized by the tier's filters:

```yaml
# High-priority tier - matrix of two passes with different popularity thresholds
strategy:
  matrix:
    include:
      - name: "Pass 1: Very popular feeds"
        args: "--update-min-popularity 100 --update-max-failures 2 --update-delay 2.0 --update-limit 100"
      - name: "Pass 2: Popular feeds"
        args: "--update-min-popularity 10 --update-max-failures 5 --update-delay 2.5 --update-limit 100"
```

Those `--update-*` flags map directly to MistKit's `QueryFilter` API - the CLI is just a thin wrapper that converts CLI arguments into filter parameters on the CloudKit query. The same pattern works for any cron job that needs to process "the top N by some metric" without scanning the whole table.

<a id="thundering-herd"></a>
### Avoiding the Thundering Herd

Both repos schedule at non-:00 minute offsets - `17`, `29`, `43` for BushelCloud. This isn't paranoia: GitHub Actions has a real bias toward delaying jobs scheduled at exactly `:00` past common UTC boundaries (top of the hour, midnight UTC), because that's when half the world's cron jobs fire. Picking a prime-ish minute offset typically gets you closer to the actual intended fire time.

[VERIFY: GitHub's official docs note that scheduled workflows can be delayed during periods of high load, particularly at the start of an hour. Quote the current doc text before publishing.]

<a id="concurrency-and-retries"></a>
## Concurrency, Idempotency, and Retries

Both repos use GitHub Actions' `concurrency:` group with `cancel-in-progress: true` to guarantee that a new sync run cancels any older one still in flight:

```yaml
concurrency:
  group: cloudkit-sync-dev
  cancel-in-progress: true
```

This is safe **only because the underlying job is idempotent**. BushelCloud uses deterministic record names based on build numbers and `.forceReplace` operations, so re-running a sync updates existing records instead of creating duplicates. CelestraCloud queries by GUID before upload and skips articles that already exist. Neither cares whether a previous run finished cleanly.

If your job isn't idempotent - say, it appends to a log or increments a counter - you want `cancel-in-progress: false` (the default) and an explicit lock at the application level (e.g. a CloudKit record that acts as a leader-election token).

MistKit itself doesn't do automatic retry on transient CloudKit errors today. For 429 (rate limit) and 503 (transient unavailability), the typical pattern is a small wrapper at the operation site that catches `CloudKitError`, checks the `serverErrorCode`, and retries with exponential backoff:

```swift
func withRetry<T>(_ op: () async throws -> T) async throws -> T {
    var delay: UInt64 = 1_000_000_000  // 1s in nanoseconds
    for attempt in 1...5 {
        do { return try await op() }
        catch let error as CloudKitError
            where error.serverErrorCode == .tooManyRequests
               || error.serverErrorCode == .serviceUnavailable {
            if attempt == 5 { throw error }
            try await Task.sleep(nanoseconds: delay)
            delay *= 2
        }
    }
    fatalError("unreachable")
}
```

[VERIFY: confirm `CloudKitError.serverErrorCode` enum cases are exactly `.tooManyRequests` and `.serviceUnavailable` at publish time - these names may have evolved.]

<a id="observability"></a>
## Observability: Reporting from a Cron Job

The hardest part of a quiet scheduled job is knowing whether it actually ran and what it did. Both repos solve this with two-step reporting: the CLI emits a structured JSON report, and a downstream CI step parses that report into a `$GITHUB_STEP_SUMMARY` (which becomes the rich summary view on the workflow run page).

CelestraCloud's pattern uses a `--update-json-output-path` flag on the CLI:

```bash
./bin/celestra-cloud update \
  --update-limit 5 \
  --update-max-failures 0 \
  --update-json-output-path ./feed-update-pr-test.json
```

A separate `summary` job then `jq`'s the resulting JSON files and writes a markdown summary:

```bash
total_feeds=$(jq -r '.summary.totalFeeds // 0' "$json_file")
success_count=$(jq -r '.summary.successCount // 0' "$json_file")
echo "- **Total Feeds Processed:** $total_feeds" >> $GITHUB_STEP_SUMMARY
echo "- **Successful:** $success_count" >> $GITHUB_STEP_SUMMARY
```

BushelCloud does the same with a `BUSHEL_SYNC_JSON_OUTPUT_FILE` environment variable, plus a per-record-type breakdown of created / updated / failed counts. The summary lives at `$GITHUB_STEP_SUMMARY` and surfaces as the workflow run's "Summary" view in the GitHub UI - no need for an external dashboard or alerting service in the early days of a deployment.

For production alerting, both repos retain the JSON report as a workflow artifact (`actions/upload-artifact@v4` with `retention-days: 30` or `90`), so a separate process - a daily Slack digest, a dashboard scrape, a manual audit - can pull historical results without re-running the job.

For a long-running service, the equivalent is the request-level logging you already have - structured logs flowing into your existing aggregator, plus health-check endpoints that exercise a representative MistKit call so you find out about auth or schema drift before users do.

<a id="dev-vs-prod"></a>
## Dev vs. Prod CloudKit Environments

CloudKit containers expose two parallel environments: `development` and `production`. The MistKit `environment:` parameter on `CloudKitService` (or the `CLOUDKIT_ENVIRONMENT` env var that the example CLIs read) selects which one a given run targets.

The deployment pattern that works in practice:

1. **Two separate workflows or service deployments**, one per environment. BushelCloud has `cloudkit-sync-dev.yml` (scheduled, 3x daily) and `cloudkit-sync-prod.yml` (`workflow_dispatch:` only).
2. **Two sets of secrets**, suffixed `_DEV` and `_PROD` in the repo's secret store. The workflow or container references the appropriate set explicitly - no shared "default" secret that one accidentally cross-contaminates.
3. **Schema changes go through dev first**, deployed via `cktool` and verified by the next scheduled dev sync. Once the dev sync is clean for a day, promote the schema to production and trigger the prod deployment.

This is the same dev/prod hygiene as any backend, just with CloudKit's specific quirk that the schema lives on Apple's infrastructure and has to be promoted explicitly via `cktool` (CloudKit Dashboard or `xcrun cktool deploy-schema-changes`).

[VERIFY: CloudKit schema promotion from dev to prod via `cktool` - check the exact subcommand at publish time, as it has shifted between Xcode versions.]

---

That's the operational picture: pick the right auth method for your workload, build a static binary, inject the credentials from your platform's secrets mechanism, and (for scheduled jobs) make the job idempotent and surface a structured report so you can tell what it did. The [`Examples/BushelCloud`](https://github.com/brightdigit/MistKit/tree/main/Examples/BushelCloud) and [`Examples/CelestraCloud`](https://github.com/brightdigit/MistKit/tree/main/Examples/CelestraCloud) directories in the MistKit repo are working references for everything in this article - both ship with the GitHub Actions workflows referenced above and have been running on schedule for months. Clone either one as a starting point and replace the data layer with your own.

📚 **[View Documentation](https://swiftpackageindex.com/brightdigit/MistKit/documentation)** | 🐙 **[GitHub Repository](https://github.com/brightdigit/MistKit)**
