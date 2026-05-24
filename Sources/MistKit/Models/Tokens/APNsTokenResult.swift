//
//  APNsTokenResult.swift
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

internal import MistKitOpenAPI

/// A CloudKit-minted APNs token, returned by
/// ``CloudKitService/createAPNsToken(environment:database:)``.
///
/// Used by non-device callers (CloudKit JS in a browser, server processes) that
/// have no device APNs token to register. The `apnsToken` becomes the push
/// destination for subscription-triggered notifications; the `webAuthToken` is
/// the web-push auth secret handed to a browser's web-push registration.
public struct APNsTokenResult: Codable, Sendable, Equatable {
  /// The CloudKit-managed APNs token to use as a push destination.
  public let apnsToken: String
  /// The web-push auth secret (the API spells this `webcAuthToken`).
  public let webAuthToken: String

  /// Initialize an APNs token result.
  public init(apnsToken: String, webAuthToken: String) {
    self.apnsToken = apnsToken
    self.webAuthToken = webAuthToken
  }

  /// Convert a decoded `TokenResponse` into an `APNsTokenResult`.
  ///
  /// Both fields are optional in the OpenAPI schema but required in a successful
  /// response; a missing field is a conversion failure (logged, asserted in
  /// DEBUG, and thrown) rather than a silently-empty token.
  internal init(from response: Components.Schemas.TokenResponse) throws(ConversionError) {
    guard let apnsToken = response.apnsToken else {
      try ConversionError.tokenMissingField(fieldName: "apnsToken").reportAndThrow()
    }
    guard let webcAuthToken = response.webcAuthToken else {
      try ConversionError.tokenMissingField(fieldName: "webcAuthToken").reportAndThrow()
    }
    self.init(apnsToken: apnsToken, webAuthToken: webcAuthToken)
  }
}
