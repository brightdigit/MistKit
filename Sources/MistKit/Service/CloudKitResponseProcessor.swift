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
  private let errorHandler = CloudKitErrorHandler()

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
      try await errorHandler.handleBadRequest(badRequestResponse)
    case .unauthorized(let unauthorizedResponse):
      try await errorHandler.handleUnauthorized(unauthorizedResponse)
    case .forbidden(let forbiddenResponse):
      try await errorHandler.handleForbidden(forbiddenResponse)
    case .notFound(let notFoundResponse):
      try await errorHandler.handleNotFound(notFoundResponse)
    case .conflict(let conflictResponse):
      try await errorHandler.handleConflict(conflictResponse)
    case .preconditionFailed(let preconditionFailedResponse):
      try await errorHandler.handlePreconditionFailed(preconditionFailedResponse)
    case .contentTooLarge(let contentTooLargeResponse):
      try await errorHandler.handleContentTooLarge(contentTooLargeResponse)
    case .tooManyRequests(let tooManyRequestsResponse):
      try await errorHandler.handleTooManyRequests(tooManyRequestsResponse)
    case .misdirectedRequest(let misdirectedResponse):
      try await errorHandler.handleMisdirectedRequest(misdirectedResponse)
    case .internalServerError(let internalServerErrorResponse):
      try await errorHandler.handleInternalServerError(internalServerErrorResponse)
    case .serviceUnavailable(let serviceUnavailableResponse):
      try await errorHandler.handleServiceUnavailable(serviceUnavailableResponse)
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
      try await processStandardErrorResponse(response)
    }

    throw CloudKitError.invalidResponse
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
      try await processStandardErrorResponse(response)
    }

    throw CloudKitError.invalidResponse
  }
}

// MARK: - Error Handling
extension CloudKitResponseProcessor {
  /// Process standard error responses common across endpoints
  private func processStandardErrorResponse<T>(_: T) async throws(CloudKitError) {
    // For now, throw a generic error - specific error handling should be implemented
    // per endpoint as needed to avoid the complexity of reflection-based error handling
    throw CloudKitError.invalidResponse
  }
}
