//
//  CloudKitResponseType.swift
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

/// Protocol for CloudKit operation response types that support unified error handling
internal protocol CloudKitResponseType {
  /// Extract BadRequest response if present
  var badRequestResponse: Components.Responses.BadRequest? { get }

  /// Extract Unauthorized response if present
  var unauthorizedResponse: Components.Responses.Unauthorized? { get }

  /// Extract Forbidden response if present
  var forbiddenResponse: Components.Responses.Forbidden? { get }

  /// Extract NotFound response if present
  var notFoundResponse: Components.Responses.NotFound? { get }

  /// Extract Conflict response if present
  var conflictResponse: Components.Responses.Conflict? { get }

  /// Extract PreconditionFailed response if present
  var preconditionFailedResponse: Components.Responses.PreconditionFailed? { get }

  /// Extract ContentTooLarge response if present
  var contentTooLargeResponse: Components.Responses.RequestEntityTooLarge? { get }

  /// Extract MisdirectedRequest response if present
  var misdirectedRequestResponse: Components.Responses.UnprocessableEntity? { get }

  /// Extract TooManyRequests response if present
  var tooManyRequestsResponse: Components.Responses.TooManyRequests? { get }

  /// Extract InternalServerError response if present
  var internalServerErrorResponse: Components.Responses.InternalServerError? { get }

  /// Extract ServiceUnavailable response if present
  var serviceUnavailableResponse: Components.Responses.ServiceUnavailable? { get }

  /// Check if response is successful (.ok case)
  var isOk: Bool { get }

  /// Extract status code from undocumented response if present
  var undocumentedStatusCode: Int? { get }
}
