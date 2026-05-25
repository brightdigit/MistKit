//
//  SubscriptionInfo+Schema.swift
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

// MARK: - OpenAPI Schema Bridge

extension SubscriptionInfo {
  /// The OpenAPI schema representation used when sending this
  /// subscription in a modify request.
  internal var schema: Components.Schemas.Subscription {
    let querySchema: Components.Schemas.Query?
    let zoneIDSchema: Components.Schemas.ZoneID?
    let firesOnSchema: [Components.Schemas.Subscription.firesOnPayloadPayload]?
    // swiftlint:disable:next discouraged_optional_boolean
    let firesOnceValue: Bool?
    // swiftlint:disable:next discouraged_optional_boolean
    let zoneWideValue: Bool?
    switch kind {
    case .query(let watchedQuery, let firesOn, let firesOnce):
      querySchema = watchedQuery.schema
      zoneIDSchema = nil
      firesOnSchema = firesOn.schemaValues
      firesOnceValue = firesOnce
      zoneWideValue = nil
    case .zone(let zoneIDValue):
      querySchema = nil
      zoneIDSchema = Components.Schemas.ZoneID(from: zoneIDValue)
      firesOnSchema = nil
      firesOnceValue = nil
      zoneWideValue = nil
    case .database:
      // Database-scoped subscription: omit zoneID, set zoneWide=true.
      querySchema = nil
      zoneIDSchema = nil
      firesOnSchema = nil
      firesOnceValue = nil
      zoneWideValue = true
    }
    return Components.Schemas.Subscription(
      subscriptionID: subscriptionID,
      subscriptionType: subscriptionType.schemaValue,
      query: querySchema,
      zoneID: zoneIDSchema,
      zoneWide: zoneWideValue,
      firesOn: firesOnSchema,
      firesOnce: firesOnceValue,
      notificationInfo: notificationInfo?.schema
    )
  }

  /// Convert a decoded `Subscription` payload into a `SubscriptionInfo`.
  ///
  /// A missing `subscriptionID`/`subscriptionType`, a `zoneID` without
  /// a `zoneName`, or a `query` subscription with no `firesOn` events
  /// is a conversion failure (logged, asserted in DEBUG, and thrown)
  /// rather than a silently-dropped subscription.
  internal init(from subscription: Components.Schemas.Subscription) throws(ConversionError) {
    guard let subscriptionID = subscription.subscriptionID else {
      try ConversionError.subscriptionMissingID.reportAndThrow()
    }
    guard let subscriptionType = subscription.subscriptionType else {
      try ConversionError.subscriptionMissingType.reportAndThrow()
    }

    let kind: Kind
    switch SubscriptionType(from: subscriptionType) {
    case .query:
      // Preserve prior behavior: a `query` subscription payload that
      // omits the query body still decodes (callers can inspect the
      // empty `Query` and decide whether to treat it as invalid).
      let query = subscription.query.map(Query.init) ?? Query(Components.Schemas.Query())
      let firesOn = SubscriptionFireEvents(schemaValues: subscription.firesOn ?? [])
      guard !firesOn.isEmpty else {
        try ConversionError.subscriptionQueryMissingFiresOn.reportAndThrow()
      }
      kind = .query(query, firesOn: firesOn, firesOnce: subscription.firesOnce)
    case .zone:
      // CloudKit collapses zone- and database-scoped subscriptions into
      // `subscriptionType: zone`; `zoneWide: true` is the
      // database-subscription marker. Surface them as separate `Kind`
      // cases so callers don't have to know about the wire collapse.
      if subscription.zoneWide == true {
        kind = .database
      } else {
        guard let payload = subscription.zoneID else {
          // A non-wide zone subscription without a zoneID is invalid;
          // surface as missing-zone-name failure for parity with
          // existing behavior.
          try ConversionError.zoneMissingName.reportAndThrow()
        }
        guard let zoneName = payload.zoneName else {
          try ConversionError.zoneMissingName.reportAndThrow()
        }
        kind = .zone(ZoneID(zoneName: zoneName, ownerName: payload.ownerName))
      }
    }

    self.init(
      subscriptionID: subscriptionID,
      kind: kind,
      notificationInfo: subscription.notificationInfo.map(NotificationInfo.init(from:))
    )
  }
}
