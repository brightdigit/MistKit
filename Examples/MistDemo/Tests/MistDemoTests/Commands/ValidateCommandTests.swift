//
//  ValidateCommandTests.swift
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

@Suite("ValidateCommand Tests")
internal struct ValidateCommandTests {
  @Test("Command has correct static properties")
  internal func staticProperties() {
    #expect(ValidateCommand.commandName == "validate")
    #expect(
      ValidateCommand.abstract == "Validate CloudKit credentials and reachability"
    )
    #expect(ValidateCommand.helpText.contains("VALIDATE"))
  }

  @Test("Command initializes with config")
  internal func initializesWithConfig() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ValidateConfig(base: baseConfig)
    _ = ValidateCommand(config: config)
  }

  @Test("Config defaults")
  internal func configDefaults() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ValidateConfig(base: baseConfig)
    #expect(config.skipNetwork == false)
    #expect(config.testQuery == false)
    #expect(config.output == .json)
  }

  @Test("Config accepts custom values")
  internal func configCustom() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ValidateConfig(
      base: baseConfig,
      skipNetwork: true,
      testQuery: true,
      output: .table
    )
    #expect(config.skipNetwork)
    #expect(config.testQuery)
    #expect(config.output == .table)
  }

  @Test("ValidationResult encodes")
  internal func validationResultEncodes() throws {
    let result = ValidationResult(
      credentialsValid: true,
      webAuthConfigured: false,
      serverToServerConfigured: true,
      errors: []
    )
    let data = try JSONEncoder().encode(result)
    let json = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    #expect(json["credentialsValid"] as? Bool == true)
    #expect(json["webAuthConfigured"] as? Bool == false)
    #expect(json["serverToServerConfigured"] as? Bool == true)
    #expect((json["errors"] as? [String])?.isEmpty == true)
  }
}
