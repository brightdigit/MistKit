//
//  CloudKitResponseProcessor+Subscriptions.swift
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

internal import MistKitOpenAPI

extension CloudKitResponseProcessor {
  /// Process listSubscriptions response.
  internal func processListSubscriptionsResponse(
    _ response: Operations.listSubscriptions.Output
  ) async throws(CloudKitError) -> Components.Schemas.SubscriptionsListResponse {
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let subscriptionsData):
        return subscriptionsData
      }
    case .badRequest, .unauthorized, .undocumented:
      throw CloudKitError(response) ?? .invalidResponse
    }
  }

  /// Process lookupSubscriptions response.
  internal func processLookupSubscriptionsResponse(
    _ response: Operations.lookupSubscriptions.Output
  ) async throws(CloudKitError) -> Components.Schemas.SubscriptionsLookupResponse {
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let subscriptionsData):
        return subscriptionsData
      }
    case .badRequest, .unauthorized, .undocumented:
      throw CloudKitError(response) ?? .invalidResponse
    }
  }

  /// Process modifySubscriptions response.
  internal func processModifySubscriptionsResponse(
    _ response: Operations.modifySubscriptions.Output
  ) async throws(CloudKitError) -> Components.Schemas.SubscriptionsModifyResponse {
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let subscriptionsData):
        return subscriptionsData
      }
    case .badRequest, .unauthorized, .undocumented:
      throw CloudKitError(response) ?? .invalidResponse
    }
  }
}
