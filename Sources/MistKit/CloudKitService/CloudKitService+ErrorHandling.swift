//
//  CloudKitService+ErrorHandling.swift
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

internal import Foundation
internal import Logging
internal import OpenAPIRuntime

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

extension CloudKitService {
  /// Maps any error thrown from a CloudKit operation to a typed CloudKitError.
  /// Includes detailed logging for decoding and network errors.
  ///
  /// - Parameters:
  ///   - error: The error to map
  ///   - context: A description of the operation (e.g., "fetchCaller")
  /// - Returns: A CloudKitError representing the original error
  internal func mapToCloudKitError(
    _ error: any Error,
    context: String
  ) -> CloudKitError {
    if let cloudKitError = error as? CloudKitError {
      return cloudKitError
    }

    // OpenAPIRuntime wraps transport-level errors in ClientError; unwrap to inspect the cause.
    let inspected: any Error =
      (error as? ClientError)?.underlyingError ?? error

    let apiLogger = Logger(subsystem: .api)

    if let decodingError = inspected as? DecodingError {
      apiLogger.error("JSON decoding failed in \(context): \(decodingError)")
      logDecodingErrorDetails(decodingError, logger: apiLogger)
      return CloudKitError.decodingError(decodingError)
    }

    if let urlError = inspected as? URLError {
      Logger(subsystem: .network).error("Network error in \(context): \(urlError)")
      return CloudKitError.networkError(urlError)
    }

    apiLogger.error("Unexpected error in \(context): \(error)")
    apiLogger.debug(
      "Error type: \(type(of: error)), Description: \(String(reflecting: error))"
    )
    return CloudKitError.underlyingError(error)
  }

  /// Logs detailed context for a DecodingError to aid debugging.
  private func logDecodingErrorDetails(
    _ decodingError: DecodingError,
    logger: Logger
  ) {
    switch decodingError {
    case .keyNotFound(let key, let context):
      logger.debug(
        "Missing key: \(key), Context: \(context.debugDescription), Coding path: \(context.codingPath)"
      )
    case .typeMismatch(let type, let context):
      logger.debug(
        """
        Type mismatch: expected \(type), Context: \(context.debugDescription), \
        Coding path: \(context.codingPath)
        """
      )
    case .valueNotFound(let type, let context):
      logger.debug(
        """
        Value not found: expected \(type), Context: \(context.debugDescription), \
        Coding path: \(context.codingPath)
        """
      )
    case .dataCorrupted(let context):
      logger.debug(
        "Data corrupted, Context: \(context.debugDescription), Coding path: \(context.codingPath)"
      )
    @unknown default:
      logger.debug("Unknown decoding error type")
    }
  }
}
