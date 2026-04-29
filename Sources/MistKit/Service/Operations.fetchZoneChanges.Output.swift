//
//  Operations.fetchZoneChanges.Output.swift
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

extension Operations.fetchZoneChanges.Output: CloudKitResponseType {
  internal var badRequestResponse: Components.Responses.BadRequest? {
    if case .badRequest(let response) = self {
      return response
    } else {
      return nil
    }
  }

  internal var unauthorizedResponse: Components.Responses.Unauthorized? {
    if case .unauthorized(let response) = self {
      return response
    } else {
      return nil
    }
  }

  internal var isOk: Bool {
    if case .ok = self {
      return true
    } else {
      return false
    }
  }

  internal var undocumentedStatusCode: Int? {
    if case .undocumented(let statusCode, _) = self {
      return statusCode
    } else {
      return nil
    }
  }

  // fetchZoneChanges only defines 200, 400, 401 responses
  internal var forbiddenResponse: Components.Responses.Forbidden? { nil }
  internal var notFoundResponse: Components.Responses.NotFound? { nil }
  internal var conflictResponse: Components.Responses.Conflict? { nil }
  internal var preconditionFailedResponse: Components.Responses.PreconditionFailed? { nil }
  internal var contentTooLargeResponse: Components.Responses.RequestEntityTooLarge? { nil }
  internal var misdirectedRequestResponse: Components.Responses.UnprocessableEntity? { nil }
  internal var tooManyRequestsResponse: Components.Responses.TooManyRequests? { nil }
  internal var internalServerErrorResponse: Components.Responses.InternalServerError? { nil }
  internal var serviceUnavailableResponse: Components.Responses.ServiceUnavailable? { nil }
}
