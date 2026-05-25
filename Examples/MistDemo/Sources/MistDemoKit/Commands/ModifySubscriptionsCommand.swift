//
//  ModifySubscriptionsCommand.swift
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

/// Command for `subscriptions/modify`. Creates or deletes a CloudKit
/// subscription.
public struct ModifySubscriptionsCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = ModifySubscriptionsConfig
  /// The command name.
  public static let commandName = "modify-subscriptions"
  /// The command abstract.
  public static let abstract = "Create or delete a CloudKit subscription"
  /// The command help text.
  public static let helpText = """
    MODIFY-SUBSCRIPTIONS - Create or delete a CloudKit subscription

    USAGE:
      mistdemo modify-subscriptions --operation create \\
        --subscription-id <id> --record-type <type> [--fires-on <events>]
      mistdemo modify-subscriptions --operation delete --subscription-id <id>

    OPTIONS:
      --operation <op>           create or delete (default: create)
      --subscription-id <id>     Subscription identifier (required)
      --record-type <type>       Record type for a create query subscription
      --fires-on <events>        Comma-separated: create,update,delete
      --database <type>          Database to target
      --output-format <format>   Output format (json, table, csv, yaml)

    EXAMPLES:
      mistdemo modify-subscriptions --operation create \\
        --subscription-id arts --record-type Article --database private
      mistdemo modify-subscriptions --operation delete \\
        --subscription-id arts --database private
    """

  private let config: ModifySubscriptionsConfig

  /// Creates a new instance.
  public init(config: ModifySubscriptionsConfig) {
    self.config = config
  }

  private static func parseFiresOn(_ raws: [String]) -> SubscriptionFireEvents {
    var firesOn: SubscriptionFireEvents = []
    for raw in raws {
      switch raw {
      case "create": firesOn.insert(.create)
      case "update": firesOn.insert(.update)
      case "delete": firesOn.insert(.delete)
      default: break
      }
    }
    return firesOn
  }

  /// Executes the command.
  public func execute() async throws {
    guard let subscriptionID = config.subscriptionID, !subscriptionID.isEmpty else {
      throw SubscriptionCommandError.missingSubscriptionID
    }
    let service = try MistKitClientFactory.create(for: config.base)

    switch config.operation {
    case "create":
      try await runCreate(subscriptionID: subscriptionID, service: service)
    case "delete":
      try await service.deleteSubscription(id: subscriptionID, database: config.base.database)
      print("✅ Deleted subscription '\(subscriptionID)'.")
    default:
      throw SubscriptionCommandError.invalidOperation(config.operation)
    }
  }

  private func runCreate(
    subscriptionID: String,
    service: CloudKitService
  ) async throws {
    guard let recordType = config.recordType, !recordType.isEmpty else {
      throw SubscriptionCommandError.missingRecordType
    }
    let firesOn = Self.parseFiresOn(config.firesOn)
    let created = try await service.createSubscription(
      .query(
        subscriptionID: subscriptionID,
        recordType: recordType,
        firesOn: firesOn
      ),
      database: config.base.database
    )
    try await outputResult(created, format: config.output)
  }
}
