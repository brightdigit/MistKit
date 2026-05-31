//
//  CloudKitServiceTests.FetchZoneChanges.SuccessCases+Pagination.swift
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
  internal static func makePaginatedService(
    pages: [(zoneCount: Int, syncToken: String)]
  ) async throws -> CloudKitService {
    let provider = ResponseProvider(
      defaultResponse: try .successfulFetchZoneChangesResponse(
        zoneCount: 0,
        moreComing: false,
        syncToken: "final-token"
      )
    )
    for (index, page) in pages.enumerated() {
      let moreComing = index < pages.count - 1
      await provider.enqueue(
        try .successfulFetchZoneChangesResponse(
          zoneCount: page.zoneCount,
          moreComing: moreComing,
          syncToken: page.syncToken
        ),
        for: "fetchZoneChanges"
      )
    }
    let transport = MockTransport(responseProvider: provider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: TestConstants.apiToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: transport
    )
  }

  internal static func makeStuckTokenService(
    syncToken: String = "stuck-token"
  ) async throws -> CloudKitService {
    let responseProvider = ResponseProvider(
      defaultResponse: try .successfulFetchZoneChangesResponse(
        zoneCount: 0,
        moreComing: true,
        syncToken: syncToken
      )
    )
    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: TestConstants.apiToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: transport
    )
  }
}

extension CloudKitServiceTests.FetchZoneChanges.SuccessCases {
  @Test("fetchAllZoneChanges() handles moreComing=true with empty first page")
  internal func fetchAllZoneChangesEmptyFirstPage() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try await CloudKitServiceTests.FetchZoneChanges.makePaginatedService(pages: [
      (zoneCount: 0, syncToken: "token-1"),
      (zoneCount: 3, syncToken: "token-2"),
    ])

    let (zones, token) = try await service.fetchAllZoneChanges(database: .private)

    #expect(zones.count == 3)
    #expect(token == "token-2")
  }

  @Test("fetchAllZoneChanges() accumulates zones across three pages")
  internal func fetchAllZoneChangesThreePage() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try await CloudKitServiceTests.FetchZoneChanges.makePaginatedService(pages: [
      (zoneCount: 2, syncToken: "token-1"),
      (zoneCount: 3, syncToken: "token-2"),
      (zoneCount: 2, syncToken: "token-3"),
    ])

    let (zones, token) = try await service.fetchAllZoneChanges(database: .private)

    #expect(zones.count == 7)
    #expect(token == "token-3")
  }

  @Test("fetchAllZoneChanges() breaks out when server returns stuck token with no zones")
  internal func fetchAllZoneChangesEscapesStuckToken() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try await CloudKitServiceTests.FetchZoneChanges.makeStuckTokenService(
      syncToken: "stuck-token"
    )

    let (zones, token) = try await service.fetchAllZoneChanges(
      syncToken: "stuck-token",
      database: .private
    )

    #expect(zones.isEmpty)
    #expect(token == "stuck-token")
  }
}
