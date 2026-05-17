//
//  CloudKitServiceTests.QueryPagination+Helpers.swift
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

extension CloudKitServiceTests.QueryPagination {
  private static let testAPIToken =
    TestConstants.apiToken

  internal static func makeSuccessfulService(
    recordCount: Int = 2,
    continuationMarker: String? = nil
  ) throws -> CloudKitService {
    let responseProvider = ResponseProvider(
      defaultResponse: try .successfulQueryResponse(
        recordCount: recordCount,
        continuationMarker: continuationMarker
      )
    )
    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(apiAuth: APICredentials(apiToken: testAPIToken)),
      transport: transport
    )
  }

  internal static func makePaginatedService(
    pages: [(recordCount: Int, continuationMarker: String?)]
  ) async throws -> CloudKitService {
    let provider = ResponseProvider(
      defaultResponse: try .successfulQueryResponse()
    )
    for page in pages {
      await provider.enqueue(
        try .successfulQueryResponse(
          recordCount: page.recordCount,
          continuationMarker: page.continuationMarker
        ),
        for: "queryRecords"
      )
    }
    let transport = MockTransport(responseProvider: provider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(apiAuth: APICredentials(apiToken: testAPIToken)),
      transport: transport
    )
  }
}

// MARK: - Query Pagination Response Builders

extension ResponseConfig {
  internal static func successfulQueryResponse(
    recordCount: Int = 0,
    continuationMarker: String? = nil
  ) throws -> ResponseConfig {
    var records: [[String: Any]] = []
    for index in 0..<recordCount {
      records.append([
        "recordName": "record-\(index)",
        "recordType": "TestRecord",
        "recordChangeTag": "tag-\(index)",
        "fields": [String: Any](),
      ])
    }

    var responseDict: [String: Any] = ["records": records]
    if let marker = continuationMarker {
      responseDict["continuationMarker"] = marker
    }

    let bodyData = try JSONSerialization.data(withJSONObject: responseDict)

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
