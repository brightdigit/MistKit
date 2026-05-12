//
//  WebServerTests+CRUD.swift
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

  extension WebServerTests {
    private struct RecordsPayload: Decodable {
      let records: [RecordInfo]
    }

    private struct DeletePayload: Decodable {
      let recordName: String
      let deleted: Bool
    }

    @Test("POST /api/records/query forwards to the backend")
    internal func queryForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = #"{"recordType":"Note","limit":10}"#

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/query",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            RecordsPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.records.count == 1)
          #expect(payload.records.first?.recordType == "Note")
        }
      }

      let captured = await fixture.backend.lastQuery
      #expect(captured?.recordType == "Note")
      #expect(captured?.limit == 10)
    }

    @Test("POST /api/records/create forwards fields to the backend")
    internal func createForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = #"{"recordType":"Note","fields":{"title":"Hi"}}"#

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/create",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastCreate
      #expect(captured?.recordType == "Note")
      #expect(captured?.fields["title"] == "Hi")
    }

    @Test("POST /api/records/update forwards record name + fields")
    internal func updateForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = """
        {"recordType":"Note","recordName":"abc","fields":{"title":"Up"}}
        """

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/update",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastUpdate
      #expect(captured?.recordType == "Note")
      #expect(captured?.recordName == "abc")
      #expect(captured?.fields["title"] == "Up")
    }

    @Test("POST /api/records/delete forwards record name")
    internal func deleteForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = #"{"recordType":"Note","recordName":"abc"}"#

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/delete",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            DeletePayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.recordName == "abc")
          #expect(payload.deleted)
        }
      }

      let captured = await fixture.backend.lastDelete
      #expect(captured?.recordType == "Note")
      #expect(captured?.recordName == "abc")
    }

    @Test("Backend errors surface as 500 with a JSON message body")
    internal func backendErrorIsSurfaced() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      await fixture.backend.failNext(message: "boom")
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/query",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"recordType":"Note"}"#)
        ) { response in
          #expect(response.status == .internalServerError)
          let body = String(buffer: response.body)
          #expect(body.contains("boom"))
        }
      }
    }
  }
#endif
