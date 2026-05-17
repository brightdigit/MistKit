//
//  AsyncHelpersTests+AsyncTimeoutError.swift
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
import Testing

@testable import MistDemoKit

extension AsyncHelpersTests {
  @Suite("AsyncTimeoutError")
  internal struct AsyncTimeoutErrorTests {
    @Test("AsyncTimeoutError timeout case has description")
    internal func timeoutErrorDescription() {
      let error = AsyncTimeoutError.timeout("Operation took too long")
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Operation timed out") == true)
      #expect(description?.contains("Operation took too long") == true)
    }

    @Test("AsyncTimeoutError cancelled case has description")
    internal func cancelledErrorDescription() {
      let error = AsyncTimeoutError.cancelled("User interrupted")
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Operation cancelled") == true)
      #expect(description?.contains("User interrupted") == true)
    }

    @Test("AsyncTimeoutError conforms to LocalizedError")
    internal func timeoutErrorIsLocalizedError() {
      let error: any Error = AsyncTimeoutError.timeout("test")
      #expect(error is any LocalizedError)
    }
  }
}
