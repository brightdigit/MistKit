//
//  WebServerTests+Subscriptions.swift
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
    private struct SubscriptionsPayload: Decodable {
      struct Sub: Decodable {
        let subscriptionID: String
        let subscriptionType: String
      }
      let subscriptions: [Sub]
    }

    @Test("GET /api/subscriptions lists subscriptions via the backend")
    internal func listSubscriptions() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(uri: "/api/subscriptions", method: .get) {
          response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            SubscriptionsPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.subscriptions.first?.subscriptionID == "stub-sub")
        }
      }

      let listed = await fixture.backend.didListSubscriptions
      #expect(listed)
    }

    @Test("GET /api/subscriptions/:id forwards the id to lookup")
    internal func lookupSubscription() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(uri: "/api/subscriptions/stub-sub", method: .get) {
          response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastLookupSubscriptions
      #expect(captured?.ids == ["stub-sub"])
    }

    @Test("POST /api/subscriptions/modify forwards a bare create subscription")
    internal func modifyCreateForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody =
        #"{"subscriptionType":"query","subscriptionID":"arts","firesOn":["#
        + #""create","update"],"query":{"recordType":"Article"}}"#

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/subscriptions/modify",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastModifySubscriptions
      #expect(captured?.operations.count == 1)
      if case .create(let info) = captured?.operations.first {
        #expect(info.subscriptionID == "arts")
        #expect(info.subscriptionType == .query)
        #expect(info.query?.recordType == "Article")
        #expect(info.firesOn == [.create, .update])
      } else {
        Issue.record("Expected a create operation")
      }
    }

    @Test("POST /api/subscriptions/modify forwards a delete batch")
    internal func modifyDeleteForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = #"{"delete":[{"subscriptionID":"arts"}]}"#

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/subscriptions/modify",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastModifySubscriptions
      #expect(captured?.operations.count == 1)
      if case .delete(let id) = captured?.operations.first {
        #expect(id == "arts")
      } else {
        Issue.record("Expected a delete operation")
      }
    }

    @Test("subscription routes return 401 without a captured auth token")
    internal func subscriptionsRequireAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(uri: "/api/subscriptions", method: .get) {
          response in
          #expect(response.status == .unauthorized)
        }
      }
    }
  }
#endif
