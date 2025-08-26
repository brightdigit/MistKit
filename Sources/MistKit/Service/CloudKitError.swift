//
//  CloudKitError.swift
//  MistKitExamples
//
//  Created by Leo Dion on 7/9/25.
//

import Foundation

enum CloudKitError: LocalizedError {
  case httpError(statusCode: Int)
  case httpErrorWithDetails(statusCode: Int, serverErrorCode: String?, reason: String?)
  case httpErrorWithRawResponse(statusCode: Int, rawResponse: String)
  case invalidResponse

  var errorDescription: String? {
    switch self {
    case .httpError(let statusCode):
      return "CloudKit API error: HTTP \(statusCode)"
    case .httpErrorWithDetails(let statusCode, let serverErrorCode, let reason):
      var message = "CloudKit API error: HTTP \(statusCode)"
      if let serverErrorCode = serverErrorCode {
        message += "\nServer Error Code: \(serverErrorCode)"
      }
      if let reason = reason {
        message += "\nReason: \(reason)"
      }
      return message
    case .httpErrorWithRawResponse(let statusCode, let rawResponse):
      return "CloudKit API error: HTTP \(statusCode)\nRaw Response: \(rawResponse)"
    case .invalidResponse:
      return "Invalid response from CloudKit"
    }
  }
}
