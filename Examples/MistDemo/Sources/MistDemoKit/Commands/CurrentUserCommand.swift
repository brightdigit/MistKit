//
//  CurrentUserCommand.swift
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

import Foundation
import MistKit

/// Command to get information about the authenticated user
public struct CurrentUserCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = CurrentUserConfig
  /// The command name.
  public static let commandName = "current-user"
  /// The command abstract.
  public static let abstract = "Get current user information"
  /// The command help text.
  public static let helpText = """
    CURRENT-USER - Get current user information

    USAGE:
      mistdemo current-user [options]

    OPTIONS:
      --api-token <token>        CloudKit API token
      --web-auth-token <token>   Web auth token
      --database <type>          Database to target
      --fields <fields>          Comma-separated fields
      --output-format <format>   Output format

    NOTES:
      - With --database public, requires server-to-server
        credentials; --web-auth-token is ignored.
      - With --database private or shared,
        --web-auth-token is required.
    """

  private let config: CurrentUserConfig

  /// Creates a new instance.
  public init(config: CurrentUserConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    do {
      // Create CloudKit client
      let client = try MistKitClientFactory.create(for: config.base)

      let userInfo = try await client.fetchCaller()
      try await outputResult(userInfo, format: config.output)
    } catch {
      throw CurrentUserError.operationFailed(error.localizedDescription)
    }
  }
}

// CurrentUserError is now defined in Errors/CurrentUserError.swift
