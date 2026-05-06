//
//  CreateConfigTests+ComplexInitialization.swift
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

extension CreateConfigTests {
  @Suite("Complex Initialization")
  internal struct ComplexInitialization {
    @Test("CreateConfig initializes with all custom values")
    func initializeWithAllCustomValues() async throws {
      let baseConfig = try await MistDemoConfig()
      let fields = [
        Field(name: "name", type: .string, value: "John Doe"),
        Field(name: "age", type: .int64, value: "30"),
      ]
      let config = CreateConfig(
        base: baseConfig,
        zone: "customZone",
        recordType: "Person",
        recordName: "person001",
        fields: fields,
        output: .yaml
      )

      #expect(config.zone == "customZone")
      #expect(config.recordType == "Person")
      #expect(config.recordName == "person001")
      #expect(config.fields.count == 2)
      #expect(config.output == .yaml)
    }
  }
}
