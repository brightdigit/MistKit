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

internal import Foundation
internal import HTTPTypes
internal import OpenAPIRuntime

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

  /// Every request received, in order, captured for test assertions.
  private var requestLog: [(operationID: String, body: Data?)] = []

  // MARK: - Initializers

  internal init(
    responses: [String: ResponseConfig] = [:],
    defaultResponse: ResponseConfig = .success()
  ) {
    self.responses = responses
    self.defaultResponse = defaultResponse
  }

  // MARK: - Factory Methods

  /// Response provider for authentication errors
  internal static func authenticationError() -> ResponseProvider {
    ResponseProvider(defaultResponse: .authenticationError())
  }

  /// Response provider for successful query operations
  internal static func successfulQuery() -> ResponseProvider {
    ResponseProvider(defaultResponse: .successfulQuery())
  }

  /// Response provider that simulates a request timeout.
  internal static func timeout() -> ResponseProvider {
    ResponseProvider(defaultResponse: .timeout())
  }

  /// Response provider that simulates a connection failure.
  internal static func connectionLost() -> ResponseProvider {
    ResponseProvider(defaultResponse: .connectionLost())
  }

  // MARK: - Configuration

  internal func enqueue(_ response: ResponseConfig, for operationID: String) {
    responseQueues[operationID, default: []].append(response)
  }

  // MARK: - Request Inspection

  /// Number of requests received for `operationID`.
  internal func callCount(for operationID: String) -> Int {
    requestLog.filter { $0.operationID == operationID }.count
  }

  /// The request bodies received for `operationID`, in order.
  internal func bodies(for operationID: String) -> [Data?] {
    requestLog.filter { $0.operationID == operationID }.map(\.body)
  }

  internal func response(
    for operationID: String,
    request _: HTTPRequest,
    body: Data? = nil
  ) throws -> (HTTPResponse, HTTPBody?) {
    requestLog.append((operationID: operationID, body: body))

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
