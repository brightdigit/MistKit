//
//  CloudKitError+OpenAPI.swift
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

extension CloudKitError {
  /// Initialize CloudKitError from a BadRequest response
  internal init(badRequest response: Components.Responses.BadRequest) {
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
  internal init(unauthorized response: Components.Responses.Unauthorized) {
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
  internal init(forbidden response: Components.Responses.Forbidden) {
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
  internal init(notFound response: Components.Responses.NotFound) {
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
  internal init(conflict response: Components.Responses.Conflict) {
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
  internal init(preconditionFailed response: Components.Responses.PreconditionFailed) {
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
  internal init(contentTooLarge response: Components.Responses.RequestEntityTooLarge) {
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
  internal init(tooManyRequests response: Components.Responses.TooManyRequests) {
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
  internal init(unprocessableEntity response: Components.Responses.UnprocessableEntity) {
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
  internal init(internalServerError response: Components.Responses.InternalServerError) {
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
  internal init(serviceUnavailable response: Components.Responses.ServiceUnavailable) {
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
  
  /// Static error handlers for modifyRecords response
  internal static let modifyRecordsErrorHandlers:
  [@Sendable (
    Operations.modifyRecords.Output
  ) -> CloudKitError?] = [
    {
      if case .badRequest(let response) = $0 {
        return CloudKitError(badRequest: response)
      } else {
        return nil
      }
    },
    {
      if case .unauthorized(let response) = $0 {
        return CloudKitError(unauthorized: response)
      } else {
        return nil
      }
    },
    {
      if case .forbidden(let response) = $0 {
        return CloudKitError(forbidden: response)
      } else {
        return nil
      }
    },
    {
      if case .notFound(let response) = $0 {
        return CloudKitError(notFound: response)
      } else {
        return nil
      }
    },
    {
      if case .conflict(let response) = $0 {
        return CloudKitError(conflict: response)
      } else {
        return nil
      }
    },
    {
      if case .preconditionFailed(let response) = $0 {
        return CloudKitError(preconditionFailed: response)
      } else {
        return nil
      }
    },
    {
      if case .contentTooLarge(let response) = $0 {
        return CloudKitError(contentTooLarge: response)
      } else {
        return nil
      }
    },
    {
      if case .misdirectedRequest(let response) = $0 {
        return CloudKitError(unprocessableEntity: response)
      } else {
        return nil
      }
    },
    {
      if case .tooManyRequests(let response) = $0 {
        return CloudKitError(tooManyRequests: response)
      } else {
        return nil
      }
    },
    {
      if case .internalServerError(let response) = $0 {
        return CloudKitError(internalServerError: response)
      } else {
        return nil
      }
    },
    {
      if case .serviceUnavailable(let response) = $0 {
        return CloudKitError(serviceUnavailable: response)
      } else {
        return nil
      }
    },
  ]
}
