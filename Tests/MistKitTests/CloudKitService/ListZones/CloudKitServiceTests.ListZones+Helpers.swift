//
//  CloudKitServiceTests.ListZones+Helpers.swift
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

extension CloudKitServiceTests.ListZones {
  /// A `zones/list` body for the private database: the default zone, which
  /// CloudKit reports as non-atomic, a custom zone reported as atomic, and a
  /// zone whose payload omits the `atomic` key.
  ///
  /// Hand-written from Apple's archived "Zone Dictionary" documentation, not
  /// recorded from a live container — see the PR that added it.
  internal static let privateZonesListJSON = """
    {
      "zones": [
        {
          "zoneID": { "zoneName": "_defaultZone", "ownerRecordName": "_defaultOwner" },
          "syncToken": "default-token",
          "atomic": false
        },
        {
          "zoneID": { "zoneName": "Tabletop", "ownerRecordName": "_defaultOwner" },
          "syncToken": "tabletop-token",
          "atomic": true
        },
        {
          "zoneID": { "zoneName": "Legacy", "ownerRecordName": "_defaultOwner" }
        }
      ]
    }
    """

  internal static func makeService(
    responseJSON: String
  ) throws -> (CloudKitService, ResponseProvider) {
    var headers = HTTPFields()
    headers[.contentType] = "application/json"
    let provider = ResponseProvider(
      defaultResponse: ResponseConfig(
        statusCode: 200,
        headers: headers,
        body: Data(responseJSON.utf8),
        error: nil
      )
    )
    let service = try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: TestConstants.apiToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: MockTransport(responseProvider: provider)
    )
    return (service, provider)
  }
}
