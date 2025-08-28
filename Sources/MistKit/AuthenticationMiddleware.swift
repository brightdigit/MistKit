//
//  AuthenticationMiddleware.swift
//  PackageDSLKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
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

/// Authentication middleware for CloudKit requests
internal struct AuthenticationMiddleware: ClientMiddleware {
  internal let configuration: MistKitConfiguration
  private let tokenEncoder = CharacterMapEncoder()

  internal func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var modifiedRequest = request

    // Get the current path without query parameters
    let requestPath = request.path ?? ""
    let pathComponents = requestPath.split(separator: "?", maxSplits: 1)
    let cleanPath = String(pathComponents.first ?? "")

    // Create URL components from the clean path
    var urlComponents = URLComponents()
    urlComponents.path = cleanPath

    // Parse existing query items if any
    if pathComponents.count > 1 {
      let existingQuery = String(pathComponents[1])
      if let existingComponents = URLComponents(string: "?" + existingQuery) {
        urlComponents.queryItems = existingComponents.queryItems ?? []
      }
    }

    // Add authentication parameters
    var queryItems = urlComponents.queryItems ?? []
    queryItems.append(URLQueryItem(name: "ckAPIToken", value: configuration.apiToken))
    if let webAuthToken = configuration.webAuthToken {
      // Encode the web authentication token using CharacterMapEncoder
      let encodedWebAuthToken = tokenEncoder.encode(webAuthToken)
      queryItems.append(URLQueryItem(name: "ckWebAuthToken", value: encodedWebAuthToken))
    }

    urlComponents.queryItems = queryItems

    // Build the new path with query parameters
    if let query = urlComponents.query {
      modifiedRequest.path = cleanPath + "?" + query
    } else {
      modifiedRequest.path = cleanPath
    }

    return try await next(modifiedRequest, body, baseURL)
  }
}
