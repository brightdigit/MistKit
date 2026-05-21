//
//  CreateTokenCommand.swift
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

/// Stub command for `tokens/create`. Creates an APNs token CloudKit can use
/// to deliver push notifications to a registered subscription. MistKit
/// Swift wrapper tracked in #52.
public struct CreateTokenCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = CreateTokenConfig
  /// The command name.
  public static let commandName = "create-token"
  /// The command abstract.
  public static let abstract = "Create an APNs token for CloudKit subscriptions (pending #52)"
  /// The command help text.
  public static let helpText = """
    CREATE-TOKEN - Create an APNs token for CloudKit subscriptions

    USAGE:
      mistdemo create-token --apns-token <hex> [--apns-environment <env>]

    OPTIONS:
      --apns-token <hex>             APNs device token (hex string)
      --apns-environment <env>       APNs environment (development, production)
      --output-format <format>       Output format (json, table, csv, yaml)

    STATUS:
      Not yet implemented — pending MistKit support, tracked in #52.
    """

  private let config: CreateTokenConfig

  /// Creates a new instance.
  public init(config: CreateTokenConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    PendingStub.printPending(endpoint: "tokens/create", trackingIssue: 52)
  }
}
