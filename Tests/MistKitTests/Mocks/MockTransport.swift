//
//  MockTransport.swift
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
import OpenAPIRuntime

/// Mock transport for testing that doesn't make actual network calls
internal struct MockTransport: ClientTransport, Sendable {
  internal let responseProvider: ResponseProvider

  internal init(responseProvider: ResponseProvider = .default) {
    self.responseProvider = responseProvider
  }

  internal func send(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String
  ) async throws -> (HTTPResponse, HTTPBody?) {
    try await responseProvider.response(for: operationID, request: request)
  }
}

/// Thread-safe provider for configuring mock responses
internal actor ResponseProvider {
  // MARK: - Factory Methods

  /// Default successful response
  internal static var `default`: ResponseProvider {
    ResponseProvider(defaultResponse: .success())
  }

  /// Response provider for validation errors
  internal static func validationError(_ type: ValidationErrorType) -> ResponseProvider {
    ResponseProvider(defaultResponse: .validationError(type))
  }

  /// Response provider for authentication errors
  internal static func authenticationError() -> ResponseProvider {
    ResponseProvider(defaultResponse: .authenticationError())
  }

  /// Response provider for successful query operations
  internal static func successfulQuery(records: [String: Any] = [:]) -> ResponseProvider {
    ResponseProvider(defaultResponse: .successfulQuery(records: records))
  }

  // MARK: - Lifecycle

  internal init(
    responses: [String: ResponseConfig] = [:],
    defaultResponse: ResponseConfig = .success()
  ) {
    self.responses = responses
    self.defaultResponse = defaultResponse
  }

  // MARK: - Internal

  private var responses: [String: ResponseConfig]
  private var defaultResponse: ResponseConfig

  internal func configure(operationID: String, response: ResponseConfig) {
    responses[operationID] = response
  }

  internal func configureDefault(response: ResponseConfig) {
    defaultResponse = response
  }

  internal func response(
    for operationID: String,
    request: HTTPRequest
  ) throws -> (HTTPResponse, HTTPBody?) {
    let config = responses[operationID] ?? defaultResponse

    if let error = config.error {
      throw error
    }

    let response = HTTPResponse(
      status: .init(code: config.statusCode),
      headerFields: config.headers
    )

    let body: HTTPBody? =
      if let data = config.body {
        HTTPBody(data)
      } else {
        nil
      }

    return (response, body)
  }
}

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
        """
        {
          "error": "\(msg)"
        }
        """.data(using: .utf8)
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

/// Types of validation errors that can occur
internal enum ValidationErrorType: Sendable {
  case emptyRecordType
  case limitTooSmall(Int)
  case limitTooLarge(Int)
}

// MARK: - CloudKit Response Builders

extension ResponseConfig {
  /// Creates a CloudKit error response
  ///
  /// - Parameters:
  ///   - statusCode: HTTP status code
  ///   - serverErrorCode: CloudKit server error code (e.g., "BAD_REQUEST")
  ///   - reason: Human-readable error reason
  ///   - uuid: Optional UUID for the error (generated if not provided)
  /// - Returns: ResponseConfig with CloudKit-formatted error JSON
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
      body: errorJSON.data(using: .utf8),
      error: nil
    )
  }

  /// Creates a validation error response (400 Bad Request)
  ///
  /// - Parameter type: The type of validation error
  /// - Returns: ResponseConfig with appropriate validation error message
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
  ///
  /// - Returns: ResponseConfig with authentication error
  internal static func authenticationError() -> ResponseConfig {
    cloudKitError(
      statusCode: 401,
      serverErrorCode: "AUTHENTICATION_FAILED",
      reason: "Authentication failed"
    )
  }

  /// Creates a successful query response
  ///
  /// - Parameter records: Dictionary of record data to include in the response
  /// - Returns: ResponseConfig with successful query response
  internal static func successfulQuery(records: [String: Any] = [:]) -> ResponseConfig {
    // Simple empty records response for now
    // Can be expanded later to support actual record data
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
      body: responseJSON.data(using: .utf8),
      error: nil
    )
  }
}
