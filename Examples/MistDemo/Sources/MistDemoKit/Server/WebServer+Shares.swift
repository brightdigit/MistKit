//
//  WebServer+Shares.swift
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
    /// `POST /api/records/resolve` and `POST /api/records/accept` — resolve
    /// or accept shares identified by short GUID. Both operate on the
    /// public database with web-auth credentials, so neither carries a
    /// `database` selector.
    internal func addSharesEndpoints(
      api: RouterGroup<BasicRequestContext>
    ) {
      addRecordsResolveEndpoint(api: api)
      addRecordsAcceptEndpoint(api: api)
    }

    /// `POST /api/records/resolve`.
    private func addRecordsResolveEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("records/resolve") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.ResolveOrAcceptShares.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let results = try await backend.webResolveShares(
            shortGUIDs: body.shortGUIDs,
            fetchRootRecord: body.fetchRootRecord,
            fields: body.fields
          )
          return try WebJSON.encoder().encode(
            WebResponse.Shares(results: results)
          )
        }
      }
    }

    /// `POST /api/records/accept`.
    private func addRecordsAcceptEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("records/accept") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.ResolveOrAcceptShares.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let results = try await backend.webAcceptShares(
            shortGUIDs: body.shortGUIDs,
            fetchRootRecord: body.fetchRootRecord,
            fields: body.fields
          )
          return try WebJSON.encoder().encode(
            WebResponse.Shares(results: results)
          )
        }
      }
    }
  }
#endif
