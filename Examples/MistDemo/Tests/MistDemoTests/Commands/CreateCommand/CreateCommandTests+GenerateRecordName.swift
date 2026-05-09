//
//  CreateCommandTests+GenerateRecordName.swift
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

extension CreateCommandTests {
  @Suite("generateRecordName helper")
  internal struct GenerateRecordNameHelper {
    @Test("generateRecordName prefixes with lowercased record type")
    internal func lowercasePrefix() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CreateConfig(base: baseConfig, recordType: "Article")
      let command = CreateCommand(config: config)

      let name = command.generateRecordName()

      #expect(name.hasPrefix("article-"))
    }

    @Test("generateRecordName format is <type>-<timestamp>-<4-digit suffix>")
    internal func threePartFormat() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CreateConfig(base: baseConfig, recordType: "Note")
      let command = CreateCommand(config: config)

      let name = command.generateRecordName()
      let parts = name.split(separator: "-").map(String.init)

      #expect(parts.count == 3)
      #expect(parts[0] == "note")
      #expect(Int(parts[1]) != nil, "expected a unix timestamp; got \(parts[1])")
      let suffix = try #require(Int(parts[2]))
      #expect(suffix >= MistDemoConstants.Limits.randomSuffixMin)
      #expect(suffix <= MistDemoConstants.Limits.randomSuffixMax)
    }

    @Test("generateRecordName produces distinct values across many calls")
    internal func distinctness() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CreateConfig(base: baseConfig, recordType: "Note")
      let command = CreateCommand(config: config)

      // The random suffix has ~9000 values; 200 samples should be highly unique.
      // Allow some collisions but require that most samples are distinct, which
      // verifies the random component is being used.
      let names = (0..<200).map { _ in command.generateRecordName() }
      let unique = Set(names)
      #expect(unique.count > 150)
    }
  }
}
