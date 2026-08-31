//
//  MistDemoConfigurationBoolTests.swift
//  MistDemo
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

internal import ConfigKeyKit
internal import Configuration
import Testing

@testable import MistDemoKit

/// Pins boolean resolution through the **real** command-line provider.
///
/// ``MistDemoConfiguration`` deliberately does not use ConfigKeyKit's `read(_:)` for
/// booleans: that resolves by probing `string(forKey:)`, and swift-configuration reports
/// a valueless flag only through `bool(forKey:)`. Routing booleans through the string
/// path makes every bare flag read as its default — measured directly:
/// `string(forKey: "verbose")` is `nil` while `bool(forKey: "verbose")` is `true`.
@Suite("MistDemoConfiguration booleans")
internal struct MistDemoConfigurationBoolTests {
  private static func cli(_ arguments: [String]) -> MistDemoConfiguration {
    MistDemoConfiguration(
      configReader: ConfigReader(
        providers: [CommandLineArgumentsProvider(arguments: ["mistdemo"] + arguments)]
      )
    )
  }

  @Test("A bare flag resolves true for a required boolean")
  internal func bareFlagIsTrue() {
    #expect(Self.cli(["--force"]).read(MistDemoKeys.Record.force))
    #expect(Self.cli(["--stdin"]).read(MistDemoKeys.Record.stdin))
    #expect(Self.cli(["--verbose"]).read(MistDemoKeys.Output.verbose))
  }

  @Test("A bare flag resolves true for an optional boolean")
  internal func bareFlagIsTrueWhenOptional() {
    #expect(Self.cli(["--zone-wide"]).read(MistDemoKeys.Query.zoneWide) == true)
    #expect(
      Self.cli(["--numbers-as-strings"]).read(MistDemoKeys.Record.numbersAsStrings) == true
    )
    #expect(
      Self.cli(["--fetch-root-record"]).read(MistDemoKeys.Sharing.fetchRootRecord) == true
    )
  }

  @Test("An absent optional boolean stays nil, distinct from an explicit false")
  internal func absentIsNil() {
    #expect(Self.cli([]).read(MistDemoKeys.Query.zoneWide) == nil)
    #expect(Self.cli(["--zone-wide", "false"]).read(MistDemoKeys.Query.zoneWide) == false)
  }

  @Test("A required boolean falls back to its default when absent")
  internal func defaultsWhenAbsent() {
    #expect(Self.cli([]).read(MistDemoKeys.Record.force) == false)
  }

  @Test("Renamed CloudKit credential flags resolve")
  internal func renamedCredentialFlags() {
    let config = Self.cli([
      "--cloudkit-container-id", "iCloud.com.example.Renamed",
      "--cloudkit-key-id", "abc123",
      "--cloudkit-environment", "production",
    ])
    #expect(config.read(MistDemoKeys.CloudKit.containerID) == "iCloud.com.example.Renamed")
    #expect(config.read(MistDemoKeys.CloudKit.keyID) == "abc123")
    #expect(config.read(MistDemoKeys.CloudKit.environment) == "production")
  }
}
