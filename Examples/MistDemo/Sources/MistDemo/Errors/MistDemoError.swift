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

public import Foundation
import MistKit

/// Comprehensive error type for MistDemo operations
enum MistDemoError: LocalizedError, Sendable {
  /// Authentication failed with underlying error
  case authenticationFailed(underlying: any Error, context: String)

  /// Configuration error
  case configurationError(String, suggestion: String?)

  /// CloudKit operation failed
  case cloudKitError(MistKit.CloudKitError, operation: String)

  /// Invalid input provided
  case invalidInput(field: String, value: String, reason: String)

  /// Output formatting failed
  case outputFormattingFailed(any Error)

  /// File not found
  case fileNotFound(String)

  /// Invalid format
  case invalidFormat(String)

  // MARK: Public

  var errorDescription: String? {
    switch self {
    case let .authenticationFailed(_, context):
      "Authentication failed: \(context)"
    case let .configurationError(message, _):
      "Configuration error: \(message)"
    case let .cloudKitError(error, operation):
      "CloudKit error during \(operation): \(error.localizedDescription)"
    case let .invalidInput(field, value, reason):
      "Invalid input for \(field) '\(value)': \(reason)"
    case .outputFormattingFailed:
      "Failed to format output"
    case let .fileNotFound(path):
      "File not found: \(path)"
    case let .invalidFormat(message):
      "Invalid format: \(message)"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .authenticationFailed:
      "Token may be expired. Run 'mistdemo auth' to sign in again."
    case let .configurationError(_, suggestion):
      suggestion
    case .cloudKitError:
      "Check your CloudKit configuration and try again."
    case let .invalidInput(field, _, _):
      "Provide a valid value for \(field)."
    case .outputFormattingFailed:
      "Try a different output format (--output json|table|csv|yaml)."
    case .fileNotFound:
      "Check the file path and try again."
    case .invalidFormat:
      "Check the format and try again."
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
    }
  }

  /// Get error details for structured output
  var errorDetails: [String: String] {
    switch self {
    case let .authenticationFailed(_, context):
      ["context": context]
    case .configurationError:
      [:]
    case let .cloudKitError(_, operation):
      ["operation": operation]
    case let .invalidInput(field, value, reason):
      ["field": field, "value": value, "reason": reason]
    case .outputFormattingFailed:
      [:]
    case let .fileNotFound(path):
      ["path": path]
    case let .invalidFormat(message):
      ["message": message]
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

// MARK: - Configuration Errors

/// Configuration-specific errors
enum ConfigError: LocalizedError, Sendable {
  case missingAPIToken
  case invalidEnvironment(String)
  case fileNotFound(String)
  case invalidFormat(String, details: String)
  case profileNotFound(String)

  // MARK: Internal

  var errorDescription: String? {
    switch self {
    case .missingAPIToken:
      "CloudKit API token is required"
    case let .invalidEnvironment(env):
      "Invalid environment: \(env)"
    case let .fileNotFound(path):
      "Configuration file not found: \(path)"
    case let .invalidFormat(format, details):
      "Invalid \(format) format: \(details)"
    case let .profileNotFound(profile):
      "Profile not found: \(profile)"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .missingAPIToken:
      "Set CLOUDKIT_API_TOKEN environment variable or use --api-token flag"
    case let .invalidEnvironment(env):
      "Use 'development' or 'production' instead of '\(env)'"
    case let .fileNotFound(path):
      "Create a configuration file at \(path)"
    case let .invalidFormat(format, _):
      "Check your \(format) configuration file syntax"
    case let .profileNotFound(profile):
      "Check available profiles or create '\(profile)' profile"
    }
  }
}
