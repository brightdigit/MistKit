//
//  TestIntegrationConfig.swift
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

/// Configuration for test-integration command.
public struct TestIntegrationConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The number of records to create during testing.
  public let recordCount: Int
  /// The asset size in kilobytes for upload testing.
  public let assetSizeKB: Int
  /// Whether to skip cleanup after testing.
  public let skipCleanup: Bool
  /// Whether to enable verbose output.
  public let verbose: Bool

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    recordCount: Int = 10,
    assetSizeKB: Int = 100,
    skipCleanup: Bool = false,
    verbose: Bool = false
  ) {
    self.base = base
    self.recordCount = recordCount
    self.assetSizeKB = assetSizeKB
    self.skipCleanup = skipCleanup
    self.verbose = verbose
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

    let recordCount =
      configuration.int(forKey: "record.count", default: 10) ?? 10
    let assetSizeKB =
      configuration.int(forKey: "asset.size", default: 100) ?? 100
    let skipCleanup =
      configuration.bool(forKey: "skip.cleanup", default: false)
    let verbose =
      configuration.bool(forKey: "verbose", default: false)

    self.init(
      base: baseConfig,
      recordCount: recordCount,
      assetSizeKB: assetSizeKB,
      skipCleanup: skipCleanup,
      verbose: verbose
    )
  }
}
