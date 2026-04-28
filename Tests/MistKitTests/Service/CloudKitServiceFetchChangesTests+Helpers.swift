//
//  CloudKitServiceFetchChangesTests+Helpers.swift
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

extension CloudKitServiceFetchChangesTests {
  private static let testAPIToken =
    "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func makeSuccessfulService(
    recordCount: Int = 2,
    moreComing: Bool = false,
    syncToken: String = "test-sync-token-abc"
  ) async throws -> CloudKitService {
    let responseProvider = try ResponseProvider.successfulFetchChanges(
      recordCount: recordCount,
      moreComing: moreComing,
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
  internal static func makePaginatedService(
    pages: [(recordCount: Int, syncToken: String)]
  ) async throws -> CloudKitService {
    let provider = ResponseProvider(
      defaultResponse: try .successfulFetchChangesResponse(moreComing: false)
    )
    for (index, page) in pages.enumerated() {
      let moreComing = index < pages.count - 1
      await provider.enqueue(
        try .successfulFetchChangesResponse(
          recordCount: page.recordCount,
          moreComing: moreComing,
          syncToken: page.syncToken
        ),
        for: "fetchRecordChanges"
      )
    }
    let transport = MockTransport(responseProvider: provider)
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

// MARK: - FetchChanges Response Builders

extension ResponseProvider {
  internal static func successfulFetchChanges(
    recordCount: Int = 2,
    moreComing: Bool = false,
    syncToken: String = "test-sync-token-abc"
  ) throws -> ResponseProvider {
    ResponseProvider(
      defaultResponse: try .successfulFetchChangesResponse(
        recordCount: recordCount,
        moreComing: moreComing,
        syncToken: syncToken
      )
    )
  }
}

extension ResponseConfig {
  internal static func successfulFetchChangesResponse(
    recordCount: Int = 2,
    moreComing: Bool = false,
    syncToken: String = "test-sync-token-abc"
  ) throws -> ResponseConfig {
    var records: [[String: Any]] = []
    for index in 0..<recordCount {
      records.append([
        "recordName": "record-\(index)",
        "recordType": "Note",
        "recordChangeTag": "tag-\(index)",
        "fields": [String: Any](),
      ])
    }

    let recordsJSON = try JSONSerialization.data(withJSONObject: records)
    let recordsString = String(decoding: recordsJSON, as: UTF8.self)

    let responseJSON = """
      {
        "records": \(recordsString),
        "syncToken": "\(syncToken)",
        "moreComing": \(moreComing)
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
