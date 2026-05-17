//
//  CommandIntegrationTests+RealWorldUsageSimulation.swift
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
  @Suite("Real-world Usage Simulation")
  internal struct RealWorldUsageSimulation {
    private static func createTestConfig() async throws -> MistDemoConfig {
      try await MistDemoConfig()
    }

    @Test("Simulate complete workflow")
    internal func simulateCompleteWorkflow() async throws {
      // 1. Auth token configuration
      #if canImport(Hummingbird)
        let authConfig = AuthTokenConfig(
          apiToken: "mock-api-token-for-test",
          openBrowser: false
        )
        _ = AuthTokenCommand(config: authConfig)
      #endif

      // 2. Current user check
      let baseConfig = try await Self.createTestConfig()
      let userConfig = CurrentUserConfig(base: baseConfig)
      _ = CurrentUserCommand(config: userConfig)

      // 3. Query existing records
      let queryConfig = QueryConfig(
        base: baseConfig,
        filters: ["title:contains:test"],
        limit: 10
      )
      _ = QueryCommand(config: queryConfig)

      // 4. Create new record
      let fields = [try Field(parsing: "title:string:Workflow Test")]
      let createConfig = CreateConfig(
        base: baseConfig,
        zone: "_defaultZone",
        recordName: nil,
        fields: fields
      )
      _ = CreateCommand(config: createConfig)

      // Verify all commands are properly configured
      #if canImport(Hummingbird)
        #expect(AuthTokenCommand.commandName == "auth-token")
      #endif
      #expect(CurrentUserCommand.commandName == "current-user")
      #expect(QueryCommand.commandName == "query")
      #expect(CreateCommand.commandName == "create")
    }
  }
}
