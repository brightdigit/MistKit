//
//  AuthTokenCommandTests+Error.swift
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

#if canImport(Hummingbird)
  import Foundation
  import Testing

  @testable import MistDemoKit

  extension AuthTokenCommandTests {
    @Suite("Error")
    internal struct ErrorTests {
      @Test("AuthTokenError timeout has correct description")
      internal func authTokenErrorTimeoutDescription() {
        let error = AuthTokenError.timeout("Operation timed out after 5 minutes")

        #expect(
          error.errorDescription == "Authentication timeout: Operation timed out after 5 minutes")
      }

      @Test("AuthTokenError missing resource has correct description")
      internal func authTokenErrorMissingResourceDescription() {
        let error = AuthTokenError.missingResource("index.html not found")

        #expect(error.errorDescription == "Missing resource: index.html not found")
      }

      @Test("AuthTokenError server error has correct description")
      internal func authTokenErrorServerErrorDescription() {
        let error = AuthTokenError.serverError("Failed to bind to port")

        #expect(error.errorDescription == "Server error: Failed to bind to port")
      }
    }
  }
#endif
