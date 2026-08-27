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
  internal import Hummingbird
  internal import MistKit

  /// Command to obtain web authentication token via browser flow.
  public struct AuthTokenCommand: MistDemoCommand {
    /// The configuration type.
    public typealias Config = AuthTokenConfig

    /// The command name.
    public static let commandName = "auth-token"
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
      """

    internal let config: AuthTokenConfig

    /// Creates a new instance.
    public init(config: AuthTokenConfig) {
      self.config = config
    }

    private static func captureToken(
      runService: @escaping @Sendable () async throws -> Void,
      tokenStore: WebAuthTokenStore,
      host: String,
      port: Int,
      openBrowser: Bool
    ) async throws -> String {
      do {
        return try await withTimeoutAndSignals(seconds: 300) {
          try await withThrowingTaskGroup(of: String?.self) { group in
            group.addTask {
              try await runService()
              return nil
            }
            group.addTask {
              if openBrowser {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                BrowserOpener.openBrowser(url: "http://\(host):\(port)")
              }
              return nil
            }
            group.addTask {
              var iterator = tokenStore.tokenUpdates.makeAsyncIterator()
              return await iterator.next()
            }

            while let result = try await group.next() {
              if let captured = result {
                group.cancelAll()
                return captured
              }
            }
            throw AuthTokenError.serverError(
              "Token capture failed unexpectedly"
            )
          }
        }
      } catch let error as AsyncTimeoutError {
        throw AuthTokenError.timeout(error.localizedDescription)
      }
    }

    /// Executes the command.
    public func execute() async throws {
      print("📍 Server URL: http://\(config.host):\(config.port)")
      if config.resetAuth {
        print("🔄 Reset auth — browser will clear any persisted Apple ID session.")
      }

      let tokenStore = WebAuthTokenStore()
      let server = WebServer(
        apiToken: config.apiToken,
        containerIdentifier: config.containerIdentifier,
        environment: config.environment,
        publicDatabaseAvailable: false,
        tokenStore: tokenStore,
        backendFactory: .live(
          apiToken: config.apiToken,
          containerIdentifier: config.containerIdentifier,
          environment: config.environment
        ),
        terminatesAfterAuth: true,
        resetAuth: config.resetAuth
      )
      let app = Application(
        router: try server.makeRouter(),
        configuration: .init(
          address: .hostname(config.host, port: config.port)
        )
      )

      let token = try await Self.captureToken(
        runService: { try await app.runService() },
        tokenStore: tokenStore,
        host: config.host,
        port: config.port,
        openBrowser: config.openBrowser
      )

      // Let the 205 response reach the browser before the process exits.
      try? await Task.sleep(nanoseconds: 500_000_000)
      print(token)
    }
  }
#endif
