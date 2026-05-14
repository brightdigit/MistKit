//
//  PublicAuthPreference.swift
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

/// Per-call attribution choice for `Database.public` requests.
///
/// CloudKit's public database accepts two signing methods:
/// server-to-server (key-pair signed, attributed to the developer key) and
/// web-auth (user session token, attributed to the iCloud user). The same
/// server legitimately writes some records as "the app" and others as
/// "this user", so the choice is genuinely per-call.
///
/// Construct via the static factories — `internal init` keeps the four
/// valid `(mode, required)` combinations the only reachable ones.
///
/// ```swift
/// // Server-attributed write, fall back to web-auth if S2S isn't configured.
/// service.createRecord(..., database: .public(.prefers(.serverToServer)))
///
/// // User-attributed write, throw if web-auth credentials aren't configured.
/// service.createRecord(..., database: .public(.requires(.webAuth)))
/// ```
public struct PublicAuthPreference: Sendable, Hashable {
  /// Which signing material to use for a `.public` request.
  public enum Mode: Sendable, Hashable {
    /// Sign with the server-to-server key pair. Records are attributed to
    /// the developer key, not an end user.
    case serverToServer

    /// Sign with the user's web-auth token. Records are attributed to the
    /// iCloud user that issued the token.
    case webAuth
  }

  /// The signing material the caller wants.
  public let mode: Mode

  /// Whether to throw if `mode`'s credentials aren't configured.
  ///
  /// - `true` → throw `CloudKitError.missingCredentials(availability: .preferenceRequired)`.
  /// - `false` → fall back to the other configured credential set when possible.
  public let required: Bool

  /// Prefer the given mode; fall back to the other if it isn't configured.
  public static func prefers(_ mode: Mode) -> Self {
    .init(mode: mode, required: false)
  }

  /// Require the given mode; throw `missingCredentials(.preferenceRequired)`
  /// if its credentials aren't configured.
  public static func requires(_ mode: Mode) -> Self {
    .init(mode: mode, required: true)
  }
}
