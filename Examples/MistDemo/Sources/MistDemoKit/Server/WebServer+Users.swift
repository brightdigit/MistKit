//
//  WebServer+Users.swift
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
    /// Register the user-identity routes: `caller` and `discover`. Both
    /// operate on the public database with web-auth credentials, so neither
    /// carries a `database` selector. The deprecated `lookup/email` and
    /// `lookup/id` primitives are intentionally not exposed — `discover` is
    /// Apple's supported replacement and handles email, phone-number, and
    /// record-name lookups.
    internal func addUsersEndpoints(
      api: RouterGroup<BasicRequestContext>
    ) {
      addUsersCallerEndpoint(api: api)
      addUsersDiscoverEndpoint(api: api)
    }

    /// `GET /api/users/caller` — the calling user's identity.
    private func addUsersCallerEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.get("users/caller") { _, _ -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let user = try await backend.webFetchCaller()
          return try WebJSON.encoder().encode(
            WebResponse.Caller(user: user)
          )
        }
      }
    }

    /// `POST /api/users/discover` — discover user identities by email
    /// address, phone number, and/or user record name.
    private func addUsersDiscoverEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("users/discover") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.DiscoverUsers.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let users = try await backend.webDiscoverUsers(
            emails: body.emails,
            phoneNumbers: body.phoneNumbers,
            userRecordNames: body.userRecordNames
          )
          return try WebJSON.encoder().encode(
            WebResponse.Users(users: users)
          )
        }
      }
    }
  }
#endif
