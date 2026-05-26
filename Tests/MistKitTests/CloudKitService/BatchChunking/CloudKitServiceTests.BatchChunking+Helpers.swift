//
//  CloudKitServiceTests.BatchChunking+Helpers.swift
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

extension CloudKitServiceTests.BatchChunking {
  private static let testAPIToken = TestConstants.apiToken

  /// A service whose provider returns `identitiesPerCall` identities for every
  /// `users/*` request, with web-auth credentials.
  internal static func makeUserService(
    provider: ResponseProvider
  ) throws -> CloudKitService {
    let transport = MockTransport(responseProvider: provider)
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

  /// A service whose provider returns `recordsPerCall` records for every
  /// `lookupRecords` request, with web-auth credentials (so `.private` works).
  internal static func makeLookupRecordsService(
    provider: ResponseProvider
  ) throws -> CloudKitService {
    try makeUserService(provider: provider)
  }

  // MARK: - Request body inspection

  /// Number of items in each recorded request body, reading the array under
  /// `key` (e.g. `"records"`, `"users"`, `"lookupInfos"`).
  internal static func itemCounts(in bodies: [Data?], key: String) -> [Int] {
    bodies.map { data in
      guard let data,
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let items = json[key] as? [[String: Any]]
      else {
        return 0
      }
      return items.count
    }
  }

  /// Concatenate the `field`-valued strings of every item across all bodies,
  /// reading items under `key` — used to verify input order is preserved.
  internal static func orderedValues(
    in bodies: [Data?],
    key: String,
    field: String
  ) -> [String] {
    bodies.flatMap { data -> [String] in
      guard let data,
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let items = json[key] as? [[String: Any]]
      else {
        return []
      }
      return items.compactMap { $0[field] as? String }
    }
  }
}

// MARK: - lookupRecords Response Builder

extension ResponseConfig {
  internal static func successfulLookupRecordsResponse(
    recordCount: Int = 1
  ) throws -> ResponseConfig {
    var records: [[String: Any]] = []
    for index in 0..<recordCount {
      records.append([
        "recordName": "found-\(index)",
        "recordType": "TestRecord",
        "recordChangeTag": "tag-\(index)",
        "fields": [String: Any](),
      ])
    }

    let bodyData = try JSONSerialization.data(withJSONObject: ["records": records])

    var headers = HTTPFields()
    headers[.contentType] = "application/json"

    return ResponseConfig(
      statusCode: 200,
      headers: headers,
      body: bodyData,
      error: nil
    )
  }
}
