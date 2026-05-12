//
//  WebCommand.swift
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

  /// Long-running interactive web demo: serves a single HTML page that
  /// performs the CloudKit auth round trip and then exposes a CRUD UI
  /// driven by MistKit on the server.
  ///
  /// Unlike `AuthTokenCommand`, this command does not exit after the
  /// browser-side auth completes — the server keeps running so the user
  /// can exercise the CRUD endpoints until they Ctrl+C.
  public struct WebCommand: MistDemoCommand {
    /// The configuration type.
    public typealias Config = WebDemoConfig

    /// The command name.
    public static let commandName = "web"
    /// The command abstract.
    public static let abstract =
      "Run the interactive MistKit web demo (CRUD + auth)"
    /// The command help text.
    public static let helpText = """
      WEB - Interactive MistKit web demo

      USAGE:
        mistdemo web [options]

      OPTIONS:
        --api-token <token>      CloudKit API token
        --environment <env>      development (default) | production
        --port <port>            Server port (default: 8080)
        --host <host>            Server host (default: 127.0.0.1)
        --no-browser             Don't open browser automatically

      The page authenticates against CloudKit via the browser, then
      exposes a CRUD UI that calls MistKit on the server. Ctrl+C to exit.
      """

    internal let config: WebDemoConfig

    /// Creates a new instance.
    public init(config: WebDemoConfig) {
      self.config = config
    }

    /// Executes the command.
    public func execute() async throws {
      print("📍 Server URL: http://\(config.host):\(config.port)")
      print("Press Ctrl+C to stop.")

      let tokenStore = WebAuthTokenStore()
      let server = WebDemoServer(
        apiToken: config.apiToken,
        containerIdentifier: config.containerIdentifier,
        environment: config.environment,
        tokenStore: tokenStore,
        backendFactory: .live(
          apiToken: config.apiToken,
          containerIdentifier: config.containerIdentifier,
          environment: config.environment
        ),
        terminatesAfterAuth: false
      )
      let router = try server.makeRouter()

      let app = Application(
        router: router,
        configuration: .init(
          address: .hostname(config.host, port: config.port)
        )
      )

      try await withSignalHandling {
        try await withThrowingTaskGroup(of: Void.self) { group in
          group.addTask {
            try await app.runService()
          }
          group.addTask {
            await openBrowserIfNeeded()
          }
          try await group.waitForAll()
        }
      }
    }

    private func openBrowserIfNeeded() async {
      guard !config.noBrowser else { return }
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      BrowserOpener.openBrowser(
        url: "http://\(config.host):\(config.port)"
      )
    }
  }
#endif
