//
//  QueryConfigTests+Offset.swift
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
import MistKit
import Testing

@testable import MistDemoKit

extension QueryConfigTests {
  @Suite("Offset")
  internal struct Offset {
    @Test("QueryConfig initializes with default offset")
    internal func initializeWithDefaultOffset() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(base: baseConfig)

      #expect(config.offset == 0)
    }

    @Test("QueryConfig initializes with custom offset")
    internal func initializeWithCustomOffset() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        offset: 10
      )

      #expect(config.offset == 10)
    }

    @Test("QueryConfig handles large offset")
    internal func handleLargeOffset() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        offset: 1_000
      )

      #expect(config.offset == 1_000)
    }
  }
}
