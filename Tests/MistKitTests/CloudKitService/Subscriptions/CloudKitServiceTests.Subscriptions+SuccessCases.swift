//
//  CloudKitServiceTests.Subscriptions+SuccessCases.swift
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
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.Subscriptions {
  @Suite("Success Cases")
  internal struct SuccessCases {
    private static let database: Database = .public(.prefers(.serverToServer))

    @Test("listSubscriptions() decodes query and zone subscriptions")
    internal func listDecodesBoth() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Subscriptions.makeService(
        returningJSON: CloudKitServiceTests.Subscriptions.sampleListJSON
      )

      let subscriptions = try await service.listSubscriptions(database: Self.database)

      #expect(subscriptions.count == 2)
      let query = try #require(subscriptions.first { $0.subscriptionType == .query })
      #expect(query.subscriptionID == "query-sub")
      #expect(query.query?.recordType == "Article")
      #expect(query.firesOn == [.create, .update])

      let zone = try #require(subscriptions.first { $0.subscriptionType == .zone })
      #expect(zone.zoneID == ZoneID(zoneName: "Photos", ownerName: "_defaultOwner"))
      // Zone subscriptions don't carry firesOn — only query subscriptions
      // do. The wire field is ignored for `.zone` / `.database` kinds.
      #expect(zone.firesOn.isEmpty)
    }

    @Test("lookupSubscriptions() returns the matching subscriptions")
    internal func lookupReturnsMatches() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Subscriptions.makeService(
        returningJSON: CloudKitServiceTests.Subscriptions.sampleListJSON
      )

      let subscriptions = try await service.lookupSubscriptions(
        ids: ["query-sub", "zone-sub"],
        database: Self.database
      )
      #expect(subscriptions.count == 2)
    }

    @Test("modifySubscriptions() returns the created subscription")
    internal func modifyReturnsCreated() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let json = """
        {
          "subscriptions": [
            {
              "subscriptionID": "new-sub",
              "subscriptionType": "query",
              "query": { "recordType": "Article" },
              "firesOn": ["create"]
            }
          ]
        }
        """
      let service = try CloudKitServiceTests.Subscriptions.makeService(returningJSON: json)

      let created = try await service.createSubscription(
        .query(
          subscriptionID: "new-sub",
          recordType: "Article",
          firesOn: [.create]
        ),
        database: Self.database
      )
      #expect(created.subscriptionID == "new-sub")
      #expect(created.query?.recordType == "Article")
    }

    @Test("deleteSubscription() completes against a deletion-acknowledgement response")
    internal func deleteCompletes() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // CloudKit echoes a deleted subscription as a bare `{ subscriptionID }`
      // entry with no `subscriptionType` — the real deletion-ack shape.
      let service = try CloudKitServiceTests.Subscriptions.makeService(
        returningJSON: #"{ "subscriptions": [{ "subscriptionID": "query-sub" }] }"#
      )
      try await service.deleteSubscription(id: "query-sub", database: Self.database)
    }

    @Test("modifySubscriptions() filters deletion acknowledgements out of its results")
    internal func modifyFiltersDeletionAcks() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // A bare `{ subscriptionID }` ack (no `subscriptionType`) is a deletion
      // acknowledgement, not a result, so it is dropped from the returned array.
      let service = try CloudKitServiceTests.Subscriptions.makeService(
        returningJSON: #"{ "subscriptions": [{ "subscriptionID": "query-sub" }] }"#
      )

      let results = try await service.modifySubscriptions(
        [.delete(subscriptionID: "query-sub")],
        database: Self.database
      )

      #expect(results.isEmpty)
    }
  }
}
