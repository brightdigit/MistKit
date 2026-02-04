//
//  Operations.fetchRecordChanges.Output.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

extension Operations.fetchRecordChanges.Output: CloudKitResponseType {
  var badRequestResponse: Components.Responses.BadRequest? {
    if case .badRequest(let response) = self { return response } else { return nil }
  }

  var unauthorizedResponse: Components.Responses.Unauthorized? {
    if case .unauthorized(let response) = self { return response } else { return nil }
  }

  var forbiddenResponse: Components.Responses.Forbidden? {
    if case .forbidden(let response) = self { return response } else { return nil }
  }

  var notFoundResponse: Components.Responses.NotFound? {
    if case .notFound(let response) = self { return response } else { return nil }
  }

  var conflictResponse: Components.Responses.Conflict? {
    if case .conflict(let response) = self { return response } else { return nil }
  }

  var preconditionFailedResponse: Components.Responses.PreconditionFailed? {
    if case .preconditionFailed(let response) = self { return response } else { return nil }
  }

  var contentTooLargeResponse: Components.Responses.RequestEntityTooLarge? {
    if case .contentTooLarge(let response) = self { return response } else { return nil }
  }

  var misdirectedRequestResponse: Components.Responses.UnprocessableEntity? {
    if case .misdirectedRequest(let response) = self { return response } else { return nil }
  }

  var tooManyRequestsResponse: Components.Responses.TooManyRequests? {
    if case .tooManyRequests(let response) = self { return response } else { return nil }
  }

  var isOk: Bool {
    if case .ok = self { return true } else { return false }
  }

  var undocumentedStatusCode: Int? {
    if case .undocumented(let statusCode, _) = self { return statusCode } else { return nil }
  }

  // fetchRecordChanges has most error responses except 500/503
  var internalServerErrorResponse: Components.Responses.InternalServerError? { nil }
  var serviceUnavailableResponse: Components.Responses.ServiceUnavailable? { nil }
}
