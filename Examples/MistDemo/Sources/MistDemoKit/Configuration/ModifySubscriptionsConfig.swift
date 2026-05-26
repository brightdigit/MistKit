//
//  ModifySubscriptionsConfig.swift
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

/// Configuration for the `modify-subscriptions` command.
public struct ModifySubscriptionsConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The operation to apply (`create` or `delete`). Defaults to `create`.
  public let operation: String
  /// The subscription ID to create or delete.
  public let subscriptionID: String?
  /// The record type for a `create` query subscription.
  public let recordType: String?
  /// Comma-separated fire events (`create`, `update`, `delete`).
  public let firesOn: [String]
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    operation: String = "create",
    subscriptionID: String? = nil,
    recordType: String? = nil,
    firesOn: [String] = ["create", "update", "delete"],
    output: OutputFormat = .json
  ) {
    self.base = base
    self.operation = operation
    self.subscriptionID = subscriptionID
    self.recordType = recordType
    self.firesOn = firesOn
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

    let firesOnString = configuration.string(forKey: "fires-on") ?? "create,update,delete"
    let firesOn =
      firesOnString
      .split(separator: ",")
      .map { String($0).trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    let outputString =
      configuration.string(
        forKey: MistDemoConstants.ConfigKeys.outputFormat,
        default: "json"
      ) ?? "json"
    let output = OutputFormat(rawValue: outputString) ?? .json

    self.init(
      base: baseConfig,
      operation: configuration.string(forKey: "operation", default: "create") ?? "create",
      subscriptionID: configuration.string(forKey: "subscription-id"),
      recordType: configuration.string(forKey: "record-type"),
      firesOn: firesOn,
      output: output
    )
  }
}
