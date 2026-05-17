//
//  TestConstants.swift
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

/// Shared constants used across the MistKit test suite.
///
/// Centralizes magic strings that previously appeared verbatim in many test files:
/// API tokens, web-auth tokens, container identifiers, zone names, and operation IDs.
internal enum TestConstants {
  /// 64-character hexadecimal API token in the format MistKit's regex validation expects.
  internal static let apiToken =
    "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"

  /// Sample web-auth token used by middleware and client tests.
  ///
  /// Length and character set satisfy `webAuthTokenRegex`
  /// (`^[A-Za-z0-9+/=_]{100,}$`) so tests remain valid if regex-based
  /// validation is later added to `WebAuthTokenManager.validateCredentials()`.
  internal static let webAuthToken =
    "user123webauthtokenabcdef0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    + "abcdefghijklmnopqrstuvwxyz0123456789AB=="

  /// Container identifier used by `CloudKitService` integration-style tests.
  internal static let serviceContainerIdentifier = "iCloud.com.example.test"

  /// Default operation ID used in middleware intercept tests.
  internal static let operationID = "test-operation"
}
