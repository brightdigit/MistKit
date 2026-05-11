//
//  AuthTokenServerTests.swift
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
  import AsyncAlgorithms
  import Foundation
  import HTTPTypes
  import Hummingbird
  import HummingbirdTesting
  import Testing

  @testable import MistDemoKit

  @Suite("AuthTokenServer Tests")
  internal struct AuthTokenServerTests {
    private struct Fixture {
      let server: AuthTokenServer
      let tokenChannel: AsyncChannel<String>
      let responseChannel: AsyncChannel<Void>
    }

    private struct ConfigPayload: Decodable {
      let apiToken: String
      let containerIdentifier: String
    }

    private struct AuthRequestPayload: Encodable {
      let sessionToken: String
      let userRecordName: String
    }

    private struct AuthResponsePayload: Decodable {
      let userRecordName: String
      let message: String
    }

    private static func makeFixture() -> Fixture {
      let tokenChannel = AsyncChannel<String>()
      let responseChannel = AsyncChannel<Void>()
      let server = AuthTokenServer(
        apiToken: "test-api-token",
        containerIdentifier: "iCloud.test.container",
        tokenChannel: tokenChannel,
        responseCompleteChannel: responseChannel
      )
      return Fixture(
        server: server,
        tokenChannel: tokenChannel,
        responseChannel: responseChannel
      )
    }

    @Test("GET / returns HTML index")
    internal func indexReturnsHtml() async throws {
      let fixture = Self.makeFixture()
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(uri: "/", method: .get) { response in
          #expect(response.status == .ok)
          #expect(
            response.headers[.contentType]
              == "text/html; charset=utf-8"
          )
          let body = String(buffer: response.body)
          #expect(body.contains("<html"))
        }
      }
    }

    @Test("GET /index.html returns the same HTML index")
    internal func indexHtmlReturnsHtml() async throws {
      let fixture = Self.makeFixture()
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(uri: "/index.html", method: .get) {
          response in
          #expect(response.status == .ok)
          #expect(
            response.headers[.contentType]
              == "text/html; charset=utf-8"
          )
        }
      }
    }

    @Test(
      "GET /api/config returns the CloudKit client config as JSON"
    )
    internal func configReturnsJson() async throws {
      let fixture = Self.makeFixture()
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(uri: "/api/config", method: .get) {
          response in
          #expect(response.status == .ok)
          #expect(
            response.headers[.contentType] == "application/json"
          )

          let payload = try JSONDecoder().decode(
            ConfigPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.apiToken == "test-api-token")
          #expect(
            payload.containerIdentifier == "iCloud.test.container"
          )
        }
      }
    }

    @Test(
      "POST /api/authenticate forwards the session token to the channel"
    )
    internal func authenticateForwardsToken() async throws {
      let fixture = Self.makeFixture()
      let app = Application(router: try fixture.server.makeRouter())

      let tokenChannel = fixture.tokenChannel
      let responseChannel = fixture.responseChannel

      let receivedToken = Task { () -> String? in
        var iterator = tokenChannel.makeAsyncIterator()
        return await iterator.next()
      }
      let receivedComplete = Task {
        var iterator = responseChannel.makeAsyncIterator()
        _ = await iterator.next()
      }

      let requestPayload = AuthRequestPayload(
        sessionToken: "session-tok-xyz",
        userRecordName: "_abc123"
      )
      let body = try JSONEncoder().encode(requestPayload)

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/authenticate",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(bytes: body)
        ) { response in
          #expect(response.status == .ok)
          #expect(
            response.headers[.contentType] == "application/json"
          )
          let decoded = try JSONDecoder().decode(
            AuthResponsePayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(decoded.userRecordName == "_abc123")
          #expect(decoded.message == "Authentication successful!")
        }
      }

      #expect(await receivedToken.value == "session-tok-xyz")
      await receivedComplete.value
    }
  }
#endif
