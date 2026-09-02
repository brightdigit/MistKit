//
//  CloudKitServiceTests.ModifyZones+ErrorHandling.swift
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

extension CloudKitServiceTests.ModifyZones {
  @Suite("Error Handling")
  internal struct ErrorHandling {
    private typealias Harness = CloudKitServiceTests.ModifyZones

    @Test("modifyZones() surfaces a per-zone failure without dropping successes")
    internal func surfacesPerZoneFailure() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeService(zones: [
        ["zoneID": ["zoneName": "good-zone", "ownerRecordName": "_defaultOwner"]],
        [
          "zoneID": ["zoneName": "bad-zone", "ownerRecordName": "_defaultOwner"],
          "serverErrorCode": "ZONE_NOT_FOUND",
          "reason": "Zone does not exist",
        ],
      ])

      let results = try await service.modifyZones(
        [
          .create(ZoneID(zoneName: "good-zone", ownerName: nil)),
          .delete(ZoneID(zoneName: "bad-zone", ownerName: nil)),
        ],
        database: .private
      )

      #expect(results.count == 2)
      #expect(results.zones.map(\.zoneName) == ["good-zone"])

      let failure = try #require(results.failures.first)
      #expect(failure.zoneName == "bad-zone")
      #expect(failure.serverErrorCode == .zoneNotFound)
      #expect(failure.reason == "Zone does not exist")
    }

    @Test("modifyZones() entry .get() rethrows a per-zone failure as zoneOperationFailed")
    internal func getRethrowsFailure() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeService(zones: [
        [
          "zoneID": ["zoneName": "bad-zone", "ownerRecordName": "_defaultOwner"],
          "serverErrorCode": "ZONE_NOT_FOUND",
        ]
      ])

      let results = try await service.modifyZones(
        [.delete(ZoneID(zoneName: "bad-zone", ownerName: nil))],
        database: .private
      )
      let entry = try #require(results.first)

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

    @Test("modifyZones() keeps zone metadata on successful entries")
    internal func keepsZoneMetadata() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeService(zones: [
        [
          "zoneID": ["zoneName": "good-zone", "ownerRecordName": "_defaultOwner"],
          "syncToken": "zone-token",
          "atomic": true,
        ]
      ])

      let results = try await service.modifyZones(
        [.create(ZoneID(zoneName: "good-zone", ownerName: nil))],
        database: .private
      )

      let zone = try #require(results.zones.first)
      #expect(zone.syncToken == "zone-token")
      #expect(zone.atomic == true)
    }
  }
}
