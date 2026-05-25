# Web-Courier Wire-Format Spike (#379)

## Goal

Capture the **CloudKit web-courier long-poll protocol** by observing CloudKit
JS do it in a browser, so we can replicate it in:

- `WebCourierPoller` (Swift) — the headless integration-test receiver, and
- a `fetch` loop in `tokens.js` — MistKit-mode reception parity in the web app.

Apple documents the *parsed* `CloudKit.Notification` object but **not** the
courier transport. This spike fills that gap. Three unknowns to resolve:

1. **Request shape** — the exact URL + query params + headers CloudKit JS sends
   on each courier `GET`.
2. **Response framing** — the body shape when a notification is delivered vs.
   an empty keepalive/timeout, and the HTTP status in each case.
3. **The cursor** — how the *next* poll differs from the first so the courier
   doesn't redeliver (a token/marker in the URL, a header, or the body).

> Why observe CloudKit JS instead of blind-polling: the web app already wires
> `registerForNotifications()` + `addNotificationListener` in CloudKit JS mode
> (`Sources/MistDemoKit/Resources/js/tokens.js:42-55`). Watching it on the wire
> shows the real request params and cursor handling — far more reliable than
> guessing.

## Findings so far

**Unknown #1 (request shape) — SOLVED.** `tokens/create` returns a
self-contained courier URL; you `GET` it verbatim, no extra params/headers:

```
https://webcourier.sandbox.push.apple.com:443/aps?tok=<apnsToken>&ttl=43200
```

- Host is **APNs' web-courier** (Safari-push long-poll infra), *not* a CloudKit
  host. `.sandbox.` = development; production is `webcourier.push.apple.com`.
- `tok` = the `apnsToken` verbatim; `ttl=43200` = token valid 12h (a long-lived
  poller must re-mint before expiry).
- Confirms `WebCourierPoller.pollOnce()`'s design (GET the URL as-is).

> ⚠️ The `apnsToken` and the browser's web-auth session cookie are **live
> secrets** — never paste the literal values into this file, commits, or issues.

**Unknown #2 (framing) — SOLVED.** HTTP 200 with a single JSON object per poll:

```jsonc
{ "aps": { "alert": "…" },              // OPTIONAL — only when the subscription set an alert
  "ck":  { "nid": "…",  "cid": "…",     // notificationID, containerIdentifier
           "ckuserid": "…", "ce": 2,    // caller user id; "ce" = protocol/env code (unconfirmed)
           "qry": { "sid": "…",         // subscriptionID
                    "rid": "…",         // recordName
                    "fo": 1,            // fires-on: 1=created 2=updated 3=deleted
                    "zid": "…", "dbs": 1, "zoid": "…" } } }
```

**Unknown #3 (cursor) — SOLVED: there is no cursor.** The courier is a
**consume-on-delivery FIFO queue**. Each `GET` pops exactly **one** queued
notification; when the queue is empty the request long-polls (hangs) until a new
push arrives. No ack/marker/`since` param is involved — re-`GET`ting the same URL
just drains the next item.

> ⚠️ `nid` is **not** unique per delivery. One change matching N subscriptions
> enqueues N notifications that **share a `nid`** but differ by `sid` (verified:
> two back-to-back polls returned the same `nid`/`rid` with different `sid`s).
> So consumers must **not** de-dup on `nid` — `WebCourierPoller.notifications()`
> therefore does no de-duplication.

> NOTE: the courier `GET` only appears in **CloudKit JS mode** (in MistKit mode
> the browser doesn't poll it — that's the reception gap). Use CloudKit JS mode
> for the DevTools route, or the direct-`curl` route which sidesteps the browser.

### Fast path: long-poll the courier directly

Precondition: a `Note` subscription exists (create/update/delete) **and** this
token is registered (the MistKit-mode tokens panel does create+register).

```bash
# Terminal 1 — hangs until a push arrives, then prints the frame:
curl -N 'https://webcourier.sandbox.push.apple.com:443/aps?tok=<apnsToken>&ttl=43200'

# Terminal 2 — fire the subscription:
swift run mistdemo create        # defaults to a Note
```

Re-run Terminal 1 after a delivery to see whether the next poll differs (cursor).
Expect an APNs payload: an `aps` dict + a `ck` dict carrying the CloudKit
notification (`subscriptionID`, record name, fire reason).

## Prerequisites

- CloudKit credentials in `Examples/MistDemo/.env` (see `CLAUDE.md` → MistDemo
  Configuration). For the web app you need at minimum:
  ```
  CLOUDKIT_CONTAINER_ID=iCloud.com.yourorg.yourapp
  CLOUDKIT_ENVIRONMENT=development
  CLOUDKIT_API_TOKEN=…
  CLOUDKIT_WEB_AUTH_TOKEN=…
  ```
- A record type to subscribe to (the demo uses `Note`).
- A browser with DevTools (Chrome/Safari/Firefox all fine).

## Procedure

1. **Start the web app** from `Examples/MistDemo`:
   ```bash
   swift run mistdemo web        # serves http://localhost:8080 by default
   ```
   Open the page and **switch the mode toggle to "CloudKit JS"** (this routes
   the panels through Apple's SDK in the browser, not through `/api/*`).

2. **Authenticate** via the auth panel (CloudKit JS `setUpAuth` / sign-in).

3. **Create a query subscription** in the subscriptions panel:
   - record type: `Note`
   - fires on: **create, update, delete** — i.e. *any* change to a `Note`.
   - note the `subscriptionID` it returns.
   - For the capture itself, a **create** is the simplest single action to fire
     it (step 6); once the wire format is confirmed, the same subscription also
     delivers on updates and deletes.

4. **Open DevTools → Network tab.** Then:
   - Enable **"Preserve log"** (long-polls reopen repeatedly; without this the
     entries get cleared and you lose the cursor progression).
   - Filter to the CloudKit host (type `cloudkit` or `icloud` in the filter).

5. **Click "Register for notifications"** in the tokens panel. In the Network
   tab you should now see, in order:
   - a `POST …/tokens/create` (returns `apnsToken` + `webcourierURL`), and
   - the **first courier `GET`** against that `webcourierURL`, left *pending*
     (this is the long-poll holding open).

6. **Trigger a notification.** In a second browser tab, or from the CLI:
   ```bash
   swift run mistdemo create     # creates a Note → fires the subscription
   ```
   Within a few seconds the pending courier `GET` should **resolve with a body**,
   and CloudKit JS should immediately open the **next** courier `GET`.

7. **Capture three requests** from the Network tab (right-click → "Copy as
   cURL", or export the whole session as **HAR**):
   - the `tokens/create` POST (request body + response),
   - the **first** courier `GET` (the empty/keepalive one, if any), and
   - the courier `GET` that **delivered** the notification, plus the **next**
     `GET` after it (to see the cursor advance).

## What to record (paste into issue #379)

For each courier `GET`:

```
URL (full, incl. query params): ______________________________________________
Method / headers of interest:   ______________________________________________
HTTP status:                    ______________________________________________
Response body (verbatim):       ______________________________________________
```

Then answer the three unknowns:

- [ ] **Request shape** — what query params/headers identify the token? Is the
      `apnsToken` in the URL, a header, or implicit via cookie/session?
- [ ] **Response framing** — JSON object? array of notifications? What does an
      *empty* poll (timeout/keepalive) return — empty body? `204`? `{}`?
- [ ] **Cursor** — what changes between the delivering `GET` and the next one?
      (a `?…token=` / `?…ck=` param, a sequence number in the prior body, etc.)
- [ ] **Notification body → documented fields** — confirm the wire body maps to
      `subscriptionID`, `notificationType`, `queryNotificationReason`,
      `recordName`, `zoneID` (the `CloudKit.Notification` fields).

## How findings feed the code

| Finding | Lands in |
|---|---|
| Request URL/params/headers | `WebCourierPoller.pollOnce()` request construction |
| Response framing + empty-poll detection | `CourierFrame` parsing + `waitForFrame()` empty check |
| Cursor handling | new `nextURL`/`cursor` plumbing in `WebCourierPoller` loop |
| Notification body shape | a `Decodable` `CourierNotification` model (mirrors `CloudKit.Notification`) |
| Confirmation it's browser-reachable | greenlights the `tokens.js` MistKit-mode `fetch` loop (no server proxy) |

Once the cursor + framing are known, `WebCourierPoller` can graduate from a raw
frame probe into a real notification stream, and the same parsing drops into the
web app's JS.
