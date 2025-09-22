//
//  AuthenticationMiddleware.swift
//  MistKit
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

import Crypto
import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Authentication middleware for CloudKit requests using TokenManager
internal struct AuthenticationMiddleware: ClientMiddleware {
  internal let tokenManager: any TokenManager
  private let tokenEncoder = CharacterMapEncoder()

  /// Creates authentication middleware with a TokenManager
  /// - Parameter tokenManager: The token manager to use for authentication
  internal init(tokenManager: any TokenManager) {
    self.tokenManager = tokenManager
  }

  internal func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    // Get credentials from token manager
    guard let credentials = try await tokenManager.getCurrentCredentials() else {
      throw TokenManagerError.invalidCredentials(reason: "No credentials available")
    }

    var modifiedRequest = request
    var urlComponents = parseRequestPath(request.path ?? "")

    // Apply authentication based on method type
    switch credentials.method {
    case .apiToken(let apiToken):
      addAPITokenAuthentication(apiToken: apiToken, to: &urlComponents)

    case .webAuthToken(let apiToken, let webToken):
      addWebAuthTokenAuthentication(apiToken: apiToken, webToken: webToken, to: &urlComponents)

    case .serverToServer:
      modifiedRequest = try await addServerToServerAuthentication(to: modifiedRequest, body: body)
    }

    // Build the new path with query parameters (for API and Web auth)
    updateRequestPath(&modifiedRequest, with: urlComponents)

    return try await next(modifiedRequest, body, baseURL)
  }

  // MARK: - Private Helper Methods

  private func parseRequestPath(_ requestPath: String) -> URLComponents {
    let pathComponents = requestPath.split(separator: "?", maxSplits: 1)
    let cleanPath = String(pathComponents.first ?? "")

    var urlComponents = URLComponents()
    urlComponents.path = cleanPath

    // Parse existing query items if any
    if pathComponents.count > 1 {
      let existingQuery = String(pathComponents[1])
      if let existingComponents = URLComponents(string: "?" + existingQuery) {
        urlComponents.queryItems = existingComponents.queryItems ?? []
      }
    }

    return urlComponents
  }

  private func addAPITokenAuthentication(apiToken: String, to urlComponents: inout URLComponents) {
    var queryItems = urlComponents.queryItems ?? []
    queryItems.append(URLQueryItem(name: "ckAPIToken", value: apiToken))
    urlComponents.queryItems = queryItems
  }

  private func addWebAuthTokenAuthentication(
    apiToken: String,
    webToken: String,
    to urlComponents: inout URLComponents
  ) {
    var queryItems = urlComponents.queryItems ?? []
    queryItems.append(URLQueryItem(name: "ckAPIToken", value: apiToken))
    let encodedWebAuthToken = tokenEncoder.encode(webToken)
    queryItems.append(URLQueryItem(name: "ckWebAuthToken", value: encodedWebAuthToken))
    urlComponents.queryItems = queryItems
  }

  private func addServerToServerAuthentication(
    to request: HTTPRequest,
    body: HTTPBody?
  ) async throws -> HTTPRequest {
    // Server-to-server authentication uses ECDSA P-256 signature in headers
    // Available on macOS 11.0+, iOS 14.0+, tvOS 14.0+, watchOS 7.0+, and Linux
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      throw TokenManagerError.internalError(
        reason:
          "Server-to-server authentication requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+"
      )
    }

    guard let serverAuthManager = tokenManager as? ServerToServerAuthManager else {
      throw TokenManagerError.internalError(
        reason: "Server-to-server credentials require ServerToServerAuthManager"
      )
    }

    // Extract body data for signing
    let requestBodyData = try await extractRequestBodyData(from: body)
    let webServiceSubpath = request.path ?? ""

    let signature = try serverAuthManager.signRequest(
      requestBody: requestBodyData,
      webServiceURL: webServiceSubpath
    )

    var modifiedRequest = request
    modifiedRequest.headerFields[.cloudKitRequestKeyID] = signature.keyID
    modifiedRequest.headerFields[.cloudKitRequestISO8601Date] = signature.date
    modifiedRequest.headerFields[.cloudKitRequestSignatureV1] = signature.signature

    return modifiedRequest
  }

  private func extractRequestBodyData(from body: HTTPBody?) async throws -> Data? {
    guard let body = body else { return nil }

    do {
      return try await Data(collecting: body, upTo: 1_024 * 1_024)
    } catch {
      return nil
    }
  }

  private func updateRequestPath(_ request: inout HTTPRequest, with urlComponents: URLComponents) {
    let cleanPath = urlComponents.path
    if let query = urlComponents.query {
      request.path = cleanPath + "?" + query
    } else {
      request.path = cleanPath
    }
  }
}
