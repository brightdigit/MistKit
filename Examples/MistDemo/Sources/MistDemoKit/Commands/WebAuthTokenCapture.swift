//
//  WebAuthTokenCapture.swift
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

  /// Shared one-shot browser capture used by `auth-token` and `auth-tokens`.
  internal enum WebAuthTokenCapture {
    /// Boots a terminate-after-auth Hummingbird server, optionally opens the
    /// browser, and returns the first token written to the store (300s timeout).
    internal static func capture(
      apiToken: String,
      containerIdentifier: String,
      environment: MistKit.Environment,
      host: String,
      port: Int,
      openBrowser: Bool,
      resetAuth: Bool
    ) async throws -> String {
      let tokenStore = WebAuthTokenStore()
      let server = WebServer(
        apiToken: apiToken,
        containerIdentifier: containerIdentifier,
        environment: environment,
        publicDatabaseAvailable: false,
        tokenStore: tokenStore,
        backendFactory: .live(
          apiToken: apiToken,
          containerIdentifier: containerIdentifier,
          environment: environment
        ),
        terminatesAfterAuth: true,
        resetAuth: resetAuth
      )
      let app = Application(
        router: try server.makeRouter(),
        configuration: .init(address: .hostname(host, port: port))
      )

      do {
        return try await withTimeoutAndSignals(seconds: 300) {
          try await withThrowingTaskGroup(of: String?.self) { group in
            group.addTask {
              try await app.runService()
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
  }
#endif
