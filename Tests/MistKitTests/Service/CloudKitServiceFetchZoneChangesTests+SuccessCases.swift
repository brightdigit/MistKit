//
//  CloudKitServiceFetchZoneChangesTests+SuccessCases.swift
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

extension CloudKitServiceFetchZoneChangesTests {
  @Suite("Success Cases")
  internal struct SuccessCases {
    @Test("fetchZoneChanges() returns zones and sync token")
    internal func fetchZoneChangesReturnsZonesAndToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchZoneChangesTests.makeSuccessfulService(
        zoneCount: 2,
        syncToken: "zone-token-xyz"
      )

      let result = try await service.fetchZoneChanges()

      #expect(result.zones.count == 2)
      #expect(result.syncToken == "zone-token-xyz")
    }

    @Test("fetchZoneChanges() returns zone names")
    internal func fetchZoneChangesReturnsZoneNames() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchZoneChangesTests.makeSuccessfulService(
        zoneCount: 1
      )

      let result = try await service.fetchZoneChanges()

      #expect(result.zones.first?.zoneName == "test-zone-0")
    }

    @Test("fetchZoneChanges() returns empty zones array when no changes")
    internal func fetchZoneChangesReturnsEmptyArray() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchZoneChangesTests.makeSuccessfulService(
        zoneCount: 0
      )

      let result = try await service.fetchZoneChanges()

      #expect(result.zones.isEmpty)
      #expect(result.syncToken != nil)
    }

    @Test("fetchZoneChanges() works with sync token (incremental fetch)")
    internal func fetchZoneChangesWorksWithSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchZoneChangesTests.makeSuccessfulService(
        zoneCount: 1,
        syncToken: "new-token"
      )

      let result = try await service.fetchZoneChanges(syncToken: "previous-token")

      #expect(result.zones.count == 1)
      #expect(result.syncToken == "new-token")
    }

    @Test("fetchZoneChanges() filters out zones with nil zoneID from server response")
    internal func fetchZoneChangesFiltersNilZoneID() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let responseProvider = ResponseProvider(
        defaultResponse: .zoneChangesResponseWithNilZoneID()
      )
      let transport = MockTransport(responseProvider: responseProvider)
      let service = try CloudKitService(
        containerIdentifier: "iCloud.com.example.test",
        apiToken: "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234",
        transport: transport
      )

      let result = try await service.fetchZoneChanges()

      #expect(result.zones.count == 1, "Zone with nil zoneID should be filtered out")
      #expect(result.zones.first?.zoneName == "valid-zone")
    }
  }
}
