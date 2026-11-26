//
//  CloudKitServiceTests.ListZones+AtomicFlag.swift
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

extension CloudKitServiceTests.ListZones {
  /// `listZones` must surface each zone's `atomic` flag so callers can tell
  /// an all-or-nothing zone from one that reports per-record results.
  @Suite("Atomic Flag")
  internal struct AtomicFlag {
    @Test("listZones() reports atomic true, false, and absent per zone")
    internal func listZonesReportsAtomicPerZone() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try CloudKitServiceTests.ListZones.makeService(
        responseJSON: CloudKitServiceTests.ListZones.privateZonesListJSON
      )

      let zones = try await service.listZones(database: .private)

      #expect(zones.map(\.zoneName) == ["_defaultZone", "Tabletop", "Legacy"])
      try #require(zones.count == 3)
      #expect(zones[0].atomic == false)
      #expect(zones[1].atomic == true)
      #expect(zones[2].atomic == nil)
      #expect(await provider.callCount(for: "listZones") == 1)
    }

    @Test("listZones() keeps each zone's sync token beside its atomic flag")
    internal func listZonesKeepsSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, _) = try CloudKitServiceTests.ListZones.makeService(
        responseJSON: CloudKitServiceTests.ListZones.privateZonesListJSON
      )

      let zones = try await service.listZones(database: .private)

      #expect(zones.map(\.syncToken) == ["default-token", "tabletop-token", nil])
    }

    @Test("listZones() returns an empty array when the response has no zones key")
    internal func listZonesWithoutZonesKey() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, _) = try CloudKitServiceTests.ListZones.makeService(responseJSON: "{}")

      let zones = try await service.listZones(database: .private)

      #expect(zones.isEmpty)
    }
  }
}
