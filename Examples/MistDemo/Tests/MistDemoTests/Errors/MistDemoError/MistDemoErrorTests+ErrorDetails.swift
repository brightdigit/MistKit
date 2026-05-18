//
//  MistDemoErrorTests+ErrorDetails.swift
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

internal import Foundation
internal import MistKit
internal import Testing

@testable import MistDemoKit

extension MistDemoErrorTests {
  @Suite("Error Details")
  internal struct ErrorDetails {
    @Test("Authentication failed includes context in details")
    internal func authenticationFailedDetails() {
      let error = MistDemoError.authenticationFailed(
        description: "Invalid token",
        context: "web auth validation"
      )

      let details = error.errorDetails
      #expect(details["context"] == "web auth validation")
    }

    @Test("CloudKit error includes operation in details")
    internal func cloudKitErrorDetails() {
      let error = MistDemoError.cloudKitError(
        .networkError(URLError(.badURL)),
        operation: "list_zones"
      )

      let details = error.errorDetails
      #expect(details["operation"] == "list_zones")
    }

    @Test("Invalid input includes all fields in details")
    internal func invalidInputDetails() {
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
  }
}
