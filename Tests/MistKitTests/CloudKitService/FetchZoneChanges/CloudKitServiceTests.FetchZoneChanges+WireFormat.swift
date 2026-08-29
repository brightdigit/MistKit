//
//  CloudKitServiceTests.FetchZoneChanges+WireFormat.swift
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

extension CloudKitServiceTests.FetchZoneChanges {
  /// Pins the on-the-wire token key for `zones/changes`.
  ///
  /// Verified against a live container (issue #430): the response's top-level
  /// keys are exactly `[moreComing, metaSyncToken, zones]`, and a request
  /// sending `syncToken` is silently ignored — CloudKit replays the first page
  /// instead of advancing. `zones/changes` is the only change-tracking
  /// operation that names its token `metaSyncToken`; `changes/database`,
  /// `changes/zone` and `records/changes` all use `syncToken`.
  ///
  /// The Swift-facing names (`ZoneChangesResult.syncToken`, the
  /// `fetchZoneChanges(syncToken:)` label) are deliberately unchanged.
  @Suite("Wire Format")
  internal struct WireFormat {
    private static let operationID = "fetchZoneChanges"

    private static func makeService(
      provider: ResponseProvider
    ) throws -> CloudKitService {
      try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(
          apiAuth: APICredentials(
            apiToken: TestConstants.apiToken,
            webAuthToken: TestConstants.webAuthToken
          )
        ),
        transport: MockTransport(responseProvider: provider)
      )
    }

    private static func sentBodies(_ provider: ResponseProvider) async throws -> [[String: Any]] {
      let bodies = await provider.bodies(for: operationID).compactMap { $0 }
      return try bodies.map { data in
        try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
      }
    }

    @Test("fetchZoneChanges() sends the token as metaSyncToken, never as syncToken")
    internal func sendsMetaSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = try ResponseProvider.successfulFetchZoneChanges(zoneCount: 1)
      let service = try Self.makeService(provider: provider)

      _ = try await service.fetchZoneChanges(syncToken: "baseline-token", database: .private)

      let sent = try await Self.sentBodies(provider)
      #expect(sent.count == 1)
      let body = try #require(sent.first)
      #expect(body["metaSyncToken"] as? String == "baseline-token")
      #expect(body["syncToken"] == nil)
    }

    @Test("fetchZoneChanges() reads metaSyncToken and ignores a stray syncToken")
    internal func readsMetaSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // The decoy `syncToken` is what MistKit used to read; the live container
      // never sends it.
      let provider = ResponseProvider(
        defaultResponse: try .zoneChangesRawResponse(
          body: """
            {
              "zones": [],
              "syncToken": "decoy-token",
              "metaSyncToken": "real-token",
              "moreComing": false
            }
            """
        )
      )
      let service = try Self.makeService(provider: provider)

      let result = try await service.fetchZoneChanges(database: .private)

      #expect(result.syncToken == "real-token")
    }

    @Test("fetchAllZoneChanges() feeds the previous page's metaSyncToken back")
    internal func paginationRoundTripsMetaSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = try ResponseProvider.successfulFetchZoneChanges(
        zoneCount: 0,
        moreComing: false,
        syncToken: "page-2-token"
      )
      await provider.enqueue(
        try .successfulFetchZoneChangesResponse(
          zoneCount: 1,
          moreComing: true,
          syncToken: "page-1-token"
        ),
        for: Self.operationID
      )
      let service = try Self.makeService(provider: provider)

      _ = try await service.fetchAllZoneChanges(database: .private)

      let sent = try await Self.sentBodies(provider)
      #expect(sent.count == 2)
      // Page one is the initial fetch; page two must carry page one's token
      // under the key CloudKit actually honors, or pagination silently
      // replays page one forever (issue #430).
      #expect(sent.last?["metaSyncToken"] as? String == "page-1-token")
    }
  }
}
