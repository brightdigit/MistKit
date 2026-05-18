//
//  CloudKitServiceTests.ModifyZones+SuccessCases.swift
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
  @Suite("Success Cases")
  internal struct SuccessCases {
    @Test("modifyZones() returns zone for create-only batch")
    internal func modifyZonesCreateOnly() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.ModifyZones.makeSuccessfulService(zoneCount: 1)

      let zones = try await service.modifyZones(
        [.create(ZoneID(zoneName: "Articles", ownerName: nil))],
        database: .private
      )

      #expect(zones.count == 1)
      #expect(zones.first?.zoneName == "modified-zone-0")
    }

    @Test("modifyZones() returns zone for delete-only batch")
    internal func modifyZonesDeleteOnly() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.ModifyZones.makeSuccessfulService(zoneCount: 1)

      let zones = try await service.modifyZones(
        [.delete(ZoneID(zoneName: "Archive", ownerName: nil))],
        database: .private
      )

      #expect(zones.count == 1)
    }

    @Test("modifyZones() returns zones for mixed create+delete batch")
    internal func modifyZonesMixedBatch() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.ModifyZones.makeSuccessfulService(zoneCount: 2)

      let zones = try await service.modifyZones(
        [
          .create(ZoneID(zoneName: "NewZone", ownerName: nil)),
          .delete(ZoneID(zoneName: "OldZone", ownerName: nil)),
        ],
        database: .private
      )

      #expect(zones.count == 2)
      #expect(zones[0].zoneName == "modified-zone-0")
      #expect(zones[1].zoneName == "modified-zone-1")
    }

    @Test("modifyZones() works against shared database")
    internal func modifyZonesAgainstShared() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.ModifyZones.makeSuccessfulService(zoneCount: 1)

      let zones = try await service.modifyZones(
        [.create(ZoneID(zoneName: "Shared", ownerName: "other-user"))],
        database: .shared
      )

      #expect(zones.count == 1)
    }
  }
}
