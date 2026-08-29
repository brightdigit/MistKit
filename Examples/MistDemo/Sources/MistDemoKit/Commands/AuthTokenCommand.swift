//
//  AuthTokenCommand.swift
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

#if canImport(Hummingbird)
  internal import Foundation
  internal import MistKit

  /// Command to obtain web authentication token via browser flow.
  public struct AuthTokenCommand: MistDemoCommand {
    /// The configuration type.
    public typealias Config = AuthTokenConfig

    /// The command name.
    public static let commandName = MistDemoConstants.Commands.authToken
    /// The command abstract.
    public static let abstract =
      "Obtain a web authentication token via browser flow"
    /// The command help text.
    public static let helpText = """
      AUTH-TOKEN - Obtain web authentication token

      USAGE:
        mistdemo auth-token [options]

      OPTIONS:
        --api-token <token>      CloudKit API token
        --environment <env>      development (default) | production
        --port <port>            Server port (default: 8080)
        --host <host>            Server host (default: 127.0.0.1)
        --browser                Open browser on startup (default for auth-token)
        --no-browser             Don't open browser on startup (overrides --browser)
        --reset-auth             Sign out any persisted CloudKit JS session before
                                 capturing (force Apple ID picker)

      NOTES:
        For sharer + sharee tokens (test-private create→accept), use
        `mistdemo auth-tokens` instead.
      """

    internal let config: AuthTokenConfig

    /// Creates a new instance.
    public init(config: AuthTokenConfig) {
      self.config = config
    }

    /// Executes the command.
    public func execute() async throws {
      print("📍 Server URL: http://\(config.host):\(config.port)")
      if config.resetAuth {
        print("🔄 Reset auth — browser will clear any persisted Apple ID session.")
      }

      let token = try await WebAuthTokenCapture.capture(
        apiToken: config.apiToken,
        containerIdentifier: config.containerIdentifier,
        environment: config.environment,
        host: config.host,
        port: config.port,
        openBrowser: config.openBrowser,
        resetAuth: config.resetAuth
      )

      // Let the 205 response reach the browser before the process exits.
      try? await Task.sleep(nanoseconds: 500_000_000)
      print(token)
    }
  }
#endif
