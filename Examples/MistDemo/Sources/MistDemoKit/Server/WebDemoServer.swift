//
//  WebDemoServer.swift
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
  internal struct WebDemoServer {
    /// JSON payload returned by `GET /api/config`, consumed by the
    /// browser-side script to configure both CloudKit JS and the mode-
    /// toggle's MistKit handlers.
    internal struct CloudKitClientConfig: Encodable {
      internal let apiToken: String
      internal let containerIdentifier: String
      internal let environment: String
    }

    internal let apiToken: String
    internal let containerIdentifier: String
    internal let environment: MistKit.Environment
    internal let tokenStore: WebAuthTokenStore
    internal let backendFactory: WebDemoBackendFactory
    /// When `true`, `POST /api/authenticate` returns `205 Reset Content` to
    /// signal the browser that the server is about to shut down (auth-token
    /// flow). When `false`, returns `204 No Content` (web flow stays up).
    internal let terminatesAfterAuth: Bool

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
          environment: environment.rawValue
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
      let indexBytes = ByteBuffer(string: WebDemoIndexHTML.content)
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

    // MARK: - CRUD

    private func addQueryEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("records/query") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebDemoRequests.QueryRequest.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let records = try await backend.webDemoQuery(
            recordType: body.recordType, limit: body.limit
          )
          return try JSONEncoder().encode(
            WebDemoRequests.RecordsResponse(records: records)
          )
        }
      }
    }

    private func addCreateEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("records/create") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebDemoRequests.CreateRequest.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let record = try await backend.webDemoCreate(
            recordType: body.recordType,
            fields: WebDemoRequests.stringFields(body.fields)
          )
          return try JSONEncoder().encode(
            WebDemoRequests.RecordsResponse(records: [record])
          )
        }
      }
    }

    private func addUpdateEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("records/update") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebDemoRequests.UpdateRequest.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let record = try await backend.webDemoUpdate(
            recordType: body.recordType,
            recordName: body.recordName,
            fields: WebDemoRequests.stringFields(body.fields)
          )
          return try JSONEncoder().encode(
            WebDemoRequests.RecordsResponse(records: [record])
          )
        }
      }
    }

    private func addDeleteEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("records/delete") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebDemoRequests.DeleteRequest.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          try await backend.webDemoDelete(
            recordType: body.recordType,
            recordName: body.recordName
          )
          return try JSONEncoder().encode(
            WebDemoRequests.DeleteResponse(
              recordName: body.recordName, deleted: true
            )
          )
        }
      }
    }

    // MARK: - Helpers

    private static func jsonResponse(
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
    private static func runOperation(
      _ operation: @Sendable () async throws -> Data
    ) async throws -> Response {
      do {
        let bytes = try await operation()
        return jsonResponse(status: .ok, bytes: bytes)
      } catch {
        let errorBody = try JSONEncoder().encode(
          WebDemoRequests.ErrorResponse(
            message: error.localizedDescription
          )
        )
        return jsonResponse(
          status: .internalServerError, bytes: errorBody
        )
      }
    }
  }
#endif
