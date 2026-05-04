//
//  LookupConfig.swift
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
import Foundation

/// Configuration for lookup command
public struct LookupConfig: Sendable, ConfigurationParseable {
  public typealias ConfigReader = MistDemoConfiguration
  public typealias BaseConfig = MistDemoConfig

  public let base: MistDemoConfig
  public let recordNames: [String]
  public let fields: [String]?
  public let output: OutputFormat

  public init(
    base: MistDemoConfig,
    recordNames: [String],
    fields: [String]? = nil,
    output: OutputFormat = .json
  ) {
    self.base = base
    self.recordNames = recordNames
    self.fields = fields
    self.output = output
  }

  public init(configuration: MistDemoConfiguration, base: MistDemoConfig?) async throws {
    let configReader = configuration
    let baseConfig: MistDemoConfig
    if let base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(configuration: configuration, base: nil)
    }

    // --record-names accepts a comma-separated list. --record-name (singular) also works for a single name.
    let recordNames: [String]
    if let raw = configReader.string(forKey: MistDemoConstants.ConfigKeys.recordNames) {
      recordNames = raw.split(separator: ",").map {
        String($0).trimmingCharacters(in: .whitespaces)
      }.filter { !$0.isEmpty }
    } else if let single = configReader.string(forKey: MistDemoConstants.ConfigKeys.recordName) {
      recordNames = [single]
    } else {
      recordNames = []
    }

    guard !recordNames.isEmpty else {
      throw LookupError.recordNamesRequired
    }

    let fieldsString = configReader.string(forKey: MistDemoConstants.ConfigKeys.fields)
    let fields = fieldsString?.split(separator: ",").map {
      String($0).trimmingCharacters(in: .whitespaces)
    }.filter { !$0.isEmpty }

    let outputString =
      configReader.string(
        forKey: MistDemoConstants.ConfigKeys.outputFormat,
        default: MistDemoConstants.Defaults.outputFormat) ?? MistDemoConstants.Defaults.outputFormat
    let output = OutputFormat(rawValue: outputString) ?? .json

    self.init(
      base: baseConfig,
      recordNames: recordNames,
      fields: fields,
      output: output
    )
  }
}
