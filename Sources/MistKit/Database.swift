//
//  Database.swift
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

/// CloudKit database scope plus, for `.public`, the per-call attribution
/// choice between server-to-server signing and web-auth signing.
///
/// The auth payload is part of `.public` rather than a separate parameter
/// because it only matters there — CloudKit rejects server-to-server signing
/// on `.private` and `.shared`, so those cases carry no payload. Encoding
/// the choice in the type means call sites either pick one explicitly
/// (`Database.public(.requires(.webAuth))`) or use a scope where the choice
/// doesn't exist (`Database.private`).
public enum Database: Sendable, Hashable {
  /// Public database. Caller must pick a signing method via
  /// `PublicAuthPreference`.
  case `public`(PublicAuthPreference)

  /// Private database. Web-auth is the only valid signing method.
  case `private`

  /// Shared database. Web-auth is the only valid signing method.
  case shared

  /// The path segment used to build CloudKit Web Services URLs
  /// (`/database/{version}/{container}/{environment}/{database}/…`).
  public var pathSegment: String {
    switch self {
    case .public:
      return "public"
    case .private:
      return "private"
    case .shared:
      return "shared"
    }
  }
}
