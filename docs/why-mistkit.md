# Why do I need MistKit?

Apple's CloudKit framework only runs on Apple platforms. MistKit wraps the CloudKit Web Services REST API so that server-side Swift, Linux services, and command-line tools can participate in the same CloudKit ecosystem as your iOS and macOS apps.

### Public Database as a Managed Content Catalog

The most common pattern: a server-side job manages a CloudKit public database that Apple devices query.

**macOS VM restore image catalog (Bushel)**
A Mac management tool stores available macOS VM restore images as CloudKit records. A server-side service adds new images and updates metadata as Apple releases them. Client apps query the public database to discover what's available to download — no custom API needed.

**RSS/feed aggregation (Celestra)**
A server-side service fetches RSS or Atom feeds on a schedule, parses the entries, and writes them as CloudKit records. Apple devices query the public database to get aggregated content, with CloudKit handling sync and delivery.

**Software version catalogs**
Track available Xcode versions, simulator runtimes, or SDK releases. A server-side job writes structured records into CloudKit; developer tools on-device query the public database to show what's available.

**App asset distribution**
A creative app (fonts, templates, themes, presets) stores downloadable asset packs as CloudKit records. A server-side tool manages the catalog — adding packs, updating metadata, deprecating old ones — without requiring an app update.

**Feature flags / remote config**
Store feature flag configurations as CloudKit records. A server-side admin tool writes flag values; Apple devices read them from the public database without needing a dedicated service.

**MDM configuration catalogs**
Configuration profiles, scripts, or policy templates stored in CloudKit public database. A web-based admin console writes and updates them server-side; managed Macs fetch and apply them.

### Private Database: Acting on Behalf of a User

When a user authenticates once and the server stores their web auth token, the server can read and write their CloudKit private database asynchronously — without the user being present. This is the same model as storing OAuth tokens for Gmail or Dropbox access.

**Wearable / peripheral device linking (Heartwitch)**
A user authenticates in the iOS app, and the server stores their web auth token. The server then connects their Apple Watch data to an external service (e.g., a live streaming platform) continuously — reading records the Watch writes to CloudKit and bridging them to the third-party API without requiring active user interaction each time.

**Wearable data pipelines**
An app writes activity or sensor data from an Apple Watch or other device to the user's CloudKit private database. A server reads those records and pushes them to a fitness platform, research database, or coaching service.

**Always-on device presence**
A user's devices write location or status records to their private database. A server monitors those records and triggers actions in another system — fleet tracking, family safety apps, or delivery coordination.

**Two-way sync with external services**
A server reads a user's CloudKit private records and syncs them to genuinely external platforms (Todoist, Notion, Google Calendar, Obsidian) — and writes changes back — acting as a persistent background sync bridge between CloudKit and the rest of the user's toolchain.

**Server-side processing**
A user uploads a photo or document to their private database. A server fetches it, runs processing (OCR, image resizing, transcoding, AI tagging), then writes the results back as new records.

### Web App ↔ Apple Device Bridge

**Web portal for a CloudKit-backed app**
A user signs into a web app with their Apple ID. The server exchanges that web auth token for CloudKit access and reads/writes the user's private database — giving them a browser-based view of their iOS app data without requiring the app to be open.

**Webhook → CloudKit writer**
An external service (Stripe, GitHub, a form submission) triggers a webhook. A server-side Swift handler writes the result directly into a CloudKit record, which instantly syncs to the user's Apple devices.

### Data Aggregation

**Anonymized telemetry**
Devices write anonymized usage events to CloudKit. A server-side job reads those records via `/records/changes`, aggregates them, and stores results elsewhere for analysis — without building a custom ingestion API.

**Crowdsourced data**
Apps contribute data points (WiFi maps, accessibility ratings, transit times) to a CloudKit public database. A server aggregates, deduplicates, and enriches the records, then writes cleaned data back — acting as a background data steward.
