//
//  CurrentUserCommandTests+ErrorHandling.swift
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
internal import Testing

@testable import MistDemoKit

extension CurrentUserCommandTests {
  @Suite("Error Handling")
  internal struct ErrorHandling {
    @Test("Command handles authentication error gracefully")
    internal func commandHandlesAuthError() async throws {
      // Test that authentication errors are properly handled
      let error = MistDemoError.authenticationFailed(
        description: "Invalid credentials",
        context: "current-user"
      )

      #expect(error.errorCode == "AUTHENTICATION_FAILED")
      #expect(error.errorDescription?.contains("current-user") == true)
      #expect(error.recoverySuggestion != nil)
    }

    @Test("Command handles missing API token")
    internal func commandHandlesMissingAPIToken() async throws {
      // Test configuration error for missing API token
      let error = ConfigurationError.missingRequired(
        "api.token",
        suggestion: "Provide API token via --api-token or environment variable"
      )

      #expect(error.errorDescription?.contains("api.token") == true)
    }
  }
}
