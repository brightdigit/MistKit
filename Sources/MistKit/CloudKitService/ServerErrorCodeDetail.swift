//
//  ServerErrorCodeDetail.swift
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

/// Wire identity of a CloudKit failure that carried a `serverErrorCode`.
///
/// Produced by `CloudKitError.serverErrorDetail` so that a code, the HTTP
/// status Apple documents for it, and the human summary used in error
/// descriptions all live in exactly one place.
internal struct ServerErrorCodeDetail: Sendable {
  /// The raw CloudKit `serverErrorCode` string, e.g. `"ACCESS_DENIED"`.
  internal let code: String
  /// The HTTP status Apple documents for `code`.
  internal let statusCode: Int
  /// Lowercase human summary used when building the error description.
  internal let summary: String
  /// The server-supplied `reason`, when the failure body carried one.
  internal let reason: String?

  /// Creates a detail describing one CloudKit `serverErrorCode` failure.
  internal init(code: String, statusCode: Int, summary: String, reason: String?) {
    self.code = code
    self.statusCode = statusCode
    self.summary = summary
    self.reason = reason
  }
}
