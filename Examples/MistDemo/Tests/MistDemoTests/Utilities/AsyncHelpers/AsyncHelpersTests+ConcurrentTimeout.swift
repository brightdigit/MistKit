//
//  AsyncHelpersTests+ConcurrentTimeout.swift
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
  @Suite("Concurrent Timeout")
  internal struct ConcurrentTimeout {
    @Test(
      "withTimeout cancels other tasks in group",
      .enabled(
        if: !TestPlatform.isWasm32,
        "wasm32 CooperativeExecutor doesn't fire the timeout race against an inner Task.sleep"
      )
    )
    internal func cancelsOtherTasks() async throws {
      await #expect(throws: AsyncTimeoutError.self) {
        try await withTimeout(seconds: 0.1) {
          try await Task.sleep(nanoseconds: 500_000_000)
          return "done"
        }
      }
    }

    @Test(
      "Multiple concurrent withTimeout operations",
      .enabled(
        if: !TestPlatform.isWasm32,
        "wasm32 CooperativeExecutor doesn't fire the timeout race against an inner Task.sleep"
      )
    )
    internal func multipleConcurrentTimeouts() async throws {
      await withTaskGroup(of: Void.self) { group in
        group.addTask {
          do {
            _ = try await withTimeout(seconds: 1.0) {
              "fast"
            }
          } catch {
            Issue.record("Fast operation should not timeout")
          }
        }

        group.addTask {
          do {
            _ = try await withTimeout(seconds: 0.2) {
              try await Task.sleep(nanoseconds: 2_000_000_000)
              return "slow"
            }
            Issue.record("Slow operation should timeout")
          } catch is AsyncTimeoutError {
            // Expected
          } catch {
            Issue.record("Unexpected error type")
          }
        }
      }
    }
  }
}
