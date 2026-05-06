//
//  AuthTokenCommandTests+Timeout.swift
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
    @Suite("Timeout")
    internal struct TimeoutTests {
      @Test("Timeout helper throws on timeout")
      internal func timeoutHelperThrowsOnTimeout() async throws {
        do {
          _ = try await withTimeoutAndSignals(seconds: 0.1) {
            try await Task.sleep(nanoseconds: 1_000_000_000)  // Sleep for 1 second
            return "should-not-return"
          }
          Issue.record("Should have timed out")
        } catch is AsyncTimeoutError {
          // Expected timeout error
          #expect(Bool(true))
        } catch {
          Issue.record("Unexpected error: \(error)")
        }
      }

      @Test("Timeout helper returns value before timeout")
      internal func timeoutHelperReturnsValue() async throws {
        let result = try await withTimeoutAndSignals(seconds: 1.0) {
          "success"
        }

        #expect(result == "success")
      }
    }
  }
#endif
