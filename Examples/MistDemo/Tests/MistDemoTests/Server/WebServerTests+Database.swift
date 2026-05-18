//
//  WebServerTests+Database.swift
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
    @Test("CRUD requests omit `database` → backend receives .private")
    internal func crudDefaultsDatabaseToPrivate() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/query",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"recordType":"Note"}"#)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastQuery
      #expect(captured?.database == .private)
    }

    @Test(
      "CRUD requests forward `database`: public → backend",
      arguments: [
        ("/api/records/query", #"{"recordType":"Note","database":"public"}"#),
        (
          "/api/records/create",
          #"{"recordType":"Note","database":"public","fields":{"title":"X"}}"#
        ),
        (
          "/api/records/update",
          #"""
          {"recordType":"Note","database":"public",\#
          "recordName":"r1","fields":{"title":"X"}}
          """#
        ),
        (
          "/api/records/delete",
          #"{"recordType":"Note","database":"public","recordName":"r1"}"#
        ),
      ]
    )
    internal func crudForwardsPublicDatabase(
      path: String,
      jsonBody: String
    ) async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: path,
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured: MistKit.Database?
      switch path {
      case "/api/records/query":
        captured = await fixture.backend.lastQuery?.database
      case "/api/records/create":
        captured = await fixture.backend.lastCreate?.database
      case "/api/records/update":
        captured = await fixture.backend.lastUpdate?.database
      case "/api/records/delete":
        captured = await fixture.backend.lastDelete?.database
      default:
        captured = nil
      }
      #expect(captured == .public(.prefers(.serverToServer)))
    }

    @Test("CRUD requests with an unknown `database` value return 400")
    internal func crudRejectsUnknownDatabase() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/query",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"recordType":"Note","database":"bogus"}"#)
        ) { response in
          #expect(response.status == .badRequest)
        }
      }
    }
  }
#endif
