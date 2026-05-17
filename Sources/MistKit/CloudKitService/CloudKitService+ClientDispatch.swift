//
//  CloudKitService+ClientDispatch.swift
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
internal import MistKitOpenAPI
internal import OpenAPIRuntime

extension CloudKitService {
  /// Resolve the token manager for an outgoing request and build a fresh
  /// OpenAPI `Client` whose middleware chain authenticates against it.
  ///
  /// Called once per dispatched operation. The signing choice for `.public`
  /// requests is carried by the `Database` value itself
  /// (`.public(PublicAuthPreference)`); `.private` / `.shared` always use
  /// web-auth.
  ///
  /// When the service was built with a caller-supplied `tokenManager:`, that
  /// fixed manager is used regardless of `database`. Otherwise `Credentials`
  /// resolves the manager via `makeTokenManager(for:)`.
  ///
  /// - Throws: `CloudKitError.missingCredentials` when `Credentials` cannot
  ///   satisfy the requested combination.
  internal func client(
    for database: Database
  ) throws -> Client {
    let tokenManager: any TokenManager
    if let fixedTokenManager {
      tokenManager = fixedTokenManager
    } else if let credentials {
      tokenManager = try credentials.makeTokenManager(for: database)
    } else {
      throw CloudKitError.missingCredentials(
        database: database,
        availability: .notConfigured,
        reason: "service has neither credentials nor a fixed token manager"
      )
    }

    return Client(
      serverURL: CloudKitService.baseURL,
      transport: transport,
      middlewares: [
        AuthenticationMiddleware(tokenManager: tokenManager),
        LoggingMiddleware(),
      ]
    )
  }
}
