//
//  UpdateConfigTests+CombinedEdgeCases.swift
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

extension UpdateConfigTests {
  @Suite("Combined / Edge Cases")
  internal struct CombinedEdgeCases {
    @Test("UpdateConfig initializes with all custom values")
    internal func initializeWithAllCustomValues() async throws {
      let baseConfig = try await MistDemoConfig()
      let fields = [
        Field(name: "title", type: .string, value: "x"),
        Field(name: "n", type: .int64, value: "1"),
      ]
      let config = UpdateConfig(
        base: baseConfig,
        zone: "Z",
        recordType: "T",
        recordName: "R",
        recordChangeTag: "tag",
        force: true,
        fields: fields,
        output: .yaml
      )

      #expect(config.zone == "Z")
      #expect(config.recordType == "T")
      #expect(config.recordName == "R")
      #expect(config.recordChangeTag == "tag")
      #expect(config.force == true)
      #expect(config.fields.count == 2)
      #expect(config.output == .yaml)
    }

    @Test("UpdateConfig handles special characters in record name")
    internal func specialCharactersInRecordName() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = UpdateConfig(base: baseConfig, recordName: "rec-name_with.special@chars")

      #expect(config.recordName == "rec-name_with.special@chars")
    }
  }
}
