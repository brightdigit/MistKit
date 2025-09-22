//
//  CloudKitErrorHandler.swift
//  PackageDSLKit
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

public import Foundation
import OpenAPIRuntime

/// Handles CloudKit API error responses
internal struct CloudKitErrorHandler {
  
  // MARK: - Generic Error Handler
  
  /// Generic error handler that extracts common error handling logic
  /// - Parameters:
  ///   - body: The response body containing error information
  ///   - statusCode: The HTTP status code for the error
  /// - Throws: CloudKitError with appropriate details
  private func handleErrorBody<T>(
    _ body: Components.Responses.ErrorResponseBody<T>,
    statusCode: Int
  ) async throws -> Never {
    if case .json(let errorResponse) = body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: statusCode,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: statusCode)
    }
  }
  
  // MARK: - Specific Error Handlers
  
  internal func handleBadRequest(_ response: Components.Responses.BadRequest) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 400)
  }

  internal func handleUnauthorized(_ response: Components.Responses.Unauthorized) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 401)
  }

  internal func handleForbidden(_ response: Components.Responses.Forbidden) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 403)
  }

  internal func handleNotFound(_ response: Components.Responses.NotFound) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 404)
  }

  internal func handleConflict(_ response: Components.Responses.Conflict) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 409)
  }

  internal func handlePreconditionFailed(_ response: Components.Responses.PreconditionFailed) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 412)
  }

  internal func handleContentTooLarge(_ response: Components.Responses.RequestEntityTooLarge) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 413)
  }

  internal func handleTooManyRequests(_ response: Components.Responses.TooManyRequests) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 429)
  }

  internal func handleMisdirectedRequest(_ response: Components.Responses.UnprocessableEntity) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 421)
  }

  internal func handleInternalServerError(_ response: Components.Responses.InternalServerError) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 500)
  }

  internal func handleServiceUnavailable(_ response: Components.Responses.ServiceUnavailable) async throws -> Never {
    try await handleErrorBody(response.body, statusCode: 503)
  }
}
