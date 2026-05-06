//
//  CurrentUserConfigTests+OutputFormat.swift
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

extension CurrentUserConfigTests {
  @Suite("Output Format")
  internal struct OutputFormatTests {
    @Test("CurrentUserConfig initializes with JSON output format")
    func initializeWithJSONOutput() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CurrentUserConfig(
        base: baseConfig,
        output: .json
      )

      #expect(config.output == .json)
    }

    @Test("CurrentUserConfig initializes with CSV output format")
    func initializeWithCSVOutput() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CurrentUserConfig(
        base: baseConfig,
        output: .csv
      )

      #expect(config.output == .csv)
    }

    @Test("CurrentUserConfig initializes with table output format")
    func initializeWithTableOutput() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CurrentUserConfig(
        base: baseConfig,
        output: .table
      )

      #expect(config.output == .table)
    }

    @Test("CurrentUserConfig initializes with YAML output format")
    func initializeWithYAMLOutput() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CurrentUserConfig(
        base: baseConfig,
        output: .yaml
      )

      #expect(config.output == .yaml)
    }
  }
}
