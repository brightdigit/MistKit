//
//  AuthenticationMiddleware.swift
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

internal import Foundation
internal import HTTPTypes
internal import Logging
internal import OpenAPIRuntime

/// Authentication middleware that delegates request mutation to whichever
/// `Authenticator` the `TokenManager` currently vends.
internal struct AuthenticationMiddleware: ClientMiddleware {
  internal let tokenManager: any TokenManager

  internal func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    guard let authenticator = try await tokenManager.currentAuthenticator() else {
      throw TokenManagerError.invalidCredentials(.noCredentialsAvailable)
    }

    var modifiedRequest = request
    var modifiedBody = body
    try await authenticator.authenticate(request: &modifiedRequest, body: &modifiedBody)
    let (response, responseBody) = try await next(modifiedRequest, modifiedBody, baseURL)
    if let rotated = response.headerFields[.cloudKitWebAuthToken] {
      do {
        try await tokenManager.didReceiveRotatedWebAuthToken(rotated)
      } catch {
        let message = "Failed to consume rotated web auth token: \(error.localizedDescription)"
        Logger(subsystem: .auth).warning("\(message)")
        RotatedWebAuthTokenFailureReporter.assertionHandler(message)
      }
    }
    return (response, responseBody)
  }
}
