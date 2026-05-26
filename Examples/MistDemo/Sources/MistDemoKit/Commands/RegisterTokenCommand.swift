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
internal import MistKit

// `helpText` below is a multi-line string whose option column doesn't align
// with Swift's indent steps; the rule isn't useful inside literal help text.
// swiftlint:disable indentation_width

/// Command for `tokens/register`. Registers a device's APNs token so CloudKit
/// delivers subscription-triggered pushes to it. Per Apple's `RegisterTokens.html`
/// REST reference, the request requires both the hex token and the APNs
/// environment it targets.
public struct RegisterTokenCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = RegisterTokenConfig
  /// The command name.
  public static let commandName = "register-token"
  /// The command abstract.
  public static let abstract = "Register a device APNs token with CloudKit"
  /// The command help text.
  public static let helpText = """
    REGISTER-TOKEN - Register a device APNs token with CloudKit

    USAGE:
      mistdemo register-token --apns-token <hex> [--apns-environment <env>] \
        [--client-id <uuid>]

    OPTIONS:
      --apns-token <hex>             APNs device token (hex string) from a device
      --apns-environment <env>       APNs environment, default development
      --client-id <uuid>             Logical CloudKit client identifier — reuse
                                     the value passed to create-token to tie the
                                     two halves to the same logical client
      --database <type>              Database to target

    EXAMPLES:
      mistdemo register-token --apns-token 0a1b2c3d... \
        --apns-environment development --database private
    """

  private let config: RegisterTokenConfig

  /// Creates a new instance.
  public init(config: RegisterTokenConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    guard let apnsToken = config.apnsToken, !apnsToken.isEmpty else {
      throw TokenCommandError.missingAPNsToken
    }
    let environment = try resolveEnvironment()
    let service = try MistKitClientFactory.create(for: config.base)
    try await service.registerAPNsToken(
      apnsToken,
      environment: environment,
      clientId: config.clientId,
      database: config.base.database
    )
    print("✅ Registered APNs token with CloudKit.")
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

// swiftlint:enable indentation_width
