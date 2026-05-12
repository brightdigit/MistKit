//
//  WebServerTests.swift
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
  import Foundation
  import HTTPTypes
  import Hummingbird
  import HummingbirdTesting
  import MistKit
  import Testing

  @testable import MistDemoKit

  @Suite("WebServer Tests")
  internal struct WebServerTests {
    internal struct Fixture {
      internal let server: WebServer
      internal let tokenStore: WebAuthTokenStore
      internal let backend: MockBackend
    }

    private struct ConfigPayload: Decodable {
      let apiToken: String
      let containerIdentifier: String
      let environment: String
    }

    internal static func makeFixture(
      authenticated: Bool = false,
      terminatesAfterAuth: Bool = false
    ) -> Fixture {
      let backend = MockBackend()
      let store = WebAuthTokenStore(
        token: authenticated ? "captured-token" : nil
      )
      let factory = WebBackendFactory { _ in backend }
      let server = WebServer(
        apiToken: "test-api-token",
        containerIdentifier: "iCloud.test.container",
        environment: .development,
        tokenStore: store,
        backendFactory: factory,
        terminatesAfterAuth: terminatesAfterAuth
      )
      return Fixture(server: server, tokenStore: store, backend: backend)
    }

    @Test("GET /api/config returns container + environment")
    internal func configIncludesEnvironment() async throws {
      let fixture = Self.makeFixture()
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(uri: "/api/config", method: .get) {
          response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            ConfigPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.apiToken == "test-api-token")
          #expect(payload.containerIdentifier == "iCloud.test.container")
          #expect(payload.environment == "development")
        }
      }
    }

    @Test("POST /api/authenticate captures the token and returns 204")
    internal func authenticateCapturesToken() async throws {
      let fixture = Self.makeFixture()
      let app = Application(router: try fixture.server.makeRouter())

      let body = try JSONEncoder().encode([
        "sessionToken": "session-xyz",
        "userRecordName": "_abc",
      ])

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/authenticate",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(bytes: body)
        ) { response in
          #expect(response.status == .noContent)
          #expect(response.body.readableBytes == 0)
        }
      }

      let stored = await fixture.tokenStore.currentToken
      #expect(stored == "session-xyz")
    }

    @Test("POST /api/authenticate returns 205 when terminatesAfterAuth")
    internal func authenticateReturns205WhenTerminating() async throws {
      let fixture = Self.makeFixture(terminatesAfterAuth: true)
      let app = Application(router: try fixture.server.makeRouter())

      let body = try JSONEncoder().encode([
        "sessionToken": "session-xyz",
        "userRecordName": "_abc",
      ])

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/authenticate",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(bytes: body)
        ) { response in
          #expect(response.status == .resetContent)
          #expect(response.body.readableBytes == 0)
        }
      }

      let stored = await fixture.tokenStore.currentToken
      #expect(stored == "session-xyz")
    }

    @Test("tokenUpdates yields the captured token after authenticate")
    internal func authenticateYieldsToTokenUpdates() async throws {
      let fixture = Self.makeFixture()
      let app = Application(router: try fixture.server.makeRouter())

      let body = try JSONEncoder().encode([
        "sessionToken": "session-xyz",
        "userRecordName": "_abc",
      ])

      try await app.test(.router) { client in
        async let firstToken: String? = {
          var iterator = fixture.tokenStore.tokenUpdates.makeAsyncIterator()
          return await iterator.next()
        }()

        try await client.execute(
          uri: "/api/authenticate",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(bytes: body)
        ) { response in
          #expect(response.status == .noContent)
        }

        #expect(await firstToken == "session-xyz")
      }
    }

    @Test(
      "CRUD routes return 401 when no auth token has been captured",
      arguments: [
        "/api/records/query",
        "/api/records/create",
        "/api/records/update",
        "/api/records/delete",
      ]
    )
    internal func crudRejectsPreAuth(path: String) async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: path,
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: "{}")
        ) { response in
          #expect(response.status == .unauthorized)
        }
      }
    }
  }
#endif
