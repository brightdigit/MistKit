//
//  CloudKitError+OpenAPI.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

  /// Initialize CloudKitError from a BadRequest response
  private init(badRequest response: Components.Responses.BadRequest) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 400,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 400)
    }
  }

  /// Initialize CloudKitError from an Unauthorized response
  private init(unauthorized response: Components.Responses.Unauthorized) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 401,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 401)
    }
  }

  /// Initialize CloudKitError from a Forbidden response
  private init(forbidden response: Components.Responses.Forbidden) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 403,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 403)
    }
  }

  /// Initialize CloudKitError from a NotFound response
  private init(notFound response: Components.Responses.NotFound) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 404,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 404)
    }
  }

  /// Initialize CloudKitError from a Conflict response
  private init(conflict response: Components.Responses.Conflict) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 409,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 409)
    }
  }

  /// Initialize CloudKitError from a PreconditionFailed response
  private init(preconditionFailed response: Components.Responses.PreconditionFailed) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 412,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 412)
    }
  }

  /// Initialize CloudKitError from a RequestEntityTooLarge response
  private init(contentTooLarge response: Components.Responses.RequestEntityTooLarge) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 413,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 413)
    }
  }

  /// Initialize CloudKitError from a TooManyRequests response
  private init(tooManyRequests response: Components.Responses.TooManyRequests) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 429,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 429)
    }
  }

  /// Initialize CloudKitError from an UnprocessableEntity response
  private init(unprocessableEntity response: Components.Responses.UnprocessableEntity) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 422,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 422)
    }
  }

  /// Initialize CloudKitError from an InternalServerError response
  private init(internalServerError response: Components.Responses.InternalServerError) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 500,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 500)
    }
  }

  /// Initialize CloudKitError from a ServiceUnavailable response
  private init(serviceUnavailable response: Components.Responses.ServiceUnavailable) {
    if case .json(let errorResponse) = response.body {
      self = .httpErrorWithDetails(
        statusCode: 503,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      self = .httpError(statusCode: 503)
    }
  }

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
      // Log warning but don't crash - undocumented status codes can occur
      MistKitLogger.logWarning(
        "Unhandled response status code: \(statusCode) - treating as generic HTTP error",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      self = .httpError(statusCode: statusCode)
      return
    }

    // Should never reach here - log and return generic error
    MistKitLogger.logWarning(
      "Unhandled response case: \(response) - treating as invalid response",
      logger: MistKitLogger.api,
      shouldRedact: false
    )
    self = .invalidResponse
  }
}
