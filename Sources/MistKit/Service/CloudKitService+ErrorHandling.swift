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

import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Maps any error thrown from a CloudKit operation to a typed CloudKitError.
  /// Includes detailed logging for decoding and network errors.
  ///
  /// - Parameters:
  ///   - error: The error to map
  ///   - context: A description of the operation (e.g., "fetchCurrentUser")
  /// - Returns: A CloudKitError representing the original error
  internal func mapToCloudKitError(
    _ error: any Error,
    context: String
  ) -> CloudKitError {
    if let cloudKitError = error as? CloudKitError {
      return cloudKitError
    }

    if let decodingError = error as? DecodingError {
      MistKitLogger.logError(
        "JSON decoding failed in \(context): \(decodingError)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      logDecodingErrorDetails(decodingError)
      return CloudKitError.decodingError(decodingError)
    }

    if let urlError = error as? URLError {
      MistKitLogger.logError(
        "Network error in \(context): \(urlError)",
        logger: MistKitLogger.network,
        shouldRedact: false
      )
      return CloudKitError.networkError(urlError)
    }

    MistKitLogger.logError(
      "Unexpected error in \(context): \(error)",
      logger: MistKitLogger.api,
      shouldRedact: false
    )
    MistKitLogger.logDebug(
      "Error type: \(type(of: error)), Description: \(String(reflecting: error))",
      logger: MistKitLogger.api,
      shouldRedact: false
    )
    return CloudKitError.underlyingError(error)
  }

  /// Logs detailed context for a DecodingError to aid debugging.
  private func logDecodingErrorDetails(_ decodingError: DecodingError) {
    switch decodingError {
    case .keyNotFound(let key, let context):
      MistKitLogger.logDebug(
        "Missing key: \(key), Context: \(context.debugDescription), "
          + "Coding path: \(context.codingPath)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
    case .typeMismatch(let type, let context):
      MistKitLogger.logDebug(
        "Type mismatch: expected \(type), Context: \(context.debugDescription), "
          + "Coding path: \(context.codingPath)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
    case .valueNotFound(let type, let context):
      MistKitLogger.logDebug(
        "Value not found: expected \(type), Context: \(context.debugDescription), "
          + "Coding path: \(context.codingPath)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
    case .dataCorrupted(let context):
      MistKitLogger.logDebug(
        "Data corrupted, Context: \(context.debugDescription), "
          + "Coding path: \(context.codingPath)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
    @unknown default:
      MistKitLogger.logDebug(
        "Unknown decoding error type",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
    }
  }
}
