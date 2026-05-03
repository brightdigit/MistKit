//
//  MistDemoError.swift
//  MistDemo
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

import Foundation
import MistKit

/// Comprehensive error type for MistDemo operations
enum MistDemoError: LocalizedError, Sendable {
  /// Authentication failed with underlying error
  case authenticationFailed(description: String, context: String)

  /// Configuration error
  case configurationError(String, suggestion: String?)

  /// CloudKit operation failed
  case cloudKitError(MistKit.CloudKitError, operation: String)

  /// Invalid input provided
  case invalidInput(field: String, value: String, reason: String)

  /// Output formatting failed
  case outputFormattingFailed(description: String)

  /// File not found
  case fileNotFound(String)

  /// Invalid format
  case invalidFormat(String)

  /// Unknown command
  case unknownCommand(String)

  // MARK: Public

  var errorDescription: String? {
    switch self {
    case .authenticationFailed(_, let context):
      "Authentication failed: \(context)"
    case .configurationError(let message, _):
      "Configuration error: \(message)"
    case .cloudKitError(let error, let operation):
      "CloudKit error during \(operation): \(error.localizedDescription)"
    case .invalidInput(let field, let value, let reason):
      "Invalid input for \(field) '\(value)': \(reason)"
    case .outputFormattingFailed:
      "Failed to format output"
    case .fileNotFound(let path):
      "File not found: \(path)"
    case .invalidFormat(let message):
      "Invalid format: \(message)"
    case .unknownCommand(let command):
      "Unknown command: \(command)"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .authenticationFailed:
      "Token may be expired. Run 'mistdemo auth' to sign in again."
    case .configurationError(_, let suggestion):
      suggestion
    case .cloudKitError:
      "Check your CloudKit configuration and try again."
    case .invalidInput(let field, _, _):
      "Provide a valid value for \(field)."
    case .outputFormattingFailed:
      "Try a different output format (--output json|table|csv|yaml)."
    case .fileNotFound:
      "Check the file path and try again."
    case .invalidFormat:
      "Check the format and try again."
    case .unknownCommand:
      "Use 'mistdemo help' to see available commands."
    }
  }

  /// Get the error code for machine-readable output
  var errorCode: String {
    switch self {
    case .authenticationFailed:
      "AUTHENTICATION_FAILED"
    case .configurationError:
      "CONFIGURATION_ERROR"
    case .cloudKitError:
      "CLOUDKIT_ERROR"
    case .invalidInput:
      "INVALID_INPUT"
    case .outputFormattingFailed:
      "OUTPUT_FORMATTING_FAILED"
    case .fileNotFound:
      "FILE_NOT_FOUND"
    case .invalidFormat:
      "INVALID_FORMAT"
    case .unknownCommand:
      "UNKNOWN_COMMAND"
    }
  }

  /// Get error details for structured output
  var errorDetails: [String: String] {
    switch self {
    case .authenticationFailed(_, let context):
      ["context": context]
    case .configurationError:
      [:]
    case .cloudKitError(_, let operation):
      ["operation": operation]
    case .invalidInput(let field, let value, let reason):
      ["field": field, "value": value, "reason": reason]
    case .outputFormattingFailed:
      [:]
    case .fileNotFound(let path):
      ["path": path]
    case .invalidFormat(let message):
      ["message": message]
    case .unknownCommand(let command):
      ["command": command]
    }
  }

  /// Convert to structured ErrorOutput
  var errorOutput: ErrorOutput {
    ErrorOutput(
      code: errorCode,
      message: errorDescription ?? "Unknown error",
      details: errorDetails.isEmpty ? nil : errorDetails,
      suggestion: recoverySuggestion
    )
  }
}
