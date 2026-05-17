//
//  WebServer.swift
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
  internal import HTTPTypes
  internal import Hummingbird
  internal import Logging
  internal import MistKit

  /// Routing surface for the long-running `mistdemo web` command.
  ///
  /// Owns the index page, the CloudKit JS config endpoint, the auth-capture
  /// endpoint, and the CRUD record endpoints. Mode-toggle between MistKit
  /// (server-side, this server's routes) and CloudKit JS (browser-side,
  /// served from Apple's CDN) lives in the HTML; this server only
  /// implements the MistKit side.
  internal struct WebServer {
    /// JSON payload returned by `GET /api/config`, consumed by the
    /// browser-side script to configure both CloudKit JS and the mode-
    /// toggle's MistKit handlers.
    ///
    /// `publicDatabaseAvailable` lets the browser know whether the server
    /// holds server-to-server credentials and can therefore route MistKit
    /// requests against `.public`. CloudKit JS can always target the public
    /// database from the browser (it only needs the API token), so the flag
    /// gates only the MistKit + public profile.
    internal struct CloudKitClientConfig: Encodable {
      internal let apiToken: String
      internal let containerIdentifier: String
      internal let environment: String
      internal let publicDatabaseAvailable: Bool
    }

    internal let apiToken: String
    internal let containerIdentifier: String
    internal let environment: MistKit.Environment
    internal let publicDatabaseAvailable: Bool
    internal let tokenStore: WebAuthTokenStore
    internal let backendFactory: WebBackendFactory
    /// When `true`, `POST /api/authenticate` returns `205 Reset Content` to
    /// signal the browser that the server is about to shut down (auth-token
    /// flow). When `false`, returns `204 No Content` (web flow stays up).
    internal let terminatesAfterAuth: Bool

    internal static func jsonResponse(
      status: HTTPResponse.Status, bytes: Data
    ) -> Response {
      Response(
        status: status,
        headers: [.contentType: "application/json"],
        body: ResponseBody { writer in
          try await writer.write(ByteBuffer(bytes: bytes))
          try await writer.finish(nil)
        }
      )
    }

    /// Run a route operation that produces a success JSON body. Any thrown
    /// error becomes a `500` response with a JSON error payload so the UI
    /// can surface the failure without parsing transport-level errors.
    internal static func runOperation(
      _ operation: @Sendable () async throws -> Data
    ) async throws -> Response {
      do {
        let bytes = try await operation()
        return jsonResponse(status: .ok, bytes: bytes)
      } catch {
        let errorBody = try JSONEncoder().encode(
          WebResponse.Error(
            message: error.localizedDescription
          )
        )
        return jsonResponse(
          status: .internalServerError, bytes: errorBody
        )
      }
    }

    /// Build the router for this server.
    internal func makeRouter() throws -> Router<BasicRequestContext> {
      let router = Router(context: BasicRequestContext.self)
      router.middlewares.add(LogRequestsMiddleware(.info))

      addIndexEndpoint(router: router)

      let api = router.group("api")
        .add(middleware: LoopbackOnlyMiddleware<BasicRequestContext>())
      let configData = try JSONEncoder().encode(
        CloudKitClientConfig(
          apiToken: apiToken,
          containerIdentifier: containerIdentifier,
          environment: environment.rawValue,
          publicDatabaseAvailable: publicDatabaseAvailable
        )
      )
      addConfigEndpoint(api: api, configData: configData)
      addAuthEndpoint(api: api)
      addQueryEndpoint(api: api)
      addCreateEndpoint(api: api)
      addUpdateEndpoint(api: api)
      addDeleteEndpoint(api: api)

      return router
    }

    private func addIndexEndpoint(
      router: Router<BasicRequestContext>
    ) {
      let indexBytes = ByteBuffer(string: WebIndexHTML.content)
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
      api.get("config") { _, _ -> Response in
        Self.jsonResponse(status: .ok, bytes: configData)
      }
    }

    private func addAuthEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let successStatus: HTTPResponse.Status =
        terminatesAfterAuth ? .resetContent : .noContent
      api.post("authenticate") { request, context -> Response in
        let authRequest = try await request.decode(
          as: AuthRequest.self, context: context
        )
        await tokenStore.update(authRequest.sessionToken)
        return Response(status: successStatus)
      }
    }
  }
#endif
