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
    /// Register the user-identity routes: `caller`, `discover`,
    /// `lookup/email`, and `lookup/id`. All operate on the public database
    /// with web-auth credentials, so none carry a `database` selector.
    internal func addUsersEndpoints(
      api: RouterGroup<BasicRequestContext>
    ) {
      addUsersCallerEndpoint(api: api)
      addUsersDiscoverEndpoint(api: api)
      addUsersLookupEmailEndpoint(api: api)
      addUsersLookupIdEndpoint(api: api)
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

    /// `POST /api/users/discover` — discover user identities by email.
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
          let users = try await backend.webDiscoverUsers(emails: body.emails)
          return try WebJSON.encoder().encode(
            WebResponse.Users(users: users)
          )
        }
      }
    }

    /// `POST /api/users/lookup/email` — look up user identities by email.
    private func addUsersLookupEmailEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("users/lookup/email") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.LookupUsersByEmail.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let users = try await backend.webLookupUsersByEmail(
            emails: body.emails
          )
          return try WebJSON.encoder().encode(
            WebResponse.Users(users: users)
          )
        }
      }
    }

    /// `POST /api/users/lookup/id` — look up user identities by user record
    /// name.
    private func addUsersLookupIdEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("users/lookup/id") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.LookupUsersByRecordName.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let users = try await backend.webLookupUsersByRecordName(
            recordNames: body.userRecordNames
          )
          return try WebJSON.encoder().encode(
            WebResponse.Users(users: users)
          )
        }
      }
    }
  }
#endif
