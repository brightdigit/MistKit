//
//  WebServer+Subscriptions.swift
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

  extension WebServer {
    /// `GET /api/subscriptions`, `GET /api/subscriptions/:id`, and
    /// `POST /api/subscriptions/modify` — the MistKit-mode counterparts to the
    /// CloudKit JS subscription primitives. These run against `.private` (the
    /// browser panel doesn't carry a database picker for subscriptions).
    internal func addSubscriptionEndpoints(
      api: RouterGroup<BasicRequestContext>
    ) {
      addSubscriptionReadEndpoints(api: api)
      addSubscriptionModifyEndpoint(api: api)
    }

    private func addSubscriptionReadEndpoints(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory

      api.get("subscriptions") { _, _ -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let subscriptions = try await backend.webListSubscriptions(
            database: WebRequests.defaultDatabase
          )
          return try WebJSON.encoder().encode(
            WebResponse.Subscriptions(subscriptions: subscriptions)
          )
        }
      }

      api.get("subscriptions/:id") { _, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        guard let id = context.parameters.get("id") else {
          return Response(status: .badRequest)
        }
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let subscriptions = try await backend.webLookupSubscriptions(
            ids: [id],
            database: WebRequests.defaultDatabase
          )
          return try WebJSON.encoder().encode(
            WebResponse.Subscriptions(subscriptions: subscriptions)
          )
        }
      }
    }

    private func addSubscriptionModifyEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory

      api.post("subscriptions/modify") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.ModifySubscriptions.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let subscriptions = try await backend.webModifySubscriptions(
            operations: body.operations(),
            database: body.database
          )
          return try WebJSON.encoder().encode(
            WebResponse.Subscriptions(subscriptions: subscriptions)
          )
        }
      }
    }
  }
#endif
