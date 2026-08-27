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
    public typealias Config = WebConfig

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
        --browser                Open browser on startup (overrides default)
        --no-browser             Don't open browser on startup (default for web)

      OPTIONAL — public database (server-to-server):
        --key-id <id>            CloudKit server-to-server key ID
        --private-key <pem>      Server-to-server private key (inline PEM)
        --private-key-path <p>   Path to server-to-server private key file

      The page authenticates against CloudKit via the browser, then
      exposes a CRUD UI that calls MistKit on the server. When key
      material is provided, the UI also exposes a public-database mode
      that signs requests with the key pair instead of the browser-
      captured web auth token. Ctrl+C to exit.
      """

    internal let config: WebConfig

    /// Creates a new instance.
    public init(config: WebConfig) {
      self.config = config
    }

    /// Executes the command.
    public func execute() async throws {
      print("📍 Server URL: http://\(config.host):\(config.port)")
      if config.publicDatabaseAvailable {
        print("🌐 Public database (server-to-server) mode available.")
      }
      print("Press Ctrl+C to stop.")

      let tokenStore = WebAuthTokenStore()
      let server = WebServer(
        apiToken: config.apiToken,
        containerIdentifier: config.containerIdentifier,
        environment: config.environment,
        publicDatabaseAvailable: config.publicDatabaseAvailable,
        tokenStore: tokenStore,
        backendFactory: .live(
          apiToken: config.apiToken,
          containerIdentifier: config.containerIdentifier,
          environment: config.environment,
          serverToServer: try makeServerToServerCredentials()
        ),
        terminatesAfterAuth: false,
        resetAuth: false
      )
      let router = try server.makeRouter()

      let app = Application(
        router: router,
        configuration: .init(
          address: .hostname(config.host, port: config.port)
        )
      )

      do {
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
      } catch AsyncTimeoutError.cancelled {
        // Ctrl+C / SIGTERM is the intended exit path for the long-running
        // web server — `withSignalHandling` throws cancelled to unwind the
        // task group. Treat it as a clean shutdown.
        print("Server stopped.")
      }
    }

    /// Build server-to-server credentials when the user supplied key
    /// material. Returns `nil` (i.e. private-only mode) when nothing is
    /// provided; throws only if an incomplete combination is supplied so
    /// silent misconfigurations don't masquerade as "public unavailable".
    private func makeServerToServerCredentials() throws
      -> ServerToServerCredentials?
    {
      let hasKeyID = (config.keyID?.isEmpty == false)
      let hasInlineKey = (config.privateKey?.isEmpty == false)
      let hasKeyFile = (config.privateKeyFile?.isEmpty == false)

      guard hasKeyID || hasInlineKey || hasKeyFile else {
        return nil
      }
      guard let keyID = config.keyID, !keyID.isEmpty else {
        throw ConfigurationError.missingRequired(
          "key.id",
          suggestion: "Provide via --key-id or CLOUDKIT_KEY_ID environment variable"
        )
      }

      let material: PrivateKeyMaterial
      if let inline = config.privateKey, !inline.isEmpty {
        material = .raw(inline)
      } else if let path = config.privateKeyFile, !path.isEmpty {
        material = .file(path: path)
      } else {
        throw ConfigurationError.missingRequired(
          "private.key",
          suggestion: "Provide via --private-key or --private-key-path"
        )
      }

      return ServerToServerCredentials(keyID: keyID, privateKey: material)
    }

    private func openBrowserIfNeeded() async {
      guard config.openBrowser else {
        return
      }
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      BrowserOpener.openBrowser(
        url: "http://\(config.host):\(config.port)"
      )
    }
  }
#endif
