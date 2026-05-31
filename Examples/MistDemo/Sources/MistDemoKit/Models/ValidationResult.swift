//
//  ValidationResult.swift
//  MistDemo
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
public import MistKit

/// Structured outcome of the `validate` command.
public struct ValidationResult: Encodable, Sendable {
  /// Whether MistDemo successfully parsed the configured credentials into a
  /// `CloudKitService`. False indicates a configuration error (missing or
  /// malformed env vars / config file).
  public let credentialsValid: Bool
  /// Whether the configuration carries API + web-auth tokens. User-identity
  /// routes (`fetchCaller`, `lookupUsers*`) require this.
  public let webAuthConfigured: Bool
  /// Whether the configuration carries a key ID + private key material.
  /// Required to sign `.public` database requests.
  public let serverToServerConfigured: Bool
  /// Caller info returned by `users/caller`. Nil when the network check was
  /// skipped or when web-auth wasn't configured.
  public let userInfo: UserInfo?
  /// Zones returned by the optional `--test-query`. Nil when the flag wasn't
  /// passed or the call failed (in which case `errors` carries the reason).
  public let zonesFound: Int?
  /// Human-readable error messages collected during validation. Empty on
  /// full success.
  public let errors: [String]

  /// Creates a new instance.
  public init(
    credentialsValid: Bool,
    webAuthConfigured: Bool,
    serverToServerConfigured: Bool,
    userInfo: UserInfo? = nil,
    zonesFound: Int? = nil,
    errors: [String] = []
  ) {
    self.credentialsValid = credentialsValid
    self.webAuthConfigured = webAuthConfigured
    self.serverToServerConfigured = serverToServerConfigured
    self.userInfo = userInfo
    self.zonesFound = zonesFound
    self.errors = errors
  }
}
