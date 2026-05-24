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

/// Command for `tokens/register`. Registers a device's APNs token so CloudKit
/// delivers subscription-triggered pushes to it. The token itself is captured
/// from a real iOS/macOS device; `/tokens/register` takes only that token.
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
      mistdemo register-token --apns-token <hex>

    OPTIONS:
      --apns-token <hex>             APNs device token (hex string) from a device
      --database <type>              Database to target

    EXAMPLES:
      mistdemo register-token --apns-token 0a1b2c3d... --database private
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
    let service = try MistKitClientFactory.create(for: config.base)
    try await service.registerAPNsToken(apnsToken, database: config.base.database)
    print("✅ Registered APNs token with CloudKit.")
  }
}
