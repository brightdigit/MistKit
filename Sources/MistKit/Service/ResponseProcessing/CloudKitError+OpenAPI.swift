//
//  CloudKitError+OpenAPI.swift
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

extension CloudKitError {
  /// Generic error extractors that work for any CloudKitResponseType
  /// Acts as a reusable dictionary mapping response cases to error initializers
  private static let errorExtractors: [@Sendable (any CloudKitResponseType) -> CloudKitError?] = [
    { $0.badRequestResponse.map { CloudKitError(badRequest: $0) } },
    { $0.unauthorizedResponse.map { CloudKitError(unauthorized: $0) } },
    { $0.forbiddenResponse.map { CloudKitError(forbidden: $0) } },
    { $0.notFoundResponse.map { CloudKitError(notFound: $0) } },
    { $0.conflictResponse.map { CloudKitError(conflict: $0) } },
    { $0.preconditionFailedResponse.map { CloudKitError(preconditionFailed: $0) } },
    { $0.contentTooLargeResponse.map { CloudKitError(contentTooLarge: $0) } },
    { $0.misdirectedRequestResponse.map { CloudKitError(unprocessableEntity: $0) } },
    { $0.tooManyRequestsResponse.map { CloudKitError(tooManyRequests: $0) } },
    { $0.internalServerErrorResponse.map { CloudKitError(internalServerError: $0) } },
    { $0.serviceUnavailableResponse.map { CloudKitError(serviceUnavailable: $0) } },
  ]

  /// Generic failable initializer for any CloudKitResponseType
  /// Returns nil if the response is .ok (not an error)
  internal init?<T: CloudKitResponseType>(_ response: T) {
    // Check if response is .ok - not an error
    if response.isOk {
      return nil
    }

    // Try each error extractor
    for extractor in Self.errorExtractors {
      if let error = extractor(response) {
        self = error
        return
      }
    }

    // Handle undocumented error
    if let statusCode = response.undocumentedStatusCode {
      // Full body lives at debug level — may contain server-echoed request data
      // (e.g. emails passed to lookupUsersByEmail). Warning stays sanitized so
      // it can ship to ops/log aggregators without leaking PII.
      MistKitLogger.logDebug(
        "Unhandled response (HTTP \(statusCode)): \(response)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      MistKitLogger.logWarning(
        "Unhandled \(type(of: response)) (HTTP \(statusCode)) - treating as generic HTTP error",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      self = .httpError(statusCode: statusCode)
      return
    }

    MistKitLogger.logDebug(
      "Unhandled response case: \(response)",
      logger: MistKitLogger.api,
      shouldRedact: false
    )
    MistKitLogger.logWarning(
      "Unhandled \(type(of: response)) - treating as invalid response",
      logger: MistKitLogger.api,
      shouldRedact: false
    )
    self = .invalidResponse
  }
}
