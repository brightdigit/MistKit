//
//  QueryConfigTests+RequestOptions.swift
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

internal import Foundation
internal import Testing

@testable import MistDemoKit

extension QueryConfigTests {
  /// Covers the documented query request options wired for #383
  /// (`zoneWide`, `numbersAsStrings`). Both default to `nil` so they are
  /// omitted from the request unless the caller opts in.
  @Suite("Request Options")
  internal struct RequestOptions {
    @Test("QueryConfig defaults zoneWide and numbersAsStrings to nil")
    internal func defaultsToNil() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(base: baseConfig)

      #expect(config.zoneWide == nil)
      #expect(config.numbersAsStrings == nil)
    }

    @Test("QueryConfig carries explicit zoneWide and numbersAsStrings")
    internal func carriesExplicitValues() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        zoneWide: true,
        numbersAsStrings: false
      )

      #expect(config.zoneWide == true)
      #expect(config.numbersAsStrings == false)
    }
  }
}
