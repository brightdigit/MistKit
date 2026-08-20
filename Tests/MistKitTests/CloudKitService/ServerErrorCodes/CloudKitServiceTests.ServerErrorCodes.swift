//
//  CloudKitServiceTests.ServerErrorCodes.swift
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

internal import Testing

@testable import MistKit

extension CloudKitServiceTests {
  /// Roundtrip coverage for every documented CloudKit `serverErrorCode`: a
  /// mock transport returns the coded failure body and the operation must
  /// surface the dedicated ``CloudKitError`` case for it.
  @Suite("CloudKitService serverErrorCode mapping", .enabled(if: Platform.isCryptoAvailable))
  internal enum ServerErrorCodes {
    /// One row of the roundtrip table: the wire code, the HTTP status it
    /// arrives with, and the ``CloudKitError`` case label expected back.
    internal struct Expectation: Sendable, CustomStringConvertible {
      internal let code: String
      internal let statusCode: Int
      internal let caseLabel: String

      internal var description: String {
        "\(code) → .\(caseLabel)"
      }

      internal init(_ code: String, _ statusCode: Int, _ caseLabel: String) {
        self.code = code
        self.statusCode = statusCode
        self.caseLabel = caseLabel
      }
    }

    /// Every code enumerated by the `ErrorResponse.serverErrorCode` enum in
    /// `openapi.yaml`, paired with the case it must map to.
    internal static let expectations: [Expectation] = [
      Expectation("ACCESS_DENIED", 403, "accessDenied"),
      Expectation("ATOMIC_ERROR", 400, "atomicFailure"),
      Expectation("AUTHENTICATION_FAILED", 401, "authenticationFailed"),
      Expectation("AUTHENTICATION_REQUIRED", 421, "authenticationRequired"),
      Expectation("BAD_REQUEST", 400, "badRequest"),
      Expectation("CONFLICT", 409, "conflict"),
      Expectation("EXISTS", 409, "exists"),
      Expectation("INTERNAL_ERROR", 500, "internalServerError"),
      Expectation("NOT_FOUND", 404, "notFound"),
      Expectation("QUOTA_EXCEEDED", 413, "quotaExceeded"),
      Expectation("THROTTLED", 429, "throttled"),
      Expectation("TRY_AGAIN_LATER", 503, "tryAgainLater"),
      Expectation("VALIDATING_REFERENCE_ERROR", 412, "validatingReferenceError"),
      Expectation("ZONE_NOT_FOUND", 404, "zoneNotFound"),
    ]
  }
}
