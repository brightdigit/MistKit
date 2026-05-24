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
internal import MistKit

/// Command for `tokens/create`. Mints a CloudKit-managed APNs token that
/// non-device callers use as the destination for subscription-triggered pushes.
public struct CreateTokenCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = CreateTokenConfig
  /// The command name.
  public static let commandName = "create-token"
  /// The command abstract.
  public static let abstract = "Create an APNs token for CloudKit subscriptions"
  /// The command help text.
  public static let helpText = """
    CREATE-TOKEN - Create an APNs token for CloudKit subscriptions

    USAGE:
      mistdemo create-token [--apns-environment <env>]

    OPTIONS:
      --apns-environment <env>       APNs environment, default development
      --database <type>              Database to target
      --output-format <format>       Output format (json, table, csv, yaml)

    EXAMPLES:
      mistdemo create-token --apns-environment development
    """

  private let config: CreateTokenConfig

  /// Creates a new instance.
  public init(config: CreateTokenConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    let environment = try resolveEnvironment()
    let service = try MistKitClientFactory.create(for: config.base)
    let result = try await service.createAPNsToken(
      environment: environment,
      database: config.base.database
    )
    try await outputResult(result, format: config.output)
  }

  private func resolveEnvironment() throws -> APNsEnvironment {
    guard let raw = config.apnsEnvironment else {
      return .development
    }
    guard let environment = APNsEnvironment(rawValue: raw) else {
      throw TokenCommandError.invalidEnvironment(raw)
    }
    return environment
  }
}
