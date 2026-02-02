//
//  MistDemoConfig+Testing.swift
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
@testable import MistDemo

extension MistDemoConfig {
    /// Create a test configuration with default values
    /// This is a synchronous wrapper for tests that don't need async initialization
    init() throws {
        let configuration = try MistDemoConfiguration()

        // Use a detached task to avoid sendability issues
        let config = try Self._runBlocking {
            try await MistDemoConfig(configuration: configuration)
        }

        self = config
    }

    /// Helper to run async code synchronously in tests
    private static func _runBlocking<T: Sendable>(_ operation: @Sendable @escaping () async throws -> T) throws -> T {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<T, any Error>?

        let task = Task.detached {
            do {
                let value = try await operation()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }

        semaphore.wait()

        guard let finalResult = result else {
            throw NSError(domain: "MistDemoTests", code: -1, userInfo: [NSLocalizedDescriptionKey: "Task did not complete"])
        }

        // Keep task reference to avoid being deallocated
        _ = task

        return try finalResult.get()
    }
}
