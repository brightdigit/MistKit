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
    // Check for errors first
    if let error = CloudKitError(response) {
      throw error
    }

    // Must be .ok case - extract data
    switch response {
    case .ok(let okResponse):
      return try extractUserData(from: okResponse)
    default:
      // Should never reach here since all errors are handled above
      throw CloudKitError.invalidResponse
    }
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

  /// Process lookupRecords response
  /// - Parameter response: The response to process
  /// - Returns: The extracted lookup response data
  /// - Throws: CloudKitError for various error conditions
  internal func processLookupRecordsResponse(_ response: Operations.lookupRecords.Output)
    async throws(CloudKitError) -> Components.Schemas.LookupResponse
  {
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let lookupData):
        return lookupData
      }
    default:
      // For non-ok responses, throw a generic error
      // The response type doesn't expose detailed error info for all cases
      throw CloudKitError.invalidResponse
    }
  }

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
      // Log non-ok responses with full details when redaction is disabled
      MistKitLogger.logError(
        "CloudKit queryRecords failed with response: \(response)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )

      // Try to extract detailed error information
      if let error = CloudKitError(response) {
        throw error
      }

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
    // Check for errors first
    if let error = CloudKitError(response) {
      throw error
    }

    // Must be .ok case - extract data
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let modifyData):
        return modifyData
      }
    default:
      // Should never reach here since all errors are handled above
      throw CloudKitError.invalidResponse
    }
  }
}
