// swiftlint:disable file_length
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
  public import Foundation
  import HTTPTypes
  import Hummingbird
  import Logging
  import MistKit

  /// Authentication-related errors for auth-token command.
  public enum AuthTokenError: Error, LocalizedError {
    case timeout(String)
    case missingResource(String)
    case serverError(String)

    /// A localized description of the error.
    public var errorDescription: String? {
      switch self {
      case .timeout(let message):
        return "Authentication timeout: \(message)"
      case .missingResource(let resource):
        return "Missing resource: \(resource)"
      case .serverError(let message):
        return "Server error: \(message)"
      }
    }
  }

  /// Command to obtain web authentication token via browser flow.
  public struct AuthTokenCommand: MistDemoCommand { // swiftlint:disable:this one_declaration_per_file
    /// The configuration type.
    public typealias Config = AuthTokenConfig

    private struct CloudKitClientConfig: Encodable {
      let apiToken: String
      let containerIdentifier: String
    }

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

    private let config: AuthTokenConfig

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
      serverTask: Task<Void, Error>
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

    private func buildRouter(
      tokenChannel: AsyncChannel<String>,
      responseCompleteChannel: AsyncChannel<Void>
    ) throws -> Router<BasicRequestContext> {
      let router = Router(context: BasicRequestContext.self)
      router.middlewares.add(LogRequestsMiddleware(.info))

      let indexBytes = ByteBuffer(
        string: AuthTokenIndexHTML.content
      )
      let indexResponseBuilder: @Sendable () -> Response = {
        Response(
          status: .ok,
          headers: [
            .contentType: "text/html; charset=utf-8"
          ],
          body: ResponseBody { writer in
            try await writer.write(indexBytes)
            try await writer.finish(nil)
          }
        )
      }
      router.get("/") { _, _ -> Response in
        indexResponseBuilder()
      }
      router.get("/index.html") { _, _ -> Response in
        indexResponseBuilder()
      }

      let api = router.group("api")

      let configPayload = CloudKitClientConfig(
        apiToken: config.apiToken,
        containerIdentifier: config.containerIdentifier
      )
      let configData = try JSONEncoder().encode(
        configPayload
      )

      addConfigEndpoint(
        api: api, configData: configData
      )
      addAuthEndpoint(
        api: api,
        tokenChannel: tokenChannel,
        responseCompleteChannel: responseCompleteChannel
      )

      return router
    }

    private func addConfigEndpoint(
      api: RouterGroup<BasicRequestContext>,
      configData: Data
    ) {
      api.get("config") { request, _ -> Response in
        let authority = request.head.authority ?? ""
        guard Self.isLoopbackAuthority(authority) else {
          return Response(status: .forbidden)
        }
        return Response(
          status: .ok,
          headers: [.contentType: "application/json"],
          body: ResponseBody { writer in
            try await writer.write(
              ByteBuffer(bytes: configData)
            )
            try await writer.finish(nil)
          }
        )
      }
    }

    private func addAuthEndpoint(
      api: RouterGroup<BasicRequestContext>,
      tokenChannel: AsyncChannel<String>,
      responseCompleteChannel: AsyncChannel<Void>
    ) {
      api.post("authenticate") {
        request, context -> Response in
        let authRequest = try await request.decode(
          as: AuthRequest.self, context: context
        )
        await tokenChannel.send(authRequest.sessionToken)

        let response = AuthResponse(
          userRecordName: authRequest.userRecordName,
          cloudKitData: .init(
            user: nil, zones: [], error: nil
          ),
          message: "Authentication successful!"
        )

        let jsonData = try JSONEncoder().encode(response)

        Task {
          try await Task.sleep(nanoseconds: 200_000_000)
          await responseCompleteChannel.send(())
        }

        return Response(
          status: .ok,
          headers: [.contentType: "application/json"],
          body: ResponseBody { writer in
            try await writer.write(
              ByteBuffer(bytes: jsonData)
            )
            try await writer.finish(nil)
          }
        )
      }
    }
  }
#endif
