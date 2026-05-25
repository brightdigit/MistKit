//
//  SubscriptionInfo.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

/// A CloudKit subscription: the change trigger that produces push
/// notifications.
///
/// A subscription is one of three kinds — query, zone, or database —
/// mirroring the native CKSubscription subclasses. Variant-specific
/// data (the watched query, `firesOn` set, `firesOnce` flag, watched
/// zone) lives inside ``Kind``. Only `subscriptionID` and
/// `notificationInfo` are shared on the outer struct.
///
/// Use ``query(subscriptionID:recordType:filters:sortBy:firesOn:firesOnce:notificationInfo:)``,
/// ``zone(subscriptionID:zoneID:notificationInfo:)``, or
/// ``database(subscriptionID:notificationInfo:)`` to build one;
/// CloudKit Web Services requires the caller to supply the
/// `subscriptionID`.
// `Bool?` is used intentionally — `nil` means "don't set the field;
// let CloudKit apply its server-side default" (e.g. `firesOnce`).
// swiftlint:disable discouraged_optional_boolean

public struct SubscriptionInfo: Sendable {
  /// The variant-specific data for a subscription. Mirrors the three
  /// native CloudKit subscription classes:
  /// - ``query(_:firesOn:firesOnce:)`` ⇄ `CKQuerySubscription`
  /// - ``zone(_:)`` ⇄ `CKRecordZoneSubscription`
  /// - ``database`` ⇄ `CKDatabaseSubscription`
  ///
  /// `firesOn` and `firesOnce` only live on the `.query` case because
  /// native CKSubscription only exposes them on `CKQuerySubscription`;
  /// zone and database subscriptions fire on any change in their scope.
  ///
  /// CloudKit Web Services only ships two `subscriptionType` values
  /// over the wire — `query` and `zone`. The `.database` case
  /// serializes as `subscriptionType: "zone"` with `zoneWide: true`
  /// and no specific `zoneID`. CloudKit serves database subscriptions
  /// only against private and shared databases.
  public enum Kind: Sendable {
    /// A query subscription that fires when records matching the
    /// embedded query change. `firesOn` must be non-empty — a query
    /// subscription with no fire events would never trigger; the
    /// public factory and ``SubscriptionInfo/init(subscriptionID:kind:notificationInfo:)``
    /// `precondition`-trap empty sets, and the schema/Codable decoders
    /// throw on the same.
    case query(Query, firesOn: SubscriptionFireEvents, firesOnce: Bool? = nil)

    /// A zone subscription that fires when any record in the named
    /// zone changes.
    case zone(ZoneID)

    /// A database subscription that fires when records in *any* zone
    /// in the database change (wire: `subscriptionType: "zone"`,
    /// `zoneWide: true`). Private and shared databases only.
    case database
  }

  /// The client-supplied unique identifier for the subscription.
  public let subscriptionID: String

  /// The variant — query, zone, or database — and its variant-specific
  /// data.
  public let kind: Kind

  /// How CloudKit should shape the push notification when this
  /// subscription fires. `nil` means "use CloudKit defaults".
  public let notificationInfo: NotificationInfo?

  /// Creates a subscription explicitly from a ``Kind`` and the shared
  /// properties. Traps if ``Kind/query(_:firesOn:firesOnce:)`` carries
  /// an empty `firesOn` set.
  public init(
    subscriptionID: String,
    kind: Kind,
    notificationInfo: NotificationInfo? = nil
  ) {
    if case .query(_, let firesOn, _) = kind {
      precondition(!firesOn.isEmpty, "Query subscription firesOn must not be empty.")
    }
    self.subscriptionID = subscriptionID
    self.kind = kind
    self.notificationInfo = notificationInfo
  }

  /// Build a `query` subscription that fires when matching records
  /// change. `firesOn` must be non-empty — passing `[]` traps.
  public static func query(
    subscriptionID: String,
    recordType: String,
    filters: [QueryFilter] = [],
    sortBy: [QuerySort] = [],
    firesOn: SubscriptionFireEvents,
    firesOnce: Bool? = nil,
    notificationInfo: NotificationInfo? = nil
  ) -> SubscriptionInfo {
    SubscriptionInfo(
      subscriptionID: subscriptionID,
      kind: .query(
        Query(recordType: recordType, filters: filters, sortBy: sortBy),
        firesOn: firesOn,
        firesOnce: firesOnce
      ),
      notificationInfo: notificationInfo
    )
  }

  /// Build a `zone` subscription that fires when any record in a zone
  /// changes. For a database-wide subscription, use
  /// ``database(subscriptionID:notificationInfo:)`` instead.
  public static func zone(
    subscriptionID: String,
    zoneID: ZoneID,
    notificationInfo: NotificationInfo? = nil
  ) -> SubscriptionInfo {
    SubscriptionInfo(
      subscriptionID: subscriptionID,
      kind: .zone(zoneID),
      notificationInfo: notificationInfo
    )
  }

  /// Build a `database` subscription that fires when records in *any*
  /// zone in the current database change. Wire representation is
  /// `subscriptionType: "zone"` with `zoneWide: true`. Private and
  /// shared databases only — CloudKit rejects database subscriptions
  /// against the public database.
  public static func database(
    subscriptionID: String,
    notificationInfo: NotificationInfo? = nil
  ) -> SubscriptionInfo {
    SubscriptionInfo(
      subscriptionID: subscriptionID,
      kind: .database,
      notificationInfo: notificationInfo
    )
  }
}

// MARK: - Derived Accessors

extension SubscriptionInfo {
  /// The wire-level `subscriptionType` — `.query` for query
  /// subscriptions, `.zone` for both zone and database subscriptions
  /// (CloudKit Web Services has no separate `database` wire value).
  /// Derived from ``kind``.
  public var subscriptionType: SubscriptionType {
    switch kind {
    case .query: return .query
    case .zone, .database: return .zone
    }
  }

  /// The watched query, when this is a `.query` subscription.
  /// `nil` for zone and database subscriptions.
  public var query: Query? {
    if case .query(let query, _, _) = kind {
      return query
    }
    return nil
  }

  /// The set of record-change events that fire this subscription
  /// (query subscriptions only). Empty for zone and database
  /// subscriptions, which fire on any change in their scope.
  public var firesOn: SubscriptionFireEvents {
    if case .query(_, let firesOn, _) = kind {
      return firesOn
    }
    return []
  }

  /// The `firesOnce` flag for a `.query` subscription. `nil` for zone
  /// and database subscriptions (the wire field doesn't apply) or when
  /// not set.
  public var firesOnce: Bool? {
    if case .query(_, _, let firesOnce) = kind {
      return firesOnce
    }
    return nil
  }

  /// The watched zone, when this is a `.zone` subscription.
  /// `nil` for query and database subscriptions.
  public var zoneID: ZoneID? {
    if case .zone(let zoneID) = kind {
      return zoneID
    }
    return nil
  }

  /// `true` for a `.database` subscription (wire: `zoneWide: true`),
  /// `nil` otherwise — query and specific-zone subscriptions do not
  /// carry the flag.
  public var zoneWide: Bool? {
    if case .database = kind {
      return true
    }
    return nil
  }
}

// MARK: - Codable (wire-compatible flat encoding)

extension SubscriptionInfo: Codable {
  private enum CodingKeys: String, CodingKey {
    case subscriptionID
    case subscriptionType
    case query
    case zoneID
    case zoneWide
    case firesOn
    case firesOnce
    case notificationInfo
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.subscriptionID = try container.decode(String.self, forKey: .subscriptionID)
    self.notificationInfo =
      try container.decodeIfPresent(NotificationInfo.self, forKey: .notificationInfo)

    let type = try container.decode(SubscriptionType.self, forKey: .subscriptionType)
    switch type {
    case .query:
      let query = try container.decode(Query.self, forKey: .query)
      let firesOn =
        try container.decodeIfPresent(SubscriptionFireEvents.self, forKey: .firesOn) ?? []
      guard !firesOn.isEmpty else {
        throw DecodingError.dataCorrupted(
          .init(
            codingPath: decoder.codingPath + [CodingKeys.firesOn],
            debugDescription:
              "Query subscription missing or empty firesOn — must declare "
              + "at least one of [create, update, delete]."
          )
        )
      }
      let firesOnce = try container.decodeIfPresent(Bool.self, forKey: .firesOnce)
      self.kind = .query(query, firesOn: firesOn, firesOnce: firesOnce)
    case .zone:
      // CloudKit collapses both "watch one zone" and "watch the whole
      // database" into `subscriptionType: zone`; `zoneWide: true` is
      // the database-subscription marker. Read it as `.database` so the
      // domain side preserves the native CKSubscription trichotomy.
      let wide = try container.decodeIfPresent(Bool.self, forKey: .zoneWide) ?? false
      if wide {
        self.kind = .database
      } else {
        let zoneID = try container.decode(ZoneID.self, forKey: .zoneID)
        self.kind = .zone(zoneID)
      }
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(subscriptionID, forKey: .subscriptionID)
    try container.encode(subscriptionType, forKey: .subscriptionType)
    try container.encodeIfPresent(notificationInfo, forKey: .notificationInfo)
    switch kind {
    case .query(let query, let firesOn, let firesOnce):
      try container.encode(query, forKey: .query)
      try container.encode(firesOn, forKey: .firesOn)
      try container.encodeIfPresent(firesOnce, forKey: .firesOnce)
    case .zone(let zoneID):
      try container.encode(zoneID, forKey: .zoneID)
    case .database:
      try container.encode(true, forKey: .zoneWide)
    }
  }
}

// swiftlint:enable discouraged_optional_boolean

// The OpenAPI schema bridge lives in `SubscriptionInfo+Schema.swift`.
