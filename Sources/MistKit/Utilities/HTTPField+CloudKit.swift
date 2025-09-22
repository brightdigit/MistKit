//
//  HTTPField+CloudKit.swift
//  MistKit
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

import HTTPTypes

/// Extension providing static properties for CloudKit-specific HTTP header field names
extension HTTPField.Name {
  /// CloudKit request key ID header field name
  /// Used for server-to-server authentication to identify the key used for signing
  // swiftlint:disable:next force_unwrapping
  // swift-format:disable:all
  internal static let cloudKitRequestKeyID = HTTPField.Name(
    "X-Apple-CloudKit-Request-KeyID")!
  // swift-format:enable:all

  /// CloudKit request ISO8601 date header field name
  /// Used for server-to-server authentication to provide the timestamp for the request
  // swiftlint:disable:next force_unwrapping
  // swift-format:disable:all
  internal static let cloudKitRequestISO8601Date = HTTPField.Name(
    "X-Apple-CloudKit-Request-ISO8601Date")!
  // swift-format:enable:all

  /// CloudKit request signature V1 header field name
  /// Used for server-to-server authentication to provide the ECDSA P-256 signature
  // swiftlint:disable:next force_unwrapping
  // swift-format:disable:all
  internal static let cloudKitRequestSignatureV1 = HTTPField.Name(
    "X-Apple-CloudKit-Request-SignatureV1")!
  // swift-format:enable:all
}
