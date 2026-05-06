//
//  CommandIntegrationTests+CrossCommandIntegration.swift
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

extension CommandIntegrationTests {
  @Suite("Cross-Command Integration")
  internal struct CrossCommandIntegration {
    private static func createTestConfig() async throws -> MistDemoConfig {
      try await MistDemoConfig()
    }

    @Test("Configuration consistency across commands")
    internal func configurationConsistencyAcrossCommands() async throws {
      let baseConfig = try await Self.createTestConfig()

      // Create configs for all commands
      _ = AuthTokenConfig(apiToken: "test-token")
      let userConfig = CurrentUserConfig(base: baseConfig)
      let queryConfig = QueryConfig(base: baseConfig)
      let createConfig = CreateConfig(
        base: baseConfig, zone: "_defaultZone", recordName: nil, fields: [])

      // Verify all use same base container
      #expect(userConfig.base.containerIdentifier == baseConfig.containerIdentifier)
      #expect(queryConfig.base.containerIdentifier == baseConfig.containerIdentifier)
      #expect(createConfig.base.containerIdentifier == baseConfig.containerIdentifier)

      // Verify environment consistency
      #expect(userConfig.base.environment == .development)
      #expect(queryConfig.base.environment == .development)
      #expect(createConfig.base.environment == .development)
    }

    @Test("Output format consistency")
    internal func outputFormatConsistency() async throws {
      let baseConfig = try await Self.createTestConfig()

      let userConfig = CurrentUserConfig(base: baseConfig, output: .json)
      let queryConfig = QueryConfig(base: baseConfig, output: .json)

      #expect(userConfig.output == .json)
      #expect(queryConfig.output == .json)

      // Test other formats
      let csvUserConfig = CurrentUserConfig(base: baseConfig, output: .csv)
      let csvQueryConfig = QueryConfig(base: baseConfig, output: .csv)

      #expect(csvUserConfig.output == .csv)
      #expect(csvQueryConfig.output == .csv)
    }
  }
}
