//
//  CloudKitServiceTests.ModifyZones+Helpers.swift
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

extension CloudKitServiceTests.ModifyZones {
  private static let testAPIToken = TestConstants.apiToken

  internal static func makeSuccessfulService(
    zoneCount: Int = 1
  ) async throws -> CloudKitService {
    try makeService(responseProvider: .successfulModifyZones(zoneCount: zoneCount))
  }

  /// Builds a service whose `zones/modify` response is the supplied raw zone
  /// dictionaries, so tests can mix success and per-zone error entries.
  internal static func makeService(zones: [[String: Any]]) throws -> CloudKitService {
    try makeService(
      responseProvider: ResponseProvider(defaultResponse: .modifyZonesResponse(zones: zones))
    )
  }

  internal static func makeService(
    responseProvider: ResponseProvider
  ) throws -> CloudKitService {
    try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: testAPIToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: MockTransport(responseProvider: responseProvider)
    )
  }
}

// MARK: - ModifyZones Response Builders

extension ResponseProvider {
  internal static func successfulModifyZones(zoneCount: Int = 1) throws -> ResponseProvider {
    ResponseProvider(defaultResponse: try .successfulModifyZonesResponse(zoneCount: zoneCount))
  }
}

extension ResponseConfig {
  internal static func successfulModifyZonesResponse(zoneCount: Int = 1) throws -> ResponseConfig {
    try .modifyZonesResponse(
      zones: (0..<zoneCount).map { index in
        [
          "zoneID": [
            "zoneName": "modified-zone-\(index)",
            "ownerName": "_defaultOwner",
          ]
        ]
      }
    )
  }

  /// Builds a `zones/modify` body from raw zone dictionaries so tests can mix
  /// success entries and per-zone error entries in one response.
  internal static func modifyZonesResponse(zones: [[String: Any]]) throws -> ResponseConfig {
    var headers = HTTPFields()
    headers[.contentType] = "application/json"

    return ResponseConfig(
      statusCode: 200,
      headers: headers,
      body: try JSONSerialization.data(withJSONObject: ["zones": zones]),
      error: nil
    )
  }
}
