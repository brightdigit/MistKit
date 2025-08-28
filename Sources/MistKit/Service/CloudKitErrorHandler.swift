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

import Foundation
import OpenAPIRuntime

/// Handles CloudKit API error responses
internal struct CloudKitErrorHandler {
  internal func handleBadRequest(_ response: Components.Responses.BadRequest) async throws -> Never
  {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 400,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 400)
    }
  }

  internal func handleUnauthorized(_ response: Components.Responses.Unauthorized) async throws
    -> Never
  {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 401,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 401)
    }
  }

  internal func handleForbidden(_ response: Components.Responses.Forbidden) async throws -> Never {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 403,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 403)
    }
  }

  internal func handleNotFound(_ response: Components.Responses.NotFound) async throws -> Never {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 404,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 404)
    }
  }

  internal func handleConflict(_ response: Components.Responses.Conflict) async throws -> Never {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 409,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 409)
    }
  }

  internal func handlePreconditionFailed(_ response: Components.Responses.PreconditionFailed)
    async throws -> Never
  {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 412,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 412)
    }
  }

  internal func handleContentTooLarge(_ response: Components.Responses.RequestEntityTooLarge)
    async throws -> Never
  {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 413,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 413)
    }
  }

  internal func handleTooManyRequests(_ response: Components.Responses.TooManyRequests) async throws
    -> Never
  {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 429,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 429)
    }
  }

  internal func handleMisdirectedRequest(_ response: Components.Responses.UnprocessableEntity)
    async throws -> Never
  {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 421,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 421)
    }
  }

  internal func handleInternalServerError(_ response: Components.Responses.InternalServerError)
    async throws -> Never
  {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 500,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 500)
    }
  }

  internal func handleServiceUnavailable(_ response: Components.Responses.ServiceUnavailable)
    async throws -> Never
  {
    if case .json(let errorResponse) = response.body {
      throw CloudKitError.httpErrorWithDetails(
        statusCode: 503,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    } else {
      throw CloudKitError.httpError(statusCode: 503)
    }
  }
}
