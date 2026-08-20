//
//  CloudKitServiceTests.FetchRecordZoneChanges+Helpers.swift
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

extension CloudKitServiceTests.FetchRecordZoneChanges {
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

  /// A single-zone success entry carrying `recordCount` synthetic records.
  internal static func zoneEntry(
    zoneName: String,
    recordCount: Int,
    syncToken: String,
    moreComing: Bool = false,
    recordNamePrefix: String = "record"
  ) -> [String: Any] {
    let records: [[String: Any]] = (0..<recordCount).map { index in
      [
        "recordName": "\(recordNamePrefix)-\(index)",
        "recordType": "TestRecord",
        "recordChangeTag": "tag-\(index)",
        "fields": ["title": ["value": "Record \(index)", "type": "STRING"]],
      ]
    }
    return [
      "zoneID": ["zoneName": zoneName, "ownerName": "_defaultOwner"],
      "records": records,
      "syncToken": syncToken,
      "moreComing": moreComing,
    ]
  }

  /// A single-zone error entry.
  internal static func zoneErrorEntry(
    zoneName: String,
    serverErrorCode: String = "ZONE_NOT_FOUND",
    reason: String = "Zone does not exist"
  ) -> [String: Any] {
    [
      "zoneID": ["zoneName": zoneName, "ownerName": "_defaultOwner"],
      "serverErrorCode": serverErrorCode,
      "reason": reason,
    ]
  }
}

// MARK: - FetchRecordZoneChanges Response Builders

extension ResponseConfig {
  internal static func recordZoneChangesResponse(
    zones: [[String: Any]]
  ) throws -> ResponseConfig {
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
