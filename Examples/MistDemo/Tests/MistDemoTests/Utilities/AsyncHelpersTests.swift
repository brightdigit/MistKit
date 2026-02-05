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
@testable import MistDemo

@Suite("AsyncHelpers Tests")
struct AsyncHelpersTests {

    // MARK: - Timeout Tests

    @Test("withTimeout completes before timeout")
    func completesBeforeTimeout() async throws {
        let result = try await withTimeout(seconds: 1.0) {
            return "success"
        }

        #expect(result == "success")
    }

    @Test("withTimeout throws on timeout")
    func throwsOnTimeout() async {
        await #expect(throws: AsyncTimeoutError.self) {
            try await withTimeout(seconds: 0.1) {
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms
                return "too slow"
            }
        }
    }

    @Test("withTimeout returns value from async operation")
    func returnsAsyncValue() async throws {
        let result = try await withTimeout(seconds: 1.0) {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
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

    @Test("withTimeout with very short timeout")
    func veryShortTimeout() async {
        await #expect(throws: AsyncTimeoutError.self) {
            try await withTimeout(seconds: 0.001) {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                return "unreachable"
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

    @Test("withTimeout cancels other tasks in group")
    func cancelsOtherTasks() async throws {
        await #expect(throws: AsyncTimeoutError.self) {
            try await withTimeout(seconds: 0.1) {
                try await Task.sleep(nanoseconds: 500_000_000)
                return "done"
            }
        }
    }

    @Test("Multiple concurrent withTimeout operations")
    func multipleConcurrentTimeouts() async throws {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    _ = try await withTimeout(seconds: 1.0) {
                        return "fast"
                    }
                } catch {
                    Issue.record("Fast operation should not timeout")
                }
            }

            group.addTask {
                do {
                    _ = try await withTimeout(seconds: 0.05) {
                        try await Task.sleep(nanoseconds: 200_000_000)
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

    // MARK: - Edge Cases

    @Test("withTimeout with zero timeout")
    func zeroTimeout() async {
        await #expect(throws: AsyncTimeoutError.self) {
            try await withTimeout(seconds: 0) {
                return "instant"
            }
        }
    }

    @Test("withTimeout with immediate return")
    func immediateReturn() async throws {
        let result = try await withTimeout(seconds: 0.1) {
            return "immediate"
        }

        #expect(result == "immediate")
    }
}
