//
//  ProbeEncryptedConfig.swift
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
internal import MistKit

/// Configuration for the `probe-encrypted` command.
public struct ProbeEncryptedConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// Default base record name for the probe records.
  public static let defaultRecordName = "mistkit-enc-probe"

  /// The base MistDemo configuration, pinned to a private or shared database.
  public let base: MistDemoConfig
  /// Base record name; the plain sibling is `<recordName>-plain`.
  public let recordName: String
  /// Optional custom zone. `nil` targets the database's default zone.
  public let zoneName: String?
  /// Optional zone owner record name (shared zones).
  public let zoneOwner: String?
  /// Size of the probe asset in kilobytes.
  public let assetSizeKB: Int
  /// Skip the write steps and only read back an earlier run's records.
  public let skipWrite: Bool
  /// Delete the probe records at the end of the run.
  public let cleanup: Bool
  /// Whether to enable verbose output (HTTP traces at debug level).
  public let verbose: Bool

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    recordName: String = ProbeEncryptedConfig.defaultRecordName,
    zoneName: String? = nil,
    zoneOwner: String? = nil,
    assetSizeKB: Int = 100,
    skipWrite: Bool = false,
    cleanup: Bool = false,
    verbose: Bool = false
  ) {
    self.base = base
    self.recordName = recordName
    self.zoneName = zoneName
    self.zoneOwner = zoneOwner
    self.assetSizeKB = assetSizeKB
    self.skipWrite = skipWrite
    self.cleanup = cleanup
    self.verbose = verbose
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let parsedBase: MistDemoConfig
    if let base {
      parsedBase = base
    } else {
      parsedBase = try await MistDemoConfig(
        configuration: configuration,
        base: nil
      )
    }
    // Encrypted fields exist only on private and shared databases; a public
    // selection (the CLI default) is redirected to private.
    let baseConfig: MistDemoConfig
    if case .public = parsedBase.database {
      baseConfig = parsedBase.with(database: .private)
    } else {
      baseConfig = parsedBase
    }

    guard
      let webAuthToken = baseConfig.webAuthToken,
      !webAuthToken.isEmpty
    else {
      throw ConfigurationError.missingRequired(
        "web.auth.token",
        suggestion:
          "Provide via CLOUDKIT_WEB_AUTH_TOKEN or run `mistdemo auth-token`"
      )
    }

    let recordName =
      configuration.read(MistDemoKeys.Record.recordName)
      ?? Self.defaultRecordName

    self.init(
      base: baseConfig,
      recordName: recordName,
      zoneName: configuration.read(MistDemoKeys.Query.zoneName),
      zoneOwner: configuration.read(MistDemoKeys.Query.zoneOwner),
      assetSizeKB: configuration.read(MistDemoKeys.Integration.assetSize),
      skipWrite: configuration.read(MistDemoKeys.Integration.skipWrite),
      cleanup: configuration.read(MistDemoKeys.Integration.cleanup),
      verbose: configuration.read(MistDemoKeys.Output.verbose)
    )
  }
}
