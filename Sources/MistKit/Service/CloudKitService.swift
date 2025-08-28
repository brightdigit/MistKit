//
//  CloudKitService.swift
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
import OpenAPIURLSession

/// Service for interacting with CloudKit Web Services
public struct CloudKitService {
  let containerIdentifier: String
  let apiToken: String
  let environment: String = "development"

  private let mistKitClient: MistKitClient
  private var client: Client {
    mistKitClient.client
  }

  /// Initialize CloudKit service
  public init(containerIdentifier: String, apiToken: String, webAuthToken: String) throws {
    self.containerIdentifier = containerIdentifier
    self.apiToken = apiToken

    let config = MistKitConfiguration(
      container: containerIdentifier,
      environment: .development,
      database: .private,
      apiToken: apiToken,
      webAuthToken: webAuthToken
    )
    self.mistKitClient = try MistKitClient(configuration: config)
  }

  /// Fetch current user information
  public func fetchCurrentUser() async throws -> UserInfo {
    let response = try await client.getCurrentUser(
      .init(
        path: createGetCurrentUserPath(containerIdentifier: containerIdentifier)
      )
    )

    let userData: Components.Schemas.UserResponse = try await processGetCurrentUserResponse(
      response)
    return UserInfo(from: userData)
  }

  /// List zones in the user's private database
  public func listZones() async throws -> [ZoneInfo] {
    let response = try await client.listZones(
      .init(
        path: createListZonesPath(containerIdentifier: containerIdentifier)
      )
    )

    let zonesData: Components.Schemas.ZonesListResponse = try await processListZonesResponse(
      response)
    return zonesData.zones?.compactMap { zone in
      guard let zoneID = zone.zoneID else { return nil }
      return ZoneInfo(
        zoneName: zoneID.zoneName ?? "Unknown",
        ownerRecordName: zoneID.ownerName,
        capabilities: []
      )
    } ?? []
  }

  /// Query records from the default zone
  public func queryRecords(recordType: String, limit: Int = 10) async throws -> [RecordInfo] {
    let response = try await client.queryRecords(
      .init(
        path: createQueryRecordsPath(containerIdentifier: containerIdentifier),
        body: .json(
          .init(
            zoneID: .init(zoneName: "_defaultZone"),
            resultsLimit: limit,
            query: .init(
              recordType: recordType,
              sortBy: [
                //                            .init(
                //                                fieldName: "modificationDate",
                //                                ascending: false
                //                            )
              ]
            )
          ))
      )
    )

    let recordsData: Components.Schemas.QueryResponse = try await processQueryRecordsResponse(
      response)
    return recordsData.records?.compactMap { RecordInfo(from: $0) } ?? []
  }
}

// MARK: - Private Helper Methods

extension CloudKitService {
  /// Create a standard path for getCurrentUser requests
  /// - Parameter containerIdentifier: The container identifier
  /// - Returns: A configured path for the request
  fileprivate func createGetCurrentUserPath(containerIdentifier: String)
    -> Operations.getCurrentUser.Input.Path
  {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .development,
      database: ._private
    )
  }

  /// Create a standard path for listZones requests
  /// - Parameter containerIdentifier: The container identifier
  /// - Returns: A configured path for the request
  fileprivate func createListZonesPath(containerIdentifier: String)
    -> Operations.listZones.Input.Path
  {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .development,
      database: ._private
    )
  }

  /// Create a standard path for queryRecords requests
  /// - Parameter containerIdentifier: The container identifier
  /// - Returns: A configured path for the request
  fileprivate func createQueryRecordsPath(containerIdentifier: String)
    -> Operations.queryRecords.Input.Path
  {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .development,
      database: ._private
    )
  }

  /// Process getCurrentUser response
  /// - Parameter response: The response to process
  /// - Returns: The extracted user data
  /// - Throws: CloudKitError for various error conditions
  fileprivate func processGetCurrentUserResponse(_ response: Operations.getCurrentUser.Output)
    async throws -> Components.Schemas.UserResponse
  {
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let userData):
        return userData
      }
    case .badRequest(let badRequestResponse):
      try await handleBadRequest(badRequestResponse)
    case .unauthorized(let unauthorizedResponse):
      try await handleUnauthorized(unauthorizedResponse)
    case .forbidden(let forbiddenResponse):
      try await handleForbidden(forbiddenResponse)
    case .notFound(let notFoundResponse):
      try await handleNotFound(notFoundResponse)
    case .conflict(let conflictResponse):
      try await handleConflict(conflictResponse)
    case .preconditionFailed(let preconditionFailedResponse):
      try await handlePreconditionFailed(preconditionFailedResponse)
    case .contentTooLarge(let contentTooLargeResponse):
      try await handleContentTooLarge(contentTooLargeResponse)
    case .tooManyRequests(let tooManyRequestsResponse):
      try await handleTooManyRequests(tooManyRequestsResponse)
    case .misdirectedRequest(let misdirectedRequestResponse):
      try await handleMisdirectedRequest(misdirectedRequestResponse)
    case .internalServerError(let internalServerErrorResponse):
      try await handleInternalServerError(internalServerErrorResponse)
    case .serviceUnavailable(let serviceUnavailableResponse):
      try await handleServiceUnavailable(serviceUnavailableResponse)
    case .undocumented(let statusCode, let undocumentedResponse):
      try await handleUndocumented(statusCode: statusCode, response: undocumentedResponse)
    }
  }

  /// Process listZones response
  /// - Parameter response: The response to process
  /// - Returns: The extracted zones data
  /// - Throws: CloudKitError for various error conditions
  fileprivate func processListZonesResponse(_ response: Operations.listZones.Output) async throws
    -> Components.Schemas.ZonesListResponse
  {
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let zonesData):
        return zonesData
      }
    case .badRequest(let badRequestResponse):
      try await handleBadRequest(badRequestResponse)
    case .unauthorized(let unauthorizedResponse):
      try await handleUnauthorized(unauthorizedResponse)
    case .forbidden(let forbiddenResponse):
      try await handleForbidden(forbiddenResponse)
    case .notFound(let notFoundResponse):
      try await handleNotFound(notFoundResponse)
    case .conflict(let conflictResponse):
      try await handleConflict(conflictResponse)
    case .preconditionFailed(let preconditionFailedResponse):
      try await handlePreconditionFailed(preconditionFailedResponse)
    case .contentTooLarge(let contentTooLargeResponse):
      try await handleContentTooLarge(contentTooLargeResponse)
    case .tooManyRequests(let tooManyRequestsResponse):
      try await handleTooManyRequests(tooManyRequestsResponse)
    case .misdirectedRequest(let misdirectedRequestResponse):
      try await handleMisdirectedRequest(misdirectedRequestResponse)
    case .internalServerError(let internalServerErrorResponse):
      try await handleInternalServerError(internalServerErrorResponse)
    case .serviceUnavailable(let serviceUnavailableResponse):
      try await handleServiceUnavailable(serviceUnavailableResponse)
    case .undocumented(let statusCode, let undocumentedResponse):
      try await handleUndocumented(statusCode: statusCode, response: undocumentedResponse)
    }
  }

  /// Process queryRecords response
  /// - Parameter response: The response to process
  /// - Returns: The extracted records data
  /// - Throws: CloudKitError for various error conditions
  fileprivate func processQueryRecordsResponse(_ response: Operations.queryRecords.Output)
    async throws -> Components.Schemas.QueryResponse
  {
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let recordsData):
        return recordsData
      }
    case .badRequest(let badRequestResponse):
      try await handleBadRequest(badRequestResponse)
    case .unauthorized(let unauthorizedResponse):
      try await handleUnauthorized(unauthorizedResponse)
    case .forbidden(let forbiddenResponse):
      try await handleForbidden(forbiddenResponse)
    case .notFound(let notFoundResponse):
      try await handleNotFound(notFoundResponse)
    case .conflict(let conflictResponse):
      try await handleConflict(conflictResponse)
    case .preconditionFailed(let preconditionFailedResponse):
      try await handlePreconditionFailed(preconditionFailedResponse)
    case .contentTooLarge(let contentTooLargeResponse):
      try await handleContentTooLarge(contentTooLargeResponse)
    case .tooManyRequests(let tooManyRequestsResponse):
      try await handleTooManyRequests(tooManyRequestsResponse)
    case .misdirectedRequest(let misdirectedRequestResponse):
      try await handleMisdirectedRequest(misdirectedRequestResponse)
    case .internalServerError(let internalServerErrorResponse):
      try await handleInternalServerError(internalServerErrorResponse)
    case .serviceUnavailable(let serviceUnavailableResponse):
      try await handleServiceUnavailable(serviceUnavailableResponse)
    case .undocumented(let statusCode, let undocumentedResponse):
      try await handleUndocumented(statusCode: statusCode, response: undocumentedResponse)
    }
  }

  // MARK: - Error Handling Methods

  fileprivate func handleBadRequest(_ response: Components.Responses.BadRequest) async throws
    -> Never
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

  fileprivate func handleUnauthorized(_ response: Components.Responses.Unauthorized) async throws
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

  fileprivate func handleForbidden(_ response: Components.Responses.Forbidden) async throws -> Never
  {
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

  fileprivate func handleNotFound(_ response: Components.Responses.NotFound) async throws -> Never {
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

  fileprivate func handleConflict(_ response: Components.Responses.Conflict) async throws -> Never {
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

  fileprivate func handlePreconditionFailed(_ response: Components.Responses.PreconditionFailed)
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

  fileprivate func handleContentTooLarge(_ response: Components.Responses.RequestEntityTooLarge)
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

  fileprivate func handleTooManyRequests(_ response: Components.Responses.TooManyRequests)
    async throws -> Never
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

  fileprivate func handleMisdirectedRequest(_ response: Components.Responses.UnprocessableEntity)
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

  fileprivate func handleInternalServerError(_ response: Components.Responses.InternalServerError)
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

  fileprivate func handleServiceUnavailable(_ response: Components.Responses.ServiceUnavailable)
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

  fileprivate func handleUndocumented(statusCode: Int, response: OpenAPIRuntime.UndocumentedPayload)
    async throws -> Never
  {
    if let responseBody = response.body {
      let errorData: Data
      do {
        errorData = try await Data(collecting: responseBody, upTo: 1_024 * 1_024)
      } catch {
        throw CloudKitError.httpError(statusCode: statusCode)
      }

      do {
        let errorResponse = try JSONDecoder().decode(
          Components.Schemas.ErrorResponse.self, from: errorData)
        throw CloudKitError.httpErrorWithDetails(
          statusCode: statusCode,
          serverErrorCode: errorResponse.serverErrorCode?.rawValue,
          reason: errorResponse.reason
        )
      } catch {
        if let errorText = String(data: errorData, encoding: .utf8) {
          throw CloudKitError.httpErrorWithRawResponse(
            statusCode: statusCode, rawResponse: errorText)
        } else {
          throw CloudKitError.httpError(statusCode: statusCode)
        }
      }
    } else {
      throw CloudKitError.httpError(statusCode: statusCode)
    }
  }
}
