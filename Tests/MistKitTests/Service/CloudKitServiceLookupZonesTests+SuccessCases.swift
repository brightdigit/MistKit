//
//  CloudKitServiceLookupZonesTests+SuccessCases.swift
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

import Foundation
import Testing

@testable import MistKit

extension CloudKitServiceLookupZonesTests {
  @Suite("Success Cases")
  internal struct SuccessCases {
    @Test("lookupZones() returns single zone")
    internal func lookupZonesReturnsSingleZone() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceLookupZonesTests.makeSuccessfulService(zoneCount: 1)

      let zones = try await service.lookupZones(
        zoneIDs: [ZoneID(zoneName: "_defaultZone", ownerName: nil)]
      )

      #expect(zones.count == 1)
      #expect(zones.first?.zoneName == "test-zone-0")
    }

    @Test("lookupZones() returns multiple zones")
    internal func lookupZonesReturnsMultipleZones() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceLookupZonesTests.makeSuccessfulService(zoneCount: 3)

      let zones = try await service.lookupZones(
        zoneIDs: [
          ZoneID(zoneName: "zone1", ownerName: nil),
          ZoneID(zoneName: "zone2", ownerName: nil),
          ZoneID(zoneName: "zone3", ownerName: nil),
        ]
      )

      #expect(zones.count == 3)
      #expect(zones[0].zoneName == "test-zone-0")
      #expect(zones[1].zoneName == "test-zone-1")
      #expect(zones[2].zoneName == "test-zone-2")
    }

    @Test("lookupZones() returns empty array when no zones match")
    internal func lookupZonesReturnsEmptyArray() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceLookupZonesTests.makeSuccessfulService(zoneCount: 0)

      let zones = try await service.lookupZones(
        zoneIDs: [ZoneID(zoneName: "nonexistent", ownerName: nil)]
      )

      #expect(zones.isEmpty)
    }
  }
}
