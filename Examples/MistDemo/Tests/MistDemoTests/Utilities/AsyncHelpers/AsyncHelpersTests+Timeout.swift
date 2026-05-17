//
//  AsyncHelpersTests+Timeout.swift
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
  @Suite("Timeout")
  internal struct Timeout {
    @Test("withTimeout completes before timeout")
    internal func completesBeforeTimeout() async throws {
      let result = try await withTimeout(seconds: 1.0) {
        "success"
      }

      #expect(result == "success")
    }

    @Test(
      "withTimeout throws on timeout",
      .enabled(
        if: !TestPlatform.isWasm32,
        "wasm32 CooperativeExecutor doesn't fire the timeout race against an inner Task.sleep"
      )
    )
    internal func throwsOnTimeout() async {
      // Intermittent: simulator cooperative executors (notably watchOS) can let the
      // operation's single long Task.sleep complete before the polling timeout task's
      // many short sleeps detect the deadline — same root cause as the wasm32 gate.
      await withKnownIssue(isIntermittent: true) {
        await #expect(throws: AsyncTimeoutError.self) {
          try await withTimeout(seconds: 0.1) {
            try await Task.sleep(nanoseconds: 500_000_000)  // 500ms
            return "too slow"
          }
        }
      }
    }

    @Test(
      "withTimeout returns value from async operation",
      .enabled(
        if: !TestPlatform.isWasm32,
        "wasm32 CooperativeExecutor's Task.sleep is unreliable; operation's inner sleep can be starved"
      )
    )
    internal func returnsAsyncValue() async {
      // The 30 s budget (vs. the operation's 50 ms inner sleep) is intentionally
      // generous: under iOS-simulator CI load the operation task's single long
      // Task.sleep can be scheduled behind the polling timeout task's many short
      // sleeps, so a tighter budget produced flaky timeouts (#283).
      // Even at 30s the iOS simulator under heavy CI load can exceed the budget
      // (observed wall times of 48-50s for ostensibly trivial operations), so
      // mark as intermittent rather than chasing the budget upward indefinitely.
      await withKnownIssue(isIntermittent: true) {
        let result = try await withTimeout(seconds: 30.0) {
          try await Task.sleep(nanoseconds: 50_000_000)  // 50ms
          return 42
        }

        #expect(result == 42)
      }
    }

    @Test("withTimeout propagates operation errors")
    internal func propagatesErrors() async {
      struct TestError: Error {}

      await #expect(throws: TestError.self) {
        try await withTimeout(seconds: 1.0) {
          throw TestError()
        }
      }
    }

    @Test(
      "withTimeout with very short timeout",
      .enabled(
        if: !TestPlatform.isWasm32,
        "wasm32 CooperativeExecutor doesn't time-slice the timeout race like Darwin/Linux dispatch"
      )
    )
    internal func veryShortTimeout() async {
      // Same root cause as `throwsOnTimeout` / `returnsAsyncValue`: under
      // simulator load (observed on visionOS, run #25990091951) the
      // operation's single 100ms Task.sleep can finish before the polling
      // timeout task's many short sleeps detect the 1ms deadline.
      await withKnownIssue(isIntermittent: true) {
        await #expect(throws: AsyncTimeoutError.self) {
          try await withTimeout(seconds: 0.001) {
            try await Task.sleep(nanoseconds: 100_000_000)  // 100ms
            return "unreachable"
          }
        }
      }
    }
  }
}
