//
//  CloudKitResponseProcessor.swift
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

internal import Foundation
import OpenAPIRuntime

/// Processes CloudKit API responses and handles errors
internal struct CloudKitResponseProcessor {
  /// Process getCurrentUser response
  /// - Parameter response: The response to process
  /// - Returns: The extracted user data
  /// - Throws: CloudKitError for various error conditions
  internal func processGetCurrentUserResponse(_ response: Operations.getCurrentUser.Output)
    async throws(CloudKitError) -> Components.Schemas.UserResponse
  {
    switch response {
    case .ok(let okResponse):
      return try extractUserData(from: okResponse)
    default:
      try await handleGetCurrentUserErrors(response)
    }

    throw CloudKitError.invalidResponse
  }

  /// Extract user data from OK response
  private func extractUserData(
    from response: Operations.getCurrentUser.Output.Ok
  ) throws(CloudKitError) -> Components.Schemas.UserResponse {
    switch response.body {
    case .json(let userData):
      return userData
    }
  }

  // swiftlint:disable cyclomatic_complexity
  /// Handle error cases for getCurrentUser
  private func handleGetCurrentUserErrors(_ response: Operations.getCurrentUser.Output)
    async throws(CloudKitError)
  {
    switch response {
    case .ok:
      return  // This case is handled in the main function
    case .badRequest(let badRequestResponse):
      throw CloudKitError(badRequest: badRequestResponse)
    case .unauthorized(let unauthorizedResponse):
      throw CloudKitError(unauthorized: unauthorizedResponse)
    case .forbidden(let forbiddenResponse):
      throw CloudKitError(forbidden: forbiddenResponse)
    case .notFound(let notFoundResponse):
      throw CloudKitError(notFound: notFoundResponse)
    case .conflict(let conflictResponse):
      throw CloudKitError(conflict: conflictResponse)
    case .preconditionFailed(let preconditionFailedResponse):
      throw CloudKitError(preconditionFailed: preconditionFailedResponse)
    case .contentTooLarge(let contentTooLargeResponse):
      throw CloudKitError(contentTooLarge: contentTooLargeResponse)
    case .tooManyRequests(let tooManyRequestsResponse):
      throw CloudKitError(tooManyRequests: tooManyRequestsResponse)
    case .misdirectedRequest(let misdirectedResponse):
      throw CloudKitError(unprocessableEntity: misdirectedResponse)
    case .internalServerError(let internalServerErrorResponse):
      throw CloudKitError(internalServerError: internalServerErrorResponse)
    case .serviceUnavailable(let serviceUnavailableResponse):
      throw CloudKitError(serviceUnavailable: serviceUnavailableResponse)
    case .undocumented(let statusCode, _):
      throw CloudKitError.httpError(statusCode: statusCode)
    }
  }
  // swiftlint:enable cyclomatic_complexity

  /// Process listZones response
  /// - Parameter response: The response to process
  /// - Returns: The extracted zones data
  /// - Throws: CloudKitError for various error conditions
  internal func processListZonesResponse(_ response: Operations.listZones.Output)
    async throws(CloudKitError)
    -> Components.Schemas.ZonesListResponse
  {
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let zonesData):
        return zonesData
      }
    default:
      // For non-ok responses, throw a generic error
      // The response type doesn't expose detailed error info for all cases
      throw CloudKitError.invalidResponse
    }
  }

  /// Process queryRecords response
  /// - Parameter response: The response to process
  /// - Returns: The extracted records data
  /// - Throws: CloudKitError for various error conditions
  internal func processQueryRecordsResponse(_ response: Operations.queryRecords.Output)
    async throws(CloudKitError) -> Components.Schemas.QueryResponse
  {
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let recordsData):
        return recordsData
      }
    default:
      // For non-ok responses, throw a generic error
      // The response type doesn't expose detailed error info for all cases
      throw CloudKitError.invalidResponse
    }
  }

  /// Process modifyRecords response
  /// - Parameter response: The response to process
  /// - Returns: The extracted modify response data
  /// - Throws: CloudKitError for various error conditions
  internal func processModifyRecordsResponse(_ response: Operations.modifyRecords.Output)
    async throws(CloudKitError) -> Components.Schemas.ModifyResponse
  {
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let modifyData):
        return modifyData
      }
    case .badRequest(let badResponse):
      switch badResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 400,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .unauthorized(let unauthResponse):
      switch unauthResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 401,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .forbidden(let forbiddenResponse):
      switch forbiddenResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 403,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .notFound(let notFoundResponse):
      switch notFoundResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 404,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .conflict(let conflictResponse):
      switch conflictResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 409,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .preconditionFailed(let preconditionResponse):
      switch preconditionResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 412,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .contentTooLarge(let tooLargeResponse):
      switch tooLargeResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 413,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .tooManyRequests(let tooManyResponse):
      switch tooManyResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 429,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .misdirectedRequest(let misdirectedResponse):
      switch misdirectedResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 421,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .internalServerError(let serverErrorResponse):
      switch serverErrorResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 500,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .serviceUnavailable(let unavailableResponse):
      switch unavailableResponse.body {
      case .json(let errorResponse):
        throw CloudKitError.httpErrorWithDetails(
          statusCode: 503,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      }
    case .undocumented(let statusCode, _):
      throw CloudKitError.httpError(statusCode: statusCode)
    }
  }
}
