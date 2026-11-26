# Subscriptions and Notifications

Create CloudKit subscriptions, mint or register an APNs token, and receive the resulting notifications without a device by long-polling CloudKit's web courier.

## Overview

A CloudKit subscription is a server-side trigger: when a record matching it changes, CloudKit enqueues a push notification. Getting that notification to your code takes three pieces, and MistKit wraps each one:

| Piece | CloudKit endpoint | MistKit API |
| --- | --- | --- |
| The trigger | `subscriptions/list`, `subscriptions/lookup`, `subscriptions/modify` | ``CloudKitService/listSubscriptions(database:)``, ``CloudKitService/lookupSubscriptions(ids:database:)``, ``CloudKitService/modifySubscriptions(_:database:)`` and its single-item conveniences |
| A push destination | `tokens/create`, `tokens/register` | ``CloudKitService/createAPNsToken(environment:clientId:database:)``, ``CloudKitService/registerAPNsToken(_:environment:clientId:database:)`` |
| Delivery without a device | the `webcourierURL` returned by `tokens/create` | ``WebCourierPoller``, ``Courier``, ``CourierNotification`` |

The native CloudKit framework hides the last two pieces: the OS binds the signed-in iCloud account to APNs for you. CloudKit Web Services has no such binding, so a server process or browser client has to supply a token itself.

MistDemo's private-database integration run (`swift run mistdemo test-private`, in `Examples/MistDemo`) exercises all three end to end: `SubscriptionRoundtripPhase` creates, lists, looks up and deletes a query subscription; `TokenRoundtripPhase` creates and registers a token; and `NotificationRoundtripPhase` creates a subscription, mints a courier token, writes a matching record and waits for the push. The samples below follow that code.

## Creating a subscription

``SubscriptionInfo`` mirrors the three native `CKSubscription` classes. Build one with a factory; CloudKit Web Services requires you to choose the `subscriptionID`:

- ``SubscriptionInfo/query(subscriptionID:recordType:filters:sortBy:firesOn:firesOnce:notificationInfo:)`` fires when records matching a query are created, updated or deleted. `firesOn` is a ``SubscriptionFireEvents`` option set and must not be empty: an empty set traps, because a query subscription with no fire events would never trigger.
- ``SubscriptionInfo/zone(subscriptionID:zoneID:notificationInfo:)`` fires on any change in one zone.
- ``SubscriptionInfo/database(subscriptionID:notificationInfo:)`` fires on any change in any zone of the database. CloudKit serves database subscriptions against the private and shared databases only.

``NotificationInfo`` shapes the push CloudKit sends. Every field is optional; leave out a field and CloudKit applies its own default.

```swift
let subscription = SubscriptionInfo.query(
  subscriptionID: "note-changes",
  recordType: "Note",
  filters: [.equals("folder", .string(.value("Inbox")))],
  firesOn: [.create, .update, .delete],
  notificationInfo: NotificationInfo(
    alertBody: "A note changed",
    shouldSendContentAvailable: true
  )
)

let created = try await service.createSubscription(subscription, database: .private)
print("created \(created.subscriptionID) (\(created.subscriptionType))")
```

``CloudKitService/createSubscription(_:database:)`` sends a single `create` operation and returns the subscription CloudKit sends back. A per-subscription failure throws ``CloudKitError/subscriptionOperationFailed(_:)``, or ``CloudKitError/subscriptionLikelyDuplicate(_:)`` when the failure looks like a collision with an existing subscription.

CloudKit Web Services sends only two `subscriptionType` values, `query` and `zone`. A database subscription goes out as `zone` with `zoneWide: true` and no `zoneID`, and MistKit decodes that shape back into ``SubscriptionInfo/Kind/database``, so ``SubscriptionInfo/subscriptionType`` is ``SubscriptionType/zone`` for both zone and database subscriptions. Use ``SubscriptionInfo/kind`` to tell them apart.

> Note: MistDemo's live runs only create **query** subscriptions on the private database. Zone and database subscriptions, and the `update` operation, are covered by unit tests against recorded and hand-written payloads, not by a live run.

### Duplicates

CloudKit decides whether two query subscriptions are the same by `(recordType, firesOn)`, not by `subscriptionID`, and reports a collision as a generic `INTERNAL_ERROR`. MistKit turns that into a hedged ``OperationFailure/isLikelyDuplicate`` hint. The details, and how to reconcile, are in <doc:HandlingErrors#Subscription-duplicates-surface-as-INTERNAL_ERROR>.

MistDemo's `SubscriptionRoundtripPhase` avoids the collision across interrupted runs by deleting leftover subscriptions on the same record type before it creates a new one:

```swift
let existing = try await service.listSubscriptions(database: .private)
for stale in existing where stale.query?.recordType == "Note" {
  try? await service.deleteSubscription(id: stale.subscriptionID, database: .private)
}
```

## Listing, looking up and deleting

```swift
let all = try await service.listSubscriptions(database: .private)
let some = try await service.lookupSubscriptions(ids: ["note-changes"], database: .private)

for subscription in some {
  switch subscription.kind {
  case .query(let query, let firesOn, _):
    print("\(subscription.subscriptionID): \(query.recordType ?? "?"), fires on \(firesOn.rawValue)")
  case .zone(let zoneID):
    print("\(subscription.subscriptionID): zone \(zoneID.zoneName)")
  case .database:
    print("\(subscription.subscriptionID): whole database")
  }
}
print("\(all.count) subscription(s) in total")

try await service.deleteSubscription(id: "note-changes", database: .private)
```

``CloudKitService/deleteSubscription(id:database:)`` throws if CloudKit returns a per-subscription failure for the delete.

## Batch changes and per-subscription failures

``CloudKitService/modifySubscriptions(_:database:)`` sends any mix of ``SubscriptionOperation`` values in one `subscriptions/modify` request. Like `records/modify`, CloudKit answers each operation separately, so the method returns a ``SubscriptionResult`` (an ``OperationResult``) per entry instead of throwing on the first failure. A ``SubscriptionOperationFailure`` carries the server error code, the reason, and the ``OperationFailure/subscriptionID`` it applies to:

```swift
let results = try await service.modifySubscriptions(
  [
    .create(.zone(subscriptionID: "notes-zone", zoneID: ZoneID(zoneName: "NotesZone"))),
    .delete(subscriptionID: "note-changes")
  ],
  database: .private
)

for result in results {
  switch result {
  case .success(let subscription):
    print("saved \(subscription.subscriptionID)")
  case .failure(let failure):
    print("failed \(failure.subscriptionID): \(failure.serverErrorCode.rawValue) \(failure.reason ?? "")")
  }
}
```

CloudKit acknowledges a successful delete with a bare `{ subscriptionID }` entry and no `subscriptionType`. That is not a subscription, so MistKit leaves it out of the results: expect one entry per created or updated subscription and per failure, not one per operation. Call ``OperationResult/get()`` to turn an entry into the subscription or a thrown ``CloudKitError/subscriptionOperationFailed(_:)``.

## Getting a push destination

A subscription only produces notifications for APNs tokens CloudKit knows about in that container. There are two ways to give it one:

- **No device:** ``CloudKitService/createAPNsToken(environment:clientId:database:)`` asks CloudKit to mint a token. The ``APNsTokenResult`` carries the ``APNsTokenResult/apnsToken``, the echoed ``APNsTokenResult/environment``, and a ``APNsTokenResult/webcourierURL`` you can long-poll for notifications. This is how CloudKit JS in a browser receives pushes.
- **A real device:** an iOS or macOS app registers with APNs the usual way and sends its hex token to your server, which passes it to ``CloudKitService/registerAPNsToken(_:environment:clientId:database:)``.

MistDemo's notification probe does both with the minted token: it creates a token, then registers that same token, the pair CloudKit JS performs in `registerForNotifications()`:

```swift
let clientId = UUID().uuidString

let token = try await service.createAPNsToken(
  environment: .development,
  clientId: clientId,
  database: .private
)
try await service.registerAPNsToken(
  token.apnsToken,
  environment: token.environment,
  clientId: clientId,
  database: .private
)
```

- **`environment`** is an ``APNsEnvironment``: ``APNsEnvironment/development`` is the APNs sandbox, paired with CloudKit's `development` environment, and ``APNsEnvironment/production`` is paired with `production`. For a device token it must match the environment the device registered under.
- **`clientId`** identifies one logical client. Pass the same value to both calls to tie them together; leave it `nil` and MistKit generates a fresh UUID for each call. An empty or whitespace-only `clientId` (or `apnsToken`) throws ``CloudKitError/badRequest(reason:)`` before any request is sent.
- **`database`** chooses only which credentials sign the request. The token endpoints are container-scoped: their path is `/device/{version}/{container}/{environment}/tokens/…`, with no database segment. Apple's archived reference documents them under `/database/…`, but the live service returns `405 Method Not Allowed` for a POST there; `/device/` is the path CloudKit JS uses.

## Receiving notifications without a device

The `webcourierURL` is a long-poll endpoint: a GET waits until a notification is queued for the token, or until it times out. ``WebCourierPoller`` binds that URL to an HTTP transport, and its ``WebCourierPoller/notifications()`` stream re-polls until the consuming task is cancelled. MistDemo filters the stream by subscription, because every subscription on the record type fires for the same change:

```swift
let poller = WebCourierPoller(courierURL: token.webcourierURL)

for try await notification in poller.notifications()
where notification.subscriptionID == "note-changes" {
  let reason = notification.reason.map { "\($0)" } ?? "unknown"
  print("record \(notification.recordName ?? "?") changed: \(reason)")
  break
}
```

What the courier gives you, as MistKit documents it:

- **Each notification is delivered once.** The courier is consume-on-delivery: a poll removes the notification it returns and never sends it again. The stream therefore does no de-duplication, and you should not key on ``CourierNotification/notificationID`` either: one change that matches several subscriptions queues several notifications that share a notification ID and differ by ``CourierNotification/subscriptionID``.
- **Only query notifications are decoded.** ``CourierNotification`` maps the `ck.qry` block: subscription ID, record name, zone, container, alert text, and the ``CourierNotification/Reason`` (created, updated, deleted). A zone notification would arrive in a different block that MistKit does not map yet. ``CourierNotification/databaseScope`` is kept as the raw number because its meaning is unconfirmed.
- **Empty answers are not errors.** ``WebCourierPoller/pollOnce()`` returns `nil` for a keepalive or a body it can't decode, and the stream waits a quarter of a second and polls again. A non-2xx status, such as an expired token, throws ``CloudKitError/httpError(statusCode:)`` so a persistent failure ends the stream instead of looping.
- **Delivery is eventual.** The stream never times out on its own. MistDemo wraps the wait in a 45-second timeout and treats a missing push as an inconclusive result rather than a failure.

### Choosing the transport

``WebCourierPoller`` can be built three ways:

- ``WebCourierPoller/init(courierURL:perPollTimeout:configuration:)`` creates its own `URLSession`, from ``WebCourierPoller/ephemeralConfiguration`` by default. This is the form MistDemo uses.
- ``WebCourierPoller/init(courierURL:perPollTimeout:session:)`` uses a session you supply for every poll.
- ``WebCourierPoller/init(courierURL:perPollTimeout:transport:)`` takes any ``Courier/Transport`` closure, such as one backed by another HTTP client, or a stub in tests.

Whichever you choose, keep the courier off the transport your ``CloudKitService`` uses. The courier is a different host from `api.apple-cloudkit.com`, and sharing an HTTP/2 connection between the two hosts causes `421 Misdirected Request`, the same reason asset uploads use a separate ``AssetUploader``. The two `URLSession` forms need macOS 12, iOS 15, tvOS 15 or watchOS 8; ``Courier`` and ``WebCourierPoller`` are not available on WASI.

``Courier`` holds the same operations as static functions, for when you don't want a poller value. A stub transport makes the decoding easy to test:

```swift
let stub: Courier.Transport = { _, _ in
  let body = #"{"ck":{"nid":"n1","qry":{"sid":"note-changes","rid":"note-1","fo":1}}}"#
  return (statusCode: 200, data: Data(body.utf8))
}

let notification = try await Courier.pollOnce(courierURL: courierURL, transport: stub)
print(notification?.reason == .recordCreated)  // true
```

## Topics

### Subscriptions

- ``SubscriptionInfo``
- ``SubscriptionType``
- ``SubscriptionFireEvents``
- ``NotificationInfo``
- ``SubscriptionOperation``

### Per-subscription results

- ``SubscriptionResult``
- ``SubscriptionOperationFailure``
- ``SubscriptionTarget``

### Push tokens

- ``APNsTokenResult``
- ``APNsEnvironment``

### Receiving notifications

- ``WebCourierPoller``
- ``Courier``
- ``CourierNotification``

## See Also

- <doc:HandlingErrors>
- <doc:AuthenticationAndDatabases>
- <doc:BuildingQueries>
