//
//  RegisterTokenCommand.swift
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

/// Stub command for `tokens/register`. Wires an APNs token into a CloudKit
/// subscription so push notifications get delivered. MistKit Swift wrapper
/// tracked in #53.
public struct RegisterTokenCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = RegisterTokenConfig
  /// The command name.
  public static let commandName = "register-token"
  /// The command abstract.
  public static let abstract = "Register an APNs token with a subscription (pending #53)"
  /// The command help text.
  public static let helpText = """
    REGISTER-TOKEN - Register an APNs token with a CloudKit subscription

    USAGE:
      mistdemo register-token --apns-token <hex> --subscription-id <id>

    OPTIONS:
      --apns-token <hex>             APNs device token (hex string)
      --subscription-id <id>         CloudKit subscription ID
      --database <type>              Database to target
      --output-format <format>       Output format (json, table, csv, yaml)

    STATUS:
      Not yet implemented — pending MistKit support, tracked in #53.
    """

  private let config: RegisterTokenConfig

  /// Creates a new instance.
  public init(config: RegisterTokenConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    PendingStub.printPending(endpoint: "tokens/register", trackingIssue: 53)
  }
}
