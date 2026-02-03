//
//  CloudKitServiceUploadTests+Helpers.swift
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

extension CloudKitServiceUploadTests {
  /// Create service for successful upload operations
  /// Test API token in 64-character hexadecimal format as required by MistKit validation
  private static let testAPIToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"

  /// Create a mock asset uploader that returns a successful upload response
  internal static func makeMockAssetUploader() -> AssetUploader {
    { data, url in
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
      return (200, response.data(using: .utf8)!)
    }
  }

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func makeSuccessfulUploadService(
    tokenCount: Int = 1
  ) async throws -> CloudKitService {
    let responseProvider = ResponseProvider.successfulUpload(tokenCount: tokenCount)

    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: testAPIToken,
      transport: transport
    )
  }

  /// Create service for validation error testing
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func makeUploadValidationErrorService(
    _ errorType: UploadValidationErrorType
  ) async throws -> CloudKitService {
    let responseProvider = ResponseProvider.uploadValidationError(errorType)

    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: testAPIToken,
      transport: transport
    )
  }

  /// Create service for auth errors
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

  /// Create service for asset data upload testing
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func makeAssetDataUploadService(tokenCount: Int = 1) async throws -> CloudKitService {
    let responseProvider = ResponseProvider.successfulUpload(tokenCount: tokenCount)

    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: testAPIToken,
      transport: transport
    )
  }
}

/// Types of upload validation errors that can occur
internal enum UploadValidationErrorType: Sendable {
  case emptyData
  case oversizedAsset(Int)
}

// MARK: - Upload Response Builders

extension ResponseProvider {
  /// Response provider for successful upload operations
  internal static func successfulUpload(tokenCount: Int = 1) -> ResponseProvider {
    ResponseProvider(defaultResponse: .successfulUploadResponse(tokenCount: tokenCount))
  }

  /// Response provider for upload validation errors
  internal static func uploadValidationError(_ type: UploadValidationErrorType) -> ResponseProvider {
    ResponseProvider(defaultResponse: .uploadValidationError(type))
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
        "fieldName": "file"
      ])
    }

    let tokensJSON = try! JSONSerialization.data(withJSONObject: tokens)
    let tokensString = String(data: tokensJSON, encoding: .utf8)!

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

  /// Creates an upload validation error response (400 Bad Request)
  ///
  /// - Parameter type: The type of upload validation error
  /// - Returns: ResponseConfig with appropriate validation error message
  internal static func uploadValidationError(_ type: UploadValidationErrorType) -> ResponseConfig {
    let reason: String
    switch type {
    case .emptyData:
      reason = "Asset data cannot be empty"
    case .oversizedAsset(let size):
      reason = "Asset size \(size) bytes exceeds maximum allowed size of 262144000 bytes (250 MB)"
    }

    return cloudKitError(
      statusCode: 400,
      serverErrorCode: "BAD_REQUEST",
      reason: reason
    )
  }

  /// Creates a successful asset data upload response (binary upload to CDN)
  ///
  /// - Returns: ResponseConfig with CloudKit asset upload response
  internal static func successfulAssetDataUpload() -> ResponseConfig {
    let responseJSON = """
      {
        "singleFile": {
          "wrappingKey": "test-wrapping-key-abc123",
          "fileChecksum": "test-checksum-def456",
          "receipt": "test-receipt-token-xyz",
          "referenceChecksum": "test-ref-checksum-789",
          "size": 1024
        }
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
