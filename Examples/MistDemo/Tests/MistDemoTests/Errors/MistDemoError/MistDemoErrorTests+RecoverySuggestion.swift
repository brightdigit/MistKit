//
//  MistDemoErrorTests+RecoverySuggestion.swift
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

@testable import MistDemoKit

extension MistDemoErrorTests {
  @Suite("Recovery Suggestion")
  internal struct RecoverySuggestion {
    @Test("Authentication failed has recovery suggestion")
    internal func authenticationFailedRecoverySuggestion() {
      let error = MistDemoError.authenticationFailed(
        description: "Test error description",
        context: "test"
      )

      let suggestion = error.recoverySuggestion
      #expect(suggestion?.contains("mistdemo auth") == true)
    }

    @Test("Configuration error uses provided suggestion")
    internal func configurationErrorRecoverySuggestion() {
      let error = MistDemoError.configurationError(
        "Test error",
        suggestion: "Custom suggestion"
      )

      let suggestion = error.recoverySuggestion
      #expect(suggestion == "Custom suggestion")
    }

    @Test("Invalid input has recovery suggestion")
    internal func invalidInputRecoverySuggestion() {
      let error = MistDemoError.invalidInput(
        field: "container-id",
        value: "bad",
        reason: "invalid format"
      )

      let suggestion = error.recoverySuggestion
      #expect(suggestion?.contains("container-id") == true)
    }
  }
}
