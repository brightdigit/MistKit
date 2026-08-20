//
//  CloudKitServiceTests.FetchRecordZoneChanges+Pagination.swift
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

extension CloudKitServiceTests.FetchRecordZoneChanges {
  @Suite("Pagination")
  internal struct Pagination {
    private typealias Harness = CloudKitServiceTests.FetchRecordZoneChanges

    private static let operationID = "fetchRecordZoneChanges"

    /// Builds a service whose `changes/zone` responses are the given rounds,
    /// in order.
    private static func makeService(
      rounds: [[[String: Any]]]
    ) async throws -> CloudKitService {
      let provider = ResponseProvider(
        defaultResponse: try .recordZoneChangesResponse(zones: [])
      )
      for round in rounds {
        await provider.enqueue(
          try .recordZoneChangesResponse(zones: round),
          for: operationID
        )
      }
      return try Harness.makeService(provider: provider)
    }

    @Test("fetchAllRecordZoneChanges() merges a zone's records across rounds")
    internal func mergesAcrossRounds() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await Self.makeService(rounds: [
        [
          Harness.zoneEntry(
            zoneName: "zone-a",
            recordCount: 2,
            syncToken: "tok-1",
            moreComing: true,
            recordNamePrefix: "first"
          )
        ],
        [
          Harness.zoneEntry(
            zoneName: "zone-a",
            recordCount: 3,
            syncToken: "tok-2",
            recordNamePrefix: "second"
          )
        ],
      ])

      let result = try await service.fetchAllRecordZoneChanges(
        zones: [ZoneChangesRequest(zoneID: ZoneID(zoneName: "zone-a"))],
        database: .private
      )

      let changes = try #require(result.changes.first)
      #expect(changes.records.count == 5)
      #expect(changes.syncToken == "tok-2")
      // The merged result is fully drained.
      #expect(changes.moreComing == false)
      #expect(result.moreComing == false)
    }

    @Test("fetchAllRecordZoneChanges() re-requests only the zones still reporting moreComing")
    internal func reRequestsOnlyPendingZones() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // Round 1: zone-a is done, zone-b has more.
      // Round 2: only zone-b is requested, and it finishes.
      let service = try await Self.makeService(rounds: [
        [
          Harness.zoneEntry(zoneName: "zone-a", recordCount: 1, syncToken: "a-1"),
          Harness.zoneEntry(
            zoneName: "zone-b",
            recordCount: 1,
            syncToken: "b-1",
            moreComing: true,
            recordNamePrefix: "b-first"
          ),
        ],
        [
          Harness.zoneEntry(
            zoneName: "zone-b",
            recordCount: 2,
            syncToken: "b-2",
            recordNamePrefix: "b-second"
          )
        ],
      ])

      let result = try await service.fetchAllRecordZoneChanges(
        zones: [
          ZoneChangesRequest(zoneID: ZoneID(zoneName: "zone-a")),
          ZoneChangesRequest(zoneID: ZoneID(zoneName: "zone-b")),
        ],
        database: .private
      )

      // Output preserves the originally-requested order.
      #expect(result.changes.map(\.zone.zoneName) == ["zone-a", "zone-b"])
      #expect(result.changes.map(\.records.count) == [1, 3])
      #expect(result.changes.map(\.syncToken) == ["a-1", "b-2"])
    }

    @Test("fetchAllRecordZoneChanges() keeps a per-zone failure in the merged result")
    internal func keepsFailure() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await Self.makeService(rounds: [
        [
          Harness.zoneEntry(zoneName: "zone-a", recordCount: 1, syncToken: "a-1"),
          Harness.zoneErrorEntry(zoneName: "zone-b"),
        ]
      ])

      let result = try await service.fetchAllRecordZoneChanges(
        zones: [
          ZoneChangesRequest(zoneID: ZoneID(zoneName: "zone-a")),
          ZoneChangesRequest(zoneID: ZoneID(zoneName: "zone-b")),
        ],
        database: .private
      )

      #expect(result.changes.count == 1)
      #expect(result.failures.map(\.zoneName) == ["zone-b"])
    }
  }
}
