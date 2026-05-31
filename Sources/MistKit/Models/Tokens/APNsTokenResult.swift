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

public import Foundation
internal import MistKitOpenAPI

/// A CloudKit-minted APNs token, returned by
/// ``CloudKitService/createAPNsToken(environment:database:)``.
///
/// Used by non-device callers (CloudKit JS in a browser, server processes) that
/// have no device APNs token to register. The `apnsToken` becomes the push
/// destination for subscription-triggered notifications. `webcourierURL` is the
/// long-poll endpoint browser / Service-Worker clients use to receive those
/// notifications; server callers receive pushes via APNs proper and can usually
/// ignore it.
public struct APNsTokenResult: Codable, Sendable, Equatable {
  /// The APNs environment the token targets (echoes the request).
  public let environment: APNsEnvironment
  /// The CloudKit-managed APNs token to use as a push destination.
  public let apnsToken: String
  /// Long-poll URL that browser / Service-Worker callers use to receive
  /// CloudKit-triggered push notifications.
  public let webcourierURL: URL

  /// Initialize an APNs token result.
  public init(environment: APNsEnvironment, apnsToken: String, webcourierURL: URL) {
    self.environment = environment
    self.apnsToken = apnsToken
    self.webcourierURL = webcourierURL
  }

  /// Convert a decoded `TokenResponse` into an `APNsTokenResult`.
  ///
  /// The OpenAPI schema makes all three fields required, so missing or
  /// malformed values represent server-side misbehavior rather than absence —
  /// conversion fails loudly (logged, asserted in DEBUG, and thrown) rather
  /// than silently producing an empty token or junk URL.
  internal init(from response: Components.Schemas.TokenResponse) throws(ConversionError) {
    guard let webcourierURL = URL(string: response.webcourierURL) else {
      try ConversionError.tokenMissingField(fieldName: "webcourierURL").reportAndThrow()
    }
    self.init(
      environment: APNsEnvironment(from: response.apnsEnvironment),
      apnsToken: response.apnsToken,
      webcourierURL: webcourierURL
    )
  }
}
