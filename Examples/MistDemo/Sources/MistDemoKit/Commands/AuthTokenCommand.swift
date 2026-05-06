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
  import AsyncAlgorithms
  import Foundation
  import HTTPTypes
  import Hummingbird
  import Logging
  import MistKit

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
        --api-token <token>   CloudKit API token
        --port <port>         Server port (default: 8080)
        --host <host>         Server host (default: 127.0.0.1)
        --no-browser          Don't open browser automatically
      """

    internal let config: AuthTokenConfig

    /// Creates a new instance.
    public init(config: AuthTokenConfig) {
      self.config = config
    }

    // Exact-match host validation against an allowlist
    // after stripping any port.
    internal static func isLoopbackAuthority(
      _ authority: String
    ) -> Bool {
      let host: String
      if authority.hasPrefix("["),
        let endBracket = authority.firstIndex(of: "]")
      {
        host = String(
          authority[authority.startIndex...endBracket]
        )
        let afterBracket =
          authority[authority.index(after: endBracket)...]
        if !afterBracket.isEmpty,
          !afterBracket.hasPrefix(":")
        {
          return false
        }
      } else {
        host = String(
          authority.split(separator: ":").first
            ?? Substring(authority)
        )
      }
      return ["localhost", "127.0.0.1", "[::1]"]
        .contains(host)
    }

    /// Executes the command.
    public func execute() async throws {
      print("📍 Server URL: http://\(config.host):\(config.port)")

      let tokenChannel = AsyncChannel<String>()
      let responseCompleteChannel = AsyncChannel<Void>()

      let router = try buildRouter(
        tokenChannel: tokenChannel,
        responseCompleteChannel: responseCompleteChannel
      )

      let app = Application(
        router: router,
        configuration: .init(
          address: .hostname(
            config.host, port: config.port
          )
        )
      )

      let serverTask = Task { try await app.runService() }

      openBrowserIfNeeded()
      let token = try await waitForToken(
        channel: tokenChannel, serverTask: serverTask
      )

      var responseIterator =
        responseCompleteChannel.makeAsyncIterator()
      _ = await responseIterator.next()

      serverTask.cancel()
      try await Task.sleep(nanoseconds: 500_000_000)
      print(token)
    }

    private func openBrowserIfNeeded() {
      if !config.noBrowser {
        Task {
          try await Task.sleep(nanoseconds: 1_000_000_000)
          BrowserOpener.openBrowser(
            url: "http://\(config.host):\(config.port)"
          )
        }
      }
    }

    private func waitForToken(
      channel: AsyncChannel<String>,
      serverTask: Task<Void, any Error>
    ) async throws -> String {
      do {
        return try await withTimeoutAndSignals(
          seconds: 300
        ) {
          var iterator = channel.makeAsyncIterator()
          guard let value = await iterator.next() else {
            throw AuthTokenError.serverError(
              "Token channel closed"
            )
          }
          return value
        }
      } catch let error as AsyncTimeoutError {
        serverTask.cancel()
        throw AuthTokenError.timeout(
          error.localizedDescription
        )
      } catch {
        serverTask.cancel()
        throw error
      }
    }
  }
#endif
