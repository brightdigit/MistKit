//
//  AuthTokenServer.swift
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
  internal import AsyncAlgorithms
  internal import Foundation
  internal import HTTPTypes
  internal import Hummingbird
  internal import Logging

  /// Routing surface for the auth-token loopback flow.
  ///
  /// Owns the index, config, and authentication endpoints used by the
  /// browser-side script during a CloudKit web-auth round trip. The owning
  /// command (`AuthTokenCommand`) provides credentials and the rendezvous
  /// channels and is responsible for the `Application` lifecycle; this type
  /// only knows how to assemble a `Router`.
  internal struct AuthTokenServer {
    /// JSON payload returned from `GET /api/config`, consumed by the
    /// browser-side script to configure CloudKit JS.
    internal struct CloudKitClientConfig: Encodable {
      internal let apiToken: String
      internal let containerIdentifier: String
    }

    internal let apiToken: String
    internal let containerIdentifier: String
    internal let tokenChannel: AsyncChannel<String>
    internal let responseCompleteChannel: AsyncChannel<Void>

    /// Build the router for this server.
    internal func makeRouter() throws -> Router<BasicRequestContext> {
      let router = Router(context: BasicRequestContext.self)
      router.middlewares.add(LogRequestsMiddleware(.info))

      addIndexEndpoint(router: router)

      let api = router.group("api")
      let configData = try JSONEncoder().encode(
        CloudKitClientConfig(
          apiToken: apiToken,
          containerIdentifier: containerIdentifier
        )
      )
      addConfigEndpoint(api: api, configData: configData)
      addAuthEndpoint(api: api)

      return router
    }

    private func addIndexEndpoint(
      router: Router<BasicRequestContext>
    ) {
      let indexBytes = ByteBuffer(string: AuthTokenIndexHTML.content)
      let indexResponseBuilder: @Sendable () -> Response = {
        Response(
          status: .ok,
          headers: [.contentType: "text/html; charset=utf-8"],
          body: ResponseBody { writer in
            try await writer.write(indexBytes)
            try await writer.finish(nil)
          }
        )
      }
      router.get("/") { _, _ -> Response in indexResponseBuilder() }
      router.get("/index.html") { _, _ -> Response in
        indexResponseBuilder()
      }
    }

    private func addConfigEndpoint(
      api: RouterGroup<BasicRequestContext>,
      configData: Data
    ) {
      api.get("config") { request, _ -> Response in
        let authority = request.head.authority ?? ""
        guard LoopbackAuthority.isLoopback(authority) else {
          return Response(status: .forbidden)
        }
        return Response(
          status: .ok,
          headers: [.contentType: "application/json"],
          body: ResponseBody { writer in
            try await writer.write(ByteBuffer(bytes: configData))
            try await writer.finish(nil)
          }
        )
      }
    }

    private func addAuthEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenChannel = self.tokenChannel
      let responseCompleteChannel = self.responseCompleteChannel
      api.post("authenticate") { request, context -> Response in
        let authRequest = try await request.decode(
          as: AuthRequest.self, context: context
        )
        await tokenChannel.send(authRequest.sessionToken)

        let response = AuthResponse(
          userRecordName: authRequest.userRecordName,
          cloudKitData: .init(user: nil, zones: [], error: nil),
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
            try await writer.write(ByteBuffer(bytes: jsonData))
            try await writer.finish(nil)
          }
        )
      }
    }
  }
#endif
