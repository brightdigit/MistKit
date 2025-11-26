//
//  CloudKitError.swift
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

public import Foundation
import OpenAPIRuntime

/// Represents errors that can occur when interacting with CloudKit Web Services
public enum CloudKitError: LocalizedError, Sendable {
  case httpError(statusCode: Int)
  case httpErrorWithDetails(statusCode: Int, serverErrorCode: String?, reason: String?)
  case httpErrorWithRawResponse(statusCode: Int, rawResponse: String)
  case invalidResponse
  case underlyingError(any Error)
  case decodingError(DecodingError)
  case networkError(URLError)

  /// A localized message describing what error occurred
  public var errorDescription: String? {
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
    case .underlyingError(let error):
      return "CloudKit operation failed with underlying error: \(String(reflecting: error))"
    case .decodingError(let error):
      var message = "Failed to decode CloudKit response"
      switch error {
      case .keyNotFound(let key, let context):
        message += "\nMissing key: \(key.stringValue)"
        message += "\nCoding path: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        if let underlyingError = context.underlyingError {
          message += "\nUnderlying error: \(underlyingError.localizedDescription)"
        }
      case .typeMismatch(let type, let context):
        message += "\nType mismatch: expected \(type)"
        message += "\nCoding path: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        if let underlyingError = context.underlyingError {
          message += "\nUnderlying error: \(underlyingError.localizedDescription)"
        }
      case .valueNotFound(let type, let context):
        message += "\nValue not found: expected \(type)"
        message += "\nCoding path: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        if let underlyingError = context.underlyingError {
          message += "\nUnderlying error: \(underlyingError.localizedDescription)"
        }
      case .dataCorrupted(let context):
        message += "\nData corrupted"
        message += "\nCoding path: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        if let underlyingError = context.underlyingError {
          message += "\nUnderlying error: \(underlyingError.localizedDescription)"
        }
      @unknown default:
        message += "\nUnknown decoding error: \(error.localizedDescription)"
      }
      return message
    case .networkError(let error):
      var message = "Network error occurred"
      message += "\nError code: \(error.code.rawValue)"
      if let url = error.failureURLString {
        message += "\nFailed URL: \(url)"
      }
      message += "\nDescription: \(error.localizedDescription)"
      return message
    }
  }
}
