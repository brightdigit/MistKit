//
//  MistKitLogger.swift
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

import Foundation
import Logging

/// Centralized logging infrastructure for MistKit
internal enum MistKitLogger {
  // MARK: - Subsystems

  /// Logger for CloudKit API operations
  internal static let api = Logger(label: "com.brightdigit.MistKit.api")

  /// Logger for authentication and token management
  internal static let auth = Logger(label: "com.brightdigit.MistKit.auth")

  /// Logger for network operations
  internal static let network = Logger(label: "com.brightdigit.MistKit.network")

  // MARK: - Log Redaction Control

  /// Check if log redaction is disabled via environment variable
  internal static var isRedactionDisabled: Bool {
    ProcessInfo.processInfo.environment["MISTKIT_DISABLE_LOG_REDACTION"] == "1"
  }

  // MARK: - Logging Helpers

  /// Log error with optional redaction
  internal static func logError(
    _ message: String,
    logger: Logger,
    shouldRedact: Bool = true
  ) {
    let finalMessage = (isRedactionDisabled || !shouldRedact) ? message : SecureLogging.safeLogMessage(message)
    logger.error("\(finalMessage)")
  }

  /// Log warning with optional redaction
  internal static func logWarning(
    _ message: String,
    logger: Logger,
    shouldRedact: Bool = true
  ) {
    let finalMessage = (isRedactionDisabled || !shouldRedact) ? message : SecureLogging.safeLogMessage(message)
    logger.warning("\(finalMessage)")
  }

  /// Log info with optional redaction
  internal static func logInfo(
    _ message: String,
    logger: Logger,
    shouldRedact: Bool = true
  ) {
    let finalMessage = (isRedactionDisabled || !shouldRedact) ? message : SecureLogging.safeLogMessage(message)
    logger.info("\(finalMessage)")
  }

  /// Log debug with optional redaction
  internal static func logDebug(
    _ message: String,
    logger: Logger,
    shouldRedact: Bool = true
  ) {
    let finalMessage = (isRedactionDisabled || !shouldRedact) ? message : SecureLogging.safeLogMessage(message)
    logger.debug("\(finalMessage)")
  }
}
