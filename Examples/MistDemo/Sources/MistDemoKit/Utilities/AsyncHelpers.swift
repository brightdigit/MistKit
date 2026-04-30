//
//  AsyncHelpers.swift
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

public import Foundation
import UnixSignals

/// Timeout error for async operations
public enum AsyncTimeoutError: Error, LocalizedError {
    case timeout(String)
    case cancelled(String)

    public var errorDescription: String? {
        switch self {
        case .timeout(let message):
            return "Operation timed out: \(message)"
        case .cancelled(let message):
            return "Operation cancelled: \(message)"
        }
    }
}

/// Execute an async operation with a timeout
public func withTimeout<T: Sendable>(
    seconds: Double,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            return try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw AsyncTimeoutError.timeout("Operation timed out after \(seconds) seconds")
        }

        guard let result = try await group.next() else {
            throw AsyncTimeoutError.timeout("Timeout task failed")
        }

        group.cancelAll()
        return result
    }
}

/// Execute an async operation with signal handling (Ctrl+C, SIGTERM)
public func withSignalHandling<T: Sendable>(
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    #if os(Linux) || os(macOS)
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            return try await operation()
        }

        group.addTask {
            let signals = await UnixSignalsSequence(trapping: [.sigint, .sigterm])
            for try await signal in signals {
                print("\n⚠️  Received signal: \(signal)")
                throw AsyncTimeoutError.cancelled("Operation cancelled by signal")
            }
            throw AsyncTimeoutError.cancelled("Signal handler completed unexpectedly")
        }

        guard let result = try await group.next() else {
            throw AsyncTimeoutError.cancelled("Task group completed without result")
        }

        group.cancelAll()
        return result
    }
    #else
    return try await operation()
    #endif
}

/// Execute an async operation with both timeout and signal handling
public func withTimeoutAndSignals<T: Sendable>(
    seconds: Double,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withSignalHandling {
        try await withTimeout(seconds: seconds, operation: operation)
    }
}

/// Format a timeout duration for user display
public func formatTimeout(_ seconds: Double) -> String {
    if seconds < 60 {
        return "\(Int(seconds)) seconds"
    } else {
        let minutes = Int(seconds / 60)
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    }
}
