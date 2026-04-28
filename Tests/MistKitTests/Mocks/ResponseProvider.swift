//
//  ResponseProvider.swift
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

import HTTPTypes

/// Thread-safe provider for configuring mock responses
internal actor ResponseProvider {
  // MARK: - Type Properties

  /// Default successful response
  internal static var `default`: ResponseProvider {
    ResponseProvider(defaultResponse: .success())
  }

  // MARK: - Instance Properties

  private var responses: [String: ResponseConfig]
  private var defaultResponse: ResponseConfig
  private var responseQueues: [String: [ResponseConfig]] = [:]

  // MARK: - Initializers

  internal init(
    responses: [String: ResponseConfig] = [:],
    defaultResponse: ResponseConfig = .success()
  ) {
    self.responses = responses
    self.defaultResponse = defaultResponse
  }

  // MARK: - Factory Methods

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

  // MARK: - Configuration

  internal func configure(operationID: String, response: ResponseConfig) {
    responses[operationID] = response
  }

  internal func configureDefault(response: ResponseConfig) {
    defaultResponse = response
  }

  internal func enqueue(_ response: ResponseConfig, for operationID: String) {
    responseQueues[operationID, default: []].append(response)
  }

  internal func response(
    for operationID: String,
    request: HTTPRequest
  ) throws -> (HTTPResponse, HTTPBody?) {
    let config: ResponseConfig
    if var queue = responseQueues[operationID], !queue.isEmpty {
      config = queue.removeFirst()
      responseQueues[operationID] = queue
    } else {
      config = responses[operationID] ?? defaultResponse
    }

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
