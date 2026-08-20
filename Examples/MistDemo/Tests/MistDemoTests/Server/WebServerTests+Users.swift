//
//  WebServerTests+Users.swift
//  MistDemoTests
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
  internal import HummingbirdTesting
  internal import MistKit
  internal import Testing

  @testable import MistDemoKit

  extension WebServerTests {
    // UserInfo is Encodable-only, so decode the response shape locally.
    private struct CallerPayload: Decodable {
      struct User: Decodable {
        let userRecordName: String
        let emailAddress: String?
      }
      let user: User
    }

    private struct UsersPayload: Decodable {
      let users: [UserIdentity]
    }

    @Test("GET /api/users/caller forwards to the backend")
    internal func usersCallerForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/users/caller",
          method: .get
        ) { response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            CallerPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.user.userRecordName == "stub-caller")
          #expect(payload.user.emailAddress == "stub@example.com")
        }
      }

      let didFetch = await fixture.backend.didFetchCaller
      #expect(didFetch)
    }

    @Test("GET /api/users/caller returns 401 without a captured auth token")
    internal func usersCallerRequiresAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/users/caller",
          method: .get
        ) { response in
          #expect(response.status == .unauthorized)
        }
      }
    }

    @Test(
      """
      POST /api/users/discover forwards emails, phone numbers, \
      and record names to the backend
      """
    )
    internal func usersDiscoverForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = """
        {"emails":["a@example.com","b@example.com"],\
        "phoneNumbers":["+15555550123"],\
        "userRecordNames":["_user-1"]}
        """

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/users/discover",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            UsersPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.users.count == 4)
        }
      }

      let captured = await fixture.backend.lastDiscoverUsers
      #expect(captured?.emails == ["a@example.com", "b@example.com"])
      #expect(captured?.phoneNumbers == ["+15555550123"])
      #expect(captured?.userRecordNames == ["_user-1"])
    }

    @Test("POST /api/users/discover returns 401 without a captured auth token")
    internal func usersDiscoverRequiresAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/users/discover",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"emails":["a@example.com"]}"#)
        ) { response in
          #expect(response.status == .unauthorized)
        }
      }
    }
  }
#endif
