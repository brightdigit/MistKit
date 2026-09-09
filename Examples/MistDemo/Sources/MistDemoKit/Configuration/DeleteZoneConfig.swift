//
//  DeleteZoneConfig.swift
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

/// Configuration for delete-zone command.
public struct DeleteZoneConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The zone name to delete.
  public let zoneName: String
  /// Optional owner record name (typically nil for the caller's own zones).
  public let ownerRecordName: String?
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    zoneName: String,
    ownerRecordName: String? = nil,
    output: OutputFormat = .table
  ) {
    self.base = base
    self.zoneName = zoneName
    self.ownerRecordName = ownerRecordName
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

    guard
      let zoneName = configuration.read(MistDemoKeys.Query.zoneName),
      !zoneName.isEmpty
    else {
      throw ConfigurationError.missingRequired(
        "zone.name",
        suggestion: "Pass --zone-name <name>."
      )
    }

    let ownerRecordName = configuration.read(MistDemoKeys.Query.zoneOwner)

    let outputString =
      configuration.read(MistDemoKeys.Output.format)
    let output = OutputFormat(rawValue: outputString) ?? .table

    self.init(
      base: baseConfig,
      zoneName: zoneName,
      ownerRecordName: ownerRecordName,
      output: output
    )
  }
}
