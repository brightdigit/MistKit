//
//  ListSubscriptionsCommand.swift
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

/// Stub command for `subscriptions/list`. Lists every CloudKit subscription
/// registered against the selected database. MistKit Swift wrapper tracked
/// in #49.
public struct ListSubscriptionsCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = ListSubscriptionsConfig
  /// The command name.
  public static let commandName = "list-subscriptions"
  /// The command abstract.
  public static let abstract = "List CloudKit subscriptions (pending #49)"
  /// The command help text.
  public static let helpText = """
    LIST-SUBSCRIPTIONS - List CloudKit subscriptions

    USAGE:
      mistdemo list-subscriptions [options]

    OPTIONS:
      --database <type>          Database to target (private, shared, public)
      --output-format <format>   Output format (json, table, csv, yaml)

    STATUS:
      Not yet implemented — pending MistKit support, tracked in #49.
    """

  private let config: ListSubscriptionsConfig

  /// Creates a new instance.
  public init(config: ListSubscriptionsConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    PendingStub.printPending(endpoint: "subscriptions/list", trackingIssue: 49)
  }
}
