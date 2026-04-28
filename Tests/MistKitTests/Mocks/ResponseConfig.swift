//
//  ResponseConfig.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

/// Configuration for a mock HTTP response
internal struct ResponseConfig: Sendable {
  internal let statusCode: Int
  internal let headers: HTTPFields
  internal let body: Data?
  internal let error: (any Error)?

  internal init(
    statusCode: Int,
    headers: HTTPFields = HTTPFields(),
    body: Data? = nil,
    error: (any Error)? = nil
  ) {
    self.statusCode = statusCode
    self.headers = headers
    self.body = body
    self.error = error
  }

  // MARK: - Factory Methods

  /// Successful response (200 OK)
  internal static func success(body: Data? = nil) -> ResponseConfig {
    var headers = HTTPFields()
    if body != nil {
      headers[.contentType] = "application/json"
    }
    return ResponseConfig(
      statusCode: 200,
      headers: headers,
      body: body,
      error: nil
    )
  }

  /// HTTP error with status code
  internal static func httpError(statusCode: Int, message: String? = nil) -> ResponseConfig {
    let body: Data? =
      if let msg = message {
        Data(
          """
          {
            "error": "\(msg)"
          }
          """.utf8
        )
      } else {
        nil
      }

    var headers = HTTPFields()
    if body != nil {
      headers[.contentType] = "application/json"
    }

    return ResponseConfig(
      statusCode: statusCode,
      headers: headers,
      body: body,
      error: nil
    )
  }
}

// MARK: - CloudKit Response Builders

extension ResponseConfig {
  /// Creates a CloudKit error response
  internal static func cloudKitError(
    statusCode: Int,
    serverErrorCode: String = "BAD_REQUEST",
    reason: String,
    uuid: String = UUID().uuidString
  ) -> ResponseConfig {
    let errorJSON = """
      {
        "uuid": "\(uuid)",
        "serverErrorCode": "\(serverErrorCode)",
        "reason": "\(reason)"
      }
      """

    var headers = HTTPFields()
    headers[.contentType] = "application/json"

    return ResponseConfig(
      statusCode: statusCode,
      headers: headers,
      body: Data(errorJSON.utf8),
      error: nil
    )
  }

  /// Creates a validation error response (400 Bad Request)
  internal static func validationError(_ type: ValidationErrorType) -> ResponseConfig {
    let reason: String
    switch type {
    case .emptyRecordType:
      reason = "recordType cannot be empty"
    case .limitTooSmall(let limit):
      reason = "limit must be between 1 and 200, got \(limit)"
    case .limitTooLarge(let limit):
      reason = "limit must be between 1 and 200, got \(limit)"
    }

    return cloudKitError(
      statusCode: 400,
      serverErrorCode: "BAD_REQUEST",
      reason: reason
    )
  }

  /// Creates an authentication error response (401 Unauthorized)
  internal static func authenticationError() -> ResponseConfig {
    cloudKitError(
      statusCode: 401,
      serverErrorCode: "AUTHENTICATION_FAILED",
      reason: "Authentication failed"
    )
  }

  /// Creates a successful query response
  internal static func successfulQuery(records: [String: Any] = [:]) -> ResponseConfig {
    let responseJSON = """
      {
        "records": []
      }
      """

    var headers = HTTPFields()
    headers[.contentType] = "application/json"

    return ResponseConfig(
      statusCode: 200,
      headers: headers,
      body: Data(responseJSON.utf8),
      error: nil
    )
  }
}
