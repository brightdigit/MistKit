//
//  CommandIntegrationTests+CurrentUserCommandIntegration.swift
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
  @Suite("CurrentUserCommand Integration")
  internal struct CurrentUserCommandIntegration {
    private static func createTestConfig() async throws -> MistDemoConfig {
      try await MistDemoConfig()
    }

    @Test("CurrentUserCommand end-to-end flow")
    internal func currentUserCommandEndToEndFlow() async throws {
      let baseConfig = try await Self.createTestConfig()
      let config = CurrentUserConfig(
        base: baseConfig,
        fields: ["userRecordName", "emailAddress"],
        output: .json
      )

      _ = CurrentUserCommand(config: config)

      // Verify command configuration
      #expect(CurrentUserCommand.commandName == "current-user")

      // Verify config properties
      #expect(config.fields?.count == 2)
      #expect(config.output == .json)
    }

    @Test("CurrentUserCommand with field filtering")
    internal func currentUserCommandWithFieldFiltering() async throws {
      let baseConfig = try await Self.createTestConfig()
      let config = CurrentUserConfig(
        base: baseConfig,
        fields: ["userRecordName", "firstName", "lastName"],
        output: .table
      )

      _ = CurrentUserCommand(config: config)

      // Verify field filtering setup
      #expect(config.fields?.contains("userRecordName") == true)
      #expect(config.fields?.contains("firstName") == true)
      #expect(config.fields?.contains("lastName") == true)
      #expect(config.output == .table)
    }
  }
}
