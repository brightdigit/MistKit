//
//  ExportSchemaConfig.swift
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

/// Configuration for the `export-schema` command.
public struct ExportSchemaConfig: Sendable, ConfigurationParseable {
  /// The reader this config parses from.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// Container and environment.
  public let base: MistDemoConfig
  /// The management token (secret), if configured.
  public let managementToken: String?
  /// The Apple Developer team ID, if configured.
  public let teamID: String?
  /// Whether to print the schema text exactly as exported.
  public let raw: Bool

  /// Creates a configuration from its parts.
  public init(
    base: MistDemoConfig,
    managementToken: String?,
    teamID: String?,
    raw: Bool = false
  ) {
    self.base = base
    self.managementToken = managementToken
    self.teamID = teamID
    self.raw = raw
  }

  /// Reads the configuration from Swift Configuration's providers.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let baseConfig: MistDemoConfig
    if let base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(configuration: configuration, base: nil)
    }
    self.init(
      base: baseConfig,
      managementToken: configuration.read(MistDemoKeys.Management.token),
      teamID: configuration.read(MistDemoKeys.Management.teamID),
      raw: configuration.read(MistDemoKeys.Management.raw)
    )
  }
}
