//
//  CloudKitResponseProcessor+Changes.swift
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

internal import Foundation
import OpenAPIRuntime

extension CloudKitResponseProcessor {
  /// Process fetchRecordChanges response
  /// - Parameter response: The response to process
  /// - Returns: The extracted changes response data
  /// - Throws: CloudKitError for various error conditions
  internal func processFetchRecordChangesResponse(_ response: Operations.fetchRecordChanges.Output)
    async throws(CloudKitError) -> Components.Schemas.ChangesResponse
  {
    if let error = CloudKitError(response) {
      throw error
    }
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let changesData):
        return changesData
      }
    default:
      assertionFailure("Unexpected response case after error handling")
      throw CloudKitError.invalidResponse
    }
  }

  /// Process discoverUserIdentities response
  internal func processDiscoverUserIdentitiesResponse(
    _ response: Operations.discoverUserIdentities.Output
  ) async throws(CloudKitError) -> Components.Schemas.DiscoverResponse {
    if let error = CloudKitError(response) {
      throw error
    }
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let discoverData):
        return discoverData
      }
    default:
      assertionFailure("Unexpected response case after error handling")
      throw CloudKitError.invalidResponse
    }
  }

  /// Process uploadAssets response
  /// - Parameter response: The response to process
  /// - Returns: The extracted asset upload response data
  /// - Throws: CloudKitError for various error conditions
  internal func processUploadAssetsResponse(_ response: Operations.uploadAssets.Output)
    async throws(CloudKitError) -> Components.Schemas.AssetUploadResponse
  {
    if let error = CloudKitError(response) {
      throw error
    }
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let uploadData):
        return uploadData
      }
    default:
      assertionFailure("Unexpected response case after error handling")
      throw CloudKitError.invalidResponse
    }
  }

  /// Process fetchZoneChanges response
  internal func processFetchZoneChangesResponse(_ response: Operations.fetchZoneChanges.Output)
    async throws(CloudKitError) -> Components.Schemas.ZoneChangesResponse
  {
    if let error = CloudKitError(response) {
      throw error
    }
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let changesData):
        return changesData
      }
    default:
      assertionFailure("Unexpected response case after error handling")
      throw CloudKitError.invalidResponse
    }
  }
}
