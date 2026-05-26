//
//  WebServerTests+Records.swift
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
    private struct RecordsPayload: Decodable {
      let records: [RecordInfo]
    }

    private struct RecordChangesPayload: Decodable {
      let records: [RecordInfo]
      let syncToken: String?
      let moreComing: Bool
    }

    @Test("POST /api/records/lookup forwards record names to the backend")
    internal func recordsLookupForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = #"{"database":"private","recordNames":["note-1","note-2"]}"#

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/lookup",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            RecordsPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.records.map(\.recordName) == ["note-1", "note-2"])
        }
      }

      let captured = await fixture.backend.lastLookupRecords
      #expect(captured?.recordNames == ["note-1", "note-2"])
      #expect(captured?.database == .private)
    }

    @Test("POST /api/records/lookup returns 401 without a captured auth token")
    internal func recordsLookupRequiresAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/lookup",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"recordNames":["note-1"]}"#)
        ) { response in
          #expect(response.status == .unauthorized)
        }
      }
    }

    @Test("POST /api/records/lookup surfaces a backend failure as an error")
    internal func recordsLookupPropagatesBackendError() async throws {
      // `webLookupRecords` is all-or-nothing: any per-record failure (e.g.
      // CloudKit NOT_FOUND) throws rather than returning partial rows, so a
      // backend error must surface as 500 — not a 200 with fewer records.
      let fixture = Self.makeFixture(authenticated: true)
      await fixture.backend.failNext(message: "record not found")
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/lookup",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"recordNames":["missing"]}"#)
        ) { response in
          #expect(response.status == .internalServerError)
        }
      }
    }

    @Test("POST /api/records/changes forwards zone and sync token to backend")
    internal func recordsChangesForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = """
        {"database":"private","zoneName":"Notes","syncToken":"token-xyz"}
        """

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/changes",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            RecordChangesPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.syncToken == "stub-record-sync-token")
          #expect(payload.moreComing == false)
          #expect(payload.records.first?.recordName == "changed-1")
        }
      }

      let captured = await fixture.backend.lastRecordChanges
      #expect(captured?.zoneName == "Notes")
      #expect(captured?.syncToken == "token-xyz")
      #expect(captured?.database == .private)
    }

    @Test("POST /api/records/changes returns 401 without a captured auth token")
    internal func recordsChangesRequiresAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/changes",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"zoneName":"Notes"}"#)
        ) { response in
          #expect(response.status == .unauthorized)
        }
      }
    }
  }
#endif
