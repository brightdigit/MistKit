//
//  CreateCommandTests+Configuration.swift
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

extension CreateCommandTests {
  @Suite("Configuration")
  internal struct Configuration {
    @Test("CreateConfig initializes with default values")
    internal func createConfigInitializesWithDefaults() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CreateConfig(
        base: baseConfig,
        zone: "_defaultZone",
        recordName: nil,
        fields: []
      )

      #expect(config.zone == "_defaultZone")
      #expect(config.recordName == nil)
      #expect(config.fields.isEmpty)
    }

    @Test("CreateConfig accepts custom values")
    internal func createConfigAcceptsCustomValues() async throws {
      let baseConfig = try await MistDemoConfig()
      let fields = [
        Field(name: "title", type: .string, value: "Test Note"),
        Field(name: "priority", type: .int64, value: "5"),
      ]
      let config = CreateConfig(
        base: baseConfig,
        zone: "customZone",
        recordName: "customRecord",
        fields: fields
      )

      #expect(config.zone == "customZone")
      #expect(config.recordName == "customRecord")
      #expect(config.fields.count == 2)
    }
  }
}
