//
//  CloudKitError.swift
//  MistKitExamples
//
//  Created by Leo Dion on 7/9/25.
//

import Foundation

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
