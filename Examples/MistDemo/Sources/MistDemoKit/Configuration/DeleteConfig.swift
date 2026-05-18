//
//  DeleteConfig.swift
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

/// Configuration for delete command.
public struct DeleteConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The CloudKit zone name.
  public let zone: String
  /// The CloudKit record type.
  public let recordType: String
  /// The record name to delete.
  public let recordName: String
  /// The optional record change tag for conflict detection.
  public let recordChangeTag: String?
  /// Whether to force deletion without change tag.
  public let force: Bool
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    zone: String = "_defaultZone",
    recordType: String = "Note",
    recordName: String,
    recordChangeTag: String? = nil,
    force: Bool = false,
    output: OutputFormat = .json
  ) {
    self.base = base
    self.zone = zone
    self.recordType = recordType
    self.recordName = recordName
    self.recordChangeTag = recordChangeTag
    self.force = force
    self.output = output
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let configReader = configuration
    let baseConfig: MistDemoConfig
    if let base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(
        configuration: configuration,
        base: nil
      )
    }

    let zone =
      configReader.string(
        forKey: MistDemoConstants.ConfigKeys.zone,
        default: MistDemoConstants.Defaults.zone
      ) ?? MistDemoConstants.Defaults.zone
    let recordType =
      configReader.string(
        forKey: MistDemoConstants.ConfigKeys.recordType,
        default: MistDemoConstants.Defaults.recordType
      ) ?? MistDemoConstants.Defaults.recordType

    guard
      let recordName = configReader.string(forKey: MistDemoConstants.ConfigKeys.recordName)
    else {
      throw DeleteError.recordNameRequired
    }

    let recordChangeTag = configReader.string(
      forKey: MistDemoConstants.ConfigKeys.recordChangeTag
    )
    let force = configReader.bool(
      forKey: MistDemoConstants.ConfigKeys.force,
      default: false
    )

    let outputString =
      configReader.string(
        forKey: MistDemoConstants.ConfigKeys.outputFormat,
        default: MistDemoConstants.Defaults.outputFormat
      ) ?? MistDemoConstants.Defaults.outputFormat
    let output = OutputFormat(rawValue: outputString) ?? .json

    self.init(
      base: baseConfig,
      zone: zone,
      recordType: recordType,
      recordName: recordName,
      recordChangeTag: recordChangeTag,
      force: force,
      output: output
    )
  }
}
