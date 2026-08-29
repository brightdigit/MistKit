//
//  AuthTokensCommand.swift
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

  /// Captures two web-auth tokens (sharer + sharee) for `test-private` sharing.
  public struct AuthTokensCommand: MistDemoCommand {
    /// The configuration type.
    public typealias Config = AuthTokensConfig

    /// The command name.
    public static let commandName = MistDemoConstants.Commands.authTokens
    /// The command abstract.
    public static let abstract =
      "Obtain sharer and sharee web-auth tokens via browser flow"
    /// The command help text.
    public static let helpText = """
      AUTH-TOKENS - Obtain sharer + sharee web authentication tokens

      Runs the browser sign-in flow twice (always with reset-auth) so you can
      capture tokens for two different Apple IDs. Prints export lines for
      CLOUDKIT_WEB_AUTH_TOKEN (sharer) and CLOUDKIT_SHAREE_WEB_AUTH_TOKEN
      (sharee) — required by `mistdemo test-private`.

      USAGE:
        mistdemo auth-tokens [options]

      OPTIONS:
        --api-token <token>      CloudKit API token
        --environment <env>      development (default) | production
        --port <port>            Server port (default: 8080)
        --host <host>            Server host (default: 127.0.0.1)
        --browser                Open browser on each capture (default)
        --no-browser             Don't open browser (overrides --browser)
        --sharee-email <email>   Sharee's iCloud email; included in the export
                                 block as CLOUDKIT_SHAREE_EMAIL

      EXAMPLES:
        mistdemo auth-tokens --sharee-email sharee@example.com
        CLOUDKIT_API_TOKEN=… mistdemo auth-tokens

      NOTES:
        - Sign in as the sharer first, then as a different Apple ID for sharee.
        - Reset-auth is always on so the second capture forces the Apple ID picker.
        - For a single token, use `mistdemo auth-token`.
      """

    internal let config: AuthTokensConfig

    /// Creates a new instance.
    public init(config: AuthTokensConfig) {
      self.config = config
    }

    /// Executes the command.
    public func execute() async throws {
      print("📍 Server URL: http://\(config.host):\(config.port)")
      print("🔄 Reset auth is always on for dual capture.")

      print(
        """

        1️⃣  Sign in as the SHARER (primary Apple ID).
           Browser will clear any persisted session first.
        """
      )
      let sharerToken = try await WebAuthTokenCapture.capture(
        apiToken: config.apiToken,
        containerIdentifier: config.containerIdentifier,
        environment: config.environment,
        host: config.host,
        port: config.port,
        openBrowser: config.openBrowser,
        resetAuth: true
      )
      // Let the 205 reach the browser before restarting the server.
      try? await Task.sleep(nanoseconds: 500_000_000)
      print("✅ Sharer token captured.")

      print(
        """

        2️⃣  Sign in as the SHAREE (a different Apple ID).
           Browser will clear the sharer session before the picker.
        """
      )
      let shareeToken = try await WebAuthTokenCapture.capture(
        apiToken: config.apiToken,
        containerIdentifier: config.containerIdentifier,
        environment: config.environment,
        host: config.host,
        port: config.port,
        openBrowser: config.openBrowser,
        resetAuth: true
      )
      try? await Task.sleep(nanoseconds: 500_000_000)
      print("✅ Sharee token captured.")

      print(
        """

        # Paste into your shell, .env, or GitHub Actions secrets:
        export CLOUDKIT_WEB_AUTH_TOKEN='\(sharerToken)'
        export CLOUDKIT_SHAREE_WEB_AUTH_TOKEN='\(shareeToken)'
        """
      )
      if let shareeEmail = config.shareeEmail, !shareeEmail.isEmpty {
        print("export CLOUDKIT_SHAREE_EMAIL='\(shareeEmail)'")
      } else {
        print(
          """
          # Also set the sharee's iCloud email (required by test-private):
          export CLOUDKIT_SHAREE_EMAIL='sharee@example.com'
          """
        )
      }
    }
  }
#endif
