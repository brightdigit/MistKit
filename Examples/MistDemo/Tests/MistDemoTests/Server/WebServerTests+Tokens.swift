//
//  WebServerTests+Tokens.swift
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
    private struct TokenPayload: Decodable {
      let apnsEnvironment: String
      let apnsToken: String
      let webcourierURL: URL
    }

    @Test("POST /api/tokens mints a token via the backend")
    internal func createToken() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = #"{"apnsEnvironment":"production"}"#

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/tokens",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            TokenPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.apnsEnvironment == "production")
          #expect(payload.apnsToken == "stub-apns")
          #expect(payload.webcourierURL == URL(string: "https://stub.example/webcourier"))
        }
      }

      let captured = await fixture.backend.lastCreateToken
      #expect(captured?.environment == .production)
    }

    @Test("POST /api/tokens/register forwards the token + environment to the backend")
    internal func registerToken() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = #"{"apnsToken":"0a1b2c3d","apnsEnvironment":"production"}"#

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/tokens/register",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastRegisterToken
      #expect(captured?.apnsToken == "0a1b2c3d")
      #expect(captured?.environment == .production)
    }

    @Test("token routes return 401 without a captured auth token")
    internal func tokensRequireAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/tokens",
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
