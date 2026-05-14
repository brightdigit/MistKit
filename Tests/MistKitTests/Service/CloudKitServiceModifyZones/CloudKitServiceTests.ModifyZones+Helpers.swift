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

import Foundation
import HTTPTypes
import Testing

@testable import MistKit

extension CloudKitServiceTests.ModifyZones {
  private static let testAPIToken = TestConstants.apiToken

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func makeSuccessfulService(
    zoneCount: Int = 1
  ) async throws -> CloudKitService {
    let responseProvider = try ResponseProvider.successfulModifyZones(zoneCount: zoneCount)
    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: testAPIToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: transport
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
    var zones: [[String: Any]] = []
    for index in 0..<zoneCount {
      zones.append([
        "zoneID": [
          "zoneName": "modified-zone-\(index)",
          "ownerName": "_defaultOwner",
        ]
      ])
    }

    let zonesJSON = try JSONSerialization.data(withJSONObject: zones)
    let zonesString = String(decoding: zonesJSON, as: UTF8.self)

    let responseJSON = """
      {
        "zones": \(zonesString)
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
