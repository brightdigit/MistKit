//
//  DiscoverCommandTests.swift
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

@Suite("DiscoverCommand Tests")
internal struct DiscoverCommandTests {
  @Test("Command has correct static properties")
  internal func staticProperties() {
    #expect(DiscoverCommand.commandName == "discover")
    #expect(DiscoverCommand.abstract == "Discover user identities by email")
    #expect(DiscoverCommand.helpText.contains("DISCOVER"))
  }

  @Test("Config initializes with emails")
  internal func configWithEmails() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DiscoverConfig(
      base: baseConfig,
      emails: ["alice@example.com", "bob@example.com"]
    )
    #expect(config.emails.count == 2)
    #expect(config.output == .json)
  }

  @Test("Execute rejects empty emails")
  internal func rejectsEmptyEmails() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DiscoverConfig(base: baseConfig, emails: [])
    let command = DiscoverCommand(config: config)

    await #expect(throws: DiscoverError.self) {
      try await command.execute()
    }
  }

  @Test("Execute rejects missing web-auth")
  internal func rejectsMissingWebAuth() async throws {
    // No webAuthToken set → hasUserContextCredentials == false
    let baseConfig = try await MistDemoConfig()
    let config = DiscoverConfig(
      base: baseConfig,
      emails: ["alice@example.com"]
    )
    let command = DiscoverCommand(config: config)

    await #expect(throws: DiscoverError.self) {
      try await command.execute()
    }
  }
}
