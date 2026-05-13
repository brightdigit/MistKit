//
//  CredentialAvailability.swift
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

/// Why a credential set was missing when the dispatcher tried to satisfy
/// a request.
///
/// Attached to `CloudKitError.missingCredentials(_:availability:reason:)` so
/// callers can distinguish a misconfiguration ("no credentials at all") from
/// a deliberate `PublicAuthPreference.requires(...)` that couldn't be
/// satisfied ("we have web-auth but the caller required server-to-server").
public enum CredentialAvailability: Sendable, Hashable {
  /// No credential of the type the route needs is configured on
  /// `Credentials`.
  case notConfigured

  /// A credential type was required by `PublicAuthPreference.requires(_:)`
  /// but is not configured. The dispatcher refuses to silently substitute
  /// the other credential set.
  case preferenceRequired
}
