//
//  CloudKitServiceTests.FetchDatabaseChanges+SuccessCases.swift
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

extension CloudKitServiceTests.FetchDatabaseChanges {
  @Suite("Success Cases")
  internal struct SuccessCases {
    private typealias Harness = CloudKitServiceTests.FetchDatabaseChanges

    @Test("fetchDatabaseChanges() returns changed zones and sync token")
    internal func returnsZonesAndToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeSuccessfulService(
        zoneCount: 2,
        syncToken: "db-token-xyz"
      )

      let result = try await service.fetchDatabaseChanges(database: .private)

      #expect(result.zones.count == 2)
      #expect(result.changedZones.count == 2)
      #expect(result.syncToken == "db-token-xyz")
      #expect(result.moreComing == false)
      #expect(result.failures.isEmpty)
    }

    @Test("fetchDatabaseChanges() surfaces zone names")
    internal func returnsZoneNames() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeSuccessfulService(zoneCount: 1)

      let result = try await service.fetchDatabaseChanges(database: .private)

      #expect(result.changedZones.first?.zoneName == "test-zone-0")
    }

    @Test("fetchDatabaseChanges() returns empty zones when nothing changed")
    internal func returnsEmptyZones() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeSuccessfulService(zoneCount: 0)

      let result = try await service.fetchDatabaseChanges(database: .private)

      #expect(result.zones.isEmpty)
      #expect(result.syncToken != nil)
    }

    @Test("fetchDatabaseChanges() reports moreComing")
    internal func reportsMoreComing() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeSuccessfulService(zoneCount: 1, moreComing: true)

      let result = try await service.fetchDatabaseChanges(database: .private)

      #expect(result.moreComing)
    }

    @Test("fetchDatabaseChanges() surfaces a per-zone failure without dropping successes")
    internal func surfacesPerZoneFailure() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeService(
        provider: ResponseProvider(
          defaultResponse: try .databaseChangesResponse(zones: [
            ["zoneID": ["zoneName": "good-zone", "ownerName": "_defaultOwner"]],
            [
              "zoneID": ["zoneName": "bad-zone", "ownerName": "_defaultOwner"],
              "serverErrorCode": "ZONE_NOT_FOUND",
              "reason": "Zone does not exist",
            ],
          ])
        )
      )

      let result = try await service.fetchDatabaseChanges(database: .private)

      #expect(result.zones.count == 2)
      #expect(result.changedZones.map(\.zoneName) == ["good-zone"])

      let failure = try #require(result.failures.first)
      #expect(failure.zoneName == "bad-zone")
      #expect(failure.serverErrorCode == .zoneNotFound)
      #expect(failure.reason == "Zone does not exist")
    }

    @Test("ZoneChangeResult.get() rethrows a per-zone failure as zoneOperationFailed")
    internal func getRethrowsFailure() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeService(
        provider: ResponseProvider(
          defaultResponse: try .databaseChangesResponse(zones: [
            [
              "zoneID": ["zoneName": "bad-zone", "ownerName": "_defaultOwner"],
              "serverErrorCode": "ZONE_NOT_FOUND",
            ]
          ])
        )
      )

      let result = try await service.fetchDatabaseChanges(database: .private)
      let entry = try #require(result.zones.first)

      do {
        _ = try entry.get()
        Issue.record("expected .zoneOperationFailed")
      } catch let error as CloudKitError {
        guard case .zoneOperationFailed(let failure) = error else {
          Issue.record("expected .zoneOperationFailed, got \(error)")
          return
        }
        #expect(failure.zoneName == "bad-zone")
      }
    }
  }
}
