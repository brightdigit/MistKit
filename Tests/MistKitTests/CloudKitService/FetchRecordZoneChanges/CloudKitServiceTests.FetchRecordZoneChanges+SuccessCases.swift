//
//  CloudKitServiceTests.FetchRecordZoneChanges+SuccessCases.swift
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
  @Suite("Success Cases")
  internal struct SuccessCases {
    private typealias Harness = CloudKitServiceTests.FetchRecordZoneChanges

    @Test("fetchRecordZoneChanges() returns per-zone records and sync token")
    internal func returnsPerZoneChanges() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeService(
        provider: ResponseProvider(
          defaultResponse: try .recordZoneChangesResponse(zones: [
            Harness.zoneEntry(zoneName: "zone-a", recordCount: 2, syncToken: "tok-a")
          ])
        )
      )

      let result = try await service.fetchRecordZoneChanges(
        zones: [ZoneChangesRequest(zoneID: ZoneID(zoneName: "zone-a"))],
        database: .private
      )

      let changes = try #require(result.changes.first)
      #expect(changes.zone.zoneName == "zone-a")
      #expect(changes.records.count == 2)
      #expect(changes.syncToken == "tok-a")
      #expect(changes.moreComing == false)
      #expect(result.moreComing == false)
    }

    @Test("fetchRecordZoneChanges() handles multiple zones independently")
    internal func handlesMultipleZones() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeService(
        provider: ResponseProvider(
          defaultResponse: try .recordZoneChangesResponse(zones: [
            Harness.zoneEntry(zoneName: "zone-a", recordCount: 1, syncToken: "tok-a"),
            Harness.zoneEntry(
              zoneName: "zone-b",
              recordCount: 3,
              syncToken: "tok-b",
              moreComing: true
            ),
          ])
        )
      )

      let result = try await service.fetchRecordZoneChanges(
        zones: [
          ZoneChangesRequest(zoneID: ZoneID(zoneName: "zone-a")),
          ZoneChangesRequest(zoneID: ZoneID(zoneName: "zone-b")),
        ],
        database: .private
      )

      #expect(result.changes.count == 2)
      #expect(result.changes.map(\.zone.zoneName) == ["zone-a", "zone-b"])
      #expect(result.changes.map(\.records.count) == [1, 3])
      // Per-zone pagination: only zone-b has more.
      #expect(result.changes.map(\.moreComing) == [false, true])
      #expect(result.moreComing)
    }

    @Test("fetchRecordZoneChanges() surfaces a per-zone failure alongside successes")
    internal func surfacesPerZoneFailure() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeService(
        provider: ResponseProvider(
          defaultResponse: try .recordZoneChangesResponse(zones: [
            Harness.zoneEntry(zoneName: "good-zone", recordCount: 1, syncToken: "tok"),
            Harness.zoneErrorEntry(zoneName: "bad-zone"),
          ])
        )
      )

      let result = try await service.fetchRecordZoneChanges(
        zones: [
          ZoneChangesRequest(zoneID: ZoneID(zoneName: "good-zone")),
          ZoneChangesRequest(zoneID: ZoneID(zoneName: "bad-zone")),
        ],
        database: .private
      )

      #expect(result.zones.count == 2)
      #expect(result.changes.map(\.zone.zoneName) == ["good-zone"])

      let failure = try #require(result.failures.first)
      #expect(failure.zoneName == "bad-zone")
      #expect(failure.serverErrorCode == .zoneNotFound)
    }

    @Test("fetchRecordZoneChanges() returns an empty result for no zones changed")
    internal func returnsEmptyResult() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeService(
        provider: ResponseProvider(
          defaultResponse: try .recordZoneChangesResponse(zones: [])
        )
      )

      let result = try await service.fetchRecordZoneChanges(
        zones: [ZoneChangesRequest(zoneID: ZoneID(zoneName: "zone-a"))],
        database: .private
      )

      #expect(result.zones.isEmpty)
      #expect(result.moreComing == false)
    }
  }
}
