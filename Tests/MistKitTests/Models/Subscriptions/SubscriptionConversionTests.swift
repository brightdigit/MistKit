//
//  SubscriptionConversionTests.swift
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

internal import Foundation
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

@Suite("Subscription ⇄ OpenAPI Conversion")
internal struct SubscriptionConversionTests {
  /// Runs `body`, expecting it to throw `error`, with the DEBUG assertion
  /// handler suppressed so the throw is observed rather than trapped.
  private func expectThrow<E: Error & Equatable>(
    _ error: E,
    _ body: () throws -> Void
  ) {
    ConversionFailureReporter.$assertionHandler.withValue(
      { _, _, _ in },
      operation: {
        #expect(throws: error) {
          try body()
        }
      }
    )
  }

  @Test("query SubscriptionInfo round-trips through the OpenAPI schema")
  internal func queryRoundTrip() throws {
    let info = SubscriptionInfo.query(
      subscriptionID: "sub-1",
      recordType: "Article",
      filters: [.equals("published", .string("true"))],
      sortBy: [.ascending("title")],
      firesOn: [.create, .update]
    )

    let schema = info.schema
    #expect(schema.subscriptionID == "sub-1")
    #expect(schema.subscriptionType == .query)
    #expect(schema.query?.recordType == "Article")
    #expect(schema.query?.filterBy?.count == 1)
    #expect(schema.query?.sortBy?.count == 1)
    #expect(schema.firesOn == [.create, .update])
    #expect(schema.zoneID == nil)

    let recovered = try SubscriptionInfo(from: schema)
    #expect(recovered.subscriptionID == "sub-1")
    #expect(recovered.subscriptionType == .query)
    #expect(recovered.query?.recordType == "Article")
    #expect(recovered.zoneID == nil)
    #expect(recovered.firesOn == [.create, .update])
  }

  @Test("zone SubscriptionInfo round-trips through the OpenAPI schema")
  internal func zoneRoundTrip() throws {
    let info = SubscriptionInfo.zone(
      subscriptionID: "sub-zone",
      zoneID: ZoneID(zoneName: "Photos", ownerName: "_owner")
    )

    let schema = info.schema
    #expect(schema.subscriptionType == .zone)
    #expect(schema.zoneID?.zoneName == "Photos")
    #expect(schema.zoneID?.ownerName == "_owner")
    #expect(schema.query == nil)
    // Zone subscriptions don't carry firesOn — only `.query` does.
    #expect(schema.firesOn == nil)

    let recovered = try SubscriptionInfo(from: schema)
    let recoveredType: SubscriptionType = recovered.subscriptionType
    #expect(recoveredType == .zone)
    #expect(recovered.zoneID == ZoneID(zoneName: "Photos", ownerName: "_owner"))
    #expect(recovered.query == nil)
    #expect(recovered.firesOn.isEmpty)
  }

  @Test("database SubscriptionInfo round-trips through the OpenAPI schema")
  internal func databaseRoundTrip() throws {
    let info = SubscriptionInfo.database(subscriptionID: "db-1")

    let schema = info.schema
    // A database-scoped subscription is a `zone` type with `zoneWide: true`
    // and no `zoneID`.
    #expect(schema.subscriptionType == .zone)
    #expect(schema.zoneWide == true)
    #expect(schema.zoneID == nil)
    #expect(schema.query == nil)
    #expect(schema.firesOn == nil)

    let recovered = try SubscriptionInfo(from: schema)
    #expect(recovered.subscriptionID == "db-1")
    #expect(recovered.subscriptionType == .zone)
    #expect(recovered.zoneID == nil)
    guard case .database = recovered.kind else {
      Issue.record("expected .database kind, got \(recovered.kind)")
      return
    }
  }

  @Test("missing subscriptionID is a conversion failure")
  internal func missingIDThrows() throws {
    expectThrow(ConversionError.subscriptionMissingID) {
      _ = try SubscriptionInfo(from: Components.Schemas.Subscription(subscriptionType: .query))
    }
  }

  @Test("missing subscriptionType is a conversion failure")
  internal func missingTypeThrows() throws {
    expectThrow(ConversionError.subscriptionMissingType) {
      _ = try SubscriptionInfo(from: Components.Schemas.Subscription(subscriptionID: "x"))
    }
  }

  @Test("zone subscription without a zoneName is a conversion failure")
  internal func zoneWithoutNameThrows() throws {
    let payload = Components.Schemas.Subscription(
      subscriptionID: "z",
      subscriptionType: .zone,
      zoneID: Components.Schemas.ZoneID(ownerName: "_owner")
    )
    expectThrow(ConversionError.zoneMissingName) {
      _ = try SubscriptionInfo(from: payload)
    }
  }

  @Test("SubscriptionOperation maps to the matching operationType")
  internal func operationMapping() throws {
    let info = SubscriptionInfo.query(
      subscriptionID: "op", recordType: "T", firesOn: [.create]
    )

    let create = Components.Schemas.SubscriptionOperation(from: .create(info))
    #expect(create.operationType == .create)
    #expect(create.subscription?.subscriptionID == "op")

    let update = Components.Schemas.SubscriptionOperation(from: .update(info))
    #expect(update.operationType == .update)

    let delete = Components.Schemas.SubscriptionOperation(from: .delete(subscriptionID: "gone"))
    #expect(delete.operationType == .delete)
    #expect(delete.subscription?.subscriptionID == "gone")
  }

  @Test("query subscription without firesOn is a conversion failure")
  internal func queryMissingFiresOnThrows() throws {
    // A `query` subscription must declare at least one fire event — an
    // empty `firesOn` would never trigger, so we surface it as a
    // conversion failure rather than silently decoding into a useless
    // subscription.
    let payload = Components.Schemas.Subscription(
      subscriptionID: "n", subscriptionType: .query
    )
    expectThrow(ConversionError.subscriptionQueryMissingFiresOn) {
      _ = try SubscriptionInfo(from: payload)
    }
  }

  @Test("zone subscription without firesOn decodes fine")
  internal func zoneFiresOnNotRequired() throws {
    // Zone (and database) subscriptions don't carry firesOn — only
    // `.query` does. A zone payload without firesOn must still decode.
    let payload = Components.Schemas.Subscription(
      subscriptionID: "n",
      subscriptionType: .zone,
      zoneID: Components.Schemas.ZoneID(zoneName: "MyZone")
    )
    let recovered = try SubscriptionInfo(from: payload)
    #expect(recovered.firesOn.isEmpty)
    #expect(recovered.zoneID?.zoneName == "MyZone")
  }
}
