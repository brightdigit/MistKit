//
//  EnvironmentTraits.swift
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

internal import Testing

/// A `TestTrait` / `SuiteTrait` that scopes a fake environment for the test.
/// Apply with `.mockEnvironment(["KEY": "value"])` to declare the environment
/// the test expects, then read it via `MockEnvironment.reader`.
internal struct MockEnvironmentTrait: TestTrait, SuiteTrait, TestScoping {
  internal let values: [String: String]

  internal func provideScope(
    for test: Test,
    testCase: Test.Case?,
    performing function: @Sendable () async throws -> Void
  ) async throws {
    try await MockEnvironment.$values.withValue(values) {
      try await function()
    }
  }
}

extension Trait where Self == MockEnvironmentTrait {
  /// Scope a fake environment dictionary for the test. The test reads it via
  /// `MockEnvironment.reader`, which is safe to share across parallel tests
  /// because each test gets its own task-local copy.
  internal static func mockEnvironment(_ values: [String: String]) -> Self {
    .init(values: values)
  }
}
