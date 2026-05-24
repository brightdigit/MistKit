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

internal import MistKitOpenAPI

/// A CloudKit subscription: the change trigger that produces push notifications.
///
/// Returned by ``CloudKitService/listSubscriptions(database:)`` and
/// ``CloudKitService/lookupSubscriptions(ids:database:)``, and constructed to
/// create new subscriptions via
/// ``CloudKitService/modifySubscriptions(_:database:)``.
///
/// Use ``query(subscriptionID:recordType:filters:sortBy:firesOn:)`` or
/// ``zone(subscriptionID:zoneID:firesOn:)`` to build one; CloudKit Web Services
/// requires the caller to supply the `subscriptionID`.
public struct SubscriptionInfo: Codable, Sendable {
  /// The client-supplied unique identifier for the subscription.
  public let subscriptionID: String
  /// Whether this is a `query` or `zone` subscription.
  public let subscriptionType: SubscriptionType
  /// The watched query, for `query` subscriptions.
  public let query: SubscriptionQuery?
  /// The watched zone, for `zone` subscriptions.
  public let zoneID: ZoneID?
  /// The record-change events that trigger a push.
  public let firesOn: [SubscriptionFireEvent]

  /// The OpenAPI schema representation used when sending this subscription in a
  /// modify request.
  internal var schema: Components.Schemas.Subscription {
    Components.Schemas.Subscription(
      subscriptionID: self.subscriptionID,
      subscriptionType: self.subscriptionType.schemaValue,
      query: self.query?.schema,
      zoneID: self.zoneID.map { Components.Schemas.ZoneID(from: $0) },
      firesOn: self.firesOn.isEmpty ? nil : self.firesOn.map(\.schemaValue)
    )
  }

  /// Initialize a subscription.
  public init(
    subscriptionID: String,
    subscriptionType: SubscriptionType,
    query: SubscriptionQuery? = nil,
    zoneID: ZoneID? = nil,
    firesOn: [SubscriptionFireEvent] = []
  ) {
    self.subscriptionID = subscriptionID
    self.subscriptionType = subscriptionType
    self.query = query
    self.zoneID = zoneID
    self.firesOn = firesOn
  }

  /// Convert a decoded `Subscription` payload into a `SubscriptionInfo`.
  ///
  /// A missing `subscriptionID`/`subscriptionType`, or a `zoneID` without a
  /// `zoneName`, is a conversion failure (logged, asserted in DEBUG, and thrown)
  /// rather than a silently-dropped subscription.
  internal init(from subscription: Components.Schemas.Subscription) throws(ConversionError) {
    guard let subscriptionID = subscription.subscriptionID else {
      try ConversionError.subscriptionMissingID.reportAndThrow()
    }
    guard let subscriptionType = subscription.subscriptionType else {
      try ConversionError.subscriptionMissingType.reportAndThrow()
    }

    let zoneID: ZoneID?
    if let payload = subscription.zoneID {
      guard let zoneName = payload.zoneName else {
        try ConversionError.zoneMissingName.reportAndThrow()
      }
      zoneID = ZoneID(zoneName: zoneName, ownerName: payload.ownerName)
    } else {
      zoneID = nil
    }

    self.init(
      subscriptionID: subscriptionID,
      subscriptionType: SubscriptionType(from: subscriptionType),
      query: subscription.query.map(SubscriptionQuery.init),
      zoneID: zoneID,
      firesOn: subscription.firesOn?.map(SubscriptionFireEvent.init(from:)) ?? []
    )
  }

  /// Build a `query` subscription that fires when matching records change.
  public static func query(
    subscriptionID: String,
    recordType: String,
    filters: [QueryFilter] = [],
    sortBy: [QuerySort] = [],
    firesOn: [SubscriptionFireEvent]
  ) -> SubscriptionInfo {
    SubscriptionInfo(
      subscriptionID: subscriptionID,
      subscriptionType: .query,
      query: SubscriptionQuery(recordType: recordType, filters: filters, sortBy: sortBy),
      firesOn: firesOn
    )
  }

  /// Build a `zone` subscription that fires when any record in a zone changes.
  public static func zone(
    subscriptionID: String,
    zoneID: ZoneID,
    firesOn: [SubscriptionFireEvent] = []
  ) -> SubscriptionInfo {
    SubscriptionInfo(
      subscriptionID: subscriptionID,
      subscriptionType: .zone,
      zoneID: zoneID,
      firesOn: firesOn
    )
  }
}
