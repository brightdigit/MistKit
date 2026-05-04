//
//  AsyncHelpersTests.swift
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

/// An async operation that never returns naturally. Used as the "slow" body
/// in `withTimeout` tests so the outcome depends only on the outer timeout
/// firing, not on a wall-clock race between two `Task.sleep` durations.
///
/// Implemented via `Task.sleep` of an unreachable duration. We do not depend
/// on that duration's precision — only on cooperative cancellation aborting
/// the sleep when the enclosing task group calls `cancelAll()`, which is a
/// mandatory contract of `Task.sleep`. Any normal return is a bug.
private func neverReturning<T: Sendable>(_ type: T.Type = T.self) async throws -> T {
  try await Task.sleep(nanoseconds: 3_600 * 1_000_000_000)  // 1 hour
  fatalError("neverReturning must be cancelled before its sleep completes")
}

@Suite("AsyncHelpers Tests")
struct AsyncHelpersTests {
  // MARK: - Timeout Tests

  @Test("withTimeout completes before timeout")
  func completesBeforeTimeout() async throws {
    let result = try await withTimeout(seconds: 1.0) {
      "success"
    }

    #expect(result == "success")
  }

  @Test(
    "withTimeout throws on timeout",
    .enabled(
      if: !TestPlatform.lacksPreemptiveTimerRace,
      "executor can't reliably wake withTimeout's outer Task.sleep timer arm"
    )
  )
  func throwsOnTimeout() async {
    await #expect(throws: AsyncTimeoutError.self) {
      try await withTimeout(seconds: 0.1) {
        try await neverReturning(String.self)
      }
    }
  }

  @Test("withTimeout returns value from async operation")
  func returnsAsyncValue() async throws {
    let result = try await withTimeout(seconds: 1.0) {
      try await Task.sleep(nanoseconds: 50_000_000)  // 50ms
      return 42
    }

    #expect(result == 42)
  }

  @Test("withTimeout propagates operation errors")
  func propagatesErrors() async {
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
      if: !TestPlatform.lacksPreemptiveTimerRace,
      "executor can't reliably wake withTimeout's outer Task.sleep timer arm"
    )
  )
  func veryShortTimeout() async {
    await #expect(throws: AsyncTimeoutError.self) {
      try await withTimeout(seconds: 0.5) {
        try await neverReturning(String.self)
      }
    }
  }

  // MARK: - Format Timeout Tests

  @Test("formatTimeout with seconds")
  func formatSecondsTimeout() {
    #expect(formatTimeout(30) == "30 seconds")
    #expect(formatTimeout(45) == "45 seconds")
  }

  @Test("formatTimeout with single minute")
  func formatSingleMinute() {
    #expect(formatTimeout(60) == "1 minute")
  }

  @Test("formatTimeout with multiple minutes")
  func formatMultipleMinutes() {
    #expect(formatTimeout(120) == "2 minutes")
    #expect(formatTimeout(300) == "5 minutes")
  }

  @Test("formatTimeout with fractional seconds under 60")
  func formatFractionalSeconds() {
    #expect(formatTimeout(15.5) == "15 seconds")
    #expect(formatTimeout(59.9) == "59 seconds")
  }

  @Test("formatTimeout with fractional minutes")
  func formatFractionalMinutes() {
    #expect(formatTimeout(90) == "1 minute")
    #expect(formatTimeout(150) == "2 minutes")
  }

  // MARK: - AsyncTimeoutError Tests

  @Test("AsyncTimeoutError timeout case has description")
  func timeoutErrorDescription() {
    let error = AsyncTimeoutError.timeout("Operation took too long")
    let description = error.errorDescription

    #expect(description != nil)
    #expect(description?.contains("Operation timed out") == true)
    #expect(description?.contains("Operation took too long") == true)
  }

  @Test("AsyncTimeoutError cancelled case has description")
  func cancelledErrorDescription() {
    let error = AsyncTimeoutError.cancelled("User interrupted")
    let description = error.errorDescription

    #expect(description != nil)
    #expect(description?.contains("Operation cancelled") == true)
    #expect(description?.contains("User interrupted") == true)
  }

  @Test("AsyncTimeoutError conforms to LocalizedError")
  func timeoutErrorIsLocalizedError() {
    let error: any Error = AsyncTimeoutError.timeout("test")
    #expect(error is LocalizedError)
  }

  // MARK: - Concurrent Timeout Tests

  @Test(
    "withTimeout cancels other tasks in group",
    .enabled(
      if: !TestPlatform.lacksPreemptiveTimerRace,
      "executor can't reliably wake withTimeout's outer Task.sleep timer arm"
    )
  )
  func cancelsOtherTasks() async throws {
    await #expect(throws: AsyncTimeoutError.self) {
      try await withTimeout(seconds: 0.1) {
        try await neverReturning(String.self)
      }
    }
  }

  @Test(
    "Multiple concurrent withTimeout operations",
    .enabled(
      if: !TestPlatform.lacksPreemptiveTimerRace,
      "executor can't reliably wake withTimeout's outer Task.sleep timer arm"
    )
  )
  func multipleConcurrentTimeouts() async throws {
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
          _ = try await withTimeout(seconds: 0.1) {
            try await neverReturning(String.self)
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

  // MARK: - Edge Cases

  @Test(
    "withTimeout with short timeout throws",
    .enabled(
      if: !TestPlatform.lacksPreemptiveTimerRace,
      "executor can't reliably wake withTimeout's outer Task.sleep timer arm"
    )
  )
  func zeroTimeout() async {
    await #expect(throws: AsyncTimeoutError.self) {
      try await withTimeout(seconds: 0.5) {
        try await neverReturning(String.self)
      }
    }
  }

  @Test("withTimeout with immediate return")
  func immediateReturn() async throws {
    let result = try await withTimeout(seconds: 0.1) {
      "immediate"
    }

    #expect(result == "immediate")
  }
}
