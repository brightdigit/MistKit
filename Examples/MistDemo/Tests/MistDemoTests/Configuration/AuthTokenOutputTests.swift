//
//  AuthTokenOutputTests.swift
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

internal import ConfigKeyKit
internal import Configuration
internal import Foundation
internal import Testing

@testable import MistDemoKit

@Suite("AuthTokenOutput Tests")
internal struct AuthTokenOutputTests {
  private static func cli(_ arguments: [String]) -> MistDemoConfiguration {
    MistDemoConfiguration(
      configReader: ConfigReader(
        providers: [CommandLineArgumentsProvider(arguments: ["mistdemo"] + arguments)]
      )
    )
  }

  @Test("Parses every case case-insensitively", arguments: AuthTokenOutput.allCases)
  internal func parsesCases(_ output: AuthTokenOutput) throws {
    #expect(try AuthTokenOutput(parsing: output.rawValue) == output)
    #expect(try AuthTokenOutput(parsing: output.rawValue.uppercased()) == output)
  }

  @Test("Rejects an unknown output value")
  internal func rejectsUnknown() {
    #expect(throws: MistDemoKit.ConfigurationError.self) {
      _ = try AuthTokenOutput(parsing: "json")
    }
  }

  @Test("--output defaults to text and reads env from the command line")
  internal func commandLineFlag() throws {
    let absent = Self.cli([]).read(MistDemoKeys.Output.authTokenOutput)
    #expect(try AuthTokenOutput(parsing: absent) == .text)

    let env = Self.cli(["--output", "env"]).read(MistDemoKeys.Output.authTokenOutput)
    #expect(try AuthTokenOutput(parsing: env) == .env)
  }

  @Test("--output does not collide with --output-format")
  internal func distinctFromOutputFormat() {
    let config = Self.cli(["--output-format", "json"])
    #expect(config.read(MistDemoKeys.Output.authTokenOutput) == AuthTokenOutput.text.rawValue)
    #expect(config.read(MistDemoKeys.Output.format) == "json")
  }

  @Test("envLines emits only the sharer token when nothing else is given")
  internal func envLinesSingle() {
    #expect(
      AuthTokenOutput.envLines(webAuthToken: "sharer==tok")
        == ["CLOUDKIT_WEB_AUTH_TOKEN=sharer==tok"]
    )
  }

  @Test("envLines emits sharer, sharee, and email in order")
  internal func envLinesAll() {
    let lines = AuthTokenOutput.envLines(
      webAuthToken: "a",
      shareeWebAuthToken: "b",
      shareeEmail: "sharee@example.com"
    )
    #expect(
      lines == [
        "CLOUDKIT_WEB_AUTH_TOKEN=a",
        "CLOUDKIT_SHAREE_WEB_AUTH_TOKEN=b",
        "CLOUDKIT_SHAREE_EMAIL=sharee@example.com",
      ]
    )
  }

  @Test("envLines omits empty optional values")
  internal func envLinesOmitsEmpty() {
    let lines = AuthTokenOutput.envLines(
      webAuthToken: "a",
      shareeWebAuthToken: "b",
      shareeEmail: ""
    )
    #expect(lines == ["CLOUDKIT_WEB_AUTH_TOKEN=a", "CLOUDKIT_SHAREE_WEB_AUTH_TOKEN=b"])
  }
}
