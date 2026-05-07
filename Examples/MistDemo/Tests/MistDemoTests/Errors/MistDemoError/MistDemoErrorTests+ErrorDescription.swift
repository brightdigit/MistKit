//
//  MistDemoErrorTests+ErrorDescription.swift
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

@testable import MistDemoKit

extension MistDemoErrorTests {
  @Suite("Error Description")
  internal struct ErrorDescription {
    @Test("Authentication failed error has descriptive message")
    internal func authenticationFailedDescription() {
      let error = MistDemoError.authenticationFailed(
        description: "Invalid credentials",
        context: "credential validation"
      )

      let description = error.errorDescription
      #expect(description?.contains("Authentication failed") == true)
      #expect(description?.contains("credential validation") == true)
    }

    @Test("Configuration error has descriptive message")
    internal func configurationErrorDescription() {
      let error = MistDemoError.configurationError(
        "Missing API token",
        suggestion: "Set CLOUDKIT_API_TOKEN"
      )

      let description = error.errorDescription
      #expect(description?.contains("Configuration error") == true)
      #expect(description?.contains("Missing API token") == true)
    }

    @Test("Invalid input error includes field and reason")
    internal func invalidInputDescription() {
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
  }
}
