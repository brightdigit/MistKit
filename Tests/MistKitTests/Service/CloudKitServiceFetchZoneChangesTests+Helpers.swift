//
//  CloudKitServiceFetchZoneChangesTests+Helpers.swift
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
import HTTPTypes
import Testing

@testable import MistKit

extension CloudKitServiceFetchZoneChangesTests {
  private static let testAPIToken =
    "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func makeSuccessfulService(
    zoneCount: Int = 1,
    syncToken: String = "zone-sync-token-abc"
  ) async throws -> CloudKitService {
    let responseProvider = try ResponseProvider.successfulFetchZoneChanges(
      zoneCount: zoneCount,
      syncToken: syncToken
    )
    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: testAPIToken,
      transport: transport
    )
  }

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func makeAuthErrorService() async throws -> CloudKitService {
    let responseProvider = ResponseProvider.authenticationError()
    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: testAPIToken,
      transport: transport
    )
  }
}

// MARK: - FetchZoneChanges Response Builders

extension ResponseProvider {
  internal static func successfulFetchZoneChanges(
    zoneCount: Int = 1,
    syncToken: String = "zone-sync-token-abc"
  ) throws -> ResponseProvider {
    ResponseProvider(
      defaultResponse: try .successfulFetchZoneChangesResponse(
        zoneCount: zoneCount,
        syncToken: syncToken
      )
    )
  }
}

extension ResponseConfig {
  internal static func successfulFetchZoneChangesResponse(
    zoneCount: Int = 1,
    syncToken: String = "zone-sync-token-abc"
  ) throws -> ResponseConfig {
    var zones: [[String: Any]] = []
    for index in 0..<zoneCount {
      zones.append([
        "zoneID": [
          "zoneName": "test-zone-\(index)",
          "ownerName": "_defaultOwner",
        ]
      ])
    }

    let zonesJSON = try JSONSerialization.data(withJSONObject: zones)
    let zonesString = String(decoding: zonesJSON, as: UTF8.self)

    let responseJSON = """
      {
        "zones": \(zonesString),
        "syncToken": "\(syncToken)"
      }
      """

    var headers = HTTPFields()
    headers[.contentType] = "application/json"

    return ResponseConfig(
      statusCode: 200,
      headers: headers,
      body: responseJSON.data(using: .utf8),
      error: nil
    )
  }

  internal static func zoneChangesResponseWithNilZoneID() -> ResponseConfig {
    let responseJSON = """
      {
        "zones": [
          {
            "zoneID": {
              "zoneName": "valid-zone",
              "ownerName": "_defaultOwner"
            }
          },
          {}
        ],
        "syncToken": "token-with-nil-zone"
      }
      """

    var headers = HTTPFields()
    headers[.contentType] = "application/json"

    return ResponseConfig(
      statusCode: 200,
      headers: headers,
      body: responseJSON.data(using: .utf8),
      error: nil
    )
  }
}
