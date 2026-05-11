//
//  DemoErrorsRunnerOutputTests.swift
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
import Testing

@testable import MistDemoKit

@Suite("DemoErrorsRunner output helpers")
internal struct DemoErrorsRunnerOutputTests {
  @Test("describe(nil) returns the <none> placeholder")
  internal func describeNil() async throws {
    let config = try await MistDemoConfig()
    let runner = DemoErrorsRunner(config: config)

    #expect(runner.describe(nil) == "<none>")
  }

  @Test("describe(\"\") returns the <none> placeholder")
  internal func describeEmpty() async throws {
    let config = try await MistDemoConfig()
    let runner = DemoErrorsRunner(config: config)

    #expect(runner.describe("") == "<none>")
  }

  @Test("describe echoes a non-empty tag verbatim")
  internal func describeNonEmpty() async throws {
    let config = try await MistDemoConfig()
    let runner = DemoErrorsRunner(config: config)

    #expect(runner.describe("rec-tag-1") == "rec-tag-1")
  }

  @Test("describe preserves whitespace in a non-empty tag")
  internal func describePreservesWhitespace() async throws {
    let config = try await MistDemoConfig()
    let runner = DemoErrorsRunner(config: config)

    // Only fully empty strings are normalized to <none>;
    // whitespace-only tags are kept as-is.
    #expect(runner.describe("   ") == "   ")
  }
}
