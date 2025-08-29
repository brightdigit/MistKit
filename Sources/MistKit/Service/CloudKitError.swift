//
//  CloudKitError.swift
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

public import Foundation

internal enum CloudKitError: LocalizedError {
  case httpError(statusCode: Int)
  case httpErrorWithDetails(statusCode: Int, serverErrorCode: String?, reason: String?)
  case httpErrorWithRawResponse(statusCode: Int, rawResponse: String)
  case invalidResponse

  internal var errorDescription: String? {
    switch self {
    case .httpError(let statusCode):
      return "CloudKit API error: HTTP \(statusCode)"
    case let .httpErrorWithDetails(statusCode, serverErrorCode, reason):
      var message = "CloudKit API error: HTTP \(statusCode)"
      if let serverErrorCode = serverErrorCode {
        message += "\nServer Error Code: \(serverErrorCode)"
      }
      if let reason = reason {
        message += "\nReason: \(reason)"
      }
      return message
    case let .httpErrorWithRawResponse(statusCode, rawResponse):
      return "CloudKit API error: HTTP \(statusCode)\nRaw Response: \(rawResponse)"
    case .invalidResponse:
      return "Invalid response from CloudKit"
    }
  }
}
