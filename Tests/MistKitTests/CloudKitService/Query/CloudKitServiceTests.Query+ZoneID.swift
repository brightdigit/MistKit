//
//  CloudKitServiceTests.Query+ZoneID.swift
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

extension CloudKitServiceTests.Query {
  /// Coverage for issue #146: `queryRecords` hard-coded `_defaultZone`, making
  /// custom and shared zones unqueryable. The `zoneID` parameter must serialize
  /// into the `records/query` request body — including a shared zone's
  /// `ownerName` — and must be omitted entirely when the caller passes `nil`.
  @Suite("Zone Selection")
  internal struct ZoneIDSelection {
    private static let database: Database = .public(.prefers(.serverToServer))

    /// Builds a service whose transport records request bodies for inspection.
    private static func makeService(
      _ provider: ResponseProvider
    ) throws -> CloudKitService {
      try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
        transport: MockTransport(responseProvider: provider)
      )
    }

    /// The `index`-th request body sent for `operationID`, decoded as a JSON object.
    private static func sentBody(
      for operationID: String,
      from provider: ResponseProvider,
      at index: Int = 0
    ) async throws -> [String: Any] {
      let bodies = await provider.bodies(for: operationID)
      let data = try #require(bodies.compactMap { $0 }.dropFirst(index).first)
      return try #require(
        try JSONSerialization.jsonObject(with: data) as? [String: Any]
      )
    }

    @Test("queryRecords() omits zoneID when none is supplied (default-zone behavior)")
    internal func queryOmitsZoneIDByDefault() async throws {
      let provider = ResponseProvider.successfulQuery()
      let service = try Self.makeService(provider)

      _ = try await service.queryRecords(
        MistKit.Query(recordType: "TestRecord"),
        database: Self.database
      )

      let body = try await Self.sentBody(for: "queryRecords", from: provider)
      // No `zoneID` key at all — CloudKit resolves `_defaultZone` server-side.
      #expect(body["zoneID"] == nil)
    }

    @Test("queryRecords() forwards a custom zone name into the request body")
    internal func queryForwardsCustomZoneName() async throws {
      let provider = ResponseProvider.successfulQuery()
      let service = try Self.makeService(provider)

      _ = try await service.queryRecords(
        MistKit.Query(recordType: "TestRecord"),
        zoneID: ZoneID(zoneName: "CustomZone"),
        database: Self.database
      )

      let body = try await Self.sentBody(for: "queryRecords", from: provider)
      let zoneID = try #require(body["zoneID"] as? [String: Any])
      #expect(zoneID["zoneName"] as? String == "CustomZone")
      #expect(zoneID["ownerName"] == nil)
    }

    @Test("queryRecords() forwards a shared zone's ownerName")
    internal func queryForwardsSharedZoneOwnerName() async throws {
      let provider = ResponseProvider.successfulQuery()
      let service = try Self.makeService(provider)

      _ = try await service.queryRecords(
        MistKit.Query(recordType: "TestRecord"),
        zoneID: ZoneID(zoneName: "SharedZone", ownerName: "_owner-record-name"),
        database: Self.database
      )

      let body = try await Self.sentBody(for: "queryRecords", from: provider)
      let zoneID = try #require(body["zoneID"] as? [String: Any])
      #expect(zoneID["zoneName"] as? String == "SharedZone")
      #expect(zoneID["ownerName"] as? String == "_owner-record-name")
    }

    @Test("queryRecords() forwards ZoneID.defaultZone explicitly when asked")
    internal func queryForwardsExplicitDefaultZone() async throws {
      let provider = ResponseProvider.successfulQuery()
      let service = try Self.makeService(provider)

      _ = try await service.queryRecords(
        MistKit.Query(recordType: "TestRecord"),
        zoneID: .defaultZone,
        database: Self.database
      )

      let body = try await Self.sentBody(for: "queryRecords", from: provider)
      let zoneID = try #require(body["zoneID"] as? [String: Any])
      #expect(zoneID["zoneName"] as? String == "_defaultZone")
    }

    @Test("queryAllRecords() forwards zoneID on every page it fetches")
    internal func queryAllRecordsForwardsZoneIDPerPage() async throws {
      // Page 1 carries a continuation marker so the paginator issues a second
      // request; the queue then falls through to the marker-less default.
      let provider = ResponseProvider(
        defaultResponse: try .successfulQueryResponse(recordCount: 1)
      )
      await provider.enqueue(
        try .successfulQueryResponse(recordCount: 1, continuationMarker: "page-2"),
        for: "queryRecords"
      )
      let service = try Self.makeService(provider)

      _ = try await service.queryAllRecords(
        recordType: "TestRecord",
        zoneID: ZoneID(zoneName: "CustomZone", ownerName: "_owner-record-name"),
        database: Self.database
      )

      let callCount = await provider.callCount(for: "queryRecords")
      #expect(callCount == 2)

      for index in 0..<callCount {
        let body = try await Self.sentBody(for: "queryRecords", from: provider, at: index)
        let zoneID = try #require(body["zoneID"] as? [String: Any])
        #expect(zoneID["zoneName"] as? String == "CustomZone")
        #expect(zoneID["ownerName"] as? String == "_owner-record-name")
      }
    }

    @Test("fetchExistingRecordNames() forwards zoneID into the query it issues")
    internal func fetchExistingRecordNamesForwardsZoneID() async throws {
      let provider = ResponseProvider.successfulQuery()
      let service = try Self.makeService(provider)

      _ = try await service.fetchExistingRecordNames(
        recordType: "TestRecord",
        zoneID: ZoneID(zoneName: "CustomZone"),
        database: Self.database
      )

      let body = try await Self.sentBody(for: "queryRecords", from: provider)
      let zoneID = try #require(body["zoneID"] as? [String: Any])
      #expect(zoneID["zoneName"] as? String == "CustomZone")
    }
  }
}
