//
//  TestPublicConfig.swift
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

/// Configuration for test-public command.
public struct TestPublicConfig: Sendable, ConfigurationParseable {
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
  /// Optional email used by the lookup-users-by-email phase. Must belong to
  /// an iCloud account discoverable to the caller; otherwise the phase skips.
  public let lookupEmail: String?
  /// Optional share short GUID used by the resolve/accept sharing phases.
  /// Must identify an existing share; otherwise both phases skip.
  public let shareShortGUID: String?

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    recordCount: Int = 10,
    assetSizeKB: Int = 100,
    skipCleanup: Bool = false,
    verbose: Bool = false,
    lookupEmail: String? = nil,
    shareShortGUID: String? = nil
  ) {
    self.base = base
    self.recordCount = recordCount
    self.assetSizeKB = assetSizeKB
    self.skipCleanup = skipCleanup
    self.verbose = verbose
    self.lookupEmail = lookupEmail
    self.shareShortGUID = shareShortGUID
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
    let lookupEmail = configuration.string(forKey: "lookup.email")
    let shareShortGUID = configuration.string(forKey: "share.short.guid")

    self.init(
      base: baseConfig,
      recordCount: recordCount,
      assetSizeKB: assetSizeKB,
      skipCleanup: skipCleanup,
      verbose: verbose,
      lookupEmail: lookupEmail,
      shareShortGUID: shareShortGUID
    )
  }
}
