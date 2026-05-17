//
//  Operations.modifyRecords.Output.swift
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

extension Operations.modifyRecords.Output: CloudKitResponseType {
  internal func toCloudKitError() -> CloudKitError? {
    switch self {
    case .ok: return nil
    case .badRequest(let response): return .init(response, statusCode: 400)
    case .unauthorized(let response): return .init(response, statusCode: 401)
    case .forbidden(let response): return .init(response, statusCode: 403)
    case .notFound(let response): return .init(response, statusCode: 404)
    case .conflict(let response): return .init(response, statusCode: 409)
    case .preconditionFailed(let response): return .init(response, statusCode: 412)
    case .contentTooLarge(let response): return .init(response, statusCode: 413)
    case .misdirectedRequest(let response): return .init(response, statusCode: 421)
    case .tooManyRequests(let response): return .init(response, statusCode: 429)
    case .internalServerError(let response): return .init(response, statusCode: 500)
    case .serviceUnavailable(let response): return .init(response, statusCode: 503)
    case .undocumented(let statusCode, _):
      return .undocumented(statusCode: statusCode, response: self)
    }
  }
}
