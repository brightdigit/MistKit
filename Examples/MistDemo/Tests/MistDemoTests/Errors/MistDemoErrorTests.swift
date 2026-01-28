//
//  MistDemoErrorTests.swift
//  MistDemoTests
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
import Testing

@testable import MistDemo

@Suite("MistDemoError Tests")
struct MistDemoErrorTests {
  // MARK: - Error Code Tests

  @Test("Authentication failed error has correct code")
  func authenticationFailedErrorCode() {
    struct TestError: Error {}
    let error = MistDemoError.authenticationFailed(
      underlying: TestError(),
      context: "test context"
    )

    #expect(error.errorCode == "AUTHENTICATION_FAILED")
  }

  @Test("Configuration error has correct code")
  func configurationErrorCode() {
    let error = MistDemoError.configurationError("test", suggestion: nil)
    #expect(error.errorCode == "CONFIGURATION_ERROR")
  }

  @Test("CloudKit error has correct code")
  func cloudKitErrorCode() {
    let error = MistDemoError.cloudKitError(
      .networkError(URLError(.badURL)),
      operation: "fetch"
    )
    #expect(error.errorCode == "CLOUDKIT_ERROR")
  }

  @Test("Invalid input error has correct code")
  func invalidInputErrorCode() {
    let error = MistDemoError.invalidInput(
      field: "email",
      value: "invalid",
      reason: "not a valid email"
    )
    #expect(error.errorCode == "INVALID_INPUT")
  }

  // MARK: - Error Description Tests

  @Test("Authentication failed error has descriptive message")
  func authenticationFailedDescription() {
    struct TestError: Error {}
    let error = MistDemoError.authenticationFailed(
      underlying: TestError(),
      context: "credential validation"
    )

    let description = error.errorDescription
    #expect(description?.contains("Authentication failed") == true)
    #expect(description?.contains("credential validation") == true)
  }

  @Test("Configuration error has descriptive message")
  func configurationErrorDescription() {
    let error = MistDemoError.configurationError(
      "Missing API token",
      suggestion: "Set CLOUDKIT_API_TOKEN"
    )

    let description = error.errorDescription
    #expect(description?.contains("Configuration error") == true)
    #expect(description?.contains("Missing API token") == true)
  }

  @Test("Invalid input error includes field and reason")
  func invalidInputDescription() {
    let error = MistDemoError.invalidInput(
      field: "port",
      value: "abc",
      reason: "must be a number"
    )

    let description = error.errorDescription
    #expect(description?.contains("port") == true)
    #expect(description?.contains("abc") == true)
    #expect(description?.contains("must be a number") == true)
  }

  // MARK: - Recovery Suggestion Tests

  @Test("Authentication failed has recovery suggestion")
  func authenticationFailedRecoverySuggestion() {
    struct TestError: Error {}
    let error = MistDemoError.authenticationFailed(
      underlying: TestError(),
      context: "test"
    )

    let suggestion = error.recoverySuggestion
    #expect(suggestion?.contains("mistdemo auth") == true)
  }

  @Test("Configuration error uses provided suggestion")
  func configurationErrorRecoverySuggestion() {
    let error = MistDemoError.configurationError(
      "Test error",
      suggestion: "Custom suggestion"
    )

    let suggestion = error.recoverySuggestion
    #expect(suggestion == "Custom suggestion")
  }

  @Test("Invalid input has recovery suggestion")
  func invalidInputRecoverySuggestion() {
    let error = MistDemoError.invalidInput(
      field: "container-id",
      value: "bad",
      reason: "invalid format"
    )

    let suggestion = error.recoverySuggestion
    #expect(suggestion?.contains("container-id") == true)
  }

  // MARK: - Error Details Tests

  @Test("Authentication failed includes context in details")
  func authenticationFailedDetails() {
    struct TestError: Error {}
    let error = MistDemoError.authenticationFailed(
      underlying: TestError(),
      context: "web auth validation"
    )

    let details = error.errorDetails
    #expect(details["context"] == "web auth validation")
  }

  @Test("CloudKit error includes operation in details")
  func cloudKitErrorDetails() {
    let error = MistDemoError.cloudKitError(
      .networkError(URLError(.badURL)),
      operation: "list_zones"
    )

    let details = error.errorDetails
    #expect(details["operation"] == "list_zones")
  }

  @Test("Invalid input includes all fields in details")
  func invalidInputDetails() {
    let error = MistDemoError.invalidInput(
      field: "api-token",
      value: "short",
      reason: "too short"
    )

    let details = error.errorDetails
    #expect(details["field"] == "api-token")
    #expect(details["value"] == "short")
    #expect(details["reason"] == "too short")
  }

  // MARK: - ErrorOutput Conversion Tests

  @Test("Convert error to ErrorOutput")
  func convertToErrorOutput() {
    let error = MistDemoError.fileNotFound("/path/to/file")
    let output = error.errorOutput

    #expect(output.error.code == "FILE_NOT_FOUND")
    #expect(output.error.message.contains("not found") == true)
    #expect(output.error.details?["path"] == "/path/to/file")
  }

  @Test("ErrorOutput includes suggestion when available")
  func errorOutputIncludesSuggestion() {
    let error = MistDemoError.configurationError(
      "Missing token",
      suggestion: "Use --api-token flag"
    )
    let output = error.errorOutput

    #expect(output.error.suggestion == "Use --api-token flag")
  }

  @Test("ErrorOutput omits empty details")
  func errorOutputOmitsEmptyDetails() {
    let error = MistDemoError.outputFormattingFailed(
      NSError(domain: "test", code: 1)
    )
    let output = error.errorOutput

    #expect(output.error.details == nil || output.error.details?.isEmpty == true)
  }
}
