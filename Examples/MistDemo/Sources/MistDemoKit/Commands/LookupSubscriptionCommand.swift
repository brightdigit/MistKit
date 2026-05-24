//
//  LookupSubscriptionCommand.swift
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

internal import Foundation
internal import MistKit

/// Command for `subscriptions/lookup`. Looks up one or more CloudKit
/// subscriptions by ID.
public struct LookupSubscriptionCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = LookupSubscriptionConfig
  /// The command name.
  public static let commandName = "lookup-subscription"
  /// The command abstract.
  public static let abstract = "Look up a CloudKit subscription by ID"
  /// The command help text.
  public static let helpText = """
    LOOKUP-SUBSCRIPTION - Look up a CloudKit subscription by ID

    USAGE:
      mistdemo lookup-subscription --subscription-ids <list> [options]

    OPTIONS:
      --subscription-ids <list>  Comma-separated subscription IDs
      --database <type>          Database to target
      --output-format <format>   Output format (json, table, csv, yaml)

    EXAMPLES:
      mistdemo lookup-subscription --subscription-ids sub-1,sub-2 --database private
    """

  private let config: LookupSubscriptionConfig

  /// Creates a new instance.
  public init(config: LookupSubscriptionConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    guard !config.subscriptionIDs.isEmpty else {
      throw SubscriptionCommandError.missingSubscriptionIDs
    }
    let service = try MistKitClientFactory.create(for: config.base)
    let subscriptions = try await service.lookupSubscriptions(
      ids: config.subscriptionIDs,
      database: config.base.database
    )
    try await outputResults(subscriptions, format: config.output)
  }
}
