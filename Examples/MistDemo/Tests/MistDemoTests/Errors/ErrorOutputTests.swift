//
//  ErrorOutputTests.swift
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
import Testing

@testable import MistDemo

@Suite("ErrorOutput Tests")
struct ErrorOutputTests {
  // MARK: - Basic Structure Tests

  @Test("Create error output with all fields")
  func createErrorOutputWithAllFields() {
    let errorOutput = ErrorOutput(
      code: "TEST_ERROR",
      message: "This is a test error",
      details: ["field": "value", "operation": "test"],
      suggestion: "Try doing something else"
    )

    #expect(errorOutput.error.code == "TEST_ERROR")
    #expect(errorOutput.error.message == "This is a test error")
    #expect(errorOutput.error.details?["field"] == "value")
    #expect(errorOutput.error.details?["operation"] == "test")
    #expect(errorOutput.error.suggestion == "Try doing something else")
  }

  @Test("Create error output without optional fields")
  func createErrorOutputWithoutOptionalFields() {
    let errorOutput = ErrorOutput(
      code: "SIMPLE_ERROR",
      message: "Simple error message"
    )

    #expect(errorOutput.error.code == "SIMPLE_ERROR")
    #expect(errorOutput.error.message == "Simple error message")
    #expect(errorOutput.error.details == nil)
    #expect(errorOutput.error.suggestion == nil)
  }

  // MARK: - JSON Serialization Tests

  @Test("Serialize error output to JSON")
  func serializeToJSON() throws {
    let errorOutput = ErrorOutput(
      code: "AUTH_FAILED",
      message: "Authentication failed",
      details: ["reason": "invalid_token"],
      suggestion: "Run 'mistdemo auth' to sign in again"
    )

    let jsonString = try errorOutput.toJSON(pretty: false)

    #expect(jsonString.contains("\"code\""))
    #expect(jsonString.contains("AUTH_FAILED"))
    #expect(jsonString.contains("\"message\""))
    #expect(jsonString.contains("Authentication failed"))
    #expect(jsonString.contains("\"details\""))
    #expect(jsonString.contains("invalid_token"))
    #expect(jsonString.contains("\"suggestion\""))
  }

  @Test("Serialize error output to pretty JSON")
  func serializeToPrettyJSON() throws {
    let errorOutput = ErrorOutput(
      code: "CONFIG_ERROR",
      message: "Configuration error"
    )

    let jsonString = try errorOutput.toJSON(pretty: true)

    // Pretty JSON should have newlines and indentation
    #expect(jsonString.contains("\n"))
    #expect(jsonString.contains("  "))
    #expect(jsonString.contains("\"error\""))
  }

  @Test("JSON output has correct structure")
  func jsonOutputHasCorrectStructure() throws {
    let errorOutput = ErrorOutput(
      code: "TEST",
      message: "Test message",
      details: ["key": "value"]
    )

    let jsonString = try errorOutput.toJSON(pretty: false)
    let jsonData = Data(jsonString.utf8)
    let decoded = try JSONDecoder().decode(ErrorOutput.self, from: jsonData)

    #expect(decoded.error.code == "TEST")
    #expect(decoded.error.message == "Test message")
    #expect(decoded.error.details?["key"] == "value")
  }

  // MARK: - Edge Cases

  @Test("Handle empty details dictionary")
  func handleEmptyDetails() throws {
    let errorOutput = ErrorOutput(
      code: "ERROR",
      message: "Message",
      details: [:]
    )

    let jsonString = try errorOutput.toJSON(pretty: false)
    #expect(jsonString.contains("\"details\""))
  }

  @Test("Handle special characters in message")
  func handleSpecialCharacters() throws {
    let errorOutput = ErrorOutput(
      code: "SPECIAL",
      message: "Error with \"quotes\" and \\ backslash"
    )

    let jsonString = try errorOutput.toJSON(pretty: false)

    // Should properly escape special characters
    #expect(jsonString.contains("\\\""))
    #expect(jsonString.contains("\\\\"))
  }

  @Test("Handle multiline suggestion")
  func handleMultilineSuggestion() throws {
    let errorOutput = ErrorOutput(
      code: "HELP",
      message: "Need help",
      suggestion: "Try these steps:\n1. First step\n2. Second step"
    )

    let jsonString = try errorOutput.toJSON(pretty: false)
    #expect(jsonString.contains("\\n"))
  }
}
