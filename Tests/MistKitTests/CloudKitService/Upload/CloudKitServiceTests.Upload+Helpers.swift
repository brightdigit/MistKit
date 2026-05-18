//
//  CloudKitServiceTests.Upload+Helpers.swift
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

extension CloudKitServiceTests.Upload {
  /// Create service for successful upload operations
  /// Test API token in 64-character hexadecimal format as required by MistKit validation
  private static let testAPIToken =
    TestConstants.apiToken

  /// Create a mock asset uploader that returns a successful upload response
  internal static func makeMockAssetUploader() -> AssetUploader {
    { data, _ in
      let response = """
        {
          "singleFile": {
            "wrappingKey": "test-wrapping-key-abc123",
            "fileChecksum": "test-checksum-def456",
            "receipt": "test-receipt-token-xyz",
            "referenceChecksum": "test-ref-checksum-789",
            "size": \(data.count)
          }
        }
        """
      return (200, Data(response.utf8))
    }
  }

  @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  internal static func makeSuccessfulUploadService(
    tokenCount: Int = 1
  ) async throws -> CloudKitService {
    let responseProvider = ResponseProvider.successfulUpload(tokenCount: tokenCount)

    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(apiAuth: APICredentials(apiToken: testAPIToken)),
      transport: transport
    )
  }

  /// Create service that responds with a 400 BAD_REQUEST for any call —
  /// used to exercise CloudKit's server-side bad-request path on
  /// asset-upload operations.
  @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  internal static func makeUploadBadRequestService(
    reason: String = "Asset data cannot be empty"
  ) async throws -> CloudKitService {
    let provider = ResponseProvider(
      defaultResponse: .cloudKitError(
        statusCode: 400,
        serverErrorCode: "BAD_REQUEST",
        reason: reason
      )
    )
    let transport = MockTransport(responseProvider: provider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(apiAuth: APICredentials(apiToken: testAPIToken)),
      transport: transport
    )
  }

  /// Create service for auth errors
  @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  internal static func makeAuthErrorService() async throws -> CloudKitService {
    let responseProvider = ResponseProvider.authenticationError()

    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(apiAuth: APICredentials(apiToken: testAPIToken)),
      transport: transport
    )
  }
}

// MARK: - Upload Response Builders

extension ResponseProvider {
  /// Response provider for successful upload operations
  internal static func successfulUpload(tokenCount: Int = 1) -> ResponseProvider {
    ResponseProvider(defaultResponse: .successfulUploadResponse(tokenCount: tokenCount))
  }
}

extension ResponseConfig {
  /// Creates a successful asset upload response
  ///
  /// - Parameter tokenCount: Number of upload tokens to include in response
  /// - Returns: ResponseConfig with successful upload response
  internal static func successfulUploadResponse(tokenCount: Int = 1) -> ResponseConfig {
    var tokens: [[String: Any]] = []
    for index in 0..<tokenCount {
      tokens.append([
        "url": "https://cvws.icloud-content.com/test-token-\(index)",
        "recordName": "test-record-\(index)",
        "fieldName": "file",
      ])
    }

    let tokensJSON = (try? JSONSerialization.data(withJSONObject: tokens)) ?? Data()
    let tokensString = String(data: tokensJSON, encoding: .utf8) ?? "[]"

    let responseJSON = """
      {
        "tokens": \(tokensString)
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

  /// Creates an upload response where the token has no recordName field
  internal static func uploadResponseWithNilRecordName() -> ResponseConfig {
    let responseJSON = """
      {
        "tokens": [
          {
            "url": "https://cvws.icloud-content.com/test-upload-url",
            "fieldName": "file"
          }
        ]
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
