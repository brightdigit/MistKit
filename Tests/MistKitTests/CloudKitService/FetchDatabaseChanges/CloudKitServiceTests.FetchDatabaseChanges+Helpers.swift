//
//  CloudKitServiceTests.FetchDatabaseChanges+Helpers.swift
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
internal import HTTPTypes
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.FetchDatabaseChanges {
  internal static func makeService(
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

  internal static func makeSuccessfulService(
    zoneCount: Int = 1,
    moreComing: Bool = false,
    syncToken: String = "db-sync-token-abc"
  ) throws -> CloudKitService {
    try makeService(
      provider: ResponseProvider(
        defaultResponse: try .successfulFetchDatabaseChangesResponse(
          zoneCount: zoneCount,
          moreComing: moreComing,
          syncToken: syncToken
        )
      )
    )
  }

  internal static func makePaginatedService(
    pages: [(zoneCount: Int, syncToken: String)]
  ) async throws -> CloudKitService {
    let provider = ResponseProvider(
      defaultResponse: try .successfulFetchDatabaseChangesResponse(
        zoneCount: 0,
        moreComing: false,
        syncToken: "final-token"
      )
    )
    for (index, page) in pages.enumerated() {
      await provider.enqueue(
        try .successfulFetchDatabaseChangesResponse(
          zoneCount: page.zoneCount,
          moreComing: index < pages.count - 1,
          syncToken: page.syncToken
        ),
        for: "fetchDatabaseChanges"
      )
    }
    return try makeService(provider: provider)
  }

  internal static func makeStuckTokenService(
    syncToken: String = "stuck-token"
  ) throws -> CloudKitService {
    try makeService(
      provider: ResponseProvider(
        defaultResponse: try .successfulFetchDatabaseChangesResponse(
          zoneCount: 0,
          moreComing: true,
          syncToken: syncToken
        )
      )
    )
  }
}

// MARK: - FetchDatabaseChanges Response Builders

extension ResponseConfig {
  internal static func successfulFetchDatabaseChangesResponse(
    zoneCount: Int = 1,
    moreComing: Bool = false,
    syncToken: String = "db-sync-token-abc"
  ) throws -> ResponseConfig {
    let zones: [[String: Any]] = (0..<zoneCount).map { index in
      [
        "zoneID": [
          "zoneName": "test-zone-\(index)",
          "ownerName": "_defaultOwner",
        ]
      ]
    }
    return try .databaseChangesResponse(
      zones: zones,
      syncToken: syncToken,
      moreComing: moreComing
    )
  }

  /// Builds a `changes/database` body from raw zone dictionaries so tests can
  /// mix success and per-zone error entries.
  internal static func databaseChangesResponse(
    zones: [[String: Any]],
    syncToken: String? = "db-sync-token-abc",
    moreComing: Bool = false
  ) throws -> ResponseConfig {
    var body: [String: Any] = [
      "zones": zones,
      "moreComing": moreComing,
    ]
    if let syncToken {
      body["syncToken"] = syncToken
    }

    var headers = HTTPFields()
    headers[.contentType] = "application/json"

    return ResponseConfig(
      statusCode: 200,
      headers: headers,
      body: try JSONSerialization.data(withJSONObject: body),
      error: nil
    )
  }
}
