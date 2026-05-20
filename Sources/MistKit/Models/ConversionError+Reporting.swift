//
//  ConversionError+Reporting.swift
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

internal import Logging

/// Trap hook used by ``ConversionError/reportAndThrow(function:file:line:)``.
///
/// The default handler calls Swift's `assertionFailure`, so a response→domain
/// conversion failure traps loudly in DEBUG. Tests override the handler via
/// `ConversionFailureReporter.$assertionHandler.withValue({ _, _, _ in }) { … }`
/// to exercise the throw path without trapping the test process.
internal enum ConversionFailureReporter {
  @TaskLocal internal static var assertionHandler: @Sendable (String, StaticString, UInt) -> Void =
    { message, file, line in
      assertionFailure(message, file: file, line: line)
    }
}

extension ConversionError {
  /// Wraps this typed conversion failure into a ``CloudKitError`` for the
  /// `CloudKitService` boundary, which throws `CloudKitError`.
  internal var asCloudKitError: CloudKitError {
    .conversionFailed(self)
  }

  /// Reports a response→domain conversion failure loudly and uniformly:
  /// - logs at `.error` on every build (with full context),
  /// - traps via the injectable assertion handler in DEBUG (no-op in release),
  /// - always throws `self` (a typed ``ConversionError``) so callers never
  ///   receive silently-truncated data.
  ///
  /// The `-> Never` shape lets call sites read as a single `try` statement.
  /// In DEBUG the handler traps *before* the throw is reached; in release it is
  /// a no-op, so the function logs then throws.
  internal func reportAndThrow(
    function: StaticString = #function,
    file: StaticString = #fileID,
    line: UInt = #line
  ) throws(ConversionError) -> Never {
    let message = self.message
    Logger(subsystem: .api).error("Conversion failure in \(function): \(message)")
    ConversionFailureReporter.assertionHandler(message, file, line)
    throw self
  }
}
