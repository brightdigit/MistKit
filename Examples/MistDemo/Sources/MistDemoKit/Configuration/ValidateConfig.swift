//
//  ValidateConfig.swift
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

public import ConfigKeyKit
internal import Foundation

/// Configuration for the `validate` command.
public struct ValidateConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// If true, only check that credentials parse — skip the live `fetchCaller`
  /// round-trip.
  public let skipNetwork: Bool
  /// If true, also run a minimal `listZones` query against the configured
  /// database to verify end-to-end reachability.
  public let testQuery: Bool
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    skipNetwork: Bool = false,
    testQuery: Bool = false,
    output: OutputFormat = .json
  ) {
    self.base = base
    self.skipNetwork = skipNetwork
    self.testQuery = testQuery
    self.output = output
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let baseConfig: MistDemoConfig
    if let base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(
        configuration: configuration,
        base: nil
      )
    }

    let skipNetwork = configuration.bool(
      forKey: "validate.skip-network",
      default: false
    )
    let testQuery = configuration.bool(
      forKey: "validate.test-query",
      default: false
    )

    let outputString =
      configuration.string(
        forKey: MistDemoConstants.ConfigKeys.outputFormat,
        default: MistDemoConstants.Defaults.outputFormat
      ) ?? MistDemoConstants.Defaults.outputFormat
    let output = OutputFormat(rawValue: outputString) ?? .json

    self.init(
      base: baseConfig,
      skipNetwork: skipNetwork,
      testQuery: testQuery,
      output: output
    )
  }
}
