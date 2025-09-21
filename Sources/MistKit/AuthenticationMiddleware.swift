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

import Crypto
public import Foundation
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

    // Apply authentication based on method type
    switch credentials.method {
    case .apiToken(let apiToken):
      // Add API token as query parameter
      var queryItems = urlComponents.queryItems ?? []
      queryItems.append(URLQueryItem(name: "ckAPIToken", value: apiToken))
      urlComponents.queryItems = queryItems

    case .webAuthToken(let apiToken, let webToken):
      // Add both API token and encoded web auth token as query parameters
      var queryItems = urlComponents.queryItems ?? []
      queryItems.append(URLQueryItem(name: "ckAPIToken", value: apiToken))
      let encodedWebAuthToken = tokenEncoder.encode(webToken)
      queryItems.append(URLQueryItem(name: "ckWebAuthToken", value: encodedWebAuthToken))
      urlComponents.queryItems = queryItems

    case .serverToServer:
      // Server-to-server authentication uses ECDSA P-256 signature in headers
      // Available on macOS 11.0+, iOS 14.0+, tvOS 14.0+, watchOS 7.0+, and Linux
      if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
        // For server-to-server auth, we expect the tokenManager to be a ServerToServerAuthManager
        // The actual signing should be handled by the ServerToServerAuthManager, not here
        if let serverAuthManager = tokenManager as? ServerToServerAuthManager {
          // Extract body data for signing
          let requestBodyData: Data?
          if let body = body {
            do {
              requestBodyData = try await Data(collecting: body, upTo: 1_024 * 1_024)
            } catch {
              requestBodyData = nil
            }
          } else {
            requestBodyData = nil
          }

          // According to Apple's documentation, the signature should use the Web Service URL Subpath
          // which is /database/1/[container]/[environment]/[operation-specific subpath]
          // NOT the full URL with https://api.apple-cloudkit.com
          let webServiceSubpath = modifiedRequest.path ?? ""

          let signature = try serverAuthManager.signRequest(
            requestBody: requestBodyData,
            webServiceURL: webServiceSubpath
          )

          // Add CloudKit headers
          modifiedRequest.headerFields[.init("X-Apple-CloudKit-Request-KeyID")!] = signature.keyID
          modifiedRequest.headerFields[.init("X-Apple-CloudKit-Request-ISO8601Date")!] =
            signature.date
          modifiedRequest.headerFields[.init("X-Apple-CloudKit-Request-SignatureV1")!] =
            signature.signature
        } else {
          throw TokenManagerError.internalError(
            reason: "Server-to-server credentials require ServerToServerAuthManager"
          )
        }
      } else {
        throw TokenManagerError.internalError(
          reason:
            "Server-to-server authentication requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+"
        )
      }
    }

    // Build the new path with query parameters (for API and Web auth)
    if let query = urlComponents.query {
      modifiedRequest.path = cleanPath + "?" + query
    } else {
      modifiedRequest.path = cleanPath
    }

    return try await next(modifiedRequest, body, baseURL)
  }
}
