//
//  CloudKitServiceLookupZonesTests+Validation.swift
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
  @Suite("Validation")
  internal struct Validation {
    @Test("lookupZones() throws 400 for empty zoneIDs array")
    internal func lookupZonesThrowsForEmptyZoneIDs() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceLookupZonesTests.makeSuccessfulService()

      await #expect {
        try await service.lookupZones(zoneIDs: [])
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithRawResponse(let status, _) = ckError
        else { return false }
        return status == 400
      }
    }

    @Test("lookupZones() throws 400 for zone with empty zoneName")
    internal func lookupZonesThrowsForEmptyZoneName() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceLookupZonesTests.makeSuccessfulService()

      await #expect {
        try await service.lookupZones(zoneIDs: [ZoneID(zoneName: "", ownerName: nil)])
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithRawResponse(let status, _) = ckError
        else { return false }
        return status == 400
      }
    }

    @Test("lookupZones() throws 400 when any zone has an empty zoneName")
    internal func lookupZonesThrowsForMixedZoneNames() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceLookupZonesTests.makeSuccessfulService()
      let zoneIDs = [
        ZoneID(zoneName: "_defaultZone", ownerName: nil),
        ZoneID(zoneName: "", ownerName: nil),
      ]

      await #expect {
        try await service.lookupZones(zoneIDs: zoneIDs)
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithRawResponse(let status, _) = ckError
        else { return false }
        return status == 400
      }
    }

    @Test("lookupZones() throws for zone with empty zoneName")
    internal func lookupZonesThrowsForEmptyZoneName() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceLookupZonesTests.makeSuccessfulService()

      await #expect(throws: CloudKitError.self) {
        try await service.lookupZones(zoneIDs: [ZoneID(zoneName: "", ownerName: nil)])
      }
    }
  }
}
